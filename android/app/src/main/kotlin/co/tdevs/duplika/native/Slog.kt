package co.tdevs.duplika.native

import android.util.Log
import co.tdevs.duplika.diagnostics.DiagCategory
import co.tdevs.duplika.diagnostics.DiagLevel
import co.tdevs.duplika.diagnostics.DiagSource
import co.tdevs.duplika.diagnostics.DiagnosticLogger

/**
 * Controlled logging for the virtualization stack.
 *
 * Only package names, profile ids and engine status are ever logged — never target
 * application data, credentials or tokens.
 *
 * Still writes to Logcat exactly as before, and additionally forwards to
 * [DiagnosticLogger] so the same lines appear in the in-app Developer Console. Keeping
 * this type is what made the diagnostics work additive: the ~55 existing call sites in
 * the engine, installer, launcher and profile manager became structured events without
 * being rewritten, and the boundaries that deserved a richer event
 * (`ENGINE_INITIALIZATION_FAILED`, `SPLIT_APK_INSTALL`, ...) then got one explicitly.
 *
 * New diagnostics on new code paths should call [DiagnosticLogger] directly, where the
 * source, category, package and profile are stated rather than inferred from a tag.
 */
object Slog {
    private const val ROOT = "Duplika"

    const val ENGINE = "$ROOT.Engine"

    /**
     * The backend itself, as distinct from Duplika's engine layer.
     *
     * Separated so the console can filter Bcore's own behaviour — its service backoff,
     * its null-binder window, its install verdicts — apart from Duplika's decisions
     * about profiles and containers. When something goes wrong, which of the two is
     * talking is usually the first thing worth knowing.
     */
    const val BCORE = "$ROOT.Bcore"
    const val PROFILE = "$ROOT.Profile"
    const val INSTALL = "$ROOT.Install"
    const val LAUNCH = "$ROOT.Launch"
    const val POWER = "$ROOT.Power"

    /**
     * Attribution for the existing tags.
     *
     * A close-enough source beats `SYSTEM` for every legacy line: without this the
     * console's source and category filters would be blind to everything the engine
     * logged before diagnostics existed.
     */
    private val ATTRIBUTION: Map<String, Pair<DiagSource, DiagCategory>> = mapOf(
        ENGINE to (DiagSource.VIRTUAL_ENGINE to DiagCategory.APP_LIFECYCLE),
        BCORE to (DiagSource.BCORE to DiagCategory.APP_LIFECYCLE),
        PROFILE to (DiagSource.VIRTUAL_ENGINE to DiagCategory.PROFILE),
        INSTALL to (DiagSource.PACKAGE_INSTALLER to DiagCategory.INSTALL),
        LAUNCH to (DiagSource.GUEST_PROCESS to DiagCategory.LAUNCH),
        POWER to (DiagSource.ANDROID to DiagCategory.APP_LIFECYCLE),
        "$ROOT.WebView" to (DiagSource.WEBVIEW to DiagCategory.WEBVIEW),
    )

    fun i(tag: String, message: String) {
        Log.i(tag, message)
        forward(DiagLevel.INFO, tag, message, null)
    }

    fun w(tag: String, message: String) {
        Log.w(tag, message)
        forward(DiagLevel.WARNING, tag, message, null)
    }

    fun e(tag: String, message: String, error: Throwable? = null) {
        Log.e(tag, message, error)
        forward(DiagLevel.ERROR, tag, message, error)
    }

    /**
     * The Logcat write above already happened, so [DiagnosticLogger] is told not to
     * mirror — otherwise every one of these lines would appear twice in a `logcat`
     * capture.
     */
    private fun forward(level: DiagLevel, tag: String, message: String, error: Throwable?) {
        if (!DiagnosticLogger.isInitialized) return
        val (source, category) = ATTRIBUTION[tag] ?: (DiagSource.KOTLIN to DiagCategory.UNKNOWN)
        DiagnosticLogger.log(
            level = level,
            source = source,
            category = category,
            message = message,
            error = error,
            metadata = mapOf("tag" to tag),
            mirrorToLogcat = false,
        )
    }
}
