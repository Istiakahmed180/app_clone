package co.tdevs.duplika.native.blackbox

import android.content.AttributionSource
import android.content.pm.ProviderInfo
import android.os.Build
import co.tdevs.duplika.native.Slog
import java.lang.reflect.InvocationHandler
import java.lang.reflect.InvocationTargetException
import java.lang.reflect.Method
import java.lang.reflect.Proxy
import top.niunaijun.blackbox.BlackBoxCore
import top.niunaijun.blackbox.app.BActivityThread
import top.niunaijun.blackbox.fake.hook.MethodHook

/**
 * Names the caller of a clone-to-clone `ContentProvider.call` the way the engine names every
 * other call to the same provider.
 *
 * A container holds more than the app that was cloned: microG is installed into it as that
 * container's `com.google.android.gms`, and a cloned Google app talks to it. When the engine
 * hands a guest a provider that lives in the container, it wraps it saying which package that
 * provider belongs to, and rewrites the caller's name to it:
 *
 *     Reflector.with(holder).field("provider")
 *         .set(new ContentProviderStub().wrapper(asInterface(client), providerInfo.packageName));
 *
 *     // ContentProviderStub.doInvoke
 *     if ("call".equals(name)) {
 *         AttributionSourceUtils.fixAttributionSourceInArgs(args);   // uid only
 *     } else {
 *         for (...) if (args[i] instanceof String && !isSystemProviderAuthority(...)) args[i] = mAppPkg;
 *         AttributionSourceUtils.fixAttributionSourceInArgs(args);
 *     }
 *
 * `call` is the one method that keeps the caller's name, and inside a container that name is
 * the host's — because a guest's context is fixed to the host package. The receiving app sees
 * a name that does not belong to the uid it is told is calling, and a provider that checks
 * refuses. microG checks:
 *
 *     SecurityException: UID [10001] is not related to packageName [co.tdevs.duplika]
 *         (seems to be com.google.android.gms)
 *         at org.microg.gms.common.PackageUtils.getAndCheckCallingPackage(PackageUtils.java:236)
 *         at org.microg.gms.auth.AccountContentProvider.call(AccountContentProvider.java:62)
 *
 * The engine catches that and answers null, so the caller is told nothing rather than "no
 * accounts" — and a cloned YouTube reads the difference as a failure:
 *
 *     E/Auth  [GoogleAuthUtil] RemoteException when fetching accounts: Key_Accounts is Null
 *     E/ModularOnboardingContro  Failed to fetch kids onboarding status, finishing the App.
 *
 * It finishes itself in the first second, every time, so the clone is a black screen.
 *
 * So `call` is given the same name the engine gives the other five methods: the provider's own
 * package. Only calls to a provider that lives in *this* container are touched — a provider on
 * the device outside it keeps the host name the platform expects — and only the name is
 * changed, on a copy, because the attribution the caller holds is shared with the rest of its
 * process.
 */
object GuestProviderCallerRepair {

    private const val HOOKED_METHOD = "getContentProvider"
    private const val CALL = "call"

    @Volatile
    private var installed = false

    @Synchronized
    fun install() {
        if (installed || Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        try {
            val replaced = EngineHookTable.wrapAll(HOOKED_METHOD) { current ->
                if (current is Repaired) null else Repaired(current)
            }
            if (replaced == 0) {
                Slog.w(Slog.LAUNCH, "Guest provider caller repair found no hook to replace")
                return
            }
            installed = true
            Slog.i(Slog.LAUNCH, "Guest provider caller repair installed on $replaced hook(s)")
        } catch (error: Throwable) {
            Slog.w(Slog.LAUNCH, "Guest provider caller repair unavailable: ${error.message}")
        }
    }

    private class Repaired(delegate: MethodHook) : EngineHookTable.Correcting(
        delegate,
        HOOKED_METHOD,
        ::rename,
    )

    /**
     * Takes the holder the engine just filled in and puts a renaming layer over the provider
     * it wrapped. Anything unexpected leaves the holder exactly as the engine returned it.
     */
    private fun rename(holder: Any?): Any? {
        holder ?: return null
        try {
            val info = field(holder, "info") as? ProviderInfo ?: return holder
            val provider = field(holder, "provider") ?: return holder
            if (alreadyRenaming(provider)) return holder
            val owner = info.packageName ?: return holder
            if (!livesInThisContainer(owner)) return holder

            val renaming = Proxy.newProxyInstance(
                provider.javaClass.classLoader,
                provider.javaClass.interfaces,
                AsProvider(provider, owner),
            )
            setField(holder, "provider", renaming)
        } catch (error: Throwable) {
            Slog.w(Slog.LAUNCH, "Guest provider caller repair left a provider alone: ${error.message}")
        }
        return holder
    }

    /** True for a provider this repair has already wrapped, so acquiring it twice is safe. */
    private fun alreadyRenaming(provider: Any): Boolean =
        Proxy.isProxyClass(provider.javaClass) && Proxy.getInvocationHandler(provider) is AsProvider

    /** Whether [packageName] is an app installed in this guest's own container. */
    private fun livesInThisContainer(packageName: String): Boolean = runCatching {
        BlackBoxCore.get().isInstalled(packageName, BActivityThread.getUserId())
    }.getOrDefault(false)

    /**
     * Passes every call to the engine's provider untouched, except that a `call` says the
     * provider's own package as the caller's name.
     */
    private class AsProvider(
        private val delegate: Any,
        private val owner: String,
    ) : InvocationHandler {

        /** Said once per provider: a clone asks its own container's microG many times. */
        private var said = false

        override fun invoke(proxy: Any?, method: Method, args: Array<Any?>?): Any? {
            val corrected = if (method.name == CALL) named(args) else args
            return try {
                method.invoke(delegate, *(corrected ?: emptyArray()))
            } catch (error: InvocationTargetException) {
                throw error.cause ?: error
            }
        }

        /** A copy of the arguments with every attribution renamed; null when there is none. */
        private fun named(args: Array<Any?>?): Array<Any?>? {
            args ?: return null
            var corrected: Array<Any?>? = null
            for (index in args.indices) {
                val source = args[index] as? AttributionSource ?: continue
                if (source.packageName == owner) continue
                val renamed = runCatching { rename(source) }.getOrNull() ?: continue
                if (corrected == null) corrected = args.copyOf()
                corrected[index] = renamed
                if (!said) {
                    said = true
                    Slog.i(
                        Slog.LAUNCH,
                        "A clone asked $owner as ${source.packageName}; asking as $owner " +
                            "instead, which is the name the engine gives every other call to it",
                    )
                }
            }
            return corrected ?: args
        }

        private fun rename(source: AttributionSource): AttributionSource =
            AttributionSource.Builder(source.uid)
                .setPackageName(owner)
                .setAttributionTag(source.attributionTag)
                .apply { source.next?.let(::setNext) }
                .build()
    }

    private fun field(owner: Any, name: String): Any? = runCatching {
        owner.javaClass.getDeclaredField(name).apply { isAccessible = true }.get(owner)
    }.getOrNull()

    private fun setField(owner: Any, name: String, value: Any?) {
        owner.javaClass.getDeclaredField(name).apply { isAccessible = true }.set(owner, value)
    }
}
