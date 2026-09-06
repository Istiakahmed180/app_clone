package co.tdevs.duplika.native

import android.app.Activity
import android.content.pm.PackageManager
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Covers the consent paths that decide what the user is told.
 *
 * Every case here previously had no coverage at all, and two of them were wrong: a refused
 * request reported success, and an interrupted one never answered.
 *
 * The bridge only ever calls `checkSelfPermission` and `requestPermissions` on the activity
 * it is given, so a stub standing in for one keeps these tests deterministic and free of
 * real system dialogs.
 */
@RunWith(AndroidJUnit4::class)
class PermissionBridgeTest {

    /** Records what the bridge would have asked the system for. */
    private class Asked {
        val permissions = mutableListOf<String>()
        var requestCode: Int = -1

        fun record(perms: Array<String>, code: Int) {
            permissions += perms
            requestCode = code
        }
    }

    private val camera = "android.permission.CAMERA"
    private val audio = "android.permission.RECORD_AUDIO"

    private fun PermissionBridge.requestForTest(
        permissions: List<String>,
        granted: Set<String>,
        asked: Asked = Asked(),
        onResult: (PermissionBridge.Outcome) -> Unit,
    ) = request(
        permissions = permissions,
        isGranted = { it in granted },
        ask = asked::record,
        onResult = onResult,
    )

    @Test
    fun anAlreadyGrantedRequestAnswersImmediatelyWithoutAskingTheUser() {
        val asked = Asked()
        var outcome: PermissionBridge.Outcome? = null

        PermissionBridge().requestForTest(listOf(camera, audio), setOf(camera, audio), asked) {
            outcome = it
        }

        assertTrue(outcome is PermissionBridge.Outcome.Answered)
        assertEquals(
            mapOf(camera to true, audio to true),
            (outcome as PermissionBridge.Outcome.Answered).grants,
        )
        assertTrue("no dialog should have been raised", asked.permissions.isEmpty())
    }

    @Test
    fun anEmptyRequestAnswersImmediately() {
        val asked = Asked()
        var outcome: PermissionBridge.Outcome? = null

        PermissionBridge().requestForTest(emptyList(), emptySet(), asked) { outcome = it }

        assertTrue(outcome is PermissionBridge.Outcome.Answered)
        assertTrue(asked.permissions.isEmpty())
    }

    @Test
    fun onlyPermissionsThatAreMissingAreAskedFor() {
        val asked = Asked()
        PermissionBridge().requestForTest(listOf(camera, audio), setOf(camera), asked) { }

        assertEquals(listOf(audio), asked.permissions)
    }

    /** A second request must not be reported as a completed one. */
    @Test
    fun aSecondRequestWhileOneIsOpenReportsBusyRatherThanSuccess() {
        val asked = Asked()
        val bridge = PermissionBridge()
        var first: PermissionBridge.Outcome? = null
        var second: PermissionBridge.Outcome? = null

        bridge.requestForTest(listOf(camera), emptySet(), asked) { first = it }
        bridge.requestForTest(listOf(audio), emptySet(), asked) { second = it }

        assertEquals(PermissionBridge.Outcome.Busy, second)
        assertNull("the open request must not have been answered", first)
        // The second request must not have reached the user either.
        assertEquals(listOf(camera), asked.permissions)
    }

    /** The path that used to hang the caller forever. */
    @Test
    fun cancellingAnOpenRequestAnswersItAsCancelled() {
        val bridge = PermissionBridge()
        var outcome: PermissionBridge.Outcome? = null

        bridge.requestForTest(listOf(camera), emptySet()) { outcome = it }
        assertNull(outcome)

        bridge.cancelPending()

        assertEquals(PermissionBridge.Outcome.Cancelled, outcome)
    }

    @Test
    fun cancellingWithNothingOpenIsHarmless() {
        PermissionBridge().cancelPending()
    }

    @Test
    fun aCancelledRequestIsNotAnsweredAgainByALateSystemResult() {
        val asked = Asked()
        val bridge = PermissionBridge()
        val outcomes = mutableListOf<PermissionBridge.Outcome>()

        bridge.requestForTest(listOf(camera), emptySet(), asked) { outcomes += it }
        bridge.cancelPending()

        val consumed = bridge.onRequestPermissionsResult(
            asked.requestCode,
            arrayOf(camera),
            intArrayOf(PackageManager.PERMISSION_GRANTED),
        )

        assertTrue("the bridge still owns its request code", consumed)
        assertEquals("the caller was answered twice", 1, outcomes.size)
        assertEquals(PermissionBridge.Outcome.Cancelled, outcomes.single())
    }

    @Test
    fun aSystemResultIsMappedPerPermission() {
        val asked = Asked()
        val bridge = PermissionBridge()
        var outcome: PermissionBridge.Outcome? = null

        bridge.requestForTest(listOf(camera, audio), emptySet(), asked) { outcome = it }
        bridge.onRequestPermissionsResult(
            asked.requestCode,
            arrayOf(camera, audio),
            intArrayOf(PackageManager.PERMISSION_GRANTED, PackageManager.PERMISSION_DENIED),
        )

        assertTrue(outcome is PermissionBridge.Outcome.Answered)
        assertEquals(
            mapOf(camera to true, audio to false),
            (outcome as PermissionBridge.Outcome.Answered).grants,
        )
    }

    /**
     * The production entry point, not the test seam.
     *
     * The other cases go through the injectable overload, so the two lines that wire an
     * Activity into it were themselves uncovered. `requestPermissions` is final and cannot
     * be stubbed, but `checkSelfPermission` can — and for an already-granted request the
     * bridge never asks, so this path exercises the real wiring end to end.
     */
    @Test
    fun theActivityOverloadUsesTheActivitysOwnPermissionState() {
        var outcome: PermissionBridge.Outcome? = null

        // Activity's constructor builds a Handler, so it needs a Looper.
        InstrumentationRegistry.getInstrumentation().runOnMainSync {
            val activity = object : Activity() {
                override fun checkSelfPermission(permission: String): Int =
                    PackageManager.PERMISSION_GRANTED
            }
            PermissionBridge().request(activity, listOf(camera, audio)) { outcome = it }
        }

        assertTrue(outcome is PermissionBridge.Outcome.Answered)
        assertEquals(
            mapOf(camera to true, audio to true),
            (outcome as PermissionBridge.Outcome.Answered).grants,
        )
    }

    @Test
    fun anotherComponentsRequestCodeIsLeftAlone() {
        val bridge = PermissionBridge()
        var outcome: PermissionBridge.Outcome? = null
        bridge.requestForTest(listOf(camera), emptySet()) { outcome = it }

        val consumed = bridge.onRequestPermissionsResult(
            /* requestCode = */ 4321,
            arrayOf(camera),
            intArrayOf(PackageManager.PERMISSION_GRANTED),
        )

        assertEquals(false, consumed)
        assertNull("an unrelated result must not answer our request", outcome)
    }
}

/**
 * What the user is finally told.
 *
 * `permissionEnvelope` is where the original defect lived: a refused request was turned
 * into a success envelope, so the UI reported a decision the user never made. The three
 * outcomes must stay distinguishable at the channel boundary.
 */
@RunWith(AndroidJUnit4::class)
class PermissionEnvelopeTest {

    private val context: android.content.Context =
        androidx.test.core.app.ApplicationProvider.getApplicationContext()
    private val bridge = NativeBridge(context)
    private val report = AppCompatibilityAnalyzer(context).analyze(TestAppManager.TEST_APP_PACKAGE)

    @Test
    fun anAnsweredRequestSucceedsAndSplitsGrantedFromDenied() {
        val envelope = bridge.permissionEnvelope(
            report,
            PermissionBridge.Outcome.Answered(
                mapOf(
                    "android.permission.CAMERA" to true,
                    "android.permission.RECORD_AUDIO" to false,
                ),
            ),
        )

        assertEquals(true, envelope["success"])
        assertEquals("PERMISSIONS_REQUESTED", envelope["code"])

        @Suppress("UNCHECKED_CAST")
        val data = envelope["data"] as Map<String, Any?>
        assertEquals(listOf("android.permission.CAMERA"), data["granted"])
        assertEquals(listOf("android.permission.RECORD_AUDIO"), data["denied"])
    }

    @Test
    fun aBusyRequestIsAFailureNotASuccess() {
        val envelope = bridge.permissionEnvelope(report, PermissionBridge.Outcome.Busy)

        assertEquals(false, envelope["success"])
        assertEquals("PERMISSION_REQUEST_IN_PROGRESS", envelope["code"])
    }

    @Test
    fun aCancelledRequestIsAFailureNotASuccess() {
        val envelope = bridge.permissionEnvelope(report, PermissionBridge.Outcome.Cancelled)

        assertEquals(false, envelope["success"])
        assertEquals("PERMISSION_REQUEST_CANCELLED", envelope["code"])
    }
}
