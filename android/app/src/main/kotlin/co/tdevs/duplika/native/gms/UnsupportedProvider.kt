package co.tdevs.duplika.native.gms

/**
 * The terminal fallback: a provider that serves nothing, deterministically.
 *
 * Selected when no backend can serve — no host Play services, or the user chose
 * [GmsProviderMode.DISABLED], or a requested provider is not available. It exists so those
 * cases have a real object with real answers instead of a null, an exception or a silently
 * skipped branch.
 *
 * Every operation returns [ProviderResult.Unavailable] carrying the [reason] it was
 * constructed with, so the answer explains *why* this provider is in play. That reason is
 * supplied by the resolver at selection time, which is the only place that knows.
 *
 * It never throws and never crashes. A caller holding this provider gets the same structured
 * answer it would get from any other, which is what lets call sites treat "no Google
 * services" as an ordinary branch rather than an error path.
 *
 * `Unavailable` rather than `Unsupported` is deliberate: the situation is a property of the
 * environment or the configuration, not a permanent property of the capability. On a device
 * with Play services, or with the mode set back to AUTO, the same call would be served.
 */
class UnsupportedProvider(
    /**
     * Why no usable provider was selected, in operator-facing terms. Set by
     * [GoogleServiceProviderResolver]; surfaced verbatim in every result.
     */
    private val reason: String = DEFAULT_REASON,
) : GoogleServiceProvider {

    override val providerName: String = NAME

    override fun availability(): ProviderAvailability = ProviderAvailability.UNAVAILABLE

    override fun capabilities(): Set<GmsCapability> = emptySet()

    override fun hostGmsPresence(): ProviderResult<Boolean> =
        unavailable(GmsCapability.HOST_GMS_PRESENCE)

    override fun provisionContainerGms(virtualUserId: Int): ProviderResult<Unit> =
        unavailable(GmsCapability.CONTAINER_GMS_PROVISIONING)

    private fun unavailable(capability: GmsCapability): ProviderResult<Nothing> =
        ProviderResult.Unavailable(
            provider = providerName,
            capability = capability,
            reason = reason,
            diagnostics = mapOf("recoverable" to "true"),
        )

    companion object {
        const val NAME: String = "UNSUPPORTED"

        const val DEFAULT_REASON: String =
            "no Google service provider is available in this environment"
    }
}
