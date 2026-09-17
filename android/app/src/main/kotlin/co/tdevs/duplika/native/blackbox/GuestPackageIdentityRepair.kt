package co.tdevs.duplika.native.blackbox

import android.content.Context
import co.tdevs.duplika.native.Slog
import java.lang.reflect.Method
import java.lang.reflect.Proxy
import top.niunaijun.blackbox.BlackBoxCore
import top.niunaijun.blackbox.app.BActivityThread

/**
 * Stops a guest being told that its own uid belongs to Duplika.
 *
 * `PackageManager.getPackagesForUid` is how an app checks that a caller is who it claims to
 * be, and inside a container the honest answer is the guest packages sharing that virtual
 * uid. Bcore's own hook answers exactly that — measured,
 * `PackageManagerStub: 10001, com.google.android.gms GetPackagesForUid:
 * [com.google.android.gms, com.airbnb.android]` — but not on every path: some calls come
 * back naming the *host*, and an app that compares the two refuses itself.
 *
 * microG is the case that made it visible. Its sign-in screen attests through DroidGuard,
 * DroidGuard's service checks its caller the ordinary way, and the check failed against
 * microG itself:
 *
 *     GmsClient: onServiceConnected(ComponentInfo{com.google.android.gms/
 *                org.microg.gms.droidguard.core.DroidGuardService})
 *     FATAL EXCEPTION: main
 *     java.lang.SecurityException: UID [10001] is not related to
 *         packageName [com.google.android.gms] (seems to be co.tdevs.duplika)
 *
 * so the sign-in died the moment Google's page was ready to take the password.
 *
 * The repair wraps the package-manager binder the whole process shares and corrects that one
 * answer: a guest is never told that a uid inside its container belongs to the host. It adds
 * no package that is not already in the container and hides nothing a guest could otherwise
 * see — the host's name is not a guest's to read in the first place, which is the same
 * boundary [GuestCallerIdentityRepair] restores for `getCallingPackage`. Answers that do not
 * mention the host are passed through byte for byte.
 */
object GuestPackageIdentityRepair {

    private const val HOOKED_METHOD = "getPackagesForUid"

    @Volatile
    private var wrapper: Any? = null

    /**
     * Installed over whatever is in `sPackageManager` at the time, which is Bcore's proxy
     * and possibly [GuestReceiverQueryRepair]'s wrapper on top of it. Both are transparent,
     * so wrapping again only adds this correction. Safe to call repeatedly: a field that
     * already holds this wrapper is left alone, and Bcore replacing the proxy underneath is
     * handled by re-wrapping whatever is there now.
     */
    @Synchronized
    fun install(context: Context?) {
        try {
            val activityThread = Class.forName("android.app.ActivityThread")
            val field = activityThread.getDeclaredField("sPackageManager")
                .apply { isAccessible = true }

            val current = field.get(null)
                ?: activityThread.getMethod("getPackageManager").invoke(null)?.also {
                    field.set(null, it)
                }
            if (current == null) {
                Slog.w(Slog.BCORE, "Guest package identity repair found no package manager")
                return
            }
            if (current === wrapper) return

            val wrapped = Proxy.newProxyInstance(
                current.javaClass.classLoader,
                current.javaClass.interfaces,
            ) { _, method, args -> delegate(current, method, args) }
            field.set(null, wrapped)
            wrapper = wrapped
            repointExistingPackageManager(context, wrapped)
            Slog.i(Slog.BCORE, "Guest package identity repair installed")
        } catch (error: Throwable) {
            Slog.w(Slog.BCORE, "Guest package identity repair unavailable: ${error.message}")
        }
    }

    /**
     * An `ApplicationPackageManager` keeps the binder it was built with, so one that already
     * exists would never reach the wrapper.
     */
    private fun repointExistingPackageManager(context: Context?, wrapped: Any) {
        val existing = context?.packageManager ?: return
        runCatching {
            existing.javaClass.getDeclaredField("mPM").apply { isAccessible = true }
                .set(existing, wrapped)
        }
    }

    private fun delegate(target: Any, method: Method, args: Array<Any?>?): Any? {
        val answer = method.invoke(target, *(args ?: emptyArray()))
        if (method.name != HOOKED_METHOD) return answer
        return withoutHostPackage(answer)
    }

    /**
     * Replaces the host's name with the guest's, in place, keeping every other entry and the
     * order they arrived in. A caller that checks `packages[0]` and one that scans the whole
     * array then agree.
     */
    private fun withoutHostPackage(answer: Any?): Any? {
        val packages = answer as? Array<*> ?: return answer
        val host = runCatching { BlackBoxCore.getHostPkg() }.getOrNull() ?: return answer
        if (packages.none { it == host }) return answer

        val guest = runCatching { BActivityThread.getAppPackageName() }.getOrNull()
        if (guest.isNullOrBlank()) return answer

        val corrected = packages
            .map { if (it == host) guest else it }
            .distinct()
            .filterIsInstance<String>()
            .toTypedArray()
        Slog.w(
            Slog.BCORE,
            "Package manager named the host for a uid inside this container; " +
                "answering $guest instead",
        )
        return corrected
    }
}
