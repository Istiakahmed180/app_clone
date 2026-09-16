package co.tdevs.duplika.native

import android.os.Build
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
    private val writeStorage = "android.permission.WRITE_EXTERNAL_STORAGE"
    private val allFiles = "android.permission.MANAGE_EXTERNAL_STORAGE"

    /** Android 11, where the legacy read still reaches the shared tree. */
    private val androidR = Build.VERSION_CODES.R

    /** Android 13, where it does not. */
    private val androidT = Build.VERSION_CODES.TIRAMISU

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
                AppCompatibilityAnalyzer.storageFindingFor(requested, true, true, androidT),
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
                deviceSdk = androidR,
            ),
        )
    }

    @Test
    fun aDeclaredButUngrantedHostAsksTheUserToGrantIt() {
        val finding = AppCompatibilityAnalyzer.storageFindingFor(
            requestedPermissions = setOf(readStorage),
            hostDeclaresAllFilesAccess = true,
            hostHoldsAllFilesAccess = false,
            deviceSdk = androidR,
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
            deviceSdk = androidR,
        )

        assertEquals(AppCompatibilityAnalyzer.CODE_STORAGE_UNAVAILABLE, finding?.code)
        assertTrue(finding!!.blocking)
    }

    @Test
    fun aGuestDeclaringAllFilesAccessItselfCountsAsStorageDependentOnEveryVersion() {
        listOf(Build.VERSION_CODES.Q, androidR, androidT).forEach { sdk ->
            val finding = AppCompatibilityAnalyzer.storageFindingFor(
                requestedPermissions = setOf(allFiles),
                hostDeclaresAllFilesAccess = false,
                hostHoldsAllFilesAccess = false,
                deviceSdk = sdk,
            )

            assertEquals(
                "wrong finding on API $sdk",
                AppCompatibilityAnalyzer.CODE_STORAGE_UNAVAILABLE,
                finding?.code,
            )
        }
    }

    @Test
    fun theMissingDeclarationIsCheckedBeforeTheMissingGrant() {
        // Neither declared nor held: the fallback message is the honest one, not "grant it".
        val finding = AppCompatibilityAnalyzer.storageFindingFor(
            requestedPermissions = setOf(readStorage),
            hostDeclaresAllFilesAccess = false,
            hostHoldsAllFilesAccess = false,
            deviceSdk = androidR,
        )

        assertEquals(AppCompatibilityAnalyzer.CODE_STORAGE_UNAVAILABLE, finding?.code)
    }

    // -------------------------------------------------------------------------------
    // The legacy declarations, which `requestedPermissions` reports verbatim
    // -------------------------------------------------------------------------------

    @Test
    fun theLegacyWriteDeclarationIsNotStorageDependenceFromAndroid11() {
        // `WRITE_EXTERNAL_STORAGE`, almost always declared with `maxSdkVersion="28"`, grants
        // nothing from API 30 on. Counting it flagged a large share of ordinary apps, and in
        // a build without All files access it would have dropped them from the picker.
        listOf(androidR, androidT).forEach { sdk ->
            assertNull(
                "unexpected finding on API $sdk",
                AppCompatibilityAnalyzer.storageFindingFor(
                    requestedPermissions = setOf(writeStorage),
                    hostDeclaresAllFilesAccess = false,
                    hostHoldsAllFilesAccess = false,
                    deviceSdk = sdk,
                ),
            )
        }
    }

    @Test
    fun theLegacyReadDeclarationIsNotStorageDependenceFromAndroid13() {
        // Replaced by the media permissions, which are scoped and need nothing from the host.
        assertNull(
            AppCompatibilityAnalyzer.storageFindingFor(
                requestedPermissions = setOf(readStorage, writeStorage),
                hostDeclaresAllFilesAccess = false,
                hostHoldsAllFilesAccess = false,
                deviceSdk = androidT,
            ),
        )
    }

    @Test
    fun bothLegacyDeclarationsStillCountBelowAndroid11() {
        // Where they are real, they are still the thing being asked about.
        listOf(readStorage, writeStorage).forEach { permission ->
            assertEquals(
                "wrong finding for $permission",
                AppCompatibilityAnalyzer.CODE_STORAGE_NOT_GRANTED,
                AppCompatibilityAnalyzer.storageFindingFor(
                    requestedPermissions = setOf(permission),
                    hostDeclaresAllFilesAccess = true,
                    hostHoldsAllFilesAccess = false,
                    deviceSdk = Build.VERSION_CODES.Q,
                )?.code,
            )
        }
    }
}
