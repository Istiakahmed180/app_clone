package co.tdevs.duplika

import android.app.Application
import android.os.Build
import android.webkit.WebView
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

    fun configure() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return

        val processName = Application.getProcessName()
        val suffix = "duplika_" + processName.replace(Regex("[^A-Za-z0-9_-]"), "_")

        try {
            WebView.setDataDirectorySuffix(suffix)
            Slog.i(TAG, "WebView data directory configured for process=$processName suffix=$suffix")
        } catch (error: IllegalStateException) {
            // A component initialized WebView earlier in this process. Keep the
            // original failure visible; do not silently select a conflicting path.
            Slog.e(TAG, "WebView data directory was already initialized for process=$processName", error)
        } catch (error: IllegalArgumentException) {
            Slog.e(TAG, "Invalid WebView data-directory suffix for process=$processName", error)
        }
    }
}
