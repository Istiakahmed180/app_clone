package co.tdevs.duplika

import android.app.Application
import android.content.Context
import co.tdevs.duplika.diagnostics.CrashCapture
import co.tdevs.duplika.diagnostics.DiagCategory
import co.tdevs.duplika.diagnostics.DiagSource
import co.tdevs.duplika.diagnostics.DiagnosticLogger
import androidx.work.Configuration
import androidx.work.WorkManager
import co.tdevs.duplika.native.ClonePushRefreshWorker
import co.tdevs.duplika.native.EngineNotificationSilencer
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

        // Before the engine: it starts its daemon foreground service while attaching, and
        // Android never raises a notification channel's importance after the first creation,
        // so blocking the channel here is what keeps the engine's "Core services are running"
        // notice off the shade.
        EngineNotificationSilencer.blockChannel(this)

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
        // The engine's own WorkManager hook runs during attachBaseContext, i.e. before
        // androidx.startup's InitializationProvider can initialise WorkManager (measured: it
        // logs "Failed to get WorkManager instance"), and in a minified release build the
        // provider does not leave WorkManager usable by the time this runs. Initialise it
        // explicitly when it is not already up, so scheduling never depends on the engine's
        // ordering.
        if (!WorkManager.isInitialized()) {
            runCatching { WorkManager.initialize(this, Configuration.Builder().build()) }
                .onFailure {
                    DiagnosticLogger.info(
                        DiagSource.ANDROID,
                        DiagCategory.APP_LIFECYCLE,
                        "WorkManager initialisation skipped: ${it.message}",
                    )
                }
        }

        // A notice an earlier launch already posted (before the channel was blocked) is not
        // removed by changing the channel, so cancel it explicitly.
        EngineNotificationSilencer.cancelPostedNotification(this)

        // Idempotent (KEEP): reconnects each clone's microG push channel while the app is in
        // the background, which a closed clone cannot do for itself on aggressive OEM builds.
        ClonePushRefreshWorker.schedule(this)
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
