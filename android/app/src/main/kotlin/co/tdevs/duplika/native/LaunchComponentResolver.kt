package co.tdevs.duplika.native

import android.content.ComponentName
import android.content.pm.PackageManager

/**
 * Works out which activity class a clone should actually start.
 *
 * Bcore resolves this itself from its virtual package database, and gets it wrong for two
 * kinds of manifest entry:
 *
 * 1. **Disabled components.** Its query does not honour `android:enabled="false"`, so a
 *    launcher entry the platform would never pick can win.
 * 2. **Activity aliases.** An `<activity-alias>` has no class of its own — it names a
 *    `targetActivity`. Bcore hands the alias name to the class loader, which cannot find
 *    it.
 *
 * Instagram trips both at once: `com.instagram.android.InternalLauncher` is a *disabled*
 * alias for `com.instagram.mainactivity.InstagramMainActivity`, so the clone died with
 * `ClassNotFoundException` and the engine restarted it in a loop. The platform resolves
 * that package to `com.instagram.android.activity.MainTabActivity` instead.
 *
 * The host package manager already applies both rules correctly, and the guest's manifest
 * is the same manifest, so asking the host is both simpler and more faithful than
 * repairing the query inside the engine — which ships as a prebuilt AAR with no source in
 * this repository.
 */
object LaunchComponentResolver {

    /**
     * The activity class to start for [packageName], or null when the host cannot resolve
     * one either — a package with no launcher entry at all, or one that disappeared
     * between the clone being listed and being tapped. Callers fall back to letting the
     * engine try its own way rather than reporting a failure the user cannot act on.
     */
    fun resolve(packageManager: PackageManager, packageName: String): ComponentName? {
        // getLaunchIntentForPackage already skips disabled components and already tries
        // CATEGORY_INFO for packages that publish no CATEGORY_LAUNCHER entry.
        val launchIntent = runCatching {
            packageManager.getLaunchIntentForPackage(packageName)
        }.getOrNull() ?: return null

        val activityInfo = runCatching {
            packageManager.resolveActivity(launchIntent, 0)?.activityInfo
        }.getOrNull() ?: return launchIntent.component

        // Non-null only on an alias, where it holds the real class. Taking it here is what
        // keeps the class loader from being handed a name that was never compiled.
        val targetActivity = activityInfo.targetActivity
        return if (targetActivity.isNullOrEmpty()) {
            ComponentName(activityInfo.packageName, activityInfo.name)
        } else {
            ComponentName(activityInfo.packageName, targetActivity)
        }
    }
}
