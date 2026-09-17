package co.tdevs.duplika.native.blackbox

import android.app.Application
import android.content.Context
import co.tdevs.duplika.native.GuestLaunchIntentRepair
import top.niunaijun.blackbox.app.configuration.AppLifecycleCallback

/**
 * Carries Duplika's guest-side repairs into a clone's own process.
 *
 * Bcore invokes this callback inside the guest, after its hooks are in place and before the
 * cloned app's `Application` exists. That window is the only one both repairs can use: the
 * engine's hooks must already be installed for them to wrap, and the app must not yet have
 * launched an activity or built a `PackageManager` of its own.
 *
 * - [GuestReceiverQueryRepair] first, so it is in place before any context in this process
 *   caches the package-manager binder it wraps.
 * - [GuestLaunchIntentRepair] second, which needs a context to read the manifest with.
 * - [GuestCallerIdentityRepair] last: it needs no context, only the engine's hooks, and
 *   the first activity that could read a caller off them has not started yet.
 */
class GuestRepairsLifecycleCallback : AppLifecycleCallback() {

    override fun beforeCreateApplication(
        processName: String?,
        packageName: String?,
        context: Context?,
        virtualUserId: Int,
    ) {
        // Said here because this is the earliest point at which a guest exists and knows
        // which container it is: the host cannot reliably ask the engine later, and a
        // process that starts without saying so is one a Force stop or a delete will miss.
        if (packageName != null) {
            GuestProcessRegistry.record(packageName, virtualUserId)
        }
        GuestReceiverQueryRepair.install(context)
        GuestLaunchIntentRepair.install(context)
        GuestCallerIdentityRepair.install()
    }

    /**
     * Bcore installs its own package-manager proxy somewhere between the two callbacks, so
     * the receiver repair is put back on top of it here. By this point the engine's hooks
     * are final and the app has not yet run a line of its own `onCreate`.
     */
    override fun beforeApplicationOnCreate(
        processName: String?,
        packageName: String?,
        application: Application?,
        virtualUserId: Int,
    ) {
        GuestReceiverQueryRepair.install(application)
    }
}
