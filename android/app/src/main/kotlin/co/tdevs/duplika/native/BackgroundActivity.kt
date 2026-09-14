package co.tdevs.duplika.native

import android.app.Activity
import android.app.ActivityManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings

/**
 * The "background activity" control, which is not the Doze exemption.
 *
 * Doze is Android's own optimiser and [BatteryOptimization] covers its exemption. The
 * "Allow background activity" switch some OEMs put on the app's battery page is a second,
 * independent control -- on a OnePlus it is App info, then Battery usage, then Allow
 * background activity -- and when it is off a clone silently stops receiving push, because
 * every clone runs inside Duplika's own process group and freezes with it.
 *
 * Android exposes no API for the OEM switch, and the screen that carries it is not
 * exported, so this cannot deep-link to it. Measured on a CPH2605 (ColorOS): starting
 * `com.oplus.battery/com.oplus.powermanager.fuelgaue.PowerControlActivity` is refused with
 * "not exported from uid 1000" -- settings may open it, apps may not.
 *
 * What the app can do instead is open the page the switch lives on, and report the two
 * facts Android *does* expose about Duplika's background standing: whether Doze exempts it
 * and whether the platform has restricted its background running. Together those are what
 * "allowed to run in the background" means to the system.
 */
class BackgroundActivity(context: Context) {

    private val appContext = context.applicationContext
    private val packageName = appContext.packageName

    /**
     * The state behind the background activity row.
     *
     * [restricted] is null on releases below Android 9 rather than false: the honest answer
     * there is "the platform cannot say", not "it is unrestricted".
     *
     * [standbyBucket] is the app standby bucket, reported for the diagnostics trail. It is
     * read defensively -- some OEM builds gate the getter behind a usage-access permission
     * the app does not hold -- so an unreadable bucket is named as such instead of failing
     * the whole call.
     */
    fun state(): Map<String, Any?> {
        val exempt = BatteryOptimization(appContext).isIgnoring()
        return mapOf(
            "exempt" to exempt,
            "restricted" to backgroundRestricted(),
            "standbyBucket" to standbyBucket(),
            // Which build this is has to travel with the state: on the ones that have their
            // own switch, the switch decides more than these two controls do and nothing in
            // the public API exposes it -- so the caller cannot call the app "allowed" from
            // here, and the row has to say so rather than guess.
            "nextStep" to nextStep(),
        )
    }

    /**
     * Opens the page that carries the OEM switch, preferring the app's own info page.
     *
     * The app info page is the destination because it is the one screen every build has,
     * and on the OEMs with a separate switch it is where that switch lives (one tap below,
     * under Battery usage). [nextStep] says so on the builds where it is known to be
     * needed, so the caller can word the instruction the user actually has to follow.
     */
    fun open(activity: Activity): EngineResult<Map<String, Any?>> {
        val appInfo = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.parse("package:$packageName"))
        if (startSettingsPage(activity, appInfo, Slog.POWER)) {
            Slog.i(Slog.POWER, "Opened app info for the background activity switch")
            return EngineResult.Success(
                mapOf("screen" to "appInfo", "nextStep" to nextStep()),
            )
        }

        val batteryList = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
        if (startSettingsPage(activity, batteryList, Slog.POWER)) {
            Slog.i(Slog.POWER, "App info unavailable; opened the battery settings list")
            return EngineResult.Success(
                mapOf("screen" to "batterySettings", "nextStep" to null),
            )
        }

        Slog.w(Slog.POWER, "No activity can handle the background activity settings")
        return EngineResult.Failure(
            EngineErrorCodes.BACKGROUND_ACTIVITY_PROMPT_UNAVAILABLE,
            "This device has no background activity screen to open.",
        )
    }

    private fun backgroundRestricted(): Boolean? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            return null
        }
        val manager = appContext.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            ?: return null
        return manager.isBackgroundRestricted
    }

    private fun standbyBucket(): String {
        val manager = appContext.getSystemService(Context.USAGE_STATS_SERVICE)
            as? UsageStatsManager
            ?: return "unavailable"
        val bucket = runCatching { manager.appStandbyBucket }.getOrElse {
            Slog.w(Slog.POWER, "Standby bucket unreadable: ${it.message}")
            return "unreadable"
        }
        return when (bucket) {
            UsageStatsManager.STANDBY_BUCKET_ACTIVE -> "active"
            UsageStatsManager.STANDBY_BUCKET_WORKING_SET -> "workingSet"
            UsageStatsManager.STANDBY_BUCKET_FREQUENT -> "frequent"
            UsageStatsManager.STANDBY_BUCKET_RARE -> "rare"
            UsageStatsManager.STANDBY_BUCKET_RESTRICTED -> "restricted"
            // Bucket 50 ("never") has no public constant, so it is reported by number
            // rather than guessed at.
            else -> "unknown($bucket)"
        }
    }

    /**
     * Which extra tap the OEM's page needs, or null when the info page is the whole story.
     *
     * Keyed off the package that owns the screen rather than the brand string: the switch
     * screen exists exactly when that battery app does, and a brand can ship either build.
     */
    private fun nextStep(): String? {
        val hasOplusBattery = runCatching {
            appContext.packageManager.getPackageInfo(OPLUS_BATTERY_PACKAGE, 0)
            true
        }.getOrDefault(false)
        return if (hasOplusBattery) "batteryUsage" else null
    }

    private companion object {
        const val OPLUS_BATTERY_PACKAGE = "com.oplus.battery"
    }
}
