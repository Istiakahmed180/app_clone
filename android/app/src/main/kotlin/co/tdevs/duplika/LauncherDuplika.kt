package co.tdevs.duplika

/**
 * The normal launcher entry, carrying the MAIN/LAUNCHER intent-filter.
 *
 * A real activity rather than an `<activity-alias>` on purpose: Flutter's tooling (and
 * `aapt dump badging`) only recognise a real `<activity>` with a launcher filter, so when the
 * launcher was declared only as aliases `flutter run` failed with
 * "package identifier or launch activity not found" and the APK reported no launchable
 * activity.
 *
 * It subclasses [MainActivity] so it is the same Flutter host as always; the disguise still
 * toggles it against the `LauncherCalculator` alias (`AppDisguise`), which targets
 * [MainActivity] and therefore keeps working while this entry is disabled.
 */
class LauncherDuplika : MainActivity()
