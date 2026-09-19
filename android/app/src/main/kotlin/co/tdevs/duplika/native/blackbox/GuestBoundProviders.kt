package co.tdevs.duplika.native.blackbox

import android.content.pm.ProviderInfo
import top.niunaijun.blackbox.app.BActivityThread

/**
 * The content-provider list a guest is about to have installed, as the engine holds it.
 *
 * `handleBindApplication` copies the package's providers into `mBoundApplication.providers`,
 * hands that same list to the platform's bound application data, and then walks it calling
 * `installProvider` on each entry. Between those two moments the list is still the engine's
 * own object, so a repair that reaches it there changes what actually gets created — which
 * is why this returns the list itself and never a copy.
 */
internal object GuestBoundProviders {

    @Suppress("UNCHECKED_CAST")
    fun list(): MutableList<ProviderInfo>? = runCatching {
        val thread = BActivityThread.currentActivityThread() ?: return null
        val bound = BActivityThread::class.java
            .getDeclaredField("mBoundApplication")
            .apply { isAccessible = true }
            .get(thread)
            ?: return null
        bound.javaClass
            .getDeclaredField("providers")
            .apply { isAccessible = true }
            .get(bound) as? MutableList<ProviderInfo>
    }.getOrNull()
}
