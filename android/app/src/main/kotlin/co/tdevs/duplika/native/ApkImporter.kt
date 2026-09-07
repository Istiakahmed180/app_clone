package co.tdevs.duplika.native

import android.content.Context
import android.content.pm.PackageManager
import android.content.res.AssetManager
import java.io.File

/**
 * Reads metadata from a standalone APK file the user picked, so the host can show what it
 * is (and run the same admission checks) before anything is installed into a container.
 *
 * The file is only ever read; it is never modified, re-signed or rewritten.
 */
class ApkImporter(private val context: Context) {

    sealed interface ApkInfo {
        data class Parsed(
            val packageName: String,
            val appName: String,
            val versionName: String?,
            val versionCode: Long,
            val apkPaths: List<String>,
            val baseApkPath: String,
            val splitApkPaths: List<String>,
        ) : ApkInfo

        data class Invalid(val code: String, val message: String) : ApkInfo
    }

    fun inspect(apkPaths: List<String>): ApkInfo {
        if (apkPaths.isEmpty()) {
            return ApkInfo.Invalid(EngineErrorCodes.APK_INVALID, "Select at least one APK.")
        }

        data class Archive(
            val path: String,
            val packageName: String,
            val versionName: String?,
            val versionCode: Long?,
            val splitName: String?,
            val applicationInfo: android.content.pm.ApplicationInfo?,
        )

        val archives = mutableListOf<Archive>()
        for (apkPath in apkPaths) {
            val file = File(apkPath)
            if (!file.isFile || !file.canRead()) {
                return ApkInfo.Invalid(
                    EngineErrorCodes.APK_UNREADABLE,
                    "One of the selected APKs could not be read.",
                )
            }
            val packageInfo = context.packageManager.getPackageArchiveInfo(apkPath, 0)
            if (packageInfo != null) {
                archives += Archive(
                    path = apkPath,
                    packageName = packageInfo.packageName,
                    versionName = packageInfo.versionName,
                    versionCode = longVersionCode(packageInfo),
                    splitName = packageInfo.splitNames?.singleOrNull(),
                    applicationInfo = packageInfo.applicationInfo,
                )
            } else {
                val manifest = readManifest(apkPath)
                    ?: return ApkInfo.Invalid(
                        EngineErrorCodes.APK_INVALID,
                        "One of the selected files is not a valid APK manifest.",
                    )
                archives += Archive(
                    path = apkPath,
                    packageName = manifest.packageName,
                    versionName = manifest.versionName,
                    versionCode = manifest.versionCode,
                    splitName = manifest.splitName,
                    applicationInfo = null,
                )
            }
        }

        val packageName = archives.first().packageName
        if (archives.any { it.packageName != packageName }) {
            return ApkInfo.Invalid(
                EngineErrorCodes.APK_PACKAGE_MISMATCH,
                "All selected APKs must belong to the same application.",
            )
        }
        val bases = archives.filter { it.splitName == null }
        if (bases.size != 1) {
            return ApkInfo.Invalid(
                EngineErrorCodes.APK_BASE_REQUIRED,
                "Select exactly one base APK and one or more configuration splits.",
            )
        }
        val splits = archives.filter { it.splitName != null }
        val versionCode = bases.single().versionCode
            ?: return ApkInfo.Invalid(
                EngineErrorCodes.APK_INVALID,
                "The base APK does not declare a version.",
            )
        // Standalone split manifests normally omit versionCode/versionName; those values
        // belong to the base manifest. Only reject a split when it explicitly identifies a
        // different version.
        if (archives.any { it.versionCode != null && it.versionCode != versionCode }) {
            return ApkInfo.Invalid(
                EngineErrorCodes.APK_VERSION_MISMATCH,
                "All selected APKs must have the same version.",
            )
        }
        val splitNames = splits.mapNotNull { it.splitName }
        if (splitNames.size != splitNames.toSet().size) {
            return ApkInfo.Invalid(
                EngineErrorCodes.APK_DUPLICATE_SPLIT,
                "Duplicate APK splits were selected.",
            )
        }

        val base = bases.single()
        val applicationInfo = base.applicationInfo
            ?: return ApkInfo.Invalid(
                EngineErrorCodes.APK_INVALID,
                "The base APK does not declare an application.",
            )
        applicationInfo.sourceDir = base.path
        applicationInfo.publicSourceDir = base.path
        val label = runCatching {
            context.packageManager.getApplicationLabel(applicationInfo).toString()
        }.getOrDefault(packageName)

        return ApkInfo.Parsed(
            packageName = packageName,
            appName = label,
            versionName = base.versionName,
            versionCode = versionCode,
            apkPaths = archives.map { it.path },
            baseApkPath = base.path,
            splitApkPaths = splits.map { it.path },
        )
    }

    private fun longVersionCode(info: android.content.pm.PackageInfo): Long =
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }

    private data class ManifestInfo(
        val packageName: String,
        val splitName: String?,
        val versionName: String?,
        val versionCode: Long?,
    )

    /** PackageManager rejects a standalone split archive; read its manifest identity only. */
    private fun readManifest(path: String): ManifestInfo? = runCatching {
        val constructor = AssetManager::class.java.getDeclaredConstructor()
        constructor.isAccessible = true
        val assets = constructor.newInstance()
        val addAssetPath = AssetManager::class.java
            .getDeclaredMethod("addAssetPath", String::class.java)
        addAssetPath.isAccessible = true
        val cookie = addAssetPath.invoke(assets, path) as Int
        if (cookie == 0) return@runCatching null
        val parser = assets.openXmlResourceParser(cookie, "AndroidManifest.xml")
        var result: ManifestInfo? = null
        while (parser.next() != org.xmlpull.v1.XmlPullParser.END_DOCUMENT) {
            if (parser.eventType == org.xmlpull.v1.XmlPullParser.START_TAG && parser.name == "manifest") {
                val ns = "http://schemas.android.com/apk/res/android"
                result = ManifestInfo(
                    packageName = parser.getAttributeValue(null, "package")
                        ?: return@runCatching null,
                    splitName = parser.getAttributeValue(null, "split")
                        ?: parser.getAttributeValue(ns, "split"),
                    versionName = parser.getAttributeValue(ns, "versionName"),
                    versionCode = parser.getAttributeValue(ns, "versionCode")?.let {
                        parser.getAttributeIntValue(ns, "versionCode", -1).toLong()
                    },
                )
                break
            }
        }
        parser.close()
        assets.close()
        result
    }.getOrNull()

    fun isInstalledOnHost(packageName: String): Boolean = try {
        context.packageManager.getPackageInfo(packageName, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }
}
