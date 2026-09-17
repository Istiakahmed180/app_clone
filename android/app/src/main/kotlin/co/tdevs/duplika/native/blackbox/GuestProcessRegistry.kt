package co.tdevs.duplika.native.blackbox

import android.os.Process
import android.system.Os
import co.tdevs.duplika.native.Slog
import java.io.File
import top.niunaijun.blackbox.core.env.BEnvironment

/**
 * Which processes belong to which clone, written by the clones themselves.
 *
 * The engine already answers this — [BlackBoxEngineAdapter] asks it — but only from
 * memory, and that memory lives in Bcore's server process. Measured on API 35, that
 * process is restarted often: stopping a package can take it down, and a fresh server has
 * no record of guests an earlier one started. The guests keep running. So the answer that
 * decides whether a deleted clone's app is actually ended was, often, "nothing is running"
 * while that app was still on screen.
 *
 * A guest knows its own pid and its own container with no help from anyone, and says so
 * here as it starts. Written under Bcore's virtual root rather than inside the container:
 * the guest's own data paths are redirected by the engine's IO hooks, this one is not, and
 * a record that outlives the container it describes is what lets the host tidy up after it.
 *
 * One file per process, named by pid, holding one number, in a directory named by
 * container and package. No locking: a guest writes its own file and nobody else's, the
 * host lists and deletes them, and two processes doing either at once cannot corrupt
 * anything.
 *
 * Every entry is a claim, never a fact. A pid is a small recycled integer, and a record
 * whose process died without tidying up names a pid the system is free to hand to
 * something else — so each record carries the start time of the process that wrote it,
 * and [livePids] hands over a pid only when `/proc` still agrees on all three of: this
 * app's uid, that package's process name, and that start time.
 *
 * The start time is what the other two cannot do. Two clones of one app run processes
 * with the same name under the same uid, so a pid recycled from one container onto
 * another container's guest of the *same* app passes both of the other checks — and
 * stopping one clone would then end another clone's app. The start time is the one thing
 * that differs, and comparing it is the ordinary answer to pid reuse.
 */
internal object GuestProcessRegistry {

    /**
     * Records this process as belonging to [virtualUserId].
     *
     * Called from the guest, early in its own startup. Failures are logged and dropped:
     * this is a better answer than the engine's, not a required one, and a clone that
     * could not write its pid must still start.
     */
    fun record(packageName: String, virtualUserId: Int, pid: Int = Process.myPid()) {
        try {
            val dir = dirFor(packageName, virtualUserId)
            if (!dir.exists() && !dir.mkdirs()) {
                return
            }
            sweep(dir)
            // The start time goes in the file rather than the name so a record written by
            // a build that did not carry one reads as unverifiable rather than as a
            // different pid.
            val startTime = startTimeOf(pid)
            if (startTime == null) {
                // Said out loud because of what it costs silently: a record with no start
                // time is one [livePids] will drop rather than trust, so a device where
                // this fails has no registry at all and looks exactly like a device where
                // every clone happened to be closed already.
                Slog.w(Slog.LAUNCH, "No start time for guest pid $pid; its record cannot be trusted")
            }
            File(dir, pid.toString()).writeText(startTime.orEmpty())
        } catch (error: Throwable) {
            Slog.w(Slog.LAUNCH, "Could not record guest pid $pid: ${error.message}")
        }
    }

    /**
     * Drops records whose process no longer exists at all.
     *
     * A guest that is closed rather than stopped leaves its record behind — nothing runs
     * in a dying process to tidy up — and the only reader that prunes properly is
     * [livePids], which runs when a clone is stopped or deleted and not before. A clone
     * opened a few hundred times and never stopped would otherwise leave a few hundred
     * files here.
     *
     * Existence only, on the guest's own startup path: this is the cheapest check there
     * is, and it is not the one that decides whether anything gets killed. A pid the
     * system has since handed to another process survives this and is caught by
     * [isGuest] at the point it would actually matter.
     */
    private fun sweep(dir: File) {
        dir.listFiles()?.forEach { entry ->
            val pid = entry.name.toIntOrNull()
            if (pid == null || !File("/proc/$pid").exists()) {
                entry.delete()
            }
        }
    }

    /**
     * The recorded pids that are still this app's own processes running [packageName].
     *
     * Records that no longer check out are deleted as they are read, so a container opened
     * and closed many times does not accumulate them.
     */
    fun livePids(packageName: String, virtualUserId: Int): List<Int> {
        val entries = dirFor(packageName, virtualUserId).listFiles().orEmpty()
        val live = mutableListOf<Int>()
        for (entry in entries) {
            val pid = entry.name.toIntOrNull()
            val recordedStart = runCatching { entry.readText().trim() }.getOrNull()
            if (pid == null ||
                pid <= 0 ||
                pid == Process.myPid() ||
                recordedStart.isNullOrEmpty() ||
                !isGuest(pid, packageName, recordedStart)
            ) {
                entry.delete()
                continue
            }
            live += pid
        }
        return live
    }

    /**
     * Drops the records for [pids], for when those processes have been ended.
     *
     * Named pids rather than the whole directory, for two reasons that both come down to
     * not throwing away a record for a process that is still running. A clone can be
     * starting at the moment it is stopped — the new guest records itself, and wiping the
     * directory would lose it while it is alive, leaving a process nothing will ever look
     * for again. And a kill that somehow did not land leaves a process that should stay
     * on the list rather than disappear from it.
     */
    fun forget(packageName: String, virtualUserId: Int, pids: Iterable<Int>) {
        val dir = dirFor(packageName, virtualUserId)
        for (pid in pids) {
            File(dir, pid.toString()).delete()
        }
    }

    /**
     * Whether [pid] is, right now, a process of this app running [packageName].
     *
     * For pids that arrive from somewhere other than this registry — the engine's own
     * list, which is its server's memory of what it started and can name a process that
     * has since died. Without a recorded start time there is no way to tell a stale entry
     * from a fresh one, so this is the weaker of the two checks; it is still the
     * difference between confirming a pid against the kernel and taking the engine's word
     * for it before sending it a signal.
     */
    fun isLiveGuest(pid: Int, packageName: String): Boolean = try {
        val owned = Os.stat("/proc/$pid").st_uid == Process.myUid()
        val command = commandOf(pid)
        pid > 0 &&
            pid != Process.myPid() &&
            owned &&
            (command == packageName || command.startsWith("$packageName:"))
    } catch (error: Throwable) {
        false
    }

    /**
     * Whether [pid] is still the very process that recorded itself here.
     *
     * All three checks earn their place. The owner check is what makes ending it
     * legitimate — a guest runs inside this app's own uid, which is why the host may end
     * it. The name check keeps the kill inside the package being stopped. The start time
     * is what makes it *this* process rather than whatever the system later gave the same
     * number to, which the first two cannot tell apart for two clones of one app.
     */
    private fun isGuest(pid: Int, packageName: String, recordedStart: String): Boolean = try {
        val owned = Os.stat("/proc/$pid").st_uid == Process.myUid()
        val command = commandOf(pid)
        owned &&
            (command == packageName || command.startsWith("$packageName:")) &&
            startTimeOf(pid) == recordedStart
    } catch (error: Throwable) {
        // Gone, or not ours to look at. Either way it is not a process to end.
        false
    }

    /**
     * When the kernel says [pid] started, in clock ticks since boot.
     *
     * Read from `/proc/<pid>/stat`, whose second field is the executable name in brackets
     * and may itself contain spaces and brackets — so the fields are counted from after
     * the last bracket rather than from the start of the line, which is the only way to
     * read this file that a process called `my (odd) name` does not break.
     */
    private fun startTimeOf(pid: Int): String? = try {
        val fields = File("/proc/$pid/stat").readText()
            .substringAfterLast(')')
            .trim()
            .split(' ')
        // `starttime` is the twenty-second field counting from one, and the two the split
        // above consumed were the first of them.
        fields.getOrNull(STARTTIME_FIELD - 3)
    } catch (error: Throwable) {
        null
    }

    /** The process name as the kernel has it: NUL-terminated, and NUL-padded on some ROMs. */
    private fun commandOf(pid: Int): String =
        File("/proc/$pid/cmdline").readText().substringBefore(NUL)

    private fun dirFor(packageName: String, virtualUserId: Int): File =
        File(BEnvironment.getVirtualRoot(), "$ROOT/$virtualUserId/$packageName")

    private const val ROOT = "duplika-guest-pids"
    private const val STARTTIME_FIELD = 22
    private const val NUL = ' '
}
