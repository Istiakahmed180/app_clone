package co.tdevs.duplika.native.gms

/**
 * Where provider diagnostics go.
 *
 * An injectable sink rather than a direct [co.tdevs.duplika.native.Slog] call, for one
 * concrete reason: `Slog` imports `android.util.Log`, which is not available on the JVM, and
 * the phase brief requires unit tests that do not depend on a device. Keeping the sink
 * behind an interface is what lets the resolver be tested for free — and it also lets a test
 * assert on the selection reasoning rather than only on the returned provider.
 *
 * Implementations must not log secrets. Callers pass [ProviderResult.redactedDiagnostics],
 * never `rawDiagnostics`.
 */
fun interface GmsProviderLog {

    fun log(line: String)

    companion object {
        /** Discards everything. The default in unit tests. */
        val NONE: GmsProviderLog = GmsProviderLog { }
    }
}

/**
 * The one line that answers "why did Duplika select this provider?".
 *
 * Built as a single structured line so it survives logcat interleaving inside a container,
 * which is where it will usually be read.
 */
internal fun formatSelectionLine(
    requested: GmsProviderMode,
    selected: GoogleServiceProvider,
    availability: ProviderAvailability,
    capabilities: Set<GmsCapability>,
    reason: String,
): String = buildString {
    append("GMS_PROVIDER")
    append(" requestedProvider=").append(requested.name)
    append(" selectedProvider=").append(selected.providerName)
    append(" availability=").append(availability.name)
    append(" capabilities=")
    append(if (capabilities.isEmpty()) "[]" else capabilities.joinToString(",", "[", "]") { it.name })
    append(" reason=\"").append(reason).append('"')
}
