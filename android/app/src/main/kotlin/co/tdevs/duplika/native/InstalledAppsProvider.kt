package co.tdevs.duplika.native

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Base64
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * Enumerates the launchable applications a user may clone.
 *
 * Only publicly documented PackageManager APIs are used, and only metadata a launcher
 * already sees (label, icon, version). No application's private data is read.
 */
class InstalledAppsProvider(private val context: Context) {

    private val packageManager: PackageManager get() = context.packageManager

    /**
     * The same analysis the clone routes run, reused rather than reimplemented here.
     *
     * An app is left out of the list on exactly the conditions that would make creating
     * its clone fail, so the two can never drift apart and say different things about the
     * same app. Built lazily because a listing is the only thing that needs it.
     */
    private val analyzer: AppCompatibilityAnalyzer by lazy { AppCompatibilityAnalyzer(context) }

    /**
     * Launchable apps that can actually be cloned, and a count of the ones left out.
     *
     * In no particular order: the picker sorts and groups the list by whichever of name,
     * install date or update date the user chose, so an order decided here is discarded
     * before anything is drawn.
     *
     * An app the engine could never host — one that asks not to be virtualized, a system
     * component, an app whose native libraries target no ABI the engine can load — is left
     * out rather than listed and then refused. Offering a row that can only fail is worse
     * than not offering it.
     *
     * The count travels with the list because silence was its own problem: an app that is
     * simply absent, with nothing said, reads as a picker that cannot see it. The picker
     * shows the number so a user looking for a missing app learns that the omission was a
     * decision.
     *
     * Icons are expensive, so they are only decoded when [includeIcons] is set.
     */
    fun listLaunchableApps(includeIcons: Boolean = true): Map<String, Any?> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)

        // Everything about this device and this build that every verdict below is measured
        // against, read once. Per app, these were the listing's largest cost.
        val host = analyzer.listingHostState()

        // Every app this pass is not offering, against the reason it is not. Kept rather
        // than tallied because the tally could not answer the only question ever asked of
        // it — a user saying an app is missing, with nothing on record to say whether it
        // was a decision or a defect, or which decision.
        val excluded = sortedMapOf<String, String>()
        val seen = HashSet<String>()
        val apps = packageManager.queryIntentActivities(intent, 0)
            .asSequence()
            .mapNotNull { it.activityInfo?.applicationInfo }
            .filter { seen.add(it.packageName) }
            .filter { it.packageName != context.packageName }
            // Read once, here, and carried through the filter and [describe]. Each of
            // those used to look the package up again, so a device with a couple of
            // hundred launchable apps paid several hundred PackageManager round trips
            // per listing.
            .mapNotNull { info ->
                val packageInfo = analyzer.installedPackageInfo(info.packageName)
                // Uninstalled between the query and this read, or unreadable. Counted
                // with the rest: it is one more row the picker is not offering.
                //
                // Recorded under a real engine code rather than a word of its own: every
                // other entry in this map is one, and a lookalike literal sitting among
                // them reads like a code nobody can find. [installedPackageInfo] has
                // already said which of the two it was, in its own line, when it was the
                // second.
                if (packageInfo == null) {
                    excluded[info.packageName] = EngineErrorCodes.APP_NOT_FOUND
                }
                packageInfo?.let { info to it }
            }
            // The archives likewise: the compatibility verdict and the picker's
            // architecture filter are the same question asked twice, and reading them once
            // for both is what keeps them from answering it differently. The label too —
            // `getApplicationLabel` opens the app's resources, so it is worth reading
            // exactly once per app.
            .map { (info, packageInfo) ->
                Listing(info, packageInfo, label(info), archivesOf(info, packageInfo))
            }
            .filter { listing ->
                // The reason, not just yes or no: it is what the summary below reports,
                // and asking for it is what lets the checks behind it stay silent while a
                // whole device is being judged. See [AppCompatibilityAnalyzer.blockingCode].
                val blocker = analyzer.blockingCode(listing.packageInfo, host, listing.archives)
                if (blocker != null) excluded[listing.packageInfo.packageName] = blocker
                blocker == null
            }
            // Deliberately unsorted. The picker sorts and groups the list itself — by name,
            // by install date or by update date, whichever the user chose — so anything
            // decided here is thrown away before a row is drawn, and sorting several
            // hundred labels to be discarded was the listing paying for a decision it does
            // not get to make.
            .map { describe(it, includeIcons) }
            .toList()

        // Only what is still installed, so an uninstalled app's entry does not outlive it.
        // Written out here rather than per app: one pass, one write.
        //
        // Guarded on having seen anything at all. A pass that enumerated nothing has not
        // discovered that the device has no apps — it has failed to ask — and retaining
        // against an empty set would answer that by throwing the whole cache away and
        // writing an empty file, making the next cold start slow for no reason.
        if (seen.isNotEmpty()) {
            archiveCache.retain(seen)
            archiveCache.flush()
        }

        // Only when the answer is not the one already on record. A listing now runs on
        // every resume and on every package change, and writing the same roster each time
        // filled the diagnostics ring with repetitions of a line that had not changed —
        // crowding out the events someone opens that console to find. Silence here means
        // "exactly as last reported"; anything else is said in full.
        if (excluded.keys != lastExcluded) {
            lastExcluded = excluded.keys.toSet()
            if (excluded.isNotEmpty()) {
                Slog.i(
                    Slog.INSTALL,
                    "Picker: left out ${excluded.size} app(s) that cannot be cloned: " +
                        excluded.entries.joinToString(", ") { "${it.key} (${it.value})" },
                )
            } else {
                Slog.i(Slog.INSTALL, "Picker: every launchable app can be cloned")
            }
        }
        return mapOf("apps" to apps, "hidden" to excluded.size)
    }

    /**
     * The roster the last listing reported, so an unchanged one is not reported again.
     *
     * Null until the first listing, which is what makes a fresh process always say where
     * it stands rather than starting out silent.
     */
    private var lastExcluded: Set<String>? = null

    /** One launchable app, with the lookups a listing would otherwise repeat. */
    private class Listing(
        val info: ApplicationInfo,
        val packageInfo: PackageInfo,
        val label: String,
        /** The app's archives as read once: its `lib/` directories, and whether it has one. */
        val archives: ApkAbis.Archives,
    )

    /**
     * The archive reads this listing does not have to do again. See [ArchiveCache] for
     * what is kept, what invalidates it, and why it is on disk rather than in memory.
     */
    private val archiveCache by lazy {
        ArchiveCache(File(context.filesDir, ARCHIVE_CACHE_FILE))
    }

    private fun archivesOf(info: ApplicationInfo, packageInfo: PackageInfo): ApkAbis.Archives {
        archiveCache.get(info.packageName, packageInfo.lastUpdateTime)?.let { return it }
        val archives = ApkAbis.read(info)
        archiveCache.put(info.packageName, packageInfo.lastUpdateTime, archives)
        return archives
    }

    /**
     * Icons for a specific set of packages.
     *
     * The home screen only needs icons for the handful of apps it has clones of. Decoding
     * every launchable app's icon for that (186 on the test device) cost several hundred
     * dropped frames per refresh.
     */
    fun iconsFor(packageNames: Collection<String>): Map<String, String> {
        val icons = HashMap<String, String>(packageNames.size)
        for (packageName in packageNames.toSet()) {
            val info = try {
                packageManager.getApplicationInfo(packageName, 0)
            } catch (_: PackageManager.NameNotFoundException) {
                continue // A clone of an imported APK has no host install; no icon to show.
            }
            encodeIcon(info)?.let { icons[packageName] = it }
        }
        return icons
    }

    private fun describe(listing: Listing, includeIcons: Boolean): Map<String, Any?> {
        val info = listing.info
        val packageInfo = listing.packageInfo

        // Base plus every split the installer wrote. `splitSourceDirs` is the only
        // public way to count them, and it is null for a plain single-APK install.
        val apkCount = 1 + (info.splitSourceDirs?.size ?: 0)

        return mapOf(
            "packageName" to info.packageName,
            "appName" to listing.label,
            "versionName" to packageInfo.versionName,
            "system" to info.isSystemApp(),
            "abis" to listing.archives.abis.filter { it in ApkAbis.KNOWN },
            "apkCount" to apkCount,
            "firstInstallTime" to packageInfo.firstInstallTime,
            "lastUpdateTime" to packageInfo.lastUpdateTime,
            "icon" to if (includeIcons) encodeIcon(info) else null,
        )
    }

    private fun label(info: ApplicationInfo): String =
        runCatching { packageManager.getApplicationLabel(info).toString() }
            .getOrDefault(info.packageName)

    private fun ApplicationInfo.isSystemApp(): Boolean =
        (flags and (ApplicationInfo.FLAG_SYSTEM or ApplicationInfo.FLAG_UPDATED_SYSTEM_APP)) != 0

    /** Base64 PNG, sized down so a full app list stays cheap to ship over the channel. */
    private fun encodeIcon(info: ApplicationInfo): String? = try {
        val drawable = packageManager.getApplicationIcon(info)
        Base64.encodeToString(drawable.toPngBytes(), Base64.NO_WRAP)
    } catch (error: Throwable) {
        Slog.w(Slog.INSTALL, "Icon decode failed for ${info.packageName}: ${error.message}")
        null
    }

    private fun Drawable.toPngBytes(): ByteArray {
        val bitmap = if (this is BitmapDrawable && bitmap != null) {
            Bitmap.createScaledBitmap(bitmap, ICON_PX, ICON_PX, true)
        } else {
            // Adaptive and vector icons have no backing bitmap; rasterise them.
            Bitmap.createBitmap(ICON_PX, ICON_PX, Bitmap.Config.ARGB_8888).also { output ->
                val canvas = Canvas(output)
                setBounds(0, 0, canvas.width, canvas.height)
                draw(canvas)
            }
        }

        return ByteArrayOutputStream().use { stream ->
            normalise(bitmap).compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        }
    }

    /**
     * Makes every icon occupy the same share of its canvas.
     *
     * Every icon is already rasterised to the same pixel size, but they do not *look*
     * the same size: a legacy icon bakes its own transparent margin into the bitmap,
     * while an adaptive icon drawn without its mask bleeds to the edges. Side by side in
     * a grid the result is Chrome noticeably smaller than Camera, which reads as a
     * rendering bug rather than as the icons' own design.
     *
     * So the transparent border is measured and thrown away, and whatever art is left is
     * scaled to [ART_FRACTION] of the canvas and centred. Aspect ratio is preserved — a
     * wide logo stays wide — so what is equalised is the art's *extent*, not its shape.
     *
     * Returns [source] unchanged when there is nothing to gain: an icon that already
     * fills its canvas, or one that is entirely transparent and has no art to measure.
     */
    private fun normalise(source: Bitmap): Bitmap {
        val width = source.width
        val height = source.height
        if (width <= 0 || height <= 0) return source

        val pixels = IntArray(width * height)
        source.getPixels(pixels, 0, width, 0, 0, width, height)

        var left = width
        var top = height
        var right = -1
        var bottom = -1
        for (y in 0 until height) {
            val row = y * width
            for (x in 0 until width) {
                // Anti-aliased edges leave near-transparent pixels that would defeat the
                // measurement, so only meaningfully opaque ones count as art.
                if ((pixels[row + x] ushr 24) > ALPHA_FLOOR) {
                    if (x < left) left = x
                    if (x > right) right = x
                    if (y < top) top = y
                    if (y > bottom) bottom = y
                }
            }
        }

        if (right < left || bottom < top) return source

        val artWidth = right - left + 1
        val artHeight = bottom - top + 1
        val target = (ICON_PX * ART_FRACTION).toInt()
        val scale = target.toFloat() / maxOf(artWidth, artHeight)

        val drawWidth = (artWidth * scale).toInt().coerceAtLeast(1)
        val drawHeight = (artHeight * scale).toInt().coerceAtLeast(1)
        val offsetX = (ICON_PX - drawWidth) / 2
        val offsetY = (ICON_PX - drawHeight) / 2

        val output = Bitmap.createBitmap(ICON_PX, ICON_PX, Bitmap.Config.ARGB_8888)
        Canvas(output).drawBitmap(
            source,
            Rect(left, top, right + 1, bottom + 1),
            Rect(offsetX, offsetY, offsetX + drawWidth, offsetY + drawHeight),
            Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG),
        )
        return output
    }

    private companion object {
        /** Under `filesDir`, so it is private to the app and cleared with its data. */
        const val ARCHIVE_CACHE_FILE = "picker-archives.tsv"

        const val ICON_PX = 144

        /**
         * How much of the canvas the art fills. Leaves a small margin so a full-bleed
         * square icon does not touch the edges of the plate it is drawn on.
         */
        const val ART_FRACTION = 0.92f

        /** Alpha above which a pixel counts as art rather than as an anti-aliased edge. */
        const val ALPHA_FLOOR = 12
    }
}
