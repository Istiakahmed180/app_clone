package co.tdevs.duplika.native

import android.content.pm.ApplicationInfo
import java.util.zip.ZipFile

/**
 * The single answer to "which CPU architectures does this application ship code for".
 *
 * Read from the archives themselves rather than from [ApplicationInfo.nativeLibraryDir].
 * That field names one ABI at best, and does not exist at all for a package installed with
 * `extractNativeLibs="false"` — which has been the build default for years, so it reports
 * "no native code" for most modern apps. Anything deciding whether a clone can run on that
 * basis would silently stop deciding.
 *
 * Only the zip central directory is touched: entry names, never their contents.
 */
object ApkAbis {

    /**
     * The four ABI directory names Android still ships.
     *
     * Used where the answer is shown to a user — the picker's architecture filter — so a
     * malformed archive cannot invent an architecture the filter has no option for. The
     * compatibility layer deliberately does *not* filter by this: an archive shipping only
     * some architecture nobody has heard of is unsupported, not architecture-free.
     */
    val KNOWN: Set<String> = setOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")

    /**
     * The ABIs the virtualization engine ships native code for.
     *
     * One constant, referenced by both the engine's own availability check and the
     * per-app compatibility verdict. Held apart, the two could come to disagree about
     * what this build can run.
     */
    val ENGINE: Set<String> = setOf("arm64-v8a", "armeabi-v7a")

    /**
     * The [ENGINE] ABIs a device can actually execute, given its `Build.SUPPORTED_ABIS`.
     *
     * The intersection matters for an imported APK: a 32-bit-only archive is loadable by
     * the engine in principle, but a 64-bit-only device (which most phones sold since
     * 2023 are) has no 32-bit runtime to load it into, and calling it supported there
     * promises a clone that can never start.
     */
    fun loadable(deviceAbis: Collection<String>): Set<String> =
        ENGINE.filterTo(LinkedHashSet()) { it in deviceAbis }

    /**
     * What a read of an app's archives found.
     *
     * The two halves are kept apart because "this app ships no native code" and "there was
     * no archive to look in" are different answers that used to arrive as the same empty
     * set. An archived app — Android 15 keeps its launcher entry and deletes its APK —
     * answered the second and was read as the first, which made it look like pure
     * bytecode: clonable anywhere, offered in the picker, and impossible to actually
     * install.
     */
    class Archives internal constructor(
        /** Every `lib/<abi>/` directory name found across the archives that opened. */
        val abis: Set<String>,
        /** Whether the base archive could be opened at all. False when there is none. */
        val baseReadable: Boolean,
    )

    /**
     * An [Archives] rebuilt from values that were read once and kept — see [ArchiveCache].
     *
     * The constructor is not public so that an [Archives] can only otherwise come from an
     * actual read; this is the one deliberate exception, and it is named so a caller
     * cannot reach for it by accident.
     */
    fun archivesOf(abis: Set<String>, baseReadable: Boolean): Archives =
        Archives(abis, baseReadable)

    /** Every `lib/<abi>/` directory name across an installed app's base APK and its splits. */
    fun of(info: ApplicationInfo): Set<String> = read(info).abis

    /** The same read, with the base archive's readability kept rather than discarded. */
    fun read(info: ApplicationInfo): Archives = readArchives(sourcesOf(info))

    /** The same, for one standalone archive. */
    fun ofArchive(apkPath: String): Set<String> = ofArchives(listOf(apkPath))

    /**
     * The union across a set of archives, since a split set puts each ABI in its own APK.
     *
     * An unreadable archive contributes nothing rather than failing the read: a split that
     * cannot be opened must not be able to make an app look architecture-free, and the
     * importer refuses a corrupt archive on its own. The *base* being unreadable is not
     * the same thing, and is reported through [Archives.baseReadable] rather than hidden.
     */
    fun ofArchives(apkPaths: Collection<String>): Set<String> = readArchives(apkPaths).abis

    /** [ofArchives], with the base archive's readability kept. [apkPaths] is base first. */
    fun readArchives(apkPaths: Collection<String>): Archives {
        val found = LinkedHashSet<String>()
        var baseReadable = false
        var base = true

        for (path in apkPaths) {
            val opened = runCatching {
                ZipFile(path).use { zip -> collectAbis(zip, found) }
            }.isSuccess
            if (base) {
                baseReadable = opened
                base = false
            }
            // Every ABI Android ships is accounted for, so nothing is left to learn from
            // the remaining archives. Safe for the compatibility verdict too: a set
            // containing all four already contains one the engine can load.
            if (found.containsAll(KNOWN)) {
                break
            }
        }

        return Archives(found, baseReadable)
    }

    private fun collectAbis(zip: ZipFile, found: MutableSet<String>) {
        val entries = zip.entries()
        while (entries.hasMoreElements()) {
            val name = entries.nextElement().name
            if (!name.startsWith(LIB_PREFIX)) {
                continue
            }
            // `lib/arm64-v8a/libfoo.so`, never `lib/NOTICE`: without the trailing
            // separator a stray file directly under lib/ would be read as an architecture.
            val rest = name.substring(LIB_PREFIX.length)
            val abi = rest.substringBefore('/')
            if (abi.isEmpty() || abi.length == rest.length) {
                continue
            }
            found.add(abi)
            // Nothing left to learn from the remaining entries — which number in the
            // thousands for a large app.
            if (found.containsAll(KNOWN)) {
                return
            }
        }
    }

    private fun sourcesOf(info: ApplicationInfo): List<String> = buildList {
        info.sourceDir?.let(::add)
        info.splitSourceDirs?.forEach { split -> split?.let(::add) }
    }

    private const val LIB_PREFIX = "lib/"
}
