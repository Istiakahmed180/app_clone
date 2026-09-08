package co.tdevs.duplika.diagnostics

import android.app.Application
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import android.util.Log
import co.tdevs.duplika.BuildConfig
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter
import java.util.ArrayDeque
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicLong

/**
 * The single sink for native diagnostics.
 *
 * Recording is cheap and never blocks the caller: build the event, push it into a
 * bounded ring, hand it to the live listener, and queue the disk write on a background
 * executor. The paths worth instrumenting — container install, guest launch, activity
 * start — are precisely the ones that must not get slower.
 *
 * Lives in **every** host process. `DuplikaApplication` is instantiated in Bcore's stub
 * processes too, so this object exists once per process, each with its own ring buffer
 * and its own log file. Only the main process has a Flutter engine, so only there does
 * [listener] get set; the other processes' events reach the console through the files
 * (see [DiagnosticStore]).
 */
object DiagnosticLogger {

    /** Recent events kept in memory, per process. */
    private const val RING_CAPACITY = 500

    /** Written together, so a burst of events costs one file write. */
    private const val FLUSH_THRESHOLD = 20

    private const val FLUSH_DELAY_MS = 1_500L

    private val sequence = AtomicLong(0)
    private val ring = ArrayDeque<DiagnosticEvent>(RING_CAPACITY)
    private val unwritten = ArrayList<DiagnosticEvent>(FLUSH_THRESHOLD)

    // Scheduled rather than plain: the delayed flush must not occupy the writer thread
    // while it waits, or an immediate batch queued behind it would be stuck for the
    // whole delay.
    private val writer = Executors.newSingleThreadScheduledExecutor { runnable ->
        Thread(runnable, "duplika-diagnostics").apply { isDaemon = true }
    }

    private val operationScope = ThreadLocal<OperationScope?>()

    @Volatile
    private var store: DiagnosticStore? = null

    @Volatile
    private var processName: String = "unknown"

    @Volatile
    private var appVersion: String? = null

    @Volatile
    private var appVersionCode: String? = null

    @Volatile
    private var deviceInfo: String = "${Build.MANUFACTURER} ${Build.MODEL}"

    @Volatile
    private var flushScheduled = false

    @Volatile
    private var idPrefix: String = "n0"

    /**
     * Where live events go when a Flutter engine is listening.
     *
     * Null in every process that has no Dart side, and null in the main process until
     * the console's channel attaches — which is why the ring buffer exists: the events
     * from before anyone was listening are replayed on attach.
     */
    @Volatile
    var listener: ((DiagnosticEvent) -> Unit)? = null

    /** True once [initialize] has resolved a log directory for this process. */
    val isInitialized: Boolean get() = store != null

    /**
     * Prepares logging for this process.
     *
     * Must be called from `Application.attachBaseContext`, **before** the virtualization
     * engine attaches. The engine rewrites this process's data directory for guest apps,
     * so resolving the log directory first is what keeps every process — host and stub
     * alike — writing into the host's real `filesDir` where the console can read them
     * back.
     *
     * Safe to call more than once; later calls are ignored.
     */
    fun initialize(context: Context) {
        if (store != null) return

        processName = resolveProcessName(context)
        idPrefix = "n${processName.substringAfterLast(':', "main").take(6)}" +
            "-${java.lang.Long.toString(System.currentTimeMillis(), 36)}"

        val directory = File(context.filesDir, DIRECTORY_NAME)
        store = DiagnosticStore(directory, sanitizeForFileName(processName))

        readVersion(context)
    }

    /** Fills in the app version. Kept separate so a failure here costs no logging. */
    private fun readVersion(context: Context) {
        try {
            val info = context.packageManager.getPackageInfo(context.packageName, 0)
            appVersion = info.versionName
            appVersionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                info.longVersionCode.toString()
            } else {
                @Suppress("DEPRECATION")
                info.versionCode.toString()
            }
        } catch (_: PackageManager.NameNotFoundException) {
            // A package manager that cannot find its own package happens inside a guest
            // process whose package visibility has been rewritten. Version stays null.
        } catch (_: Throwable) {
            // Version is a nicety; never let reading it break logging.
        }
    }

    fun currentProcessName(): String = processName

    fun currentAppVersion(): String? = appVersion

    fun currentAppVersionCode(): String? = appVersionCode

    fun buildType(): String = if (BuildConfig.DEBUG) "debug" else "release"

    fun retainedEventCount(): Int = synchronized(ring) { ring.size }

    fun occupiedBytes(): Long = store?.occupiedBytes() ?: 0L

    fun knownProcesses(): List<String> = store?.knownProcesses() ?: emptyList()

    /** Recent events from this process, oldest first. */
    fun recentEvents(): List<DiagnosticEvent> = synchronized(ring) { ring.toList() }

    /** The durable history across every process, oldest first. */
    fun history(limit: Int): List<DiagnosticEvent> {
        flushNow()
        return store?.readAll(limit) ?: recentEvents()
    }

    fun clear() {
        synchronized(ring) { ring.clear() }
        synchronized(unwritten) { unwritten.clear() }
        store?.clear()
    }

    // -------------------------------------------------------------------------
    // Correlation
    // -------------------------------------------------------------------------

    /** The operation in scope on this thread, if the Dart caller sent one. */
    fun currentOperation(): OperationScope? = operationScope.get()

    /**
     * Runs [block] with [id] as the ambient operation for this thread.
     *
     * Thread-local rather than a parameter on every call: the correlation id has to
     * reach code several layers down — the installer, the adapter, the engine's own
     * error paths — none of which should have to grow a diagnostics parameter.
     *
     * Restores the previous scope, so nesting works and an inner operation cannot
     * silently clear an outer one.
     */
    fun <T> withOperation(id: String?, name: String? = null, block: () -> T): T {
        if (id.isNullOrEmpty()) return block()
        val previous = operationScope.get()
        operationScope.set(OperationScope(id, name))
        return try {
            block()
        } finally {
            operationScope.set(previous)
        }
    }

    /** A correlation id captured on one thread and re-applied on another. */
    data class OperationScope(val id: String, val name: String?)

    // -------------------------------------------------------------------------
    // Recording
    // -------------------------------------------------------------------------

    fun debug(
        source: DiagSource,
        category: DiagCategory,
        message: String,
        metadata: Map<String, String> = emptyMap(),
    ) = log(DiagLevel.DEBUG, source, category, message, metadata = metadata)

    fun info(
        source: DiagSource,
        category: DiagCategory,
        message: String,
        packageName: String? = null,
        profileId: String? = null,
        virtualUserId: Int? = null,
        metadata: Map<String, String> = emptyMap(),
    ) = log(
        DiagLevel.INFO, source, category, message,
        packageName = packageName, profileId = profileId,
        virtualUserId = virtualUserId, metadata = metadata,
    )

    fun success(
        source: DiagSource,
        category: DiagCategory,
        message: String,
        packageName: String? = null,
        profileId: String? = null,
        virtualUserId: Int? = null,
        metadata: Map<String, String> = emptyMap(),
    ) = log(
        DiagLevel.SUCCESS, source, category, message,
        packageName = packageName, profileId = profileId,
        virtualUserId = virtualUserId, metadata = metadata,
    )

    fun warning(
        source: DiagSource,
        category: DiagCategory,
        message: String,
        error: Throwable? = null,
        packageName: String? = null,
        profileId: String? = null,
        virtualUserId: Int? = null,
        metadata: Map<String, String> = emptyMap(),
    ) = log(
        DiagLevel.WARNING, source, category, message, error,
        packageName = packageName, profileId = profileId,
        virtualUserId = virtualUserId, metadata = metadata,
    )

    fun error(
        source: DiagSource,
        category: DiagCategory,
        message: String,
        error: Throwable? = null,
        packageName: String? = null,
        profileId: String? = null,
        virtualUserId: Int? = null,
        metadata: Map<String, String> = emptyMap(),
    ) = log(
        DiagLevel.ERROR, source, category, message, error,
        packageName = packageName, profileId = profileId,
        virtualUserId = virtualUserId, metadata = metadata,
    )

    fun fatal(
        source: DiagSource,
        category: DiagCategory,
        message: String,
        error: Throwable? = null,
        metadata: Map<String, String> = emptyMap(),
    ) = log(DiagLevel.FATAL, source, category, message, error, metadata = metadata)

    /**
     * The one method that creates events.
     *
     * [mirrorToLogcat] exists for [co.tdevs.duplika.native.Slog], which has already
     * written the line to Logcat by the time it forwards here; writing it again would
     * double every message in a `logcat` capture.
     */
    fun log(
        level: DiagLevel,
        source: DiagSource,
        category: DiagCategory,
        message: String,
        error: Throwable? = null,
        details: String? = null,
        operation: String? = null,
        operationName: String? = null,
        packageName: String? = null,
        profileId: String? = null,
        virtualUserId: Int? = null,
        metadata: Map<String, String> = emptyMap(),
        mirrorToLogcat: Boolean = true,
    ): DiagnosticEvent {
        val scope = operationScope.get()
        val next = sequence.getAndIncrement()

        val event = DiagnosticEvent(
            id = "$idPrefix-${java.lang.Long.toString(next, 36)}",
            timestampMillis = System.currentTimeMillis(),
            sequence = next,
            level = level,
            source = source,
            category = category,
            message = DiagRedactor.redactText(message).orEmpty(),
            operation = operation ?: scope?.id,
            operationName = operationName ?: scope?.name,
            details = DiagRedactor.redactText(details ?: error?.message),
            stackTrace = error?.let(::stackTraceOf),
            exceptionType = error?.javaClass?.name,
            packageName = packageName,
            profileId = profileId,
            processName = processName,
            virtualUserId = virtualUserId,
            thread = Thread.currentThread().name,
            buildType = buildType(),
            appVersion = appVersion,
            deviceInfo = deviceInfo,
            metadata = DiagRedactor.redactMetadata(
                if (error != null) metadata + ("errorMessage" to (error.message ?: "")) else metadata,
            ),
        )

        publish(event)
        if (mirrorToLogcat) {
            mirror(event, error)
        }
        return event
    }

    /** Sends the in-memory ring to a listener that has just attached. */
    fun replayTo(target: (DiagnosticEvent) -> Unit) {
        recentEvents().forEach(target)
    }

    private fun publish(event: DiagnosticEvent) {
        synchronized(ring) {
            if (ring.size >= RING_CAPACITY) ring.removeFirst()
            ring.addLast(event)
        }

        listener?.let { target ->
            try {
                target(event)
            } catch (_: Throwable) {
                // A detached channel throws on send. Losing the live copy is fine; the
                // event is already in the ring and queued for disk.
            }
        }

        // DEBUG stays in memory. It is the noisiest level and the least useful after
        // the fact, and the file budget is better spent on everything else.
        if (event.level == DiagLevel.DEBUG) return

        val batch: List<DiagnosticEvent>? = synchronized(unwritten) {
            unwritten.add(event)
            if (unwritten.size >= FLUSH_THRESHOLD) {
                val copy = ArrayList(unwritten)
                unwritten.clear()
                copy
            } else {
                null
            }
        }

        if (batch != null) {
            submit { store?.append(batch) }
        } else {
            scheduleFlush()
        }
    }

    private fun scheduleFlush() {
        if (flushScheduled) return
        flushScheduled = true
        try {
            writer.schedule(
                {
                    flushScheduled = false
                    try {
                        flushNow()
                    } catch (_: Throwable) {
                        // See DiagnosticStore.append.
                    }
                },
                FLUSH_DELAY_MS,
                TimeUnit.MILLISECONDS,
            )
        } catch (_: RejectedExecutionException) {
            flushScheduled = false
        }
    }

    /** Writes anything queued. Called before any read, so a history is never stale. */
    fun flushNow() {
        val batch = synchronized(unwritten) {
            if (unwritten.isEmpty()) return
            val copy = ArrayList(unwritten)
            unwritten.clear()
            copy
        }
        store?.append(batch)
    }

    private fun submit(work: () -> Unit) {
        try {
            writer.execute {
                try {
                    work()
                } catch (_: Throwable) {
                    // Swallowed on purpose: see DiagnosticStore.append.
                }
            }
        } catch (_: RejectedExecutionException) {
            // Process is going down. The event is still in the ring for anyone who asks.
        }
    }

    /**
     * Keeps Logcat working exactly as before diagnostics existed.
     *
     * Everything Duplika used to print still prints, under the same `Duplika.*` tags,
     * so an existing `adb logcat` workflow is unaffected.
     */
    private fun mirror(event: DiagnosticEvent, error: Throwable?) {
        val tag = "Duplika.${event.source.wire}"
        val line = if (event.operation != null) {
            "[${event.operation}] ${event.message}"
        } else {
            event.message
        }
        when (event.level) {
            DiagLevel.DEBUG -> Log.d(tag, line)
            DiagLevel.INFO, DiagLevel.SUCCESS -> Log.i(tag, line)
            DiagLevel.WARNING -> Log.w(tag, line, error)
            DiagLevel.ERROR, DiagLevel.FATAL -> Log.e(tag, line, error)
        }
    }

    private fun stackTraceOf(error: Throwable): String {
        val writer = StringWriter()
        error.printStackTrace(PrintWriter(writer))
        val text = writer.toString().trimEnd()
        // A deep Kotlin/AOSP trace can run to hundreds of lines. Keeping all of them
        // would let a handful of exceptions consume the whole size-bounded log.
        val lines = text.lines()
        return if (lines.size <= MAX_STACK_LINES) {
            text
        } else {
            lines.take(MAX_STACK_LINES).joinToString("\n") +
                "\n\t... ${lines.size - MAX_STACK_LINES} more lines"
        }
    }

    /**
     * The process this code is running in.
     *
     * `Application.getProcessName()` is API 28+; below that the only reliable answer is
     * the running-app-process list, and even that can come back empty on some OEM
     * builds, so an unknown process name is reported rather than guessed.
     */
    private fun resolveProcessName(context: Context): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            return runCatching { Application.getProcessName() }.getOrNull()
                ?: context.packageName
        }
        val pid = Process.myPid()
        return runCatching {
            val manager = context.getSystemService(Context.ACTIVITY_SERVICE)
                as? android.app.ActivityManager
            manager?.runningAppProcesses
                ?.firstOrNull { it.pid == pid }
                ?.processName
        }.getOrNull() ?: context.packageName
    }

    private fun sanitizeForFileName(value: String): String =
        value.replace(Regex("[^A-Za-z0-9_.-]"), "_").take(48)

    private const val DIRECTORY_NAME = "diagnostics"
    private const val MAX_STACK_LINES = 60
}
