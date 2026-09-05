package com.example.virtualspacedemo.native

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build

/**
 * Decides whether a target application may be loaded into the virtual container.
 *
 * Google requires on-device Android containers to honour an application's request not to
 * be virtualized. Virtual Space treats that request as binding: a declaring application is
 * rejected, and there is deliberately no override, no manifest rewriting and no
 * environment spoofing to defeat it.
 *
 * The property is a Play-policy manifest declaration rather than a platform SDK constant
 * (it is absent from android.jar on API 35-37), so the candidate names below are checked
 * defensively. See docs/SECURITY.md.
 */
class AppSecurityChecker(private val context: Context) {

    sealed interface Verdict {
        data object Allowed : Verdict
        data class Rejected(val code: String, val message: String) : Verdict
    }

    fun check(packageName: String): Verdict {
        if (packageName != AllowList.TEST_APP) {
            return Verdict.Rejected(
                EngineErrorCodes.APP_NOT_SUPPORTED,
                "Phase 2 supports only the controlled Virtual Test App.",
            )
        }

        if (!isInstalled(packageName)) {
            return Verdict.Rejected(
                EngineErrorCodes.APP_NOT_FOUND,
                "The application is not installed on this device.",
            )
        }

        if (requiresSecureEnvironment(packageName)) {
            Slog.w(Slog.INSTALL, "$packageName declares a secure-environment requirement; rejecting")
            return Verdict.Rejected(
                EngineErrorCodes.SECURE_ENV_REQUIRED,
                "This application requires a secure environment and cannot be virtualized.",
            )
        }

        return Verdict.Allowed
    }

    /** Fail-closed: any positive declaration found through either mechanism rejects. */
    fun requiresSecureEnvironment(packageName: String): Boolean =
        declaredViaProperty(packageName) || declaredViaMetaData(packageName)

    private fun declaredViaProperty(packageName: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false

        return SECURE_ENV_PROPERTIES.any { name ->
            try {
                val property = context.packageManager.getProperty(name, packageName)
                property.isBoolean && property.boolean
            } catch (_: PackageManager.NameNotFoundException) {
                false
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun declaredViaMetaData(packageName: String): Boolean = try {
        val info = context.packageManager.getApplicationInfo(
            packageName,
            PackageManager.GET_META_DATA,
        )
        SECURE_ENV_PROPERTIES.any { info.metaData?.getBoolean(it, false) == true }
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    private fun isInstalled(packageName: String): Boolean = try {
        context.packageManager.getPackageInfo(packageName, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    object AllowList {
        const val TEST_APP = "com.example.virtualtestapp"
    }

    private companion object {
        val SECURE_ENV_PROPERTIES = listOf(
            "REQUIRE_SECURE_ENV",
            "android.content.pm.REQUIRE_SECURE_ENV",
            "android.app.REQUIRE_SECURE_ENV",
        )
    }
}
