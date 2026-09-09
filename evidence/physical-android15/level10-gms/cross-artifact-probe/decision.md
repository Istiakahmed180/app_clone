# Phase 10 — decision

## Classification: BLOCKED (device unavailable) — not Case A, B or C

Step 8's three cases all presuppose measured host and guest results. **None exist.** The
OnePlus CPH2605 disconnected from ADB before the host control could be run, and did not come
back across three `kill-server`/`start-server` recovery cycles with waits — only
`emulator-5554` remains attached. That is a physical/USB condition, not something recoverable
from software.

So:

| Step 8 case | Applies? |
| --- | --- |
| Case A — SmsRetriever also fails in guest | **No** — not measured |
| Case B — SmsRetriever succeeds in guest | **No** — not measured |
| Case C — inconclusive *because of the API* | **No** — the API was never exercised; nothing about it proved inconclusive |

Recording this as Case C would be wrong: Case C is about the API failing to give a usable
signal. Here the API gave no signal because it was never run.

## Hypothesis status — UNCHANGED from Phase 9

| Hypothesis | Status |
| --- | --- |
| **H9** — general containerised-caller attribution problem | **STRONGLY SUPPORTED** (Phase 9), *not* upgraded to CONFIRMED |
| **H10** — play-services-location-specific | **Reduced likelihood, NOT eliminated** (Phase 9) |

The play-services-location artifact confound that Phase 10 exists to remove is **still
present**. No conclusion may be drawn from this phase.

## What is ready

Everything up to the device step is complete and re-runnable without further work:

- API validated against the resolved graph: `play-services-auth-api-phone:18.0.2`, on both
  compile and runtime classpaths, **no dependency added or changed**.
- `SmsRetrieverClient extends GoogleApi<Api.ApiOptions.NoOptions>` confirmed by `javap` on
  the resolved AAR, so `checkApiAvailability` applies and the measurement is symmetric with
  Phases 8 and 9.
- Credential-free operation chosen and documented.
- `ProbeSmsRetriever` (P8) written and wired in; it checks **all three** APIs
  (SmsRetriever, ActivityRecognition, LocationServices) in one run for a symmetric
  comparison.
- Debug and Release diagnostic APKs built, minification retained; `ProbeSmsRetriever`
  verified present in the minified release dex.
- `flutter analyze` 0 errors, `flutter test` 245/245.

## To finish the phase

Reattach the CPH2605 and run four cells with the already-built APKs: host Debug, host
Release, then clone each and run guest Debug, guest Release. No code change needed.

## Note on the emulator

`emulator-5554` was **not** substituted. It is a different Android image with a different
GMS build and no existing Duplika clone set, so its results would not be comparable with the
Phase 8/9 baselines that this phase's entire value depends on. Substituting it silently
would have produced a number that looks like an answer but cannot be compared to anything.
