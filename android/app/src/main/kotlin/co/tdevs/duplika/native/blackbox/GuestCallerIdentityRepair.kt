package co.tdevs.duplika.native.blackbox

import android.content.ComponentName
import co.tdevs.duplika.native.Slog
import java.lang.reflect.Method
import top.niunaijun.blackbox.BlackBoxCore
import top.niunaijun.blackbox.fake.hook.ClassInvocationStub
import top.niunaijun.blackbox.fake.hook.HookManager
import top.niunaijun.blackbox.fake.hook.MethodHook

/**
 * Stops a clone that nobody launched for a result from claiming it was.
 *
 * `Activity.getCallingActivity()` and `getCallingPackage()` answer null on real Android
 * whenever the activity was not started with `startActivityForResult` — which is every
 * launch from a launcher icon. Bcore answers them from its own activity stack instead, and
 * its no-caller branch fabricates one rather than returning null:
 *
 *     ActivityRecord caller = findActivityRecordByToken(userId, record.resultTo);
 *     if (caller != null) return caller.component;
 *     return new ComponentName(BlackBoxCore.getHostPkg(), ProxyActivity.P0.class.getName());
 *
 * So inside a container every activity looks started-for-result, by Duplika. Apps branch on
 * exactly that to tell "I am the app's entry point" from "I was opened to hand something
 * back", and they take the wrong branch. Airbnb's splash is the clearest case:
 *
 *     if (getCallingActivity() == null) { startActivity(HomeActivity); finish(); }
 *     else                              { setResult(RESULT_OK);        finish(); }
 *
 * The clone therefore drew its splash, took the second branch, and closed again — never a
 * crash, so nothing in the log said why.
 *
 * The repair replaces those two hooks with wrappers that pass the engine's answer through
 * untouched unless it is the fabricated one, which becomes null. A container's real caller
 * is always another guest activity, so an answer naming the *host* package can only be the
 * fallback — no genuine answer is discarded. It also closes the identity leak the fallback
 * opened: a guest could read Duplika's package name straight off `getCallingPackage()`.
 *
 * Bcore registers both hooks, by annotation, on all three of `IActivityManagerProxy`,
 * `IActivityTaskManagerProxy` and `IActivityClientProxy`; which one serves a given call
 * depends on the platform version, so every injector is swept rather than one named.
 */
object GuestCallerIdentityRepair {

    private val REPAIRED = setOf("getCallingActivity", "getCallingPackage")

    @Volatile
    private var installed = false

    /**
     * Idempotent: the wrappers are recognised on a second pass and left alone, so a guest
     * process that reaches this more than once does not stack them. The latch is only set
     * once something was actually replaced, so a call that arrives before the engine's
     * hooks exist does not lock in the unrepaired state. Never fatal — a clone that cannot
     * be repaired keeps Bcore's behaviour.
     */
    @Synchronized
    fun install() {
        if (installed) return
        try {
            var replaced = 0
            for (injector in injectors().orEmpty()) {
                if (injector !is ClassInvocationStub) continue
                replaced += repair(injector)
            }
            if (replaced == 0) {
                Slog.w(Slog.BCORE, "Guest caller identity repair found no hook to replace")
                return
            }
            installed = true
            Slog.i(Slog.BCORE, "Guest caller identity repair installed on $replaced hook(s)")
        } catch (error: Throwable) {
            Slog.w(Slog.BCORE, "Guest caller identity repair unavailable: ${error.message}")
        }
    }

    /**
     * The map is keyed by the method name the stub dispatches on, so each entry is replaced
     * in place under a key that is already present — no rehash, and nothing the engine may
     * be reading from a binder thread at the same moment is restructured.
     */
    private fun repair(injector: ClassInvocationStub): Int {
        val hooks = hookMap(injector) ?: return 0
        var replaced = 0
        for (name in REPAIRED) {
            val current = hooks[name] ?: continue
            if (current is NullWhenFabricated) continue
            hooks[name] = NullWhenFabricated(current, name)
            replaced++
        }
        return replaced
    }

    @Suppress("UNCHECKED_CAST")
    private fun hookMap(injector: ClassInvocationStub): MutableMap<String, MethodHook>? =
        runCatching {
            ClassInvocationStub::class.java
                .getDeclaredField("mMethodHookMap")
                .apply { isAccessible = true }
                .get(injector) as? MutableMap<String, MethodHook>
        }.getOrNull()

    @Suppress("UNCHECKED_CAST")
    private fun injectors(): Collection<Any>? = runCatching {
        val map = HookManager::class.java
            .getDeclaredField("mInjectors")
            .apply { isAccessible = true }
            .get(HookManager.get()) as? Map<*, *>
        map?.values?.filterNotNull()
    }.getOrNull()

    /**
     * Delegates to the hook it replaced and drops only the fabricated answer.
     *
     * The stub returns `afterHook(hook(...))`, so filtering in [afterHook] catches the whole
     * normal path once. [beforeHook] is passed through untouched: there, null means "no
     * short-circuit, keep going" rather than "no caller", and rewriting it would change
     * which branch the stub takes.
     *
     * [MethodHook.getMethodName] is only read by the single-argument `addMethodHook`, but it
     * still answers the name the original was registered under.
     */
    private class NullWhenFabricated(
        private val delegate: MethodHook,
        private val name: String,
    ) : MethodHook() {

        override fun getMethodName(): String = name

        override fun isEnable(): Boolean = delegate.isEnable()

        override fun beforeHook(who: Any?, method: Method?, args: Array<Any?>?): Any? =
            delegate.beforeHook(who, method, args)

        override fun hook(who: Any?, method: Method?, args: Array<Any?>?): Any? =
            delegate.hook(who, method, args)

        override fun afterHook(result: Any?): Any? {
            val answer = delegate.afterHook(result)
            return if (isFabricated(answer)) null else answer
        }

        /**
         * The host package can only come from Bcore's no-caller fallback: a guest's real
         * caller is another guest activity, and its component and package are the guest's.
         */
        private fun isFabricated(answer: Any?): Boolean {
            val host = runCatching { BlackBoxCore.getHostPkg() }.getOrNull() ?: return false
            return when (answer) {
                is ComponentName -> answer.packageName == host
                is String -> answer == host
                else -> false
            }
        }
    }
}
