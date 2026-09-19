package co.tdevs.duplika.native.blackbox

import co.tdevs.duplika.native.Slog
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.FutureTask
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

/**
 * Answers "is this clone installed / running?" within a deadline, whether or not the engine
 * feels like answering.
 *
 * These two reads are not work — they are questions the home screen asks about every clone it
 * draws, one after another, before it can render anything at all. They are also synchronous
 * binder calls into the engine's server process, and that process is demonstrably able to
 * stop answering for a minute at a time while it is otherwise alive. Measured on API 35,
 * right after a clone was deleted:
 *
 *     10:35:00  Call started  : isAppInstalledInProfile
 *     10:35:21  Duplika.Engine: A native call has not answered in 21s      <- lane stepped aside
 *     10:35:47  ActivityManager: Kill app due to repeated failure to freeze binder
 *     10:35:49  BlackManager  : PackageManager service died during isInstalled check
 *     10:35:49  Call succeeded: isAppInstalledInProfile (49091 ms)
 *
 * [co.tdevs.duplika.native.EngineLane] keeps such a call from stranding the ones behind it,
 * and that is why the app picker now opens while the engine is wedged. It cannot help here:
 * the status read is not waiting behind anything, it *is* the wedged call, and the grid has
 * nothing to draw until it returns. So deleting a clone and coming back to the home screen
 * left it loading for the best part of a minute.
 *
 * A status read therefore gets [DEADLINE_MILLIS] and no more. A healthy answer arrives in
 * single-digit milliseconds, so the deadline is only ever reached by an engine that has
 * stopped answering — and when it is, the question is answered from what the engine last
 * said rather than from nothing. The call itself is not cancelled (a binder transaction in
 * flight cannot be), it is left to land on its own; when it does, its answer is kept and the
 * next refresh shows it. The screen stays honest and never stops drawing.
 *
 * Reads are also deduplicated by key, so a grid that refreshes while the engine is wedged
 * joins the outstanding question instead of asking it again on another thread.
 */
internal object EngineStatusRead {

    /**
     * Long enough that a working engine always answers inside it — its own service-creation
     * backoff is 2 s, and an answered `isInstalled` is a map lookup behind one binder hop —
     * and short enough that a wedged one costs a refresh rather than a screen.
     */
    private const val DEADLINE_MILLIS = 1_500L

    /**
     * Cached rather than fixed: a thread that is inside a wedged binder call is unusable
     * until it returns, so the pool has to be able to grow past the ones it has lost.
     * Daemon threads, because none of this is work the process should be kept alive for.
     */
    private val readers = Executors.newCachedThreadPool { runnable ->
        Thread(runnable, "duplika-status-read").apply { isDaemon = true }
    }

    private val lastKnown = ConcurrentHashMap<String, Boolean>()
    private val inFlight = ConcurrentHashMap<String, Read>()

    /**
     * Runs [read] and returns its answer, or — if it does not arrive in time — the last
     * answer [read] gave for [key], or [optimistic] if it has never given one.
     *
     * [optimistic] is what the caller would rather be wrong about on a screen that has no
     * information yet: a clone whose profile exists is reported installed rather than
     * broken, and a clone is reported stopped rather than running.
     */
    fun answer(key: String, optimistic: Boolean, read: () -> Boolean): Boolean {
        var mine: Read? = null
        val task = inFlight.computeIfAbsent(key) { Read(key, read).also { mine = it } }
        mine?.let(readers::execute)

        return try {
            task.get(DEADLINE_MILLIS, TimeUnit.MILLISECONDS)
        } catch (_: TimeoutException) {
            val fallback = lastKnown[key] ?: optimistic
            Slog.w(
                Slog.BCORE,
                "The engine did not answer '$key' within ${DEADLINE_MILLIS}ms; " +
                    "reporting $fallback and leaving the question outstanding",
            )
            fallback
        } catch (error: Throwable) {
            // The read threw, or this thread was interrupted waiting for it. Either way the
            // engine has told us nothing, so the same fallback applies.
            Slog.w(Slog.BCORE, "Engine status read '$key' failed: ${error.message}")
            lastKnown[key] ?: optimistic
        }
    }

    /**
     * Clears what is remembered about one container, so a profile that is deleted and its
     * virtual user id later reused does not inherit the old container's status.
     */
    fun forget(virtualUserId: Int) {
        val suffix = ":$virtualUserId:"
        lastKnown.keys.removeAll { it.contains(suffix) }
    }

    /**
     * Keeps [lastKnown] current and [inFlight] clean from whenever the call actually lands,
     * which for an abandoned one is long after the caller has been answered.
     */
    private class Read(
        private val key: String,
        read: () -> Boolean,
    ) : FutureTask<Boolean>(read) {

        override fun done() {
            inFlight.remove(key, this)
            runCatching { lastKnown[key] = get() }
        }
    }
}
