package co.tdevs.duplika.native.blackbox

import android.content.AttributionSource
import android.os.Build
import android.os.Bundle
import co.tdevs.duplika.native.Slog
import java.lang.reflect.InvocationTargetException
import java.lang.reflect.Method
import top.niunaijun.blackbox.BlackBoxCore
import top.niunaijun.blackbox.fake.hook.MethodHook

/**
 * Lets a clone hold a Wi-Fi lock instead of being killed for asking.
 *
 * A clone's calls carry the container's identity: the engine gives the guest a virtual uid,
 * and the platform sees the host's. Where a call names who is asking, the two have to be
 * reconciled, and the engine does that for the arguments it knows — but `acquireWifiLock`
 * carries its `AttributionSource` inside a `Bundle`, which the engine's fix does not look
 * into, and the Wi-Fi service hook it installs only covers `getConnectionInfo`.
 *
 * So the first clone that takes a Wi-Fi lock dies. Measured with Prime Video on API 35, on
 * its own network thread a second after launch:
 *
 *     FATAL EXCEPTION: Http:Network-0
 *     Process: com.amazon.avod.thirdpartyclient
 *     java.lang.SecurityException: Calling uid: 10463 doesn't match source uid: 10002
 *         at IWifiManager$Stub$Proxy.acquireWifiLock(IWifiManager.java:4938)
 *         at android.net.wifi.WifiManager$WifiLock.acquire(WifiManager.java:8514)
 *         at com.amazon.bolthttp.internal.net.WifiLockHolder.acquireLock
 *
 * — an uncaught exception on a thread the app did not expect to lose, so the process goes and
 * the clone is a black screen. Prime Video takes that lock for every HTTP fetch, so it never
 * gets past its first request.
 *
 * The repair asks as the host: every attribution in the call — an argument, or one nested in
 * a `Bundle` of extras — is replaced with one naming the host uid and package, which is the
 * identity the platform will check the call against anyway. Nothing else about the call is
 * touched, and a call already naming the host is left exactly as it is.
 */
object GuestWifiLockRepair {

    private const val WIFI_INTERFACE = "android.net.wifi.IWifiManager"

    /**
     * The Wi-Fi calls that carry the caller's attribution. Named rather than discovered,
     * because rewriting an identity is only right where the identity is the caller's own.
     */
    private val ATTRIBUTED_METHODS = arrayOf(
        "acquireWifiLock",
        "updateWifiLockWorkSource",
        "acquireMulticastLock",
    )

    @Volatile
    private var installed = false

    @Synchronized
    fun install() {
        if (installed || Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        try {
            val repaired = ATTRIBUTED_METHODS.filter { method ->
                EngineHookTable.addTo(WIFI_INTERFACE, method) { AsHost(method) } > 0
            }
            if (repaired.isEmpty()) {
                Slog.w(Slog.LAUNCH, "Guest Wi-Fi lock repair found no Wi-Fi hook")
                return
            }
            installed = true
            Slog.i(Slog.LAUNCH, "Guest Wi-Fi lock repair installed on ${repaired.joinToString()}")
        } catch (error: Throwable) {
            Slog.w(Slog.LAUNCH, "Guest Wi-Fi lock repair unavailable: ${error.message}")
        }
    }

    /** Asks as the host, and otherwise leaves the call and its answer exactly as they were. */
    private class AsHost(private val name: String) : MethodHook() {

        /** Said once per process: a clone takes a Wi-Fi lock for every request it makes. */
        private var said = false

        override fun getMethodName(): String = name

        override fun isEnable(): Boolean = true

        override fun hook(who: Any?, method: Method?, args: Array<Any?>?): Any? {
            method ?: return null
            val corrected = args?.copyOf()
            corrected?.let { rename(it) }
            return try {
                method.invoke(who, *(corrected ?: emptyArray()))
            } catch (error: InvocationTargetException) {
                throw error.cause ?: error
            }
        }

        /** Replaces every attribution in [args], including one inside a `Bundle` of extras. */
        private fun rename(args: Array<Any?>) {
            for (index in args.indices) {
                when (val argument = args[index]) {
                    is AttributionSource -> asHost(argument)?.let { args[index] = it }
                    is Bundle -> asHost(argument)?.let { args[index] = it }
                    else -> Unit
                }
            }
        }

        /** A copy of [source] naming the host, or null when it already does. */
        private fun asHost(source: AttributionSource): AttributionSource? {
            val host = BlackBoxCore.getHostUid()
            if (source.uid == host) return null
            say(source.uid)
            return runCatching {
                AttributionSource.Builder(host)
                    .setPackageName(BlackBoxCore.getHostPkg())
                    .setAttributionTag(source.attributionTag)
                    .build()
            }.getOrNull()
        }

        /**
         * A copy of [extras] with every attribution in it renamed, or null when there is
         * none to rename. The bundle is copied rather than written to, because it belongs to
         * the caller and may be reused for the next request.
         */
        private fun asHost(extras: Bundle): Bundle? {
            val renamed = runCatching {
                var changed = false
                val copy = Bundle(extras)
                for (key in extras.keySet()) {
                    @Suppress("DEPRECATION")
                    val source = extras.getParcelable<AttributionSource>(key) ?: continue
                    val host = asHost(source) ?: continue
                    copy.putParcelable(key, host)
                    changed = true
                }
                copy.takeIf { changed }
            }
            return renamed.getOrNull()
        }

        private fun say(askedAs: Int) {
            if (said) return
            said = true
            Slog.i(
                Slog.LAUNCH,
                "$name was asked as uid $askedAs; asking as the host instead, so the " +
                    "platform answers rather than killing the clone",
            )
        }
    }
}
