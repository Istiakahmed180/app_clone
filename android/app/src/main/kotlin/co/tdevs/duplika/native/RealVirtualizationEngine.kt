package co.tdevs.duplika.native

import android.content.Context
import java.io.File

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
    private val analyzer = AppCompatibilityAnalyzer(context)
    private val installer = VirtualAppInstaller(context, adapter, securityChecker, analyzer)
    private val launcher = VirtualAppLauncher(adapter)
    private val installedApps = InstalledAppsProvider(context)
    private val apkImporter = ApkImporter(context)

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
    fun installAppToProfile(
        profileId: String,
        packageName: String,
        provisionGms: Boolean,
    ): EngineResult<Unit> {
        requireAvailable()?.let { return it }

        val virtualUserId = profileManager.getOrCreate(profileId)
        val result = installer.install(packageName, virtualUserId, provisionGms)

        // Same reasoning as installApkToProfile: the engine's own verdict is authoritative.
        if (result is EngineResult.Failure) {
            releaseProfileArtifacts(profileId)
        }
        return result
    }

    fun listInstalledApps(includeIcons: Boolean): List<Map<String, Any?>> =
        installedApps.listLaunchableApps(includeIcons)

    fun appIconsFor(packageNames: Collection<String>): Map<String, String> =
        installedApps.iconsFor(packageNames)

    fun analyzeApk(apkPath: String, packageName: String): Map<String, Any?> =
        analyzer.analyzeApk(apkPath, packageName).toMap()

    fun describeApp(packageName: String): Map<String, Any?>? =
        installedApps.describeInstalled(packageName)

    /** Reads an imported APK's identity so the UI can confirm before installing. */
    fun inspectApk(apkPath: String): EngineResult<Map<String, Any?>> =
        when (val info = apkImporter.inspect(apkPath)) {
            is ApkImporter.ApkInfo.Invalid -> EngineResult.Failure(info.code, info.message)
            is ApkImporter.ApkInfo.Parsed -> EngineResult.Success(
                mapOf(
                    "packageName" to info.packageName,
                    "appName" to info.appName,
                    "versionName" to info.versionName,
                    "versionCode" to info.versionCode.toString(),
                    "installedOnHost" to apkImporter.isInstalledOnHost(info.packageName),
                ),
            )
        }

    /**
     * Creates the virtual user if needed and installs an imported APK into it.
     *
     * Mirrors [installAppToProfile], including releasing the mapping when the install
     * fails so a profile is never left pointing at an empty container.
     */
    fun installApkToProfile(
        profileId: String,
        apkPath: String,
        packageName: String,
        provisionGms: Boolean,
    ): EngineResult<Unit> {
        requireAvailable()?.let { return it }

        val virtualUserId = profileManager.getOrCreate(profileId)

        // The picker hands back a cache copy, which the system may reclaim. Keep our own
        // copy so a lost container can be rebuilt later without re-picking the file.
        val retained = retainApk(profileId, apkPath) ?: apkPath
        val result = installer.installApk(retained, packageName, virtualUserId, provisionGms)

        // No isInstalled() guard here: it answers from the host package manager when the
        // engine's service is unhealthy, so for an APK whose package is also installed
        // normally it would report success and leave an orphan profile behind. If the
        // engine said the install failed, treat it as failed.
        if (result is EngineResult.Failure) {
            releaseProfileArtifacts(profileId)
        }
        return result
    }

    /** Drops the user mapping and any retained APK for a profile that never came up. */
    private fun releaseProfileArtifacts(profileId: String) {
        profileManager.apkPathFor(profileId)?.let { path ->
            if (!File(path).delete()) {
                Slog.w(Slog.INSTALL, "Could not delete retained APK for $profileId")
            }
        }
        profileManager.forgetApkPath(profileId)
        profileManager.remove(profileId)
    }

    private fun retainApk(profileId: String, apkPath: String): String? = try {
        val store = File(context.filesDir, "imported_apks").apply { mkdirs() }
        val target = File(store, "$profileId.apk")
        File(apkPath).inputStream().use { input ->
            target.outputStream().use(input::copyTo)
        }
        profileManager.rememberApkPath(profileId, target.absolutePath)
        target.absolutePath
    } catch (error: Throwable) {
        Slog.w(Slog.INSTALL, "Could not retain imported APK: ${error.message}")
        null
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

        val first = launcher.launch(packageName, virtualUserId)
        if (first is EngineResult.Success) {
            return first
        }

        // The container may have been dropped by the engine; rebuild it and try once more.
        repair(profileId, packageName, virtualUserId)?.let { return it }
        return launcher.launch(packageName, virtualUserId)
    }

    /**
     * Rebuilds a container the engine has forgotten.
     *
     * Bcore only makes a per-user install record durable once the guest has actually run
     * in that user, so creating several clones before launching any of them can lose the
     * earlier records. Rather than depend on the user launching in a particular order, a
     * failed launch rebuilds its own container and retries. Returns a failure only if the
     * rebuild itself fails.
     */
    private fun repair(
        profileId: String,
        packageName: String,
        virtualUserId: Int,
    ): EngineResult.Failure? {
        Slog.w(Slog.INSTALL, "Launch failed for user $virtualUserId; rebuilding container")

        // Rebuild without re-provisioning GMS. The per-clone opt-in is not persisted, so
        // this recovery path cannot know whether the clone had it; re-provisioning
        // unconditionally would add the (currently non-functional, SERVICE_INVALID) Google
        // packages and their background crashes to a clone that may never have asked for
        // them. If GMS is persisted per profile later, thread that flag through here.
        val retainedApk = profileManager.apkPathFor(profileId)
        val result = if (retainedApk != null && File(retainedApk).isFile) {
            installer.installApk(retainedApk, packageName, virtualUserId, provisionGms = false)
        } else {
            installer.install(packageName, virtualUserId, provisionGms = false)
        }

        return when (result) {
            is EngineResult.Success -> null
            is EngineResult.Failure -> EngineResult.Failure(
                result.code,
                "This clone's data could not be restored: ${result.message}",
            )
        }
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

        // A pinned shortcut outlives the clone; an app cannot delete one, so disable it
        // with a reason rather than leaving a tile that silently does nothing.
        CloneShortcutManager(context).disable(
            profileId,
            "This clone was deleted in Duplika.",
        )

        launcher.stop(packageName, virtualUserId)
        installer.uninstall(packageName, virtualUserId)
        val deletion = adapter.deleteVirtualUser(virtualUserId)
        releaseProfileArtifacts(profileId)
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
