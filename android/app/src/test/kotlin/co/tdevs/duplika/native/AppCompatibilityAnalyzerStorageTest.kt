package co.tdevs.duplika.native

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Unit tests for the `MANAGE_EXTERNAL_STORAGE` fallback.
 *
 * Runs on the JVM with no device: [AppCompatibilityAnalyzer.storageFindingFor] is the pure
 * decision with every Android lookup already resolved to a boolean, which is exactly why it
 * was split out of `storageFinding`.
 */
class AppCompatibilityAnalyzerStorageTest {

    private val readStorage = "android.permission.READ_EXTERNAL_STORAGE"
    private val allFiles = "android.permission.MANAGE_EXTERNAL_STORAGE"

    @Test
    fun anAppThatDoesNotTouchSharedStorageIsNeverFlagged() {
        listOf(
            emptySet(),
            setOf("android.permission.INTERNET", "android.permission.CAMERA"),
            // Media-scoped: reached through MediaStore, which does not need All files access.
            setOf("android.permission.READ_MEDIA_IMAGES", "android.permission.READ_MEDIA_VIDEO"),
        ).forEach { requested ->
            assertNull(
                "unexpected finding for $requested",
                AppCompatibilityAnalyzer.storageFindingFor(requested, true, true),
            )
        }
    }

    @Test
    fun aStorageAppIsCleanWhenTheHostDeclaresAndHoldsAllFilesAccess() {
        assertNull(
            AppCompatibilityAnalyzer.storageFindingFor(
                requestedPermissions = setOf(readStorage),
                hostDeclaresAllFilesAccess = true,
                hostHoldsAllFilesAccess = true,
            ),
        )
    }

    @Test
    fun aDeclaredButUngrantedHostAsksTheUserToGrantIt() {
        val finding = AppCompatibilityAnalyzer.storageFindingFor(
            requestedPermissions = setOf(readStorage),
            hostDeclaresAllFilesAccess = true,
            hostHoldsAllFilesAccess = false,
        )

        assertEquals(AppCompatibilityAnalyzer.CODE_STORAGE_NOT_GRANTED, finding?.code)
        assertFalse(finding!!.blocking)
        assertTrue(finding.message.contains("All files access"))
    }

    @Test
    fun thePlayRejectionFallbackBlocksStorageAppsRatherThanLettingThemHang() {
        // The host stopped declaring it, so no clone can ever reach shared storage.
        val finding = AppCompatibilityAnalyzer.storageFindingFor(
            requestedPermissions = setOf(readStorage),
            hostDeclaresAllFilesAccess = false,
            hostHoldsAllFilesAccess = false,
        )

        assertEquals(AppCompatibilityAnalyzer.CODE_STORAGE_UNAVAILABLE, finding?.code)
        assertTrue(finding!!.blocking)
    }

    @Test
    fun aGuestDeclaringAllFilesAccessItselfCountsAsStorageDependent() {
        val finding = AppCompatibilityAnalyzer.storageFindingFor(
            requestedPermissions = setOf(allFiles),
            hostDeclaresAllFilesAccess = false,
            hostHoldsAllFilesAccess = false,
        )

        assertEquals(AppCompatibilityAnalyzer.CODE_STORAGE_UNAVAILABLE, finding?.code)
    }

    @Test
    fun theMissingDeclarationIsCheckedBeforeTheMissingGrant() {
        // Neither declared nor held: the fallback message is the honest one, not "grant it".
        val finding = AppCompatibilityAnalyzer.storageFindingFor(
            requestedPermissions = setOf(readStorage),
            hostDeclaresAllFilesAccess = false,
            hostHoldsAllFilesAccess = false,
        )

        assertEquals(AppCompatibilityAnalyzer.CODE_STORAGE_UNAVAILABLE, finding?.code)
    }
}
