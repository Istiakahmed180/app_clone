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
     * Launchable apps that can actually be cloned, user-installed first, alphabetically
     * within each group, and a count of the ones left out.
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

        var hidden = 0
        val seen = HashSet<String>()
        val apps = packageManager.queryIntentActivities(intent, 0)
            .asSequence()
            .mapNotNull { it.activityInfo?.applicationInfo }
            .filter { seen.add(it.packageName) }
            .filter { it.packageName != context.packageName }
            // Read once, here, and carried through the filter, the sort and [describe].
            // Each of those used to look the package up again, so a device with a couple
            // of hundred launchable apps paid several hundred PackageManager round trips
            // per listing.
            .mapNotNull { info ->
                val packageInfo = analyzer.installedPackageInfo(info.packageName)
                // Uninstalled between the query and this read. Counted with the rest:
                // it is one more row the picker is not offering.
                if (packageInfo == null) hidden++
                packageInfo?.let { info to it }
            }
            // The ABIs likewise: the compatibility verdict and the picker's architecture
            // filter are the same question asked twice, and reading the archives once for
            // both is what keeps them from answering it differently.
            //
            // The label for a sharper reason still: `compareBy` runs its selectors on
            // every comparison, so a label read inside the comparator was thousands of
            // `getApplicationLabel` calls — each one opening the app's resources — where
            // one per app is enough.
            .map { (info, packageInfo) ->
                Listing(info, packageInfo, label(info), ApkAbis.of(info))
            }
            .filter { listing ->
                val allowed = listing.packageInfo != null &&
                    analyzer.canClone(listing.packageInfo, host, listing.abis)
                if (!allowed) hidden++
                allowed
            }
            .sortedWith(
                compareBy(
                    { it.info.isSystemApp() },
                    { it.sortKey },
                ),
            )
            .map { describe(it, includeIcons) }
            .toList()

        if (hidden > 0) {
            Slog.i(Slog.INSTALL, "Picker: left out $hidden app(s) that cannot be cloned")
        }
        return mapOf("apps" to apps, "hidden" to hidden)
    }

    /** One launchable app, with the lookups a listing would otherwise repeat. */
    private class Listing(
        val info: ApplicationInfo,
        /** Null only on the single-package path, where the record is read defensively. */
        val packageInfo: PackageInfo?,
        val label: String,
        /** Every `lib/<abi>/` directory the app's APKs carry, read once. */
        val abis: Set<String>,
    ) {
        /** Folded once rather than per comparison, for the same reason as [label]. */
        val sortKey: String = label.lowercase()
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

    fun describeInstalled(packageName: String, includeIcons: Boolean = true): Map<String, Any?>? {
        val info = try {
            packageManager.getApplicationInfo(packageName, 0)
        } catch (_: PackageManager.NameNotFoundException) {
            return null
        }
        val packageInfo = runCatching {
            packageManager.getPackageInfo(packageName, 0)
        }.getOrNull()
        return describe(Listing(info, packageInfo, label(info), ApkAbis.of(info)), includeIcons)
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
            "versionName" to packageInfo?.versionName,
            "system" to info.isSystemApp(),
            "abis" to listing.abis.filter { it in ApkAbis.KNOWN },
            "apkCount" to apkCount,
            "firstInstallTime" to packageInfo?.firstInstallTime,
            "lastUpdateTime" to packageInfo?.lastUpdateTime,
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
