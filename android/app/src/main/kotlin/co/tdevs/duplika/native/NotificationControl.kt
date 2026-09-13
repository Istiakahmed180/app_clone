package co.tdevs.duplika.native

import android.content.Context
import android.content.Intent
import android.provider.Settings

/**
 * Opens Android's notification settings for Duplika, where each clone is a channel the user
 * can silence on its own.
 *
 * A guest runs under Duplika's identity, so its notifications are posted under Duplika. The
 * engine still keeps clones apart: every channel is created and every notification posted
 * with an id namespaced by the container (`<channel>@black-<userId>`), and the engine's
 * `BNotificationManager` override also labels the channel with its clone number. So the
 * settings screen this opens lists "… · Clone 1", "… · Clone 2" separately, and turning one
 * off silences that clone without touching the others.
 *
 * It deliberately does not try to open a single channel: Duplika's own
 * `NotificationManager.getNotificationChannels()` is hooked in this process and answers for
 * the host, not for a container, so the real per-clone ids are not enumerable from here. The
 * app-wide screen is what the system will actually show them on.
 */
class NotificationControl(private val context: Context) {

    /** Returns true when the settings screen was opened. */
    fun openNotificationSettings(): Boolean {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(intent)
            true
        } catch (error: Exception) {
            Slog.w(Slog.ENGINE, "Could not open notification settings: ${error.message}")
            false
        }
    }
}
