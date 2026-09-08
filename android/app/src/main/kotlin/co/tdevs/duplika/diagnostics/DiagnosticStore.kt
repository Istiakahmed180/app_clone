package co.tdevs.duplika.diagnostics

import java.io.File

/**
 * The durable native log: JSON lines, one file per real host process.
 *
 * Per process, not per app, and that is the whole point. Bcore runs guest activities in
 * separate host processes (`:p0`, `:p1`, ... and `:black`), where `DuplikaApplication`
 * is instantiated again and where no Flutter engine exists. A launch failure, a WebView
 * data-directory clash or a storage error inside one of those processes cannot be sent
 * over a method channel, because there is no channel there. Writing to a file the main
 * process reads back is the only way those events reach the console at all.
 *
 * It also means no cross-process locking is needed: each process only ever appends to
 * its own file, and the reader opens the others read-only.
 *
 * Retention is bounded twice: two segments per process of [maxSegmentBytes] each
 * (rotated, never rewritten), and a tail limit applied on read.
 */
class DiagnosticStore(
    private val directory: File,
    private val processTag: String,
    private val maxSegmentBytes: Long = 384 * 1024,
    private val maxProcessFiles: Int = 12,
) {

    private val currentFile: File by lazy { File(directory, "$FILE_PREFIX$processTag.jsonl") }
    private val previousFile: File by lazy { File(directory, "$FILE_PREFIX$processTag.1.jsonl") }

    /** Appends a batch. Never throws: a logging failure must not become the incident. */
    @Synchronized
    fun append(events: List<DiagnosticEvent>) {
        if (events.isEmpty()) return
        try {
            if (!directory.exists() && !directory.mkdirs()) return
            pruneForeignFiles()

            currentFile.appendText(events.joinToString(separator = "\n", postfix = "\n") { it.toJsonLine() })

            if (currentFile.length() >= maxSegmentBytes) {
                rotate()
            }
        } catch (_: Throwable) {
            // Nothing to do and nowhere useful to say it: reporting a log-write failure
            // through the logger would recurse.
        }
    }

    /**
     * Every process's events, oldest first, tail-limited to [limit].
     *
     * The tail is what is kept, because the newest events are the ones that describe
     * whatever the developer is looking at right now.
     */
    @Synchronized
    fun readAll(limit: Int): List<DiagnosticEvent> {
        val files = segmentFiles()
        if (files.isEmpty()) return emptyList()

        val events = ArrayList<DiagnosticEvent>()
        files.forEach { file ->
            try {
                file.forEachLine { line ->
                    if (line.isNotBlank()) {
                        DiagnosticEvent.fromJsonLine(line)?.let(events::add)
                    }
                }
            } catch (_: Throwable) {
                // An unreadable segment loses that segment, not the whole history.
            }
        }

        events.sortWith(compareBy({ it.timestampMillis }, { it.sequence }))
        return if (events.size <= limit) events else events.subList(events.size - limit, events.size)
    }

    @Synchronized
    fun clear() {
        segmentFiles().forEach { runCatching { it.delete() } }
    }

    @Synchronized
    fun occupiedBytes(): Long = segmentFiles().sumOf { it.length() }

    /** Which real processes have written events, for the system information screen. */
    @Synchronized
    fun knownProcesses(): List<String> = segmentFiles()
        .map { it.name.removePrefix(FILE_PREFIX).removeSuffix(".jsonl").removeSuffix(".1") }
        .distinct()
        .sorted()

    private fun rotate() {
        if (previousFile.exists() && !previousFile.delete()) return
        currentFile.renameTo(previousFile)
    }

    /**
     * Stops the per-process files from becoming their own unbounded growth.
     *
     * Bcore allocates stub processes as it needs them, and a device that has run many
     * clones accumulates a file per process name. Each is individually bounded, so the
     * risk is file count rather than size; the least recently written ones go first.
     */
    private fun pruneForeignFiles() {
        val files = segmentFiles()
        if (files.size <= maxProcessFiles) return
        files.sortedBy { it.lastModified() }
            .take(files.size - maxProcessFiles)
            .forEach { file -> if (file != currentFile) runCatching { file.delete() } }
    }

    private fun segmentFiles(): List<File> =
        directory.listFiles { file -> file.isFile && file.name.startsWith(FILE_PREFIX) }
            ?.sortedBy { it.name }
            ?: emptyList()

    private companion object {
        const val FILE_PREFIX = "native-"
    }
}
