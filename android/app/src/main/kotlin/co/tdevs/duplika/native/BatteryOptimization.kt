package co.tdevs.duplika.native

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings

/**
 * The Doze exemption prompt.
 *
 * Clones are hosted inside Duplika's own process group, so Android's battery optimiser
 * treats them as Duplika. When the host is dozed every clone is dozed with it, and a
 * cloned messenger silently stops delivering while the user believes it is running. The
 * exemption is the only way to keep that from happening.
 *
 * Nothing here grants anything. Android owns both screens and the user's answer; this
 * only opens the right one and reports what the state actually is afterwards.
 */
class BatteryOptimization(context: Context) {

    private val appContext = context.applicationContext
    private val packageName = appContext.packageName

    /** Whether Android currently exempts Duplika from Doze. */
    fun isIgnoring(): Boolean {
        val power = appContext.getSystemService(Context.POWER_SERVICE) as? PowerManager
            ?: return false
        return power.isIgnoringBatteryOptimizations(packageName)
    }

    /**
     * Opens the exemption prompt, preferring the one-tap dialog.
     *
     * Some OEM builds -- and any build where the permission was stripped -- have no
     * activity for [Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS]. Falling back to
     * the battery optimisation list still lets the user finish the job, so the caller is
     * told which screen opened rather than being told this failed.
     */
    fun request(activity: Activity): EngineResult<Map<String, Any?>> {
        if (isIgnoring()) {
            return EngineResult.Success(mapOf("alreadyExempt" to true, "screen" to "none"))
        }

        val direct = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            .setData(Uri.parse("package:$packageName"))
        if (start(activity, direct)) {
            return EngineResult.Success(mapOf("alreadyExempt" to false, "screen" to "dialog"))
        }

        val list = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
        if (start(activity, list)) {
            Slog.i(Slog.POWER, "Doze dialog unavailable; opened the battery settings list")
            return EngineResult.Success(mapOf("alreadyExempt" to false, "screen" to "settings"))
        }

        Slog.w(Slog.POWER, "No activity can handle a battery optimisation request")
        return EngineResult.Failure(
            EngineErrorCodes.BATTERY_PROMPT_UNAVAILABLE,
            "This device has no battery optimisation screen to open.",
        )
    }

    private fun start(activity: Activity, intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (error: Throwable) {
        // ActivityNotFoundException on devices without the screen, SecurityException where
        // the OEM gates it. Both mean "try the next one", not "crash".
        Slog.w(Slog.POWER, "Cannot open ${intent.action}: ${error.message}")
        false
    }
}
