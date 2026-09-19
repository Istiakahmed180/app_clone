package co.tdevs.duplika.native.blackbox

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.MessageQueue
import co.tdevs.duplika.native.Slog
import java.lang.reflect.Field
import java.util.Collections
import java.util.WeakHashMap
import top.niunaijun.blackbox.BlackBoxCore
import top.niunaijun.blackbox.fake.hook.IInjectHook
import top.niunaijun.blackbox.fake.hook.MethodHook

/**
 * Keeps the engine's activity-launch hook on the handler the guest is actually using.
 *
 * Bcore starts every guest activity as one of the `ProxyActivity` stubs in Duplika's manifest
 * and swaps the stub for the real thing from a `Handler.Callback` it installs on
 * `ActivityThread.mH`: the `EXECUTE_TRANSACTION` message carries a `LaunchActivityItem` whose
 * `mIntent`/`mInfo` it rewrites to the activity named in the stub intent's extras.
 *
 * TikTok Lite replaces `ActivityThread.mH` outright:
 *
 *     mH = com.zhiliaoapp.musically.go.task.HookActivityThreadTask$DelegateActivityThreadHandler
 *
 * a handler of its own with no callback on it. The engine's callback is left on the handler
 * that was there when the process started, which nothing dispatches to any more — and the
 * engine cannot notice, because `HCallbackProxy.isBadEnv` reads `mCallback` off whatever
 * `mH` *now* holds and finds it empty, which it reads as "nothing has displaced me".
 *
 * So no launch is ever rewritten. The platform creates the stub, and `ProxyActivity.onCreate`
 * does the only thing it can:
 *
 *     finish();
 *     HookManager.get().checkEnv(HCallbackProxy.class);   // sees a healthy environment
 *     startActivity(ProxyActivityRecord.create(getIntent()).mTarget);
 *
 * which starts the same stub again. Measured on API 35, that is 203 launches of
 * `com.zhiliaoapp.musically.go.mini.MainActivity` in eleven seconds, no frame ever drawn, no
 * crash to explain it: the clone is a black screen until it is killed.
 *
 * The repair is to put the engine's own callback back on the handler that is live, whenever a
 * different one has taken its place. It is the engine's callback that is re-installed, not a
 * copy of what it does — the swap is only half of that method's job, which also restarts an
 * unbound process, binds the application and tells the server the activity was created.
 *
 * There is nothing to be notified by, so it re-checks at two points that cost nothing and
 * between them cover the whole window:
 *
 * - main-thread idle, which is where the swap is normally caught, before any launch;
 * - every activity creation in this process; and
 * - every activity the guest starts, which is the one that ends a loop already under way.
 *   Idle never arrives during one — the restarts keep the queue full — but each turn of it
 *   goes through `ProxyActivity.onCreate`'s own `startActivity`, and that is hooked. So the
 *   hook is back before the next restart is dispatched and the loop ends on its first turn.
 */
object GuestProxyLaunchRepair {

    private const val ENGINE_CALLBACK = "top.niunaijun.blackbox.fake.service.HCallbackProxy"
    private const val PLATFORM_HANDLER = "android.app.ActivityThread\$H"
    private const val STARTING_ACTIVITY = "startActivity"

    @Volatile
    private var installed = false

    /** The handler last reported, so a swap is said once rather than at every idle. */
    @Volatile
    private var reported = 0

    /**
     * The applications already being watched. Two of them share a guest process — the host's,
     * which the engine's stub activities belong to, and the cloned app's — and an activity
     * creation is only dispatched to the one whose package declares it.
     */
    private val watched = Collections.newSetFromMap(WeakHashMap<Application, Boolean>())

    @Synchronized
    fun install() {
        if (installed) return
        val queue = runCatching { Looper.myQueue() }.getOrNull() ?: run {
            Slog.w(Slog.LAUNCH, "Guest proxy launch repair found no message queue")
            return
        }
        installed = true
        reassert()
        queue.addIdleHandler(MessageQueue.IdleHandler { reassert(); true })
        watch(runCatching { BlackBoxCore.getApplication() }.getOrNull())
        EngineHookTable.wrapAll(STARTING_ACTIVITY) { current ->
            if (current is Starting) null else Starting(current)
        }
        Slog.i(Slog.LAUNCH, "Guest proxy launch repair installed")
    }

    /**
     * Also re-checks whenever an activity is created in this process, which is the only
     * signal available while a restart loop is under way: idle never arrives during one, and
     * a stub's `onCreate` reaches here through `super.onCreate` before it restarts itself.
     */
    @Synchronized
    fun watch(application: Application?) {
        application ?: return
        if (!watched.add(application)) return
        application.registerActivityLifecycleCallbacks(object : NoLifecycle() {
            override fun onActivityCreated(activity: Activity, state: Bundle?) = reassert()
        })
    }

    /**
     * Puts the engine's callback back on the current `mH` if something else is on it. Silent
     * and cheap in the ordinary case: one field read that finds the engine already there.
     */
    private fun reassert() {
        try {
            val handler = mainHandler() ?: return
            val callback = callbackField()?.get(handler)
            if (callback != null && callback.javaClass.name == ENGINE_CALLBACK) return

            val engine = engineCallback() ?: return
            engine.injectHook()

            // Only a handler the guest brought with it is worth a line. The engine's own
            // handler having no callback yet is ordinary: this runs before the engine has
            // finished installing its hooks, and putting the callback on early changes
            // nothing about what the engine does with it.
            if (handler.javaClass.name == PLATFORM_HANDLER) return
            val identity = System.identityHashCode(handler)
            if (reported == identity) return
            reported = identity
            Slog.i(
                Slog.LAUNCH,
                "The guest is dispatching on ${handler.javaClass.name} rather than the " +
                    "handler it started with; put the engine's launch hook back on it so " +
                    "activities are started rather than restarted",
            )
        } catch (error: Throwable) {
            Slog.w(Slog.LAUNCH, "Guest proxy launch repair could not re-assert: ${error.message}")
        }
    }

    /** The engine's `HCallbackProxy`, taken from the injectors it keeps rather than rebuilt. */
    private fun engineCallback(): IInjectHook? =
        EngineHookTable.injectorNamed(ENGINE_CALLBACK) as? IInjectHook

    /** `ActivityThread.mH`, read fresh every time: the point of this class is that it changes. */
    private fun mainHandler(): Handler? = runCatching {
        val activityThread = Class.forName("android.app.ActivityThread")
        val current = activityThread.getMethod("currentActivityThread").invoke(null)
        field(activityThread, "mH")?.get(current) as? Handler
    }.getOrNull()

    private fun callbackField(): Field? = field(Handler::class.java, "mCallback")

    private fun field(type: Class<*>, name: String): Field? {
        var current: Class<*>? = type
        while (current != null) {
            val declared = runCatching { current!!.getDeclaredField(name) }.getOrNull()
            if (declared != null) return declared.apply { isAccessible = true }
            current = current.superclass
        }
        return null
    }

    /**
     * Re-checks as the guest starts an activity. Nothing about the call is touched: the
     * launch being made is the signal, and what it carries is the engine's business.
     */
    private class Starting(delegate: MethodHook) : EngineHookTable.Adjusting(
        delegate,
        STARTING_ACTIVITY,
        { reassert() },
    )

    /** Only one of the eight callbacks is of any interest here; the rest are left empty. */
    private abstract class NoLifecycle : Application.ActivityLifecycleCallbacks {
        override fun onActivityStarted(activity: Activity) = Unit
        override fun onActivityResumed(activity: Activity) = Unit
        override fun onActivityPaused(activity: Activity) = Unit
        override fun onActivityStopped(activity: Activity) = Unit
        override fun onActivitySaveInstanceState(activity: Activity, state: Bundle) = Unit
        override fun onActivityDestroyed(activity: Activity) = Unit
    }
}
