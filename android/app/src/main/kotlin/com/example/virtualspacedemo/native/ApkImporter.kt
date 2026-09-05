package com.example.virtualspacedemo.native

import android.content.Context
import android.content.pm.PackageManager
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
        ) : ApkInfo

        data class Invalid(val code: String, val message: String) : ApkInfo
    }

    fun inspect(apkPath: String): ApkInfo {
        val file = File(apkPath)
        if (!file.isFile || !file.canRead()) {
            return ApkInfo.Invalid(
                EngineErrorCodes.APK_UNREADABLE,
                "The selected file could not be read.",
            )
        }

        val packageInfo = context.packageManager.getPackageArchiveInfo(apkPath, 0)
            ?: return ApkInfo.Invalid(
                EngineErrorCodes.APK_INVALID,
                "The selected file is not a valid APK.",
            )

        val applicationInfo = packageInfo.applicationInfo
            ?: return ApkInfo.Invalid(
                EngineErrorCodes.APK_INVALID,
                "The APK does not declare an application.",
            )

        // An archive's ApplicationInfo has no paths set, so the label cannot be resolved
        // until they are pointed at the file itself.
        applicationInfo.sourceDir = apkPath
        applicationInfo.publicSourceDir = apkPath

        val label = runCatching {
            context.packageManager.getApplicationLabel(applicationInfo).toString()
        }.getOrDefault(packageInfo.packageName)

        return ApkInfo.Parsed(
            packageName = packageInfo.packageName,
            appName = label,
            versionName = packageInfo.versionName,
            versionCode = longVersionCode(packageInfo),
        )
    }

    private fun longVersionCode(info: android.content.pm.PackageInfo): Long =
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }

    fun isInstalledOnHost(packageName: String): Boolean = try {
        context.packageManager.getPackageInfo(packageName, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }
}
