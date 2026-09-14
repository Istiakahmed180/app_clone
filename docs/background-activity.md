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

## The "Allow background usage" toggle is not the Doze exemption

Read off the Settings UI on a Pixel image (API 35), toggling the switch and watching the
signals:

| Switch | `RUN_ANY_IN_BACKGROUND` | deviceidle whitelist |
| --- | --- | --- |
| **on** | `allow` | unchanged (absent here) |
| **off** | `ignore` | unchanged (absent here) |

So that toggle is the **background-restriction app-op**, the one
`ActivityManager.isBackgroundRestricted()` reports — not the Doze whitelist. A Pixel shows
it **on** for a freshly installed, perfectly ordinary app: the app is *optimised*, not
unrestricted. Calling that state "Restricted" tells the user their green switch is lying.

## The rule the UI follows (two states)

- **Allowed** — Doze exempts the app and `isBackgroundRestricted()` is false.
- **Not allowed** — anything else.

The technical middle grounds are deliberately not their own labels. Android's "Optimised"
is the state every freshly installed app is in, and putting that word (or "Restricted")
beside a green system toggle reads as a fault; a third label for the unreadable OEM switch
told the user nothing they could act on. Two states, and the guide carries the difference:
"Not allowed" always leads to the sheet that explains and opens the right screen.

The sheet also knows the state: once allowed it states that and offers **Done**, instead of
offering the same "Allow" button that was already pressed.

**Known limit, measured.** On the OEM builds with a second switch (`verifiable` is false),
turning that switch off is not detected: none of the readable controls move, so the row
keeps saying Allowed. The app cannot see that switch ([measured above](#what-was-measured-oneplus-cph2605-coloros-android-15)); the
guide still names the taps that reach it.

The nudge follows `allowed`, so it appears whenever the row says `Not allowed` — one
reminder, dismissed for good by either button.

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
