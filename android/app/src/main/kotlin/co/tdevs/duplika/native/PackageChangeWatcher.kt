package co.tdevs.duplika.native

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.core.content.ContextCompat

/**
 * Tells Flutter when the set of installed apps changes, so the picker does not have to
 * guess.
 *
 * The picker re-reads the device when it opens, when Duplika returns to the foreground and
 * when the list is pulled down, and those three cover almost everything — installing an
 * app from Play means leaving Duplika and coming back, which is a resume. What they do not
 * cover is an install that happens while Duplika is *already* in front: a sideload
 * finishing in the background, an update Play applies on its own, an uninstall from a
 * notification. Those left a row that could only fail, or an app the user had just
 * installed and could not find, until something else happened to prompt a refresh.
 *
 * Registered against the context rather than declared in the manifest, which is the only
 * thing that works: since Android 8 a manifest-declared receiver is not delivered
 * `PACKAGE_ADDED` at all. So this is live exactly while the Flutter engine is attached —
 * while there is a screen that could care — and costs nothing the rest of the time.
 *
 * It reports only *that* something changed, never what. The picker's answer to any of
 * these is the same: read the device again. Naming the package would invite the UI to
 * patch its list from a broadcast, which is how a list drifts out of step with the device
 * it claims to describe.
 */
class PackageChangeWatcher(context: Context, private val onChanged: () -> Unit) {

    private val appContext = context.applicationContext

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val packageName = intent?.data?.schemeSpecificPart
            // Duplika updating itself is not news about the device's apps, and arrives
            // just as the process is being torn down.
            if (packageName == appContext.packageName) {
                return
            }
            // An update arrives as REMOVED(replacing) + ADDED. Dropping the first half
            // spares a listing that would be immediately redone, and — more to the point —
            // spares the moment in between where the app genuinely is not installed and a
            // listing would drop the row and put it straight back.
            if (intent?.action == Intent.ACTION_PACKAGE_REMOVED &&
                intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)
            ) {
                return
            }
            Slog.i(Slog.INSTALL, "Packages changed (${intent?.action}); telling the picker")
            onChanged()
        }
    }

    private var registered = false

    fun start() {
        if (registered) {
            return
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED)
            addAction(Intent.ACTION_PACKAGE_REMOVED)
            addAction(Intent.ACTION_PACKAGE_REPLACED)
            // Covers an app being enabled or disabled, which adds or removes a launcher
            // entry without installing anything.
            addAction(Intent.ACTION_PACKAGE_CHANGED)
            // Required for the actions above: without it the filter matches nothing.
            addDataScheme("package")
        }
        // NOT_EXPORTED because every action above is a protected system broadcast — no
        // other app can send one — so there is nothing to gain by accepting them from
        // anywhere else, and API 34 requires the flag to be stated either way.
        ContextCompat.registerReceiver(
            appContext,
            receiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        registered = true
    }

    fun stop() {
        if (!registered) {
            return
        }
        registered = false
        runCatching { appContext.unregisterReceiver(receiver) }
    }
}
