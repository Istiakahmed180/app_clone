package com.example.virtualspacedemo.native

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.example.virtualspacedemo.VirtualSpaceApplication
import java.util.concurrent.Executors
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
    private val engine = RealVirtualizationEngine(appContext, VirtualSpaceApplication.engine)
    private var channel: MethodChannel? = null

    // Engine calls can install packages and wait out the backend's service backoff, so they
    // must never run on the platform thread. Results are posted back to the main looper,
    // which MethodChannel.Result requires.
    private val engineExecutor = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "virtual-space-engine")
    }
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Runs [work] off the platform thread and replies on the main looper. */
    private fun async(result: MethodChannel.Result, work: () -> Map<String, Any?>) {
        engineExecutor.execute {
            val response = try {
                work()
            } catch (error: Throwable) {
                Slog.e(Slog.ENGINE, "Engine work failed", error)
                failure("BRIDGE_ERROR", error.message ?: "Native call failed.")
            }
            mainHandler.post {
                // The activity can be destroyed while a long install is still running;
                // replying on a torn-down channel throws.
                if (channel == null) {
                    Slog.w(Slog.ENGINE, "Dropping reply: bridge already detached")
                    return@post
                }
                try {
                    result.success(response)
                } catch (error: Throwable) {
                    Slog.w(Slog.ENGINE, "Reply failed: ${error.message}")
                }
            }
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

    private fun dispatch(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformInfo" -> result.success(testAppManager.getPlatformInfo())
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
                val apkPath = call.requiredArg("apkPath", result) ?: return
                async(result) {
                    when (val info = engine.inspectApk(apkPath)) {
                        is EngineResult.Success ->
                            success("APK_INSPECTED", "APK read successfully.", info.value)
                        is EngineResult.Failure -> failure(info.code, info.message)
                    }
                }
            }

            "installApkToProfile" -> {
                val profileId = call.requiredProfile(result) ?: return
                val packageName = call.requiredPackage(result) ?: return
                val apkPath = call.requiredArg("apkPath", result) ?: return
                async(result) {
                    engine.installApkToProfile(profileId, apkPath, packageName)
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
                async(result) {
                    engine.installAppToProfile(profileId, packageName)
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
        const val CHANNEL_NAME = "virtual_space/native_bridge"
    }
}
