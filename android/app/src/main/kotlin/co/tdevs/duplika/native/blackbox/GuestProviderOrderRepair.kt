package co.tdevs.duplika.native.blackbox

import android.content.pm.ProviderInfo
import co.tdevs.duplika.native.Slog

/**
 * Installs a guest's content providers in the order the app asked for.
 *
 * `android:initOrder` is how an app says which of its providers has to be created first —
 * "a larger number is initialized first" — and apps lean on it to stand their dependency
 * graph up before anything can ask the graph a question. Bcore installs them in the order
 * its package parser produced, which is the order they appear in the manifest, so the
 * attribute has no effect inside a container.
 *
 * Reddit is the case that made it visible. It declares:
 *
 *     <provider android:name=".di.DependencyInjectionInitProvider" android:initOrder="99999999"/>
 *     <provider android:name=".firebase.provider.RedditFirebaseInitProvider" android:initOrder="999"/>
 *     <provider android:name="androidx.startup.InitializationProvider"/>   <!-- 0 -->
 *
 * but lists `androidx.startup.InitializationProvider` first. On a device the platform runs
 * the injection provider first and everything that follows finds the graph ready. In a
 * clone the startup provider went first, its `LoggingInitializer` waited sixty seconds for
 * a component nothing had registered yet, and then threw:
 *
 *     Caused by: java.lang.IllegalStateException: Unable to wait for a component of type pr5
 *     Rejecting re-init on previously-failed class java.lang.Class<rx70>:
 *         java.lang.ExceptionInInitializerError
 *
 * A class whose static initializer throws stays poisoned for the life of the process, so
 * the app's logging and flag layer was dead before its first activity ran: the clone drew
 * zero frames and sat on a black screen with no crash to explain it.
 *
 * The repair reorders the list Bcore is about to walk, which is the whole of it — the sort
 * is by `initOrder` descending and stable, so providers that share a value keep the
 * manifest order they already had, and an app that sets the attribute nowhere is left
 * exactly as it was.
 */
object GuestProviderOrderRepair {

    /**
     * Runs after Bcore has bound the application data and before it installs the providers
     * from it, which is the only window where the list can still be reordered. Never fatal:
     * a list that cannot be read or sorted leaves the engine's own order in place.
     */
    fun install() {
        try {
            val providers = GuestBoundProviders.list() ?: return
            if (providers.size < 2) return

            val before = providers.map { it.name }
            // Stable, so equal initOrder keeps manifest order — the platform's own rule.
            providers.sortWith(compareByDescending(ProviderInfo::initOrder))
            if (providers.map { it.name } == before) return

            Slog.i(
                Slog.LAUNCH,
                "Reordered ${providers.size} content provider(s) by initOrder; " +
                    "first is now ${providers.firstOrNull()?.name}",
            )
        } catch (error: Throwable) {
            Slog.w(Slog.LAUNCH, "Guest provider order repair unavailable: ${error.message}")
        }
    }
}
