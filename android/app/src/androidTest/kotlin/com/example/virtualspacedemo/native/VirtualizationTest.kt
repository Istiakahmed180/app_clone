package com.example.virtualspacedemo.native

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/** Maps Flutter profile ids onto engine user ids without a running engine. */
@RunWith(AndroidJUnit4::class)
class VirtualProfileManagerTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    @Test
    fun allocatesDistinctIdsAndReusesFreedOnes() {
        val manager = VirtualProfileManager(context)
        val existing = manager.allMappings().keys.toList()
        existing.forEach(manager::remove)

        val first = manager.getOrCreate("profile-a")
        val second = manager.getOrCreate("profile-b")

        assertNotEquals(first, second)
        // Stable for the same profile.
        assertEquals(first, manager.getOrCreate("profile-a"))

        manager.remove("profile-a")
        assertNull(manager.virtualUserIdFor("profile-a"))
        // The freed id becomes available again, and never collides with the live one.
        assertNotEquals(second, manager.getOrCreate("profile-c"))

        listOf("profile-b", "profile-c").forEach(manager::remove)
    }

    @Test
    fun mappingSurvivesANewManagerInstance() {
        val manager = VirtualProfileManager(context)
        val id = manager.getOrCreate("profile-persist")

        assertEquals(id, VirtualProfileManager(context).virtualUserIdFor("profile-persist"))

        manager.remove("profile-persist")
    }
}

/** The container admission policy. */
@RunWith(AndroidJUnit4::class)
class AppSecurityCheckerTest {

    private val checker = AppSecurityChecker(ApplicationProvider.getApplicationContext())

    @Test
    fun allowsTheControlledTestApp() {
        assertTrue(checker.check(TestAppManager.TEST_APP_PACKAGE) is AppSecurityChecker.Verdict.Allowed)
    }

    /** Phase 3 removed the single-package allow-list; arbitrary installed apps are allowed. */
    @Test
    fun allowsAnArbitraryInstalledApp() {
        val other = InstalledAppsProvider(ApplicationProvider.getApplicationContext())
            .listLaunchableApps(includeIcons = false)
            .map { it["packageName"] as String }
            .firstOrNull { it != TestAppManager.TEST_APP_PACKAGE }

        // Nothing to assert on a device with no other launchable app.
        if (other != null) {
            assertTrue(
                "expected $other to be admissible",
                checker.check(other) is AppSecurityChecker.Verdict.Allowed,
            )
        }
    }

    @Test
    fun rejectsAPackageThatIsNotInstalled() {
        val verdict = checker.check("com.example.definitely.not.installed")

        assertTrue(verdict is AppSecurityChecker.Verdict.Rejected)
        assertEquals(
            EngineErrorCodes.APP_NOT_FOUND,
            (verdict as AppSecurityChecker.Verdict.Rejected).code,
        )
    }

    @Test
    fun refusesToCloneItselfOrSystemComponents() {
        val context: Context = ApplicationProvider.getApplicationContext()

        for (blocked in listOf(context.packageName, "android", "com.android.settings")) {
            val verdict = checker.check(blocked)
            assertTrue("$blocked should be rejected", verdict is AppSecurityChecker.Verdict.Rejected)
            assertEquals(
                EngineErrorCodes.APP_NOT_SUPPORTED,
                (verdict as AppSecurityChecker.Verdict.Rejected).code,
            )
        }
    }

    @Test
    fun theControlledTestAppDoesNotDeclareASecureEnvironmentRequirement() {
        assertFalse(checker.requiresSecureEnvironment(TestAppManager.TEST_APP_PACKAGE))
    }
}

/** Targeted icon lookup used by the home screen. */
@RunWith(AndroidJUnit4::class)
class InstalledAppsProviderTest {

    private val provider = InstalledAppsProvider(ApplicationProvider.getApplicationContext())

    @Test
    fun listsLaunchableAppsWithoutTheHostItself() {
        val context: Context = ApplicationProvider.getApplicationContext()
        val packages = provider.listLaunchableApps(includeIcons = false)
            .map { it["packageName"] as String }

        assertTrue(packages.contains(TestAppManager.TEST_APP_PACKAGE))
        assertFalse("the host must not offer to clone itself", packages.contains(context.packageName))
    }

    @Test
    fun returnsIconsOnlyForTheRequestedPackages() {
        val icons = provider.iconsFor(
            listOf(TestAppManager.TEST_APP_PACKAGE, "com.example.definitely.not.installed"),
        )

        assertEquals(1, icons.size)
        assertTrue(icons.containsKey(TestAppManager.TEST_APP_PACKAGE))
        assertTrue(icons.getValue(TestAppManager.TEST_APP_PACKAGE).isNotEmpty())
    }

    @Test
    fun anEmptyRequestDoesNoWork() {
        assertTrue(provider.iconsFor(emptyList()).isEmpty())
    }
}

/** The engine adapter's own availability reporting. */
@RunWith(AndroidJUnit4::class)
class VirtualizationAvailabilityTest {

    @Test
    fun reportsAvailabilityAndBackendIdentity() {
        val context: Context = ApplicationProvider.getApplicationContext()
        val engine = RealVirtualizationEngine(context, com.example.virtualspacedemo.VirtualSpaceApplication.engine)

        val availability = engine.availability()

        assertNotEquals("", availability["backend"])
        // Availability must be a real answer, never assumed true.
        assertTrue(availability["available"] is Boolean)
    }
}

/**
 * Exercises the APK-import path end to end, minus the system file picker.
 *
 * A real APK file is obtained from the platform (the controlled test app's own
 * `sourceDir`), so this covers parsing, admission and container installation exactly as
 * an imported file would. Driving the SAF picker itself is out of scope for an
 * instrumentation test.
 */
@RunWith(AndroidJUnit4::class)
class ApkImportTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val importer = ApkImporter(context)
    private val checker = AppSecurityChecker(context)

    private fun testAppApkPath(): String =
        context.packageManager
            .getApplicationInfo(TestAppManager.TEST_APP_PACKAGE, 0)
            .sourceDir

    @Test
    fun parsesIdentityFromARealApkFile() {
        val info = importer.inspect(testAppApkPath())

        assertTrue(info is ApkImporter.ApkInfo.Parsed)
        info as ApkImporter.ApkInfo.Parsed
        assertEquals(TestAppManager.TEST_APP_PACKAGE, info.packageName)
        assertEquals("Virtual Test App", info.appName)
        assertNotNull(info.versionName)
    }

    @Test
    fun rejectsAFileThatIsNotAnApk() {
        val notAnApk = java.io.File(context.filesDir, "not-an-apk.txt").apply {
            writeText("definitely not a package archive")
        }

        val info = importer.inspect(notAnApk.absolutePath)

        assertTrue(info is ApkImporter.ApkInfo.Invalid)
        assertEquals(EngineErrorCodes.APK_INVALID, (info as ApkImporter.ApkInfo.Invalid).code)
        notAnApk.delete()
    }

    @Test
    fun rejectsAMissingFile() {
        val info = importer.inspect("${context.filesDir}/nope.apk")

        assertTrue(info is ApkImporter.ApkInfo.Invalid)
        assertEquals(EngineErrorCodes.APK_UNREADABLE, (info as ApkImporter.ApkInfo.Invalid).code)
    }

    @Test
    fun reportsWhetherTheParsedPackageIsAlsoInstalledOnTheHost() {
        assertTrue(importer.isInstalledOnHost(TestAppManager.TEST_APP_PACKAGE))
        assertFalse(importer.isInstalledOnHost("com.example.definitely.not.installed"))
    }

    @Test
    fun refusesToImportAnApkDeclaringTheHostPackage() {
        // Cloning Virtual Space into Virtual Space would recurse.
        val verdict = checker.checkApk(context.packageName)

        assertTrue(verdict is AppSecurityChecker.Verdict.Rejected)
        assertEquals(
            EngineErrorCodes.APP_NOT_SUPPORTED,
            (verdict as AppSecurityChecker.Verdict.Rejected).code,
        )
    }

    @Test
    fun installsAnApkIntoItsOwnContainerAndCleansUp() {
        val engine = RealVirtualizationEngine(
            context,
            com.example.virtualspacedemo.VirtualSpaceApplication.engine,
        )
        val profileId = "androidtest-apk-${System.currentTimeMillis()}"

        try {
            val result = engine.installApkToProfile(
                profileId,
                testAppApkPath(),
                TestAppManager.TEST_APP_PACKAGE,
            )

            assertTrue("install returned $result", result is EngineResult.Success)

            val state = engine.profileState(profileId, TestAppManager.TEST_APP_PACKAGE)
            assertNotNull("the profile should be mapped to a virtual user", state["virtualUserId"])
        } finally {
            engine.deleteProfile(profileId, TestAppManager.TEST_APP_PACKAGE)
        }
    }
}
