package co.tdevs.duplika.native.gms

/**
 * The Google-service capabilities Duplika itself actually uses.
 *
 * Deliberately only two. The audit (`docs/level10-gms-provider-audit.md`) established that
 * Duplika's production code makes no Google API calls of its own: Google APIs are called by
 * the *guest apps* inside containers, directly against the host's real Play services
 * through the engine's IPC. Duplika is the substrate under that call path, not a
 * participant in it.
 *
 * So there is no location, messaging or GoogleApi-client functionality here to model.
 * Adding `LocationServiceCapability`, `MessagingServiceCapability` or
 * `GoogleApiCapability` now would be abstracting nothing, and an interface with no
 * implementation and no caller is worse than no interface: it invites a future provider to
 * implement a contract nobody verified. Those become entries here only if Duplika itself
 * ever calls such an API — see `docs/level10-gms-provider-architecture.md` for how to add
 * one.
 */
enum class GmsCapability {

    /**
     * Whether legitimate Google Play services exists on the **host**.
     *
     * A container can only ever be given what the host already has, so this gates
     * everything else. Backed today by `VirtualizationEngineAdapter.isGmsSupported()`.
     */
    HOST_GMS_PRESENCE,

    /**
     * Provisioning Google packages **into a container**.
     *
     * Carried through the abstraction because it is real, existing, reachable code — not
     * because it is recommended. It is known not to work (the container copy cannot
     * bootstrap its Chimera modules) and to shadow the host-passthrough path that does
     * work, and the standing recommendation is to disable it by default. Modelling it
     * honestly is what lets a provider decline it rather than silently attempt it.
     */
    CONTAINER_GMS_PROVISIONING,
}
