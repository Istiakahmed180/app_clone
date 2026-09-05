package com.example.virtualspacedemo.native

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import com.example.virtualspacedemo.CloneLauncherActivity

/**
 * Puts a clone on the home screen.
 *
 * The shortcut targets [CloneLauncherActivity] with the profile id, so tapping it opens
 * that specific clone directly rather than Virtual Space.
 */
class CloneShortcutManager(private val context: Context) {

    fun isSupported(): Boolean = ShortcutManagerCompat.isRequestPinShortcutSupported(context)

    /**
     * Asks the launcher to pin a shortcut. The launcher shows its own confirmation, so a
     * `true` result means the request was accepted, not that the user agreed.
     */
    fun requestPin(profileId: String, packageName: String, label: String): EngineResult<Unit> {
        if (!isSupported()) {
            return EngineResult.Failure(
                EngineErrorCodes.SHORTCUTS_UNSUPPORTED,
                "This launcher does not support adding shortcuts.",
            )
        }

        return try {
            val intent = Intent(context, CloneLauncherActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                putExtra(CloneLauncherActivity.EXTRA_PROFILE_ID, profileId)
                putExtra(CloneLauncherActivity.EXTRA_PACKAGE_NAME, packageName)
            }

            val shortcut = ShortcutInfoCompat.Builder(context, profileId)
                .setShortLabel(label)
                .setLongLabel(label)
                .setIcon(iconFor(packageName))
                .setIntent(intent)
                .build()

            if (ShortcutManagerCompat.requestPinShortcut(context, shortcut, null)) {
                Slog.i(Slog.PROFILE, "Requested a home-screen shortcut for $profileId")
                EngineResult.ok()
            } else {
                EngineResult.Failure(
                    EngineErrorCodes.SHORTCUT_REQUEST_FAILED,
                    "The launcher refused the shortcut.",
                )
            }
        } catch (error: Throwable) {
            Slog.e(Slog.PROFILE, "Shortcut request failed", error)
            EngineResult.Failure(
                EngineErrorCodes.SHORTCUT_REQUEST_FAILED,
                error.message ?: "The shortcut could not be created.",
            )
        }
    }

    /**
     * Disables a pinned shortcut whose clone is gone.
     *
     * An app cannot delete a shortcut the user pinned, so the best it can do is disable it
     * and explain why when tapped — better than a shortcut that silently does nothing.
     */
    fun disable(profileId: String, reason: String) {
        try {
            ShortcutManagerCompat.disableShortcuts(context, listOf(profileId), reason)
        } catch (error: Throwable) {
            Slog.w(Slog.PROFILE, "Could not disable shortcut for $profileId: ${error.message}")
        }
    }

    /** The guest app's own icon, falling back to Virtual Space's when it is not installed. */
    private fun iconFor(packageName: String): IconCompat {
        val drawable: Drawable = try {
            context.packageManager.getApplicationIcon(packageName)
        } catch (_: PackageManager.NameNotFoundException) {
            context.applicationInfo.loadIcon(context.packageManager)
        }
        return IconCompat.createWithBitmap(drawable.toBitmap())
    }

    private fun Drawable.toBitmap(): Bitmap {
        if (this is BitmapDrawable && bitmap != null) {
            return Bitmap.createScaledBitmap(bitmap, ICON_PX, ICON_PX, true)
        }
        return Bitmap.createBitmap(ICON_PX, ICON_PX, Bitmap.Config.ARGB_8888).also { output ->
            val canvas = Canvas(output)
            setBounds(0, 0, canvas.width, canvas.height)
            draw(canvas)
        }
    }

    private companion object {
        const val ICON_PX = 192
    }
}
