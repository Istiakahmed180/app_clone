package co.tdevs.duplika.native

import android.content.Context
import co.tdevs.duplika.native.gms.GmsProviderLog
import co.tdevs.duplika.native.gms.GmsProviderMode
import co.tdevs.duplika.native.gms.GoogleServiceProviderResolver
import co.tdevs.duplika.native.gms.ProviderResult
import co.tdevs.duplika.native.gms.RealGmsProvider

/**
 * Installs the controlled application into a virtual profile.
 *
 * Only the package identity is handed to the engine, which resolves the APK through the
 * platform's own PackageManager. Duplika never reads the target application's
 * private data directory and never copies its files.
 */
class VirtualAppInstaller(
    private val context: Context,
    private val adapter: VirtualizationEngineAdapter,
    private val securityChecker: AppSecurityChecker,
    private val analyzer: AppCompatibilityAnalyzer,
    /**
     * How Google-service capability is resolved. Defaults to Real GMS over the same engine
     * adapter this class already holds, so the default behaviour is byte-for-byte the
     * behaviour that was here before the provider abstraction: the same two engine calls,
     * in the same order.
     *
     * Injectable so the selection logic can be unit-tested without a device.
     */
    private val providerResolver: GoogleServiceProviderResolver =
        GoogleServiceProviderResolver(
            realGms = RealGmsProvider(adapter),
            log = GmsProviderLog { line -> Slog.i(Slog.INSTALL, line) },
        ),
    /** Requested provider mode. AUTO reproduces the pre-abstraction behaviour. */
    private val providerMode: GmsProviderMode = GmsProviderMode.DEFAULT,
) {

    fun install(
        packageName: String,
        virtualUserId: Int,
        provisionGms: Boolean,
    ): EngineResult<Unit> {
        when (val verdict = securityChecker.check(packageName)) {
            is AppSecurityChecker.Verdict.Rejected ->
                return EngineResult.Failure(verdict.code, verdict.message)
            AppSecurityChecker.Verdict.Allowed -> Unit
        }

        // Deliberately no "already installed?" short-circuit. Bcore's isInstalled answers
        // from the *host* package manager whenever its own service is unhealthy, so it
        // reports every host-installed app as present in every container and would skip a
        // real install. Re-installing is idempotent and does not clear container data
        // (only the explicit clearPackage does), so always going through is both safe and
        // the only way to guarantee the per-user record exists.
        provisionGmsIfRequested(
            virtualUserId,
            provisionGms && analyzer.analyze(packageName).requiresGms,
        )
        return adapter.installPackage(packageName, virtualUserId)
    }

    /**
     * Resolves which Google-service provider is active, and -- only if still asked --
     * provisions a container-local copy of the Google packages.
     *
     * ## Provisioning is RETIRED. [wanted] is false on every production path.
     *
     * There is no longer any UI that can request it: the compatibility sheet's
     * "Install Google Play services in this clone" checkbox was removed, and both clone
     * routes (installed app and imported APK) now leave it off. Two measured reasons:
     *
     * - **It shadows the path that works.** Every hook in the engine's
     *   `IPackageManagerProxy` answers from the container first and only falls back to the
     *   host. A provisioned container therefore answers GMS queries from its own copy, and
     *   the host's genuine, Google-signed Play services is never consulted -- so opting in
     *   *removed* working host passthrough from that clone.
     * - **The copy cannot start.** It fails its Chimera module bootstrap
     *   (`app_chimera/current_config.fb: ENOENT`, then
     *   `GmsProxy: Failed to get gms service binder`), because Play services resolves its
     *   real implementation from its own data directory and expects to be the platform's
     *   singleton. Availability came back `SERVICE_INVALID(9)`.
     *
     * For the record, the earlier explanation in this comment -- that provisioning failed
     * because the container "cannot present Google's signing certificate" -- was
     * **falsified**: the container reports Google's genuine certificate history
     * byte-identically to the host and was still rejected. Host passthrough now returns
     * `SUCCESS(0)` in a guest with no certificate work at all. See
     * `evidence/physical-android15/level9-gms/host-passthrough-investigation/`.
     *
     * The call is kept, isolated and disabled, rather than deleted: it is the only
     * implementation of [GmsCapability.CONTAINER_GMS_PROVISIONING], which the provider
     * abstraction models honestly so a provider can *decline* it instead of silently
     * attempting it, and a future provider may have a legitimate reason to provision.
     *
     * The provider is resolved before the early return so the selection diagnostic is
     * emitted for every clone, not just the (now unreachable) opt-in path.
     *
     * Failure is deliberately not fatal. A clone whose provisioning failed is exactly the
     * clone the compatibility warning already describes, so the app is still installed --
     * degraded rather than absent. The reason is logged.
     */
    private fun provisionGmsIfRequested(virtualUserId: Int, wanted: Boolean) {
        // Logged unconditionally: whether a container gets GMS decides whether Google sign-in
        // and push work inside it, and silently skipping was previously indistinguishable from
        // provisioning that ran and did nothing.
        Slog.i(Slog.INSTALL, "GMS provisioning for user $virtualUserId: requested=$wanted")

        // Resolved -- and therefore logged -- before the early return, so "which provider is
        // active, and why" is answerable for every clone rather than only for the rare one
        // that opted into provisioning. That is the whole point of the selection diagnostic;
        // emitting it only on the opt-in path would leave the normal path silent.
        //
        // The cost is one extra read-only engine query (isGmsSupported) per clone install.
        // It changes no outcome: nothing is provisioned unless `wanted`, exactly as before.
        val provider = providerResolver.resolve(providerMode)

        if (!wanted) {
            return
        }
        // The provider decides, rather than this method asking the engine directly. With the
        // default AUTO mode and Real GMS available the calls made are exactly the two that
        // were made before -- isGmsSupported() then installGms() -- so behaviour is
        // unchanged; the difference is that "no host GMS" and "engine refused" are now
        // distinguishable outcomes instead of a boolean and an EngineResult read here.
        //
        // No "already provisioned?" short-circuit, for the same reason install() has none:
        // the engine answers that question with isInstalled, which falls back to the *host*
        // package manager. The host has Google Play services, so it reports every container
        // as already provisioned and the real work is skipped -- measured, after this check
        // silently suppressed provisioning entirely. Re-provisioning is idempotent.
        when (val result = provider.provisionContainerGms(virtualUserId)) {
            is ProviderResult.Success -> Unit
            // Preserves the previous behaviour for the no-host-GMS case: a warning and a
            // skip, never a failed install. A clone whose GMS provisioning was skipped is
            // exactly the clone the compatibility warning already describes.
            is ProviderResult.Unavailable -> Slog.w(
                Slog.INSTALL,
                "GMS provisioning skipped by ${result.provider}: ${result.reason}",
            )
            is ProviderResult.NotImplemented, is ProviderResult.Unsupported -> Slog.w(
                Slog.INSTALL,
                "GMS provisioning not served by ${result.provider} " +
                    "(${result.outcome}): ${result.reasonOrEmpty}",
            )
            else -> Slog.e(
                Slog.INSTALL,
                "GMS provisioning failed via ${result.provider} " +
                    "(${result.outcome}): ${result.reasonOrEmpty}",
            )
        }
    }

    /**
     * Installs a standalone APK the user imported.
     *
     * The package identity is parsed from the archive first so the same admission policy
     * applies as for an installed app — an APK that declares a secure-environment
     * requirement is rejected before the engine ever sees it.
     */
    fun installApks(
        apkPaths: List<String>,
        packageName: String,
        virtualUserId: Int,
        provisionGms: Boolean,
    ): EngineResult<Unit> {
        when (val verdict = securityChecker.checkApk(packageName, apkPaths.first())) {
            is AppSecurityChecker.Verdict.Rejected ->
                return EngineResult.Failure(verdict.code, verdict.message)
            AppSecurityChecker.Verdict.Allowed -> Unit
        }

        provisionGmsIfRequested(
            virtualUserId,
            provisionGms && analyzer.analyzeApk(apkPaths.first(), packageName).requiresGms,
        )
        return adapter.installApkFiles(apkPaths, virtualUserId)
    }

    fun uninstall(packageName: String, virtualUserId: Int): EngineResult<Unit> =
        adapter.uninstallPackage(packageName, virtualUserId)

    fun isInstalled(packageName: String, virtualUserId: Int): Boolean =
        adapter.isPackageInstalled(packageName, virtualUserId)
}
