package co.tdevs.duplika.native

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.PermissionInfo
import android.os.Build
import android.os.Environment

/**
 * Works out, before anything is cloned, whether a target app can be hosted at all.
 *
 * This layer does not make incompatible apps work. It exists so an app the engine cannot
 * run — one that ships no ABI the engine can load, a system component, an app that demands
 * a secure environment — is refused up front instead of failing mysteriously after the
 * user has already created a clone.
 *
 * What it deliberately does **not** report is how well a clone will work once it runs.
 * Findings about Google Play services and push were removed: they described the container
 * to the user, and nothing about the engine behind a clone is shown to them.
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
        val packageInfo = installedPackageInfo(packageName)
            ?: return Report(
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

        val abi = packageInfo.applicationInfo?.let(::detectAbi)
        val findings = findingsFor(packageName, packageInfo, abi)

        return Report(
            packageName = packageName,
            verdict = verdictOf(findings),
            // Still computed -- the action sheet uses it to decide whether to offer the
            // Google services install -- but no longer reported as a finding: what a clone
            // can and cannot do with Google's services is not something the user is shown.
            requiresGms = requiresGooglePlayServices(packageName, packageInfo),
            findings = findings,
            abi = abi,
        )
    }

    /**
     * Whether a clone of this package could be created at all.
     *
     * The picker's filter, and the reason it is not simply `analyze().verdict`: that call
     * also resolves the app's Google-services dependency, which costs a second metadata
     * read of every package on the device and answers a question a listing never asks.
     *
     * It shares [findingsFor] with [analyze] rather than restating the rules, so the list
     * cannot come to disagree with the verdict shown when a row is opened.
     */
    fun canClone(packageName: String): Boolean {
        val packageInfo = installedPackageInfo(packageName) ?: return false
        return canClone(packageInfo)
    }

    /**
     * The same verdict for a package the caller has already read.
     *
     * A listing asks this of every launchable package, and reading each one's
     * [PackageInfo] a second time here doubled the PackageManager round trips behind the
     * picker for nothing. The record must have been read with [PackageManager.GET_PERMISSIONS]
     * — [findingsFor] judges the storage declarations, and a record fetched without that
     * flag reports no permissions rather than none declared, which would silently drop a
     * finding. Callers with only a package name should use the overload above, which
     * fetches it correctly.
     */
    fun canClone(packageInfo: PackageInfo): Boolean {
        val abi = packageInfo.applicationInfo?.let(::detectAbi)
        return findingsFor(packageInfo.packageName, packageInfo, abi).none { it.blocking }
    }

    /** Reads a package with every flag [findingsFor] needs. */
    fun installedPackageInfo(packageName: String): PackageInfo? = try {
        context.packageManager.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)
    } catch (_: PackageManager.NameNotFoundException) {
        null
    }

    /** Everything known to stand in the way of hosting an installed package. */
    private fun findingsFor(
        packageName: String,
        packageInfo: PackageInfo,
        abi: String?,
    ): List<Finding> {
        val findings = mutableListOf<Finding>()

        (securityChecker.check(packageName) as? AppSecurityChecker.Verdict.Rejected)?.let {
            findings += Finding(it.code, it.message, blocking = true)
        }

        val applicationInfo = packageInfo.applicationInfo
        if (applicationInfo != null && hasNativeCode(applicationInfo) && abi == null) {
            findings += Finding(
                EngineErrorCodes.ABI_NOT_SUPPORTED,
                "This app's native libraries are not built for an architecture the engine supports.",
                blocking = true,
            )
        }

        storageFinding(packageInfo.requestedPermissions?.toSet().orEmpty())?.let {
            findings += it
        }

        return findings
    }

    private fun verdictOf(findings: List<Finding>): Verdict = when {
        findings.any { it.blocking } -> Verdict.UNSUPPORTED
        findings.isNotEmpty() -> Verdict.LIMITED
        else -> Verdict.SUPPORTED
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

        storageFinding(requested)?.let { findings += it }

        return Report(
            packageName = packageName,
            verdict = verdictOf(findings),
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
            engineAbiOf(
                zip.entries().asSequence()
                    .map { it.name }
                    .filter { it.startsWith("lib/") }
                    .mapNotNull { it.split('/').getOrNull(1) }
                    .toSet(),
            )
        }
    } catch (error: Exception) {
        Slog.w(Slog.INSTALL, "Could not read ABIs from $apkPath: ${error.message}")
        null
    }

    /**
     * The dangerous permissions an installed app declares, sorted.
     *
     * The per-clone permission control offers exactly these. Returns an empty list for a
     * package that is not installed (an imported-APK clone) — there is no manifest to read.
     */
    fun declaredDangerousPermissions(packageName: String): List<String> {
        val requested = try {
            context.packageManager
                .getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)
                .requestedPermissions
                ?.toSet()
                .orEmpty()
        } catch (_: PackageManager.NameNotFoundException) {
            return emptyList()
        }
        return requested.filter(::isDangerous).sorted()
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
     * The `MANAGE_EXTERNAL_STORAGE` fallback, and the honest answer when it cannot be used.
     *
     * Guests run under the host's identity, so a guest that touches shared storage can only
     * reach it if **Duplika** holds All files access. That permission is special-access: the
     * user grants it in Settings, never through a runtime dialog, so the app cannot ask for
     * it and must instead say what is wrong. The decision itself is
     * [storageFindingFor] — a pure function, so it is unit-tested without a device.
     */
    private fun storageFinding(requestedPermissions: Set<String>): Finding? =
        storageFindingFor(
            requestedPermissions = requestedPermissions,
            hostDeclaresAllFilesAccess = hostDeclaresAllFilesAccess,
            hostHoldsAllFilesAccess = hostHoldsAllFilesAccess(),
        )

    /**
     * Cached: this is a fact about Duplika's own manifest, so it cannot change while the
     * process lives. The picker analyses every launchable app to decide what to list, and
     * re-reading the host's own permission set once per app was the one part of that pass
     * that scaled with the number of apps for no reason.
     *
     * Deliberately not paired with a cache for [hostHoldsAllFilesAccess]: that one is a
     * runtime grant the user can change in Settings while Duplika is running, and a stale
     * answer there would be wrong rather than merely slow.
     */
    private val hostDeclaresAllFilesAccess: Boolean by lazy {
        try {
            context.packageManager
                .getPackageInfo(context.packageName, PackageManager.GET_PERMISSIONS)
                .requestedPermissions
                ?.contains(ALL_FILES_ACCESS) == true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun hostHoldsAllFilesAccess(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            // All files access is an API 30+ concept. Before Android 11 the legacy storage
            // grant is what matters and the engine's app-op check does not apply.
            true
        }

    private fun hasNativeCode(info: ApplicationInfo): Boolean =
        !info.nativeLibraryDir.isNullOrEmpty() && java.io.File(info.nativeLibraryDir).let {
            it.isDirectory && (it.list()?.isNotEmpty() == true)
        }

    /**
     * Derived from `nativeLibraryDir` (a public field) rather than the hidden
     * `primaryCpuAbi`, so no hidden API is touched.
     */
    private fun detectAbi(info: ApplicationInfo): String? =
        engineAbiForLibraryDir(info.nativeLibraryDir)

    companion object {
        const val CODE_STORAGE_UNAVAILABLE = "STORAGE_UNAVAILABLE"
        const val CODE_STORAGE_NOT_GRANTED = "STORAGE_NOT_GRANTED"

        private const val ALL_FILES_ACCESS = "android.permission.MANAGE_EXTERNAL_STORAGE"

        /**
         * Broad shared-storage declarations. A guest that asks for one of these wants the
         * whole shared tree, which only exists for it when the host holds All files access.
         * `READ_MEDIA_*` is deliberately absent: it is media-scoped, and an app that declares
         * only those reaches media through MediaStore, which does not need this.
         */
        private val STORAGE_PERMISSIONS = setOf(
            "android.permission.READ_EXTERNAL_STORAGE",
            "android.permission.WRITE_EXTERNAL_STORAGE",
            ALL_FILES_ACCESS,
        )

        private const val STORAGE_UNAVAILABLE_MESSAGE =
            "This app uses shared storage, and this build of Duplika does not declare All " +
                "files access. A clone of it cannot reach your files and will not work."

        private const val STORAGE_NOT_GRANTED_MESSAGE =
            "This app uses shared storage. Grant Duplika \"All files access\" in Settings → " +
                "Special app access before launching the clone, or it may be refused at launch."

        /**
         * The pure half of the storage fallback, with every Android lookup passed in.
         *
         * Two cases, and they are different: the host does not declare All files access at
         * all (the Play-rejection fallback — blocking, because no clone can ever reach shared
         * storage), versus the host declares it but the user has not granted it yet
         * (non-blocking, with the Settings path).
         */
        @JvmStatic
        internal fun storageFindingFor(
            requestedPermissions: Set<String>,
            hostDeclaresAllFilesAccess: Boolean,
            hostHoldsAllFilesAccess: Boolean,
        ): Finding? {
            if (STORAGE_PERMISSIONS.none { it in requestedPermissions }) {
                return null
            }
            return when {
                !hostDeclaresAllFilesAccess -> Finding(
                    CODE_STORAGE_UNAVAILABLE,
                    STORAGE_UNAVAILABLE_MESSAGE,
                    blocking = true,
                )

                !hostHoldsAllFilesAccess -> Finding(
                    CODE_STORAGE_NOT_GRANTED,
                    STORAGE_NOT_GRANTED_MESSAGE,
                    blocking = false,
                )

                else -> null
            }
        }

        /**
         * The engine-loadable ABI for a set of `lib/` directory names.
         *
         * Three outcomes, and the difference between the last two is what the ABI finding
         * turns on: null for an archive with no native code at all (pure bytecode, which
         * runs anywhere), [UNSUPPORTED_ABI] for one that ships native code the engine
         * cannot load, and the ABI itself otherwise.
         *
         * Split out as a pure function for the same reason as [storageFindingFor]: it is
         * a decision worth testing, and reaching it through a real archive on a real
         * device is not.
         */
        @JvmStatic
        internal fun engineAbiOf(abiDirectories: Set<String>): String? = when {
            abiDirectories.isEmpty() -> null
            else -> abiDirectories.firstOrNull { it in ENGINE_ABIS } ?: UNSUPPORTED_ABI
        }

        /**
         * The engine-loadable ABI an installed package's `nativeLibraryDir` implies.
         *
         * Android names the directory after the ABI family rather than the ABI, so the
         * two names it can end in are mapped back. Null covers both "no native code" and
         * "an ABI this engine does not load" — the caller separates them with
         * `hasNativeCode`, which asks whether the directory has anything in it.
         */
        @JvmStatic
        internal fun engineAbiForLibraryDir(nativeLibraryDir: String?): String? {
            return when (nativeLibraryDir?.substringAfterLast('/')) {
                "arm64" -> "arm64-v8a".takeIf { it in ENGINE_ABIS }
                "arm" -> "armeabi-v7a".takeIf { it in ENGINE_ABIS }
                else -> null
            }
        }

        internal val ENGINE_ABIS = setOf("arm64-v8a", "armeabi-v7a")

        private const val GMS_VERSION_META = "com.google.android.gms.version"
        internal const val UNSUPPORTED_ABI = "unsupported"

        private val GMS_PERMISSION_MARKERS = setOf(
            "com.google.android.c2dm.permission.RECEIVE",
            "com.google.android.providers.gsf.permission.READ_GSERVICES",
            "com.google.android.finsky.permission.BIND_GET_INSTALL_REFERRER_SERVICE",
        )
    }
}
