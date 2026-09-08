package co.tdevs.duplika.diagnostics

import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Severity, shared with the Dart model.
 *
 * The wire name is written out explicitly rather than taken from [name], so renaming a
 * constant here cannot silently invalidate every event already on disk.
 */
enum class DiagLevel(val wire: String, val severity: Int) {
    DEBUG("DEBUG", 0),
    INFO("INFO", 1),
    SUCCESS("SUCCESS", 2),
    WARNING("WARNING", 3),
    ERROR("ERROR", 4),
    FATAL("FATAL", 5),
    ;

    companion object {
        fun parse(value: String?): DiagLevel =
            entries.firstOrNull { it.wire == value } ?: INFO
    }
}

/** Which subsystem produced the event. Mirrors `DiagnosticSource` on the Dart side. */
enum class DiagSource(val wire: String) {
    FLUTTER("FLUTTER"),
    DART("DART"),
    ANDROID("ANDROID"),
    KOTLIN("KOTLIN"),
    METHOD_CHANNEL("METHOD_CHANNEL"),
    VIRTUAL_ENGINE("VIRTUAL_ENGINE"),
    BCORE("BCORE"),
    APK_IMPORTER("APK_IMPORTER"),
    PACKAGE_INSTALLER("PACKAGE_INSTALLER"),
    GUEST_PROCESS("GUEST_PROCESS"),
    ACTIVITY("ACTIVITY"),
    PERMISSION("PERMISSION"),
    STORAGE("STORAGE"),
    WEBVIEW("WEBVIEW"),
    NOTIFICATION("NOTIFICATION"),
    JOBSCHEDULER("JOBSCHEDULER"),
    NETWORK("NETWORK"),
    NATIVE("NATIVE"),
    SYSTEM("SYSTEM"),
    ;

    companion object {
        fun parse(value: String?): DiagSource = entries.firstOrNull { it.wire == value } ?: SYSTEM
    }
}

/** What was going on. Mirrors `DiagnosticCategory` on the Dart side. */
enum class DiagCategory(val wire: String) {
    APP_LIFECYCLE("APP_LIFECYCLE"),
    IMPORT("IMPORT"),
    INSTALL("INSTALL"),
    PROFILE("PROFILE"),
    LAUNCH("LAUNCH"),
    PROCESS("PROCESS"),
    ACTIVITY("ACTIVITY"),
    STORAGE("STORAGE"),
    PERMISSION("PERMISSION"),
    WEBVIEW("WEBVIEW"),
    NOTIFICATION("NOTIFICATION"),
    JOB("JOB"),
    NETWORK("NETWORK"),
    NATIVE_LIBRARY("NATIVE_LIBRARY"),
    CRASH("CRASH"),
    UNKNOWN("UNKNOWN"),
    ;

    companion object {
        fun parse(value: String?): DiagCategory =
            entries.firstOrNull { it.wire == value } ?: UNKNOWN
    }
}

/**
 * One recorded native fact, in the same shape the Flutter console consumes.
 *
 * Every optional field really is optional. A storage probe has no `profileId`; forcing
 * one would put a made-up value in a report someone is trying to read the truth out of.
 */
data class DiagnosticEvent(
    val id: String,
    val timestampMillis: Long,
    val sequence: Long,
    val level: DiagLevel,
    val source: DiagSource,
    val category: DiagCategory,
    val message: String,
    val operation: String? = null,
    val operationName: String? = null,
    val details: String? = null,
    val stackTrace: String? = null,
    val exceptionType: String? = null,
    val packageName: String? = null,
    val profileId: String? = null,
    val processName: String? = null,
    val virtualUserId: Int? = null,
    val thread: String? = null,
    val buildType: String? = null,
    val appVersion: String? = null,
    val deviceInfo: String? = null,
    val metadata: Map<String, String> = emptyMap(),
) {

    /** For the method/event channel. Flutter's standard codec handles these types. */
    fun toMap(): Map<String, Any?> = buildMap {
        put("id", id)
        put("timestamp", isoTimestamp(timestampMillis))
        put("sequence", sequence.toInt())
        put("level", level.wire)
        put("source", source.wire)
        put("category", category.wire)
        put("message", message)
        operation?.let { put("operation", it) }
        operationName?.let { put("operationName", it) }
        details?.let { put("details", it) }
        stackTrace?.let { put("stackTrace", it) }
        exceptionType?.let { put("exceptionType", it) }
        packageName?.let { put("packageName", it) }
        profileId?.let { put("profileId", it) }
        processName?.let { put("processName", it) }
        virtualUserId?.let { put("virtualUserId", it) }
        thread?.let { put("thread", it) }
        buildType?.let { put("buildType", it) }
        appVersion?.let { put("appVersion", it) }
        deviceInfo?.let { put("deviceInfo", it) }
        if (metadata.isNotEmpty()) put("metadata", metadata)
    }

    /**
     * One JSON object per line, so a torn write costs one event instead of the file.
     *
     * Built key by key rather than from `JSONObject(Map)`: that constructor stores a
     * nested map by reference and then serialises it with `toString()`, which would
     * write the metadata as one quoted Java map literal instead of a JSON object.
     */
    fun toJsonLine(): String {
        val json = JSONObject()
        toMap().forEach { (key, value) ->
            @Suppress("UNCHECKED_CAST")
            json.put(
                key,
                if (value is Map<*, *>) JSONObject(value as Map<String, Any?>) else value,
            )
        }
        return json.toString()
    }

    fun toLogLine(): String = buildString {
        append(isoTimestamp(timestampMillis))
        append(" [").append(level.wire).append("] ")
        append(source.wire).append('/').append(category.wire)
        operation?.let { append(" op=").append(it) }
        packageName?.let { append(" pkg=").append(it) }
        append(" — ").append(message)
    }

    companion object {
        private val ISO = object : ThreadLocal<SimpleDateFormat>() {
            override fun initialValue(): SimpleDateFormat =
                SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
                    timeZone = TimeZone.getTimeZone("UTC")
                }
        }

        fun isoTimestamp(millis: Long): String = ISO.get()!!.format(Date(millis))

        /** Reads an event back off disk. Returns null for a line that cannot be trusted. */
        fun fromJsonLine(line: String): DiagnosticEvent? = try {
            val json = JSONObject(line)
            val metadata = mutableMapOf<String, String>()
            json.optJSONObject("metadata")?.let { raw ->
                raw.keys().forEach { key -> metadata[key] = raw.optString(key) }
            }
            DiagnosticEvent(
                id = json.optString("id"),
                timestampMillis = parseIso(json.optString("timestamp")),
                sequence = json.optLong("sequence"),
                level = DiagLevel.parse(json.optString("level")),
                source = DiagSource.parse(json.optString("source")),
                category = DiagCategory.parse(json.optString("category")),
                message = json.optString("message"),
                operation = json.optStringOrNull("operation"),
                operationName = json.optStringOrNull("operationName"),
                details = json.optStringOrNull("details"),
                stackTrace = json.optStringOrNull("stackTrace"),
                exceptionType = json.optStringOrNull("exceptionType"),
                packageName = json.optStringOrNull("packageName"),
                profileId = json.optStringOrNull("profileId"),
                processName = json.optStringOrNull("processName"),
                virtualUserId = if (json.has("virtualUserId")) json.optInt("virtualUserId") else null,
                thread = json.optStringOrNull("thread"),
                buildType = json.optStringOrNull("buildType"),
                appVersion = json.optStringOrNull("appVersion"),
                deviceInfo = json.optStringOrNull("deviceInfo"),
                metadata = metadata,
            )
        } catch (_: Throwable) {
            null
        }

        private fun JSONObject.optStringOrNull(key: String): String? =
            if (has(key) && !isNull(key)) optString(key) else null

        private fun parseIso(value: String?): Long {
            if (value.isNullOrEmpty()) return 0L
            return try {
                ISO.get()!!.parse(value)?.time ?: 0L
            } catch (_: Throwable) {
                0L
            }
        }
    }
}
