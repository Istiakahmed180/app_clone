package co.tdevs.duplika

import co.tdevs.duplika.diagnostics.DiagCategory
import co.tdevs.duplika.diagnostics.DiagSource
import co.tdevs.duplika.diagnostics.DiagnosticLogger
import co.tdevs.duplika.diagnostics.DiagnosticsBridge
import co.tdevs.duplika.native.NativeBridge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

open class MainActivity : FlutterFragmentActivity() {

    private var nativeBridge: NativeBridge? = null
    private var diagnosticsBridge: DiagnosticsBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Attached before the native bridge, so a failure while wiring the engine bridge
        // is itself recorded and streamable rather than only reaching Logcat.
        diagnosticsBridge = DiagnosticsBridge(applicationContext).also {
            it.attach(flutterEngine.dartExecutor.binaryMessenger)
            it.bindActivity(this)
        }

        nativeBridge = NativeBridge(applicationContext).also {
            it.attach(flutterEngine.dartExecutor.binaryMessenger)
            // Permission dialogs need an Activity, which the application context is not.
            it.bindActivity(this)
        }

        DiagnosticLogger.info(
            DiagSource.ANDROID,
            DiagCategory.APP_LIFECYCLE,
            "Flutter engine configured; platform channels attached",
        )
    }

    /**
     * Holds the engine's server process while this screen is on.
     *
     * A server left cached between two clone launches is frozen by the time the next launch
     * calls into it, and the platform kills it for failing that transaction — measured as
     * `FREEZER BINDER TRANSACTION` in the same second as the user's tap. Holding it from here
     * means the server the launch talks to is always a running one.
     */
    override fun onStart() {
        super.onStart()
        co.tdevs.duplika.native.EngineServerAnchor.hold(
            this,
            holder = co.tdevs.duplika.native.EngineServerAnchor.UI,
        )
    }

    /** Released here, so the server is only anchored while a clone or this screen needs it. */
    override fun onStop() {
        co.tdevs.duplika.native.EngineServerAnchor.release(
            this,
            co.tdevs.duplika.native.EngineServerAnchor.UI,
        )
        super.onStop()
    }

    override fun onResume() {
        super.onResume()
        // Reaching this activity means the user is back in Duplika, so the clone that needed
        // the host kept alive is no longer in the foreground. Stopping here is what keeps the
        // keep-alive scoped to a clone the user actually has open.
        co.tdevs.duplika.native.CloneKeepAliveService.stop(this)
        // Whatever the clone's engine did to its notification channels while it was in the
        // foreground, undo the labelling here.
        co.tdevs.duplika.native.EngineNotificationSilencer.blockChannel(this)
    }

    /**
     * The same re-labelling on the way out.
     *
     * Creating a clone starts containers without ever leaving this activity, so the engine
     * can rename its channels with no [onResume] in between. Every route to Android's own
     * notification settings for Duplika passes through here first, which makes this the
     * last point the app controls before the user can read those names.
     */
    override fun onPause() {
        co.tdevs.duplika.native.EngineNotificationSilencer.blockChannel(this)
        super.onPause()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        nativeBridge?.unbindActivity()
        nativeBridge?.detach()
        nativeBridge = null
        diagnosticsBridge?.unbindActivity()
        diagnosticsBridge?.detach()
        diagnosticsBridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
