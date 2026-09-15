package co.tdevs.duplika.native.blackbox

import android.app.Application
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import java.io.File
import co.tdevs.duplika.native.EngineAvailability
import co.tdevs.duplika.native.EngineErrorCodes
import co.tdevs.duplika.native.EngineResult
import co.tdevs.duplika.native.LaunchComponentResolver
import co.tdevs.duplika.native.Slog
import co.tdevs.duplika.native.VirtualizationEngineAdapter
import top.niunaijun.blackbox.BlackBoxCore
import top.niunaijun.blackbox.app.configuration.ClientConfiguration
import top.niunaijun.blackbox.core.env.BEnvironment

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
            Slog.i(Slog.BCORE, "Engine attached in process ${application.packageName}")
        } catch (error: Throwable) {
            // A failure here must not take the host UI down; checkAvailability reports it.
            initialized = false
            Slog.e(Slog.BCORE, "Engine attach failed", error)
        }
    }

    override fun onCreate(application: Application) {
        if (!initialized) return
        try {
            BlackBoxCore.get().doCreate()
            warmUpPackageService()
            Slog.i(Slog.BCORE, "Engine created")
        } catch (error: Throwable) {
            initialized = false
            Slog.e(Slog.BCORE, "Engine create failed", error)
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
            Slog.w(Slog.BCORE, "Package service warm-up failed: ${error.message}")
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
            Slog.w(Slog.BCORE, "Engine gave no response; retrying after service backoff")
        } catch (error: Throwable) {
            Slog.w(Slog.BCORE, "Engine service unavailable (${error.javaClass.simpleName}); retrying")
        }

        SystemClock.sleep(RETRY_TIMEOUT_MS + 200L)
        warmUpPackageService(force = true)
        return try {
            block()
        } catch (error: Throwable) {
            Slog.e(Slog.BCORE, "Engine service still unavailable after retry", error)
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
        Slog.w(Slog.BCORE, "No response from the engine for $what")
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

    override fun installApkFiles(apkPaths: List<String>, virtualUserId: Int): EngineResult<Unit> =
        guarded(EngineErrorCodes.APP_INSTALL_FAILED) {
            withServiceRetry {
                warmUpPackageService()
                doInstallApks(apkPaths, virtualUserId)
            }
        }

    private fun doInstallApks(apkPaths: List<String>, virtualUserId: Int): EngineResult<Unit> {
        if (apkPaths.isEmpty()) {
            return EngineResult.Failure(EngineErrorCodes.APK_INVALID, "No APKs were selected.")
        }
        apkPaths.forEach { apkPath ->
            if (!File(apkPath).isFile) {
                return EngineResult.Failure(
                    EngineErrorCodes.APK_UNREADABLE,
                    "One of the selected APKs could not be read.",
                )
            }
        }
        val base = File(apkPaths.first())
        val splits = apkPaths.drop(1).map(::File).toTypedArray()
        val result = BlackBoxCore.get().installPackageSetAsUser(base, splits, virtualUserId)
            ?: return noResponse("APK package set install into user $virtualUserId")
        if (!result.success) {
            val reason = result.msg ?: "the engine refused the APK package set"
            Slog.e(Slog.INSTALL, "APK package set install failed: $reason")
            return EngineResult.Failure(EngineErrorCodes.APP_INSTALL_FAILED, reason)
        }
        Slog.i(Slog.INSTALL, "Installed APK package set ${result.packageName} into user $virtualUserId")
        return EngineResult.ok()
    }

    override fun uninstallPackage(packageName: String, virtualUserId: Int): EngineResult<Unit> =
        guarded(EngineErrorCodes.PROFILE_DELETE_FAILED) {
            BlackBoxCore.get().uninstallPackageAsUser(packageName, virtualUserId)
            EngineResult.ok()
        }

    override fun clearPackageData(packageName: String, virtualUserId: Int): EngineResult<Unit> =
        guarded(EngineErrorCodes.CLEAR_DATA_FAILED) {
            // Bcore's own API, which also drops the container's cache directories.
            BlackBoxCore.get().clearPackage(packageName, virtualUserId)
            Slog.i(Slog.INSTALL, "Cleared data for $packageName in user $virtualUserId")
            EngineResult.ok()
        }

    /**
     * Deletes the container's cache directories and nothing else.
     *
     * Bcore has no cache-only API, so the two directories are emptied directly. Their
     * paths come from [BEnvironment], which is Bcore's own public accessor for them —
     * the layout is not guessed or reflected into, and this stays inside the one file
     * allowed to know the backend.
     *
     * A missing directory is success, not failure: a guest that has never run has no
     * cache to clear.
     */
    override fun clearPackageCache(packageName: String, virtualUserId: Int): EngineResult<Unit> =
        guarded(EngineErrorCodes.CLEAR_CACHE_FAILED) {
            val targets = listOf(
                runCatching { BEnvironment.getDataCacheDir(packageName, virtualUserId) }.getOrNull(),
                runCatching {
                    BEnvironment.getExternalDataCacheDir(packageName, virtualUserId)
                }.getOrNull(),
            )

            var failed = 0
            targets.filterNotNull().forEach { directory ->
                if (directory.exists() && !directory.deleteRecursively()) {
                    failed++
                    Slog.w(Slog.INSTALL, "Could not fully clear cache at ${directory.name}")
                }
            }

            if (failed > 0) {
                EngineResult.Failure(
                    EngineErrorCodes.CLEAR_CACHE_FAILED,
                    "Part of this clone's cache could not be deleted.",
                )
            } else {
                Slog.i(Slog.INSTALL, "Cleared cache for $packageName in user $virtualUserId")
                EngineResult.ok()
            }
        }

    override fun isPackageInstalled(packageName: String, virtualUserId: Int): Boolean =
        runCatching {
            BlackBoxCore.get().isInstalled(packageName, virtualUserId)
        }.getOrDefault(false)

    /**
     * Bcore's own accessor for the container's data directory, so the layout is not guessed.
     * A container that has never run has no file; callers treat null and a missing file the
     * same way.
     */
    override fun guestSharedPreferencesFile(
        packageName: String,
        virtualUserId: Int,
        preferenceName: String,
    ): File? = runCatching {
        File(
            BEnvironment.getDataDir(packageName, virtualUserId),
            "shared_prefs/$preferenceName.xml",
        )
    }.getOrNull()

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
        launchByResolvedComponent(packageName, virtualUserId)?.let { return it }
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

    /**
     * Starts the clone at the component the *platform* would pick, bypassing Bcore's own
     * resolution — see [LaunchComponentResolver] for the two manifest shapes it gets
     * wrong and the crash loop that follows.
     *
     * Returns null when the component cannot be resolved, which hands the launch back to
     * [BlackBoxCore.launchApk] unchanged. `launchApk` is otherwise only
     * `getLaunchIntentForPackage` followed by `startActivity`, so replacing it costs
     * nothing but the resolution itself; its pre-launch hook is invoked here so guests
     * still see the callback they would have seen.
     */
    private fun launchByResolvedComponent(
        packageName: String,
        virtualUserId: Int,
    ): EngineResult<Unit>? {
        val core = BlackBoxCore.get()
        val component = runCatching {
            LaunchComponentResolver.resolve(
                BlackBoxCore.getContext().packageManager,
                packageName,
            )
        }.getOrNull() ?: return null

        core.onBeforeMainLaunchApk(packageName, virtualUserId)
        val intent = Intent(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_LAUNCHER)
            .setComponent(component)
            .setFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        core.startActivity(intent, virtualUserId)
        Slog.i(
            Slog.LAUNCH,
            "Launched $packageName in user $virtualUserId at ${component.className}",
        )
        return EngineResult.ok()
    }

    override fun startContainerService(
        packageName: String,
        serviceClassName: String,
        virtualUserId: Int,
        requireForeground: Boolean,
        action: String?,
    ): EngineResult<Unit> = guarded(EngineErrorCodes.CONTAINER_SERVICE_START_FAILED) {
        withServiceRetry {
            warmUpPackageService()
            doStartContainerService(
                packageName,
                serviceClassName,
                virtualUserId,
                requireForeground,
                action,
            )
        }
    }

    private fun doStartContainerService(
        packageName: String,
        serviceClassName: String,
        virtualUserId: Int,
        requireForeground: Boolean,
        action: String?,
    ): EngineResult<Unit> {
        val intent = Intent().setClassName(packageName, serviceClassName)
        if (action != null) intent.action = action
        val resolved = BlackBoxCore.getBActivityManager()
            .startService(intent, null, requireForeground, virtualUserId)
        // A null answer is not a refusal. Measured with microG's MCS service: Bcore's
        // startService returned null and the service still started, connected to
        // mtalk.google.com and logged in. Only a thrown exception is treated as a failure.
        Slog.i(
            Slog.LAUNCH,
            "Requested $packageName/$serviceClassName in user $virtualUserId " +
                "(engine answered ${resolved ?: "nothing"})",
        )
        return EngineResult.ok()
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
        Slog.e(Slog.BCORE, "Engine call failed ($code)", error)
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
