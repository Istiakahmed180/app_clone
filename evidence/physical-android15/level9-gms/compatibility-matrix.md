# Level 9 — Google Play services compatibility matrix

Device: OnePlus CPH2605, Android 15 / API 35 / arm64-v8a
ADB serial: `KNOJORMFV4GERKHM`
Host Play services: `com.google.android.gms` 26.32.34 (versionCode 263234035)
Host Play Store: `com.android.vending` 53.0.27-34
Test dates: 2026-09-08 (pre-fix baseline), 2026-09-09 (post-fix re-verification)

Diagnostic app: `compatibility_test_ladder/level9_gms`, package
`com.example.duplikaladder.level9gms`.

| Build | sha256 |
| --- | --- |
| `level9_gms-debug.apk` | `f8a295a0b3f2f8ab105943f293e196bb22f927c6e36540b8a3ec79de58dd4251` |
| `level9_gms-release.apk` (minified) | `4662fea49866d26ec5ef01087d80011df5efca47b59e3e2adf58e152ede432a1` |

Release keeps `isMinifyEnabled = true`. Minification was not turned off to obtain any
result below.

## Method

The same APK is run twice and the two reports compared:

1. **Host control** — installed normally with `adb install`. Establishes what the tests
   answer when nothing is virtualized. Without it a guest failure proves nothing.
2. **Guest** — cloned into a Duplika container through the ordinary user-facing flow.

The app carries no Duplika dependency, so the only difference between the two runs is the
virtualization layer.

Three configurations were measured, because Duplika has two distinct GMS behaviours:

- **Guest (unprovisioned)** — the default for an installed app.
- **Guest (GMS provisioned)** — the opt-in that installs Google packages into the
  container, reachable only through the APK-import route (see the note below).

> **Status: superseded in part.** The tables below record the state **before**
> `engine-patches/0002-host-platform-package-visibility.patch`. For the current result see
> [Post-fix results](#post-fix-results-host-platform-package-visibility) below and
> `host-passthrough-investigation/`.

## Controlled diagnostic results (pre-fix)

| Test | Host control (Debug) | Host control (Release) | Guest unprovisioned (Debug) | Guest unprovisioned (Release) | Guest GMS-provisioned (Release) |
| --- | --- | --- | --- | --- | --- |
| A — GMS package detection | PASS | PASS | **FAIL** | **FAIL** | PASS |
| B — Play services availability | PASS `SUCCESS(0)` | PASS `SUCCESS(0)` | **FAIL** `SERVICE_MISSING(1)` | **FAIL** `SERVICE_MISSING(1)` | **FAIL** `SERVICE_INVALID(9)` |
| C — GMS service resolution and bind | PASS | PASS | **PASS** | **PASS** | **PASS** |
| D — GoogleApi client connection | PASS | PASS | **FAIL** (no callback in 10 s) | **FAIL** (no callback in 10 s) | **FAIL** `API_NOT_CONNECTED(17)` |
| E — Google/Firebase dependency diagnostics | PASS | PASS | PARTIAL (E1/E2 pass, E4 fails) | PARTIAL (E1/E2 pass, E4 fails) | PASS |

Debug and Release guest results are identical, so **R8 is not a factor in any Level 9
failure**.

Relaunching the provisioned clone reproduced its row exactly
(`controlled-diagnostic/release-provisioned/guest-relaunch.log`), so the results are
deterministic rather than first-run artefacts.

## What each guest configuration actually sees

### Unprovisioned container — the PackageManager answers inconsistently

Measured inside virtual user 0 and 1:

| Call | Result |
| --- | --- |
| `getPackageInfo("com.google.android.gms")` | `NameNotFoundException` |
| `getApplicationInfo("com.google.android.gms")` | `NameNotFoundException` |
| `getApplicationEnabledSetting("com.google.android.gms")` | **`0`** — answers as though the package exists |
| `getPackageInfo("com.android.vending")` | OK, but reports **33.8.16-21** while the host has **53.0.27-34** |
| `getApplicationInfo("com.android.vending")` | `NameNotFoundException` |
| `queryIntentServices` for five public GMS actions | **all resolve, to real GMS components** |
| `bindService` to `com.google.android.gms/.chimera.GmsApiService` | **succeeds, returns `IGmsServiceBroker`** |

The engine's virtualized PackageManager is not simply hiding Play services. It hides it
from two entry points, answers a third as if it were present, reports a stale version for
the Play Store, and lets intent resolution and service binding through to the genuine host
package.

### Provisioned container — the certificate is genuine, and it still fails

Measured inside virtual user 2 and 3, with `installGms` opted in:

| Probe | Host control | Guest (provisioned) |
| --- | --- | --- |
| GMS versionCode | 263234035 | **263234035** (identical) |
| GMS signing certificate sha256 | `f0fd6c5b…`, `7ce83c1b…`, `5f239127…` | **identical, all three** |
| `isGooglePlayServicesAvailable` | `SUCCESS(0)` | **`SERVICE_INVALID(9)`** |

The container reports the real Google signing certificate history, unchanged. This
**falsifies** the hypothesis recorded in `docs/PHASE_4_COMPATIBILITY.md`, which attributed
`SERVICE_INVALID` to the container being unable to present Google's signing certificate.
It presents it correctly and is still rejected. See `root-cause-analysis.md`.

## Note on reachability of the GMS opt-in

The "Install Google Play services in this clone" checkbox lives in the compatibility sheet,
which is only shown on the **APK-import** path. Cloning an **installed** app goes through
`_quickClone` → `cloneNow`, which passes `installGms: false` and shows no sheet — the code
says so directly at `lib/features/apps/views/app_picker_view.dart:253-261`. So on the
installed-app route the provisioning feature cannot be reached at all. This is existing
product behaviour, not a Level 9 regression, and no code was changed for it.

## Post-fix results — host-platform package visibility

Measured 2026-09-09 on the same device, with `engine-patches/0002-host-platform-package-visibility.patch`
in the shipped `bcore.aar` (sha256 `0178aa0b0fe2…`). Full detail in
`host-passthrough-investigation/`.

Clones were created through the ordinary installed-app flow, so **GMS provisioning was off**
for every run (`GMS provisioning for user N: requested=false` in each clone's log).

| Test | Debug | Release | Result |
| --- | --- | --- | --- |
| A — GMS package detection | PASS | PASS | **PASS** (was FAIL) |
| B — Play services availability | PASS `SUCCESS(0)` | PASS `SUCCESS(0)` | **PASS** (was `SERVICE_MISSING(1)`) |
| C — GMS service resolution and bind | PASS | PASS | **PASS** (no regression) |
| D — GoogleApi client connection | FAIL `17` / `DEVELOPER_ERROR` | FAIL `17` / `DEVELOPER_ERROR` | **BLOCKED** — caller identity, not visibility |
| E — Google/Firebase dependency diagnostics | PASS | PASS | **PASS** (was PARTIAL) |
| F — no fabricated Google account | PASS | PASS | **PASS** |
| G — caller identity coherence (as seen inside the guest) | PASS | PASS | **PASS** |

`Debug`/`Release` above is the diagnostic app's build type. All four combinations of
{debug, release} host app × {debug, release} diagnostic app were measured and agree; a full
`force-stop` and relaunch on each host build reproduced the same verdicts. `isMinifyEnabled`
stayed `true` for every release run.

### Host vs guest metadata

| Property | Host control | Guest (post-fix) |
| --- | --- | --- |
| GMS `versionName` | `26.32.34 (260400-968093310)` | **identical** |
| GMS `versionCode` | `263234035` | **identical** |
| GMS signing certs (sha256) | `f0fd6c5b…`, `7ce83c1b…`, `5f239127…` | **identical, all three** |
| GMS `enabledSetting` | `0` | `0` |
| GSF `versionName` / `versionCode` | `15-12154782` / `35` | **identical** |
| Play Store `versionName` | `53.0.27-34 [0] [PR] 973951861` | **identical** (was fabricated `33.8.16-21`) |
| Play Store `versionCode` | `85302740` | **identical** |
| Play Store `enabledSetting` | `1` | `1` |
| `getInstalledPackages` scope | host | **container only** (unchanged) |

### Why D is BLOCKED rather than FAIL

The pre-fix analysis predicted D would clear once availability (Test B) passed. It did not,
which falsifies that prediction. The measured reason is caller identity, not visibility:

- the guest process runs under the Duplika host UID — `Start proc …:co.tdevs.duplika:p0/u0a962`,
  and `co.tdevs.duplika` is uid `10962` (debug host) / `10963` (release host);
- Play services' own broker logged the guest's binds as `mCallingUid=10962` / `10963`;
- the client library sends the guest's package name, `com.example.duplikaladder.level9gms`;
- the host PackageManager does not associate that package with that UID.

GMS resolves the caller inside its own process against the real host PackageManager, so no
hook in the guest can change what it sees. Closing D would require convincing GMS that the
host UID owns the guest's package — caller-identity spoofing, which is on the forbidden list
and was not attempted. Evidence: `host-passthrough-investigation/gms-caller-identity.log`.

## Real-world application test

NOT TESTED. See the report for why: the controlled diagnostics already determine the
outcome for any app that calls `isGooglePlayServicesAvailable`, and choosing and
downloading a new third-party APK is a decision for the project owner.

## Evidence layout

```
level9-gms/
├── compatibility-matrix.md              this file
├── root-cause-analysis.md
├── controlled-diagnostic/
│   ├── debug/                           host control + unprovisioned guest
│   ├── release/                         host control + unprovisioned guest
│   └── release-provisioned/             GMS-provisioned guest + relaunch
├── package-detection/                   Test A per run
├── play-services-availability/          Test B per run
├── service-resolution/                  Test C intent + service lines per run
├── binder/                              Test C bind lines, plus the container's own
│                                        Play services process log
├── host-passthrough-investigation/      POST-FIX: patch analysis, security review,
│                                        root cause, provisioning review, regression
└── real-app/                            empty — not tested
```
