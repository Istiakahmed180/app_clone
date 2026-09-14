package co.tdevs.duplika.native

import android.app.Activity
import android.content.Intent

/**
 * Opens a system settings page, answering whether anything opened at all.
 *
 * `ActivityNotFoundException` on a device without the screen and `SecurityException` on the
 * OEM builds that gate one both mean "try the next screen", not "crash", so every caller
 * gets a boolean instead of an exception. The caller names its own log tag because the
 * screen belongs to the caller: a battery screen and a Doze screen are different stories.
 */
internal fun startSettingsPage(activity: Activity, intent: Intent, tag: String): Boolean = try {
    activity.startActivity(intent)
    true
} catch (error: Throwable) {
    Slog.w(tag, "Cannot open ${intent.action ?: intent.component}: ${error.message}")
    false
}
