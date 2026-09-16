package co.tdevs.duplika.native

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Unit tests for the ABI decision behind the `ABI_NOT_SUPPORTED` finding.
 *
 * Runs on the JVM with no device: [AppCompatibilityAnalyzer.engineAbiOf] and
 * [ApkAbis.loadable] are the pure halves of it, with the archive read and the device's own
 * architectures already resolved to sets.
 *
 * The distinction worth protecting is between "no native code" and "native code this
 * engine cannot load". Both come back without a usable ABI, and only the second is a
 * reason to refuse the clone: conflating them would either block every pure-bytecode app
 * or silently offer clones that cannot start.
 */
class AppCompatibilityAnalyzerAbiTest {

    /** A 64-bit device that still carries a 32-bit runtime. */
    private val armDevice = ApkAbis.loadable(listOf("arm64-v8a", "armeabi-v7a"))

    @Test
    fun anArchiveWithNoNativeCodeHasNoAbiRatherThanAnUnsupportedOne() {
        // Pure bytecode runs anywhere, so this must not read as a refusal.
        assertNull(AppCompatibilityAnalyzer.engineAbiOf(emptySet(), armDevice))
    }

    @Test
    fun anArchiveTheEngineCanLoadReportsTheAbiItShips() {
        assertEquals(
            "arm64-v8a",
            AppCompatibilityAnalyzer.engineAbiOf(setOf("arm64-v8a"), armDevice),
        )
        assertEquals(
            "armeabi-v7a",
            AppCompatibilityAnalyzer.engineAbiOf(setOf("armeabi-v7a"), armDevice),
        )
    }

    @Test
    fun anArchiveShippingOnlyAbisTheEngineCannotLoadIsMarkedUnsupported() {
        assertEquals(
            AppCompatibilityAnalyzer.UNSUPPORTED_ABI,
            AppCompatibilityAnalyzer.engineAbiOf(setOf("x86", "x86_64", "riscv64"), armDevice),
        )
    }

    @Test
    fun aSupportedAbiIsFoundEvenWhenTheArchiveAlsoShipsOthers() {
        // A fat APK is loadable as long as one of its ABIs is, so the unsupported
        // siblings must not decide the answer.
        assertEquals(
            "arm64-v8a",
            AppCompatibilityAnalyzer.engineAbiOf(setOf("x86_64", "arm64-v8a", "x86"), armDevice),
        )
    }

    @Test
    fun everyAbiTheEngineDeclaresIsAcceptedOnItsOwn() {
        // Guards the two constants against drifting apart: whatever ApkAbis.ENGINE holds
        // must be accepted, or the listing would refuse an app the engine can host.
        ApkAbis.ENGINE.forEach { abi ->
            assertEquals(abi, AppCompatibilityAnalyzer.engineAbiOf(setOf(abi), armDevice))
        }
    }

    // -------------------------------------------------------------------------------
    // What the device itself can run
    // -------------------------------------------------------------------------------

    @Test
    fun aDeviceWithNo32BitRuntimeCannotLoad32BitArchives() {
        // Most phones sold since 2023 are arm64-only. The engine can load armeabi-v7a in
        // principle, but there is nothing here to load it into, and an imported 32-bit APK
        // called supported would promise a clone that can never start.
        val arm64Only = ApkAbis.loadable(listOf("arm64-v8a"))

        assertEquals(
            AppCompatibilityAnalyzer.UNSUPPORTED_ABI,
            AppCompatibilityAnalyzer.engineAbiOf(setOf("armeabi-v7a"), arm64Only),
        )
        assertEquals(
            "arm64-v8a",
            AppCompatibilityAnalyzer.engineAbiOf(setOf("arm64-v8a", "armeabi-v7a"), arm64Only),
        )
    }

    @Test
    fun aDeviceTheEngineDoesNotSupportLoadsNothing() {
        val x86Only = ApkAbis.loadable(listOf("x86_64", "x86"))

        assertTrue(x86Only.isEmpty())
        assertEquals(
            AppCompatibilityAnalyzer.UNSUPPORTED_ABI,
            AppCompatibilityAnalyzer.engineAbiOf(setOf("arm64-v8a"), x86Only),
        )
        // Still not a refusal for an app that ships no native code at all: the engine's own
        // availability check is what speaks for a device it cannot run on.
        assertNull(AppCompatibilityAnalyzer.engineAbiOf(emptySet(), x86Only))
    }

    @Test
    fun engineAbisAreAllKnownAbis() {
        // The picker labels an app's architectures from ApkAbis.KNOWN, so anything the
        // engine claims to load must be nameable there.
        assertTrue(ApkAbis.KNOWN.containsAll(ApkAbis.ENGINE))
    }
}
