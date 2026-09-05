package com.example.virtualspacedemo.native.blackbox

import android.app.Application
import android.content.Context
import android.os.Build
import com.example.virtualspacedemo.native.EngineAvailability
import com.example.virtualspacedemo.native.EngineErrorCodes
import com.example.virtualspacedemo.native.EngineResult
import com.example.virtualspacedemo.native.Slog
import com.example.virtualspacedemo.native.VirtualizationEngineAdapter
import top.niunaijun.blackbox.BlackBoxCore
import top.niunaijun.blackbox.app.configuration.ClientConfiguration

/**
 * The ONLY file in Virtual Space permitted to reference NewBlackbox (`top.niunaijun.*`).
 *
 * Backend: NewBlackbox `Bcore`, Apache-2.0, vendored as a prebuilt AAR — see
 * `android/app/libs/BCORE_SOURCE_COMMIT.txt` and `docs/DEPENDENCY_LICENSE_AUDIT.md`.
 */
class BlackBoxEngineAdapter : VirtualizationEngineAdapter {

    override val backendName: String = "NewBlackbox/Bcore"

    @Volatile
    private var initialized = false

    override fun attachBaseContext(application: Application, base: Context) {
        try {
            val core = BlackBoxCore.get()
            core.closeCodeInit()
            core.onBeforeMainApplicationAttach(application, base)
            core.doAttachBaseContext(base, hostConfiguration(base))
            core.onAfterMainApplicationAttach(application, base)
            initialized = true
            Slog.i(Slog.ENGINE, "Engine attached in process ${application.packageName}")
        } catch (error: Throwable) {
            // A failure here must not take the host UI down; checkAvailability reports it.
            initialized = false
            Slog.e(Slog.ENGINE, "Engine attach failed", error)
        }
    }

    override fun onCreate(application: Application) {
        if (!initialized) return
        try {
            BlackBoxCore.get().doCreate()
            warmUpPackageService()
            Slog.i(Slog.ENGINE, "Engine created")
        } catch (error: Throwable) {
            initialized = false
            Slog.e(Slog.ENGINE, "Engine create failed", error)
        }
    }

    /**
     * Works around a Bcore defect: `BPackageManager.shouldUseFallbackMode()` calls
     * `isServiceHealthy()`, which inspects the lazily-cached binder *without* fetching it
     * first. On a cold process the binder is still null, so the very first call silently
     * degrades to a host-PackageManager fallback — reporting the app as "installed" in
     * every virtual user and launching it unvirtualized.
     *
     * `forceReinitialize()` is Bcore's own public API and populates that cache, so the
     * engine is not patched or reflected into. Called before any package-manager work.
     */
    private fun warmUpPackageService() {
        try {
            BlackBoxCore.getBPackageManager().forceReinitialize()
        } catch (error: Throwable) {
            Slog.w(Slog.ENGINE, "Package service warm-up failed: ${error.message}")
        }
    }

    /**
     * Security posture is pinned here, not left to backend defaults:
     * FLAG_SECURE is never disabled, root is never hidden, and no VPN interception.
     */
    private fun hostConfiguration(base: Context): ClientConfiguration =
        object : ClientConfiguration() {
            override fun getHostPackageName(): String = base.packageName

            override fun isHideRoot(): Boolean = false

            override fun isDisableFlagSecure(): Boolean = false

            override fun isUseVpnNetwork(): Boolean = false

            override fun isEnableDaemonService(): Boolean = false

            override fun isEnableLauncherActivity(): Boolean = false
        }

    override fun checkAvailability(context: Context): EngineAvailability {
        if (Build.VERSION.SDK_INT < MIN_SDK) {
            return EngineAvailability.Unavailable(
                EngineErrorCodes.ENGINE_UNSUPPORTED_ANDROID_VERSION,
                "The virtualization engine requires Android 5.0 or newer.",
            )
        }

        // Bcore ships native code for arm64-v8a and armeabi-v7a only.
        val abis = Build.SUPPORTED_ABIS.toSet()
        if (SUPPORTED_ABIS.none { it in abis }) {
            return EngineAvailability.Unavailable(
                EngineErrorCodes.ABI_NOT_SUPPORTED,
                "This device's CPU (${abis.joinToString()}) is not supported by the engine.",
            )
        }

        if (!initialized) {
            return EngineAvailability.Unavailable(
                EngineErrorCodes.ENGINE_INITIALIZATION_FAILED,
                "The virtualization engine failed to start on this device.",
            )
        }

        return EngineAvailability.Available
    }

    override fun initialize(context: Context): EngineResult<Unit> =
        when (val availability = checkAvailability(context)) {
            is EngineAvailability.Available -> EngineResult.ok()
            is EngineAvailability.Unavailable ->
                EngineResult.Failure(availability.code, availability.message)
        }

    override fun installPackage(packageName: String, virtualUserId: Int): EngineResult<Unit> =
        guarded(EngineErrorCodes.APP_INSTALL_FAILED) {
            warmUpPackageService()
            val result = BlackBoxCore.get().installPackageAsUser(packageName, virtualUserId)
            if (result != null && result.success) {
                Slog.i(Slog.INSTALL, "Installed $packageName into user $virtualUserId")
                EngineResult.ok()
            } else {
                val reason = result?.msg ?: "unknown engine error"
                Slog.e(Slog.INSTALL, "Install of $packageName failed: $reason")
                EngineResult.Failure(EngineErrorCodes.APP_INSTALL_FAILED, reason)
            }
        }

    override fun uninstallPackage(packageName: String, virtualUserId: Int): EngineResult<Unit> =
        guarded(EngineErrorCodes.PROFILE_DELETE_FAILED) {
            BlackBoxCore.get().uninstallPackageAsUser(packageName, virtualUserId)
            EngineResult.ok()
        }

    override fun isPackageInstalled(packageName: String, virtualUserId: Int): Boolean =
        runCatching {
            warmUpPackageService()
            BlackBoxCore.get().isInstalled(packageName, virtualUserId)
        }.getOrDefault(false)

    override fun launch(packageName: String, virtualUserId: Int): EngineResult<Unit> =
        guarded(EngineErrorCodes.VIRTUAL_APP_LAUNCH_FAILED) {
            warmUpPackageService()
            if (!isPackageInstalled(packageName, virtualUserId)) {
                return@guarded EngineResult.Failure(
                    EngineErrorCodes.VIRTUAL_APP_NOT_INSTALLED,
                    "The application is not installed in this virtual profile.",
                )
            }
            if (BlackBoxCore.get().launchApk(packageName, virtualUserId)) {
                Slog.i(Slog.LAUNCH, "Launched $packageName in user $virtualUserId")
                EngineResult.ok()
            } else {
                EngineResult.Failure(
                    EngineErrorCodes.VIRTUAL_APP_LAUNCH_FAILED,
                    "The engine refused to launch the virtual application.",
                )
            }
        }

    override fun stop(packageName: String, virtualUserId: Int): EngineResult<Unit> =
        guarded(EngineErrorCodes.VIRTUAL_APP_LAUNCH_FAILED) {
            BlackBoxCore.get().stopPackage(packageName, virtualUserId)
            EngineResult.ok()
        }

    override fun isRunning(packageName: String, virtualUserId: Int): Boolean =
        runCatching { BlackBoxCore.isRunningApplication(packageName, virtualUserId) }
            .getOrDefault(false)

    override fun deleteVirtualUser(virtualUserId: Int): EngineResult<Unit> =
        guarded(EngineErrorCodes.PROFILE_DELETE_FAILED) {
            BlackBoxCore.get().deleteUser(virtualUserId)
            EngineResult.ok()
        }

    override fun listVirtualUserIds(): List<Int> =
        runCatching {
            BlackBoxCore.get().users.orEmpty().map { it.id }
        }.getOrDefault(emptyList())

    /** Converts any backend throwable into a typed failure instead of crashing the host. */
    private inline fun guarded(
        code: String,
        block: () -> EngineResult<Unit>,
    ): EngineResult<Unit> = try {
        block()
    } catch (error: Throwable) {
        Slog.e(Slog.ENGINE, "Engine call failed ($code)", error)
        EngineResult.Failure(code, error.message ?: "Engine call failed.")
    }

    private companion object {
        const val MIN_SDK = Build.VERSION_CODES.LOLLIPOP
        val SUPPORTED_ABIS = setOf("arm64-v8a", "armeabi-v7a")
    }
}
