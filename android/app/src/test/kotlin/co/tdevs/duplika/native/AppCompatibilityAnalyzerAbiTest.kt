package co.tdevs.duplika.native

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * Unit tests for the ABI decision behind the `ABI_NOT_SUPPORTED` finding.
 *
 * Runs on the JVM with no device: [AppCompatibilityAnalyzer.engineAbiOf] and
 * [AppCompatibilityAnalyzer.engineAbiForLibraryDir] are the pure halves of the two
 * routes to an ABI — an archive's own `lib/` entries, and an installed package's
 * `nativeLibraryDir`.
 *
 * The distinction worth protecting is between "no native code" and "native code this
 * engine cannot load". Both come back without a usable ABI, and only the second is a
 * reason to refuse the clone: conflating them would either block every pure-bytecode app
 * or silently offer clones that cannot start.
 */
class AppCompatibilityAnalyzerAbiTest {

    @Test
    fun anArchiveWithNoNativeCodeHasNoAbiRatherThanAnUnsupportedOne() {
        // Pure bytecode runs anywhere, so this must not read as a refusal.
        assertNull(AppCompatibilityAnalyzer.engineAbiOf(emptySet()))
    }

    @Test
    fun anArchiveTheEngineCanLoadReportsTheAbiItShips() {
        assertEquals(
            "arm64-v8a",
            AppCompatibilityAnalyzer.engineAbiOf(setOf("arm64-v8a")),
        )
        assertEquals(
            "armeabi-v7a",
            AppCompatibilityAnalyzer.engineAbiOf(setOf("armeabi-v7a")),
        )
    }

    @Test
    fun anArchiveShippingOnlyAbisTheEngineCannotLoadIsMarkedUnsupported() {
        assertEquals(
            AppCompatibilityAnalyzer.UNSUPPORTED_ABI,
            AppCompatibilityAnalyzer.engineAbiOf(setOf("x86", "x86_64", "riscv64")),
        )
    }

    @Test
    fun aSupportedAbiIsFoundEvenWhenTheArchiveAlsoShipsOthers() {
        // A fat APK is loadable as long as one of its ABIs is, so the unsupported
        // siblings must not decide the answer.
        assertEquals(
            "arm64-v8a",
            AppCompatibilityAnalyzer.engineAbiOf(setOf("x86_64", "arm64-v8a", "x86")),
        )
    }

    @Test
    fun everyAbiTheEngineDeclaresIsAcceptedOnItsOwn() {
        // Guards the two constants against drifting apart: whatever ENGINE_ABIS holds
        // must be accepted, or the listing would refuse an app the engine can host.
        AppCompatibilityAnalyzer.ENGINE_ABIS.forEach { abi ->
            assertEquals(abi, AppCompatibilityAnalyzer.engineAbiOf(setOf(abi)))
        }
    }

    @Test
    fun anInstalledPackageIsReadFromTheFamilyNameAndroidUsesForTheDirectory() {
        // Android names the directory after the family, not the ABI, and this mapping is
        // the only thing that turns one back into the other.
        assertEquals(
            "arm64-v8a",
            AppCompatibilityAnalyzer.engineAbiForLibraryDir("/data/app/~~abc==/com.example-1/lib/arm64"),
        )
        assertEquals(
            "armeabi-v7a",
            AppCompatibilityAnalyzer.engineAbiForLibraryDir("/data/app/~~abc==/com.example-1/lib/arm"),
        )
    }

    @Test
    fun anInstalledPackageOnAnArchitectureTheEngineDoesNotLoadHasNoAbi() {
        listOf(
            "/data/app/com.example-1/lib/x86",
            "/data/app/com.example-1/lib/x86_64",
            "/data/app/com.example-1/lib/riscv64",
        ).forEach { dir ->
            assertNull("unexpected ABI for $dir", AppCompatibilityAnalyzer.engineAbiForLibraryDir(dir))
        }
    }

    @Test
    fun aPackageWithoutANativeLibraryDirectoryHasNoAbi() {
        assertNull(AppCompatibilityAnalyzer.engineAbiForLibraryDir(null))
        assertNull(AppCompatibilityAnalyzer.engineAbiForLibraryDir(""))
    }
}
