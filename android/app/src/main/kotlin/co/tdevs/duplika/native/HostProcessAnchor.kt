package co.tdevs.duplika.native

import android.app.Service
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Binder
import android.os.IBinder

/**
 * Keeps Duplika's own process alive while a clone the user opened is on screen.
 *
 * A clone runs in `co.tdevs.duplika:pN`, and while it is on screen that process is the
 * foreground one. Duplika's main process is then only a background process of the same app —
 * and on an aggressive OEM build that is enough to have it killed. Measured on the user's
 * OnePlus CPH2605 (Android 15, 3.7 GB RAM, ~130 MB free) twelve seconds after opening a
 * Netflix clone:
 *
 *     15:37:55  Launch requested for com.netflix.mediaclient
 *     15:38:04  process=co.tdevs.duplika:p2  reason=3 (LOW_MEMORY)   <- the container's microG
 *     15:38:09  process=co.tdevs.duplika     reason=3 (LOW_MEMORY)   <- this process
 *     15:38:24  process=co.tdevs.duplika:p1  reason=3 (LOW_MEMORY)
 *
 * The clone was left with a dead microG and a dead host, showing a black screen on Netflix's
 * sign-up step. That is what a foreground service used to prevent, at the cost of a permanent
 * "A cloned app is running" notification.
 *
 * This buys the same standing without telling the user anything: the **guest** binds this
 * service with `BIND_IMPORTANT`, and a process bound that way is ranked with the client that
 * bound it. The client is the clone itself, which is foreground for as long as it is on
 * screen — so the host is ranked foreground too, and the binding ends by itself when the
 * guest process goes.
 *
 * It is the same trick [EngineServerAnchor] plays for the engine's server process; the two
 * are separate classes because a service is anchored in the process its manifest entry names,
 * and these are two different processes.
 *
 * The service does nothing and is never called. Being bound is the whole point of it.
 */
class HostProcessAnchor : Service() {

    override fun onBind(intent: Intent?): IBinder = Binder()

    companion object {

        /** Connected for the side effect, so the callbacks have nothing to do. */
        private val connection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, binder: IBinder?) = Unit
            override fun onServiceDisconnected(name: ComponentName?) = Unit
        }

        @Volatile
        private var bound = false

        /**
         * Idempotent, and never fatal: a device that refuses the binding leaves the host
         * exactly as exposed to the killer as it was.
         *
         * [hostPackage] is named rather than taken from the context, because a guest's
         * context reports the cloned app's package and the component would not resolve.
         */
        @Synchronized
        fun hold(context: Context, hostPackage: String? = null) {
            if (bound) return
            val intent = Intent().setComponent(
                ComponentName(
                    hostPackage ?: context.packageName,
                    HostProcessAnchor::class.java.name,
                ),
            )
            val flags = Context.BIND_AUTO_CREATE or Context.BIND_IMPORTANT
            bound = runCatching { context.bindService(intent, connection, flags) }
                .onFailure { Slog.w(Slog.ENGINE, "Could not anchor the host process: ${it.message}") }
                .getOrDefault(false)
            if (bound) {
                Slog.i(Slog.ENGINE, "Host process anchored against the low-memory killer")
            } else {
                Slog.w(Slog.ENGINE, "Host process could not be anchored")
            }
        }
    }
}
