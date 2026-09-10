# GMS compatibility expansion — Pixel 9 / Android 15 / API 35

Every cell measured on this device in this phase, host **and** guest, Debug **and** minified
Release. Nothing inferred; anything not run says NOT TESTED.

Device: AVD `Pixel_9`, sdk 35, release 15, `arm64-v8a`. Play services **26.33.32**
(`263332035`), Play Store 53.0.27-34.
Engine: `bcore.aar` `23689bce6d76f144f9c2b6c17745fa79abc26a04a3aaae5ec8bf4a39031da6b9`
(was `7769e0d4cfa09ee1d9b42d76d74b6c7761602546734c49715cb6228329df160d`; the difference is
the repository's own runtime overrides, applied via `engine-patches/apply-runtime-overrides.sh`).

## New probes

| API | Host | Guest | Caller-scoped? | Result | Root cause |
| --- | --- | --- | --- | --- | --- |
| Chimera / Dynamite module load (P13) | PASS | **PASS** | no | `maps_dynamite` 203115000 and `cast.framework` 263332001 both loaded into the guest process | — |
| Play services security provider (P14) | PASS | **PASS** | no | `installIfNeeded` OK; `GmsCore_OpenSSL` visibly added to the JCE provider list | — |
| Google Maps SDK (P15) | PASS | **PASS** | no | SDK init (renderer LEGACY), MapView constructed, GoogleMap delivered, camera move + readback | was FAIL before the permission fix |
| Play Billing connection (P16) | PASS `OK` | **FAIL** | not established | `responseCode=3 BILLING_UNAVAILABLE` "Google Play In-app Billing API version is less than 3" | **open — not classified** |
| Manifest self-inspection (P17) | PASS | **PASS** | no | all 5 declared permissions reported back | — |
| Permission lookup variants (P18) | PASS | **PASS** | no | 7/7 GRANTED | was 3/7 DENIED before the fix |

## The permission-lookup defect, before and after

`Context.check*Permission` resolves by pid/uid; a guest runs with a virtual UID, so the
platform was asked about a UID it does not know.

| Lookup | Host | Guest before | Guest after |
| --- | --- | --- | --- |
| `context.checkSelfPermission` | GRANTED | **DENIED** | GRANTED |
| `context.checkCallingOrSelfPermission` | GRANTED | **DENIED** | GRANTED |
| `context.checkPermission(pid,uid)` | GRANTED | **DENIED** | GRANTED |
| `appPM.checkPermission(perm,self)` | GRANTED | GRANTED | GRANTED |
| `appPM.getPackageInfo` declared? | declared | declared | declared |
| `gmsCtxPM.checkPermission(perm,self)` | GRANTED | GRANTED | GRANTED |
| `gmsCtxPM.getPackageInfo` declared? | declared | declared | declared |

Downstream: Maps P15 PARTIAL -> **PASS**; Level 6 runtime-permission probe header
`notification=false camera=false` -> **`notification=true camera=true`** after granting.

## The caller-identity boundary is unchanged

| | Before fix | After fix |
| --- | --- | --- |
| `Unknown calling package name` per guest run | 29 | 28-29 |
| P3 LocationServices | FAIL | FAIL |
| P7 ActivityRecognition | FAIL | FAIL |
| P8 SmsRetriever | UNSUPPORTED | UNSUPPORTED |
| P12 Google Sign-In | UNSUPPORTED | UNSUPPORTED |

The fix maps a guest UID to the **host** UID — the UID the process genuinely runs under — for
the app's own permission checks. It does not alter what Play services observes, and the
evidence above confirms it did not.

## Maps API key

The fixture declares `AIzaSyPLACEHOLDER-NOT-A-REAL-KEY-diagnostics-only`, registered to
nobody. Rationale and the first no-key host run are in `host/host-p15-maps-no-key.txt`: with
no key the SDK fails at a local manifest check (`API key not found`) in **both** columns and
measures nothing about virtualization. The placeholder bypasses no validation — Google's
authorisation still runs and is still expected to fail — it only reaches the stages a
container can actually break. Rendering/authorisation is therefore NOT TESTED.

## Files

| Path | What |
| --- | --- |
| `host/host-debug-expansion.txt`, `host/host-release-expansion.txt` | host runs |
| `guest/guest-debug-expansion.txt` | guest, **before** the permission fix (Maps PARTIAL) |
| `guest/guest-debug-expansion-postfix.txt` | guest, after the fix (Maps PASS) |
| `guest/guest-release-expansion.txt` | guest Release, after the fix |
| `host/host-p15-maps-no-key.txt` | the no-key host control |
| `host/host-p17-manifest.txt`, `guest/guest-p17-manifest.txt` | manifest self-inspection |
| `host/host-p18-permission-variants.txt`, `guest/guest-p18-permission-variants.txt` | the lookup differential |
