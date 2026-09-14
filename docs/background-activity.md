# Background activity: what Android lets the app see, and what it must not claim

Duplika's clones run inside its own process group, so a clone goes quiet when Duplika is
frozen, Doze'd or killed. Two separate Android controls decide whether that happens:

1. **The Doze exemption** — battery "Don't optimise" / "Unrestricted". Readable
   (`PowerManager.isIgnoringBatteryOptimizations`) and grantable in one tap from the app.
2. **The OEM switch** — e.g. OnePlus/ColorOS *App info → Battery usage → Allow background
   activity*. This is the one that decides on those builds, and **it is not readable by
   any public API.**

## What was measured (OnePlus CPH2605, ColorOS, Android 15)

With the OEM switch **off** and the app Doze-exempt:

| Probe | Result |
| --- | --- |
| `ActivityManager.isBackgroundRestricted()` | `false` |
| `cmd appops get <pkg> RUN_ANY_IN_BACKGROUND` | default `allow` |
| `cmd activity get-standby-bucket <pkg>` | `5` (OEM scheme, not the AOSP 10/20/30/40/45/50) |
| `dumpsys deviceidle whitelist` | package present |

Nothing moved. The switch is invisible; the readable controls describe a different pair of
mechanisms and stay green with it off.

The screen itself cannot be deep-linked either: starting
`com.oplus.battery/com.oplus.powermanager.fuelgaue.PowerControlActivity` is refused with
`SecurityException: ... not exported from uid 1000` — Settings may open it, apps may not.
The app can only open **App info**, one tap above it.

## The rule the UI follows

- `verifiable` = the device has no OEM switch (no `com.oplus.battery`).
- `hasKnownProblem` = Doze is not exempt, or `isBackgroundRestricted()` is true.
- **Allowed** — verifiable and nothing known to be wrong. This is the only case worth a
  green label, and it is only reachable where every control was actually read.
- **Restricted** — a problem Android reported. Said plainly, including on OEM builds.
- **Check** — an OEM build with nothing known to be wrong. Not a claim: the row says the
  switch cannot be read and names the taps that reach it
  ("Tap here, then Battery usage, then Allow background activity").

The home nudge follows the same state (`!allowed`): on OEM builds one reminder per install
teaches where the switch is, and either **Allow** or dismiss retires it for good. There is
no second banner: settings is the permanent surface, the nudge is the one-time teacher.

## Where it lives

- `android/app/src/main/kotlin/co/tdevs/duplika/native/BackgroundActivity.kt` — the reads,
  the OEM detection and the destination.
- `lib/data/models/background_activity_state.dart` — `verifiable` / `hasKnownProblem` /
  `allowed`.
- `lib/features/settings/views/settings_view.dart` — the row's three states.
- `lib/features/home/widgets/background_activity_nudge.dart` — the one-time nudge.
