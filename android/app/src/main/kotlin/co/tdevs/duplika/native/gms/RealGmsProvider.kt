package co.tdevs.duplika.native.gms

import co.tdevs.duplika.native.EngineResult
import co.tdevs.duplika.native.VirtualizationEngineAdapter

/**
 * The host's genuine, Google-signed Play services — the default and the only provider that
 * works.
 *
 * This is an **adapter, not a reimplementation**. Every answer comes from the existing
 * [VirtualizationEngineAdapter] calls that `VirtualAppInstaller` used directly before this
 * phase:
 *
 * | Provider method | Delegates to (unchanged) |
 * | --- | --- |
 * | [hostGmsPresence] | `adapter.isGmsSupported()` |
 * | [provisionContainerGms] | `adapter.installGms(virtualUserId)` |
 *
 * The behaviour of the Real GMS path is therefore identical to before: the same engine
 * calls, in the same order, with the same arguments and the same outcomes. What changed is
 * only that the results are now modelled values rather than a `Boolean` and an
 * `EngineResult` interpreted at the call site.
 *
 * ## What this provider does not do
 *
 * It does not touch package identity, UID mapping, signatures, certificates, account
 * identity, Play Integrity or any security check — it cannot, because it only forwards two
 * calls whose implementations live in the engine and were not modified. In particular it
 * does **not** make the guest see Play services; that is the engine's host-platform package
 * visibility patch (`engine-patches/0002-host-platform-package-visibility.patch`), which is
 * unrelated to and unaffected by this class.
 *
 * Note that a `true` from `isGmsSupported()` means the *host* has Play services, which is a
 * different and weaker claim than "Google APIs work in a guest". The Level 10 evidence is
 * explicit that some do and some do not.
 */
class RealGmsProvider(
    private val adapter: VirtualizationEngineAdapter,
) : GoogleServiceProvider {

    override val providerName: String = NAME

    /**
     * Asked of the engine every time rather than cached.
     *
     * Play services can be disabled or uninstalled while Duplika is running, and a cached
     * `true` would then have the provider assert a presence that no longer exists — exactly
     * the fabricated-availability failure this abstraction is meant to prevent. The call is
     * a cheap engine query.
     */
    override fun availability(): ProviderAvailability =
        if (hostHasGms()) ProviderAvailability.AVAILABLE else ProviderAvailability.UNAVAILABLE

    override fun capabilities(): Set<GmsCapability> =
        if (hostHasGms()) {
            setOf(GmsCapability.HOST_GMS_PRESENCE, GmsCapability.CONTAINER_GMS_PROVISIONING)
        } else {
            // Not a partial set. Without host Play services there is nothing to report the
            // presence of and nothing to copy into a container.
            emptySet()
        }

    override fun hostGmsPresence(): ProviderResult<Boolean> {
        val present = hostHasGms()
        return ProviderResult.Success(
            provider = providerName,
            capability = GmsCapability.HOST_GMS_PRESENCE,
            value = present,
            diagnostics = mapOf("hostGmsPresent" to present.toString()),
        )
    }

    override fun provisionContainerGms(virtualUserId: Int): ProviderResult<Unit> {
        if (!hostHasGms()) {
            // The same precondition `provisionGmsIfRequested` checked before this phase,
            // preserved: a container can only be given what the host already has.
            return ProviderResult.Unavailable(
                provider = providerName,
                capability = GmsCapability.CONTAINER_GMS_PROVISIONING,
                reason = "the host has no Google Play services, so no container can be given it",
                diagnostics = mapOf("virtualUserId" to virtualUserId.toString()),
            )
        }
        return when (val result = adapter.installGms(virtualUserId)) {
            is EngineResult.Success -> ProviderResult.Success(
                provider = providerName,
                capability = GmsCapability.CONTAINER_GMS_PROVISIONING,
                value = Unit,
                diagnostics = mapOf("virtualUserId" to virtualUserId.toString()),
            )
            is EngineResult.Failure -> ProviderResult.Error(
                provider = providerName,
                capability = GmsCapability.CONTAINER_GMS_PROVISIONING,
                code = result.code,
                message = result.message,
                diagnostics = mapOf("virtualUserId" to virtualUserId.toString()),
            )
        }
    }

    /**
     * `isGmsSupported` is the engine's own guarded call, but it crosses into Bcore and a
     * provider must not propagate a surprise from there into selection — the resolver calls
     * this while *choosing*, and a throw would take out the clone instead of degrading it.
     * An unreadable answer is treated as "no", which is the safe direction: it declines
     * provisioning rather than attempting it blind.
     */
    private fun hostHasGms(): Boolean = runCatching { adapter.isGmsSupported() }.getOrDefault(false)

    companion object {
        const val NAME: String = "REAL_GMS"
    }
}
