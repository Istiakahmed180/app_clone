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

    /**
     * Phase 3 removed the single-package allow-list; ordinary installed apps are allowed.
     *
     * Deliberately does not assume the *first* app in the list is admissible — some are
     * legitimately refused, e.g. an app declaring a secure-environment requirement. What
     * matters is that ordinary apps get through and that every refusal has a stated reason.
     */
    @Test
    fun allowsOrdinaryInstalledAppsAndExplainsAnyRefusal() {
        val installed = InstalledAppsProvider(ApplicationProvider.getApplicationContext())
            .listLaunchableApps(includeIcons = false)
            .map { it["packageName"] as String }
            .filter { it != TestAppManager.TEST_APP_PACKAGE }
            .take(20)

        val verdicts = installed.associateWith(checker::check)

        for ((packageName, verdict) in verdicts) {
            if (verdict is AppSecurityChecker.Verdict.Rejected) {
                assertTrue(
                    "$packageName was refused without a recognised reason: ${verdict.code}",
                    verdict.code in setOf(
                        EngineErrorCodes.SECURE_ENV_REQUIRED,
                        EngineErrorCodes.APP_NOT_SUPPORTED,
                        EngineErrorCodes.APP_NOT_FOUND,
                    ),
                )
            }
        }

        if (installed.isNotEmpty()) {
            assertTrue(
                "no ordinary installed app was admissible",
                verdicts.values.any { it is AppSecurityChecker.Verdict.Allowed },
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

    /**
     * The installed-app path, which is what the picker uses.
     *
     * This is the case that actually failed: the archive check rejected Authenticator while
     * `check()` still admitted it, because the declaration is compiled as an integer rather
     * than a boolean. Skipped when the app is absent so the suite stays portable.
     */
    @Test
    fun anInstalledAppDeclaringASecureEnvironmentIsRejected() {
        val context: Context = ApplicationProvider.getApplicationContext()
        val authenticator = "com.google.android.apps.authenticator2"
        runCatching { context.packageManager.getApplicationInfo(authenticator, 0) }
            .getOrNull() ?: return

        assertTrue(
            "the installed declaration was not detected",
            checker.requiresSecureEnvironment(authenticator),
        )

        val verdict = checker.check(authenticator)
        assertTrue(verdict is AppSecurityChecker.Verdict.Rejected)
        assertEquals(
            EngineErrorCodes.SECURE_ENV_REQUIRED,
            (verdict as AppSecurityChecker.Verdict.Rejected).code,
        )
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

    /** The archive-level secure-environment screen added after the audit. */
    @Test
    fun anOrdinaryApkDoesNotDeclareASecureEnvironmentRequirement() {
        assertFalse(checker.archiveRequiresSecureEnvironment(testAppApkPath()))
    }

    @Test
    fun anUnreadableArchiveIsTreatedAsUndeclaredRatherThanCrashing() {
        assertFalse(checker.archiveRequiresSecureEnvironment("${context.filesDir}/nope.apk"))
    }

    @Test
    fun checkApkStillAdmitsAnOrdinaryArchive() {
        val verdict = checker.checkApk(TestAppManager.TEST_APP_PACKAGE, testAppApkPath())

        assertTrue(verdict is AppSecurityChecker.Verdict.Allowed)
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


/** The Phase 4 compatibility layer. */
@RunWith(AndroidJUnit4::class)
class AppCompatibilityAnalyzerTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val analyzer = AppCompatibilityAnalyzer(context)

    @Test
    fun theControlledTestAppIsFullySupported() {
        val report = analyzer.analyze(TestAppManager.TEST_APP_PACKAGE)

        // It declares no dangerous permissions and no GMS dependency.
        assertEquals(AppCompatibilityAnalyzer.Verdict.SUPPORTED, report.verdict)
        assertTrue(report.findings.isEmpty())
        assertFalse(report.requiresGms)
    }

    @Test
    fun systemComponentsAreUnsupportedAndBlocking() {
        val report = analyzer.analyze("com.android.settings")

        assertEquals(AppCompatibilityAnalyzer.Verdict.UNSUPPORTED, report.verdict)
        assertTrue(report.findings.any { it.blocking })
    }

    @Test
    fun theHostRefusesToAnalyseItselfAsCloneable() {
        val report = analyzer.analyze(context.packageName)

        assertEquals(AppCompatibilityAnalyzer.Verdict.UNSUPPORTED, report.verdict)
    }

    @Test
    fun aMissingPackageIsUnsupportedRatherThanCrashing() {
        val report = analyzer.analyze("com.example.definitely.not.installed")

        assertEquals(AppCompatibilityAnalyzer.Verdict.UNSUPPORTED, report.verdict)
        assertEquals(EngineErrorCodes.APP_NOT_FOUND, report.findings.single().code)
    }

    @Test
    fun missingPermissionsAreASubsetOfBridgeableOnes() {
        val installed = InstalledAppsProvider(context)
            .listLaunchableApps(includeIcons = false)
            .map { it["packageName"] as String }

        for (packageName in installed.take(12)) {
            val report = analyzer.analyze(packageName)
            assertTrue(
                "$packageName: missing must be a subset of bridgeable",
                report.bridgeablePermissions.containsAll(report.missingPermissions),
            )
            // Anything reported as missing must genuinely not be held.
            for (permission in report.missingPermissions) {
                assertFalse(analyzer.isGrantedToHost(permission))
            }
        }
    }

    /**
     * Guards against a false "unsupported" verdict. Real apps commonly ship
     * `extractNativeLibs=false`, so the per-ABI directory can be empty even though the app
     * runs fine. If ABI detection ever regresses, arm64 apps would be blocked outright.
     */
    @Test
    fun arm64AppsAreNeverBlockedForTheirAbi() {
        val installed = InstalledAppsProvider(context)
            .listLaunchableApps(includeIcons = false)
            .map { it["packageName"] as String }

        var checked = 0
        for (packageName in installed) {
            val info = try {
                context.packageManager.getApplicationInfo(packageName, 0)
            } catch (_: Exception) {
                continue
            }
            // Only meaningful for apps that actually carry native code.
            val libDir = info.nativeLibraryDir ?: continue
            if (!java.io.File(libDir).isDirectory) continue

            val report = analyzer.analyze(packageName)
            val abiBlocked = report.findings.any {
                it.code == EngineErrorCodes.ABI_NOT_SUPPORTED && it.blocking
            }
            assertFalse(
                "$packageName (libDir=$libDir) was wrongly blocked on ABI",
                abiBlocked,
            )
            checked++
            if (checked >= 20) break
        }
    }

    @Test
    fun aReportSurvivesConversionToTheChannelShape() {
        val map = analyzer.analyze(TestAppManager.TEST_APP_PACKAGE).toMap()

        assertEquals(TestAppManager.TEST_APP_PACKAGE, map["packageName"])
        assertEquals("SUPPORTED", map["verdict"])
        assertTrue(map["findings"] is List<*>)
        assertTrue(map["bridgeablePermissions"] is List<*>)
    }
}
