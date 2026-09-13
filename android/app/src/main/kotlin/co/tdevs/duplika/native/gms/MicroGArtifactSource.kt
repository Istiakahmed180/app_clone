package co.tdevs.duplika.native.gms

import android.content.Context
import java.io.InputStream

/**
 * Where the bundled microG artefacts come from.
 *
 * A seam, so [MicroGProvider] can be tested without an APK, an engine or a device: the
 * provider only ever asks this for the *names* of the artefacts and a stream for each.
 */
interface MicroGArtifactSource {

    /** Base file names of the bundled microG APKs, sorted; empty when none are bundled. */
    fun apkAssetNames(): List<String>

    /** Opens one artefact named by [apkAssetNames]. */
    fun open(name: String): InputStream

    fun isPresent(): Boolean = apkAssetNames().isNotEmpty()
}

/**
 * Reads the artefacts from the app's own `assets/microg/` directory.
 *
 * What is bundled is the **official, unmodified** microG GmsCore (Apache-2.0), re-signed
 * only where an ABI trim required it. Nothing Google-proprietary is copied. The repository's
 * `NOTICE` carries the microG attribution obligation.
 */
class AssetMicroGArtifactSource(
    private val context: Context,
    private val assetDir: String = DEFAULT_ASSET_DIR,
) : MicroGArtifactSource {

    override fun apkAssetNames(): List<String> = runCatching {
        context.assets.list(assetDir)
            ?.filter { it.endsWith(".apk", ignoreCase = true) }
            ?.sorted()
            .orEmpty()
    }.getOrDefault(emptyList())

    override fun open(name: String): InputStream = context.assets.open("$assetDir/$name")

    companion object {
        const val DEFAULT_ASSET_DIR: String = "microg"
    }
}
