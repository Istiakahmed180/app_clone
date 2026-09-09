package co.tdevs.duplika.native.gms

/**
 * A backend that can answer Duplika's Google-service questions.
 *
 * Three implementations exist: [RealGmsProvider] (the host's genuine Play services, and the
 * only one that works), [MicroGProvider] (a declared placeholder, no implementation) and
 * [UnsupportedProvider] (deterministic refusals). Selection is
 * [GoogleServiceProviderResolver]'s job, not a caller's.
 *
 * ## Contract
 *
 * - [availability] and [capabilities] must be cheap and side-effect free. The resolver calls
 *   them to *choose* a provider, so a provider that provisioned something while being
 *   inspected would make selection observable.
 * - A capability absent from [capabilities] must still be callable and must return a
 *   modelled [ProviderResult] — never throw. A caller may hold a provider reference across
 *   an environment change, and crashing is not an acceptable answer to "can you do this".
 * - No implementation may fabricate availability. Reporting a capability that is not
 *   genuinely present is the one thing this abstraction exists to make impossible: the whole
 *   point of the Level 9/10 work is that Duplika reports the host's real state.
 */
interface GoogleServiceProvider {

    /** Stable identifier used in logs, results and reports. Never localised. */
    val providerName: String

    /**
     * Whether this provider can serve anything in the current environment.
     *
     * Must reflect the real environment. [ProviderAvailability.AVAILABLE] means the backend
     * is genuinely present — for [RealGmsProvider] that it asked the engine and the host
     * really has Play services.
     */
    fun availability(): ProviderAvailability

    /**
     * The capabilities this provider can actually serve **right now**, given both what it
     * implements and what the environment offers.
     *
     * Environment-dependent on purpose: `RealGmsProvider` on a device with no Play services
     * reports an empty set rather than claiming `HOST_GMS_PRESENCE` and then failing. So an
     * empty set is a legitimate answer and callers must handle it.
     */
    fun capabilities(): Set<GmsCapability>

    /** Whether the host has legitimate Google Play services. */
    fun hostGmsPresence(): ProviderResult<Boolean>

    /**
     * Provision Google packages into the container for [virtualUserId].
     *
     * Present because the code path exists and is reachable, not because it is recommended
     * — see [GmsCapability.CONTAINER_GMS_PROVISIONING].
     */
    fun provisionContainerGms(virtualUserId: Int): ProviderResult<Unit>
}

/** Whether a provider's backend is genuinely present. */
enum class ProviderAvailability {

    /** The backend is really there and usable. */
    AVAILABLE,

    /**
     * This provider's backend is not present in this environment. Says nothing about
     * whether the provider is implemented — a fully implemented provider is UNAVAILABLE on
     * a device that lacks its backend.
     */
    UNAVAILABLE,

    /**
     * The provider is a placeholder with no implementation, so availability is not even a
     * meaningful question yet. Kept separate from [UNAVAILABLE] so a resolver can never
     * pick a placeholder by mistaking "unwritten" for "absent".
     */
    NOT_IMPLEMENTED,
}
