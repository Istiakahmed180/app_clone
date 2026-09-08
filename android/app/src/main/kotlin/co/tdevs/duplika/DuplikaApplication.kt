package co.tdevs.duplika

import android.app.Application
import android.content.Context
import co.tdevs.duplika.diagnostics.CrashCapture
import co.tdevs.duplika.diagnostics.DiagCategory
import co.tdevs.duplika.diagnostics.DiagSource
import co.tdevs.duplika.diagnostics.DiagnosticLogger
import co.tdevs.duplika.native.VirtualizationEngineAdapter
import co.tdevs.duplika.native.blackbox.BlackBoxEngineAdapter

/**
 * Host application entry point.
 *
 * The virtualization engine must be attached before any other component runs, because
 * it also runs inside the engine's own stub processes (`:p0`, `:p1`, ...) where this
 * same Application class is instantiated. [VirtualizationEngineAdapter.attachBaseContext]
 * is responsible for detecting that case.
 */
class DuplikaApplication : Application() {

    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)

        // First, and before the engine: attaching Bcore rewrites this process's data
        // directory for guest apps, so the log directory has to be resolved against the
        // host's real filesDir while it is still the real one. Doing it first is also
        // what lets the WebView and engine attach steps below be instrumented at all —
        // they are the two most common places for a process to fail on start-up.
        DiagnosticLogger.initialize(base)
        CrashCapture.install()

        DiagnosticLogger.info(
            DiagSource.ANDROID,
            DiagCategory.APP_LIFECYCLE,
            "Process attachBaseContext: ${DiagnosticLogger.currentProcessName()}",
            metadata = mapOf("buildType" to DiagnosticLogger.buildType()),
        )

        WebViewProcessIsolation.configure()
        engine.attachBaseContext(this, base)
    }

    override fun onCreate() {
        super.onCreate()
        engine.onCreate(this)
        DiagnosticLogger.info(
            DiagSource.ANDROID,
            DiagCategory.APP_LIFECYCLE,
            "Process onCreate: ${DiagnosticLogger.currentProcessName()}",
        )
    }

    companion object {
        /**
         * The single engine instance for this process. Swapping this line is the only
         * change needed to move Duplika onto a different virtualization backend.
         */
        @JvmStatic
        val engine: VirtualizationEngineAdapter = BlackBoxEngineAdapter()
    }
}
