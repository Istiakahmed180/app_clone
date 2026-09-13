package co.tdevs.duplika.native

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager

/**
 * Switches which launcher entry the app presents.
 *
 * There are two entries in the manifest — [NORMAL_ALIAS] (a real activity, subclass of
 * `MainActivity`, label "Duplika") and [CALCULATOR_ALIAS] (an `activity-alias` targeting
 * `MainActivity`, label "Calculator"). Exactly one is enabled at any time; [setMode] never
 * leaves both disabled, because a build with no enabled launcher entry is an app the user
 * cannot open again from the launcher.
 *
 * The normal entry is a real activity rather than an alias because Flutter's tooling only
 * recognises a real `<activity>` with a MAIN/LAUNCHER filter; the calculator alias targets
 * `MainActivity`, which is never disabled, so it keeps working while the normal entry is off.
 *
 * Both host the same Flutter app. Which UI it shows is decided in Dart; this class only
 * changes the icon and label the launcher draws.
 *
 * `DONT_KILL_APP` matters: the components being toggled are launcher entries, not the running
 * activity, so the process survives the switch and the user does not see the app vanish
 * mid-toggle.
 */
class AppDisguise(private val context: Context) {

    enum class Mode {
        NORMAL,
        CALCULATOR;

        companion object {
            /** Unrecognised input reads as [NORMAL]: a failed parse must not hide the app. */
            fun parse(raw: String?): Mode = when (raw) {
                CALCULATOR.name -> CALCULATOR
                else -> NORMAL
            }
        }
    }

    fun currentMode(): Mode {
        val state = context.packageManager.getComponentEnabledSetting(
            ComponentName(context, CALCULATOR_ALIAS),
        )
        return if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
            Mode.CALCULATOR
        } else {
            Mode.NORMAL
        }
    }

    fun setMode(mode: Mode) {
        val normal = ComponentName(context, NORMAL_ALIAS)
        val calculator = ComponentName(context, CALCULATOR_ALIAS)
        val flags = PackageManager.DONT_KILL_APP

        // Both are set on every call, in this order. Switching to CALCULATOR enables the
        // calculator alias before disabling the normal one; switching back does the reverse.
        // There is therefore no moment at which neither is enabled.
        when (mode) {
            Mode.CALCULATOR -> {
                set(calculator, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, flags)
                set(normal, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, flags)
            }
            Mode.NORMAL -> {
                set(normal, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, flags)
                set(calculator, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, flags)
            }
        }
        Slog.i(Slog.ENGINE, "Launcher disguise set to ${mode.name}")
    }

    private fun set(component: ComponentName, state: Int, flags: Int) {
        try {
            context.packageManager.setComponentEnabledSetting(component, state, flags)
        } catch (error: IllegalArgumentException) {
            // A manifest without the alias would throw here. That is a build error, not a
            // user one — log it and leave the other alias's state alone rather than
            // disabling both and stranding the app.
            Slog.w(Slog.ENGINE, "Could not set ${component.className} state: ${error.message}")
        }
    }

    companion object {
        const val NORMAL_ALIAS = "co.tdevs.duplika.LauncherDuplika"
        const val CALCULATOR_ALIAS = "co.tdevs.duplika.LauncherCalculator"
    }
}
