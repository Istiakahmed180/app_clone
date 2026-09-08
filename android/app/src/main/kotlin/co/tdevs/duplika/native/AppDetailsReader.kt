package co.tdevs.duplika.native

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.os.Build
import java.io.File
import java.security.MessageDigest
import java.util.zip.ZipFile

/**
 * Reads everything Duplika can say about one installed package's archive.
 *
 * Kept apart from [InstalledAppsProvider] because the cost is different in kind: this
 * opens every APK in the package and hashes its signing certificate, which is fine for
 * one app the user asked about and would be indefensible for all two hundred rows of the
 * picker.
 *
 * Only public PackageManager APIs and the archives' own zip directories are read. No
 * application's private data is touched.
 */
class AppDetailsReader(private val context: Context) {

    private val packageManager: PackageManager get() = context.packageManager

    fun read(packageName: String): Map<String, Any?>? {
        val info: PackageInfo = try {
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
        } catch (_: PackageManager.NameNotFoundException) {
            return null
        }
        val app: ApplicationInfo = info.applicationInfo ?: return null

        val components = componentsOf(app)
        val abis = components.flatMap {
            @Suppress("UNCHECKED_CAST")
            it["abis"] as List<String>
        }.distinct()

        return mapOf(
            "packageName" to packageName,
            "appName" to label(app),
            "versionName" to info.versionName,
            "versionCode" to versionCode(info),
            "abis" to abis,
            "apkCount" to components.size,
            "totalSizeBytes" to components.sumOf { it["sizeBytes"] as Long },
            "signingSha256" to signingSha256(info),
            "components" to components,
        )
    }

    /** Base APK first, then the splits in the order the installer recorded them. */
    private fun componentsOf(app: ApplicationInfo): List<Map<String, Any?>> {
        val out = ArrayList<Map<String, Any?>>()
        out.add(describeApk(app.sourceDir, isBase = true, splitName = null))

        val splitPaths = app.splitSourceDirs ?: return out
        // `splitNames` is index-aligned with `splitSourceDirs`, but a package can report
        // one and not the other; the name is decoration here, so a missing one is null
        // rather than a reason to give up on the file.
        val splitNames = app.splitNames
        for ((index, path) in splitPaths.withIndex()) {
            out.add(
                describeApk(
                    path = path,
                    isBase = false,
                    splitName = splitNames?.getOrNull(index),
                ),
            )
        }
        return out
    }

    private fun describeApk(path: String, isBase: Boolean, splitName: String?): Map<String, Any?> {
        val file = File(path)
        return mapOf(
            "name" to file.name,
            "path" to path,
            "isBase" to isBase,
            "splitName" to splitName,
            "abis" to abisIn(file),
            "sizeBytes" to (runCatching { file.length() }.getOrNull() ?: 0L),
        )
    }

    /**
     * The ABI directories this one archive carries native code for.
     *
     * Per file, not per package: which split holds `arm64-v8a` is the whole point of the
     * component list, and a package-wide answer would say the same thing on every row.
     */
    private fun abisIn(file: File): List<String> {
        val found = LinkedHashSet<String>()
        runCatching {
            ZipFile(file).use { zip ->
                val entries = zip.entries()
                while (entries.hasMoreElements()) {
                    val name = entries.nextElement().name
                    if (!name.startsWith(LIB_PREFIX)) {
                        continue
                    }
                    val abi = name.substring(LIB_PREFIX.length).substringBefore('/')
                    if (KNOWN_ABIS.contains(abi)) {
                        found.add(abi)
                        if (found.size == KNOWN_ABIS.size) {
                            return found.toList()
                        }
                    }
                }
            }
        }
        return found.toList()
    }

    @Suppress("DEPRECATION")
    private fun versionCode(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            info.versionCode.toLong()
        }

    /**
     * SHA-256 of the certificate the package is signed with, colon-grouped.
     *
     * The current signers, not the rotation history: this is here so a user can check an
     * archive they are about to share is the one they think it is, and the answer to that
     * is what signs it now. A package with several signers is reported as several hashes.
     */
    private fun signingSha256(info: PackageInfo): String? {
        val signatures: Array<Signature> = info.signingInfo?.let { signing ->
            if (signing.hasMultipleSigners()) {
                signing.apkContentsSigners
            } else {
                signing.signingCertificateHistory
            }
        } ?: return null

        val digest = MessageDigest.getInstance("SHA-256")
        return signatures
            .mapNotNull { signature ->
                runCatching {
                    digest.digest(signature.toByteArray())
                        .joinToString(":") { "%02X".format(it) }
                }.getOrNull()
            }
            .takeIf { it.isNotEmpty() }
            ?.joinToString("\n")
    }

    private fun label(info: ApplicationInfo): String =
        runCatching { packageManager.getApplicationLabel(info).toString() }
            .getOrDefault(info.packageName)

    private companion object {
        const val LIB_PREFIX = "lib/"
        val KNOWN_ABIS = setOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")
    }
}
