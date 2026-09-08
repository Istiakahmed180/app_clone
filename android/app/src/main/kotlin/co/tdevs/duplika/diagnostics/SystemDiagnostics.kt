package co.tdevs.duplika.diagnostics

import android.content.Context
import android.os.Build
import android.os.Environment
import android.os.Process
import android.os.StatFs
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

    private fun freeBytes(): Long =
        StatFs(context.filesDir.absolutePath).let { it.availableBlocksLong * it.blockSizeLong }

    private fun totalBytes(): Long =
        StatFs(context.filesDir.absolutePath).let { it.blockCountLong * it.blockSizeLong }
}
