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

    private companion object {
        const val SECURE_FIXTURE = "secure-env-fixture.apk"
        const val PLAIN_FIXTURE = "plain-fixture.apk"
    }
}
