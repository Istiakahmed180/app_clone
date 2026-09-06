package com.example.virtualspacedemo.native

import android.content.Context

/**
 * Installs the controlled application into a virtual profile.
 *
 * Only the package identity is handed to the engine, which resolves the APK through the
 * platform's own PackageManager. Virtual Space never reads the target application's
 * private data directory and never copies its files.
 */
class VirtualAppInstaller(
    private val context: Context,
    private val adapter: VirtualizationEngineAdapter,
    private val securityChecker: AppSecurityChecker,
    private val analyzer: AppCompatibilityAnalyzer,
) {

    fun install(
        packageName: String,
        virtualUserId: Int,
        provisionGms: Boolean,
    ): EngineResult<Unit> {
        when (val verdict = securityChecker.check(packageName)) {
            is AppSecurityChecker.Verdict.Rejected ->
                return EngineResult.Failure(verdict.code, verdict.message)
            AppSecurityChecker.Verdict.Allowed -> Unit
        }

        // Deliberately no "already installed?" short-circuit. Bcore's isInstalled answers
        // from the *host* package manager whenever its own service is unhealthy, so it
        // reports every host-installed app as present in every container and would skip a
        // real install. Re-installing is idempotent and does not clear container data
        // (only the explicit clearPackage does), so always going through is both safe and
        // the only way to guarantee the per-user record exists.
        provisionGmsIfRequested(
            virtualUserId,
            provisionGms && analyzer.analyze(packageName).requiresGms,
        )
        return adapter.installPackage(packageName, virtualUserId)
    }

    /**
     * Gives this container its own copy of the Google packages when its app needs them.
     *
     * A guest cannot see the host's Google Play services -- measured, not assumed: inside a
     * container `isGooglePlayServicesAvailable` returns SERVICE_MISSING and
     * `com.google.android.gms` is not visible to the guest at all, so Google sign-in, push
     * and maps fail at their first call. Provisioning puts those packages inside the
     * container so there is something for the guest to find.
     *
     * Opt-in per clone, and off by default. Provisioning is not free: it installs a set of
     * Google packages (a few seconds), makes the container heavier, and -- because the guest
     * runs under the host UID and cannot present Google's signing certificate -- still leaves
     * Google Play services reporting SERVICE_INVALID, so sign-in and push do not actually
     * work yet (see docs/PHASE_4_COMPATIBILITY.md). Real apps that need no GMS (Telegram,
     * WhatsApp) run fine without it, so the default cost/benefit is negative. The user asks
     * for it per clone when they want to try a Google-login app and accept the trade.
     *
     * [wanted] is already the AND of the user's opt-in and the app actually declaring a GMS
     * dependency, so this method only decides device support and carries out the install.
     *
     * Failure is deliberately not fatal. A clone whose GMS provisioning failed is exactly the
     * clone the compatibility warning already describes, so the app is still installed and the
     * user still gets it -- degraded rather than absent. The reason is logged.
     */
    private fun provisionGmsIfRequested(virtualUserId: Int, wanted: Boolean) {
        // Logged unconditionally: whether a container gets GMS decides whether Google sign-in
        // and push work inside it, and silently skipping was previously indistinguishable from
        // provisioning that ran and did nothing.
        Slog.i(Slog.INSTALL, "GMS provisioning for user $virtualUserId: requested=$wanted")
        if (!wanted) {
            return
        }
        if (!adapter.isGmsSupported()) {
            Slog.w(Slog.INSTALL, "App needs GMS but this device has none; skipping provisioning")
            return
        }
        // No "already provisioned?" short-circuit, for the same reason install() has none:
        // the engine answers that question with isInstalled, which falls back to the *host*
        // package manager. The host has Google Play services, so it reports every container
        // as already provisioned and the real work is skipped -- measured, after this check
        // silently suppressed provisioning entirely. Re-provisioning is idempotent.
        when (val result = adapter.installGms(virtualUserId)) {
            is EngineResult.Success -> Unit
            is EngineResult.Failure ->
                Slog.e(Slog.INSTALL, "GMS provisioning failed (${result.code}): ${result.message}")
        }
    }

    /**
     * Installs a standalone APK the user imported.
     *
     * The package identity is parsed from the archive first so the same admission policy
     * applies as for an installed app — an APK that declares a secure-environment
     * requirement is rejected before the engine ever sees it.
     */
    fun installApk(
        apkPath: String,
        packageName: String,
        virtualUserId: Int,
        provisionGms: Boolean,
    ): EngineResult<Unit> {
        when (val verdict = securityChecker.checkApk(packageName, apkPath)) {
            is AppSecurityChecker.Verdict.Rejected ->
                return EngineResult.Failure(verdict.code, verdict.message)
            AppSecurityChecker.Verdict.Allowed -> Unit
        }

        provisionGmsIfRequested(
            virtualUserId,
            provisionGms && analyzer.analyzeApk(apkPath, packageName).requiresGms,
        )
        return adapter.installApkFile(apkPath, virtualUserId)
    }

    fun uninstall(packageName: String, virtualUserId: Int): EngineResult<Unit> =
        adapter.uninstallPackage(packageName, virtualUserId)

    fun isInstalled(packageName: String, virtualUserId: Int): Boolean =
        adapter.isPackageInstalled(packageName, virtualUserId)
}
