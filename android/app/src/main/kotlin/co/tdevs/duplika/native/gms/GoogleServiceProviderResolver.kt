package co.tdevs.duplika.native.gms

/**
 * Chooses the provider. The only place that decides.
 *
 * Selection is **deterministic**: the same mode and the same environment always yield the
 * same provider and the same stated reason. Nothing here probes the network, caches a
 * verdict, or falls back on a guess.
 *
 * The rules, in full:
 *
 * | Mode | Outcome |
 * | --- | --- |
 * | `AUTO` | Real GMS if the host genuinely has it; else a real microG implementation if one ever exists; else unsupported. |
 * | `REAL_GMS` | Real GMS if genuinely available; else unsupported with a stated reason. **No fallback.** |
 * | `MICROG` | microG if genuinely available (never, today); else unsupported saying it is not implemented. **Never falls back to Real GMS.** |
 * | `DISABLED` | Unsupported, always. |
 *
 * A provider is only ever selected on the strength of its **own** report of what it can
 * serve, and every non-AUTO mode is checked against that report too. So no mode can
 * conjure a capability: this is the property that makes the abstraction safe to extend, and
 * it is what the unit tests pin down.
 */
class GoogleServiceProviderResolver(
    private val realGms: GoogleServiceProvider,
    private val microG: GoogleServiceProvider = MicroGProvider(),
    private val log: GmsProviderLog = GmsProviderLog.NONE,
) {

    /**
     * Resolves [mode] against the current environment and logs the reasoning.
     *
     * Deliberately not memoised. Play services can be disabled or uninstalled while Duplika
     * runs, so a cached provider could assert a backend that has since gone; each call
     * re-reads the environment, and the reads are cheap engine queries.
     */
    fun resolve(mode: GmsProviderMode = GmsProviderMode.DEFAULT): GoogleServiceProvider {
        val selection = select(mode)
        log.log(
            formatSelectionLine(
                requested = mode,
                selected = selection.provider,
                availability = selection.provider.availability(),
                capabilities = selection.provider.capabilities(),
                reason = selection.reason,
            )
        )
        return selection.provider
    }

    private fun select(mode: GmsProviderMode): Selection = when (mode) {
        GmsProviderMode.DISABLED -> Selection(
            UnsupportedProvider(
                "Google service integration is disabled by configuration (mode=DISABLED); " +
                    "this governs Duplika's own operations only and does not affect a " +
                    "guest app's access to the host's Play services"
            ),
            "configuration disabled Google service integration",
        )

        GmsProviderMode.REAL_GMS -> if (canServe(realGms)) {
            Selection(realGms, "Real GMS was requested and is available on this host")
        } else {
            Selection(
                UnsupportedProvider(
                    "Real GMS was requested but the host has no usable Google Play services"
                ),
                "Real GMS requested but unavailable; not falling back",
            )
        }

        GmsProviderMode.MICROG -> if (canServe(microG)) {
            Selection(microG, "microG was requested and is available")
        } else {
            Selection(
                UnsupportedProvider(
                    "microG was requested but no microG implementation exists in this " +
                        "build (implementationStatus=${MicroGProvider.IMPLEMENTATION_STATUS})"
                ),
                "microG requested but not implemented; deliberately not falling back to Real GMS",
            )
        }

        GmsProviderMode.AUTO -> when {
            // Real GMS first: it is the only backend that works, and preferring the
            // genuine host installation is the correct default.
            canServe(realGms) ->
                Selection(realGms, "AUTO selected Real GMS because the host has it")
            // Reachable only once MicroGProvider both detects and implements something.
            canServe(microG) ->
                Selection(microG, "AUTO selected microG because Real GMS is unavailable")
            else -> Selection(
                UnsupportedProvider(
                    "no Google service backend is available: the host has no usable Google " +
                        "Play services and no microG implementation exists in this build"
                ),
                "AUTO found no available backend",
            )
        }
    }

    /**
     * Whether a provider is genuinely usable.
     *
     * Both conditions are required, and the second is the important one: a provider that
     * claims [ProviderAvailability.AVAILABLE] but reports no capabilities cannot serve
     * anything, and selecting it would produce failures at the call site instead of an
     * honest `UnsupportedProvider` here. Requiring a non-empty capability set is what stops
     * a future half-finished provider from being picked.
     */
    private fun canServe(provider: GoogleServiceProvider): Boolean =
        provider.availability() == ProviderAvailability.AVAILABLE &&
            provider.capabilities().isNotEmpty()

    private data class Selection(val provider: GoogleServiceProvider, val reason: String)
}
