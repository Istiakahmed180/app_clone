package com.example.virtualspacedemo.native

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.virtualspacedemo.VirtualSpaceApplication
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

/**
 * The product's central claim: two clones of one application do not share data.
 *
 * Until this existed the claim rested entirely on manual observation, so an engine or
 * adapter regression could have silently removed isolation without any suite noticing.
 * These tests assert it from the host process, where the container directories are
 * readable because they live inside the host's own sandbox.
 */
@RunWith(AndroidJUnit4::class)
class ContainerIsolationTest {

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val engine = RealVirtualizationEngine(context, VirtualSpaceApplication.engine)

    private val createdProfiles = mutableListOf<String>()

    @Before
    fun requireAWorkingEngine() {
        // Isolation cannot be asserted on a device where the backend never started; fail
        // loudly rather than reporting a green run that proved nothing.
        assertTrue(
            "the virtualization engine is not available: ${engine.availability()}",
            engine.isAvailable(),
        )
    }

    @After
    fun removeProfilesCreatedByThisTest() {
        // A container left behind would leak a virtual user into later runs, so a failed
        // cleanup is surfaced rather than swallowed.
        val failures = mutableListOf<String>()
        for (profileId in createdProfiles) {
            val outcome = runCatching { engine.deleteProfile(profileId, PACKAGE) }
                .getOrElse { EngineResult.Failure("EXCEPTION", it.message.orEmpty()) }
            if (outcome is EngineResult.Failure) {
                failures += "$profileId -> ${outcome.code}"
            }
        }
        createdProfiles.clear()
        assertTrue("profiles were left behind: $failures", failures.isEmpty())
    }

    // ---------------------------------------------------------------------------------
    // helpers
    // ---------------------------------------------------------------------------------

    private fun newProfile(): Pair<String, Int> {
        val profileId = "isolation-${System.nanoTime()}"
        createdProfiles += profileId

        val result = engine.installAppToProfile(profileId, PACKAGE)
        assertTrue("install into $profileId returned $result", result is EngineResult.Success)

        val virtualUserId = engine.profileState(profileId, PACKAGE)["virtualUserId"]
        assertNotNull("no virtual user was allocated for $profileId", virtualUserId)
        return profileId to virtualUserId as Int
    }

    /**
     * Where the backend keeps a package's per-user data. This mirrors Bcore's on-disk
     * layout; if the backend is ever replaced this helper is the single place to update.
     */
    private fun containerDir(virtualUserId: Int): File =
        File(context.dataDir, "blackbox/data/user/$virtualUserId/$PACKAGE")

    private fun writeSentinel(virtualUserId: Int, value: String) {
        val prefs = File(containerDir(virtualUserId), "shared_prefs").apply { mkdirs() }
        File(prefs, SENTINEL_FILE).writeText(value)
    }

    private fun readSentinel(virtualUserId: Int): String? =
        File(containerDir(virtualUserId), "shared_prefs/$SENTINEL_FILE")
            .takeIf { it.isFile }
            ?.readText()

    private fun fileCount(virtualUserId: Int): Int =
        containerDir(virtualUserId).walkTopDown().count { it.isFile }

    // ---------------------------------------------------------------------------------
    // tests
    // ---------------------------------------------------------------------------------

    @Test
    fun twoClonesOfOnePackageGetSeparateContainers() {
        val (_, first) = newProfile()
        val (_, second) = newProfile()

        assertNotEquals("both clones were mapped to the same virtual user", first, second)
        assertNotEquals(
            "both clones resolved to the same container directory",
            containerDir(first).absolutePath,
            containerDir(second).absolutePath,
        )
    }

    @Test
    fun dataWrittenInOneContainerIsNotVisibleInTheOther() {
        val (_, first) = newProfile()
        val (_, second) = newProfile()

        writeSentinel(first, "Alice")
        writeSentinel(second, "Bob")

        assertEquals("Alice", readSentinel(first))
        assertEquals("Bob", readSentinel(second))
    }

    @Test
    fun writingToOneContainerDoesNotCreateTheFileInAnUnwrittenOne() {
        val (_, written) = newProfile()
        val (_, untouched) = newProfile()

        writeSentinel(written, "only-here")

        assertEquals("only-here", readSentinel(written))
        assertNull("the sentinel leaked into a container never written to", readSentinel(untouched))
    }

    /**
     * The redirection proof.
     *
     * The previous tests show the host can keep two directories apart. This one shows the
     * *guest* is actually confined to its own: only the launched clone's container gains
     * files, written by the guest process rather than by this test.
     */
    @Test
    fun aLaunchedGuestWritesOnlyIntoItsOwnContainer() {
        val (launchedProfile, launched) = newProfile()
        val (_, idle) = newProfile()

        // Recorded before launching so growth can only come from the launch itself.
        val filesBefore = fileCount(launched)
        val idleBefore = fileCount(idle)

        val result = engine.launchProfile(launchedProfile, PACKAGE)
        assertTrue("launch returned $result", result is EngineResult.Success)

        try {
            val grew = waitUntil(LAUNCH_TIMEOUT_MS) { fileCount(launched) > filesBefore }
            assertTrue(
                "the guest never wrote anything into its container within ${LAUNCH_TIMEOUT_MS}ms",
                grew,
            )
            assertEquals(
                "launching one clone wrote into a different clone's container",
                idleBefore,
                fileCount(idle),
            )
        } finally {
            engine.stopProfile(launchedProfile, PACKAGE)
        }
    }

    @Test
    fun deletingOneCloneLeavesTheOthersDataIntact() {
        val (doomedProfile, doomed) = newProfile()
        val (_, survivor) = newProfile()

        writeSentinel(doomed, "doomed")
        writeSentinel(survivor, "survivor")

        val result = engine.deleteProfile(doomedProfile, PACKAGE)
        assertTrue("delete returned $result", result is EngineResult.Success)
        createdProfiles.remove(doomedProfile)

        assertEquals("the surviving clone lost its data", "survivor", readSentinel(survivor))
    }

    @Test
    fun containersLiveInsideTheHostSandboxNotTheNormalInstallation() {
        val (_, virtualUserId) = newProfile()

        val container = containerDir(virtualUserId).absolutePath
        assertTrue(
            "container $container is not inside the host's data directory",
            container.startsWith(context.dataDir.absolutePath),
        )
        // The normally installed app keeps its own UID and directory; a clone must never
        // resolve to it.
        assertFalse(
            "a clone resolved to the normal installation's data directory",
            container.startsWith("/data/data/$PACKAGE"),
        )
    }

    private fun waitUntil(timeoutMs: Long, condition: () -> Boolean): Boolean {
        val deadline = System.currentTimeMillis() + timeoutMs
        while (System.currentTimeMillis() < deadline) {
            if (condition()) return true
            Thread.sleep(POLL_INTERVAL_MS)
        }
        return condition()
    }

    private companion object {
        const val PACKAGE = TestAppManager.TEST_APP_PACKAGE
        const val SENTINEL_FILE = "isolation_probe.xml"
        const val LAUNCH_TIMEOUT_MS = 30_000L
        const val POLL_INTERVAL_MS = 250L
    }
}
