package co.tdevs.duplika.native

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Binder
import android.os.IBinder
import android.app.Service

/**
 * Keeps the engine's server process out of the cached state while a clone is open.
 *
 * Bcore runs its own system server — the package, activity and provider services every guest
 * calls into — in a process of its own, `:black`. Nothing in that process is ever visible, so
 * from Android's point of view it is a cached process, and from Android 14 a cached process
 * is *frozen*: its binder threads stop running and every transaction into it fails. Measured
 * on API 35, with a clone in the foreground the whole time:
 *
 *     15:54:56  Keeping the host alive while com.airbnb.android is open
 *     15:55:48  ActivityManager: freezing 25152 co.tdevs.duplika:black
 *     15:55:53  IPCThreadState: Transaction failed because process frozen.
 *               BlackManager: PackageManager service died during resolveContentProvider
 *               ActivityThread: Failed to find provider info for com.google.android.gms.microg.settings
 *               FATAL EXCEPTION: main
 *
 * The engine reacts to that `DeadObjectException` by dropping its cached binder and building
 * a new one, but the process is frozen rather than dead, so the rebuild is refused by its own
 * rate limiter and the guest is handed a null. A guest that asked for something it cannot do
 * without — microG's sign-in screen reading the device's check-in record — dies on the spot.
 *
 * A process bound with `BIND_IMPORTANT` is ranked with the client that bound it rather than
 * cached, so the freezer leaves it alone.
 *
 * It is also held while Duplika's own screen is on, because a server left cached between two
 * clone launches is frozen by the time the next launch calls into it. Measured on API 35, at
 * the moment the user tapped a clone:
 *
 *     16:00:06.254  Launch requested for com.netflix.mediaclient
 *     16:00:06.258  IPCThreadState: Transaction failed because process frozen.
 *     16:00:06.261  :black  reason=14 (FREEZER) subreason=20 (FREEZER BINDER TRANSACTION)
 *     16:00:06.404  :black starts again
 *
 * — the platform killed the server for failing that transaction, and the launch went on with
 * a server that was still starting up. Two clients hold it, and the first is the one that
 * matters: the **guest process**, which binds as its repairs are installed and is genuinely
 * foreground for as long as the clone is on screen. [CloneKeepAliveService] holds it as well,
 * covering the moment before the guest process exists. Both bindings end by themselves — the
 * guest's when its process goes, the host's when the user returns to Duplika.
 *
 * The service itself does nothing and is never called. Being bound is the whole point of it.
 */
class EngineServerAnchor : Service() {

    override fun onBind(intent: Intent?): IBinder = Binder()

    companion object {

        /**
         * Connected for the side effect, so the callbacks have nothing to do. Kept as a
         * single instance because unbinding must pass the very object that was bound.
         */
        private val connection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, binder: IBinder?) = Unit
            override fun onServiceDisconnected(name: ComponentName?) = Unit
        }

        @Volatile
        private var bound = false

        /**
         * Who is asking for the server to stay unfrozen. The binding is one, and it lasts as
         * long as any of them wants it: Duplika's own screen, the keep-alive of a clone the
         * user opened, and the guest process itself. Without this an activity stopping would
         * take the binding out from under a clone that had just started.
         */
        private val holders = mutableSetOf<String>()

        /**
         * Idempotent, and never fatal: a device that refuses the binding keeps the engine's
         * server exactly as exposed to the freezer as it was, which is the behaviour this
         * build had before.
         */
        @Synchronized
        fun hold(context: Context, hostPackage: String? = null, holder: String = HOST) {
            if (!holders.add(holder)) return
            if (bound) return
            // Named rather than built from the context, because a guest's context reports
            // the cloned app's package: `Intent(context, Anchor::class.java)` would name a
            // component of the *guest*, which neither the container nor the platform has.
            val intent = Intent().setComponent(
                ComponentName(
                    hostPackage ?: context.packageName,
                    EngineServerAnchor::class.java.name,
                ),
            )
            val flags = Context.BIND_AUTO_CREATE or Context.BIND_IMPORTANT
            bound = runCatching { context.bindService(intent, connection, flags) }
                .onFailure { Slog.w(Slog.ENGINE, "Could not anchor the engine server: ${it.message}") }
                .getOrDefault(false)
            if (bound) {
                Slog.i(Slog.ENGINE, "Engine server process anchored against the freezer")
            } else {
                holders.remove(holder)
                Slog.w(Slog.ENGINE, "Engine server process could not be anchored")
            }
        }

        /**
         * Gives up one holder's claim, and lets the server process be cached again once no
         * holder is left. Idempotent, and a holder that never held is simply ignored.
         */
        @Synchronized
        fun release(context: Context, holder: String = HOST) {
            if (!holders.remove(holder)) return
            if (holders.isNotEmpty() || !bound) return
            bound = false
            runCatching { context.unbindService(connection) }
        }

        /** Duplika's own screen: held while it is on, so a launch never meets a frozen server. */
        const val UI = "ui"

        /** The keep-alive of a clone the user opened. */
        const val CLONE = "clone"

        /** Anything else in this process, and the guest, which has statics of its own. */
        const val HOST = "host"
    }
}
