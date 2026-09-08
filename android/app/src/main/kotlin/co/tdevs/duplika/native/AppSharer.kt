package co.tdevs.duplika.native

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File

/**
 * Hands a cloned app's APK to the Android share sheet.
 *
 * Shares the **installable archive**, not a store link. That is the only reading that
 * works for this app: a clone can be created from an imported APK that exists on no
 * store at all, and the whole point of sharing it is that the recipient can install or
 * clone the same thing. A `play.google.com` URL would be a dead end for exactly the
 * clones a user is most likely to want to pass on.
 *
 * The archive is copied into Duplika's own cache first, because a share needs a URI the
 * receiving app can read and `/data/app/...` is not ours to grant. The copy is the cost
 * of that: a large app means a large copy, so this runs on a background thread and the
 * staging directory is emptied before each share rather than accumulating.
 *
 * The copy goes out as `<app name>_<timestamp>.papk.bin` under a generic binary MIME
 * type rather than as `<package>.apk`. Two reasons: the APK type makes most receivers
 * refuse the file outright -- Drive, Gmail and several chat apps will not accept a
 * package -- and the name says which app and which moment it came from, which a package
 * name does not. The trade is that the recipient cannot tap the file to install it; it
 * comes back in through Duplika's own APK import, which accepts this extension.
 */
class AppSharer(context: Context) {

    private val appContext = context.applicationContext

    /**
     * Copies the APK for [packageName] into cache and starts the chooser.
     *
     * Prefers the copy retained for an imported clone: that clone's package may not be
     * installed on the host at all, and even when it is, the retained file is the exact
     * archive this clone was built from.
     */
    fun share(profileId: String, packageName: String, label: String): EngineResult<Unit> {
        val source = retainedApk(profileId) ?: hostApk(packageName)
            ?: return EngineResult.Failure(
                EngineErrorCodes.APK_NOT_AVAILABLE,
                "This clone's APK is no longer on the device, so there is nothing to share.",
            )

        return try {
            val staged = stage(source, label)
            val uri: Uri = FileProvider.getUriForFile(appContext, FILE_PROVIDER_AUTHORITY, staged)

            val send = Intent(Intent.ACTION_SEND)
                .setType(SHARE_MIME)
                .putExtra(Intent.EXTRA_STREAM, uri)
                .putExtra(Intent.EXTRA_SUBJECT, label)
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

            appContext.startActivity(
                Intent.createChooser(send, label)
                    .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    // Started from the application context, so the chooser needs its own task.
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            Slog.i(Slog.PROFILE, "Shared the APK for $packageName")
            EngineResult.ok()
        } catch (error: Throwable) {
            Slog.e(Slog.PROFILE, "Sharing $packageName failed", error)
            EngineResult.Failure(
                EngineErrorCodes.SHARE_FAILED,
                error.message ?: "The app could not be shared.",
            )
        }
    }

    private fun retainedApk(profileId: String): File? =
        VirtualProfileManager(appContext)
            .apkPathsFor(profileId)
            .map(::File)
            .firstOrNull { it.isFile && it.canRead() }

    private fun hostApk(packageName: String): File? = try {
        val info = appContext.packageManager.getApplicationInfo(packageName, 0)
        File(info.sourceDir).takeIf { it.isFile && it.canRead() }
    } catch (_: PackageManager.NameNotFoundException) {
        null
    }

    /**
     * Copies [source] into the share staging directory under a readable filename.
     *
     * The directory is cleared first: these are whole APKs, and a user who shares a few
     * apps should not be left with hundreds of megabytes of copies in the app's cache.
     */
    private fun stage(source: File, label: String): File {
        val staging = File(appContext.cacheDir, STAGING_DIR)
        if (staging.exists()) {
            staging.deleteRecursively()
        }
        staging.mkdirs()

        val target =
            File(staging, fileName(label) + "_" + System.currentTimeMillis() + EXTENSION)
        source.inputStream().use { input ->
            target.outputStream().use(input::copyTo)
        }
        return target
    }

    /**
     * The app's name, reduced to something a filesystem and a mail client will both
     * accept.
     *
     * Trimmed to [MAX_NAME] because the app name is user-editable while Android's
     * 255-byte filename limit is not: a clone someone named by pasting a paragraph would
     * otherwise fail to stage at all.
     */
    private fun fileName(label: String): String {
        val cleaned = label
            .map { if (it.isLetterOrDigit() || it == '-') it else '_' }
            .joinToString("")
            .trim('_')
        return when {
            cleaned.isEmpty() -> "app"
            cleaned.length > MAX_NAME -> cleaned.take(MAX_NAME)
            else -> cleaned
        }
    }

    private companion object {
        /**
         * Deliberately generic. `application/vnd.android.package-archive` is refused by
         * most receivers, which is the whole reason the file does not go out as an APK.
         */
        const val SHARE_MIME = "application/octet-stream"

        /** Matched by the APK importer's allowed extensions. Keep the two in step. */
        const val EXTENSION = ".papk.bin"
        const val MAX_NAME = 64
        const val STAGING_DIR = "shared_apk"

        /** Must match the `android:authorities` of the provider in AndroidManifest.xml. */
        const val FILE_PROVIDER_AUTHORITY = "co.tdevs.duplika.share.fileprovider"
    }
}
