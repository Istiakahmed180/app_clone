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

    /**
     * The facts about *this device and this build* that every verdict is measured against.
     *
     * Read once and carried, rather than looked up per app. A listing analyses every
     * launchable package on the device, and each of these was costing a platform call on
     * each of them — the All files grant, and one property query per candidate property
     * name. None of them can change while a single listing pass runs.
     *
     * Deliberately not cached across passes: the All files grant is one the user can change
     * in Settings while Duplika is running, and a stale answer there would be wrong rather
     * than merely slow. Every pass builds a fresh one — [hostState] for a single app,
     * [listingHostState] for a pass over all of them.
     */
    class HostState internal constructor(
        internal val hostDeclaresAllFilesAccess: Boolean,
        internal val hostHoldsAllFilesAccess: Boolean,
        internal val loadableAbis: Set<String>,
        /**
         * Every package that declares a secure-environment property, or null where the
         * platform cannot be asked that question in one go (below API 31) and each package
         * must be queried on its own.
         */
        internal val secureEnvironmentDeclarers: Set<String>?,
    )

    private val securityChecker = AppSecurityChecker(context)

    /**
     * The device and build facts as they stand right now, for judging a single app.
     *
     * No declarer set: gathering one asks the platform for every package on the device
     * that declares each candidate property, which is a bargain across a whole listing and
     * a waste for one app that can be asked about directly. [listingHostState] is the
     * other half of that trade.
     */
    fun hostState(): HostState = hostState(declarers = null)

    /**
     * The same facts for a pass that will judge every launchable app on the device.
     *
     * Worth the device-wide property query exactly once here: it replaces one query per
     * candidate property per app, which was the listing's largest cost.
     */
    fun listingHostState(): HostState =
        hostState(declarers = securityChecker.secureEnvironmentDeclarers())

    /**
     * The two above differ in one field, and are built here so they cannot come to differ
     * in another: a fact added for one pass and forgotten for the other would be a verdict
     * that quietly depends on which route asked for it.
     */
    private fun hostState(declarers: Set<String>?): HostState = HostState(
        hostDeclaresAllFilesAccess = hostDeclaresAllFilesAccess,
        hostHoldsAllFilesAccess = hostHoldsAllFilesAccess(),
        loadableAbis = ApkAbis.loadable(Build.SUPPORTED_ABIS?.asList().orEmpty()),
        secureEnvironmentDeclarers = declarers,
    )

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

        val host = hostState()
        val abi = abiOf(packageInfo.applicationInfo, host)
        val findings = findingsFor(packageInfo, abi, host)

        return Report(
            packageName = packageName,
            verdict = verdictOf(findings),
            // Still computed -- the action sheet uses it to decide whether to offer the
            // Google services install -- but no longer reported as a finding: what a clone
            // can and cannot do with Google's services is not something the user is shown.
            requiresGms = requiresGooglePlayServices(packageName, packageInfo),
            findings = findings,
            abi = abi.takeIf { it != UNSUPPORTED_ABI },
        )
    }

    /**
     * Whether a clone of this package could be created at all.
     *
     * The picker's filter, and the one question a listing has: whether to show the row.
     * It stops at the first blocking finding's existence rather than building the whole
     * [Report] that [analyze] returns, which also resolves the app's Google-services
     * dependency — a question a listing never asks.
     *
     * It shares [findingsFor] with [analyze] rather than restating the rules, so the list
     * cannot come to disagree with the verdict shown when a row is opened.
     */
    fun canClone(packageName: String): Boolean {
        val packageInfo = installedPackageInfo(packageName) ?: return false
        return canClone(packageInfo, hostState())
    }

    /**
     * The same verdict for a package the caller has already read.
     *
     * A listing asks this of every launchable package, so everything it would otherwise
     * repeat is passed in: the record (read by [installedPackageInfo], whose flags
     * [findingsFor] depends on), the device facts, and the app's ABIs, which the listing
     * needs for its own architecture filter and would otherwise read out of the archives
     * twice.
     */
    fun canClone(
        packageInfo: PackageInfo,
        host: HostState,
        abis: Set<String> = packageInfo.applicationInfo?.let(ApkAbis::of).orEmpty(),
    ): Boolean = findingsFor(packageInfo, engineAbiOf(abis, host.loadableAbis), host)
        .none { it.blocking }

    /**
     * Reads a package with every flag [findingsFor] needs.
     *
     * `GET_PERMISSIONS` for the storage declarations, and `GET_META_DATA` so the
     * secure-environment check can read the app's meta-data off this record instead of
     * fetching the package a second time for it.
     */
    fun installedPackageInfo(packageName: String): PackageInfo? = try {
        context.packageManager.getPackageInfo(
            packageName,
            PackageManager.GET_PERMISSIONS or PackageManager.GET_META_DATA,
        )
    } catch (_: PackageManager.NameNotFoundException) {
        null
    }

    /** Everything known to stand in the way of hosting an installed package. */
    private fun findingsFor(
        packageInfo: PackageInfo,
        abi: String?,
        host: HostState,
    ): List<Finding> {
        val findings = mutableListOf<Finding>()

        val rejection = securityChecker.check(packageInfo, host.secureEnvironmentDeclarers)
        (rejection as? AppSecurityChecker.Verdict.Rejected)?.let {
            findings += Finding(it.code, it.message, blocking = true)
        }

        if (abi == UNSUPPORTED_ABI) {
            findings += Finding(
                EngineErrorCodes.ABI_NOT_SUPPORTED,
                "This app's native libraries are not built for an architecture the engine supports.",
                blocking = true,
            )
        }

        storageFinding(packageInfo.requestedPermissions?.toSet().orEmpty(), host)?.let {
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
     * Analyses a standalone APK, or a split set, without needing it to be installed.
     *
     * The import flow previously had nothing to inspect for an APK that is not installed
     * here, and presented it as "Supported / no known problems" — an overclaim about
     * something never examined. Everything below is read out of the archives themselves.
     *
     * [apkPaths] is the whole set, base first. Only the ABI question needs more than the
     * base: an app bundle puts its native code in a `config.<abi>` split, so reading the
     * base alone found no `lib/` at all and called every split import pure bytecode —
     * which is the ABI check not running rather than passing. The manifest questions —
     * permissions, secure environment, the Google-services marker — are the base's to
     * answer, and are still asked of it alone.
     */
    fun analyzeApk(apkPaths: List<String>, packageName: String): Report {
        val apkPath = apkPaths.first()
        val host = hostState()
        val findings = mutableListOf<Finding>()

        (securityChecker.checkApk(packageName, apkPath) as? AppSecurityChecker.Verdict.Rejected)
            ?.let { findings += Finding(it.code, it.message, blocking = true) }

        val abi = engineAbiOf(ApkAbis.ofArchives(apkPaths), host.loadableAbis)
        if (abi == UNSUPPORTED_ABI) {
            findings += Finding(
                EngineErrorCodes.ABI_NOT_SUPPORTED,
                "This app's native libraries are not built for an architecture the engine supports.",
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

        storageFinding(requested, host)?.let { findings += it }

        return Report(
            packageName = packageName,
            verdict = verdictOf(findings),
            findings = findings,
            requiresGms = requiresGms,
            abi = abi.takeIf { it != UNSUPPORTED_ABI },
        )
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
        // Read off the record rather than fetched again: [installedPackageInfo] already
        // asks for GET_META_DATA.
        return info.applicationInfo?.metaData?.containsKey(GMS_VERSION_META) == true
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
    private fun storageFinding(requestedPermissions: Set<String>, host: HostState): Finding? =
        storageFindingFor(
            requestedPermissions = requestedPermissions,
            hostDeclaresAllFilesAccess = host.hostDeclaresAllFilesAccess,
            hostHoldsAllFilesAccess = host.hostHoldsAllFilesAccess,
            deviceSdk = Build.VERSION.SDK_INT,
        )

    /**
     * Cached: this is a fact about Duplika's own manifest, so it cannot change while the
     * process lives.
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

    private fun abiOf(info: ApplicationInfo?, host: HostState): String? =
        info?.let { engineAbiOf(ApkAbis.of(it), host.loadableAbis) }

    companion object {
        const val CODE_STORAGE_UNAVAILABLE = "STORAGE_UNAVAILABLE"
        const val CODE_STORAGE_NOT_GRANTED = "STORAGE_NOT_GRANTED"

        private const val ALL_FILES_ACCESS = "android.permission.MANAGE_EXTERNAL_STORAGE"
        private const val READ_EXTERNAL_STORAGE = "android.permission.READ_EXTERNAL_STORAGE"
        private const val WRITE_EXTERNAL_STORAGE = "android.permission.WRITE_EXTERNAL_STORAGE"

        private const val STORAGE_UNAVAILABLE_MESSAGE =
            "This app uses shared storage, and this build of Duplika does not declare All " +
                "files access. A clone of it cannot reach your files and will not work."

        private const val STORAGE_NOT_GRANTED_MESSAGE =
            "This app uses shared storage. Grant Duplika \"All files access\" in Settings → " +
                "Special app access before launching the clone, or it may be refused at launch."

        /**
         * The declarations that still mean "this app wants the whole shared tree" *on this
         * device*, which is not a fixed set.
         *
         * Reading them as fixed was a false positive with a long reach. `requestedPermissions`
         * lists a manifest's declarations verbatim, `android:maxSdkVersion` and all, and the
         * overwhelmingly common legacy pattern — `WRITE_EXTERNAL_STORAGE` capped at API 28 —
         * is inert on every device sold in years. Counting it flagged a large share of
         * ordinary apps as storage-dependent, and in a build without All files access (the
         * Play-rejection fallback, where the finding turns blocking) it would have dropped
         * them from the picker entirely.
         *
         * So the set follows the platform:
         *  - From Android 13 the legacy pair is gone; media arrives through `READ_MEDIA_*`,
         *    which is media-scoped and needs nothing from the host.
         *  - From Android 11 `WRITE_EXTERNAL_STORAGE` grants nothing at all, while
         *    `READ_EXTERNAL_STORAGE` still reads the shared tree.
         *  - Below that, both are real.
         *
         * `READ_MEDIA_*` is absent throughout, for the reason it always was: it is
         * media-scoped and reaches its files through MediaStore.
         */
        @JvmStatic
        internal fun sharedStoragePermissionsFor(deviceSdk: Int): Set<String> = when {
            deviceSdk >= Build.VERSION_CODES.TIRAMISU -> setOf(ALL_FILES_ACCESS)
            deviceSdk >= Build.VERSION_CODES.R ->
                setOf(ALL_FILES_ACCESS, READ_EXTERNAL_STORAGE)
            else ->
                setOf(ALL_FILES_ACCESS, READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE)
        }

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
            deviceSdk: Int,
        ): Finding? {
            if (sharedStoragePermissionsFor(deviceSdk).none { it in requestedPermissions }) {
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
         * [loadable] is passed in rather than read from [ApkAbis.ENGINE] directly so that
         * the device's own architectures are part of the answer — see [ApkAbis.loadable] —
         * and so this stays a pure function, testable without a device.
         */
        @JvmStatic
        internal fun engineAbiOf(abiDirectories: Set<String>, loadable: Set<String>): String? =
            when {
                abiDirectories.isEmpty() -> null
                else -> abiDirectories.firstOrNull { it in loadable } ?: UNSUPPORTED_ABI
            }

        private const val GMS_VERSION_META = "com.google.android.gms.version"
        internal const val UNSUPPORTED_ABI = "unsupported"

        private val GMS_PERMISSION_MARKERS = setOf(
            "com.google.android.c2dm.permission.RECEIVE",
            "com.google.android.providers.gsf.permission.READ_GSERVICES",
            "com.google.android.finsky.permission.BIND_GET_INSTALL_REFERRER_SERVICE",
        )
    }
}
