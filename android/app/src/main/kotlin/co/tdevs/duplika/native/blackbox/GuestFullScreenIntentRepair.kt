package co.tdevs.duplika.native.blackbox

import android.content.AttributionSource
import android.os.Build
import co.tdevs.duplika.native.Slog
import java.lang.reflect.Method
import top.niunaijun.blackbox.BlackBoxCore
import top.niunaijun.blackbox.fake.hook.MethodHook

/**
 * Lets a guest ask whether it may post full-screen notifications without being killed for it.
 *
 * `NotificationManager.canUseFullScreenIntent()` (API 34+) is answered by the *real* system
 * service, and the call carries an `AttributionSource` describing who is asking. The platform
 * reads that structure back with `AttributionSource.enforceCallingUid()`, so the uid inside it
 * has to be the uid the binder transaction actually came from. Inside a container it is not:
 * the guest's context was built with the container's own uid, and the transaction leaves the
 * host process under the host's. The system then refuses the call outright:
 *
 *     SecurityException: Calling uid: 10428 doesn't match source uid: 10003
 *       at INotificationManager$Stub$Proxy.canUseFullScreenIntent
 *       at NotificationManager.canUseFullScreenIntent
 *       at com.linkedin.android.infra.navigation.MainActivity.onCreate
 *
 * LinkedIn asks this question in `onCreate`, so the exception came back out of
 * `performLaunchActivity` and killed the process before it drew a frame — the clone opened on a
 * black screen with nothing on screen to explain it.
 *
 * Bcore means to prevent this: `AttributionSourceUtils` rewrites the uid of every
 * `AttributionSource` in a hooked call's arguments. It cannot, because it looks for fields named
 * `mUid`, `uid`, `mCallingUid` and so on, while `AttributionSource` keeps both uid and package
 * inside an `AttributionSourceState` of its own. Every field lookup misses, the helper logs
 * "Fixed AttributionSource UID in method arguments" and nothing has been changed.
 *
 * So the argument is replaced here with one the platform will accept: the host's uid and the
 * host's package, which is the identity the transaction genuinely has. The answer is then the
 * honest one for the process that is really asking. A call that still fails is reported as "no"
 * rather than thrown, because not using a full-screen intent is a feature the app can do
 * without, and a dead activity is not.
 */
object GuestFullScreenIntentRepair {

    private const val HOOKED_METHOD = "canUseFullScreenIntent"
    private const val NOTIFICATION_INTERFACE = "android.app.INotificationManager"

    @Volatile
    private var installed = false

    /** Idempotent, and a no-op below API 34 where the call does not exist. */
    @Synchronized
    fun install() {
        if (installed || Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return
        try {
            val added = EngineHookTable.addTo(NOTIFICATION_INTERFACE, HOOKED_METHOD) { Repaired() }
            if (added == 0) {
                Slog.w(Slog.LAUNCH, "Guest full-screen intent repair found no notification hook")
                return
            }
            installed = true
            Slog.i(Slog.LAUNCH, "Guest full-screen intent repair installed on $added hook(s)")
        } catch (error: Throwable) {
            Slog.w(Slog.LAUNCH, "Guest full-screen intent repair unavailable: ${error.message}")
        }
    }

    private class Repaired : MethodHook() {

        override fun getMethodName(): String = HOOKED_METHOD

        // Installed only inside a guest, so there is no other process to exclude.
        override fun isEnable(): Boolean = true

        override fun hook(who: Any?, method: Method?, args: Array<Any?>?): Any? {
            method ?: return false
            val corrected: Array<Any?> = args?.copyOf() ?: arrayOfNulls(0)
            for (index in corrected.indices) {
                val argument = corrected[index]
                if (argument is AttributionSource && argument.uid != hostUid()) {
                    Slog.i(
                        Slog.LAUNCH,
                        "$HOOKED_METHOD was asked as uid ${argument.uid}; " +
                            "asking as the host instead so the platform will answer",
                    )
                    corrected[index] = asHost()
                }
            }
            return try {
                method.invoke(who, *corrected)
            } catch (error: Throwable) {
                // Reflection wraps whatever the service threw; the cause is the interesting half.
                val reason = (error.cause ?: error).message
                Slog.w(Slog.LAUNCH, "The system would not answer $HOOKED_METHOD: $reason")
                false
            }
        }

        /**
         * The uid the binder transaction will really arrive under.
         *
         * Not [Process.myUid]: the engine spoofs it inside a guest so that the app sees the
         * uid of its own container, which is the whole point of a container and exactly the
         * number the platform is about to reject. Measured in a LinkedIn guest, on a host
         * whose uid was 10429: `Process.myUid()` answered 10002, and the engine's own record
         * of the host answered 10429.
         */
        private fun hostUid(): Int = BlackBoxCore.getHostUid()

        /**
         * The host's identity, and only that: the package must belong to the uid, and the
         * guest's attribution tag belongs to neither.
         */
        private fun asHost(): AttributionSource =
            AttributionSource.Builder(hostUid())
                .setPackageName(BlackBoxCore.getHostPkg())
                .build()
    }
}
