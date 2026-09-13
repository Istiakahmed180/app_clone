package co.tdevs.duplika.diagnostics

import android.app.ActivityManager
import android.content.Context
import android.content.res.Resources
import android.os.Build
import android.os.Environment
import android.os.Process
import android.os.StatFs
import android.os.UserManager
import co.tdevs.duplika.DuplikaApplication
import co.tdevs.duplika.native.EngineAvailability

/**
 * The System Information payload.
 *
 * Deliberately narrow. Everything here is either a build fact or a device capability
 * that changes how Duplika behaves; there is no identifier that could single out a
 * person or a device — no serial, no `ANDROID_ID`, no advertising id, no accounts.
 * A diagnostics report is meant to be sent to a developer, and none of that would help
 * them read it.
 */
class SystemDiagnostics(private val context: Context) {

    fun collect(): Map<String, Any?> {
        val availability = runCatching {
            DuplikaApplication.engine.checkAvailability(context)
        }.getOrNull()

        return buildMap {
            put("applicationId", context.packageName)
            put("appVersion", DiagnosticLogger.currentAppVersion())
            put("appVersionCode", DiagnosticLogger.currentAppVersionCode())
            put("nativeBuildType", DiagnosticLogger.buildType())
            put("processName", DiagnosticLogger.currentProcessName())
            put("pid", Process.myPid())
            put("uid", Process.myUid())

            put("manufacturer", Build.MANUFACTURER)
            put("model", Build.MODEL)
            put("device", Build.DEVICE)
            put("androidVersion", Build.VERSION.RELEASE)
            put("sdkInt", Build.VERSION.SDK_INT)
            put("supportedAbis", Build.SUPPORTED_ABIS.toList())
            put("primaryAbi", Build.SUPPORTED_ABIS.firstOrNull())

            // How much room a clone has to run in, as opposed to room to exist in. An
            // idle container costs storage; a running one costs this. `isLowRamDevice`
            // is the manufacturer's own declaration and is the closest thing to a
            // verdict the platform offers.
            val memory = runCatching { memoryInfo() }.getOrNull()
            put("totalMemBytes", memory?.totalMem)
            put("availMemBytes", memory?.availMem)
            put("memoryThresholdBytes", memory?.threshold)
            put("underMemoryPressure", memory?.lowMemory)
            put("isLowRamDevice", runCatching { activityManager()?.isLowRamDevice }.getOrNull())

            when (availability) {
                is EngineAvailability.Available -> {
                    put("engineStatus", "READY")
                    put("engineDetail", "The backend reports itself usable on this device.")
                }
                is EngineAvailability.Unavailable -> {
                    put("engineStatus", "UNAVAILABLE")
                    put("engineDetail", "${availability.code}: ${availability.message}")
                }
                null -> {
                    // Asking the engine threw. Saying so is the finding; reporting READY
                    // or UNAVAILABLE would both be inventions.
                    put("engineStatus", "UNKNOWN")
                    put("engineDetail", "The engine did not answer an availability check.")
                }
            }
            put("engineBackend", runCatching { DuplikaApplication.engine.backendName }.getOrNull())
            put("bcoreAttached", availability is EngineAvailability.Available)
            put(
                "virtualUserIds",
                runCatching { DuplikaApplication.engine.listVirtualUserIds() }.getOrDefault(emptyList()),
            )

            // Android's own multi-user configuration, recorded because it is the first
            // thing a reader assumes is the ceiling on clones. It is not: the engine
            // numbers its own virtual users inside this app's storage and never asks
            // the platform for a secondary user, so a device that permits one Android
            // user still hosts as many containers as there is room for. Kept here so a
            // report can rule the assumption out rather than invite it.
            put("hostSupportsMultipleUsers", runCatching { UserManager.supportsMultipleUsers() }.getOrNull())
            put("hostMaxAndroidUsers", hostMaxAndroidUsers())

            put("internalFreeBytes", runCatching { freeBytes() }.getOrNull())
            put("internalTotalBytes", runCatching { totalBytes() }.getOrNull())
            put("externalStorageState", runCatching { Environment.getExternalStorageState() }.getOrNull())
            put(
                "isExternalStorageManager",
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    runCatching { Environment.isExternalStorageManager() }.getOrNull()
                } else {
                    null
                },
            )

            put("nativeEventCount", DiagnosticLogger.retainedEventCount())
            put("nativeLogBytes", DiagnosticLogger.occupiedBytes())
            put("nativeProcesses", DiagnosticLogger.knownProcesses())
        }
    }

    private fun activityManager(): ActivityManager? =
        context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager

    private fun memoryInfo(): ActivityManager.MemoryInfo? =
        activityManager()?.let { manager ->
            ActivityManager.MemoryInfo().also(manager::getMemoryInfo)
        }

    /**
     * The platform's cap on Android user accounts, read from the framework resource the
     * platform itself consults. Null when the resource cannot be resolved — an unknown
     * is the honest answer, and this number constrains nothing Duplika does anyway.
     */
    private fun hostMaxAndroidUsers(): Int? = runCatching {
        val resources = Resources.getSystem()
        val id = resources.getIdentifier("config_multiuserMaximumUsers", "integer", "android")
        if (id == 0) null else resources.getInteger(id)
    }.getOrNull()

    private fun freeBytes(): Long =
        StatFs(context.filesDir.absolutePath).let { it.availableBlocksLong * it.blockSizeLong }

    private fun totalBytes(): Long =
        StatFs(context.filesDir.absolutePath).let { it.blockCountLong * it.blockSizeLong }
}
