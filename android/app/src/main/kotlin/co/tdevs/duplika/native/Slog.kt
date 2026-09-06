package co.tdevs.duplika.native

import android.util.Log

/**
 * Controlled logging for the virtualization stack.
 *
 * Only package names, profile ids and engine status are ever logged — never target
 * application data, credentials or tokens.
 */
object Slog {
    private const val ROOT = "Duplika"

    const val ENGINE = "$ROOT.Engine"
    const val PROFILE = "$ROOT.Profile"
    const val INSTALL = "$ROOT.Install"
    const val LAUNCH = "$ROOT.Launch"
    const val POWER = "$ROOT.Power"

    fun i(tag: String, message: String) = Log.i(tag, message)

    fun w(tag: String, message: String) = Log.w(tag, message)

    fun e(tag: String, message: String, error: Throwable? = null) = Log.e(tag, message, error)
}
