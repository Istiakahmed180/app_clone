package co.tdevs.duplika.native

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

/**
 * What the picker is allowed to remember between listings, and what it must not.
 *
 * The cache exists to spare a cold start the cost of opening every installed APK, so the
 * tests that matter are the ones about *not* trusting it: a stale stamp, a file from a
 * different version of this code, a line that was cut off by a process death.
 */
class ArchiveCacheTest {

    @get:Rule
    val folder = TemporaryFolder()

    private fun cacheFile() = File(folder.root, "picker-archives.tsv")

    private fun archives(vararg abis: String, readable: Boolean = true) =
        ApkAbis.archivesOf(abis.toSet(), readable)

    @Test
    fun `remembers a read within one instance`() {
        val cache = ArchiveCache(cacheFile())
        cache.put("com.example", 100L, archives("arm64-v8a"))

        val found = cache.get("com.example", 100L)

        assertEquals(setOf("arm64-v8a"), found?.abis)
        assertTrue(found?.baseReadable == true)
    }

    @Test
    fun `a package that has been updated since is not answered from the cache`() {
        // The whole invalidation rule: an app that updated may ship different native code,
        // and answering from the old read is how a picker shows a stale architecture.
        val cache = ArchiveCache(cacheFile())
        cache.put("com.example", 100L, archives("arm64-v8a"))

        assertNull(cache.get("com.example", 101L))
    }

    @Test
    fun `an unknown package is not answered`() {
        assertNull(ArchiveCache(cacheFile()).get("com.example", 100L))
    }

    @Test
    fun `survives to the next process`() {
        // The point of the file: the *first* listing after a cold start is the one the
        // user waits for, and an in-memory cache does nothing for it.
        val first = ArchiveCache(cacheFile())
        first.put("com.example", 100L, archives("arm64-v8a", "armeabi-v7a"))
        first.flush()

        val second = ArchiveCache(cacheFile())

        assertEquals(setOf("arm64-v8a", "armeabi-v7a"), second.get("com.example", 100L)?.abis)
    }

    @Test
    fun `an unreadable archive is remembered as unreadable`() {
        val first = ArchiveCache(cacheFile())
        first.put("com.archived", 100L, archives(readable = false))
        first.flush()

        val found = ArchiveCache(cacheFile()).get("com.archived", 100L)

        assertTrue(found?.abis?.isEmpty() == true)
        assertFalse(found?.baseReadable == true)
    }

    @Test
    fun `an app with no native code survives the round trip as readable`() {
        // The pair above and this one are the two answers the file has to keep apart.
        val first = ArchiveCache(cacheFile())
        first.put("com.bytecode", 100L, archives(readable = true))
        first.flush()

        val found = ArchiveCache(cacheFile()).get("com.bytecode", 100L)

        assertTrue(found?.abis?.isEmpty() == true)
        assertTrue(found?.baseReadable == true)
    }

    @Test
    fun `retain drops packages the listing no longer saw`() {
        val cache = ArchiveCache(cacheFile())
        cache.put("com.kept", 100L, archives("arm64-v8a"))
        cache.put("com.uninstalled", 100L, archives("arm64-v8a"))

        cache.retain(setOf("com.kept"))
        cache.flush()

        val reloaded = ArchiveCache(cacheFile())
        assertEquals(setOf("arm64-v8a"), reloaded.get("com.kept", 100L)?.abis)
        assertNull(reloaded.get("com.uninstalled", 100L))
    }

    @Test
    fun `a file from another version of this code is ignored rather than guessed at`() {
        cacheFile().writeText("duplika-archive-cache\t99\ncom.example\t100\t1\tarm64-v8a\n")

        assertNull(ArchiveCache(cacheFile()).get("com.example", 100L))
    }

    @Test
    fun `a truncated last line loses that entry and no other`() {
        // What a process killed mid-write would leave behind if the rename had not saved
        // it. Losing one entry costs one archive read; refusing the file costs all of them.
        val cache = ArchiveCache(cacheFile())
        cache.put("com.complete", 100L, archives("arm64-v8a"))
        cache.flush()
        cacheFile().appendText("com.truncated\t100\t1")

        val reloaded = ArchiveCache(cacheFile())

        assertEquals(setOf("arm64-v8a"), reloaded.get("com.complete", 100L)?.abis)
        assertNull(reloaded.get("com.truncated", 100L))
    }

    @Test
    fun `a corrupt file loses the cache and nothing else`() {
        cacheFile().writeText("this is not a cache")

        assertNull(ArchiveCache(cacheFile()).get("com.example", 100L))
    }

    @Test
    fun `a missing file is not an error`() {
        assertNull(ArchiveCache(File(folder.root, "never-written.tsv")).get("com.example", 1L))
    }

    @Test
    fun `a clean pass writes nothing`() {
        val cache = ArchiveCache(cacheFile())

        cache.flush()

        assertFalse(cacheFile().exists())
    }
}
