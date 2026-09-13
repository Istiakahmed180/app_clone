package co.tdevs.duplika.native.gms

import android.content.Context
import co.tdevs.duplika.native.EngineResult
import co.tdevs.duplika.native.VirtualizationEngineAdapter
import java.io.File

/**
 * microG — a real, measured implementation.
 *
 * It provisions the **bundled** microG GmsCore into a container as that container's
 * `com.google.android.gms`, so a cloned app's Google client libraries have a local
 * implementation to bind. It was implemented only after being verified on a device: a cloned
 * Firebase app in a Duplika container completed push registration and stored a real FCM
 * token. See `docs/microg-container-spike.md`.
 *
 * ## What makes it work in this container (and what it does not do)
 *
 * - It installs the artefact through the engine's ordinary APK install path; no engine
 *   private state is touched.
 * - The guest trusts it because the engine already answers with the **host package's**
 *   certificate for a container package that shares the host's name
 *   (`PackageManagerCompat.generatePackageInfo`). This provider spoofs **no** signature,
 *   package identity, UID or account, and does not touch Play Integrity.
 * - It seeds microG's own checkin/push switches, which default to off (see
 *   [MicroGCheckinSeeder]).
 *
 * ## Honesty rules it keeps
 *
 * - [availability] is a real detection: the artefact is bundled or it is not.
 * - [capabilities] is empty when nothing is bundled, so [GoogleServiceProviderResolver] can
 *   never select a backend that cannot serve.
 * - [hostGmsPresence] is [ProviderResult.Unsupported] on purpose: microG says nothing about
 *   the host's Play services, and reporting a value there would be fabrication.
 */
class MicroGProvider(
    private val artifactSource: MicroGArtifactSource,
    private val materialize: (String) -> File?,
    private val installApk: (path: String, virtualUserId: Int) -> EngineResult<Unit>,
    private val seedCheckin: (virtualUserId: Int) -> Boolean,
) : GoogleServiceProvider {

    override val providerName: String = NAME

    /** Real detection, not an assertion: true only when an artefact is actually bundled. */
    override fun availability(): ProviderAvailability =
        if (artifactSource.isPresent()) ProviderAvailability.AVAILABLE
        else ProviderAvailability.UNAVAILABLE

    /**
     * `CONTAINER_GMS_PROVISIONING` only when an artefact is bundled. Empty otherwise, so
     * AUTO selection cannot pick a backend with nothing to install.
     */
    override fun capabilities(): Set<GmsCapability> =
        if (artifactSource.isPresent()) setOf(GmsCapability.CONTAINER_GMS_PROVISIONING)
        else emptySet()

    override fun hostGmsPresence(): ProviderResult<Boolean> = ProviderResult.Unsupported(
        provider = providerName,
        capability = GmsCapability.HOST_GMS_PRESENCE,
        reason = "microG does not report the host's Play services presence; Real GMS does",
    )

    override fun provisionContainerGms(virtualUserId: Int): ProviderResult<Unit> {
        val assetNames = artifactSource.apkAssetNames()
        if (assetNames.isEmpty()) {
            return ProviderResult.Unavailable(
                provider = providerName,
                capability = GmsCapability.CONTAINER_GMS_PROVISIONING,
                reason = "no microG artefact is bundled in this build",
                diagnostics = mapOf("virtualUserId" to virtualUserId.toString()),
            )
        }

        // Each bundled artefact is a separate package (GmsCore, optionally FakeStore), not a
        // base+split set, so install them one at a time.
        var installed = 0
        assetNames.forEach { name ->
            val file = materialize(name)
            if (file == null || !file.isFile) {
                return ProviderResult.Error(
                    provider = providerName,
                    capability = GmsCapability.CONTAINER_GMS_PROVISIONING,
                    code = "MICROG_ARTIFACT_UNREADABLE",
                    message = "bundled microG artefact $name could not be read",
                    diagnostics = mapOf("virtualUserId" to virtualUserId.toString()),
                )
            }
            when (val result = installApk(file.absolutePath, virtualUserId)) {
                is EngineResult.Success -> installed++
                is EngineResult.Failure -> return ProviderResult.Error(
                    provider = providerName,
                    capability = GmsCapability.CONTAINER_GMS_PROVISIONING,
                    code = result.code,
                    message = "install of $name failed: ${result.message}",
                    diagnostics = mapOf("virtualUserId" to virtualUserId.toString()),
                )
            }
        }

        if (installed == 0) {
            return ProviderResult.Error(
                provider = providerName,
                capability = GmsCapability.CONTAINER_GMS_PROVISIONING,
                code = "MICROG_INSTALL_FAILED",
                message = "no microG artefact was installed",
                diagnostics = mapOf("virtualUserId" to virtualUserId.toString()),
            )
        }

        // Fire-and-check: a failure here is worth surfacing, but the packages are installed,
        // so it is reported through diagnostics rather than as a hard error.
        val checkinSeeded = seedCheckin(virtualUserId)

        return ProviderResult.Success(
            provider = providerName,
            capability = GmsCapability.CONTAINER_GMS_PROVISIONING,
            value = Unit,
            diagnostics = mapOf(
                "virtualUserId" to virtualUserId.toString(),
                "artifactsInstalled" to installed.toString(),
                "checkinSeeded" to checkinSeeded.toString(),
            ),
        )
    }

    companion object {
        const val NAME: String = "MICROG"

        /** Builds the provider wired to the app's assets, the engine and the cache dir. */
        fun forEngine(context: Context, adapter: VirtualizationEngineAdapter): MicroGProvider {
            val source = AssetMicroGArtifactSource(context)
            return MicroGProvider(
                artifactSource = source,
                materialize = { name -> materializeAsset(context, source, name) },
                installApk = { path, userId -> adapter.installApkFiles(listOf(path), userId) },
                seedCheckin = { userId -> MicroGCheckinSeeder.seed(adapter, userId) },
            )
        }

        /**
         * Copies one bundled artefact out of the APK into the cache so the engine can read
         * it as a file. Re-copies when the size differs, so an updated bundle replaces a
         * stale cache copy.
         */
        private fun materializeAsset(
            context: Context,
            source: MicroGArtifactSource,
            name: String,
        ): File? = runCatching {
            val dir = File(context.cacheDir, "microg").apply { mkdirs() }
            val target = File(dir, name)
            val bytes = source.open(name).use { it.readBytes() }
            if (!target.isFile || target.length() != bytes.size.toLong()) {
                target.writeBytes(bytes)
            }
            target
        }.getOrNull()
    }
}
