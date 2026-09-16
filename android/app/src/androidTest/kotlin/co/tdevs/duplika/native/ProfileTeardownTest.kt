package co.tdevs.duplika.native

import android.app.Application
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

/**
 * What happens to a container the engine refused to delete.
 *
 * Every other test in this package drives the path where the backend agrees. This one
 * drives the path where it does not, through a stub adapter, because that is where the
 * data-crossover risk lives: a delete that failed halfway used to release the virtual user
 * id anyway, leaving the container — logins and all — on disk under an id the next clone
 * was then allocated into.
 *
 * The stub also makes the test independent of whether a real engine is available on the
 * device running it.
 */
@RunWith(AndroidJUnit4::class)
class ProfileTeardownTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private var savedMapping: String? = null
    private var savedQuarantine: String? = null

    @Before
    fun startFromAKnownMapping() {
        savedMapping = prefs.getString(KEY_MAPPING, null)
        savedQuarantine = prefs.getString(KEY_QUARANTINE, null)
        // Written rather than allocated. getOrCreate hands out the lowest free id, which on
        // a device with real clones is a real container — and these tests delete identity
        // files and disable shortcuts for whatever id they are given.
        prefs.edit()
            .putString(KEY_MAPPING, "{\"$PROFILE\": $TEST_USER_ID}")
            .remove(KEY_QUARANTINE)
            .commit()
    }

    @After
    fun restoreTheDevicesOwnMapping() {
        SpaceIdentityStore(context).forget(TEST_USER_ID)
        prefs.edit()
            .putString(KEY_MAPPING, savedMapping)
            .putString(KEY_QUARANTINE, savedQuarantine)
            .commit()
    }

    /**
     * A delete the backend refuses must leave the mapping alone.
     *
     * The Flutter side keeps the profile on screen after a failed delete specifically so
     * the user can try again; a retry can only reach this container while the mapping
     * still points at it.
     */
    @Test
    fun aRefusedDeleteKeepsTheProfileDeletable() {
        val adapter = StubAdapter(deleteSucceeds = false)
        val engine = RealVirtualizationEngine(context, adapter)

        val refused = engine.deleteProfile(PROFILE, PACKAGE)

        assertTrue("a refused delete was reported as success", refused is EngineResult.Failure)
        assertEquals(
            "the profile lost its mapping while its container was still on disk",
            TEST_USER_ID,
            VirtualProfileManager(context).virtualUserIdFor(PROFILE),
        )

        // The retry the Flutter layer is designed around: same profile, backend now
        // agrees, and the delete completes rather than returning a hollow success.
        adapter.deleteSucceeds = true
        val retried = engine.deleteProfile(PROFILE, PACKAGE)

        assertTrue("the retry did not succeed: $retried", retried is EngineResult.Success)
        assertNull(VirtualProfileManager(context).virtualUserIdFor(PROFILE))
        assertEquals("the retry never reached the engine", 2, adapter.deleteAttempts)
    }

    /**
     * A refused delete must not take the space's identifiers with it.
     *
     * The space is still there — that is the whole point of the failure — so wiping its
     * identity file would silently reset identifiers the user typed.
     *
     * The typed value matters to the test, not just to the user: a space's first set is
     * *derived* from its profile id, so a wrongly deleted file rebuilds itself byte for
     * byte and an untouched space cannot tell the two cases apart. Only a hand-entered
     * value, which nothing can recompute, makes the loss visible.
     */
    @Test
    fun aRefusedDeleteLeavesTheSpacesIdentityAlone() {
        val identities = SpaceIdentityStore(context)
        val typed = identities.update(PROFILE, TEST_USER_ID, mapOf("deviceId" to TYPED_DEVICE_ID))
        assertTrue("the test could not store a hand-typed identifier", typed.isSuccess)

        RealVirtualizationEngine(context, StubAdapter(deleteSucceeds = false))
            .deleteProfile(PROFILE, PACKAGE)

        assertEquals(
            "a refused delete threw away identifiers the user had typed",
            TYPED_DEVICE_ID,
            identities.identity(PROFILE, TEST_USER_ID).deviceId,
        )
    }

    /**
     * An identity file left behind by a previous space belongs to that space, not to
     * whoever ends up holding the id.
     */
    @Test
    fun aSpaceDoesNotInheritAnotherSpacesIdentifiers() {
        val identities = SpaceIdentityStore(context)
        val first = identities.identity(PROFILE, TEST_USER_ID)

        val second = identities.identity("a-different-profile", TEST_USER_ID)

        assertNotEquals(first.deviceId, second.deviceId)
        assertNotEquals(first.androidId, second.androidId)
    }

    /**
     * The minimum backend that [RealVirtualizationEngine.deleteProfile] touches: stop,
     * uninstall, delete. Everything else throws if reached, so a test that drifts into an
     * untested path fails instead of quietly passing.
     */
    private class StubAdapter(var deleteSucceeds: Boolean) : VirtualizationEngineAdapter {
        var deleteAttempts = 0
            private set

        override val backendName = "stub"

        override fun deleteVirtualUser(virtualUserId: Int): EngineResult<Unit> {
            deleteAttempts++
            return if (deleteSucceeds) {
                EngineResult.ok()
            } else {
                EngineResult.Failure(
                    EngineErrorCodes.PROFILE_DELETE_FAILED,
                    "the stub refused this delete",
                )
            }
        }

        override fun stop(packageName: String, virtualUserId: Int) = EngineResult.ok()

        override fun uninstallPackage(packageName: String, virtualUserId: Int) = EngineResult.ok()

        override fun isRunning(packageName: String, virtualUserId: Int) = false

        override fun attachBaseContext(application: Application, base: Context) = unexpected()
        override fun onCreate(application: Application) = unexpected()
        override fun checkAvailability(context: Context): EngineAvailability = unexpected()
        override fun initialize(context: Context): EngineResult<Unit> = unexpected()
        override fun installPackage(packageName: String, virtualUserId: Int) = unexpected()
        override fun isGmsSupported(): Boolean = unexpected()
        override fun installGms(virtualUserId: Int): EngineResult<Unit> = unexpected()
        override fun installApkFiles(apkPaths: List<String>, virtualUserId: Int) = unexpected()
        override fun clearPackageData(packageName: String, virtualUserId: Int) = unexpected()
        override fun clearPackageCache(packageName: String, virtualUserId: Int) = unexpected()
        override fun isPackageInstalled(packageName: String, virtualUserId: Int): Boolean =
            unexpected()

        override fun launch(packageName: String, virtualUserId: Int): EngineResult<Unit> =
            unexpected()

        override fun listVirtualUserIds(): List<Int> = unexpected()

        override fun guestSharedPreferencesFile(
            packageName: String,
            virtualUserId: Int,
            preferenceName: String,
        ): File? = unexpected()

        override fun startContainerService(
            packageName: String,
            serviceClassName: String,
            virtualUserId: Int,
            requireForeground: Boolean,
            action: String?,
        ): EngineResult<Unit> = unexpected()

        private fun unexpected(): Nothing =
            throw AssertionError("the teardown path reached an unstubbed backend call")
    }

    private companion object {
        const val PROFILE = "teardown-test-profile"

        /**
         * Far above any id allocation would reach, so nothing here can resolve to a
         * container or identity file belonging to a clone the device actually has.
         */
        const val TEST_USER_ID = 90_001

        /** 15 digits, so it passes validation, and derivable from nothing. */
        const val TYPED_DEVICE_ID = "123456789012345"
        const val PACKAGE = TestAppManager.TEST_APP_PACKAGE
        const val PREFS_NAME = "duplika_profile_mapping"
        const val KEY_MAPPING = "profile_to_virtual_user"
        const val KEY_QUARANTINE = "quarantined_virtual_users"
    }
}
