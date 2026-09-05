# Phase 4 — App Compatibility Layer

Device of record: **OnePlus CPH2605, Android 15 (API 35), arm64-v8a**.

## Why this phase exists

Phase 3 made it possible to clone any app. It did not make every app *work*. The measured
gaps were concrete:

- `GmsProxy: Failed to get gms service binder` — Google Play Services is not virtualized.
- The host holds the engine's ~322 merged permissions but **none are granted**, and guests
  run under the host's UID, so Android checks the *host's* grants when a guest touches the
  camera, microphone, storage or location.
- Bcore ships native code for `arm64-v8a` and `armeabi-v7a` only.

Before Phase 4 a user could clone any of these and simply watch it misbehave. This layer does
not make incompatible apps work — **it tells the truth before the clone is created.**

## What it does

### 1. Compatibility analysis (`AppCompatibilityAnalyzer`)

For a target package it produces a verdict plus concrete findings:

| Verdict | Meaning |
| --- | --- |
| `SUPPORTED` | Nothing known stands in the way |
| `LIMITED` | Runnable, but something will not work fully |
| `UNSUPPORTED` | Cannot be cloned — a blocking finding exists |

Checks performed, all through public APIs:

| Check | Source | Result |
| --- | --- | --- |
| Secure-environment / self / system component | `AppSecurityChecker` | blocking |
| Native ABI the engine can load | `ApplicationInfo.nativeLibraryDir` (public field, not the hidden `primaryCpuAbi`) | blocking |
| Google Play Services dependency | GMS permission markers, `com.google.android.gms.version` meta-data | non-blocking |
| Runtime permissions the guest needs | guest's requested permissions ∩ host-declared ∩ dangerous | non-blocking |

GMS detection is a **heuristic** and is documented as one: an app that reaches Play Services
without declaring any of the usual markers will not be flagged.

### 2. Permission bridging (`PermissionBridge`)

Because a guest runs under the host's identity, the host must hold the permissions the guest
needs. The bridge asks for exactly those, through the ordinary system dialog.

This is not a privilege escalation and contains no bypass:

- Only permissions the **host already declares** can be requested.
- Only **dangerous** permissions the guest actually declares are asked for.
- Already-granted permissions are filtered out, so no needless dialogs.
- A denial is respected; the user can still clone, and the sheet says so.

### 3. Honest UI

The compatibility sheet appears **before** a clone is created, for both installed apps and
imported APKs. It shows the verdict badge, every finding in plain language, a "Grant N
permission(s)" action, and disables "Add clone" outright when the app is unsupported. The app
list shows a per-row badge for anything not fully supported.

## Results on device

| Check | Result |
| --- | --- |
| VLC analysed | **Limited** — 9 bridgeable permissions outstanding |
| Google Drive analysed | **Limited** — GMS dependency reported, plus 4 permissions |
| Controlled test app analysed | **Supported** — no findings |
| System component / host itself / missing package | **Unsupported** with a blocking finding (instrumentation) |
| Permission dialog appears with correct text | PASS — "Allow Virtual Space to record audio?" |
| Grant is reflected honestly | PASS — allowed notifications only; sheet went 9 → 8, and `dumpsys` confirmed `POST_NOTIFICATIONS granted=true`, `RECORD_AUDIO granted=false` |
| Clone + launch still work through the new flow | PASS — VLC cloned to `user 0` and launched as `ProxyActivity$P0` |

### Test suites

| Suite | Result |
| --- | --- |
| `flutter analyze` | No issues |
| `flutter test` | 61 passed |
| `connectedDebugAndroidTest` | 28 passed on device |

## Defect found by the new tests

`CompatibilityReport.fromMap` used a hard cast (`map['findings'] as List<dynamic>?`) which
threw when the channel payload had an unexpected shape. Every field is now shape-checked
rather than cast. Caught by a deliberately malformed-payload test, not on device.

## Known limitations

- **GMS is still not virtualized.** The layer reports the dependency; it does not fix it.
  Sign-in, push and maps will still fail inside clones of GMS-dependent apps.
- **GMS detection is heuristic** (see above).
- **Permission bridging is host-wide, not per-clone.** Granting the camera for one clone
  grants it to Virtual Space, and therefore to every clone. Per-clone permission scoping
  would require the engine to virtualize permission checks, which it does not.
- The analyzer cannot inspect an imported APK whose package is not installed on the device;
  the sheet falls back to "no known problems" for that case, which is an absence of evidence
  rather than a clean bill of health.
- Banking, payment, authenticator and anti-cheat apps remain untested and out of scope.
- Verified on one device and one OEM build.
