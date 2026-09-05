package com.example.virtualspacedemo.native

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Exercises package detection against the real PackageManager.
 *
 * Requires the controlled test app to be installed on the target device; the
 * not-installed path is covered separately with a package that cannot exist.
 */
@RunWith(AndroidJUnit4::class)
class TestAppManagerTest {

    private lateinit var manager: TestAppManager

    @Before
    fun setUp() {
        val context: Context = ApplicationProvider.getApplicationContext()
        manager = TestAppManager(context)
    }

    @Test
    fun detectsInstalledTestApp() {
        assertTrue(manager.isTestAppInstalled())
    }

    @Test
    fun returnsPackageMetadataForInstalledTestApp() {
        val info = manager.getTestAppInfo()

        assertEquals(true, info["installed"])
        assertEquals(TestAppManager.TEST_APP_PACKAGE, info["packageName"])
        assertEquals("Virtual Test App", info["appName"])
        assertNotNull(info["versionName"])
        assertNotNull(info["versionCode"])
    }

    @Test
    fun reportsPlatformInfo() {
        val info = manager.getPlatformInfo()

        assertNotNull(info["androidVersion"])
        assertTrue((info["sdkInt"] as Int) > 0)
    }
}

@RunWith(AndroidJUnit4::class)
class AppLauncherTest {

    @Test
    fun returnsStructuredFailureForUnknownPackage() {
        val context: Context = ApplicationProvider.getApplicationContext()
        val result = AppLauncher(context).launch("com.example.package.that.does.not.exist")

        assertEquals(false, result["success"])
        assertEquals(AppLauncher.ERROR_NOT_INSTALLED, result["error"])
    }

    @Test
    fun launchIntentExistsForTheControlledTestApp() {
        val context: Context = ApplicationProvider.getApplicationContext()
        val intent = context.packageManager
            .getLaunchIntentForPackage(TestAppManager.TEST_APP_PACKAGE)

        assertNotNull(intent)
        assertFalse(intent!!.component?.packageName.isNullOrEmpty())
    }
}
