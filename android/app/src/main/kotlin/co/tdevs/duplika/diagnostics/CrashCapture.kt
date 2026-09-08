package co.tdevs.duplika.diagnostics

/**
 * Records unhandled JVM exceptions on their way out of the process.
 *
 * What this genuinely captures:
 *  - unhandled Kotlin/Java exceptions on any thread of any Duplika process, including
 *    the Bcore stub processes where guest activities run;
 *  - the thread and the process, which for a guest crash is the interesting part.
 *
 * What it cannot capture, and does not pretend to:
 *  - **native (SIGSEGV/SIGABRT) crashes.** Those never reach a Java handler. Android
 *    writes a tombstone under `/data/tombstones`, which is readable only by the system
 *    and by `adb bugreport` — an app cannot read its own. Installing a signal handler
 *    to fake it would mean interfering with the ART runtime's own crash handling inside
 *    a process that is also hosting guest code, which is not a trade worth making for
 *    a log line.
 *  - **crashes in another application's process.** A cloned app runs inside a Duplika
 *    process, so its crashes are covered; an app running normally on the device is not,
 *    and Android's sandbox is why.
 *  - **anything that kills the process without unwinding**: a low-memory kill, a
 *    watchdog ANR kill, `Process.killProcess`.
 *
 * The handler is chained, never replaced. After recording, the previous handler runs
 * and the process dies exactly as it would have: diagnostics observe a crash, they do
 * not turn one into a survivable event.
 */
object CrashCapture {

    @Volatile
    private var installed = false

    fun install() {
        if (installed) return
        installed = true

        val previous = Thread.getDefaultUncaughtExceptionHandler()

        Thread.setDefaultUncaughtExceptionHandler { thread, error ->
            try {
                DiagnosticLogger.log(
                    level = DiagLevel.FATAL,
                    source = DiagSource.KOTLIN,
                    category = DiagCategory.CRASH,
                    message = "Unhandled ${error.javaClass.simpleName} on thread ${thread.name}",
                    error = error,
                    metadata = mapOf(
                        "kind" to "uncaughtJvm",
                        "thread" to thread.name,
                        "captured" to "true",
                    ),
                )
                // The process is about to die, so the batching that keeps logging cheap
                // has to be defeated here: an unflushed crash event is a crash nobody
                // can read about afterwards.
                DiagnosticLogger.flushNow()
            } catch (_: Throwable) {
                // Never let the crash reporter change how the crash itself surfaces.
            }

            if (previous != null) {
                previous.uncaughtException(thread, error)
            } else {
                // No prior handler means nothing else will end the process. Rethrowing
                // from here would be swallowed, so terminate the way the platform would.
                @Suppress("DEPRECATION")
                android.os.Process.killProcess(android.os.Process.myPid())
            }
        }
    }
}
