package co.tdevs.duplika.native

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Message

/**
 * Repairs activity launches inside a clone whose intent still names an `<activity-alias>`.
 *
 * `ActivityThread.performLaunchActivity` takes the class to instantiate from
 * `intent.getComponent().getClassName()`, not from the `ActivityInfo` beside it. Real
 * Android gets away with that because an alias arrives with `ActivityInfo.targetActivity`
 * set, and the platform swaps in that target. Bcore instead substitutes the *resolved*
 * `ActivityInfo` while leaving the alias in the intent, so the two disagree and the class
 * loader is asked for a name that was never compiled:
 *
 *     LaunchActivityItem{
 *       intent = Intent{ ... cmp=com.instagram.android/.InternalLauncher },
 *       info   = ActivityInfo{ com.instagram.nux.activity.BloksSignedOutFragmentActivity }
 *     }
 *     → ClassNotFoundException: com.instagram.android.InternalLauncher
 *
 * Instagram hits this the moment "I already have a profile" is tapped, and the engine
 * restarts the process on every crash, so the clone becomes a black screen that loops.
 *
 * The repair does what the platform would have done: an intent naming a class the guest
 * cannot load is pointed at the alias's own `targetActivity`, read from the manifest. It
 * only ever acts on a launch that was going to throw, so one that would have succeeded is
 * never touched.
 *
 * This runs in the guest process, ahead of the app's own `Application`, by wrapping the
 * `Handler.Callback` Bcore installs on `ActivityThread.mH` — the engine's callback is
 * invoked first and does its own rewrite; this only inspects what it produced. Field
 * lookups go by type rather than by name so the shape changes across platform versions
 * (`ClientTransaction` from API 28, `ActivityClientRecord` before it) do not matter.
 */
object GuestLaunchIntentRepair {

    @Volatile
    private var installed = false

    /**
     * The clone's own package manager, kept from the bind callback because the repair runs
     * later, on the main looper, where no context is handed to it. Used only to read the
     * `targetActivity` off an alias.
     */
    @Volatile
    private var packageManager: PackageManager? = null

    /**
     * Idempotent: a guest process that binds more than once must not stack wrappers, and a
     * failure here is never fatal — the clone simply keeps the behaviour it had.
     */
    @Synchronized
    fun install(context: Context?) {
        packageManager = context?.packageManager ?: packageManager
        if (installed) return
        installed = true
        try {
            val handler = activityThreadHandler() ?: return
            val callbackField = Handler::class.java.getDeclaredField("mCallback")
                .apply { isAccessible = true }
            val engineCallback = callbackField.get(handler) as? Handler.Callback
            callbackField.set(handler, wrap(engineCallback))
            Slog.i(Slog.LAUNCH, "Guest launch repair installed")
        } catch (error: Throwable) {
            Slog.w(Slog.LAUNCH, "Guest launch repair unavailable: ${error.message}")
        }
    }

    private fun wrap(engineCallback: Handler.Callback?) = Handler.Callback { message ->
        // The engine's callback substitutes the real intent and ActivityInfo for the proxy
        // activity's, so there is nothing to repair until after it has run. Its exceptions
        // are its own and must not be swallowed here.
        val consumed = engineCallback?.handleMessage(message) ?: false
        if (!consumed) {
            runCatching { repair(message) }
                .onFailure { Slog.w(Slog.LAUNCH, "Guest launch repair skipped: ${it.message}") }
        }
        consumed
    }

    private fun repair(message: Message) {
        val payload = message.obj ?: return
        if (payload.javaClass.name.endsWith("ClientTransaction")) {
            transactionItems(payload).forEach(::repairLaunchItem)
        } else {
            repairLaunchItem(payload)
        }
    }

    /** API 35 renamed the accessor; both return the items a transaction will execute. */
    private fun transactionItems(transaction: Any): List<Any> {
        for (name in arrayOf("getTransactionItems", "getCallbacks")) {
            val items = runCatching {
                transaction.javaClass.getMethod(name).invoke(transaction)
            }.getOrNull()
            if (items is List<*>) return items.filterNotNull()
        }
        return emptyList()
    }

    private fun repairLaunchItem(item: Any) {
        val simpleName = item.javaClass.simpleName
        // Everything else a transaction carries — resume, pause, configuration — has no
        // class name to get wrong.
        if (simpleName != "LaunchActivityItem" && simpleName != "ActivityClientRecord") return

        val intent = firstFieldOfType(item, Intent::class.java) as? Intent ?: return
        val info = firstFieldOfType(item, ActivityInfo::class.java) as? ActivityInfo ?: return
        val requested = intent.component ?: return

        // Only a launch that is already doomed gets rewritten.
        val loader = Thread.currentThread().contextClassLoader ?: return
        if (canLoad(loader, requested.className)) return

        // The alias's own target first, which is the substitution the platform makes and
        // the only one that lands where the app meant to go. Bcore's ActivityInfo is the
        // fallback: it names a class that at least exists, so a clone that would have
        // crash-looped keeps running even when the manifest cannot be read.
        val replacement = listOfNotNull(aliasTargetOf(requested), info.name)
            .firstOrNull { it.isNotEmpty() && it != requested.className && canLoad(loader, it) }
            ?: return

        intent.component = ComponentName(requested.packageName, replacement)
        Slog.i(
            Slog.LAUNCH,
            "Repaired alias launch ${requested.className} -> $replacement",
        )
    }

    /**
     * The real class behind an `<activity-alias>`, or null when [component] is not one.
     *
     * `MATCH_DISABLED_COMPONENTS` is required: the aliases that reach this point are the
     * ones the manifest ships disabled, and the default query would not return them.
     */
    private fun aliasTargetOf(component: ComponentName): String? = runCatching {
        packageManager
            ?.getActivityInfo(component, PackageManager.MATCH_DISABLED_COMPONENTS)
            ?.targetActivity
    }.getOrNull()

    private fun canLoad(loader: ClassLoader, className: String): Boolean =
        runCatching { Class.forName(className, false, loader) }.isSuccess

    private fun firstFieldOfType(target: Any, type: Class<*>): Any? {
        var cursor: Class<*>? = target.javaClass
        while (cursor != null && cursor != Any::class.java) {
            for (field in cursor.declaredFields) {
                if (field.type != type) continue
                return runCatching {
                    field.isAccessible = true
                    field.get(target)
                }.getOrNull()
            }
            cursor = cursor.superclass
        }
        return null
    }

    private fun activityThreadHandler(): Handler? {
        val activityThreadClass = Class.forName("android.app.ActivityThread")
        val activityThread = activityThreadClass
            .getDeclaredMethod("currentActivityThread")
            .apply { isAccessible = true }
            .invoke(null)
            ?: return null
        return activityThreadClass.getDeclaredField("mH")
            .apply { isAccessible = true }
            .get(activityThread) as? Handler
    }
}
