package com.example.virtualspacedemo.native

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

/**
 * Proves the archive manifest reader actually detects a `<property>` declaration.
 *
 * Without a fixture that really declares one, a reader that always returned "not declared"
 * would pass every other test — and the secure-environment screen would be silently useless
 * for imported APKs, which is exactly the case `PackageManager` cannot cover.
 *
 * The fixtures are ~750-byte APKs built with `aapt2 link --manifest`; they contain a
 * compiled manifest and nothing else.
 */
@RunWith(AndroidJUnit4::class)
class ApkManifestReaderTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val secureEnvNames = listOf(
        "REQUIRE_SECURE_ENV",
        "android.content.pm.REQUIRE_SECURE_ENV",
        "android.app.REQUIRE_SECURE_ENV",
    )

    /** Copies a packaged fixture out of the test APK so it has a real file path. */
    private fun fixture(assetName: String): String {
        val target = File(context.cacheDir, assetName)
        InstrumentationRegistry.getInstrumentation().context.assets.open(assetName).use { input ->
            target.outputStream().use(input::copyTo)
        }
        return target.absolutePath
    }

    @Test
    fun readsAPropertyDeclarationOutOfAnUninstalledArchive() {
        val declarations = ApkManifestReader.readDeclarations(fixture(SECURE_FIXTURE))

        val property = declarations.singleOrNull { it.element == "property" }
        assertEquals("REQUIRE_SECURE_ENV", property?.name)
        assertEquals("true", property?.value)
    }

    @Test
    fun detectsTheSecureEnvironmentRequirement() {
        assertTrue(ApkManifestReader.declaresTrue(fixture(SECURE_FIXTURE), secureEnvNames))
    }

    @Test
    fun doesNotReportADeclarationThatIsNotThere() {
        assertFalse(ApkManifestReader.declaresTrue(fixture(PLAIN_FIXTURE), secureEnvNames))
    }

    @Test
    fun readsMetaDataToo() {
        val declarations = ApkManifestReader.readDeclarations(fixture(PLAIN_FIXTURE))

        val meta = declarations.singleOrNull { it.element == "meta-data" }
        assertEquals("something.else", meta?.name)
    }

    @Test
    fun anOrdinaryRealApkDeclaresNoSuchRequirement() {
        val realApk = context.packageManager
            .getApplicationInfo(TestAppManager.TEST_APP_PACKAGE, 0)
            .sourceDir

        assertFalse(ApkManifestReader.declaresTrue(realApk, secureEnvNames))
        // The reader must still be able to parse a real, full-sized APK.
        assertTrue(ApkManifestReader.readDeclarations(realApk).isNotEmpty())
    }

    @Test
    fun unreadableInputIsTreatedAsNoDeclaration() {
        assertTrue(ApkManifestReader.readDeclarations("/does/not/exist.apk").isEmpty())

        val notAnApk = File(context.cacheDir, "garbage.apk").apply { writeText("not a zip") }
        assertTrue(ApkManifestReader.readDeclarations(notAnApk.absolutePath).isEmpty())
        assertFalse(ApkManifestReader.declaresTrue(notAnApk.absolutePath, secureEnvNames))
        notAnApk.delete()
    }

    /** The admission decision itself, not just the reader. */
    @Test
    fun anImportedApkDeclaringTheRequirementIsRejected() {
        val verdict = AppSecurityChecker(context)
            .checkApk("com.example.secureenvfixture", fixture(SECURE_FIXTURE))

        assertTrue(verdict is AppSecurityChecker.Verdict.Rejected)
        assertEquals(
            EngineErrorCodes.SECURE_ENV_REQUIRED,
            (verdict as AppSecurityChecker.Verdict.Rejected).code,
        )
    }

    /**
     * Sweeps real APKs on the device.
     *
     * Guards the failure mode that no fixture can catch: a parser that quietly degraded to
     * returning nothing would reopen the very hole this reader exists to close while every
     * other test stayed green.
     *
     * Note this does **not** assert that no app declares the requirement — at least one on
     * a normal device does. See [googleAuthenticatorIsRefused].
     */
    @Test
    fun realApksAreParsedRatherThanSilentlyReturningNothing() {
        val packages = InstalledAppsProvider(context)
            .listLaunchableApps(includeIcons = false)
            .map { it["packageName"] as String }
            .take(25)

        var parsed = 0
        var examined = 0

        for (packageName in packages) {
            val apk = runCatching {
                context.packageManager.getApplicationInfo(packageName, 0).sourceDir
            }.getOrNull() ?: continue
            if (!File(apk).canRead()) continue

            examined++
            // Must not throw on any real archive.
            if (ApkManifestReader.readDeclarations(apk).isNotEmpty()) parsed++
        }

        assertTrue("no readable APKs were examined", examined > 0)
        // Essentially every real app declares at least one <meta-data> or <property>.
        assertTrue(
            "the reader extracted declarations from only $parsed of $examined real APKs",
            parsed * 2 >= examined,
        )
    }

    /**
     * A real-world end-to-end case for the whole point of this reader.
     *
     * Google Authenticator ships
     * `<property android:name="REQUIRE_SECURE_ENV" android:value="true"/>` — verified
     * independently with `aapt2 dump xmltree`. It is exactly the kind of app that must not be
     * cloned, and before this reader existed it would have been admitted without complaint.
     *
     * Skipped rather than failed when the app is absent, so the suite stays portable.
     */
    @Test
    fun googleAuthenticatorIsRefused() {
        val apk = runCatching {
            context.packageManager.getApplicationInfo(AUTHENTICATOR, 0).sourceDir
        }.getOrNull() ?: return

        assertTrue(
            "the declaration in $AUTHENTICATOR was not detected",
            ApkManifestReader.declaresTrue(apk, secureEnvNames),
        )

        val verdict = AppSecurityChecker(context).checkApk(AUTHENTICATOR, apk)
        assertTrue(verdict is AppSecurityChecker.Verdict.Rejected)
        assertEquals(
            EngineErrorCodes.SECURE_ENV_REQUIRED,
            (verdict as AppSecurityChecker.Verdict.Rejected).code,
        )
    }

    /**
     * The import flow's verdict now comes from the archive, not from an assumption.
     * An APK declaring the requirement must be UNSUPPORTED before anything is installed.
     */
    @Test
    fun analysingADeclaringArchiveYieldsAnUnsupportedVerdict() {
        val report = AppCompatibilityAnalyzer(context)
            .analyzeApk(fixture(SECURE_FIXTURE), "com.example.secureenvfixture")

        assertEquals(AppCompatibilityAnalyzer.Verdict.UNSUPPORTED, report.verdict)
        assertTrue(report.findings.any { it.blocking })
    }

    @Test
    fun analysingAnOrdinaryArchiveDoesNotBlockIt() {
        val realApk = context.packageManager
            .getApplicationInfo(TestAppManager.TEST_APP_PACKAGE, 0)
            .sourceDir

        val report = AppCompatibilityAnalyzer(context)
            .analyzeApk(realApk, TestAppManager.TEST_APP_PACKAGE)

        assertFalse(
            "an ordinary APK was blocked: ${report.findings.map { it.code }}",
            report.findings.any { it.blocking },
        )
    }

    /** Real-world end-to-end: the archive path must refuse Authenticator too. */
    @Test
    fun analysingAuthenticatorsArchiveIsUnsupported() {
        val apk = runCatching {
            context.packageManager.getApplicationInfo(AUTHENTICATOR, 0).sourceDir
        }.getOrNull() ?: return

        val report = AppCompatibilityAnalyzer(context).analyzeApk(apk, AUTHENTICATOR)

        assertEquals(AppCompatibilityAnalyzer.Verdict.UNSUPPORTED, report.verdict)
        assertTrue(
            report.findings.any {
                it.blocking && it.code == EngineErrorCodes.SECURE_ENV_REQUIRED
            },
        )
    }

    /**
     * Differential check between the two analysis paths.
     *
     * For an app that is installed, `analyze(package)` (via PackageManager) and
     * `analyzeApk(sourceDir, package)` (via the archive) are looking at the same
     * application and must reach the same blocking conclusion. A disagreement means one of
     * them is wrong, and neither is obviously the authority — so it is worth failing on.
     */
    @Test
    fun bothAnalysisPathsAgreeOnRealInstalledApps() {
        val analyzer = AppCompatibilityAnalyzer(context)
        val packages = InstalledAppsProvider(context)
            .listLaunchableApps(includeIcons = false)
            .map { it["packageName"] as String }
            .take(20)

        val disagreements = mutableListOf<String>()
        var compared = 0

        for (packageName in packages) {
            val apk = runCatching {
                context.packageManager.getApplicationInfo(packageName, 0).sourceDir
            }.getOrNull() ?: continue
            if (!File(apk).canRead()) continue

            val installed = analyzer.analyze(packageName)
            val archive = analyzer.analyzeApk(apk, packageName)
            compared++

            val installedBlocked = installed.findings.filter { it.blocking }.map { it.code }.toSet()
            val archiveBlocked = archive.findings.filter { it.blocking }.map { it.code }.toSet()
            if (installedBlocked != archiveBlocked) {
                disagreements += "$packageName: installed=$installedBlocked archive=$archiveBlocked"
            }

            if (installed.requiresGms != archive.requiresGms) {
                disagreements += "$packageName: GMS installed=${installed.requiresGms} archive=${archive.requiresGms}"
            }
        }

        assertTrue("no apps were compared", compared > 0)
        assertTrue("the two analysis paths disagree: $disagreements", disagreements.isEmpty())
    }

    private companion object {
        const val SECURE_FIXTURE = "secure-env-fixture.apk"
        const val PLAIN_FIXTURE = "plain-fixture.apk"
        const val AUTHENTICATOR = "com.google.android.apps.authenticator2"
    }
}
