package co.tdevs.duplika.native.blackbox

import android.content.Context
import co.tdevs.duplika.native.GuestLaunchIntentRepair
import top.niunaijun.blackbox.app.configuration.AppLifecycleCallback

/**
 * Carries [GuestLaunchIntentRepair] into the clone's own process.
 *
 * Bcore invokes this callback inside the guest, after its hooks are in place and before
 * the cloned app's `Application` exists — the only window where the repair can wrap the
 * engine's `ActivityThread.mH` callback without racing the first activity launch.
 */
class GuestAliasLifecycleCallback : AppLifecycleCallback() {

    override fun beforeCreateApplication(
        processName: String?,
        packageName: String?,
        context: Context?,
        virtualUserId: Int,
    ) {
        GuestLaunchIntentRepair.install()
    }
}
