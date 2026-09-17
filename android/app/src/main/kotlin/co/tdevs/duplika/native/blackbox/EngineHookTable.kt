package co.tdevs.duplika.native.blackbox

import top.niunaijun.blackbox.fake.hook.ClassInvocationStub
import top.niunaijun.blackbox.fake.hook.HookManager
import top.niunaijun.blackbox.fake.hook.MethodHook

/**
 * Lets Duplika put its own layer over one of the engine's method hooks, in the guest.
 *
 * Bcore dispatches a hooked binder call by looking the method name up in a map each stub
 * keeps, so a hook can be corrected by replacing the entry under the same key with one that
 * delegates to it. The map is private and the stub instances live in `HookManager`, hence
 * the reflection; matching is by the method name the stub dispatches on, which is stable
 * across the engine's obfuscation.
 *
 * Bcore registers the same hook on several stubs — `getCallingActivity` sits on the activity
 * manager, the activity task manager and the activity client — and which one serves a call
 * depends on the platform version, so every injector is swept rather than one named.
 *
 * Each entry is replaced in place under a key that is already present: no rehash, so nothing
 * the engine may be reading from a binder thread at the same moment is restructured.
 */
internal object EngineHookTable {

    /**
     * Replaces every hook registered under [methodName] with [wrap] applied to it, and
     * returns how many were replaced. A hook [wrap] declines (by returning null) is left
     * alone, which is how a caller keeps this idempotent: it returns null for a hook it
     * has already wrapped.
     */
    fun wrapAll(methodName: String, wrap: (MethodHook) -> MethodHook?): Int {
        var replaced = 0
        for (injector in injectors()) {
            if (injector !is ClassInvocationStub) continue
            val hooks = hookMap(injector) ?: continue
            val current = hooks[methodName] ?: continue
            val wrapped = wrap(current) ?: continue
            hooks[methodName] = wrapped
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
    private fun injectors(): Collection<Any> = runCatching {
        val map = HookManager::class.java
            .getDeclaredField("mInjectors")
            .apply { isAccessible = true }
            .get(HookManager.get()) as? Map<*, *>
        map?.values?.filterNotNull().orEmpty()
    }.getOrDefault(emptyList())

    /**
     * A hook that hands its call to the one it replaced and corrects only the answer.
     *
     * The stub returns `afterHook(hook(...))`, so [correct] is applied there and catches the
     * whole normal path once. `beforeHook` is passed through untouched: there, null means
     * "no short-circuit, keep going" rather than an answer, and rewriting it would change
     * which branch the stub takes.
     */
    open class Correcting(
        private val delegate: MethodHook,
        private val name: String,
        private val correct: (Any?) -> Any?,
    ) : MethodHook() {

        override fun getMethodName(): String = name

        override fun isEnable(): Boolean = delegate.isEnable()

        override fun beforeHook(
            who: Any?,
            method: java.lang.reflect.Method?,
            args: Array<Any?>?,
        ): Any? = delegate.beforeHook(who, method, args)

        override fun hook(
            who: Any?,
            method: java.lang.reflect.Method?,
            args: Array<Any?>?,
        ): Any? = delegate.hook(who, method, args)

        override fun afterHook(result: Any?): Any? = correct(delegate.afterHook(result))
    }

    /**
     * A hook that adjusts the *arguments* before the one it replaced sees them.
     *
     * [adjust] runs in `beforeHook`, which the stub calls first and whose return value it
     * only uses to decide whether to short-circuit — so the arguments are corrected before
     * any of the engine's own handling, and its answer is passed through unchanged.
     */
    open class Adjusting(
        private val delegate: MethodHook,
        private val name: String,
        private val adjust: (Array<Any?>?) -> Unit,
    ) : MethodHook() {

        override fun getMethodName(): String = name

        override fun isEnable(): Boolean = delegate.isEnable()

        override fun beforeHook(
            who: Any?,
            method: java.lang.reflect.Method?,
            args: Array<Any?>?,
        ): Any? {
            runCatching { adjust(args) }
            return delegate.beforeHook(who, method, args)
        }

        override fun hook(
            who: Any?,
            method: java.lang.reflect.Method?,
            args: Array<Any?>?,
        ): Any? = delegate.hook(who, method, args)

        override fun afterHook(result: Any?): Any? = delegate.afterHook(result)
    }
}
