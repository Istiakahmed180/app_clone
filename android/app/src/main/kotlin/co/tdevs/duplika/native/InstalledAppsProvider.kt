package co.tdevs.duplika.native

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Base64
import java.io.ByteArrayOutputStream
import java.util.zip.ZipFile

/**
 * Enumerates the launchable applications a user may clone.
 *
 * Only publicly documented PackageManager APIs are used, and only metadata a launcher
 * already sees (label, icon, version). No application's private data is read.
 */
class InstalledAppsProvider(private val context: Context) {

    private val packageManager: PackageManager get() = context.packageManager

    /**
     * Launchable apps, user-installed first, alphabetically within each group.
     *
     * Icons are expensive, so they are only decoded when [includeIcons] is set.
     */
    fun listLaunchableApps(includeIcons: Boolean = true): List<Map<String, Any?>> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)

        val seen = HashSet<String>()
        return packageManager.queryIntentActivities(intent, 0)
            .asSequence()
            .mapNotNull { it.activityInfo?.applicationInfo }
            .filter { seen.add(it.packageName) }
            .filter { it.packageName != context.packageName }
            .sortedWith(
                compareBy(
                    { it.isSystemApp() },
                    { label(it).lowercase() },
                ),
            )
            .map { info -> describe(info, includeIcons) }
            .toList()
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
        return describe(info, includeIcons)
    }

    private fun describe(info: ApplicationInfo, includeIcons: Boolean): Map<String, Any?> {
        val packageInfo = runCatching {
            packageManager.getPackageInfo(info.packageName, 0)
        }.getOrNull()

        // Base plus every split the installer wrote. `splitSourceDirs` is the only
        // public way to count them, and it is null for a plain single-APK install.
        val apkCount = 1 + (info.splitSourceDirs?.size ?: 0)

        return mapOf(
            "packageName" to info.packageName,
            "appName" to label(info),
            "versionName" to packageInfo?.versionName,
            "system" to info.isSystemApp(),
            "abis" to abisOf(info),
            "apkCount" to apkCount,
            "firstInstallTime" to packageInfo?.firstInstallTime,
            "lastUpdateTime" to packageInfo?.lastUpdateTime,
            "icon" to if (includeIcons) encodeIcon(info) else null,
        )
    }

    /**
     * The ABI directories this package actually ships native code for.
     *
     * Read from the archive rather than from `ApplicationInfo`: the only field that
     * names an ABI is `primaryCpuAbi`, which is hidden, and `nativeLibraryDir` names one
     * ABI at best and does not exist at all for a package installed with
     * `extractNativeLibs="false"`. The archive is the source of truth, and reading it
     * only touches the zip's central directory.
     *
     * An empty list is a real answer: it means the package is pure bytecode, which is
     * what the picker's "No native code" filter is about.
     */
    private fun abisOf(info: ApplicationInfo): List<String> {
        val found = LinkedHashSet<String>()
        val sources = buildList {
            add(info.sourceDir)
            info.splitSourceDirs?.let(::addAll)
        }

        for (source in sources) {
            runCatching {
                ZipFile(source).use { zip ->
                    val entries = zip.entries()
                    while (entries.hasMoreElements()) {
                        val name = entries.nextElement().name
                        if (!name.startsWith(LIB_PREFIX)) {
                            continue
                        }
                        val abi = name.substring(LIB_PREFIX.length).substringBefore('/')
                        if (abi.isNotEmpty() && KNOWN_ABIS.contains(abi)) {
                            found.add(abi)
                            // Every known ABI accounted for; nothing left to learn from
                            // the remaining entries, which can number in the thousands.
                            if (found.size == KNOWN_ABIS.size) {
                                return found.toList()
                            }
                        }
                    }
                }
            }
        }
        return found.toList()
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
        const val LIB_PREFIX = "lib/"

        /**
         * The four ABIs Android still ships. Anything else in `lib/` is not a CPU
         * directory, and matching a fixed set keeps a malformed archive from inventing
         * architectures the filter cannot offer.
         */
        val KNOWN_ABIS = setOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")

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
