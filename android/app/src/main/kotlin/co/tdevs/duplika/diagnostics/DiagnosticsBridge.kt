package co.tdevs.duplika.diagnostics

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

/**
 * The Flutter end of native diagnostics.
 *
 * Two channels, because the two jobs have different shapes: a method channel for
 * request/response (system information, history, probes, sharing) and an event channel
 * for the live stream. The alternative — Flutter polling for new events — either lags
 * behind a failure or wakes the app up for nothing, and the native side already knows
 * the moment it has something to say.
 *
 * Kept separate from `native/NativeBridge` on purpose. Diagnostics must keep working
 * when the virtualization bridge is the thing that is broken, and a shared channel
 * would put an engine-shutdown guard in front of the console's own calls.
 */
class DiagnosticsBridge(context: Context) {

    private val appContext = context.applicationContext
    private val system = SystemDiagnostics(appContext)
    private val mainHandler = Handler(Looper.getMainLooper())

    private var methods: MethodChannel? = null
    private var events: EventChannel? = null
    private var sink: EventChannel.EventSink? = null
    private var activity: Activity? = null

    // Reading the merged history parses every stored line, and a probe does real file
    // I/O. Neither belongs on the platform thread.
    private val worker = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "duplika-diagnostics-bridge")
    }

    fun attach(messenger: BinaryMessenger) {
        methods = MethodChannel(messenger, METHOD_CHANNEL).also {
            it.setMethodCallHandler(::onMethodCall)
        }
        events = EventChannel(messenger, EVENT_CHANNEL).also {
            it.setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink) {
                        sink = eventSink
                        // Replay what happened before anyone was listening. Without this
                        // every event from process start until the console opens would be
                        // visible only after a manual history reload.
                        DiagnosticLogger.replayTo(::emit)
                        DiagnosticLogger.listener = ::emit
                    }

                    override fun onCancel(arguments: Any?) {
                        DiagnosticLogger.listener = null
                        sink = null
                    }
                },
            )
        }
    }

    fun bindActivity(activity: Activity) {
        this.activity = activity
    }

    fun unbindActivity() {
        activity = null
    }

    fun detach() {
        DiagnosticLogger.listener = null
        sink = null
        methods?.setMethodCallHandler(null)
        methods = null
        events?.setStreamHandler(null)
        events = null
        worker.shutdown()
    }

    /** Live events are posted to the main looper, which is where an EventSink must be used. */
    private fun emit(event: DiagnosticEvent) {
        val payload = event.toMap()
        mainHandler.post {
            try {
                sink?.success(payload)
            } catch (_: Throwable) {
                // The engine was torn down between the post and the delivery. The event
                // is already on disk; dropping the live copy is the right outcome.
            }
        }
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSystemInfo" -> async(result) { system.collect() }

            "readEvents" -> {
                val limit = call.argument<Int>("limit") ?: 2000
                async(result) {
                    DiagnosticLogger.history(limit.coerceIn(1, 20_000)).map { it.toMap() }
                }
            }

            "clearEvents" -> async(result) {
                DiagnosticLogger.clear()
                // Recorded after the clear, so the log always says who emptied it rather
                // than starting from an unexplained gap.
                DiagnosticLogger.info(
                    DiagSource.SYSTEM,
                    DiagCategory.APP_LIFECYCLE,
                    "Native diagnostic history cleared from the developer console",
                )
                true
            }

            "runStorageDiagnostics" -> probe(result) { StorageDiagnostics(appContext).run() }

            "runWebViewDiagnostics" -> probe(result) { WebViewDiagnostics(appContext).run() }

            "runPermissionDiagnostics" -> probe(result) { PermissionDiagnostics(appContext).run() }

            "runNotificationDiagnostics" -> probe(result) { NotificationDiagnostics(appContext).run() }

            "runJobDiagnostics" -> probe(result) { JobDiagnostics(appContext).run() }

            "selfTest" -> async(result) { selfTest() }

            "shareReport" -> {
                val paths = call.argument<List<String>>("paths").orEmpty()
                val subject = call.argument<String>("subject") ?: "Duplika diagnostics"
                result.success(share(paths, subject))
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Proves native capture works on this build, on this device.
     *
     * Raises a real exception through a real code path and records the real result,
     * stack trace included — that record *is* the proof, so it stays at `ERROR`.
     *
     * The category is deliberately NOT [DiagCategory.CRASH]: nothing crashed here, the
     * exception is caught on the line below, and filing it as a crash put it at the top
     * of the console's error list next to genuine unhandled failures. `selfTest` in the
     * metadata is what the UI groups on.
     */
    private fun selfTest(): Map<String, Any?> {
        DiagnosticLogger.info(
            DiagSource.SYSTEM,
            DiagCategory.APP_LIFECYCLE,
            "Native diagnostics self-test started",
            metadata = mapOf("selfTest" to "true"),
        )

        val thrown = try {
            throw IllegalStateException("Deliberate self-test exception from DiagnosticsBridge")
        } catch (error: IllegalStateException) {
            DiagnosticLogger.error(
                DiagSource.KOTLIN,
                DiagCategory.APP_LIFECYCLE,
                "Native diagnostics self-test exception captured",
                error,
                metadata = mapOf("selfTest" to "true"),
            )
            error
        }

        DiagnosticLogger.flushNow()
        return mapOf(
            "captured" to true,
            "exceptionType" to thrown.javaClass.name,
            "processName" to DiagnosticLogger.currentProcessName(),
        )
    }

    /**
     * Hands the report files to the Android share sheet.
     *
     * Through `FileProvider` and a per-file content URI with read permission granted for
     * the chooser only. No storage permission is involved, and nothing is copied into
     * shared storage: the files stay in Duplika's own cache, which the system can
     * reclaim, and the receiving app gets a temporary grant.
     */
    private fun share(paths: List<String>, subject: String): Boolean {
        val files = paths.map(::File).filter { it.isFile }
        if (files.isEmpty()) {
            DiagnosticLogger.warning(
                DiagSource.SYSTEM,
                DiagCategory.APP_LIFECYCLE,
                "Share was asked for with no readable report files",
            )
            return false
        }

        return try {
            val uris = ArrayList<Uri>(files.size)
            files.forEach { file ->
                uris += FileProvider.getUriForFile(appContext, FILE_PROVIDER_AUTHORITY, file)
            }

            val send = Intent(if (uris.size == 1) Intent.ACTION_SEND else Intent.ACTION_SEND_MULTIPLE)
                .setType("text/plain")
                .putExtra(Intent.EXTRA_SUBJECT, subject)
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            if (uris.size == 1) {
                send.putExtra(Intent.EXTRA_STREAM, uris.first())
            } else {
                send.putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
            }

            val chooser = Intent.createChooser(send, subject)
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

            val host = activity
            if (host != null) {
                host.startActivity(chooser)
            } else {
                // No foreground activity: the chooser needs its own task.
                chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                appContext.startActivity(chooser)
            }

            DiagnosticLogger.info(
                DiagSource.SYSTEM,
                DiagCategory.APP_LIFECYCLE,
                "Diagnostics report shared (${files.size} file(s))",
            )
            true
        } catch (error: Throwable) {
            DiagnosticLogger.error(
                DiagSource.SYSTEM,
                DiagCategory.APP_LIFECYCLE,
                "Sharing the diagnostics report failed",
                error,
            )
            false
        }
    }

    /**
     * Runs a probe off the platform thread and reports how many events it produced.
     *
     * The count is what tells the console whether a probe found anything worth saying,
     * as opposed to having simply run.
     */
    private fun probe(result: MethodChannel.Result, run: () -> ProbeReport) {
        async(result) {
            val before = DiagnosticLogger.retainedEventCount()
            val report = run()
            report.toMap((DiagnosticLogger.retainedEventCount() - before).coerceAtLeast(0))
        }
    }

    private fun async(result: MethodChannel.Result, work: () -> Any?) {
        try {
            worker.execute {
                val outcome = runCatching(work)
                mainHandler.post {
                    outcome.fold(
                        onSuccess = { value -> replySafely { result.success(value) } },
                        onFailure = { error ->
                            // Diagnostics failing is itself a diagnostic. Report it as an
                            // error to Flutter rather than leaving the future pending.
                            DiagnosticLogger.error(
                                DiagSource.SYSTEM,
                                DiagCategory.APP_LIFECYCLE,
                                "A diagnostics call failed",
                                error as? Throwable,
                            )
                            replySafely {
                                result.error(
                                    "DIAGNOSTICS_FAILED",
                                    error.message ?: "The diagnostics call failed.",
                                    null,
                                )
                            }
                        },
                    )
                }
            }
        } catch (_: RejectedExecutionException) {
            replySafely { result.error("DIAGNOSTICS_SHUTTING_DOWN", "Duplika is closing.", null) }
        }
    }

    private inline fun replySafely(reply: () -> Unit) {
        if (methods == null) return
        try {
            reply()
        } catch (_: Throwable) {
            // Replying on a channel that has since been torn down throws.
        }
    }

    companion object {
        const val METHOD_CHANNEL = "duplika/diagnostics"
        const val EVENT_CHANNEL = "duplika/diagnostics/events"

        /** Must match the `android:authorities` of the provider in AndroidManifest.xml. */
        const val FILE_PROVIDER_AUTHORITY = "co.tdevs.duplika.diagnostics.fileprovider"
    }
}
