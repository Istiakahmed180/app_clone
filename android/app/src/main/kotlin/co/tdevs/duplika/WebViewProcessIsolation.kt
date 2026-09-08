package co.tdevs.duplika

import android.app.Application
import android.os.Build
import android.webkit.WebView
import co.tdevs.duplika.diagnostics.DiagCategory
import co.tdevs.duplika.diagnostics.DiagSource
import co.tdevs.duplika.diagnostics.DiagnosticLogger
import co.tdevs.duplika.native.Slog

/**
 * Gives each real Duplika process its own WebView data directory.
 *
 * Bcore hosts different guest activities in different real host processes
 * (`:p0`, `:p1`, ...), while the guest Application can initialize WebView in
 * each of them. Android requires distinct WebView data directories in that
 * situation, and the suffix must be set before WebView is touched.
 */
object WebViewProcessIsolation {
    private const val TAG = "Duplika.WebView"

    /**
     * What this process ended up with, for the WebView diagnostics probe.
     *
     * Recorded rather than recomputed: by the time anyone asks, `setDataDirectorySuffix`
     * has already either taken effect or thrown, and re-deriving the name would report
     * the suffix that *would* have been chosen instead of the one in force.
     */
    @Volatile
    var configuredSuffix: String? = null
        private set

    /** `configured`, `already-initialized`, `invalid-suffix`, or `unsupported-api`. */
    @Volatile
    var outcome: String = "not-attempted"
        private set

    fun configure() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            outcome = "unsupported-api"
            return
        }

        val processName = Application.getProcessName()
        val suffix = "duplika_" + processName.replace(Regex("[^A-Za-z0-9_-]"), "_")

        try {
            WebView.setDataDirectorySuffix(suffix)
            configuredSuffix = suffix
            outcome = "configured"
            Slog.i(TAG, "WebView data directory configured for process=$processName suffix=$suffix")
        } catch (error: IllegalStateException) {
            // A component initialized WebView earlier in this process. Keep the
            // original failure visible; do not silently select a conflicting path.
            outcome = "already-initialized"
            Slog.e(TAG, "WebView data directory was already initialized for process=$processName", error)
            recordFailure(processName, suffix, error)
        } catch (error: IllegalArgumentException) {
            outcome = "invalid-suffix"
            Slog.e(TAG, "Invalid WebView data-directory suffix for process=$processName", error)
            recordFailure(processName, suffix, error)
        }
    }

    /**
     * A second, richer event on top of the Slog line above.
     *
     * This particular failure is the one that later surfaces inside a guest as
     * "Using WebView from more than one process", several seconds and several layers
     * away from its cause, so it is worth carrying the process and suffix that caused
     * it rather than only a message.
     */
    private fun recordFailure(processName: String, suffix: String, error: Throwable) {
        DiagnosticLogger.error(
            DiagSource.WEBVIEW,
            DiagCategory.WEBVIEW,
            "WebView data directory could not be isolated for this process",
            error,
            metadata = mapOf(
                "process" to processName,
                "suffix" to suffix,
                "outcome" to outcome,
            ),
        )
    }
}
