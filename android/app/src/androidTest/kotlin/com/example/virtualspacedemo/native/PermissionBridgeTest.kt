package com.example.virtualspacedemo.native

import android.content.pm.PackageManager
import androidx.test.ext.junit.runners.AndroidJUnit4
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
