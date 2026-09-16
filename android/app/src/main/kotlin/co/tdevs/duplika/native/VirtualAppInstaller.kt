package co.tdevs.duplika.native

import android.content.Context
import co.tdevs.duplika.native.gms.GmsProviderLog
import co.tdevs.duplika.native.gms.GmsProviderMode
import co.tdevs.duplika.native.gms.GoogleServiceProviderResolver
import co.tdevs.duplika.native.gms.MicroGProvider
import co.tdevs.duplika.native.gms.ProviderAvailability
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
     * How Google-service capability is resolved. Accepts injected providers so the selection
     * logic can be unit-tested without a device.
     */
    private val providerResolver: GoogleServiceProviderResolver =
        GoogleServiceProviderResolver(
            realGms = RealGmsProvider(adapter),
            microG = MicroGProvider.forEngine(context, adapter),
            log = GmsProviderLog { line -> Slog.i(Slog.INSTALL, line) },
        ),
    /** Requested provider mode. AUTO reproduces the pre-abstraction behaviour. */
    private val providerMode: GmsProviderMode = GmsProviderMode.DEFAULT,
    /**
     * The microG backend, held directly because the clone flow prefers it for a container
     * that genuinely needs Google services. See [provisionGoogleServices].
     */
    private val microGProvider: MicroGProvider = MicroGProvider.forEngine(context, adapter),
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
        provisionGoogleServices(
            virtualUserId,
            requiresGms = analyzer.analyze(packageName).requiresGms,
            explicitlyRequested = provisionGms,
        )
        return adapter.installPackage(packageName, virtualUserId)
    }

    /**
     * Provisions Google services into a fresh container when it needs them.
     *
     * **microG is preferred, and provisioned automatically for an app that requires Google
     * Play services.** The host-GMS copy is still modelled by [providerResolver] but is not
     * used for this: it cannot bootstrap inside a container (its Chimera modules fail to
     * load), whereas microG starts and completes FCM registration -- measured end to end on a
     * device, with a real token stored.
     *
     * This runs before the app itself is installed, so a clone that needs Google services has
     * a `com.google.android.gms` to find on its first launch rather than having to be
     * re-cloned. Provisioning failure is never fatal: the clone is still installed, degraded,
     * which is exactly the state the compatibility warning already describes.
     */
    private fun provisionGoogleServices(
        virtualUserId: Int,
        requiresGms: Boolean,
        explicitlyRequested: Boolean,
    ) {
        Slog.i(
            Slog.INSTALL,
            "Google services for user $virtualUserId: requiresGms=$requiresGms explicit=$explicitlyRequested",
        )
        // The resolver still runs for its selection diagnostic, so "which backend is active
        // and why" stays answerable even when nothing is provisioned.
        val selected = providerResolver.resolve(providerMode)
        if (!requiresGms && !explicitlyRequested) {
            return
        }

        // microG when it is bundled; otherwise fall back to the selected provider so an
        // explicit request still reaches the Real-GMS path rather than doing nothing.
        val provider = if (microGProvider.availability() == ProviderAvailability.AVAILABLE) {
            microGProvider
        } else {
            selected
        }

        when (val result = provider.provisionContainerGms(virtualUserId)) {
            is ProviderResult.Success -> Slog.i(
                Slog.INSTALL,
                "Google services provisioned into user $virtualUserId via ${result.provider}",
            )
            is ProviderResult.Unavailable -> Slog.w(
                Slog.INSTALL,
                "Google services provisioning skipped by ${result.provider}: ${result.reason}",
            )
            is ProviderResult.NotImplemented, is ProviderResult.Unsupported -> Slog.w(
                Slog.INSTALL,
                "Google services provisioning not served by ${result.provider} " +
                    "(${result.outcome}): ${result.reasonOrEmpty}",
            )
            else -> Slog.e(
                Slog.INSTALL,
                "Google services provisioning failed via ${result.provider} " +
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

        provisionGoogleServices(
            virtualUserId,
            requiresGms = analyzer.analyzeApk(apkPaths, packageName).requiresGms,
            explicitlyRequested = provisionGms,
        )
        return adapter.installApkFiles(apkPaths, virtualUserId)
    }

    fun uninstall(packageName: String, virtualUserId: Int): EngineResult<Unit> =
        adapter.uninstallPackage(packageName, virtualUserId)

    fun isInstalled(packageName: String, virtualUserId: Int): Boolean =
        adapter.isPackageInstalled(packageName, virtualUserId)
}
