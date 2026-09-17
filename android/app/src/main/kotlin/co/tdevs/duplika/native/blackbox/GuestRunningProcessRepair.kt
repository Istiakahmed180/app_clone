package co.tdevs.duplika.native.blackbox

import android.app.ActivityManager
import co.tdevs.duplika.native.Slog
import top.niunaijun.blackbox.BlackBoxCore
import top.niunaijun.blackbox.fake.hook.MethodHook

/**
 * Stops the running-process list naming Duplika as the app behind a guest process.
 *
 * `ActivityManager.getRunningAppProcesses()` is the older of the two ways an app identifies
 * a caller, and microG uses it first — before it ever asks the package manager:
 *
 *     String pkg = packageFromProcessId(context, callingPid);   // running-process list
 *     if (pkg == null) { ... getPackagesForUid(callingUid) ... }
 *     if (pkg == null || suggested == null || pkg.equals(suggested)) return pkg;
 *     throw new SecurityException("UID [...] is not related to packageName [" + suggested +
 *                                 "] (seems to be " + pkg + ")");
 *
 * and `packageFromProcessId` answers with `pkgList[0]` of the entry whose pid matches, when
 * that entry names exactly one package. Inside a container the entry for a guest process
 * came back naming the host, so microG's own sign-in service refused microG's own UI:
 *
 *     GmsClient: onServiceConnected(ComponentInfo{com.google.android.gms/
 *                org.microg.gms.droidguard.core.DroidGuardService})
 *     FATAL EXCEPTION: main
 *     java.lang.SecurityException: UID [10001] is not related to
 *         packageName [com.google.android.gms] (seems to be co.tdevs.duplika)
 *
 * which killed Google sign-in at the moment DroidGuard was asked to attest the login — the
 * last step before the password page can do anything.
 *
 * The repair corrects that one field. An entry whose package list names the host is given
 * the package its own `processName` already says it is running: Bcore names a guest process
 * after the guest (`com.google.android.gms:ui`, `com.airbnb.android`), so the answer comes
 * from the entry itself rather than from an assumption about the caller. Entries that name
 * no host package are passed through untouched, and nothing is added to the list.
 *
 * This is the same boundary [GuestCallerIdentityRepair] restores for `getCallingActivity`:
 * the host's identity is not a guest's to read, and a guest that reads it makes wrong
 * decisions about itself.
 */
object GuestRunningProcessRepair {

    private const val HOOKED_METHOD = "getRunningAppProcesses"

    @Volatile
    private var installed = false

    /** Idempotent; a wrapper already in place is recognised and left alone. */
    @Synchronized
    fun install() {
        if (installed) return
        try {
            val replaced = EngineHookTable.wrapAll(HOOKED_METHOD) { current ->
                if (current is Repaired) null
                else Repaired(current)
            }
            if (replaced == 0) {
                Slog.w(Slog.BCORE, "Guest running-process repair found no hook to replace")
                return
            }
            installed = true
            Slog.i(Slog.BCORE, "Guest running-process repair installed on $replaced hook(s)")
        } catch (error: Throwable) {
            Slog.w(Slog.BCORE, "Guest running-process repair unavailable: ${error.message}")
        }
    }

    private class Repaired(delegate: MethodHook) : EngineHookTable.Correcting(
        delegate,
        HOOKED_METHOD,
        Fix::repair,
    )

    private object Fix {

        fun repair(answer: Any?): Any? {
            val processes = answer as? List<*> ?: return answer
            val host = runCatching { BlackBoxCore.getHostPkg() }.getOrNull() ?: return answer
            for (process in processes) {
                val info = process as? ActivityManager.RunningAppProcessInfo ?: continue
                val packages = info.pkgList ?: continue
                if (packages.none { it == host }) continue
                val guest = packageOfProcess(info.processName, host) ?: continue
                info.pkgList = packages.map { if (it == host) guest else it }.distinct().toTypedArray()
            }
            return answer
        }

        /**
         * The package a guest process belongs to, read off its own name — `a.b.c:push`
         * belongs to `a.b.c`. Null for a process that is genuinely the host's, so a host
         * process listed alongside the guests keeps its real name.
         */
        fun packageOfProcess(processName: String?, host: String): String? {
            if (processName.isNullOrBlank()) return null
            val packageName = processName.substringBefore(':')
            return if (packageName.isEmpty() || packageName == host) null else packageName
        }
    }
}
