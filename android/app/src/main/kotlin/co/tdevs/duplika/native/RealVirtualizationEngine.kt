package co.tdevs.duplika.native

import android.content.Context
import co.tdevs.duplika.diagnostics.DiagCategory
import co.tdevs.duplika.diagnostics.DiagLevel
import co.tdevs.duplika.diagnostics.DiagRedactor
import co.tdevs.duplika.diagnostics.DiagSource
import co.tdevs.duplika.diagnostics.DiagnosticLogger
import co.tdevs.duplika.native.gms.MicroGProvider
import co.tdevs.duplika.native.gms.ProviderResult
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
    private val microGProvider = MicroGProvider.forEngine(context, adapter)

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
            discardFailedInstall(profileId, virtualUserId, packageName)
        } else {
            seedChromeOnboardingComplete(packageName, virtualUserId)
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

    /** The picker's payload: the clonable apps, and how many were left out. */
    fun listInstalledApps(includeIcons: Boolean): Map<String, Any?> =
        installedApps.listLaunchableApps(includeIcons)

    fun appIconsFor(packageNames: Collection<String>): Map<String, String> =
        installedApps.iconsFor(packageNames)

    fun analyzeApk(apkPaths: List<String>, packageName: String): Map<String, Any?> =
        analyzer.analyzeApk(apkPaths, packageName).toMap()

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
    /**
     * Provisions the bundled microG into an existing profile's container as its
     * `com.google.android.gms`.
     *
     * Separate from the retired host-GMS provisioning on purpose: this installs Duplika's
     * own Apache-2.0 microG artefact, not a copy of the host's Play services. It is exposed
     * as an explicit action rather than an AUTO-selected behaviour, because choosing microG
     * changes which implementation a guest sees for *every* Google API.
     */
    fun provisionMicroG(profileId: String): EngineResult<Unit> {
        val virtualUserId = profileManager.getOrCreate(profileId)
        return when (val result = microGProvider.provisionContainerGms(virtualUserId)) {
            is ProviderResult.Success -> EngineResult.ok()
            is ProviderResult.Error -> EngineResult.Failure(result.code, result.message)
            else -> EngineResult.Failure("MICROG_PROVISIONING_FAILED", result.reasonOrEmpty)
        }
    }

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
            discardFailedInstall(profileId, virtualUserId, packageName)
        } else {
            seedChromeOnboardingComplete(packageName, virtualUserId)
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

    /** Drops the retained APKs of a profile whose container is going away. */
    private fun releaseRetainedApks(profileId: String) {
        profileManager.apkPathsFor(profileId).forEach { path ->
            if (!File(path).delete() && File(path).exists()) {
                Slog.w(Slog.INSTALL, "Could not delete retained APK for $profileId: $path")
            }
        }
        profileManager.forgetApkPaths(profileId)
    }

    /**
     * Tears down the container of an install that failed, then releases its id.
     *
     * Provisioning runs *before* the package install (see [VirtualAppInstaller]), so by
     * the time an install fails the container can already hold microG and a partly
     * written package. The Flutter side throws this profile id away the moment the install
     * fails, so nobody will ever retry it — but the id itself goes back into the pool, and
     * handing the next clone a container full of a previous attempt's state is how a space
     * ends up with data that was never its own.
     *
     * When the engine will not remove the container the id is quarantined instead of
     * freed: the profile is gone either way, but the id must never be allocated again.
     */
    private fun discardFailedInstall(
        profileId: String,
        virtualUserId: Int,
        packageName: String,
    ) {
        launcher.stop(packageName, virtualUserId)
        uninstallForTeardown(packageName, virtualUserId)
        val deletion = adapter.deleteVirtualUser(virtualUserId)
        spaceIdentity.forget(virtualUserId)
        releaseRetainedApks(profileId)

        if (deletion is EngineResult.Success) {
            profileManager.remove(profileId)
            phase(
                "PROFILE_CREATION_FAILED",
                DiagCategory.PROFILE,
                "Virtual user $virtualUserId released after a failed install",
                level = DiagLevel.WARNING,
                packageName = packageName,
                profileId = profileId,
                virtualUserId = virtualUserId,
            )
            return
        }
        profileManager.quarantine(profileId)
        phase(
            "PROFILE_CREATION_FAILED",
            DiagCategory.PROFILE,
            "Virtual user $virtualUserId could not be removed after a failed install " +
                "(${(deletion as EngineResult.Failure).message}); its id is reserved so no " +
                "later clone can be allocated into that container",
            level = DiagLevel.ERROR,
            packageName = packageName,
            profileId = profileId,
            virtualUserId = virtualUserId,
        )
    }

    /**
     * Uninstalls a package on the way to removing its container.
     *
     * The verdict cannot change what happens next — the virtual user is being deleted
     * regardless — but a silent failure here is the first sign of a container that will
     * outlive its profile, so it is recorded.
     */
    private fun uninstallForTeardown(packageName: String, virtualUserId: Int) {
        val result = installer.uninstall(packageName, virtualUserId)
        if (result is EngineResult.Failure) {
            Slog.w(
                Slog.INSTALL,
                "Uninstall of $packageName from user $virtualUserId failed " +
                    "(${result.code}); removing the virtual user anyway",
            )
        }
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
    /**
     * Reads, replaces or regenerates one space's identifier set.
     *
     * [values] is only read for `"update"`, and only the five identifier keys are taken
     * from it; anything else in the map is ignored rather than trusted.
     */
    fun spaceIdentity(
        profileId: String,
        action: String,
        values: Map<String, String> = emptyMap(),
    ): EngineResult<Map<String, Any?>> {
        val virtualUserId = profileManager.virtualUserIdFor(profileId)
            ?: return EngineResult.Failure(
                EngineErrorCodes.VIRTUAL_APP_NOT_INSTALLED,
                "This profile has no virtual environment yet.",
            )

        val identity = when (action) {
            "regenerate" -> spaceIdentity.regenerate(profileId, virtualUserId)
            "update" -> spaceIdentity.update(profileId, virtualUserId, values)
                .getOrElse { error ->
                    return EngineResult.Failure(
                        EngineErrorCodes.SPACE_IDENTITY_INVALID,
                        error.message ?: "That identifier is not well-formed.",
                    )
                }
            else -> spaceIdentity.identity(profileId, virtualUserId)
        }

        if (action != "read") {
            phase(
                if (action == "update") "SPACE_IDENTITY_EDITED" else "SPACE_IDENTITY_REGENERATED",
                DiagCategory.PROFILE,
                "Space identity ${if (action == "update") "edited" else "regenerated"} " +
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

    /**
     * Shares a host-installed app's own APK, with no profile involved.
     *
     * The empty profile id is deliberate: [AppSharer] looks for an imported archive
     * retained for a clone first, and there is no clone here, so it falls through to the
     * host's own `sourceDir`.
     */
    fun shareInstalledApk(packageName: String, label: String): EngineResult<Unit> =
        AppSharer(context).share(profileId = "", packageName = packageName, label = label)

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
            // The clone now owns the foreground, so the host is about to go background and
            // an aggressive OEM would otherwise kill it — measured on OnePlus. The service
            // stops when the user comes back to Duplika.
            CloneKeepAliveService.start(context, packageName, virtualUserId)
            // Open microG's push receive connection for this container. microG only connects
            // to mtalk.google.com when its MCS service is started, and without that
            // connection Google accepts a message but never delivers it. Done on every
            // launch because the connection dies with the guest process; a container with no
            // microG simply reports false and is unaffected.
            microGProvider.wakeReceiveChannel(virtualUserId)
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

        launcher.stop(packageName, virtualUserId)
        uninstallForTeardown(packageName, virtualUserId)
        val deletion = adapter.deleteVirtualUser(virtualUserId)

        // Only once the engine has actually released the container. VirtualProfileManager
        // allocates the lowest free integer, so freeing the id while this space's data is
        // still on disk would hand that data — and its identifiers — to the next clone.
        //
        // Leaving the mapping in place on failure is also what makes a retry work: the
        // Flutter side keeps the profile visible precisely so the user can try again (see
        // RealVirtualizationEngine.deleteProfile in Dart), and a retry can only reach this
        // container while the mapping still points at it.
        if (deletion is EngineResult.Success) {
            // A pinned shortcut outlives the clone; an app cannot delete one, so disable
            // it with a reason rather than leaving a tile that silently does nothing.
            CloneShortcutManager(context).disable(
                profileId,
                "This clone was deleted in Duplika.",
            )
            spaceIdentity.forget(virtualUserId)
            releaseRetainedApks(profileId)
            profileManager.remove(profileId)
        }
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

    /**
     * Marks Chrome's first run as already complete in a fresh container, so Chrome opens on
     * the New Tab page instead of showing its "Welcome to Chrome" First Run Experience.
     *
     * The FRE cannot finish inside a container: it completes by sending a PendingIntent, and
     * that send does not execute here, so the FRE would stay on screen; the only way past it
     * would be to restart the clone, which flashes the host UI. Chrome's own first-run flag
     * is therefore written into the container before its first launch.
     */
    private fun seedChromeOnboardingComplete(packageName: String, virtualUserId: Int) {
        if (packageName != CHROME_PACKAGE) return
        val preferences = adapter.guestSharedPreferencesFile(
            packageName,
            virtualUserId,
            CHROME_PREFERENCES_NAME,
        ) ?: return

        try {
            val existing = if (preferences.isFile) preferences.readText() else null
            if (existing != null && existing.contains(CHROME_FIRST_RUN_TRUE)) return

            preferences.parentFile?.mkdirs()
            val content = when {
                existing == null -> CHROME_FIRST_RUN_SEED
                existing.contains(CHROME_MAP_CLOSE) ->
                    existing.replace(CHROME_MAP_CLOSE, CHROME_FIRST_RUN_ENTRIES + CHROME_MAP_CLOSE)
                else -> CHROME_FIRST_RUN_SEED
            }
            preferences.writeText(content)
            phase(
                "CHROME_ONBOARDING_SEEDED",
                DiagCategory.INSTALL,
                "Pre-seeded Chrome's first-run state in virtual user $virtualUserId",
                level = DiagLevel.SUCCESS,
                packageName = packageName,
                virtualUserId = virtualUserId,
            )
        } catch (error: Throwable) {
            Slog.w(
                Slog.INSTALL,
                "Could not seed Chrome's first-run state in user $virtualUserId: ${error.message}",
            )
        }
    }

    private companion object {
        const val CHROME_PACKAGE = "com.android.chrome"
        const val CHROME_PREFERENCES_NAME = "com.android.chrome_preferences"

        const val CHROME_FIRST_RUN_TRUE = "name=\"first_run_flow\" value=\"true\""
        const val CHROME_MAP_CLOSE = "</map>"
        const val CHROME_FIRST_RUN_ENTRIES =
            "    <boolean name=\"first_run_flow\" value=\"true\" />\n" +
                "    <boolean name=\"skip_welcome_page\" value=\"true\" />\n"

        /**
         * Chrome's own first-run-complete flags, as FirstRunStatus reads them. Written into a
         * fresh container's `shared_prefs/com.android.chrome_preferences.xml` so Chrome skips
         * its First Run Experience entirely.
         */
        val CHROME_FIRST_RUN_SEED: String = buildString {
            append("<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n")
            append("<map>\n")
            append(CHROME_FIRST_RUN_ENTRIES)
            append("</map>\n")
        }
    }
}
