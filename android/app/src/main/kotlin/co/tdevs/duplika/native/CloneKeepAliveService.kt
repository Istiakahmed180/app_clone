package co.tdevs.duplika.native

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import co.tdevs.duplika.DuplikaApplication
import co.tdevs.duplika.R
import co.tdevs.duplika.native.gms.MicroGCheckinSeeder
import co.tdevs.duplika.native.gms.MicroGProvider

/**
 * Keeps the host process alive while a clone the user opened is running, and keeps that
 * clone's microG receive channel connected.
 *
 * ## Why the host needs keeping alive
 *
 * On aggressive OEM builds the host process is killed as soon as it stops being the
 * foreground activity — which is exactly the moment a clone takes the foreground. Measured on
 * an OnePlus CPH2605: `UserAwareMgr: process killed: {… pid=9435, flags='bg'}` within seconds
 * of the clone opening (adding the app to the battery-optimisation whitelist did not stop
 * it). The clone itself keeps running in its own process, but the host being killed
 * cold-starts Duplika when the user returns and drops an attached debugger.
 *
 * ## Why it also reconnects microG
 *
 * The same OEM killer ends the container's microG process (`exited due to signal 9`), and
 * microG's MCS connection to `mtalk.google.com` dies with it, so FCM messages stop arriving.
 * While a clone is open this service re-wakes that connection every [WAKE_INTERVAL_MS] — FCM
 * stores undelivered messages, so they arrive at the next reconnect. A closed clone is
 * covered by [ClonePushRefreshWorker] instead.
 *
 * It keeps *Duplika* alive; it does not run the clone. The guest runs in its own process
 * either way.
 *
 * **Why it does not poll the engine's `isRunning`.** That call is broken on API 35
 * (`isRunningApplication failed: BActivityManagerService cannot be cast to ActivityStack`),
 * so a poll-based stop ended the service 15 s after every launch while the clone was plainly
 * still on screen. "The host activity resumed" is the reliable signal: the host only resumes
 * when the clone has left the foreground.
 */
class CloneKeepAliveService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var userId: Int = -1

    /**
     * Re-labels the engine's notification channels once the guest process is up.
     *
     * The engine creates them from inside the guest (`:black`) process, a moment after this
     * service starts, and that creation replaces the neutral names set earlier. Measured on
     * API 35: right after a launch the channel reads "blackbox_core" in Android's
     * notification settings for Duplika; a pass a few seconds later restores it.
     */
    private val relabel = Runnable { EngineNotificationSilencer.blockChannel(this) }

    private val reconnect = object : Runnable {
        override fun run() {
            // The long-interval backstop for the same drift, for a guest that creates a
            // channel later still.
            EngineNotificationSilencer.blockChannel(this@CloneKeepAliveService)
            val user = userId
            if (user < 0) return
            runCatching {
                DuplikaApplication.engine.startContainerService(
                    packageName = MicroGCheckinSeeder.GMS_PACKAGE,
                    serviceClassName = MicroGProvider.MCS_SERVICE,
                    virtualUserId = user,
                    requireForeground = false,
                    action = MicroGProvider.MCS_CONNECT_ACTION,
                )
            }
            handler.postDelayed(this, WAKE_INTERVAL_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val packageName = intent?.getStringExtra(EXTRA_PACKAGE)
        if (packageName == null) {
            // A restart with no target (e.g. the system recreating the service) has nothing
            // to keep alive.
            stopSelf()
            return START_NOT_STICKY
        }

        userId = intent.getIntExtra(EXTRA_USER_ID, -1)
        startForegroundCompat()
        // The engine creates its own channels lazily, when it first starts the daemon for a
        // container -- i.e. after Application.onCreate has already run. This service starts
        // on the same launch, just after, so it is the first point at which the engine's
        // names can be overwritten again with neutral ones. Measured: without this the
        // channel reads "blackbox_core" in Android's notification settings for Duplika.
        EngineNotificationSilencer.blockChannel(this)
        handler.removeCallbacks(relabel)
        RELABEL_DELAYS_MS.forEach { handler.postDelayed(relabel, it) }
        handler.removeCallbacks(reconnect)
        if (userId >= 0) {
            handler.postDelayed(reconnect, WAKE_INTERVAL_MS)
        }
        Slog.i(
            Slog.LAUNCH,
            "Keeping the host alive while $packageName is open (user $userId)",
        )
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(relabel)
        handler.removeCallbacks(reconnect)
        super.onDestroy()
    }

    private fun startForegroundCompat() {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Running clones",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "Shown while a cloned app is open"
                    setShowBadge(false)
                },
            )
        }

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_clone)
            .setContentTitle(getString(R.string.clone_keepalive_title))
            .setContentText(getString(R.string.clone_keepalive_text))
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setSilent(true)
            .build()

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
        } else {
            0
        }
        ServiceCompat.startForeground(this, NOTIFICATION_ID, notification, type)
    }

    companion object {
        private const val CHANNEL_ID = "clone_keepalive"
        private const val NOTIFICATION_ID = 4711
        /** When to re-label after a launch, bracketing how long the guest takes to come up. */
        private val RELABEL_DELAYS_MS = longArrayOf(3_000L, 10_000L, 30_000L)

        private const val WAKE_INTERVAL_MS = 120_000L

        const val EXTRA_PACKAGE = "package_name"
        const val EXTRA_USER_ID = "virtual_user_id"

        /**
         * Starts the keep-alive for a clone the user just launched. Callers are in the
         * foreground when they do this, so the background-start restriction does not apply.
         * Failure is logged, never fatal: a device that refuses the service still gets a
         * working clone, only without the protection.
         */
        fun start(context: Context, packageName: String, virtualUserId: Int) {
            val intent = Intent(context, CloneKeepAliveService::class.java)
                .putExtra(EXTRA_PACKAGE, packageName)
                .putExtra(EXTRA_USER_ID, virtualUserId)
            runCatching {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            }.onFailure {
                Slog.w(Slog.LAUNCH, "Could not start clone keep-alive: ${it.message}")
            }
        }

        /** Stops the keep-alive; called when the user is back in Duplika. Idempotent. */
        fun stop(context: Context) {
            runCatching { context.stopService(Intent(context, CloneKeepAliveService::class.java)) }
        }
    }
}
