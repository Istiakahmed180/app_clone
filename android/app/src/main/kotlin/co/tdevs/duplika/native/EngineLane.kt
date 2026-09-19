package co.tdevs.duplika.native

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.RejectedExecutionException

/**
 * Runs the bridge's native work one call at a time, and steps around a call that has
 * stopped answering.
 *
 * Every call from Dart that can reach the engine is serialised, because the backend's
 * install, launch and teardown paths are not safe to overlap. A plain single-thread
 * executor does that, and it was what the bridge used — but it also means one call that
 * never returns strands every call queued behind it, for as long as it lasts.
 *
 * Which is not hypothetical. `BlackBoxCore.deleteUser` is a synchronous binder call into
 * the engine's server process, and measured on API 35 it can stop answering outright
 * while that process is otherwise healthy and still serving other callers:
 *
 *     10:04:26.608  Ended com.reddit.frontpage process 21018      <- teardown got this far
 *     10:04:37.975  CrashMonitor(:black) health check              <- server alive
 *     10:05:01.652  SystemCallProvider(:black) service provided    <- server answering others
 *     10:05:29.192  ActivityManager: Kill app due to repeated failure to freeze binder
 *     10:05:29.256  BUserManager: service died during deleteUser, clearing cache and retrying
 *     10:05:29.851  Removed the virtual environment for virtual user 0
 *
 * — sixty-three seconds, ended not by the call completing but by the platform killing the
 * server process out from under it. Behind that call sat the app picker's own
 * `listInstalledApps`, which needs nothing from the engine at all: it reads the host's
 * package manager. So deleting a clone left "Add app" spinning, and leaving the screen and
 * coming back only queued another one.
 *
 * So the queue is kept, and the *thread* is made disposable. A worker that has been inside
 * one call for [stallMillis] is retired: it is left to finish whenever the engine lets it
 * go, and a fresh worker picks the queue up immediately. Work that was waiting behind the
 * stalled call runs at that point rather than at the mercy of the backend.
 *
 * Retiring does not cancel anything — a binder transaction in flight cannot be cancelled,
 * and pretending otherwise would be worse than waiting. It only stops one wedged call from
 * being the whole app's problem. The retired call still completes and still answers Dart,
 * and the cost is that it may overlap the calls that follow it; that is the same overlap
 * the backend already handles from its own guests, and it is a far smaller price than an
 * app that has to be force-stopped to be used again.
 */
internal class EngineLane(
    private val stallMillis: Long,
    private val threadName: String,
) {

    /** Shared by every worker, so retiring one hands its backlog to the next. */
    private val queue = LinkedBlockingQueue<Runnable>()

    /**
     * On the main looper rather than a thread of its own: it does two volatile reads and
     * only ever ticks while a call is actually in flight, so it costs nothing at rest.
     */
    private val watchdog = Handler(Looper.getMainLooper())
    private val tick = Runnable { sweep() }

    private var worker: Worker? = null
    private var lanes = 0
    private var ticking = false
    private var stopped = false

    /** Queues [task]. Throws once [shutdown] has run, which the caller answers to Dart. */
    @Synchronized
    fun execute(task: Runnable) {
        if (stopped) throw RejectedExecutionException("The native bridge is shutting down")
        if (worker == null) {
            worker = Worker(++lanes).also { it.start() }
        }
        queue.put(task)
    }

    /**
     * Retires the current worker and refuses further work. A worker stuck in a call is
     * left to unwind on its own; a worker waiting for work is handed a no-op so it wakes,
     * sees that it was retired and exits.
     */
    @Synchronized
    fun shutdown() {
        stopped = true
        worker?.retire()
        worker = null
        queue.clear()
        queue.put(Runnable {})
        watchdog.removeCallbacks(tick)
        ticking = false
    }

    /**
     * Called by a worker as it picks up a call. Arms the watchdog if it is not already
     * armed, so exactly one tick is ever pending.
     */
    @Synchronized
    private fun armWatchdog() {
        if (ticking || stopped) return
        ticking = true
        watchdog.postDelayed(tick, TICK_MILLIS)
    }

    @Synchronized
    private fun sweep() {
        ticking = false
        if (stopped) return

        val running = worker
        val stalledFor = running?.busyFor() ?: 0L
        if (running != null && stalledFor >= stallMillis) {
            Slog.w(
                Slog.ENGINE,
                "A native call has not answered in ${stalledFor / 1_000}s; leaving it to " +
                    "finish and moving ${queue.size} queued call(s) to a fresh thread",
            )
            running.retire()
            worker = Worker(++lanes).also { it.start() }
        }

        // Keep ticking only while there is something that could stall.
        if ((worker?.busyFor() ?: 0L) > 0L || queue.isNotEmpty()) {
            ticking = true
            watchdog.postDelayed(tick, TICK_MILLIS)
        }
    }

    private inner class Worker(lane: Int) : Thread("$threadName-$lane") {

        /** Zero while idle; otherwise when the current call started. */
        @Volatile
        private var startedAt = 0L

        @Volatile
        private var retired = false

        /** How long the current call has been running, or 0 when there is none. */
        fun busyFor(): Long {
            val began = startedAt
            return if (began == 0L) 0L else SystemClock.elapsedRealtime() - began
        }

        fun retire() {
            retired = true
        }

        override fun run() {
            while (!retired) {
                val task = try {
                    queue.take()
                } catch (_: InterruptedException) {
                    return
                }
                // Read again: a worker retired while it waited must not run the call it
                // just took, because the replacement is the one that owns the queue now.
                if (retired) {
                    queue.put(task)
                    return
                }
                startedAt = SystemClock.elapsedRealtime()
                armWatchdog()
                try {
                    task.run()
                } catch (error: Throwable) {
                    Slog.e(Slog.ENGINE, "Native call failed outside its own handler", error)
                } finally {
                    startedAt = 0L
                }
            }
        }
    }

    private companion object {
        /**
         * How often the watchdog looks, while a call is in flight. Coarse on purpose: it
         * decides when the app recovers, not whether it does.
         */
        const val TICK_MILLIS = 2_000L
    }
}
