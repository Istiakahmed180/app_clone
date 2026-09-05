package com.example.virtualspacedemo.native

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
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

        return mapOf(
            "packageName" to info.packageName,
            "appName" to label(info),
            "versionName" to packageInfo?.versionName,
            "system" to info.isSystemApp(),
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
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        }
    }

    private companion object {
        const val ICON_PX = 144
    }
}
