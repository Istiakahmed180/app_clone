package co.tdevs.duplika.native

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Typeface
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import co.tdevs.duplika.CloneLauncherActivity

/**
 * Puts a clone on the home screen.
 *
 * The shortcut targets [CloneLauncherActivity] with the profile id, so tapping it opens
 * that specific clone directly rather than Duplika.
 */
class CloneShortcutManager(private val context: Context) {

    fun isSupported(): Boolean = ShortcutManagerCompat.isRequestPinShortcutSupported(context)

    /**
     * Asks the launcher to pin a shortcut. The launcher shows its own confirmation, so a
     * `true` result means the request was accepted, not that the user agreed.
     */
    /**
     * Asks the launcher to pin a shortcut for one clone.
     *
     * [spaceIndex] and [spaceCount] are what make the shortcut identifiable. Every clone
     * of an app carries that app's name and that app's icon, so on a home screen the
     * shortcuts for three copies of one app were three identical tiles — and the launcher
     * itself was appending "-1", "-2" to tell the *labels* apart, which says nothing
     * about which clone is which. When there is more than one, the space number is drawn
     * onto the icon and appended to the label.
     */
    fun requestPin(
        profileId: String,
        packageName: String,
        label: String,
        spaceIndex: Int = 1,
        spaceCount: Int = 1,
        badgeArgb: Int? = null,
        iconPath: String? = null,
    ): EngineResult<Unit> {
        if (!isSupported()) {
            return EngineResult.Failure(
                EngineErrorCodes.SHORTCUTS_UNSUPPORTED,
                "This launcher does not support adding shortcuts.",
            )
        }

        return try {
            val shortcut = describe(
                profileId, packageName, label, spaceIndex, spaceCount, badgeArgb, iconPath,
            )

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

    /**
     * Repaints a shortcut the launcher already holds, if it holds one.
     *
     * A pinned shortcut is not frozen: the app that published it may update it, which is
     * what keeps a home-screen tile honest after the clone it points at is re-marked or
     * given a new picture. Launchers redraw on their own schedule, so the change may not
     * be instant, but it does arrive.
     *
     * Silent when the clone has no shortcut pinned: `updateShortcuts` matches on id and
     * simply does nothing for one nobody has. That is why this takes no "is it pinned"
     * check of its own.
     */
    fun refreshPinned(
        profileId: String,
        packageName: String,
        label: String,
        spaceIndex: Int = 1,
        spaceCount: Int = 1,
        badgeArgb: Int? = null,
        iconPath: String? = null,
    ): EngineResult<Unit> = try {
        ShortcutManagerCompat.updateShortcuts(
            context,
            listOf(
                describe(
                    profileId, packageName, label, spaceIndex, spaceCount, badgeArgb,
                    iconPath,
                ),
            ),
        )
        EngineResult.ok()
    } catch (error: Throwable) {
        // Never fatal: the clone's icon has already changed everywhere the app draws it,
        // and a launcher that would not take the update is not worth failing over.
        Slog.w(Slog.PROFILE, "Could not refresh the shortcut for $profileId: ${error.message}")
        EngineResult.ok()
    }

    /** The shortcut for one clone, as both pinning and refreshing need it. */
    private fun describe(
        profileId: String,
        packageName: String,
        label: String,
        spaceIndex: Int,
        spaceCount: Int,
        badgeArgb: Int?,
        iconPath: String?,
    ): ShortcutInfoCompat {
        val intent = Intent(context, CloneLauncherActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            putExtra(CloneLauncherActivity.EXTRA_PROFILE_ID, profileId)
            putExtra(CloneLauncherActivity.EXTRA_PACKAGE_NAME, packageName)
        }

        return ShortcutInfoCompat.Builder(context, profileId)
            .setShortLabel(label)
            .setLongLabel(label)
            .setIcon(iconFor(packageName, spaceIndex, spaceCount, badgeArgb, iconPath))
            .setIntent(intent)
            .build()
    }

    /**
     * The guest app's own icon, badged, falling back to Duplika's icon when the package
     * is not installed on the host.
     *
     * Two reasons to badge, and they draw differently:
     *
     * - the app has **more than one clone**, so the badge carries the space number;
     * - the user **marked this clone** with a colour ([badgeArgb]), so the badge is a
     *   plain dot -- with one clone a number says nothing, and the mark is the message.
     *
     * Neither applies, no badge: the launcher already stamps a pinned shortcut with the
     * owning app's icon, which separates it from the host app's own launcher entry.
     *
     * The colour matches what the grid draws, because both come from the same `argb` on
     * the Dart side, and [refreshPinned] carries a later change out to a shortcut the
     * launcher already holds.
     */
    private fun iconFor(
        packageName: String,
        spaceIndex: Int,
        spaceCount: Int,
        badgeArgb: Int?,
        iconPath: String?,
    ): IconCompat {
        // A picture the user chose wins over the app's own icon. Read defensively: the
        // file is the app's, but a missing or unreadable one should cost the shortcut its
        // custom look, not stop it being created.
        val chosen = iconPath?.let { path ->
            runCatching { BitmapFactory.decodeFile(path) }
                .onFailure { Slog.w(Slog.PROFILE, "Could not read the clone icon: ${it.message}") }
                .getOrNull()
        }

        val base = chosen?.let { Bitmap.createScaledBitmap(it, ICON_PX, ICON_PX, true) }
            ?: run {
                val drawable: Drawable = try {
                    context.packageManager.getApplicationIcon(packageName)
                } catch (_: PackageManager.NameNotFoundException) {
                    context.applicationInfo.loadIcon(context.packageManager)
                }
                drawable.toBitmap()
            }
        val color = badgeArgb ?: BADGE_COLOR
        val bitmap = when {
            spaceCount > 1 -> badge(base, spaceIndex, color)
            badgeArgb != null -> badge(base, null, color)
            else -> base
        }
        return IconCompat.createWithBitmap(bitmap)
    }

    /**
     * Draws a filled circle over the icon, carrying [number] when there is one.
     *
     * Bottom-**left**, because Android puts its own owning-app badge bottom-right, and
     * inset from the edge rather than flush: a launcher that masks the icon to a circle
     * or squircle would clip a corner-flush badge to a sliver.
     *
     * A white ring around it keeps the number readable over an icon of any colour.
     */
    private fun badge(source: Bitmap, number: Int?, fillColor: Int): Bitmap {
        val output = source.copy(Bitmap.Config.ARGB_8888, true) ?: return source
        val canvas = Canvas(output)
        val size = output.width.toFloat()

        val radius = size * BADGE_RADIUS_FRACTION
        val centreX = radius + size * BADGE_INSET_FRACTION
        val centreY = size - radius - size * BADGE_INSET_FRACTION

        val ring = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }
        canvas.drawCircle(centreX, centreY, radius, ring)

        val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = fillColor }
        canvas.drawCircle(centreX, centreY, radius * 0.86f, fill)

        // A mark without siblings to count: the colour is the whole message.
        val text = number?.toString() ?: return output
        val label = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            // Shrinks for a two-digit number so "12" does not overflow the circle.
            textSize = radius * if (text.length > 1) 1.05f else 1.35f
            textAlign = Paint.Align.CENTER
        }
        val bounds = Rect()
        label.getTextBounds(text, 0, text.length, bounds)
        canvas.drawText(text, centreX, centreY + bounds.height() / 2f, label)

        return output
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

        /**
         * Mirrors `AppTheme.accent`; a launcher icon has no theme to follow. Used when the
         * user has not marked the clone with a colour of their own.
         */
        val BADGE_COLOR = Color.rgb(0xFF, 0x5A, 0x2E)

        const val BADGE_RADIUS_FRACTION = 0.20f
        const val BADGE_INSET_FRACTION = 0.04f
    }
}
