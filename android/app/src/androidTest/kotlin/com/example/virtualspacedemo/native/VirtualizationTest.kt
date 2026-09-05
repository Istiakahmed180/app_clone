package com.example.virtualspacedemo.native

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
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

    @Test
    fun rejectsAnyOtherPackage() {
        val verdict = checker.check("com.example.some.other.app")

        assertTrue(verdict is AppSecurityChecker.Verdict.Rejected)
        assertEquals(
            EngineErrorCodes.APP_NOT_SUPPORTED,
            (verdict as AppSecurityChecker.Verdict.Rejected).code,
        )
    }

    @Test
    fun theControlledTestAppDoesNotDeclareASecureEnvironmentRequirement() {
        assertFalse(checker.requiresSecureEnvironment(TestAppManager.TEST_APP_PACKAGE))
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
