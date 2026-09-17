package co.tdevs.duplika.native.blackbox

import android.os.Looper
import android.os.Process
import co.tdevs.duplika.native.Slog
import kotlin.system.exitProcess

/**
 * Lets a clone die when its main thread has already died, instead of freezing.
 *
 * Bcore installs a global handler that swallows whole classes of crash rather than letting
 * the process end — `SimpleCrashFix` catches anything whose message or stack mentions a
 * Context, Play services or a WebView, and `CrashMonitor` reports "Crash successfully
 * recovered" for the rest. On a background thread that is a reasonable trade. On the main
 * thread it is not, and it cannot be: by the time `uncaughtException` runs there,
 * `Looper.loop()` has already unwound. There is no loop left to deliver the next frame,
 * the next touch, or the `finish()` that would close the window.
 *
 * What is left is a process that is alive, holds a visible window, and answers nothing:
 *
 *     ANR in co.tdevs.duplika:p11
 *     Reason: Input dispatching timed out (... LoginActivity (server) is not responding)
 *     ".android.gms:ui"  native: art::ThreadList::WaitForOtherNonDaemonThreadsToExit
 *                        native: art::JII::DestroyJavaVM
 *
 * That is what "nothing works" looks like from the user's side: a screen that draws, takes
 * no input, and never comes back — with no crash anywhere to explain it. Worse, the zombie
 * keeps the resources its process owned, so the *next* attempt fails too: a stuck guest
 * holding Chromium's WebView lock is what kept a clone's Google sign-in broken until the
 * whole clone was force-stopped (see [GuestWebViewDataDirRepair]).
 *
 * This wraps whatever handler is in place rather than replacing it, so Bcore still gets to
 * log and report exactly as it does now. The only change is the last step: if the crash was
 * on the main thread and the process is somehow still running afterwards, it is ended. A
 * clone that closes can be opened again; a clone that freezes cannot.
 *
 * Background threads are left entirely alone — Bcore's recovery there is what keeps clones
 * running through non-fatal faults, and nothing about it is unsound.
 */
object GuestFatalCrashRepair {

    @Volatile
    private var installed = false

    /**
     * Idempotent, and deliberately installed after Bcore's handler so that this one wraps
     * it rather than the other way round.
     */
    @Synchronized
    fun install() {
        if (installed) return
        try {
            val mainThread = Looper.getMainLooper()?.thread ?: return
            val engineHandler = Thread.getDefaultUncaughtExceptionHandler()
            val platformHandler = platformHandlerUnder(engineHandler)

            Thread.setDefaultUncaughtExceptionHandler { thread, error ->
                // Bcore's handler first: its logging and reporting are the only record of
                // what happened, and on a background thread its recovery is the whole
                // behaviour. If it decides to end the process, nothing below ever runs.
                runCatching { engineHandler?.uncaughtException(thread, error) }

                if (thread === mainThread) {
                    Slog.e(
                        Slog.BCORE,
                        "Main thread of this clone died; ending the process rather than " +
                            "leaving its window frozen",
                        error,
                    )
                    end(platformHandler, thread, error)
                }
            }

            installed = true
            Slog.i(Slog.BCORE, "Guest fatal crash repair installed")
        } catch (error: Throwable) {
            Slog.w(Slog.BCORE, "Guest fatal crash repair unavailable: ${error.message}")
        }
    }

    /**
     * Ends the process the way the platform would, which is not the same as killing it.
     *
     * `RuntimeInit$KillApplicationHandler` reports the crash to the activity manager before
     * it kills, and that report is what stops a crash *loop*: the activity manager counts
     * an app's crashes and gives up relaunching one that keeps failing at startup. A bare
     * `killProcess` skips the report, so from the system's side a process merely vanished
     * while its task was still on screen — and it starts it again, forever. Measured: an
     * activity that could not inflate its layout relaunched about ten times a second until
     * the clone was force-stopped.
     *
     * The kill and exit stay as the fallback for a process where the platform handler
     * cannot be found: a loop is bad, a frozen window is worse.
     */
    private fun end(
        platformHandler: Thread.UncaughtExceptionHandler?,
        thread: Thread,
        error: Throwable,
    ): Nothing {
        runCatching { platformHandler?.uncaughtException(thread, error) }
        runCatching { Process.killProcess(Process.myPid()) }
        exitProcess(10)
    }

    /**
     * Digs the platform's own handler out from under whatever Bcore layered on top of it.
     *
     * Each handler in the chain keeps the one it replaced in a field, so following fields of
     * that type from the outermost handler reaches the platform's — `SimpleCrashFix` holds
     * one, `CrashMonitor` holds another. Matched by class rather than by field name, which
     * neither the engine's obfuscation nor a platform version changes.
     */
    private fun platformHandlerUnder(
        handler: Thread.UncaughtExceptionHandler?,
    ): Thread.UncaughtExceptionHandler? {
        var current = handler
        // Bounded: the chain is two or three deep in practice, and a cycle must not hang
        // the only code that can end a crashed process.
        repeat(8) {
            if (current == null) return null
            if (current!!.javaClass.name.startsWith("com.android.internal.os.")) return current
            current = wrappedHandlerOf(current!!)
        }
        return null
    }

    private fun wrappedHandlerOf(handler: Thread.UncaughtExceptionHandler): Thread.UncaughtExceptionHandler? {
        var cursor: Class<*>? = handler.javaClass
        while (cursor != null && cursor != Any::class.java) {
            for (field in cursor.declaredFields) {
                if (!Thread.UncaughtExceptionHandler::class.java.isAssignableFrom(field.type)) continue
                val value = runCatching {
                    field.isAccessible = true
                    field.get(handler)
                }.getOrNull()
                if (value is Thread.UncaughtExceptionHandler && value !== handler) return value
            }
            cursor = cursor.superclass
        }
        return null
    }
}
