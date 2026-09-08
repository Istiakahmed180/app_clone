package co.tdevs.duplika.native

import android.content.Context
import co.tdevs.duplika.diagnostics.DiagCategory
import co.tdevs.duplika.diagnostics.DiagLevel
import co.tdevs.duplika.diagnostics.DiagRedactor
import co.tdevs.duplika.diagnostics.DiagSource
import co.tdevs.duplika.diagnostics.DiagnosticLogger
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
    private val spaceIdentity = SpaceIdentityStore(context)

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

    fun initialize(): EngineResult<Unit> {
        phase("ENGINE_INITIALIZATION_STARTED", DiagCategory.APP_LIFECYCLE, "Engine initialization started")
        val result = adapter.initialize(context)
        when (result) {
            is EngineResult.Success -> phase(
                "ENGINE_INITIALIZATION_SUCCESS",
                DiagCategory.APP_LIFECYCLE,
                "Engine reports itself ready (${adapter.backendName})",
                level = DiagLevel.SUCCESS,
            )
            is EngineResult.Failure -> phase(
                "ENGINE_INITIALIZATION_FAILED",
                DiagCategory.APP_LIFECYCLE,
                "Engine initialization failed: ${result.message}",
                level = DiagLevel.ERROR,
                metadata = mapOf("code" to result.code),
            )
        }
        return result
    }

    /**
     * Records one named lifecycle boundary.
     *
     * Named phases rather than free prose: the console's search is only as good as the
     * vocabulary in the log, and `GUEST_PROCESS_FAILED` is something a developer can look
     * for without knowing how the sentence around it was worded. The phase name is carried
     * in metadata so it survives message edits.
     */
    private fun phase(
        event: String,
        category: DiagCategory,
        message: String,
        level: DiagLevel = DiagLevel.INFO,
        packageName: String? = null,
        profileId: String? = null,
        virtualUserId: Int? = null,
        error: Throwable? = null,
        metadata: Map<String, String> = emptyMap(),
    ) {
        DiagnosticLogger.log(
            level = level,
            source = DiagSource.VIRTUAL_ENGINE,
            category = category,
            message = message,
            error = error,
            packageName = packageName,
            profileId = profileId,
            virtualUserId = virtualUserId,
            metadata = metadata + ("event" to event),
        )
    }

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
        requireAvailable()?.let { availability ->
            phase(
                "PACKAGE_INSTALL_FAILED",
                DiagCategory.INSTALL,
                "Install refused: the engine is unavailable (${availability.code})",
                level = DiagLevel.ERROR,
                packageName = packageName,
                profileId = profileId,
                metadata = mapOf("code" to availability.code),
            )
            return availability
        }

        phase(
            "PROFILE_CREATION_STARTED",
            DiagCategory.PROFILE,
            "Allocating a virtual user for this profile",
            profileId = profileId,
            packageName = packageName,
        )
        val virtualUserId = profileManager.getOrCreate(profileId)
        phase(
            "PROFILE_CREATION_SUCCESS",
            DiagCategory.PROFILE,
            "Profile mapped to virtual user $virtualUserId",
            level = DiagLevel.SUCCESS,
            profileId = profileId,
            packageName = packageName,
            virtualUserId = virtualUserId,
        )

        phase(
            "PACKAGE_INSTALL_STARTED",
            DiagCategory.INSTALL,
            "Installing $packageName from the host package manager",
            packageName = packageName,
            profileId = profileId,
            virtualUserId = virtualUserId,
            metadata = mapOf("provisionGms" to provisionGms.toString()),
        )
        val result = installer.install(packageName, virtualUserId, provisionGms)

        // Same reasoning as installApkToProfile: the engine's own verdict is authoritative.
        if (result is EngineResult.Failure) {
            phase(
                "PACKAGE_INSTALL_FAILED",
                DiagCategory.INSTALL,
                "Install of $packageName failed: ${result.message}",
                level = DiagLevel.ERROR,
                packageName = packageName,
                profileId = profileId,
                virtualUserId = virtualUserId,
                metadata = mapOf("code" to result.code),
            )
            releaseProfileArtifacts(profileId)
            phase(
                "PROFILE_CREATION_FAILED",
                DiagCategory.PROFILE,
                "Virtual user $virtualUserId released after a failed install",
                level = DiagLevel.WARNING,
                profileId = profileId,
                packageName = packageName,
                virtualUserId = virtualUserId,
            )
        } else {
            phase(
                "PACKAGE_INSTALL_SUCCESS",
                DiagCategory.INSTALL,
                "Installed $packageName into virtual user $virtualUserId",
                level = DiagLevel.SUCCESS,
                packageName = packageName,
                profileId = profileId,
                virtualUserId = virtualUserId,
            )
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
    fun inspectApk(apkPaths: List<String>): EngineResult<Map<String, Any?>> {
        phase(
            "APK_IMPORT_STARTED",
            DiagCategory.IMPORT,
            "Reading ${apkPaths.size} selected APK file(s)",
            metadata = mapOf(
                "selectedFiles" to apkPaths.size.toString(),
                // Sanitised: the filename is what identifies which archive failed, and
                // the directories above it are the user's business, not a report's.
                "files" to apkPaths.joinToString(", ") { DiagRedactor.sanitizePath(it) },
            ),
        )

        return when (val info = apkImporter.inspect(apkPaths)) {
            is ApkImporter.ApkInfo.Invalid -> {
                phase(
                    "APK_VALIDATION_FAILED",
                    DiagCategory.IMPORT,
                    "APK validation failed: ${info.message}",
                    level = DiagLevel.ERROR,
                    metadata = mapOf("code" to info.code),
                )
                EngineResult.Failure(info.code, info.message)
            }

            is ApkImporter.ApkInfo.Parsed -> {
                phase(
                    "APK_METADATA_PARSED",
                    DiagCategory.IMPORT,
                    "Parsed ${info.packageName} ${info.versionName ?: "?"} " +
                        "(${info.splitApkPaths.size} split(s))",
                    packageName = info.packageName,
                    metadata = mapOf(
                        "versionCode" to info.versionCode.toString(),
                        "baseApk" to DiagRedactor.sanitizePath(info.baseApkPath),
                        "splitCount" to info.splitApkPaths.size.toString(),
                        "splits" to info.splitApkPaths.joinToString(", ") {
                            DiagRedactor.sanitizePath(it)
                        },
                        "installedOnHost" to apkImporter.isInstalledOnHost(info.packageName).toString(),
                    ),
                )
                phase(
                    "APK_VALIDATION_SUCCESS",
                    DiagCategory.IMPORT,
                    "APK set accepted for ${info.packageName}",
                    level = DiagLevel.SUCCESS,
                    packageName = info.packageName,
                )
                EngineResult.Success(
                    mapOf(
                        "packageName" to info.packageName,
                        "appName" to info.appName,
                        "versionName" to info.versionName,
                        "versionCode" to info.versionCode.toString(),
                        "installedOnHost" to apkImporter.isInstalledOnHost(info.packageName),
                        "apkPaths" to info.apkPaths,
                        "baseApkPath" to info.baseApkPath,
                        "splitApkPaths" to info.splitApkPaths,
                    ),
                )
            }
        }
    }

    /**
     * Creates the virtual user if needed and installs an imported APK into it.
     *
     * Mirrors [installAppToProfile], including releasing the mapping when the install
     * fails so a profile is never left pointing at an empty container.
     */
    fun installApkToProfile(
        profileId: String,
        apkPaths: List<String>,
        packageName: String,
        provisionGms: Boolean,
    ): EngineResult<Unit> {
        requireAvailable()?.let { availability ->
            phase(
                "PACKAGE_INSTALL_FAILED",
                DiagCategory.INSTALL,
                "APK install refused: the engine is unavailable (${availability.code})",
                level = DiagLevel.ERROR,
                packageName = packageName,
                profileId = profileId,
                metadata = mapOf("code" to availability.code),
            )
            return availability
        }

        val virtualUserId = profileManager.getOrCreate(profileId)
        phase(
            "PROFILE_CREATION_SUCCESS",
            DiagCategory.PROFILE,
            "Profile mapped to virtual user $virtualUserId",
            level = DiagLevel.SUCCESS,
            profileId = profileId,
            packageName = packageName,
            virtualUserId = virtualUserId,
        )

        // The picker hands back a cache copy, which the system may reclaim. Keep our own
        // copy so a lost container can be rebuilt later without re-picking the file.
        val retained = retainApks(profileId, apkPaths) ?: apkPaths
        phase(
            "PACKAGE_INSTALL_STARTED",
            DiagCategory.INSTALL,
            "Installing an imported APK set for $packageName",
            packageName = packageName,
            profileId = profileId,
            virtualUserId = virtualUserId,
            metadata = mapOf(
                "apkCount" to retained.size.toString(),
                "retainedCopy" to (retained !== apkPaths).toString(),
                "provisionGms" to provisionGms.toString(),
            ),
        )
        // Split installs are the Level 7 path, and "which archive went in" is the first
        // question when one of them is the wrong ABI or a duplicate split.
        retained.forEachIndexed { index, path ->
            phase(
                if (index == 0) "BASE_APK_INSTALL" else "SPLIT_APK_INSTALL",
                DiagCategory.INSTALL,
                (if (index == 0) "Base APK: " else "Split APK: ") + DiagRedactor.sanitizePath(path),
                level = DiagLevel.DEBUG,
                packageName = packageName,
                profileId = profileId,
                virtualUserId = virtualUserId,
                metadata = mapOf("index" to index.toString()),
            )
        }
        val result = installer.installApks(retained, packageName, virtualUserId, provisionGms)

        // No isInstalled() guard here: it answers from the host package manager when the
        // engine's service is unhealthy, so for an APK whose package is also installed
        // normally it would report success and leave an orphan profile behind. If the
        // engine said the install failed, treat it as failed.
        if (result is EngineResult.Failure) {
            phase(
                "PACKAGE_INSTALL_FAILED",
                DiagCategory.INSTALL,
                "APK install of $packageName failed: ${result.message}",
                level = DiagLevel.ERROR,
                packageName = packageName,
                profileId = profileId,
                virtualUserId = virtualUserId,
                metadata = mapOf("code" to result.code, "apkCount" to retained.size.toString()),
            )
            releaseProfileArtifacts(profileId)
        } else {
            phase(
                "PACKAGE_INSTALL_SUCCESS",
                DiagCategory.INSTALL,
                "Installed imported $packageName into virtual user $virtualUserId",
                level = DiagLevel.SUCCESS,
                packageName = packageName,
                profileId = profileId,
                virtualUserId = virtualUserId,
                metadata = mapOf("apkCount" to retained.size.toString()),
            )
        }
        return result
    }

    /** Drops the user mapping and any retained APK for a profile that never came up. */
    private fun releaseProfileArtifacts(profileId: String) {
        profileManager.apkPathsFor(profileId).forEach { path ->
            if (!File(path).delete() && File(path).exists()) {
                Slog.w(Slog.INSTALL, "Could not delete retained APK for $profileId: $path")
            }
        }
        profileManager.forgetApkPaths(profileId)
        profileManager.remove(profileId)
    }

    private fun retainApks(profileId: String, apkPaths: List<String>): List<String>? = try {
        val store = File(context.filesDir, "imported_apks").apply { mkdirs() }
        val profileStore = File(store, profileId).apply { mkdirs() }
        val retained = apkPaths.mapIndexed { index, apkPath ->
            val target = File(profileStore, "${index}_${File(apkPath).name}")
            File(apkPath).inputStream().use { input ->
                target.outputStream().use(input::copyTo)
            }
            target.absolutePath
        }
        profileManager.rememberApkPaths(profileId, retained)
        retained
    } catch (error: Throwable) {
        Slog.w(Slog.INSTALL, "Could not retain imported APK: ${error.message}")
        null
    }

    /**
     * Empties this clone's container: the next launch is a first launch.
     *
     * The package stays installed, so this is not the same as deleting the profile — the
     * clone and its virtual user survive, only what the guest wrote is gone.
     */
    fun clearProfileData(profileId: String, packageName: String): EngineResult<Unit> {
        val virtualUserId = profileManager.virtualUserIdFor(profileId)
            ?: return EngineResult.Failure(
                EngineErrorCodes.VIRTUAL_APP_NOT_INSTALLED,
                "This profile has no virtual environment.",
            )

        // Stopped first: clearing the data underneath a running guest leaves it holding
        // handles to files that no longer exist, which it experiences as corruption.
        launcher.stop(packageName, virtualUserId)
        val result = adapter.clearPackageData(packageName, virtualUserId)
        phase(
            if (result is EngineResult.Success) "PROFILE_DATA_CLEARED" else "PROFILE_DATA_CLEAR_FAILED",
            DiagCategory.PROFILE,
            if (result is EngineResult.Success) {
                "Cleared all data for $packageName in virtual user $virtualUserId"
            } else {
                "Could not clear data for $packageName"
            },
            level = if (result is EngineResult.Success) DiagLevel.SUCCESS else DiagLevel.ERROR,
            packageName = packageName,
            profileId = profileId,
            virtualUserId = virtualUserId,
        )
        return result
    }

    /** Empties only this clone's caches; logins and settings survive. */
    fun clearProfileCache(profileId: String, packageName: String): EngineResult<Unit> {
        val virtualUserId = profileManager.virtualUserIdFor(profileId)
            ?: return EngineResult.Failure(
                EngineErrorCodes.VIRTUAL_APP_NOT_INSTALLED,
                "This profile has no virtual environment.",
            )

        val result = adapter.clearPackageCache(packageName, virtualUserId)
        phase(
            if (result is EngineResult.Success) "PROFILE_CACHE_CLEARED" else "PROFILE_CACHE_CLEAR_FAILED",
            DiagCategory.STORAGE,
            if (result is EngineResult.Success) {
                "Cleared the cache for $packageName in virtual user $virtualUserId"
            } else {
                "Could not clear the cache for $packageName"
            },
            level = if (result is EngineResult.Success) DiagLevel.SUCCESS else DiagLevel.WARNING,
            packageName = packageName,
            profileId = profileId,
            virtualUserId = virtualUserId,
        )
        return result
    }

    /**
     * The identifiers this space presents as its own.
     *
     * [action] is `read`, `regenerate` or `reset`. A space with no container yet has no
     * virtual user to key the set on, so it is allocated first — the same allocation a
     * launch would do, and it is what makes the identity stable from here on.
     */
    fun spaceIdentity(profileId: String, action: String): EngineResult<Map<String, Any?>> {
        val virtualUserId = profileManager.virtualUserIdFor(profileId)
            ?: return EngineResult.Failure(
                EngineErrorCodes.VIRTUAL_APP_NOT_INSTALLED,
                "This profile has no virtual environment yet.",
            )

        val identity = when (action) {
            "regenerate" -> spaceIdentity.regenerate(profileId, virtualUserId)
            "reset" -> spaceIdentity.reset(profileId, virtualUserId)
            else -> spaceIdentity.identity(profileId, virtualUserId)
        }

        if (action != "read") {
            phase(
                if (action == "reset") "SPACE_IDENTITY_RESET" else "SPACE_IDENTITY_REGENERATED",
                DiagCategory.PROFILE,
                "Space identity ${if (action == "reset") "reset" else "regenerated"} " +
                    "for virtual user $virtualUserId (revision ${identity.revision})",
                level = DiagLevel.SUCCESS,
                profileId = profileId,
                virtualUserId = virtualUserId,
            )
        }
        return EngineResult.Success(identity.toMap())
    }

    /** Offers this clone's APK to the share sheet. */
    fun shareProfileApk(
        profileId: String,
        packageName: String,
        label: String,
    ): EngineResult<Unit> = AppSharer(context).share(profileId, packageName, label)

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
        phase(
            "ACTIVITY_LAUNCH_STARTED",
            DiagCategory.LAUNCH,
            "Launch requested for $packageName",
            packageName = packageName,
            profileId = profileId,
        )

        requireAvailable()?.let { availability ->
            phase(
                "ACTIVITY_LAUNCH_FAILED",
                DiagCategory.LAUNCH,
                "Launch refused: the engine is unavailable (${availability.code})",
                level = DiagLevel.ERROR,
                packageName = packageName,
                profileId = profileId,
                metadata = mapOf("code" to availability.code),
            )
            return availability
        }

        val virtualUserId = profileManager.virtualUserIdFor(profileId)
        if (virtualUserId == null) {
            phase(
                "ACTIVITY_LAUNCH_FAILED",
                DiagCategory.LAUNCH,
                "This profile has no virtual user mapping",
                level = DiagLevel.ERROR,
                packageName = packageName,
                profileId = profileId,
                metadata = mapOf("code" to EngineErrorCodes.VIRTUAL_APP_NOT_INSTALLED),
            )
            return EngineResult.Failure(
                EngineErrorCodes.VIRTUAL_APP_NOT_INSTALLED,
                "This profile has no virtual environment yet.",
            )
        }

        phase(
            "GUEST_PROCESS_STARTING",
            DiagCategory.PROCESS,
            "Starting $packageName in virtual user $virtualUserId",
            packageName = packageName,
            profileId = profileId,
            virtualUserId = virtualUserId,
        )
        val first = launcher.launch(packageName, virtualUserId)
        if (first is EngineResult.Success) {
            phase(
                "GUEST_PROCESS_STARTED",
                DiagCategory.PROCESS,
                "Guest process accepted the launch of $packageName",
                level = DiagLevel.SUCCESS,
                packageName = packageName,
                profileId = profileId,
                virtualUserId = virtualUserId,
            )
            phase(
                "ACTIVITY_LAUNCH_SUCCESS",
                DiagCategory.LAUNCH,
                "Launched $packageName",
                level = DiagLevel.SUCCESS,
                packageName = packageName,
                profileId = profileId,
                virtualUserId = virtualUserId,
            )
            return first
        }

        phase(
            "GUEST_PROCESS_FAILED",
            DiagCategory.PROCESS,
            "First launch attempt failed: ${(first as EngineResult.Failure).message}",
            level = DiagLevel.WARNING,
            packageName = packageName,
            profileId = profileId,
            virtualUserId = virtualUserId,
            metadata = mapOf("code" to first.code, "attempt" to "1"),
        )

        // The container may have been dropped by the engine; rebuild it and try once more.
        repair(profileId, packageName, virtualUserId)?.let { repairFailure ->
            phase(
                "ACTIVITY_LAUNCH_FAILED",
                DiagCategory.LAUNCH,
                "Container rebuild failed: ${repairFailure.message}",
                level = DiagLevel.ERROR,
                packageName = packageName,
                profileId = profileId,
                virtualUserId = virtualUserId,
                metadata = mapOf("code" to repairFailure.code),
            )
            return repairFailure
        }

        val second = launcher.launch(packageName, virtualUserId)
        when (second) {
            is EngineResult.Success -> {
                phase(
                    "ACTIVITY_LAUNCH_SUCCESS",
                    DiagCategory.LAUNCH,
                    "Launched $packageName after rebuilding its container",
                    level = DiagLevel.SUCCESS,
                    packageName = packageName,
                    profileId = profileId,
                    virtualUserId = virtualUserId,
                    metadata = mapOf("attempt" to "2"),
                )
            }
            is EngineResult.Failure -> {
                phase(
                    "ACTIVITY_LAUNCH_FAILED",
                    DiagCategory.LAUNCH,
                    "Launch of $packageName failed after a rebuild: ${second.message}",
                    level = DiagLevel.ERROR,
                    packageName = packageName,
                    profileId = profileId,
                    virtualUserId = virtualUserId,
                    metadata = mapOf("code" to second.code, "attempt" to "2"),
                )
            }
        }
        return second
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
        phase(
            "GUEST_RELAUNCH",
            DiagCategory.LAUNCH,
            "Rebuilding the container for $packageName before a second launch attempt",
            level = DiagLevel.WARNING,
            packageName = packageName,
            profileId = profileId,
            virtualUserId = virtualUserId,
        )

        // Rebuild without re-provisioning GMS. The per-clone opt-in is not persisted, so
        // this recovery path cannot know whether the clone had it; re-provisioning
        // unconditionally would add the (currently non-functional, SERVICE_INVALID) Google
        // packages and their background crashes to a clone that may never have asked for
        // them. If GMS is persisted per profile later, thread that flag through here.
        val retainedApks = profileManager.apkPathsFor(profileId)
        val result = if (retainedApks.isNotEmpty() && retainedApks.all { File(it).isFile }) {
            installer.installApks(retainedApks, packageName, virtualUserId, provisionGms = false)
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
        phase(
            "GUEST_CLOSE",
            DiagCategory.PROCESS,
            "Stopping $packageName in virtual user $virtualUserId",
            packageName = packageName,
            profileId = profileId,
            virtualUserId = virtualUserId,
        )
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
        // Before the id is released: VirtualProfileManager allocates the lowest free
        // integer, so a later clone would otherwise inherit this space's identifiers.
        spaceIdentity.forget(virtualUserId)
        val deletion = adapter.deleteVirtualUser(virtualUserId)
        releaseProfileArtifacts(profileId)
        phase(
            if (deletion is EngineResult.Success) "PROFILE_DELETE_SUCCESS" else "PROFILE_DELETE_FAILED",
            DiagCategory.PROFILE,
            if (deletion is EngineResult.Success) {
                "Removed the virtual environment for virtual user $virtualUserId"
            } else {
                "Could not remove virtual user $virtualUserId: " +
                    (deletion as EngineResult.Failure).message
            },
            level = if (deletion is EngineResult.Success) DiagLevel.SUCCESS else DiagLevel.ERROR,
            packageName = packageName,
            profileId = profileId,
            virtualUserId = virtualUserId,
        )
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
