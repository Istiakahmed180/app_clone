package co.tdevs.duplika.native.gms

/**
 * The outcome of asking a provider to do something.
 *
 * Expected capability failures are values, not exceptions. "microG is not implemented" and
 * "this device has no Play services" are ordinary answers a caller should be able to branch
 * on; throwing for them would make the normal path exceptional and push every caller into a
 * try/catch that cannot distinguish the cases anyway.
 *
 * Every non-success case names both the [provider] that answered and the [capability] that
 * was asked for, so a log line or a bug report says *who* refused *what* without needing
 * the call site for context.
 *
 * ## What must never appear in [diagnostics]
 *
 * The map is for operator-facing metadata — a mode, a status, a count. It must not carry
 * OAuth/access/refresh tokens, account emails or identifiers, advertising IDs, App Set IDs,
 * or any guest application data. [redactedDiagnostics] enforces this rather than trusting
 * call sites: a key that looks like a secret has its value dropped and the drop is visible.
 */
sealed interface ProviderResult<out T> {

    val provider: String
    val capability: GmsCapability

    /** The operation completed and [value] is its result. */
    data class Success<T>(
        override val provider: String,
        override val capability: GmsCapability,
        val value: T,
        val diagnostics: Map<String, String> = emptyMap(),
    ) : ProviderResult<T>

    /**
     * The provider implements this capability but the environment cannot satisfy it right
     * now — e.g. Real GMS is the selected provider and the host has no Play services.
     * Recoverable: the same call could succeed on another device or after the user installs
     * Play services.
     */
    data class Unavailable(
        override val provider: String,
        override val capability: GmsCapability,
        val reason: String,
        val diagnostics: Map<String, String> = emptyMap(),
    ) : ProviderResult<Nothing>

    /**
     * This provider does not implement this capability at all, and never will. Distinct
     * from [NotImplemented]: nothing is pending here, so a caller should stop asking.
     */
    data class Unsupported(
        override val provider: String,
        override val capability: GmsCapability,
        val reason: String,
        val diagnostics: Map<String, String> = emptyMap(),
    ) : ProviderResult<Nothing>

    /**
     * The provider is an architectural placeholder — the capability is intended but no
     * implementation exists yet. This is what every microG call returns today, and it is
     * deliberately not [Unavailable]: "not written" and "not present on this device" are
     * different facts and collapsing them would let an unimplemented provider look like a
     * device problem.
     */
    data class NotImplemented(
        override val provider: String,
        override val capability: GmsCapability,
        val reason: String,
        val diagnostics: Map<String, String> = emptyMap(),
    ) : ProviderResult<Nothing>

    /**
     * The capability cannot be provided legitimately by a third-party container because it
     * needs an identity or integrity guarantee only the platform can give.
     *
     * Its own case, not an error, because it must never read like a defect awaiting a fix:
     * making one of these "work" would mean spoofing an identity, forging a signature or
     * defeating an integrity check. Nothing in Duplika returns this today — no capability
     * in [GmsCapability] is account- or attestation-bound — but the case exists so that a
     * future capability which *is* has somewhere honest to land instead of being reported
     * as [Error].
     */
    data class SecurityRestricted(
        override val provider: String,
        override val capability: GmsCapability,
        val reason: String,
        val diagnostics: Map<String, String> = emptyMap(),
    ) : ProviderResult<Nothing>

    /** Something genuinely went wrong: an unexpected failure, not a modelled outcome. */
    data class Error(
        override val provider: String,
        override val capability: GmsCapability,
        val code: String,
        val message: String,
        val diagnostics: Map<String, String> = emptyMap(),
    ) : ProviderResult<Nothing>

    val isSuccess: Boolean get() = this is Success

    /** A short, stable label for logs and reports. */
    val outcome: String
        get() = when (this) {
            is Success -> "SUCCESS"
            is Unavailable -> "UNAVAILABLE"
            is Unsupported -> "UNSUPPORTED"
            is NotImplemented -> "NOT_IMPLEMENTED"
            is SecurityRestricted -> "SECURITY_RESTRICTED"
            is Error -> "ERROR"
        }

    /** The human-readable reason, or empty for a success. */
    val reasonOrEmpty: String
        get() = when (this) {
            is Success -> ""
            is Unavailable -> reason
            is Unsupported -> reason
            is NotImplemented -> reason
            is SecurityRestricted -> reason
            is Error -> "$code: $message"
        }

    val rawDiagnostics: Map<String, String>
        get() = when (this) {
            is Success -> diagnostics
            is Unavailable -> diagnostics
            is Unsupported -> diagnostics
            is NotImplemented -> diagnostics
            is SecurityRestricted -> diagnostics
            is Error -> diagnostics
        }

    /**
     * [rawDiagnostics] with anything that looks like a secret or a personal identifier
     * removed.
     *
     * A guard, not a feature: the diagnostics this phase actually produces contain no such
     * values, and this exists so a future call site cannot quietly start leaking one. The
     * drop is recorded in place of the value so it cannot pass unnoticed.
     */
    val redactedDiagnostics: Map<String, String>
        get() = rawDiagnostics.mapValues { (key, value) ->
            if (FORBIDDEN_KEY_MARKERS.any { it in key.lowercase() }) {
                "[REDACTED: key matched forbidden marker]"
            } else {
                value
            }
        }

    companion object {
        /**
         * Substrings that must never appear as a diagnostics key, matched
         * case-insensitively. Names the categories the phase brief forbids.
         */
        private val FORBIDDEN_KEY_MARKERS = listOf(
            "token", "oauth", "bearer", "credential", "password", "secret",
            "account", "email", "advertisingid", "advertising_id",
            "appsetid", "appset_id",
        )
    }
}
