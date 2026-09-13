package co.tdevs.duplika.native

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import co.tdevs.duplika.DuplikaApplication
import co.tdevs.duplika.diagnostics.DiagnosticLogger
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The single Flutter <-> Android entry point.
 *
 * Android and engine types stay behind this boundary; Flutter only ever receives plain
 * maps. Every call returns a structured envelope so a native failure can never be mistaken
 * for success on the Dart side.
 */
class NativeBridge(context: Context) : MethodChannel.MethodCallHandler {

    private val appContext = context.applicationContext
    private val testAppManager = TestAppManager(appContext)
    private val appLauncher = AppLauncher(appContext)
    private val engine = RealVirtualizationEngine(appContext, DuplikaApplication.engine)
    private val analyzer = AppCompatibilityAnalyzer(appContext)
    private val shortcuts = CloneShortcutManager(appContext)
    private val battery = BatteryOptimization(appContext)
    private val appDetails = AppDetailsReader(appContext)
    private val deviceCapacity = DeviceCapacity(appContext)
    private val disguise = AppDisguise(appContext)
    private val notifications = NotificationControl(appContext)
    private val profiles = VirtualProfileManager(appContext)
    private val permissionPolicy = ClonePermissionPolicy(appContext)
    private var channel: MethodChannel? = null
    private var activity: Activity? = null

    fun bindActivity(activity: Activity) {
        this.activity = activity
    }

    fun unbindActivity() {
        activity = null
    }

    // Engine calls can install packages and wait out the backend's service backoff, so they
    // must never run on the platform thread. Results are posted back to the main looper,
    // which MethodChannel.Result requires.
    private val engineExecutor = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "duplika-engine")
    }
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Runs [work] off the platform thread and replies on the main looper. */
    private fun async(result: MethodChannel.Result, work: () -> Map<String, Any?>) {
        try {
            submit(result, work)
        } catch (_: RejectedExecutionException) {
            // detach() has already shut the executor down. Answer instead of leaving the
            // Dart future pending forever.
            Slog.w(Slog.ENGINE, "Rejecting call: bridge is shutting down")
            reply(result, failure("BRIDGE_SHUTTING_DOWN", "Duplika is closing."))
        }
    }

    private fun submit(result: MethodChannel.Result, work: () -> Map<String, Any?>) {
        // The correlation id is thread-local, and the work is about to hop threads.
        // Capturing it here — on the platform thread, still inside the scope installed
        // by onMethodCall — and re-applying it on the engine thread is what keeps a
        // container install's events tied to the launch that asked for it.
        val scope = DiagnosticLogger.currentOperation()
        engineExecutor.execute {
            val response = DiagnosticLogger.withOperation(scope?.id, scope?.name) {
                try {
                    work()
                } catch (error: Throwable) {
                    Slog.e(Slog.ENGINE, "Engine work failed", error)
                    failure("BRIDGE_ERROR", error.message ?: "Native call failed.")
                }
            }
            mainHandler.post { reply(result, response) }
        }
    }

    /**
     * Replies on the main looper, tolerating a bridge that has since been detached.
     *
     * The activity can go away while a long install or a permission dialog is still
     * outstanding, and replying on a torn-down channel throws.
     */
    private fun reply(result: MethodChannel.Result, response: Map<String, Any?>) {
        if (channel == null) {
            Slog.w(Slog.ENGINE, "Dropping reply: bridge already detached")
            return
        }
        try {
            result.success(response)
        } catch (error: Throwable) {
            Slog.w(Slog.ENGINE, "Reply failed: ${error.message}")
        }
    }

    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL_NAME).also { it.setMethodCallHandler(this) }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        engineExecutor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        // Every Dart call carries the id of the operation that made it (see
        // ChannelDiagnostics on the Flutter side). Installing it for the duration of the
        // dispatch means the engine, installer and launcher below emit events tagged with
        // that operation without any of them taking a diagnostics parameter.
        DiagnosticLogger.withOperation(
            call.argument<String>(ARG_OPERATION_ID),
            call.argument<String>(ARG_OPERATION_NAME),
        ) {
            try {
                dispatch(call, result)
            } catch (error: Throwable) {
                // Surface the failure instead of leaving the Dart future hanging.
                Slog.e(Slog.ENGINE, "Bridge call ${call.method} threw", error)
                result.success(
                    failure("BRIDGE_ERROR", error.message ?: "Native call failed."),
                )
            }
        }
    }

    private fun dispatch(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformInfo" -> result.success(testAppManager.getPlatformInfo())
            "getDeviceCapacity" -> result.success(deviceCapacity.read())

            "getAppDisguise" -> result.success(
                success(
                    "APP_DISGUISE_READ",
                    "Launcher disguise read.",
                    mapOf("mode" to disguise.currentMode().name),
                ),
            )
            "setAppDisguise" -> {
                val mode = AppDisguise.Mode.parse(call.argument<String>("mode"))
                disguise.setMode(mode)
                result.success(
                    success(
                        "APP_DISGUISE_SET",
                        "Launcher disguise set.",
                        mapOf("mode" to disguise.currentMode().name),
                    ),
                )
            }

            "openCloneNotificationSettings" -> {
                val opened = notifications.openNotificationSettings()
                result.success(
                    if (opened) {
                        success(
                            "NOTIFICATION_SETTINGS_OPENED",
                            "Opened Duplika's notification settings.",
                        )
                    } else {
                        failure(
                            "NOTIFICATION_SETTINGS_UNAVAILABLE",
                            "This device has no notification settings screen to open.",
                        )
                    },
                )
            }

            "getClonePermissions" -> {
                val profileId = call.requiredProfile(result) ?: return
                val packageName = call.requiredPackage(result) ?: return
                val virtualUserId = profiles.virtualUserIdFor(profileId)
                if (virtualUserId == null) {
                    result.success(
                        failure("NO_CONTAINER", "This clone has no container yet."),
                    )
                    return
                }
                result.success(
                    success(
                        "CLONE_PERMISSIONS_READ",
                        "Clone permission policy read.",
                        mapOf(
                            "virtualUserId" to virtualUserId,
                            "permissions" to analyzer.declaredDangerousPermissions(packageName),
                            "denied" to permissionPolicy.denied(virtualUserId).toList(),
                        ),
                    ),
                )
            }

            "setClonePermission" -> {
                val profileId = call.requiredProfile(result) ?: return
                val permission = call.requiredArg("permission", result) ?: return
                val allowed = call.argument<Boolean>("allowed") ?: false
                val virtualUserId = profiles.virtualUserIdFor(profileId)
                if (virtualUserId == null) {
                    result.success(
                        failure("NO_CONTAINER", "This clone has no container yet."),
                    )
                    return
                }
                permissionPolicy.setDenied(virtualUserId, permission, !allowed)
                result.success(
                    success(
                        "CLONE_PERMISSION_SET",
                        "Clone permission updated.",
                        mapOf("denied" to permissionPolicy.denied(virtualUserId).toList()),
                    ),
                )
            }
            "isTestAppInstalled" -> result.success(testAppManager.isTestAppInstalled())
            "getTestAppInfo" -> result.success(testAppManager.getTestAppInfo())

            "isVirtualizationAvailable" -> result.success(engine.availability())

            "listInstalledApps" -> {
                val includeIcons = call.argument<Boolean>("includeIcons") ?: true
                async(result) {
                    success(
                        "APPS_LISTED",
                        "Installed applications listed.",
                        mapOf("apps" to engine.listInstalledApps(includeIcons)),
                    )
                }
            }

            "analyzeApp" -> {
                val packageName = call.requiredPackage(result) ?: return
                async(result) {
                    success(
                        "APP_ANALYZED",
                        "Compatibility analysed.",
                        analyzer.analyze(packageName).toMap(),
                    )
                }
            }

            "analyzeApk" -> {
                val packageName = call.requiredPackage(result) ?: return
                val apkPath = call.requiredArg("apkPath", result) ?: return
                async(result) {
                    success(
                        "APK_ANALYZED",
                        "Compatibility analysed.",
                        engine.analyzeApk(apkPath, packageName),
                    )
                }
            }

            // The Doze prompt is main-thread, Activity-bound and short. It must not go
            // through async(): the engine executor is a single queue that a long install
            // would sit in front of.
            "isIgnoringBatteryOptimizations" -> result.success(
                success(
                    "BATTERY_STATE",
                    "Battery optimisation state read.",
                    mapOf("ignoring" to battery.isIgnoring()),
                ),
            )

            "requestIgnoreBatteryOptimizations" -> {
                val host = activity ?: return result.success(noActivity("The battery prompt"))
                result.success(
                    when (val outcome = battery.request(host)) {
                        is EngineResult.Success -> success(
                            "BATTERY_PROMPT_OPENED",
                            "Battery optimisation prompt opened.",
                            outcome.value,
                        )
                        is EngineResult.Failure -> failure(outcome.code, outcome.message)
                    },
                )
            }

            "areShortcutsSupported" -> result.success(
                success(
                    "SHORTCUT_SUPPORT",
                    "Shortcut support checked.",
                    mapOf("supported" to shortcuts.isSupported()),
                ),
            )

            "pinCloneShortcut" -> {
                val profileId = call.requiredProfile(result) ?: return
                val packageName = call.requiredPackage(result) ?: return
                val label = call.argument<String>("label").orEmpty().ifBlank { packageName }
                result.success(
                    shortcuts.requestPin(
                        profileId,
                        packageName,
                        label,
                        spaceIndex = call.argument<Int>("spaceIndex") ?: 1,
                        spaceCount = call.argument<Int>("spaceCount") ?: 1,
                    ).toEnvelope("SHORTCUT_REQUESTED", "Shortcut request sent to the launcher."),
                )
            }

            "getAppIcons" -> {
                val packages = call.argument<List<String>>("packageNames").orEmpty()
                async(result) {
                    success(
                        "ICONS_LOADED",
                        "Icons loaded.",
                        mapOf("icons" to engine.appIconsFor(packages)),
                    )
                }
            }

            "inspectApk" -> {
                val apkPaths = call.argument<List<String>>("apkPaths").orEmpty()
                if (apkPaths.isEmpty()) {
                    result.success(failure(EngineErrorCodes.APK_INVALID, "Select at least one APK."))
                    return
                }
                async(result) {
                    when (val info = engine.inspectApk(apkPaths)) {
                        is EngineResult.Success ->
                            success("APK_INSPECTED", "APK read successfully.", info.value)
                        is EngineResult.Failure -> failure(info.code, info.message)
                    }
                }
            }

            "installApkToProfile" -> {
                val profileId = call.requiredProfile(result) ?: return
                val packageName = call.requiredPackage(result) ?: return
                val apkPaths = call.argument<List<String>>("apkPaths").orEmpty()
                if (apkPaths.isEmpty()) {
                    result.success(failure(EngineErrorCodes.APK_INVALID, "Select at least one APK."))
                    return
                }
                val provisionGms = call.argument<Boolean>("installGms") ?: false
                async(result) {
                    engine.installApkToProfile(profileId, apkPaths, packageName, provisionGms)
                        .toEnvelope("APP_INSTALLED", "Application installed successfully.")
                }
            }

            "initializeVirtualization" ->
                async(result) { engine.initialize().toEnvelope("ENGINE_READY", "Engine ready.") }

            "isAppSupported" -> {
                val packageName = call.requiredPackage(result) ?: return
                result.success(
                    success(
                        "APP_SUPPORT_CHECKED",
                        "Support check complete.",
                        mapOf("supported" to engine.isAppSupported(packageName)),
                    ),
                )
            }

            "checkSecureEnvironmentRequirement" -> {
                val packageName = call.requiredPackage(result) ?: return
                val required = engine.requiresSecureEnvironment(packageName)
                result.success(
                    success(
                        if (required) "SECURE_ENV_REQUIRED" else "SECURE_ENV_NOT_REQUIRED",
                        if (required) {
                            "This application refuses to run in a container."
                        } else {
                            "No secure-environment requirement declared."
                        },
                        mapOf("requiresSecureEnv" to required),
                    ),
                )
            }

            "installAppToProfile" -> {
                val profileId = call.requiredProfile(result) ?: return
                val packageName = call.requiredPackage(result) ?: return
                val provisionGms = call.argument<Boolean>("installGms") ?: false
                async(result) {
                    engine.installAppToProfile(profileId, packageName, provisionGms)
                        .toEnvelope("APP_INSTALLED", "Application installed successfully.")
                }
            }

            "uninstallAppFromProfile" -> {
                val profileId = call.requiredProfile(result) ?: return
                val packageName = call.requiredPackage(result) ?: return
                async(result) {
                    engine.uninstallAppFromProfile(profileId, packageName)
                        .toEnvelope("APP_UNINSTALLED", "Application removed from profile.")
                }
            }

            "isAppInstalledInProfile" -> {
                val profileId = call.requiredProfile(result) ?: return
                val packageName = call.requiredPackage(result) ?: return
                async(result) {
                    success(
                        "PROFILE_STATE",
                        "Profile state read.",
                        engine.profileState(profileId, packageName),
                    )
                }
            }

            "clearProfileData" -> {
                val profileId = call.requiredProfile(result) ?: return
                val packageName = call.requiredPackage(result) ?: return
                async(result) {
                    engine.clearProfileData(profileId, packageName)
                        .toEnvelope("PROFILE_DATA_CLEARED", "Clone data cleared.")
                }
            }

            "clearProfileCache" -> {
                val profileId = call.requiredProfile(result) ?: return
                val packageName = call.requiredPackage(result) ?: return
                async(result) {
                    engine.clearProfileCache(profileId, packageName)
                        .toEnvelope("PROFILE_CACHE_CLEARED", "Clone cache cleared.")
                }
            }

            "spaceIdentity" -> {
                val profileId = call.requiredProfile(result) ?: return
                val action = call.argument<String>("action") ?: "read"
                // Only strings are taken across, so a malformed argument map cannot put
                // anything but text into the stored identity.
                val values = call.argument<Map<String, Any?>>("values")
                    .orEmpty()
                    .mapNotNull { (key, value) ->
                        if (value is String) key to value else null
                    }
                    .toMap()
                async(result) {
                    when (val identity = engine.spaceIdentity(profileId, action, values)) {
                        is EngineResult.Success ->
                            success("SPACE_IDENTITY", "Space identity read.", identity.value)
                        is EngineResult.Failure -> failure(identity.code, identity.message)
                    }
                }
            }

            "shareProfileApk" -> {
                val profileId = call.requiredProfile(result) ?: return
                val packageName = call.requiredPackage(result) ?: return
                val label = call.argument<String>("label").orEmpty().ifBlank { packageName }
                // Copying a whole APK belongs off the platform thread.
                async(result) {
                    engine.shareProfileApk(profileId, packageName, label)
                        .toEnvelope("APK_SHARED", "Share sheet opened.")
                }
            }

            // Shares an app that is installed on the host and has no clone yet, which is
            // every row in the picker. Separate from `shareProfileApk` because there is no
            // profile to name: the archive comes straight from the host package manager.
            // Everything Duplika can say about one package's archive. Opens every APK
            // in the set and hashes its certificate, so it stays off the platform thread
            // and is asked for one app at a time rather than for the whole picker.
            "getAppDetails" -> {
                val packageName = call.requiredPackage(result) ?: return
                async(result) {
                    when (val details = appDetails.read(packageName)) {
                        null -> failure(
                            EngineErrorCodes.APP_NOT_FOUND,
                            "This app is no longer installed on this device.",
                        )
                        else -> success("APP_DETAILS", "App details read.", details)
                    }
                }
            }

            "shareInstalledApk" -> {
                val packageName = call.requiredPackage(result) ?: return
                val label = call.argument<String>("label").orEmpty().ifBlank { packageName }
                async(result) {
                    engine.shareInstalledApk(packageName, label)
                        .toEnvelope("APK_SHARED", "Share sheet opened.")
                }
            }

            "launchProfile" -> {
                val profileId = call.requiredProfile(result) ?: return
                val packageName = call.requiredPackage(result) ?: return
                async(result) {
                    engine.launchProfile(profileId, packageName)
                        .toEnvelope("PROFILE_LAUNCHED", "Virtual application launched.")
                }
            }

            "stopProfile" -> {
                val profileId = call.requiredProfile(result) ?: return
                val packageName = call.requiredPackage(result) ?: return
                async(result) {
                    engine.stopProfile(profileId, packageName)
                        .toEnvelope("PROFILE_STOPPED", "Virtual application stopped.")
                }
            }

            "deleteProfile" -> {
                val profileId = call.requiredProfile(result) ?: return
                val packageName = call.requiredPackage(result) ?: return
                async(result) {
                    engine.deleteProfile(profileId, packageName)
                        .toEnvelope("PROFILE_DELETED", "Virtual environment removed.")
                }
            }

            // Phase 1 path, kept so the normal (unvirtualized) launch stays testable.
            "launchTestApp" -> result.success(appLauncher.launch(TestAppManager.TEST_APP_PACKAGE))

            else -> result.notImplemented()
        }
    }

    private fun MethodCall.requiredProfile(result: MethodChannel.Result): String? =
        requiredArg("profileId", result)

    private fun MethodCall.requiredPackage(result: MethodChannel.Result): String? =
        requiredArg("packageName", result)

    private fun noActivity(subject: String): Map<String, Any?> = failure(
        EngineErrorCodes.NO_ACTIVITY,
        "$subject can only be shown while the app is open.",
    )

    private fun MethodCall.requiredArg(name: String, result: MethodChannel.Result): String? {
        val value = argument<String>(name)
        if (value.isNullOrBlank()) {
            result.success(failure("INVALID_ARGUMENT", "Missing required argument \"$name\"."))
            return null
        }
        return value
    }

    private fun EngineResult<Unit>.toEnvelope(
        successCode: String,
        successMessage: String,
    ): Map<String, Any?> = when (this) {
        is EngineResult.Success -> success(successCode, successMessage)
        is EngineResult.Failure -> failure(code, message)
    }

    private fun success(
        code: String,
        message: String,
        data: Map<String, Any?> = emptyMap(),
    ): Map<String, Any?> = mapOf(
        "success" to true,
        "code" to code,
        "message" to message,
        "data" to data,
    )

    private fun failure(code: String, message: String): Map<String, Any?> = mapOf(
        "success" to false,
        "code" to code,
        "message" to message,
        "data" to emptyMap<String, Any?>(),
    )

    companion object {
        const val CHANNEL_NAME = "duplika/native_bridge"

        /**
         * Diagnostics-only argument keys, prefixed so they can never collide with a real
         * parameter and are skipped by the argument summariser on the Dart side.
         */
        const val ARG_OPERATION_ID = "__opId"
        const val ARG_OPERATION_NAME = "__opName"
    }
}
