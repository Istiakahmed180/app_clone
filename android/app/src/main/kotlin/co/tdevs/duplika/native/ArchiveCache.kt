package co.tdevs.duplika.native

import java.io.File
import java.util.concurrent.ConcurrentHashMap

/**
 * Remembers what reading an app's APKs found, so a listing does not read them all again.
 *
 * Answering "which `lib/<abi>/` directories does this app ship" means opening the base APK
 * and every split and walking the zip central directory, and the picker asks it of every
 * launchable app on the device. It is the bulk of what a listing costs, and it was paid
 * again on every cold start. Measured on an API 35 emulator with 30 launchable apps, a
 * listing went from ~480ms to ~130-220ms once the answers survived the process; the gap
 * grows with the number of launchable apps, since this is the only per-app cost removed.
 *
 * [PackageManager.lastUpdateTime][android.content.pm.PackageInfo.lastUpdateTime] is the
 * entire cache key. It moves on an install, an update, a downgrade and a reinstall, which
 * is every way an app's archives can change; nothing else can change them without the
 * package manager writing a new record. An entry whose stamp no longer matches is not
 * used, and the archives are read again.
 *
 * Kept on disk rather than only in memory because the cost this exists to avoid is the
 * *cold* one: an in-memory map makes the second listing of a session cheap and does
 * nothing for the first, which is the one the user waits for on the screen they just
 * opened.
 *
 * Everything here treats the file as a hint, never as a source of truth. A missing,
 * truncated, corrupt or future-version file loses the cache and nothing else — the
 * archives are simply read again, which is what the code did before this class existed.
 */
class ArchiveCache(private val file: File) {

    private class Entry(val lastUpdateTime: Long, val archives: ApkAbis.Archives)

    private val entries = ConcurrentHashMap<String, Entry>()

    /** Whether anything has changed since the last [flush], so a clean pass writes nothing. */
    @Volatile
    private var dirty = false

    @Volatile
    private var loaded = false

    /**
     * The remembered read for [packageName], or null when there is none for this stamp.
     *
     * Loads the file on the first call rather than in the constructor: a process that
     * never opens the picker should not pay for the read at all.
     */
    @Synchronized
    fun get(packageName: String, lastUpdateTime: Long): ApkAbis.Archives? {
        ensureLoaded()
        val entry = entries[packageName] ?: return null
        return entry.archives.takeIf { entry.lastUpdateTime == lastUpdateTime }
    }

    @Synchronized
    fun put(packageName: String, lastUpdateTime: Long, archives: ApkAbis.Archives) {
        // Loads here too, and not only in [get]. A listing happens to read before it
        // writes, so this is never the first call today — but if it ever were, a [flush]
        // would write this one entry over a file holding every other app on the device
        // and call it the cache. Whether a cache is correct should not rest on the order
        // its caller happens to use it in.
        ensureLoaded()
        entries[packageName] = Entry(lastUpdateTime, archives)
        dirty = true
    }

    /**
     * Forgets every package not in [packageNames].
     *
     * Called with everything the listing saw, so an app the user has uninstalled does not
     * keep an entry — and the file does not grow for the life of the install.
     */
    @Synchronized
    fun retain(packageNames: Set<String>) {
        ensureLoaded()
        if (entries.keys.retainAll(packageNames)) {
            dirty = true
        }
    }

    /** Writes the cache out, if there is anything new to write. */
    @Synchronized
    fun flush() {
        if (!dirty) {
            return
        }
        dirty = false
        val text = buildString {
            append(HEADER).append('\n')
            for ((packageName, entry) in entries) {
                // Package names cannot contain a tab or a newline, and neither can an ABI
                // directory name, so no escaping is needed for either field.
                append(packageName).append('\t')
                append(entry.lastUpdateTime).append('\t')
                append(if (entry.archives.baseReadable) '1' else '0').append('\t')
                append(entry.archives.abis.joinToString(",")).append('\n')
            }
        }
        try {
            // Written beside the real file and moved into place, so a process killed
            // mid-write leaves the previous cache rather than a half-written one. A
            // truncated file would be survivable anyway — see [load] — but losing the
            // whole cache to a bad shutdown is a slow cold start nobody asked for.
            val temporary = File(file.parentFile, file.name + ".tmp")
            temporary.writeText(text)
            if (!temporary.renameTo(file)) {
                file.writeText(text)
                temporary.delete()
            }
        } catch (error: Throwable) {
            Slog.w(Slog.INSTALL, "Could not write the archive cache: ${error.message}")
        }
    }

    private fun ensureLoaded() {
        if (loaded) {
            return
        }
        // Set before the read, not after: a load that throws must not be retried on every
        // single lookup of the pass that follows.
        loaded = true
        load()
    }

    private fun load() {
        val lines = try {
            if (!file.exists()) return
            file.readLines()
        } catch (error: Throwable) {
            Slog.w(Slog.INSTALL, "Could not read the archive cache: ${error.message}")
            return
        }

        if (lines.firstOrNull() != HEADER) {
            // Written by a different version of this code. Dropped rather than guessed at.
            return
        }

        for (line in lines.drop(1)) {
            val fields = line.split('\t')
            if (fields.size != FIELDS) {
                continue // A truncated final line, or a file someone has edited.
            }
            val packageName = fields[0]
            val stamp = fields[1].toLongOrNull() ?: continue
            val readable = when (fields[2]) {
                "1" -> true
                "0" -> false
                else -> continue
            }
            val abis = fields[3]
                .split(',')
                .filterTo(LinkedHashSet(), String::isNotEmpty)
            if (packageName.isNotEmpty()) {
                entries[packageName] = Entry(stamp, ApkAbis.archivesOf(abis, readable))
            }
        }
    }

    private companion object {
        /**
         * Carries the format version. A change to the fields below changes this line, and
         * every older file is then dropped on sight rather than misread.
         */
        const val HEADER = "duplika-archive-cache\t1"
        const val FIELDS = 4
    }
}
