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

**PHYSICALLY VERIFIED (2026-09-08). NOT RE-RUN this session.**

The imported split-APK fixture launched in a container
(`ComponentInfo{com.example.duplikaladder.level7fixture/.MainActivity}`, window created,
no crash). The two `Failed trying to add dependency on non-existing package` and
`Invalid dex load report` lines are the engine's ordinary host-PM warnings for a
container-only package, present before this change.

Evidence: `regression-level7.log`. Re-running needs the APK-import flow; not repeated.

## Level 8 — real third-party apps

**PHYSICALLY VERIFIED (2026-09-08). NOT RE-RUN this session.**

| App | Result | Observation |
| --- | --- | --- |
| Markor (embedded WebView) | **PASS** | `net.gsantner.markor/.MainActivity` → `IntroActivity` drew to `HAS_DRAWN`; WebView sandbox process started for the container (`com.google.android.webview:sandboxed_process0 … for {co.tdevs.duplika/…SandboxedProcessService0}`); 0 fatals, 0 ANRs |
| Fossify Notes persistence | **NOT RE-RUN** | |
| AntennaPod networking | **NOT RE-RUN** | |

Evidence: `regression-level8-markor.log`.

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

## Net assessment

No regression was observed in anything that previously worked. The only surface not
positively confirmed is the Level 6 in-app permission label, which the patch has no
mechanism to affect and which was equally unconfirmed before the change.
