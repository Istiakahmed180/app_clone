package co.tdevs.duplika.native.blackbox

import co.tdevs.duplika.native.Slog

/**
 * Leaves a guest's disabled content providers uncreated, the way the platform does.
 *
 * `android:enabled="false"` on a provider means "declared, but do not create it". The
 * platform honours it before a process is even bound: `generateApplicationProvidersLocked`
 * asks the package settings whether each component is enabled and the disabled ones never
 * reach `installContentProviders`. Bcore has no such filter — `installProviders` walks the
 * whole list and creates every entry whose process matches.
 *
 * That turns a deliberate "off" into an "on", and the providers apps disable are precisely
 * the ones that would otherwise initialise a library behind the app's back. MX Player
 * disables three:
 *
 *     <provider android:name="com.google.firebase.provider.FirebaseInitProvider"  android:enabled="false"/>
 *     <provider android:name="com.google.android.gms.ads.MobileAdsInitProvider"   android:enabled="false"/>
 *     <provider android:name="com.facebook.internal.FacebookInitProvider"         android:enabled="false"/>
 *
 * because it initialises Firebase itself, with its own options, from `App.onCreate`. In a
 * clone the provider went first and took the name (measured on API 35):
 *
 *     FirebaseApp: Device unlocked: initializing all Firebase APIs for app [DEFAULT]
 *     FirebaseInitProvider: FirebaseApp initialization successful
 *     FATAL EXCEPTION: main
 *     java.lang.RuntimeException: Unable to makeApplication
 *     Caused by: java.lang.IllegalStateException: FirebaseApp name [DEFAULT] already exists!
 *         at com.mxtech.videoplayer.ad.App.i(App.java:1)
 *
 * — the app's own `initializeApp` found the name taken, `Application.onCreate` threw, and
 * every process that tried again threw the same way: 21 fatals in thirty seconds and a
 * black screen. The host's own copy of MX Player starts cleanly and never logs that
 * provider, which is what pointed at the missing filter.
 *
 * Only the manifest's own answer is read. A component the app re-enables at runtime is not
 * created at that moment on a real device either — it is created the next time the process
 * starts — and asking it for content still goes through the engine's provider path, which
 * publishes it on demand.
 */
object GuestDisabledProviderRepair {

    /**
     * Runs after Bcore has bound the application data and before it installs the providers
     * from it, which is the only window where the list can still be narrowed. Never fatal:
     * a list that cannot be read leaves the engine's own behaviour in place.
     */
    fun install() {
        try {
            val providers = GuestBoundProviders.list() ?: return
            val disabled = providers.filter { !it.enabled }
            if (disabled.isEmpty()) return

            providers.removeAll(disabled.toSet())
            Slog.i(
                Slog.LAUNCH,
                "Left ${disabled.size} disabled content provider(s) uncreated, as the " +
                    "platform would: ${disabled.joinToString { it.name }}",
            )
        } catch (error: Throwable) {
            Slog.w(Slog.LAUNCH, "Guest disabled provider repair unavailable: ${error.message}")
        }
    }
}
