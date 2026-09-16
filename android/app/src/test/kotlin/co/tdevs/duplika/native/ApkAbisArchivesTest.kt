package co.tdevs.duplika.native

import java.io.File
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

/**
 * The half of the archive read that has nothing to do with Android: given these files on
 * disk, what does the picker conclude about them.
 *
 * [ApkAbis.readArchives] takes paths and uses `java.util.zip`, so the interesting cases —
 * a base that will not open, an ABI that lives only in a split — are reachable without a
 * device. The cases this covers are the ones that were being answered wrongly: an archive
 * that could not be read reported the same empty ABI set as an app that genuinely ships
 * no native code, and the two mean opposite things to the compatibility verdict.
 */
class ApkAbisArchivesTest {

    @get:Rule
    val folder = TemporaryFolder()

    private fun apk(name: String, vararg entries: String): File =
        File(folder.root, name).also { file ->
            ZipOutputStream(file.outputStream()).use { zip ->
                for (entry in entries) {
                    zip.putNextEntry(ZipEntry(entry))
                    zip.write(byteArrayOf(0))
                    zip.closeEntry()
                }
            }
        }

    @Test
    fun `reads the abi directories out of a base apk`() {
        val base = apk("base.apk", "classes.dex", "lib/arm64-v8a/libfoo.so")

        val archives = ApkAbis.readArchives(listOf(base.path))

        assertEquals(setOf("arm64-v8a"), archives.abis)
        assertTrue(archives.baseReadable)
    }

    @Test
    fun `an app with no native code is readable and architecture-free`() {
        // The distinction this whole type exists for: nothing found, but looked at.
        val base = apk("base.apk", "classes.dex", "AndroidManifest.xml")

        val archives = ApkAbis.readArchives(listOf(base.path))

        assertTrue(archives.abis.isEmpty())
        assertTrue(archives.baseReadable)
    }

    @Test
    fun `a base that is not there is not architecture-free`() {
        // What an archived app looks like: the package record survives, the APK does not.
        // Reported as "no native code" this was offered in the picker as clonable.
        val archives = ApkAbis.readArchives(listOf(File(folder.root, "gone.apk").path))

        assertTrue(archives.abis.isEmpty())
        assertFalse(archives.baseReadable)
    }

    @Test
    fun `a base that is not a zip is not readable`() {
        val corrupt = File(folder.root, "corrupt.apk").also { it.writeText("not a zip") }

        assertFalse(ApkAbis.readArchives(listOf(corrupt.path)).baseReadable)
    }

    @Test
    fun `no archives at all is not readable`() {
        assertFalse(ApkAbis.readArchives(emptyList()).baseReadable)
    }

    @Test
    fun `an abi that lives only in a split is still found`() {
        // An app bundle puts native code in a `config.<abi>` split, so the base alone
        // finds no lib/ alone and would call the whole app pure bytecode.
        val base = apk("base.apk", "classes.dex")
        val split = apk("split_config.arm64_v8a.apk", "lib/arm64-v8a/libfoo.so")

        val archives = ApkAbis.readArchives(listOf(base.path, split.path))

        assertEquals(setOf("arm64-v8a"), archives.abis)
        assertTrue(archives.baseReadable)
    }

    @Test
    fun `a split that will not open cannot make the base look unreadable`() {
        val base = apk("base.apk", "lib/armeabi-v7a/libfoo.so")

        val archives = ApkAbis.readArchives(
            listOf(base.path, File(folder.root, "missing_split.apk").path),
        )

        assertEquals(setOf("armeabi-v7a"), archives.abis)
        assertTrue(archives.baseReadable)
    }

    @Test
    fun `a file directly under lib is not read as an architecture`() {
        val base = apk("base.apk", "lib/NOTICE", "lib/arm64-v8a/libfoo.so")

        assertEquals(setOf("arm64-v8a"), ApkAbis.readArchives(listOf(base.path)).abis)
    }

    @Test
    fun `every known abi in the base stops the read before the splits`() {
        val base = apk(
            "base.apk",
            "lib/arm64-v8a/a.so",
            "lib/armeabi-v7a/a.so",
            "lib/x86_64/a.so",
            "lib/x86/a.so",
        )
        // Unreadable, and never reached: the base already answered the whole question.
        val split = File(folder.root, "unreadable_split.apk").path

        val archives = ApkAbis.readArchives(listOf(base.path, split))

        assertEquals(ApkAbis.KNOWN, archives.abis)
        assertTrue(archives.baseReadable)
    }
}
