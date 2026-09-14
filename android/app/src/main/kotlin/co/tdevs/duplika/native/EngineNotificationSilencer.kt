package co.tdevs.duplika.native

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

/**
 * Blocks every notification the virtualization engine posts on its own behalf.
 *
 * The engine runs foreground services and error notices for its own internals — the daemon
 * ("BlackBox Core / Core services are running"), the proxy service, the VPN service and a
 * log-upload failure — and none of them describe anything the user did. Duplika suppresses
 * all of them.
 *
 * Channels blocked (the engine's own; verified against the vendored source):
 *
 * | Channel | Posted by |
 * | --- | --- |
 * | `blackbox_daemon_channel` | `DaemonService` |
 * | `<pkg>.blackbox_core` | `BlackBoxCore` log-upload failure |
 * | `<pkg>.blackbox_proxy` | `ProxyService` |
 * | `BlackBoxVPN` | `ProxyVpnService` (unused: VPN mode is pinned off) |
 * | `<pkg>` | `NotificationChannelManager.APP_CHANNEL` |
 *
 * **Not** touched: the clone keep-alive notice (`clone_keepalive`, Duplika's own) and every
 * guest notification channel (`<channel>@black-<userId>`), so clone notifications are
 * unaffected.
 *
 * Two mechanisms, because Android's channel rules and the engine's start order both matter:
 *
 * - [blockChannel] creates each channel with `IMPORTANCE_NONE` **before** the engine attaches
 *   (`DuplikaApplication.attachBaseContext`). Android never raises a channel's importance
 *   after its first creation, so the engine's own `IMPORTANCE_HIGH`/`LOW` requests cannot undo
 *   it.
 * - [cancelPostedNotification] cancels notices an earlier launch already posted. The engine's
 *   ids are `hostPkg.hashCode()` (daemon and proxy), `9999` (log upload) and `1001` (VPN).
 */
object EngineNotificationSilencer {

    /** `DaemonService` */
    private const val DAEMON_CHANNEL_ID = "blackbox_daemon_channel"

    /** `BlackBoxCore.initNotificationManager` and `ProxyService.showNotification` */
    private const val CORE_CHANNEL_SUFFIX = ".blackbox_core"
    private const val PROXY_CHANNEL_SUFFIX = ".blackbox_proxy"

    /** `ProxyVpnService` (VPN mode is pinned off, kept for completeness). */
    private const val VPN_CHANNEL_ID = "BlackBoxVPN"

    /** Engine notification ids that are not package-derived. */
    private const val LOG_UPLOAD_NOTIFICATION_ID = 9999
    private const val VPN_NOTIFICATION_ID = 1001

    /** Runs before the engine attaches; see [co.tdevs.duplika.DuplikaApplication]. */
    fun blockChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        engineChannelIds(context.packageName).forEach { id ->
            val channel = NotificationChannel(
                id,
                "BlackBox",
                NotificationManager.IMPORTANCE_NONE,
            ).apply {
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_SECRET
            }
            runCatching { manager.createNotificationChannel(channel) }
                .onFailure { Slog.w(Slog.ENGINE, "Could not block $id: ${it.message}") }
        }
    }

    /** Cancels notices already posted by an earlier launch. Safe to call on every start. */
    fun cancelPostedNotification(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        listOf(
            context.packageName.hashCode(),
            LOG_UPLOAD_NOTIFICATION_ID,
            VPN_NOTIFICATION_ID,
        ).forEach { id ->
            runCatching { manager.cancel(id) }
        }
    }

    private fun engineChannelIds(packageName: String): List<String> = listOf(
        DAEMON_CHANNEL_ID,
        packageName + CORE_CHANNEL_SUFFIX,
        packageName + PROXY_CHANNEL_SUFFIX,
        VPN_CHANNEL_ID,
        // NotificationChannelManager.APP_CHANNEL: the channel id is the bare package name.
        packageName,
    )
}
