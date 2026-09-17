package co.tdevs.duplika.native.blackbox

import android.content.ComponentName
import co.tdevs.duplika.native.Slog
import top.niunaijun.blackbox.BlackBoxCore
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
 * The repair passes the engine's answer through untouched unless it is the fabricated one,
 * which becomes null. A container's real caller is always another guest activity, so an
 * answer naming the *host* package can only be the fallback — no genuine answer is
 * discarded. It also closes the identity leak the fallback opened: a guest could read
 * Duplika's package name straight off `getCallingPackage()`.
 */
object GuestCallerIdentityRepair {

    private val REPAIRED = listOf("getCallingActivity", "getCallingPackage")

    @Volatile
    private var installed = false

    /**
     * Idempotent: the wrappers are recognised on a second pass and left alone. The latch is
     * only set once something was actually replaced, so a call that arrives before the
     * engine's hooks exist does not lock in the unrepaired state. Never fatal — a clone that
     * cannot be repaired keeps Bcore's behaviour.
     */
    @Synchronized
    fun install() {
        if (installed) return
        try {
            var replaced = 0
            for (name in REPAIRED) {
                replaced += EngineHookTable.wrapAll(name) { current ->
                    if (current is NullWhenFabricated) null else NullWhenFabricated(current, name)
                }
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

    private class NullWhenFabricated(delegate: MethodHook, name: String) :
        EngineHookTable.Correcting(delegate, name, Fix::nullWhenHost)

    private object Fix {

        /**
         * The host package can only come from Bcore's no-caller fallback: a guest's real
         * caller is another guest activity, and its component and package are the guest's.
         */
        fun nullWhenHost(answer: Any?): Any? {
            val host = runCatching { BlackBoxCore.getHostPkg() }.getOrNull() ?: return answer
            return when {
                answer is ComponentName && answer.packageName == host -> null
                answer is String && answer == host -> null
                else -> answer
            }
        }
    }
}
