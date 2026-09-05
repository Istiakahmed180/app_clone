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

        if (adapter.isPackageInstalled(packageName, virtualUserId)) {
            Slog.i(Slog.INSTALL, "$packageName already present in user $virtualUserId")
            return EngineResult.ok()
        }

        return adapter.installPackage(packageName, virtualUserId)
    }

    fun uninstall(packageName: String, virtualUserId: Int): EngineResult<Unit> =
        adapter.uninstallPackage(packageName, virtualUserId)

    fun isInstalled(packageName: String, virtualUserId: Int): Boolean =
        adapter.isPackageInstalled(packageName, virtualUserId)
}
