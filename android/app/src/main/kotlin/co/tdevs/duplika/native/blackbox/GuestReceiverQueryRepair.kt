package co.tdevs.duplika.native.blackbox

import android.content.Context
import android.content.Intent
import android.content.pm.ResolveInfo
import co.tdevs.duplika.native.Slog
import java.lang.reflect.InvocationTargetException
import java.lang.reflect.Method
import java.lang.reflect.Proxy
import top.niunaijun.blackbox.BlackBoxCore
import top.niunaijun.blackbox.app.BActivityThread
import top.niunaijun.blackbox.utils.compat.BuildCompat
import top.niunaijun.blackbox.utils.compat.ParceledListSliceCompat

/**
 * Keeps a clone alive when Bcore's broadcast-receiver query returns a malformed entry.
 *
 * `IPackageManagerProxy$QueryBroadcastReceivers.hook` logs the list it is about to return:
 *
 *     List list = BlackBoxCore.getBPackageManager().queryBroadcastReceivers(...);
 *     Slog.d("PackageManagerStub", "queryIntentReceivers:" + list);
 *
 * The concatenation calls `ResolveInfo.toString()` on every entry, and that throws
 * `IllegalStateException: Missing ComponentInfo!` for any entry whose activityInfo,
 * serviceInfo and providerInfo are all null. The string is built before the log call, so
 * no log level silences it. WhatsApp queries receivers from `performAsyncInit` on a worker
 * thread, so the throw was an uncaught fatal on every single launch of the clone:
 *
 *     FATAL EXCEPTION: WhatsApp Worker #2
 *     java.lang.IllegalStateException: Missing ComponentInfo!
 *       at android.content.pm.ResolveInfo.toString(ResolveInfo.java:446)
 *       at ...IPackageManagerProxy$QueryBroadcastReceivers.hook
 *
 * The repair wraps the engine's own `sPackageManager` proxy in the guest process and, for
 * that one method, catches the failure and answers the query again without the malformed
 * entries. Dropping them loses nothing: an entry with no component info cannot be used by
 * any caller — every accessor on it throws the same exception the log did.
 *
 * Every other method passes straight through, and a call that already succeeds is never
 * touched, so the engine keeps its behaviour everywhere else.
 */
object GuestReceiverQueryRepair {

    private const val HOOKED_METHOD = "queryIntentReceivers"

    @Volatile
    private var wrapper: Any? = null

    /**
     * Safe to call repeatedly, and meant to be: Bcore installs its own proxy over the same
     * field, so a wrapper put in place too early is simply replaced. Each call re-wraps
     * whatever is there now and does nothing once the field already holds this wrapper.
     *
     * [context] is the guest's own, used to repoint a `PackageManager` it may already have
     * built — that one caches the binder at construction and would otherwise keep calling
     * the engine's proxy directly. Never fatal: a clone that cannot be wrapped keeps Bcore's
     * behaviour.
     */
    @Synchronized
    fun install(context: Context?) {
        try {
            val activityThread = Class.forName("android.app.ActivityThread")
            val field = activityThread.getDeclaredField("sPackageManager")
                .apply { isAccessible = true }

            // Null on a cold process until something asks for it. Asking populates the same
            // cache the engine and the app both read, so there is something to wrap.
            val current = field.get(null)
                ?: activityThread.getMethod("getPackageManager").invoke(null)?.also {
                    field.set(null, it)
                }
            if (current == null) {
                Slog.w(Slog.BCORE, "Guest receiver query repair found no package manager")
                return
            }
            if (current === wrapper) return

            val wrapped = Proxy.newProxyInstance(
                current.javaClass.classLoader,
                current.javaClass.interfaces,
            ) { _, method, args -> delegate(current, method, args) }
            field.set(null, wrapped)
            wrapper = wrapped
            repointExistingPackageManager(context, wrapped)
            Slog.i(Slog.BCORE, "Guest receiver query repair installed")
        } catch (error: Throwable) {
            Slog.w(Slog.BCORE, "Guest receiver query repair unavailable: ${error.message}")
        }
    }

    /**
     * `ApplicationPackageManager` keeps the binder it was built with, so one created before
     * this repair would never reach the wrapper.
     */
    private fun repointExistingPackageManager(context: Context?, wrapped: Any) {
        val existing = context?.packageManager ?: return
        runCatching {
            val field = existing.javaClass.getDeclaredField("mPM").apply { isAccessible = true }
            field.set(existing, wrapped)
        }
    }

    private fun delegate(target: Any, method: Method, args: Array<Any?>?): Any? {
        val arguments = args ?: emptyArray()
        return try {
            method.invoke(target, *arguments)
        } catch (error: InvocationTargetException) {
            val cause = error.cause ?: throw error
            if (method.name != HOOKED_METHOD || !isMissingComponentInfo(cause)) throw cause
            usableReceivers(method, arguments)
        }
    }

    private fun isMissingComponentInfo(error: Throwable): Boolean =
        error is IllegalStateException && error.message?.contains("ComponentInfo") == true

    /**
     * Re-runs the query the hook was serving and returns it in the hook's own shape.
     *
     * Argument order follows the hook: the first `Intent`, the first `String` and the first
     * `Integer` among the arguments, with the virtual user taken from the engine.
     */
    private fun usableReceivers(method: Method, args: Array<Any?>): Any? {
        val intent = args.filterIsInstance<Intent>().firstOrNull() ?: return emptyAnswer()
        val resolvedType = args.filterIsInstance<String>().firstOrNull()
        val flags = args.filterIsInstance<Int>().firstOrNull() ?: 0

        val all: List<ResolveInfo> = BlackBoxCore.getBPackageManager()
            .queryBroadcastReceivers(intent, flags, resolvedType, BActivityThread.getUserId())
            ?: emptyList()
        val usable = all.filter {
            it.activityInfo != null || it.serviceInfo != null || it.providerInfo != null
        }
        Slog.w(
            Slog.BCORE,
            "Dropped ${all.size - usable.size} receiver(s) with no component info for " +
                "${intent.action ?: intent.component?.className ?: "an intent"}",
        )
        return answer(usable)
    }

    private fun emptyAnswer(): Any? = answer(emptyList())

    /** Mirrors the hook: a ParceledListSlice from N onwards, a bare list before it. */
    private fun answer(receivers: List<ResolveInfo>): Any? =
        if (BuildCompat.isN()) ParceledListSliceCompat.create(receivers) else receivers
}
