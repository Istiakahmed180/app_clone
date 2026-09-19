package co.tdevs.duplika.native.blackbox

import android.app.Application
import android.content.Context
import co.tdevs.duplika.native.EngineServerAnchor
import co.tdevs.duplika.native.HostProcessAnchor
import co.tdevs.duplika.native.GuestLaunchIntentRepair
import top.niunaijun.blackbox.BlackBoxCore
import top.niunaijun.blackbox.app.configuration.AppLifecycleCallback

/**
 * Carries Duplika's guest-side repairs into a clone's own process.
 *
 * Bcore invokes this callback inside the guest, after its hooks are in place and before the
 * cloned app's `Application` exists. That window is the only one the repairs can use: the
 * engine's hooks must already be installed for them to wrap, the app must not yet have
 * launched an activity or built a `PackageManager` of its own, and WebView must not yet
 * have been loaded.
 *
 * - [GuestReceiverQueryRepair] first, so it is in place before any context in this process
 *   caches the package-manager binder it wraps.
 * - [GuestPackageIdentityRepair] on top of it, so a guest asking who owns a uid in its own
 *   container is never answered with the host.
 * - [GuestLaunchIntentRepair] next, which needs a context to read the manifest with.
 * - [GuestCallerIdentityRepair] next: it needs no context, only the engine's hooks, and
 *   the first activity that could read a caller off them has not started yet.
 * - [GuestRunningProcessRepair] beside it, for the other half of the same boundary: the
 *   running-process list must not name the host as the app behind a guest process.
 * - [GuestRestartLaunchRepair] next, which needs a context to read the manifest with and
 *   must be in place before the app can restart itself into a closed activity.
 * - [GuestTaskClearLaunchRepair] beside it, for the other way an app restarts itself: the two
 *   correct different flags on the same launch and neither reads what the other wrote.
 * - [GuestFullScreenIntentRepair] next: like the two above it needs only the engine's hooks,
 *   and the activity whose `onCreate` asks the question has not started yet.
 * - [GuestProxyLaunchRepair] next, which has to be on the main handler before the first
 *   activity launch arrives on it, and below the engine's own callback rather than above it.
 * - [GuestMediaRouterRepair] beside it: like the repairs above it needs only the engine's
 *   hooks, and the first activity to build a `MediaRouter2` has not started yet.
 * - [GuestWifiLockRepair] beside those two, before the app's first network request can take
 *   a Wi-Fi lock.
 * - [GuestProviderCallerRepair] beside those two, and before [GuestProviderOrderRepair] runs
 *   the app's own providers: it has to be in place before the first provider is acquired.
 * - [GuestWebViewDataDirRepair] next, because Bcore chose the WebView directory a few
 *   lines before this callback and the first WebView is still several steps away.
 * - [GuestFatalCrashRepair] next, so it wraps every handler installed above it.
 * - [GuestDisabledProviderRepair] next to last and [GuestProviderOrderRepair] last, because
 *   both touch the list Bcore reads a few lines later: the disabled entries are dropped
 *   first so the reorder only has to sort providers that will really be created.
 *
 * The guest also anchors the engine's server process and Duplika's own process here. A clone on screen makes *this*
 * process foreground, so binding the server from here is what keeps the freezer off it — the
 * job the host used to do by running a foreground service, and the reason that service no
 * longer has to show "A cloned app is running" for as long as a clone is open.
 *
 * ### The two `String` arguments
 *
 * Bcore erases their names, and it passes them **package first**:
 * `handleBindApplication(packageName, processName)` looks the package up with
 * `getPackageInfo(packageName, ...)` and hands `processName` to `VirtualRuntime.setupRuntime`,
 * and its own callers read `bindApplication(serviceInfo.packageName, serviceInfo.processName)`.
 * They are named accordingly here. They were the other way round until it was noticed that
 * [GuestProcessRegistry] was being given `com.airbnb.android:push` where it expected
 * `com.airbnb.android` — the two agree for a guest's main process and only diverge for its
 * sub-processes, which is exactly the set that a Force stop or a delete then failed to find.
 */
class GuestRepairsLifecycleCallback : AppLifecycleCallback() {

    override fun beforeCreateApplication(
        packageName: String?,
        processName: String?,
        context: Context?,
        virtualUserId: Int,
    ) {
        // Said here because this is the earliest point at which a guest exists and knows
        // which container it is: the host cannot reliably ask the engine later, and a
        // process that starts without saying so is one a Force stop or a delete will miss.
        if (packageName != null) {
            GuestProcessRegistry.record(packageName, virtualUserId)
        }
        if (context != null) {
            EngineServerAnchor.hold(context, BlackBoxCore.getHostPkg(), EngineServerAnchor.HOST)
            HostProcessAnchor.hold(context, BlackBoxCore.getHostPkg())
        }
        GuestReceiverQueryRepair.install(context)
        GuestPackageIdentityRepair.install(context)
        GuestLaunchIntentRepair.install(context)
        GuestCallerIdentityRepair.install()
        GuestRunningProcessRepair.install()
        GuestRestartLaunchRepair.install(context)
        GuestTaskClearLaunchRepair.install()
        GuestFullScreenIntentRepair.install()
        GuestProxyLaunchRepair.install()
        GuestMediaRouterRepair.install()
        GuestWifiLockRepair.install()
        GuestProviderCallerRepair.install()
        GuestWebViewDataDirRepair.install(context, packageName, processName, virtualUserId)
        GuestFatalCrashRepair.install()
        GuestDisabledProviderRepair.install()
        GuestProviderOrderRepair.install()
    }

    /**
     * Bcore installs its own package-manager proxy somewhere between the two callbacks, so
     * the receiver repair is put back on top of it here. By this point the engine's hooks
     * are final and the app has not yet run a line of its own `onCreate`.
     *
     * [GuestProxyLaunchRepair] is given the application here too, because this is the first
     * point at which there is one to register an activity lifecycle callback on.
     */
    override fun beforeApplicationOnCreate(
        packageName: String?,
        processName: String?,
        application: Application?,
        virtualUserId: Int,
    ) {
        GuestReceiverQueryRepair.install(application)
        GuestPackageIdentityRepair.install(application)
        GuestProxyLaunchRepair.watch(application)
    }
}
