package co.tdevs.duplika

import co.tdevs.duplika.diagnostics.DiagCategory
import co.tdevs.duplika.diagnostics.DiagSource
import co.tdevs.duplika.diagnostics.DiagnosticLogger
import co.tdevs.duplika.diagnostics.DiagnosticsBridge
import co.tdevs.duplika.native.NativeBridge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {

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

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (nativeBridge?.onRequestPermissionsResult(requestCode, permissions, grantResults) != true) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
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
