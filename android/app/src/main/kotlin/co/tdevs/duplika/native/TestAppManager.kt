package co.tdevs.duplika.native

import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build

/**
 * Read-only package metadata for the single controlled test application.
 *
 * The controlled app is `baseline_test_app/` in this repository, built as
 * [TEST_APP_PACKAGE]. Only the public PackageManager surface is used. This class never
 * touches another application's private storage.
 */
class TestAppManager(private val context: Context) {

    fun isTestAppInstalled(): Boolean = findPackageInfo() != null

    fun getTestAppInfo(): Map<String, Any?> {
        val info = findPackageInfo()
            ?: return mapOf(
                "installed" to false,
                "packageName" to TEST_APP_PACKAGE,
            )

        return mapOf(
            "installed" to true,
            "packageName" to TEST_APP_PACKAGE,
            "appName" to resolveAppName(info),
            "versionName" to info.versionName,
            "versionCode" to longVersionCode(info).toString(),
        )
    }

    fun getPlatformInfo(): Map<String, Any?> = mapOf(
        "androidVersion" to Build.VERSION.RELEASE,
        "sdkInt" to Build.VERSION.SDK_INT,
        "manufacturer" to Build.MANUFACTURER,
        "model" to Build.MODEL,
    )

    private fun findPackageInfo(): PackageInfo? = try {
        context.packageManager.getPackageInfo(TEST_APP_PACKAGE, 0)
    } catch (_: PackageManager.NameNotFoundException) {
        null
    }

    private fun resolveAppName(info: PackageInfo): String {
        val applicationInfo = info.applicationInfo ?: return TEST_APP_PACKAGE
        return context.packageManager.getApplicationLabel(applicationInfo).toString()
    }

    @Suppress("DEPRECATION")
    private fun longVersionCode(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) info.longVersionCode
        else info.versionCode.toLong()

    companion object {
        const val TEST_APP_PACKAGE = "com.example.duplikabaseline"
    }
}
