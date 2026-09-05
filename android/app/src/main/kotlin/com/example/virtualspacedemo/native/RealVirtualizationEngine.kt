package com.example.virtualspacedemo.native

import android.content.Context

/**
 * Application-facing virtualization API.
 *
 * Composes the profile mapping, installer, launcher and security checker into the profile
 * lifecycle the host app needs, and is the only type [NativeBridge] talks to. It holds no
 * reference to any third-party engine type — that lives behind
 * [VirtualizationEngineAdapter].
 */
class RealVirtualizationEngine(
    private val context: Context,
    private val adapter: VirtualizationEngineAdapter,
) {

    private val profileManager = VirtualProfileManager(context)
    private val securityChecker = AppSecurityChecker(context)
    private val installer = VirtualAppInstaller(context, adapter, securityChecker)
    private val launcher = VirtualAppLauncher(adapter)

    val backendName: String get() = adapter.backendName

    fun isAvailable(): Boolean = adapter.checkAvailability(context) is EngineAvailability.Available

    fun availability(): Map<String, Any?> =
        when (val state = adapter.checkAvailability(context)) {
            is EngineAvailability.Available -> mapOf(
                "available" to true,
                "backend" to adapter.backendName,
            )
            is EngineAvailability.Unavailable -> mapOf(
                "available" to false,
                "backend" to adapter.backendName,
                "code" to state.code,
                "message" to state.message,
            )
        }

    fun initialize(): EngineResult<Unit> = adapter.initialize(context)

    fun isAppSupported(packageName: String): Boolean =
        securityChecker.check(packageName) is AppSecurityChecker.Verdict.Allowed

    fun requiresSecureEnvironment(packageName: String): Boolean =
        securityChecker.requiresSecureEnvironment(packageName)

    /**
     * Creates the virtual user if needed and installs the application into it.
     *
     * On failure the mapping is released again, so a profile is never left marked as
     * installed when the engine disagrees.
     */
    fun installAppToProfile(profileId: String, packageName: String): EngineResult<Unit> {
        requireAvailable()?.let { return it }

        val virtualUserId = profileManager.getOrCreate(profileId)
        val result = installer.install(packageName, virtualUserId)

        if (result is EngineResult.Failure && !installer.isInstalled(packageName, virtualUserId)) {
            profileManager.remove(profileId)
        }
        return result
    }

    fun uninstallAppFromProfile(profileId: String, packageName: String): EngineResult<Unit> {
        val virtualUserId = profileManager.virtualUserIdFor(profileId)
            ?: return EngineResult.Failure(
                EngineErrorCodes.VIRTUAL_APP_NOT_INSTALLED,
                "This profile has no virtual environment.",
            )
        return installer.uninstall(packageName, virtualUserId)
    }

    fun isAppInstalledInProfile(profileId: String, packageName: String): Boolean {
        val virtualUserId = profileManager.virtualUserIdFor(profileId) ?: return false
        return installer.isInstalled(packageName, virtualUserId)
    }

    fun launchProfile(profileId: String, packageName: String): EngineResult<Unit> {
        requireAvailable()?.let { return it }

        val virtualUserId = profileManager.virtualUserIdFor(profileId)
            ?: return EngineResult.Failure(
                EngineErrorCodes.VIRTUAL_APP_NOT_INSTALLED,
                "This profile has no virtual environment yet.",
            )
        return launcher.launch(packageName, virtualUserId)
    }

    fun stopProfile(profileId: String, packageName: String): EngineResult<Unit> {
        val virtualUserId = profileManager.virtualUserIdFor(profileId)
            ?: return EngineResult.ok()
        return launcher.stop(packageName, virtualUserId)
    }

    /** Removes the virtual environment for a profile. Other profiles are untouched. */
    fun deleteProfile(profileId: String, packageName: String): EngineResult<Unit> {
        val virtualUserId = profileManager.virtualUserIdFor(profileId)
            ?: return EngineResult.ok()

        launcher.stop(packageName, virtualUserId)
        installer.uninstall(packageName, virtualUserId)
        val deletion = adapter.deleteVirtualUser(virtualUserId)
        profileManager.remove(profileId)
        return deletion
    }

    /** Engine-observed state for one profile, used to render honest status in the UI. */
    fun profileState(profileId: String, packageName: String): Map<String, Any?> {
        val virtualUserId = profileManager.virtualUserIdFor(profileId)
        val installed = virtualUserId != null && installer.isInstalled(packageName, virtualUserId)
        val running = virtualUserId != null && launcher.isRunning(packageName, virtualUserId)

        return mapOf(
            "profileId" to profileId,
            "virtualUserId" to virtualUserId,
            "installed" to installed,
            "running" to running,
        )
    }

    private fun requireAvailable(): EngineResult.Failure? =
        when (val state = adapter.checkAvailability(context)) {
            is EngineAvailability.Available -> null
            is EngineAvailability.Unavailable -> EngineResult.Failure(state.code, state.message)
        }
}
