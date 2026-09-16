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

    /** Every `lib/<abi>/` directory name across an installed app's base APK and its splits. */
    fun of(info: ApplicationInfo): Set<String> = ofArchives(sourcesOf(info))

    /** The same, for one standalone archive. */
    fun ofArchive(apkPath: String): Set<String> = ofArchives(listOf(apkPath))

    /**
     * The union across a set of archives, since a split set puts each ABI in its own APK.
     *
     * An unreadable archive contributes nothing rather than failing the read: a split that
     * cannot be opened must not be able to make an app look architecture-free, and the
     * importer refuses a corrupt archive on its own.
     */
    fun ofArchives(apkPaths: Collection<String>): Set<String> {
        val found = LinkedHashSet<String>()
        for (path in apkPaths) {
            runCatching {
                ZipFile(path).use { zip ->
                    val entries = zip.entries()
                    while (entries.hasMoreElements()) {
                        val name = entries.nextElement().name
                        if (!name.startsWith(LIB_PREFIX)) {
                            continue
                        }
                        // `lib/arm64-v8a/libfoo.so`, never `lib/NOTICE`: without the
                        // trailing separator a stray file directly under lib/ would be
                        // read as an architecture.
                        val rest = name.substring(LIB_PREFIX.length)
                        val abi = rest.substringBefore('/')
                        if (abi.isEmpty() || abi.length == rest.length) {
                            continue
                        }
                        found.add(abi)
                        // Every ABI Android ships is accounted for, so nothing is left to
                        // learn from the remaining entries — which number in the thousands
                        // for a large app. Safe for the compatibility verdict too: a set
                        // containing all four already contains one the engine can load.
                        if (found.containsAll(KNOWN)) {
                            return found
                        }
                    }
                }
            }
        }
        return found
    }

    private fun sourcesOf(info: ApplicationInfo): List<String> = buildList {
        info.sourceDir?.let(::add)
        info.splitSourceDirs?.forEach { split -> split?.let(::add) }
    }

    private const val LIB_PREFIX = "lib/"
}
