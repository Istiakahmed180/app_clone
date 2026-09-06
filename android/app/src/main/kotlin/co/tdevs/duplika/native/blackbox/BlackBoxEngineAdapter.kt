package co.tdevs.duplika.native.blackbox

import android.app.Application
import android.content.Context
import android.os.Build
import android.os.SystemClock
import java.io.File
import co.tdevs.duplika.native.EngineAvailability
import co.tdevs.duplika.native.EngineErrorCodes
import co.tdevs.duplika.native.EngineResult
import co.tdevs.duplika.native.Slog
import co.tdevs.duplika.native.VirtualizationEngineAdapter
import top.niunaijun.blackbox.BlackBoxCore
import top.niunaijun.blackbox.app.configuration.ClientConfiguration

/**
 * The ONLY file in Duplika permitted to reference NewBlackbox (`top.niunaijun.*`).
 *
 * Backend: NewBlackbox `Bcore`, Apache-2.0, vendored as a prebuilt AAR — see
 * `android/app/libs/BCORE_SOURCE_COMMIT.txt` and `docs/DEPENDENCY_LICENSE_AUDIT.md`.
 */
class BlackBoxEngineAdapter : VirtualizationEngineAdapter {

    override val backendName: String = "NewBlackbox/Bcore"

    @Volatile
    private var initialized = false

    private var lastWarmUpAt = 0L

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
     * engine is not patched or reflected into.
     *
     * It must NOT be called back-to-back. It clears the cache and then re-fetches, but
     * Bcore rate-limits service creation to one attempt per 50 ms and returns the
     * (just-cleared, null) reference inside that window — so two rapid warm-ups leave the
     * service null and the next call throws an NPE. Hence the interval guard.
     */
    @Synchronized
    private fun warmUpPackageService(force: Boolean = false) {
        val now = SystemClock.elapsedRealtime()
        if (!force && now - lastWarmUpAt < WARM_UP_MIN_INTERVAL_MS) {
            return
        }
        lastWarmUpAt = now
        try {
            BlackBoxCore.getBPackageManager().forceReinitialize()
        } catch (error: Throwable) {
            Slog.w(Slog.ENGINE, "Package service warm-up failed: ${error.message}")
        }
    }

    /**
     * Retries once past Bcore's failure backoff.
     *
     * After a service creation failure Bcore refuses to rebuild the binder for
     * [RETRY_TIMEOUT_MS], returning null and throwing an NPE on every call in between.
     * Waiting out that window and forcing a rebuild recovers without touching the engine.
     * Callers run on a background thread, so this never blocks the UI.
     */
    private fun withServiceRetry(block: () -> EngineResult<Unit>): EngineResult<Unit> {
        // Retried only when the engine failed to answer: either it threw (the null binder
        // surfaces as an NPE) or it returned ENGINE_NO_RESPONSE. Any other returned Failure
        // is a definitive answer ("not installed", "refused") and must not be delayed by the
        // backoff or repeated.
        try {
            val first = block()
            if (first !is EngineResult.Failure || first.code != EngineErrorCodes.ENGINE_NO_RESPONSE) {
                return first
            }
            Slog.w(Slog.ENGINE, "Engine gave no response; retrying after service backoff")
        } catch (error: Throwable) {
            Slog.w(Slog.ENGINE, "Engine service unavailable (${error.javaClass.simpleName}); retrying")
        }

        SystemClock.sleep(RETRY_TIMEOUT_MS + 200L)
        warmUpPackageService(force = true)
        return try {
            block()
        } catch (error: Throwable) {
            Slog.e(Slog.ENGINE, "Engine service still unavailable after retry", error)
            EngineResult.Failure(
                EngineErrorCodes.ENGINE_INITIALIZATION_FAILED,
                "The virtualization engine service is not responding.",
            )
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
            withServiceRetry {
                warmUpPackageService()
                doInstall(packageName, virtualUserId)
            }
        }

    private fun doInstall(packageName: String, virtualUserId: Int): EngineResult<Unit> {
        val result = BlackBoxCore.get().installPackageAsUser(packageName, virtualUserId)
            ?: return noResponse("install of $packageName")

        return if (result.success) {
            Slog.i(Slog.INSTALL, "Installed $packageName into user $virtualUserId")
            EngineResult.ok()
        } else {
            val reason = result.msg ?: "the engine refused the install"
            Slog.e(Slog.INSTALL, "Install of $packageName failed: $reason")
            EngineResult.Failure(EngineErrorCodes.APP_INSTALL_FAILED, reason)
        }
    }

    /**
     * A null result is Bcore saying nothing, not saying no — it happens when its package
     * service is momentarily unhealthy. Reporting it as a plain install failure made an
     * otherwise fine install fail intermittently, because a returned failure is never
     * retried. Giving it its own code lets [withServiceRetry] treat it as transient.
     */
    private fun noResponse(what: String): EngineResult.Failure {
        Slog.w(Slog.ENGINE, "No response from the engine for $what")
        return EngineResult.Failure(
            EngineErrorCodes.ENGINE_NO_RESPONSE,
            "The virtualization engine did not respond.",
        )
    }

    override fun isGmsSupported(): Boolean =
        runCatching { BlackBoxCore.get().isSupportGms() }.getOrDefault(false)

    override fun installGms(virtualUserId: Int): EngineResult<Unit> =
        guarded(EngineErrorCodes.GMS_INSTALL_FAILED) {
            withServiceRetry {
                warmUpPackageService()
                doInstallGms(virtualUserId)
            }
        }

    private fun doInstallGms(virtualUserId: Int): EngineResult<Unit> {
        val result = BlackBoxCore.get().installGms(virtualUserId)
            ?: return noResponse("Google Play services install into user $virtualUserId")

        return if (result.success) {
            Slog.i(Slog.INSTALL, "Provisioned Google Play services into user $virtualUserId")
            EngineResult.ok()
        } else {
            val reason = result.msg ?: "the engine refused to install Google Play services"
            Slog.e(Slog.INSTALL, "GMS provisioning failed for user $virtualUserId: $reason")
            EngineResult.Failure(EngineErrorCodes.GMS_INSTALL_FAILED, reason)
        }
    }

    override fun installApkFile(apkPath: String, virtualUserId: Int): EngineResult<Unit> =
        guarded(EngineErrorCodes.APP_INSTALL_FAILED) {
            withServiceRetry {
                warmUpPackageService()
                doInstallApk(apkPath, virtualUserId)
            }
        }

    private fun doInstallApk(apkPath: String, virtualUserId: Int): EngineResult<Unit> {
        val file = File(apkPath)
        if (!file.isFile) {
            return EngineResult.Failure(
                EngineErrorCodes.APK_UNREADABLE,
                "The selected APK could not be read.",
            )
        }

        val result = BlackBoxCore.get().installPackageAsUser(file, virtualUserId)
            ?: return noResponse("APK install into user $virtualUserId")

        return if (result.success) {
            Slog.i(Slog.INSTALL, "Installed APK ${result.packageName} into user $virtualUserId")
            EngineResult.ok()
        } else {
            val reason = result.msg ?: "the engine refused the install"
            Slog.e(Slog.INSTALL, "APK install failed: $reason")
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
            BlackBoxCore.get().isInstalled(packageName, virtualUserId)
        }.getOrDefault(false)

    override fun launch(packageName: String, virtualUserId: Int): EngineResult<Unit> =
        guarded(EngineErrorCodes.VIRTUAL_APP_LAUNCH_FAILED) {
            // Launch reads the same package service that install does, so it needs the
            // same recovery from Bcore's null-binder window.
            withServiceRetry {
                // A launch is user-initiated and infrequent, so always rebuild the binder
                // rather than trusting a possibly stale cached one.
                warmUpPackageService(force = true)
                doLaunch(packageName, virtualUserId)
            }
        }

    /**
     * Deliberately does NOT pre-check [isPackageInstalled].
     *
     * Bcore's `isInstalled` silently answers from the *host* package manager whenever its
     * own service binder is unhealthy, which made it both false-negative (blocking a
     * perfectly good launch) and false-positive. Attempting the launch and reacting to the
     * real result is the only trustworthy signal; the caller repairs on failure.
     */
    private fun doLaunch(packageName: String, virtualUserId: Int): EngineResult<Unit> {
        return if (BlackBoxCore.get().launchApk(packageName, virtualUserId)) {
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

        /** Comfortably above Bcore's 50 ms service-creation rate limit. */
        const val WARM_UP_MIN_INTERVAL_MS = 1_000L

        /** Matches Bcore's own RETRY_TIMEOUT_MS failure backoff. */
        const val RETRY_TIMEOUT_MS = 2_000L
    }
}
