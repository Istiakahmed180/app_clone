package co.tdevs.duplika.diagnostics

/**
 * The native half of the redaction policy, deliberately identical in intent to
 * `lib/core/diagnostics/diagnostic_redactor.dart`.
 *
 * Redaction happens where the event is created, not where it is displayed: once a
 * secret is in the persistent log it has already leaked, and the log is what gets
 * exported and shared.
 *
 * This is a safety net for text that arrives from somewhere else — an engine error
 * message, an exception's `getMessage()`. Callers still must not hand credentials to
 * the logger.
 */
object DiagRedactor {

    const val PLACEHOLDER = "[REDACTED]"

    private val SENSITIVE_KEY_PARTS = listOf(
        "password", "passwd", "secret", "token", "auth", "cookie", "credential",
        "bearer", "apikey", "api_key", "privatekey", "private_key", "session",
        "signature", "card", "cvv", "iban", "ssn",
    )

    private val BEARER = Regex(
        """\b(bearer|authorization\s*[:=])\s*[A-Za-z0-9._\-+/=]{8,}""",
        RegexOption.IGNORE_CASE,
    )

    private val JWT = Regex("""\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{4,}""")

    private val PEM = Regex(
        """-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----""",
    )

    private val INLINE_ASSIGNMENT = Regex(
        "(" + SENSITIVE_KEY_PARTS.joinToString("|") + """)(["']?\s*[:=]\s*["']?)([^\s,;&"'}\]]{4,})""",
        RegexOption.IGNORE_CASE,
    )

    private val DIGIT_RUN = Regex("""\b(?:\d[ -]?){13,19}\b""")

    /** Longest prefix first, so `/storage/emulated/0` is labelled before `/storage`. */
    private val PATH_ROOTS = listOf(
        "/storage/emulated/0" to "<shared>",
        "/sdcard" to "<shared>",
        "/data/user/0" to "<app-data>",
        "/data/data" to "<app-data>",
        "/data/media/0" to "<shared>",
        "/storage" to "<volume>",
    )

    fun isSensitiveKey(key: String): Boolean {
        val needle = key.lowercase()
        return SENSITIVE_KEY_PARTS.any(needle::contains)
    }

    fun redactText(value: String?): String? {
        if (value.isNullOrEmpty() || !mightContainSecret(value)) return value
        var result = PEM.replace(value, PLACEHOLDER)
        result = JWT.replace(result, PLACEHOLDER)
        result = BEARER.replace(result, PLACEHOLDER)
        result = INLINE_ASSIGNMENT.replace(result) { match ->
            match.groupValues[1] + match.groupValues[2] + PLACEHOLDER
        }
        // Only a Luhn-valid run is treated as a card number: version codes, byte counts
        // and epoch millis are all long digit runs, and redacting those would make an
        // install log unreadable.
        return DIGIT_RUN.replace(result) { match ->
            val digits = match.value.filter(Char::isDigit)
            if (passesLuhn(digits)) PLACEHOLDER else match.value
        }
    }

    fun redactMetadata(metadata: Map<String, String>): Map<String, String> {
        if (metadata.isEmpty()) return metadata
        return metadata.mapValues { (key, value) ->
            if (isSensitiveKey(key)) PLACEHOLDER else redactText(value).orEmpty()
        }
    }

    /**
     * Shortens a path to something safe to show and still useful.
     *
     * The filename survives, because "which APK failed" is the question an import
     * diagnostic exists to answer; the directories above it collapse to a root label so
     * an exported report carries no folder structure.
     */
    fun sanitizePath(path: String?): String {
        if (path.isNullOrEmpty()) return ""
        for ((prefix, label) in PATH_ROOTS) {
            if (path.startsWith(prefix)) {
                val remainder = path.substring(prefix.length)
                val lastSlash = remainder.lastIndexOf('/')
                return if (lastSlash <= 0) "$label$remainder"
                else "$label/…/" + remainder.substring(lastSlash + 1)
            }
        }
        val lastSlash = path.lastIndexOf('/')
        return if (lastSlash <= 0) path else "…/" + path.substring(lastSlash + 1)
    }

    /**
     * Cheap pre-check so the patterns above do not run on every log line.
     *
     * Almost every native event is prose plus a package name, which cannot contain any
     * of these shapes.
     */
    private fun mightContainSecret(value: String): Boolean {
        val lower = value.lowercase()
        if (lower.contains("-----begin") || lower.contains("eyj")) return true
        if (SENSITIVE_KEY_PARTS.any(lower::contains)) return true

        var digits = 0
        for (character in value) {
            when {
                character.isDigit() -> if (++digits >= 13) return true
                character == ' ' || character == '-' -> Unit
                else -> digits = 0
            }
        }
        return false
    }

    private fun passesLuhn(digits: String): Boolean {
        if (digits.length !in 13..19) return false
        var sum = 0
        var doubleIt = false
        for (index in digits.indices.reversed()) {
            var digit = digits[index] - '0'
            if (digit !in 0..9) return false
            if (doubleIt) {
                digit *= 2
                if (digit > 9) digit -= 9
            }
            sum += digit
            doubleIt = !doubleIt
        }
        return sum % 10 == 0
    }
}
