package co.tdevs.duplika.native

import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle

/**
 * Decides whether a target application may be loaded into the virtual container.
 *
 * Google requires on-device Android containers to honour an application's request not to
 * be virtualized. Duplika treats that request as binding: a declaring application is
 * rejected, and there is deliberately no override, no manifest rewriting and no
 * environment spoofing to defeat it.
 *
 * The property is a Play-policy manifest declaration rather than a platform SDK constant
 * (it is absent from android.jar on API 35-37), so the candidate names below are checked
 * defensively.
 */
class AppSecurityChecker(private val context: Context) {

    sealed interface Verdict {
        data object Allowed : Verdict
        data class Rejected(val code: String, val message: String) : Verdict
    }

    /**
     * Admission check for an application already installed on this device.
     *
     * Phase 3 removed the single-package allow-list, so the policy is now a deny-list plus
     * the secure-environment rule. Nothing here weakens the Phase 2 guarantees: a target
     * that asks not to be virtualized is still rejected outright.
     */
    fun check(packageName: String): Verdict {
        blockedReason(packageName)?.let { return it }

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

    /**
     * Admission check for a record the caller has already read.
     *
     * A listing runs this over every launchable package, and the name-only [check] above
     * costs two platform calls on each of them that this one does not: the installed check
     * (the caller is holding the record, so the question is already answered), and the
     * meta-data fetch (read off [PackageInfo.applicationInfo], which requires the record to
     * have been read with `GET_META_DATA`). With [declarers] supplied, the property queries
     * go too — three more per package.
     *
     * [declarers] is the set of packages that declare a secure-environment *property*,
     * gathered once by [secureEnvironmentDeclarers]. Null means it could not be gathered,
     * and this package is queried on its own — the same answer, one binder call at a time.
     */
    fun check(packageInfo: PackageInfo, declarers: Set<String>? = null): Verdict {
        val packageName = packageInfo.packageName
        blockedReason(packageName)?.let { return it }

        val viaProperty =
            if (declarers == null) declaredViaProperty(packageName) else packageName in declarers

        if (viaProperty || declaredInMetaData(packageInfo.applicationInfo?.metaData)) {
            Slog.w(Slog.INSTALL, "$packageName declares a secure-environment requirement; rejecting")
            return Verdict.Rejected(
                EngineErrorCodes.SECURE_ENV_REQUIRED,
                "This application requires a secure environment and cannot be virtualized.",
            )
        }

        return Verdict.Allowed
    }

    /**
     * Every installed package that declares a secure-environment property, asked of the
     * platform once for the whole device.
     *
     * Null below API 31, where `queryApplicationProperty` does not exist and there is
     * nothing to gather — and also when the query itself fails, so a caller falls back to
     * asking package by package rather than concluding that nobody declares anything.
     *
     * Safe to use for a listing even though it is one bulk answer rather than a direct
     * question about each package: nothing is admitted on its strength. Tapping a row
     * re-analyses that app with no declarer set, which asks about it directly, and
     * [VirtualAppInstaller] asks a third time before anything is installed. A package this
     * set somehow missed is a row that is offered and then refused — never a clone of an
     * app that said no.
     */
    fun secureEnvironmentDeclarers(): Set<String>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return null
        }
        return try {
            SECURE_ENV_PROPERTIES.flatMapTo(HashSet()) { name ->
                context.packageManager.queryApplicationProperty(name)
                    .filter { it.isTruthy() }
                    .map { it.packageName }
            }
        } catch (error: Exception) {
            Slog.w(Slog.INSTALL, "Could not query secure-environment properties: ${error.message}")
            null
        }
    }

    /**
     * Admission check for a standalone APK file.
     *
     * The host-installed check does not apply — the point of importing an APK is to run
     * something that is not installed — but the secure-environment rule still must. It is
     * read from the archive itself via [apkPath]; if the same package also happens to be
     * installed, the installed declaration is honoured too.
     *
     * Platform limit, stated plainly: `PackageManager.getProperty()` only answers for
     * installed packages, so an archive can only be screened through its application
     * meta-data. An APK that declares the requirement solely as a `<property>` and is not
     * installed here cannot be detected.
     */
    fun checkApk(packageName: String, apkPath: String? = null): Verdict {
        blockedReason(packageName)?.let { return it }

        val declared = (apkPath != null && archiveRequiresSecureEnvironment(apkPath)) ||
            (isInstalled(packageName) && requiresSecureEnvironment(packageName))

        if (declared) {
            Slog.w(Slog.INSTALL, "$packageName declares a secure-environment requirement; rejecting")
            return Verdict.Rejected(
                EngineErrorCodes.SECURE_ENV_REQUIRED,
                "This application requires a secure environment and cannot be virtualized.",
            )
        }

        return Verdict.Allowed
    }

    /**
     * Reads the secure-environment declaration straight out of an uninstalled archive.
     *
     * Two independent sources, because neither is sufficient alone:
     *  - `PackageManager` surfaces an archive's `<meta-data>` but not its `<property>`
     *    elements, which are only exposed through `getProperty()` for installed packages.
     *  - [ApkManifestReader] decodes the archive's own binary manifest and therefore sees
     *    `<property>` as well.
     */
    fun archiveRequiresSecureEnvironment(apkPath: String): Boolean {
        if (ApkManifestReader.declaresTrue(apkPath, SECURE_ENV_PROPERTIES)) {
            return true
        }

        val meta = try {
            context.packageManager
                .getPackageArchiveInfo(apkPath, PackageManager.GET_META_DATA)
                ?.applicationInfo
                ?.metaData
        } catch (error: Exception) {
            // An unreadable archive is refused by ApkImporter; treat it as undeclared here
            // rather than letting a parse failure look like a positive declaration.
            Slog.w(Slog.INSTALL, "Could not read archive meta-data: ${error.message}")
            null
        } ?: return false

        return SECURE_ENV_PROPERTIES.any { meta.getBoolean(it, false) }
    }

    /**
     * Packages Duplika refuses to clone.
     *
     * The host itself would recurse, and cloning core system/framework packages produces
     * a broken container rather than a useful one.
     */
    private fun blockedReason(packageName: String): Verdict.Rejected? {
        if (packageName == context.packageName) {
            return Verdict.Rejected(
                EngineErrorCodes.SELF_CLONE_UNSUPPORTED,
                "Duplika cannot clone itself.",
            )
        }
        if (BLOCKED_PREFIXES.any { packageName == it || packageName.startsWith("$it.") }) {
            return Verdict.Rejected(
                EngineErrorCodes.SYSTEM_COMPONENT_UNSUPPORTED,
                "System components cannot be cloned.",
            )
        }
        return null
    }

    /** Fail-closed: any positive declaration found through either mechanism rejects. */
    fun requiresSecureEnvironment(packageName: String): Boolean =
        declaredViaProperty(packageName) || declaredViaMetaData(packageName)

    private fun declaredViaProperty(packageName: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false

        return SECURE_ENV_PROPERTIES.any { name ->
            try {
                context.packageManager.getProperty(name, packageName).isTruthy()
            } catch (_: PackageManager.NameNotFoundException) {
                false
            } catch (_: Exception) {
                false
            }
        }
    }

    /**
     * Accepts every encoding a manifest can use for "yes".
     *
     * Requiring `isBoolean` was wrong and had real consequences: Google Authenticator ships
     * `<property android:name="REQUIRE_SECURE_ENV" android:value="true"/>`, which aapt2
     * compiles to the **integer** 1, not a boolean. The stricter check therefore found no
     * declaration, and an app that explicitly refuses to be virtualized was offered for
     * cloning. Verified with `aapt2 dump xmltree`.
     */
    private fun PackageManager.Property.isTruthy(): Boolean = when {
        isBoolean -> boolean
        isInteger -> integer != 0
        isString -> string.equals("true", ignoreCase = true) || string == "1"
        else -> false
    }

    private fun declaredViaMetaData(packageName: String): Boolean = try {
        val info = context.packageManager.getApplicationInfo(
            packageName,
            PackageManager.GET_META_DATA,
        )
        declaredInMetaData(info.metaData)
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    /**
     * The same reading of a bundle the caller already has.
     *
     * Every encoding counts, for the reason [isTruthy] spells out: `android:value="true"`
     * does not reach the bundle as a boolean in every app, and asking only for a boolean
     * silently missed apps that had refused virtualization in writing.
     */
    private fun declaredInMetaData(metaData: Bundle?): Boolean = metaData != null &&
        SECURE_ENV_PROPERTIES.any { name ->
            // Asked by type rather than through the untyped getter: a bundle returns the
            // default for a key stored as something else, so the three questions are safe
            // to ask in turn and none of them is deprecated.
            metaData.getBoolean(name, false) ||
                metaData.getInt(name, 0) != 0 ||
                metaData.getString(name).let {
                    it != null && (it.equals("true", ignoreCase = true) || it == "1")
                }
        }

    private fun isInstalled(packageName: String): Boolean = try {
        context.packageManager.getPackageInfo(packageName, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    private companion object {
        val BLOCKED_PREFIXES = listOf(
            "android",
            "com.android.systemui",
            "com.android.settings",
            "com.android.providers",
        )

        val SECURE_ENV_PROPERTIES = listOf(
            "REQUIRE_SECURE_ENV",
            "android.content.pm.REQUIRE_SECURE_ENV",
            "android.app.REQUIRE_SECURE_ENV",
        )
    }
}
