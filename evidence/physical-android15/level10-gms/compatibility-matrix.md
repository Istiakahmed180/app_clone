# Level 10 — GMS API reach compatibility matrix

Device: OnePlus CPH2605, Android 15 / API 35 / arm64-v8a
ADB serial: `KNOJORMFV4GERKHM` (verified `device`; `ro.product.model=CPH2605`, `ro.build.version.sdk=35`)
Engine artefact: `android/app/libs/bcore.aar` sha256 `0178aa0b0fe2…` — **unchanged**, no engine change was made for Level 10
Host Play services: `com.google.android.gms` 26.32.34 (versionCode 263234035)
Test date: 2026-09-09

Diagnostic: `compatibility_test_ladder/level10_gms`, package
`com.example.duplikaladder.level10gms`. Release keeps `isMinifyEnabled = true`;
minification was never disabled to obtain any result below.

## Why Level 10 exists

Level 9 measured one Google API — `SettingsClient.checkLocationSettings` — and found
`DEVELOPER_ERROR`. Its conclusion was that the boundary was Play services validating the
caller's package against the Binder calling UID, which in a container do not correspond.

**That conclusion was wrong as a general statement, and Level 10 falsifies it.** A single
probe could not support it: the probe varied nothing, so its failure was equally consistent
with "the framework rejects containerised callers" and "this one API is unavailable".

Level 10 is built as a controlled comparison. Three probes need **no Google account, no API
key and no runtime permission** — the credential requirement is held constant — and differ
only in client layer and API:

| Probe | Client layer | API |
| --- | --- | --- |
| P1 | direct `bindService` + own AIDL | `AdvertisingIdClient` |
| P2 | GoogleApi framework | AppSet ID |
| P3 | GoogleApi framework | `LocationServices` (Level 9's exact API, as control) |

## Results

Host control = the identical APK installed normally. Guest = the same APK cloned through the
ordinary installed-app flow, so **GMS provisioning was off** for every run
(`GMS provisioning for user N: requested=false`, logged per clone).

| Probe | Host Debug | Host Release | Guest Debug | Guest Release | Result |
| --- | --- | --- | --- | --- | --- |
| P0 — package visibility + availability | PASS | PASS | **PASS** | **PASS** | **PASS** |
| P1 — direct-AIDL GMS service | PASS | PASS | **PASS** | **PASS** | **PASS** |
| P2 — GoogleApi framework client | PASS | PASS | **PASS** | **PASS** | **PASS** |
| P3 — LocationServices (L9 control) | PASS | PASS | **FAIL** | **FAIL** | **FAIL** |
| P4 — caller identity trace | PASS | PASS | PASS¹ | PASS¹ | diagnostic only |
| P5 — account-bound APIs | UNSUPPORTED | UNSUPPORTED | UNSUPPORTED | UNSUPPORTED | **UNSUPPORTED / SECURITY-BOUNDARY** |
| P6 — per-API availability | PARTIAL² | PARTIAL² | PARTIAL² | PARTIAL² | narrows P3 |

¹ Self-consistent *inside* the guest only. This says nothing about the host's view and must
not be read as a compatibility pass — see the note below.
² The probe's `queryIntentServices` arm turned out to be the wrong instrument; its
`checkApiAvailability` arm is decisive. See `root-cause-analysis.md`.

Debug and Release are identical on every row, so **R8 is not a factor in any Level 10
result**.

## What the guest actually got back

| Measurement | Host | Guest |
| --- | --- | --- |
| `isGooglePlayServicesAvailable` | `0` SUCCESS | **`0` SUCCESS** |
| `getPackageInfo` / `getApplicationInfo` / `getApplicationEnabledSetting` agree | yes | **yes** |
| GMS declared services visible | 370 | **370** |
| `getInstalledPackages` count | 208 | **1** — container-scoped, isolation intact |
| `AdvertisingIdClient` | id returned, 872 ms | **id returned, 137 ms** |
| AppSet ID | id returned, scope 1 | **id returned, scope 1** |
| `LocationServices` | works | **`DEVELOPER_ERROR`** |
| `checkApiAvailability(LocationServices)` | `available` | **`AvailabilityException: … LocationServices.API: DEVELOPER_ERROR`** |
| Google accounts visible | 0 | 0, **none fabricated** |

Identifier *values* are deliberately not recorded anywhere in the evidence — only their
presence, length and scope. The advertising ID and App Set ID are device/developer-scoped
identifiers and the diagnosis does not need them.

## The finding

**The GoogleApi client framework works inside a container, and Play services accepts a
containerised caller.** P2 is a `GoogleApi` subclass; it went through `GoogleApiManager`,
Play services bound it — its bind is in Play services' own broker log at
`act=com.google.android.gms.appset.service.START` — and it returned a real App Set ID, in
both Debug and minified Release.

So the Level 9 explanation is falsified: if the framework's caller validation rejected
containerised callers, P2 could not have succeeded.

**The real boundary is per-API and is decided locally, before any IPC.** P3 fails in ~20 ms
and produces **no GMS bind at all**, while P2 binds and answers in ~100 ms. The framework's
own per-API check agrees: `checkApiAvailability(LocationServices)` returns
`available` on the host and `DEVELOPER_ERROR` in the guest. The client library concludes
`LocationServices.API` is unavailable without ever connecting.

## Status summary

- **PASS** — package visibility and metadata consistency; Play services availability
  (`SUCCESS(0)`); direct-AIDL GMS services; the GoogleApi client framework itself; a
  non-credentialed GoogleApi call end to end.
- **FAIL** — `LocationServices`, in both Debug and Release, for a reason narrowed to a
  client-side per-API availability decision (see `root-cause-analysis.md`). Root cause is
  narrowed but **not confirmed**, so no fix was attempted.
- **UNSUPPORTED / SECURITY-BOUNDARY** — Google account sign-in and any OAuth-token-bound
  API. Not attempted, and not attemptable legitimately.
- **NOT TESTED** — real-world Google-dependent third-party applications. `real-app-tests/`
  is empty; testing one needs the owner's approval.

No claim is made that Google apps in general work. What is claimed is exactly the four PASS
rows above, each physically measured on the device of record in both build types.
