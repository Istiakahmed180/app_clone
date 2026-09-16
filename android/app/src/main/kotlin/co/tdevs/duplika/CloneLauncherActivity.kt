package co.tdevs.duplika

import android.app.Activity
import android.os.Bundle
import android.widget.Toast
import co.tdevs.duplika.diagnostics.DiagCategory
import co.tdevs.duplika.diagnostics.DiagSource
import co.tdevs.duplika.diagnostics.DiagnosticLogger
import co.tdevs.duplika.native.EngineErrorCodes
import co.tdevs.duplika.native.EngineResult
import co.tdevs.duplika.native.RealVirtualizationEngine
import co.tdevs.duplika.native.Slog

/**
 * Opens one clone straight from a home-screen shortcut.
 *
 * Deliberately has no UI of its own: the point of a shortcut is to reach the guest app
 * without passing through Duplika, so this starts the container and finishes.
 */
class CloneLauncherActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val profileId = intent?.getStringExtra(EXTRA_PROFILE_ID)
        val packageName = intent?.getStringExtra(EXTRA_PACKAGE_NAME)
        val operationId = "shortcut_${System.currentTimeMillis().toString(36)}"

        if (profileId.isNullOrBlank() || packageName.isNullOrBlank()) {
            Slog.w(Slog.LAUNCH, "Shortcut carried no profile; ignoring")
            finish()
            return
        }

        // Given its own correlation id, because a shortcut launch never passes through
        // Flutter: without one, the engine and guest-process events it produces would
        // arrive in the console untied to anything.
        DiagnosticLogger.withOperation(operationId, "shortcut launch $packageName") {
            DiagnosticLogger.info(
                DiagSource.ACTIVITY,
                DiagCategory.ACTIVITY,
                "Shortcut launch requested for $packageName",
                packageName = packageName,
                profileId = profileId,
                metadata = mapOf("event" to "SHORTCUT_LAUNCH_STARTED"),
            )

            val engine = RealVirtualizationEngine(applicationContext, DuplikaApplication.engine)
            // The profile mapping refuses to answer rather than guess when its storage is
            // unreadable, and refusing is right — a guessed id opens the wrong container.
            // But this entry point has no Flutter layer above it to turn a thrown failure
            // into a message, and an uncaught one here crashes the home screen, so the
            // refusal is caught and said out loud like any other launch failure.
            val result = try {
                engine.launchProfile(profileId, packageName)
            } catch (error: Throwable) {
                Slog.e(Slog.LAUNCH, "Shortcut launch could not be resolved", error)
                EngineResult.Failure(
                    EngineErrorCodes.VIRTUAL_APP_NOT_INSTALLED,
                    "This clone could not be opened. Open Duplika and try again.",
                )
            }

            when (result) {
                is EngineResult.Success ->
                    Slog.i(Slog.LAUNCH, "Shortcut launched $packageName")

                is EngineResult.Failure -> {
                    // A shortcut can outlive the clone it points at, so say why rather than
                    // failing silently on the home screen.
                    Slog.w(Slog.LAUNCH, "Shortcut launch failed: ${result.code}")
                    Toast.makeText(this, result.message, Toast.LENGTH_LONG).show()
                }
            }
        }

        finish()
    }

    companion object {
        const val EXTRA_PROFILE_ID = "profileId"
        const val EXTRA_PACKAGE_NAME = "packageName"
    }
}
