package co.tdevs.duplika.native.blackbox

import co.tdevs.duplika.native.Slog
import java.lang.reflect.InvocationTargetException
import java.lang.reflect.Method
import top.niunaijun.blackbox.fake.hook.MethodHook
import top.niunaijun.blackbox.utils.MethodParameterUtils

/**
 * Lets a clone ask about media routes without being killed for saying who it is.
 *
 * Every media-router call that names its caller is checked by the platform against the uid
 * behind the binder call. A clone has the host's uid and the guest's package name, so it has
 * to say the host's name — which is what the engine does, but only for the two methods it
 * hooks, `registerClientAsUser` and `registerRouter2`:
 *
 *     @ProxyMethod("registerRouter2")
 *     public Object hook(Object who, Method method, Object[] args) {
 *         MethodParameterUtils.replaceFirstAppPkg(args);
 *         return method.invoke(who, args);
 *     }
 *
 * `getSystemRoutes` is not one of them, and `MediaRouter2` asks it in its constructor. So the
 * first clone to touch `MediaRouter2.getInstance()` dies in `onCreate`. Measured with YouTube
 * on API 35:
 *
 *     FATAL EXCEPTION: main
 *     Process: com.google.android.youtube
 *     java.lang.SecurityException: callerPackageName does not match calling uid.
 *         at IMediaRouterService$Stub$Proxy.getSystemRoutes(IMediaRouterService.java:1045)
 *         at android.media.MediaRouter2.loadSystemRoutes(MediaRouter2.java:658)
 *         at android.media.MediaRouter2.<init>(MediaRouter2.java:626)
 *         at android.media.MediaRouter2.getInstance(MediaRouter2.java:228)
 *
 * — thirty-five times in thirty seconds, the clone relaunching into the same crash each time,
 * so all that is ever on screen is black.
 *
 * The repair gives the rest of that interface the same answer the engine already gives those
 * two: the caller is named as the host. [MethodParameterUtils.replaceFirstAppPkg] rewrites
 * only the first argument that names a package installed in this container, so a method that
 * also carries a *target* package — `registerProxyRouter`, `getSystemSessionInfoForPackage` —
 * keeps it. A method the engine already hooks is left alone, and so is a name this release
 * does not have: [EngineHookTable.addTo] adds nothing the interface will not be asked for.
 */
object GuestMediaRouterRepair {

    private const val MEDIA_ROUTER_INTERFACE = "android.media.IMediaRouterService"

    /**
     * The methods of that interface whose first package argument is the caller's own. They
     * are named rather than discovered because the correction is only right for a caller
     * name: applying it to a method that names some *other* app would be a different bug.
     */
    private val CALLER_NAMED_METHODS = arrayOf(
        "getSystemRoutes",
        "getSystemSessionInfoForPackage",
        "registerManager",
        "registerProxyRouter",
    )

    @Volatile
    private var installed = false

    @Synchronized
    fun install() {
        if (installed) return
        try {
            val repaired = CALLER_NAMED_METHODS.filter { method ->
                EngineHookTable.addTo(MEDIA_ROUTER_INTERFACE, method) { AsHost(method) } > 0
            }
            if (repaired.isEmpty()) {
                Slog.w(Slog.LAUNCH, "Guest media router repair found no media router hook")
                return
            }
            installed = true
            Slog.i(Slog.LAUNCH, "Guest media router repair installed on ${repaired.joinToString()}")
        } catch (error: Throwable) {
            Slog.w(Slog.LAUNCH, "Guest media router repair unavailable: ${error.message}")
        }
    }

    /** Asks as the host, and otherwise leaves the call and its answer exactly as they were. */
    private class AsHost(private val name: String) : MethodHook() {

        override fun getMethodName(): String = name

        override fun isEnable(): Boolean = true

        override fun hook(who: Any?, method: Method?, args: Array<Any?>?): Any? {
            method ?: return null
            val asked = runCatching { MethodParameterUtils.replaceFirstAppPkg(args) }.getOrNull()
            if (asked != null) {
                Slog.i(Slog.LAUNCH, "$name was asked as $asked; asked as the host instead")
            }
            return try {
                method.invoke(who, *(args ?: emptyArray()))
            } catch (error: InvocationTargetException) {
                // Thrown on, not swallowed: the caller is the framework's own media router,
                // and an answer invented here would only move the failure somewhere quieter.
                throw error.cause ?: error
            }
        }
    }
}
