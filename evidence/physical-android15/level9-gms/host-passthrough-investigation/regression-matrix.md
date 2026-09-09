# Regression matrix — host-platform package visibility

Device: OnePlus CPH2605, Android 15 / API 35 / arm64-v8a, serial `KNOJORMFV4GERKHM`.

Three evidence classes are kept strictly apart, as required:

- **PHYSICALLY VERIFIED** — run on the device in this session (2026-09-09) and observed.
- **PHYSICALLY VERIFIED (2026-09-08)** — run on the device in the prior session, against
  the *same* `bcore.aar` (sha256 `0178aa0b0fe2…`, confirmed unchanged) and the same host
  APKs. Not re-run today.
- **BUILD ONLY** / **NOT RE-RUN** — exactly what it says.

## Automated checks — PHYSICALLY VERIFIED (this session)

| Check | Result |
| --- | --- |
| `flutter analyze` | **PASS** — exit 0, 4 pre-existing info-level lints, 0 errors/warnings |
| `flutter test` | **PASS** — 246/246 tests |
| Engine artefact carries the patch | **PASS** — `javap` on the shipped `bcore.aar` shows `isHostPlatformPackage` / `isVisibleHostPackage`, referenced at 7 sites in `IPackageManagerProxy` |
| Fabricated `PackageInfo` stub removed | **PASS** — no `33.8.16-21` / `createFakeGooglePlayServices` string in any `IPackageManagerProxy` class |

No production Dart/Kotlin code was changed in this session, so these confirm the committed
state rather than new work.

## Level 6 — modern Android API surface

**PHYSICALLY VERIFIED (this session)**, release host build, guest clone, virtual user 2.

| Surface | Result | Observation |
| --- | --- | --- |
| Activity launch | **PASS** | `Displayed …ProxyActivity$P0 +833ms`; guest UI rendered |
| SQLite persistence | **PASS** | `LadderLevel6: onCreate persistedCount=1`; `SQLite value=1` in-app |
| JobScheduler | **PASS** | `LadderLevel6: job schedule result=0` |
| Notifications | **PASS** | `LadderLevel6: notification posted channel=level6` |
| Runtime permission dialogs | **PASS** | Camera and notification dialogs both shown and accepted; host records `CAMERA: granted=true`, `POST_NOTIFICATIONS: granted=true` |
| In-app permission label refresh | **UNCONFIRMED** | The guest's own label still read `notification=false camera=false` after both grants. Pre-existing: the patch hooks no permission API (`checkSelfPermission` / `requestPermissions` are untouched), and the same confirmation was absent from the 2026-09-08 baseline. Not attributable to this change, but not verified working either. |
| Crashes / ANRs | **PASS** | 0 `FATAL EXCEPTION`, 0 `ANR in` across launch and all interactions |

Evidence: `regression-level6-launch.log`, `regression-level6-actions.log`,
`regression-level6-guest.png`.

## Level 7 — split APK / ABI split / native library loading

**PHYSICALLY VERIFIED (2026-09-09), release host build, virtual user 6.**

Re-run in full through the real APK-import flow (picker → "Import by the file manager" →
multi-select), not inherited. Three release splits were imported:
`level7fixture-base-release.apk` + `config.en` + `config.arm64_v8a`.

| Surface | Result | Observation |
| --- | --- | --- |
| Split APK import | **PASS** | `Parsed com.example.duplikaladder.level7fixture 1.0 (2 split(s))` → `APK set accepted` → `Installed an imported APK set` |
| All splits loaded at runtime | **PASS** | `openDexFileNative` for all three: `base.apk`, `1_1_…config.en-release.apk`, `2_2_…config.arm64_v8a-release.apk` |
| Split resource resolution | **PASS** | In-app: `split resource loaded marker=split_marker` |
| ABI split native library loading | **PASS** | In-app: `native=abi-native-loaded` |
| Relaunch persistence | **PASS** | `launches=1` → `am force-stop` → **verified 0 remaining `level7fixture` processes** → relaunch → `launches=2`, marker and native still loaded |
| Crashes / ANRs | **PASS** | 0 |
| GMS provisioning | off | The compatibility sheet showed no GMS checkbox (fixture declares no GMS dependency); `GMS provisioning for user 6: requested=false` |

The `Failed trying to add dependency on non-existing package` / `Invalid dex load report`
lines are the engine's ordinary host-PM warnings for a container-only package, present
before this change.

Evidence: `regression-level7-0909.log`, `regression-level7-guest.png`. Prior run:
`regression-level7.log` (2026-09-08).

## Level 8 — real third-party apps

All three apps are vendored in `compatibility_test_ladder/real_apps/`; nothing new was
downloaded. Clones were made through the ordinary installed-app flow (provisioning off,
`GMS provisioning for user N: requested=false`), on the **release** host build.

| App | Result | Class | Observation |
| --- | --- | --- | --- |
| **Fossify Notes** — persistence | **PASS** | **PHYSICALLY VERIFIED (2026-09-09)** | Launched in virtual user 3, editor rendered. Typed `L9passthrough-persist-0909`, backed out, `am force-stop`, **verified 0 remaining `fossify` processes**, relaunched — the note was still present (confirmed by `uiautomator` dump, not just visually). Also exercises multi-ABI selection: the APK declares ARM64 + ARMv7 + x86_64 + x86. 0 fatals, 0 ANRs. |
| **AntennaPod** — networking | **PASS** | **PHYSICALLY VERIFIED (2026-09-09)** | Launched in virtual user 4 to "Welcome to AntennaPod!". Online podcast search for "Linux" returned live results attributed *"Results by Apple, Podcast Index"* with cover art fetched over the network — so HTTPS and image loading both work from inside the container (`notifyNetdUID 10963` shows traffic attributed to the host UID, as expected). 0 fatals, 0 ANRs. |
| **Markor** — launch / embedded WebView | **PASS** | **PHYSICALLY VERIFIED (2026-09-09)** | Re-run: cloned into virtual user 5, `net.gsantner.markor/.MainActivity` → `IntroActivity` reached `HAS_DRAWN`, intro UI rendered with its file-browser preview. 0 fatals, 0 ANRs. Prior run (2026-09-08) additionally captured the WebView sandbox process starting for the container (`com.google.android.webview:sandboxed_process0 … for {co.tdevs.duplika/…SandboxedProcessService0}`). |

Evidence: `regression-level8-fossify.log`, `regression-level8-fossify-guest.png`,
`regression-level8-antennapod.log`, `regression-level8-antennapod-guest.png`,
`regression-level8-markor-0909.log`, `regression-level8-markor-guest.png`,
`regression-level8-markor.log` (2026-09-08).

**Every Level 6/7/8 surface named in the regression brief is now physically verified on
2026-09-09.** Nothing in the regression set is inherited or inferred, with the single
exception noted for the Level 6 in-app permission label.

## Level 9 — the change under test

**PHYSICALLY VERIFIED (this session)**, all four build combinations. See
`../compatibility-matrix.md` for the full result table.

| Host build | Diagnostic build | A | B | C | D | E | F | G |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debug | release (minified) | PASS | PASS | PASS | BLOCKED | PASS | PASS | PASS |
| debug | debug | PASS | PASS | PASS | BLOCKED | PASS | PASS | PASS |
| release (R8) | debug | PASS | PASS | PASS | BLOCKED | PASS | PASS | PASS |
| release (R8) | release (minified) | PASS | PASS | PASS | BLOCKED | PASS | PASS | PASS |

Relaunch after a full `force-stop` reproduced the same verdicts on both host builds, so
results are deterministic and not first-run artefacts. Minification was never disabled to
obtain any result.

## Documentation correction (2026-09-09)

`docs/PHASE_4_COMPATIBILITY.md` explained the GMS failure as a **"signature wall"** —
`SERVICE_INVALID` supposedly caused by the container being unable to present Google Play
services' signing certificate, concluding that working GMS needed a signature bypass and was
"not fixable at the engine level". That explanation is **falsified** and has been corrected in
place: a document-level banner at the top, a correction block at the `SERVICE_INVALID`
section (original text struck through, not deleted), and inline markers at the four
downstream inferences that inherited the error.

Falsified because (a) a provisioned container reports GMS certificates byte-identical to the
host and *still* returned `SERVICE_INVALID(9)`, and (b) an unprovisioned container with the
package-visibility patch returns `SUCCESS(0)` with no certificate change whatsoever.

## Net assessment

No regression was observed in anything that previously worked. The only surface not
positively confirmed is the Level 6 in-app permission label, which the patch has no
mechanism to affect and which was equally unconfirmed before the change.
