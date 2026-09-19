package co.tdevs.duplika.native.blackbox

import android.content.ComponentName
import android.content.Intent
import co.tdevs.duplika.native.Slog
import top.niunaijun.blackbox.fake.hook.MethodHook

/**
 * Keeps a clone on screen when the app clears its own task to start over.
 *
 * `NEW_TASK | CLEAR_TASK` is how an app says "throw this task away and make this activity its
 * new root" — apps use it to return to a clean start after onboarding, a sign-out or a
 * configuration change. Bcore answers it from `ActivityStack.startActivityLocked`:
 *
 *     if (clearTask && newTask) {
 *         for (ActivityRecord r : task.activities) r.finished = true;
 *         finishAllActivity(userId);
 *     }
 *     ...
 *     return startActivityInSourceTask(...);
 *
 * `finishAllActivity` finishes every activity the container has, and it is asynchronous: the
 * finishes land on the guest *after* the replacement activity has been started into the same
 * task. So the new activity is created, resumed and then finished along with everything else,
 * the task is left empty, and the platform brings whatever is underneath to the front.
 *
 * LinkedIn does this on its way into the feed. Measured on API 35:
 *
 *     Hook in : Intent { flg=0x10008000 cmp=com.linkedin.android/.infra.navigation.MainActivity }
 *     startActivityLocked : MainActivity        <- the replacement
 *     onActivityResumed   : MainActivity        <- it was on screen
 *     onFinishActivity    : MainActivity
 *     ActivityTaskManager : Duplicate finish request for ProxyActivity$P0 t1164
 *     onFinishActivity    : MainActivity        <- and then it was not
 *     TopTaskTracker: onTaskMovedToFront ... co.tdevs.duplika/.LauncherDuplika
 *
 * — the clone flashed and dropped back to Duplika, with no crash to explain it.
 *
 * There is no flag that asks this engine for what `CLEAR_TASK` means. LinkedIn's MainActivity is
 * `launchMode="singleTop"`, and every other branch of `startActivityLocked` answers a singleTop
 * target that already has a record by delivering the intent to it — `CLEAR_TOP` included. So the
 * engine can be steered away from emptying the task, but not into building the replacement, and
 * the activity that survives is the one the app had just decided to throw away: LinkedIn's
 * `MainActivity` had asked to be replaced before filling `infra_activity_container`, took an
 * `onNewIntent` it does not route, and sat on an empty window — the black screen, now stable.
 *
 * What the app is owed is a fresh `onCreate` with this intent. Where the target is live in this
 * process, that is something the guest can do for itself: the intent is handed to the instance
 * and the instance is recreated, which is the restart the app asked for, without the engine
 * being asked a question it answers wrongly. The launch is then not forwarded at all.
 *
 * Where the target lives in another of the clone's processes there is no instance here to
 * restart, so the flags are corrected instead — `CLEAR_TOP` for `CLEAR_TASK` — which at least
 * keeps `finishAllActivity` from emptying the container. That is a smaller repair for the case
 * this one cannot reach, not a second opinion about the same one.
 */
object GuestTaskClearLaunchRepair {

    private const val HOOKED_METHOD = "startActivity"

    /** What the engine is asked for when the restart cannot be performed here. */
    private const val TASK_RESET = Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_NEW_TASK

    @Volatile
    private var installed = false

    /** Idempotent; a wrapper already in place is recognised and left alone. */
    @Synchronized
    fun install() {
        if (installed) return
        try {
            val replaced = EngineHookTable.wrapAll(HOOKED_METHOD) { current ->
                if (current is Repaired) null else Repaired(current)
            }
            if (replaced == 0) {
                Slog.w(Slog.LAUNCH, "Guest task clear repair found no hook to replace")
                return
            }
            installed = true
            Slog.i(Slog.LAUNCH, "Guest task clear repair installed on $replaced hook(s)")
        } catch (error: Throwable) {
            Slog.w(Slog.LAUNCH, "Guest task clear repair unavailable: ${error.message}")
        }
    }

    /**
     * Wraps the engine's own hook. `beforeHook` is where a call can be answered instead of
     * forwarded — the engine's stub returns whatever it gives back — which is what a restart
     * performed here needs; everything else is passed through untouched.
     */
    private class Repaired(private val delegate: MethodHook) : MethodHook() {

        override fun getMethodName(): String = HOOKED_METHOD

        override fun isEnable(): Boolean = delegate.isEnable()

        override fun beforeHook(
            who: Any?,
            method: java.lang.reflect.Method?,
            args: Array<Any?>?,
        ): Any? {
            // Never fatal: a restart this cannot perform is one the engine should still see.
            val handled = runCatching { Fix.restart(args) }.getOrDefault(false)
            // `startActivity` answers with a result code, and zero is the engine's own "started".
            if (handled) return 0
            return delegate.beforeHook(who, method, args)
        }

        override fun hook(
            who: Any?,
            method: java.lang.reflect.Method?,
            args: Array<Any?>?,
        ): Any? = delegate.hook(who, method, args)

        override fun afterHook(result: Any?): Any? = delegate.afterHook(result)
    }

    private object Fix {

        /**
         * Returns true when the restart has been performed here and must not be forwarded.
         */
        fun restart(args: Array<Any?>?): Boolean {
            val intent = args?.filterIsInstance<Intent>()?.firstOrNull() ?: return false
            if (intent.flags and TASK_RESET != TASK_RESET) return false
            val target = intent.component ?: return false

            val live = GuestActivities.liveHere(target.className)
            if (live.isEmpty()) {
                askForClearTopInstead(intent, target)
                return false
            }

            // The task is not being cleared any more, so the flags that said so would only
            // mislead whatever reads the intent next — the activity itself included.
            intent.flags = intent.flags and TASK_RESET.inv()
            live.forEach { activity ->
                activity.intent = intent
                activity.recreate()
            }
            Slog.i(
                Slog.LAUNCH,
                "Restarted ${live.size} instance(s) of ${target.className} in place, because " +
                    "clearing the task would have left the engine reusing the old one",
            )
            return true
        }

        /** For a target this process does not host: at least keep the container from emptying. */
        private fun askForClearTopInstead(intent: Intent, target: ComponentName) {
            intent.flags = intent.flags and Intent.FLAG_ACTIVITY_CLEAR_TASK.inv() or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            Slog.i(
                Slog.LAUNCH,
                "Restart into ${target.className} asked to clear its task, and runs in another " +
                    "process; asked for CLEAR_TOP so the replacement is not finished with it",
            )
        }
    }
}
