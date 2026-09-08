package co.tdevs.duplika.diagnostics

/**
 * The shape every manual subsystem probe returns.
 *
 * One shape for all of them so the console renders storage, WebView, permission,
 * notification and job findings with a single widget, and the exporter writes them all
 * with a single code path.
 */
class ProbeReport(val title: String) {

    class Field(val label: String, val value: String)

    class Section(val title: String, val fields: List<Field>)

    private val sections = mutableListOf<Section>()
    private var current: MutableList<Field>? = null
    private var currentTitle: String = ""

    /** Starts a new section. The previous one is closed even if it ended up empty. */
    fun section(title: String): ProbeReport {
        flush()
        currentTitle = title
        current = mutableListOf()
        return this
    }

    fun field(label: String, value: String?): ProbeReport {
        val target = current ?: mutableListOf<Field>().also {
            current = it
            currentTitle = "General"
        }
        target += Field(label, value ?: "unavailable")
        return this
    }

    fun field(label: String, value: Boolean): ProbeReport = field(label, value.toString())

    fun field(label: String, value: Long): ProbeReport = field(label, value.toString())

    /**
     * Records what a call threw instead of what it returned.
     *
     * A probe that silently omitted a row the platform refused to answer would read as
     * "not applicable" when the truth is "denied" — which is usually the finding.
     */
    fun failure(label: String, error: Throwable): ProbeReport =
        field(label, "EXCEPTION ${error.javaClass.simpleName}: ${error.message ?: "no message"}")

    /** Runs [read] and records either its value or its exception. */
    fun probe(label: String, read: () -> String?): ProbeReport = try {
        field(label, read())
    } catch (error: Throwable) {
        failure(label, error)
    }

    fun build(): List<Section> {
        flush()
        return sections.toList()
    }

    /** The same findings as text, for the export bundle. */
    fun buildText(): String = buildString {
        appendLine("=".repeat(72))
        appendLine(title.uppercase())
        appendLine("Captured: ${DiagnosticEvent.isoTimestamp(System.currentTimeMillis())}")
        appendLine("Process:  ${DiagnosticLogger.currentProcessName()}")
        appendLine("=".repeat(72))
        appendLine()
        build().forEach { section ->
            appendLine(section.title)
            appendLine("-".repeat(section.title.length))
            section.fields.forEach { field ->
                appendLine("  ${field.label.padEnd(38)}${field.value}")
            }
            appendLine()
        }
    }

    /** The channel payload the Dart `NativeProbeResult` parses. */
    fun toMap(eventCount: Int): Map<String, Any?> = mapOf(
        "title" to title,
        "sections" to build().map { section ->
            mapOf(
                "title" to section.title,
                "fields" to section.fields.map { mapOf("label" to it.label, "value" to it.value) },
            )
        },
        "text" to buildText(),
        "eventCount" to eventCount,
    )

    private fun flush() {
        val fields = current ?: return
        sections += Section(currentTitle, fields.toList())
        current = null
    }
}
