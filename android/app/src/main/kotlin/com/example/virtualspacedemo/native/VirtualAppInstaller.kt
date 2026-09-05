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
) {

    fun install(packageName: String, virtualUserId: Int): EngineResult<Unit> {
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
        return adapter.installPackage(packageName, virtualUserId)
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
    ): EngineResult<Unit> {
        when (val verdict = securityChecker.checkApk(packageName)) {
            is AppSecurityChecker.Verdict.Rejected ->
                return EngineResult.Failure(verdict.code, verdict.message)
            AppSecurityChecker.Verdict.Allowed -> Unit
        }

        return adapter.installApkFile(apkPath, virtualUserId)
    }

    fun uninstall(packageName: String, virtualUserId: Int): EngineResult<Unit> =
        adapter.uninstallPackage(packageName, virtualUserId)

    fun isInstalled(packageName: String, virtualUserId: Int): Boolean =
        adapter.isPackageInstalled(packageName, virtualUserId)
}
