package co.tdevs.duplika.native

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager

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
        val requiresGms: Boolean,
        val abi: String?,
    ) {
        fun toMap(): Map<String, Any?> = mapOf(
            "packageName" to packageName,
            "verdict" to verdict.name,
            "findings" to findings.map {
                mapOf("code" to it.code, "message" to it.message, "blocking" to it.blocking)
            },
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
                GMS_MESSAGE,
                blocking = false,
            )
        }

        if (usesPush(packageInfo.requestedPermissions?.toSet().orEmpty())) {
            findings += Finding(CODE_PUSH_UNSUPPORTED, PUSH_MESSAGE, blocking = false)
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
                GMS_MESSAGE,
                blocking = false,
            )
        }

        if (usesPush(requested)) {
            findings += Finding(CODE_PUSH_UNSUPPORTED, PUSH_MESSAGE, blocking = false)
        }

        return Report(
            packageName = packageName,
            verdict = when {
                findings.any { it.blocking } -> Verdict.UNSUPPORTED
                findings.isNotEmpty() -> Verdict.LIMITED
                else -> Verdict.SUPPORTED
            },
            findings = findings,
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

    /**
     * Whether the app uses Firebase Cloud Messaging / GCM push.
     *
     * The permission is the marker: an app cannot receive push without requesting
     * `com.google.android.c2dm.permission.RECEIVE`, and it is declared in the manifest, so
     * the same check works for an installed package and for an uninstalled archive.
     *
     * This is a subset of [GMS_PERMISSION_MARKERS] rather than a separate signal, and it is
     * reported separately on purpose: "sign-in may not work" and "notifications will never
     * arrive" are very different things to a user about to clone a messaging app.
     */
    private fun usesPush(requestedPermissions: Set<String>): Boolean =
        PUSH_PERMISSION in requestedPermissions

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
        const val CODE_PUSH_UNSUPPORTED = "PUSH_UNSUPPORTED"

        /**
         * Note what this no longer says: "other Google features are unaffected". Push is a
         * Google feature and it is affected, so that sentence was an overclaim once push was
         * measured. Push now has its own finding rather than being folded in here.
         */
        private const val GMS_MESSAGE =
            "Google Play services is available inside a clone, but Google features that must " +
                "verify this app's own identity are not supported — including sign-in and " +
                "identity-bound APIs such as location and SMS verification."

        /**
         * Measured, not predicted: `evidence/physical-android15/fcm-cabexfx/`. Play services
         * logs `GCM: Invalid caller: <package> <host uid>` and the client library surfaces
         * `SERVICE_NOT_AVAILABLE` about thirty seconds later. The delay is worth warning
         * about too — without it the clone simply looks like it has hung on first launch.
         */
        private const val PUSH_MESSAGE =
            "Push notifications will not work in a clone. Google Play services will not " +
                "register this app for push while it runs under Duplika's identity, so " +
                "messages sent to the clone never arrive. The app is otherwise usable, but " +
                "expect a pause on first launch while it waits for a push registration that " +
                "cannot succeed."

        private const val PUSH_PERMISSION = "com.google.android.c2dm.permission.RECEIVE"

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
