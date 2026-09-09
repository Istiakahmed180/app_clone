package co.tdevs.duplika.native.gms

/**
 * microG — an architectural placeholder with **no implementation**.
 *
 * This class exists for exactly one reason: to prove the provider abstraction can hold a
 * second backend without the Real GMS path changing. It is not a microG integration and
 * must not be mistaken for the beginning of one.
 *
 * ## What it deliberately does not do
 *
 * - It does not bundle, download, install or reference any microG artefact.
 * - It does not copy or modify any proprietary Google component.
 * - It does not detect microG. [availability] returns [ProviderAvailability.NOT_IMPLEMENTED]
 *   unconditionally — **not** the result of a lookup. Detecting microG would imply the rest
 *   of the class could then serve it, and it cannot; a provider that could report
 *   `AVAILABLE` while every operation returns `NotImplemented` would be exactly the
 *   "pretend the APIs work" failure the brief forbids.
 * - It reports **no** capabilities, so [GoogleServiceProviderResolver] can never select it
 *   in AUTO mode.
 * - Every operation returns [ProviderResult.NotImplemented]. Nothing returns a plausible
 *   default, an empty success, or `false`-as-if-measured.
 *
 * The one thing it does provide is a *deterministic, structured* refusal that names itself,
 * so a caller that ends up here learns why rather than seeing a generic failure.
 *
 * ## Implementing this later
 *
 * The order matters, and it is the opposite of what is tempting:
 *
 * 1. make [availability] a real detection of an actually-installed microG;
 * 2. implement one capability, and add it to [capabilities] **only once it is verified on a
 *    device**;
 * 3. leave every unimplemented capability returning [ProviderResult.NotImplemented].
 *
 * Adding a capability to [capabilities] before it works would make AUTO selection prefer a
 * backend that cannot serve — the single most damaging change possible to this file. See
 * `docs/level10-gms-provider-architecture.md`.
 */
class MicroGProvider : GoogleServiceProvider {

    override val providerName: String = NAME

    /** Unconditional. Not a detection — see the class note. */
    override fun availability(): ProviderAvailability = ProviderAvailability.NOT_IMPLEMENTED

    /** Empty, and must stay empty until a capability is implemented and device-verified. */
    override fun capabilities(): Set<GmsCapability> = emptySet()

    override fun hostGmsPresence(): ProviderResult<Boolean> =
        notImplemented(GmsCapability.HOST_GMS_PRESENCE)

    override fun provisionContainerGms(virtualUserId: Int): ProviderResult<Unit> =
        notImplemented(GmsCapability.CONTAINER_GMS_PROVISIONING)

    private fun notImplemented(capability: GmsCapability): ProviderResult<Nothing> =
        ProviderResult.NotImplemented(
            provider = providerName,
            capability = capability,
            reason = "the microG provider is an architectural placeholder; " +
                "no microG implementation exists in this build",
            diagnostics = mapOf("implementationStatus" to IMPLEMENTATION_STATUS),
        )

    companion object {
        const val NAME: String = "MICROG"

        /** Reported in diagnostics so a log line states the status without inference. */
        const val IMPLEMENTATION_STATUS: String = "NOT_IMPLEMENTED"
    }
}
