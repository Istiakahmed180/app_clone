package co.tdevs.duplika.native

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.PermissionInfo
import android.os.Build

/**
 * Works out, before anything is cloned, what will and will not work for a target app —
 * and says so plainly.
 *
 * This layer does not make incompatible apps work. It exists so Duplika stops
 * pretending every app is equally supported: an app that needs Google Play Services, or
 * ships no ABI the engine can load, is reported as such instead of failing mysteriously
 * after the user has already created a clone.
 */
class AppCompatibilityAnalyzer(private val context: Context) {

    enum class Verdict { SUPPORTED, LIMITED, UNSUPPORTED }

    data class Finding(val code: String, val message: String, val blocking: Boolean)

    data class Report(
        val packageName: String,
        val verdict: Verdict,
        val findings: List<Finding>,
        /** Dangerous permissions the guest declares that the host is able to hold. */
        val bridgeablePermissions: List<String>,
        /** Of those, the ones the host has not been granted yet. */
        val missingPermissions: List<String>,
        val requiresGms: Boolean,
        val abi: String?,
    ) {
        fun toMap(): Map<String, Any?> = mapOf(
            "packageName" to packageName,
            "verdict" to verdict.name,
            "findings" to findings.map {
                mapOf("code" to it.code, "message" to it.message, "blocking" to it.blocking)
            },
            "bridgeablePermissions" to bridgeablePermissions,
            "missingPermissions" to missingPermissions,
            "requiresGms" to requiresGms,
            "abi" to abi,
        )
    }

    private val securityChecker = AppSecurityChecker(context)

    fun analyze(packageName: String): Report {
        val findings = mutableListOf<Finding>()

        val packageInfo = try {
            context.packageManager.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)
        } catch (_: PackageManager.NameNotFoundException) {
            return Report(
                packageName = packageName,
                verdict = Verdict.UNSUPPORTED,
                findings = listOf(
                    Finding(
                        EngineErrorCodes.APP_NOT_FOUND,
                        "This application is not installed on the device.",
                        blocking = true,
                    ),
                ),
                bridgeablePermissions = emptyList(),
                missingPermissions = emptyList(),
                requiresGms = false,
                abi = null,
            )
        }

        (securityChecker.check(packageName) as? AppSecurityChecker.Verdict.Rejected)?.let {
            findings += Finding(it.code, it.message, blocking = true)
        }

        val applicationInfo = packageInfo.applicationInfo
        val abi = applicationInfo?.let(::detectAbi)

        if (applicationInfo != null && hasNativeCode(applicationInfo) && abi == null) {
            findings += Finding(
                EngineErrorCodes.ABI_NOT_SUPPORTED,
                "This app's native libraries are not built for an architecture the engine supports.",
                blocking = true,
            )
        }

        val requiresGms = requiresGooglePlayServices(packageName, packageInfo)
        if (requiresGms) {
            findings += Finding(
                CODE_REQUIRES_GMS,
                "This app relies on Google Play Services, which is not virtualized in this build. " +
                    "Sign-in, push notifications and maps are likely to fail.",
                blocking = false,
            )
        }

        val bridgeable = bridgeablePermissions(packageInfo)
        val missing = bridgeable.filterNot(::isGrantedToHost)
        if (missing.isNotEmpty()) {
            findings += Finding(
                CODE_PERMISSIONS_REQUIRED,
                "The clone needs ${missing.size} permission(s) that Duplika does not hold yet. " +
                    "Guests run under the host's identity, so the host must be granted them.",
                blocking = false,
            )
        }

        val verdict = when {
            findings.any { it.blocking } -> Verdict.UNSUPPORTED
            findings.isNotEmpty() -> Verdict.LIMITED
            else -> Verdict.SUPPORTED
        }

        return Report(
            packageName = packageName,
            verdict = verdict,
            findings = findings,
            bridgeablePermissions = bridgeable,
            missingPermissions = missing,
            requiresGms = requiresGms,
            abi = abi,
        )
    }

    /**
     * Analyses a standalone APK, without needing it to be installed.
     *
     * The import flow previously had nothing to inspect for an APK that is not installed
     * here, and presented it as "Supported / no known problems" — an overclaim about
     * something never examined. Everything below is read out of the archive itself.
     */
    fun analyzeApk(apkPath: String, packageName: String): Report {
        val findings = mutableListOf<Finding>()

        (securityChecker.checkApk(packageName, apkPath) as? AppSecurityChecker.Verdict.Rejected)
            ?.let { findings += Finding(it.code, it.message, blocking = true) }

        val abi = archiveAbi(apkPath)
        if (abi == UNSUPPORTED_ABI) {
            findings += Finding(
                EngineErrorCodes.ABI_NOT_SUPPORTED,
                "This APK's native libraries are not built for an architecture the engine supports.",
                blocking = true,
            )
        }

        val archive = try {
            context.packageManager.getPackageArchiveInfo(apkPath, PackageManager.GET_PERMISSIONS)
        } catch (_: Exception) {
            null
        }

        val requested = archive?.requestedPermissions?.toSet().orEmpty()
        val requiresGms = GMS_PERMISSION_MARKERS.any { it in requested } ||
            ApkManifestReader.readDeclarations(apkPath)
                .any { it.element == "meta-data" && it.name == GMS_VERSION_META }

        if (requiresGms) {
            findings += Finding(
                CODE_REQUIRES_GMS,
                "This app relies on Google Play Services, which is not virtualized in this build. " +
                    "Sign-in, push notifications and maps are likely to fail.",
                blocking = false,
            )
        }

        val hostDeclared = hostDeclaredPermissions()
        val bridgeable = requested.filter { it in hostDeclared }.filter(::isDangerous).sorted()
        val missing = bridgeable.filterNot(::isGrantedToHost)
        if (missing.isNotEmpty()) {
            findings += Finding(
                CODE_PERMISSIONS_REQUIRED,
                "The clone needs ${missing.size} permission(s) that Duplika does not hold yet. " +
                    "Guests run under the host's identity, so the host must be granted them.",
                blocking = false,
            )
        }

        return Report(
            packageName = packageName,
            verdict = when {
                findings.any { it.blocking } -> Verdict.UNSUPPORTED
                findings.isNotEmpty() -> Verdict.LIMITED
                else -> Verdict.SUPPORTED
            },
            findings = findings,
            bridgeablePermissions = bridgeable,
            missingPermissions = missing,
            requiresGms = requiresGms,
            abi = abi.takeIf { it != UNSUPPORTED_ABI },
        )
    }

    /**
     * The engine-loadable ABI an archive ships, [UNSUPPORTED_ABI] when it carries native
     * code for none, or null when it carries no native code at all.
     */
    private fun archiveAbi(apkPath: String): String? = try {
        java.util.zip.ZipFile(java.io.File(apkPath)).use { zip ->
            val abis = zip.entries().asSequence()
                .map { it.name }
                .filter { it.startsWith("lib/") }
                .mapNotNull { it.split('/').getOrNull(1) }
                .toSet()

            when {
                abis.isEmpty() -> null
                else -> abis.firstOrNull { it in ENGINE_ABIS } ?: UNSUPPORTED_ABI
            }
        }
    } catch (error: Exception) {
        Slog.w(Slog.INSTALL, "Could not read ABIs from $apkPath: ${error.message}")
        null
    }

    /**
     * Permissions worth bridging: dangerous ones the guest asks for that the host is also
     * able to hold. The host cannot be granted a permission it does not declare, and the
     * engine's merged manifest is what makes most of them declarable.
     */
    private fun bridgeablePermissions(guest: PackageInfo): List<String> {
        val requested = guest.requestedPermissions?.toSet() ?: return emptyList()
        val hostDeclared = hostDeclaredPermissions()

        return requested
            .filter { it in hostDeclared }
            .filter(::isDangerous)
            .sorted()
    }

    private fun hostDeclaredPermissions(): Set<String> = try {
        context.packageManager
            .getPackageInfo(context.packageName, PackageManager.GET_PERMISSIONS)
            .requestedPermissions
            ?.toSet()
            .orEmpty()
    } catch (_: PackageManager.NameNotFoundException) {
        emptySet()
    }

    private fun isDangerous(permission: String): Boolean = try {
        val info = context.packageManager.getPermissionInfo(permission, 0)
        val level = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.protection
        } else {
            @Suppress("DEPRECATION")
            info.protectionLevel and PermissionInfo.PROTECTION_MASK_BASE
        }
        level == PermissionInfo.PROTECTION_DANGEROUS
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    fun isGrantedToHost(permission: String): Boolean =
        context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    /**
     * GMS dependency is inferred from the markers Play apps conventionally declare. This
     * is a heuristic: it can miss an app that reaches GMS without declaring any of them.
     */
    private fun requiresGooglePlayServices(packageName: String, info: PackageInfo): Boolean {
        val requested = info.requestedPermissions?.toSet().orEmpty()
        if (GMS_PERMISSION_MARKERS.any { it in requested }) {
            return true
        }

        return try {
            val meta = context.packageManager
                .getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                .metaData
            meta?.containsKey("com.google.android.gms.version") == true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun hasNativeCode(info: ApplicationInfo): Boolean =
        !info.nativeLibraryDir.isNullOrEmpty() && java.io.File(info.nativeLibraryDir).let {
            it.isDirectory && (it.list()?.isNotEmpty() == true)
        }

    /**
     * Derived from `nativeLibraryDir` (a public field) rather than the hidden
     * `primaryCpuAbi`, so no hidden API is touched.
     */
    private fun detectAbi(info: ApplicationInfo): String? {
        val dir = info.nativeLibraryDir?.substringAfterLast('/') ?: return null
        return when (dir) {
            "arm64" -> "arm64-v8a".takeIf { it in ENGINE_ABIS }
            "arm" -> "armeabi-v7a".takeIf { it in ENGINE_ABIS }
            else -> null
        }
    }

    companion object {
        const val CODE_REQUIRES_GMS = "REQUIRES_GMS"
        const val CODE_PERMISSIONS_REQUIRED = "PERMISSIONS_REQUIRED"

        private val ENGINE_ABIS = setOf("arm64-v8a", "armeabi-v7a")

        private const val GMS_VERSION_META = "com.google.android.gms.version"
        private const val UNSUPPORTED_ABI = "unsupported"

        private val GMS_PERMISSION_MARKERS = setOf(
            "com.google.android.c2dm.permission.RECEIVE",
            "com.google.android.providers.gsf.permission.READ_GSERVICES",
            "com.google.android.finsky.permission.BIND_GET_INSTALL_REFERRER_SERVICE",
        )
    }
}
