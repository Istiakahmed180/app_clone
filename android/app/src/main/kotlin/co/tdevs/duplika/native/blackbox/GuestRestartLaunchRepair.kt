package co.tdevs.duplika.native.blackbox

import android.app.Activity
import android.content.Context
import android.content.Intent
import co.tdevs.duplika.native.Slog
import top.niunaijun.blackbox.app.BActivityThread
import top.niunaijun.blackbox.fake.hook.MethodHook

/**
 * Keeps a clone on screen when the app restarts itself into an activity that has just closed.
 *
 * `CLEAR_TOP | SINGLE_TOP | NEW_TASK` on the launcher activity is the ordinary way an app
 * restarts itself after finishing setup. Bcore answers it from `ActivityStack`:
 *
 *     ActivityRecord found = findActivityRecordByComponentName(userId, target);
 *     if (clearTop && found != null) {
 *         for (ActivityRecord r : found.task.activities)
 *             if (r != found) r.finished = true;
 *             else if (singleTop) activityRecord = found; else found.finished = true;
 *     }
 *     ...
 *     if (activityRecord != null) { deliverNewIntentLocked(activityRecord, intent); return 0; }
 *
 * and `findActivityRecordByComponentName` returns a record whether or not it is already
 * `finished`. So when the target closed a moment ago, `CLEAR_TOP` finishes everything else in
 * the task and `SINGLE_TOP` hands the intent to the dead record — which cannot show anything.
 * The task is left empty and the clone disappears with no crash to explain it.
 *
 * Signal does exactly this. Measured on API 35:
 *
 *     startActivityLocked : MainActivity            ← first launch
 *     startActivityLocked : PassphraseCreateActivity
 *     onFinishActivity    : MainActivity            ← the record that goes stale
 *     startActivityLocked : MainActivity            ← the restart, flg=0x34000000
 *     makerFinish         : PassphraseCreateActivity
 *     onFinishActivity    : PassphraseCreateActivity
 *                                                   ← nothing ever launches
 *
 * `SINGLE_TOP` only ever means "if this activity is already there, hand it the intent instead
 * of making another". When it is not there, dropping the flag asks the platform for exactly
 * what it would have done anyway — and it steers Bcore past the branch that reuses the dead
 * record, on to the one that really starts the activity.
 *
 * Which is why the flag is dropped only when this process can *prove* the target is absent:
 * the component has to be one this very process hosts, and no live instance of it may be
 * among the activities this process is running. A target belonging to another process is
 * left alone, because from here there is no way to tell whether it is on screen.
 */
object GuestRestartLaunchRepair {

    private const val HOOKED_METHOD = "startActivity"

    @Volatile
    private var installed = false

    @Volatile
    private var context: Context? = null

    /** Idempotent; a wrapper already in place is recognised and left alone. */
    @Synchronized
    fun install(context: Context?) {
        this.context = context ?: this.context
        if (installed) return
        try {
            val replaced = EngineHookTable.wrapAll(HOOKED_METHOD) { current ->
                if (current is Repaired) null else Repaired(current)
            }
            if (replaced == 0) {
                Slog.w(Slog.LAUNCH, "Guest restart launch repair found no hook to replace")
                return
            }
            installed = true
            Slog.i(Slog.LAUNCH, "Guest restart launch repair installed on $replaced hook(s)")
        } catch (error: Throwable) {
            Slog.w(Slog.LAUNCH, "Guest restart launch repair unavailable: ${error.message}")
        }
    }

    private class Repaired(delegate: MethodHook) : EngineHookTable.Adjusting(
        delegate,
        HOOKED_METHOD,
        Fix::adjust,
    )

    private object Fix {

        fun adjust(args: Array<Any?>?) {
            val intent = args?.filterIsInstance<Intent>()?.firstOrNull() ?: return
            val flags = intent.flags
            if (flags and Intent.FLAG_ACTIVITY_CLEAR_TOP == 0) return
            if (flags and Intent.FLAG_ACTIVITY_SINGLE_TOP == 0) return

            val target = intent.component ?: return
            if (!isHostedHere(target)) return
            if (isLiveHere(target.className)) return

            intent.flags = flags and Intent.FLAG_ACTIVITY_SINGLE_TOP.inv()
            Slog.i(
                Slog.LAUNCH,
                "Restart into ${target.className} had no live instance; " +
                    "dropped SINGLE_TOP so it is started rather than handed to a closed one",
            )
        }

        /**
         * Whether [target] runs in this process, read from the guest's own manifest. Only
         * then is the absence check below an answer rather than a guess: a component has one
         * process, so a live instance of it can exist nowhere else.
         */
        fun isHostedHere(target: android.content.ComponentName): Boolean {
            val packageManager = context?.packageManager ?: return false
            val info = runCatching { packageManager.getActivityInfo(target, 0) }.getOrNull()
                ?: return false
            val here = runCatching { BActivityThread.getAppProcessName() }.getOrNull()
                ?: return false
            // A component with no android:process runs in the package's own process, which
            // is what ActivityInfo already reports, so the two are compared directly.
            return info.processName == here
        }

        /**
         * Whether this process is running an instance of [className] that could still take
         * the intent. A finishing or destroyed one could not, which is the whole point.
         */
        fun isLiveHere(className: String): Boolean = runCatching {
            val activityThread = Class.forName("android.app.ActivityThread")
            val current = activityThread.getDeclaredMethod("currentActivityThread")
                .apply { isAccessible = true }
                .invoke(null) ?: return false
            val records = activityThread.getDeclaredField("mActivities")
                .apply { isAccessible = true }
                .get(current) as? Map<*, *> ?: return false

            records.values.any { record ->
                val activity = record?.let { activityOf(it) } ?: return@any false
                activity.javaClass.name == className &&
                    !activity.isFinishing &&
                    !activity.isDestroyed
            }
        }.getOrDefault(false)

        private fun activityOf(record: Any): Activity? {
            var cursor: Class<*>? = record.javaClass
            while (cursor != null && cursor != Any::class.java) {
                for (field in cursor.declaredFields) {
                    if (!Activity::class.java.isAssignableFrom(field.type)) continue
                    return runCatching {
                        field.isAccessible = true
                        field.get(record) as? Activity
                    }.getOrNull()
                }
                cursor = cursor.superclass
            }
            return null
        }
    }
}
