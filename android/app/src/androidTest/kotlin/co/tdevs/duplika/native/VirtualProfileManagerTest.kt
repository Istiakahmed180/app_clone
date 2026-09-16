package co.tdevs.duplika.native

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Virtual user id allocation, which is where isolation is actually decided.
 *
 * Every container on disk is named by its id, so the only thing standing between a new
 * clone and somebody else's logged-in account is this class handing out an id nobody's
 * data is sitting under. [ContainerIsolationTest] proves two live containers stay apart;
 * this proves the id that addresses them is never reissued over data that is still there.
 *
 * The store is the app's own SharedPreferences, so each test snapshots it and puts it back
 * — a developer's real clones must survive a test run.
 */
@RunWith(AndroidJUnit4::class)
class VirtualProfileManagerTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private var savedMapping: String? = null
    private var savedQuarantine: String? = null

    @Before
    fun startFromAnEmptyStore() {
        savedMapping = prefs.getString(KEY_MAPPING, null)
        savedQuarantine = prefs.getString(KEY_QUARANTINE, null)
        prefs.edit().remove(KEY_MAPPING).remove(KEY_QUARANTINE).commit()
    }

    @After
    fun restoreTheDevicesOwnMapping() {
        prefs.edit()
            .putString(KEY_MAPPING, savedMapping)
            .putString(KEY_QUARANTINE, savedQuarantine)
            .commit()
    }

    private fun manager() = VirtualProfileManager(context)

    @Test
    fun twoProfilesNeverShareAnId() {
        val manager = manager()

        val first = manager.getOrCreate("profile-a")
        val second = manager.getOrCreate("profile-b")

        assertNotEquals(first, second)
    }

    @Test
    fun askingTwiceForOneProfileReturnsTheSameId() {
        val manager = manager()

        assertEquals(manager.getOrCreate("profile-a"), manager.getOrCreate("profile-a"))
    }

    @Test
    fun anIdIsReusedOnlyAfterItsProfileIsRemoved() {
        val manager = manager()
        val first = manager.getOrCreate("profile-a")

        assertEquals(first, manager.remove("profile-a"))

        // Removal is what deleteProfile does *after* the engine confirmed the container is
        // gone, so reuse here is correct: nothing is left under that id.
        assertEquals(first, manager.getOrCreate("profile-b"))
    }

    /**
     * The regression this class's quarantine exists for.
     *
     * A delete whose container removal failed used to free the id anyway, and the next
     * clone was allocated straight into a container still holding the previous space's
     * logged-in session.
     */
    @Test
    fun aQuarantinedIdIsNeverHandedOutAgain() {
        val manager = manager()
        val stranded = manager.getOrCreate("profile-a")

        assertEquals(stranded, manager.quarantine("profile-a"))

        // The profile is gone...
        assertNull("the quarantined profile kept its mapping", manager.virtualUserIdFor("profile-a"))
        // ...but its id is not on offer to anyone else.
        repeat(4) { index ->
            assertNotEquals(
                "a later clone was allocated into a quarantined container",
                stranded,
                manager.getOrCreate("later-$index"),
            )
        }
    }

    @Test
    fun aMappingSurvivesANewInstanceOfTheManager() {
        val id = manager().getOrCreate("profile-a")

        assertEquals(id, manager().virtualUserIdFor("profile-a"))
    }

    @Test
    fun aQuarantinedIdSurvivesANewInstanceOfTheManager() {
        val stranded = manager().getOrCreate("profile-a")
        manager().quarantine("profile-a")

        // A fresh instance reads the store rather than any in-memory state; a quarantine
        // that lived only in memory would expire the first time the process restarted.
        assertNotEquals(stranded, manager().getOrCreate("profile-b"))
    }

    @Test
    fun quarantiningAnUnknownProfileReservesNothing() {
        val manager = manager()
        val expected = manager.getOrCreate("profile-a")

        assertNull(manager.quarantine("never-mapped"))

        // Nothing was reserved, so the next id is still the one it would have been.
        assertEquals(expected, manager.getOrCreate("profile-a"))
        assertFalse("an unknown profile added an entry to the quarantine list",
            prefs.contains(KEY_QUARANTINE))
    }

    /**
     * An unreadable store must refuse, not guess.
     *
     * Allocation hands out the lowest free id, so answering "nothing is mapped" reissues
     * 0, 1, 2… over every container already on disk — and does it silently. A thrown
     * failure reaches the user as an error; a wrong id reaches them as someone else's
     * account.
     */
    @Test
    fun anUnreadableMappingRefusesToAllocate() {
        prefs.edit().putString(KEY_MAPPING, "{ this is not json").commit()

        assertThrows(IllegalStateException::class.java) { manager().getOrCreate("profile-a") }
        assertThrows(IllegalStateException::class.java) { manager().virtualUserIdFor("profile-a") }
    }

    @Test
    fun anUnreadableQuarantineListRefusesToAllocate() {
        prefs.edit().putString(KEY_QUARANTINE, "{ this is not json").commit()

        // Same reasoning: not knowing which ids are unsafe is not the same as there being
        // none, and only one of those two answers is safe to act on.
        assertThrows(IllegalStateException::class.java) { manager().getOrCreate("profile-a") }
    }

    @Test
    fun aStoreThatWasNeverWrittenIsNotAnError() {
        // Distinct from the unreadable case above: a first run has no file at all, and
        // that must still allocate normally.
        assertTrue(manager().getOrCreate("profile-a") >= 0)
    }

    private companion object {
        // Mirrors VirtualProfileManager's own private constants; the test writes malformed
        // values directly because no API can produce them.
        const val PREFS_NAME = "duplika_profile_mapping"
        const val KEY_MAPPING = "profile_to_virtual_user"
        const val KEY_QUARANTINE = "quarantined_virtual_users"
    }
}
