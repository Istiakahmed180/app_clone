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
| `connectedDebugAndroidTest` | 29 passed on device |

## Defect found by the new tests

`CompatibilityReport.fromMap` used a hard cast (`map['findings'] as List<dynamic>?`) which
threw when the channel payload had an unexpected shape. Every field is now shape-checked
rather than cast. Caught by a deliberately malformed-payload test, not on device.

## Review pass — defects found and fixed

A recheck of the Phase 4 code found three defects in the permission bridge, all in the paths
where a request does *not* simply succeed:

1. **A refused request reported success.** When a permission request was already on screen,
   the bridge invoked the callback with an empty map, which the bridge turned into
   `PERMISSIONS_REQUESTED — "Permission request finished."` The UI would have told the user
   their answer had been recorded when they were never asked. The callback now carries a typed
   outcome — `Answered` / `Busy` / `Cancelled` — and only `Answered` produces a success
   envelope.

2. **An interrupted request left the caller waiting forever.** If the host went away while the
   system dialog was up, `onRequestPermissionsResult` never reached that bridge instance, the
   `MethodChannel.Result` was never completed, and the Dart future never resolved — the sheet
   would sit on "Waiting for your answer…" indefinitely. `cancelPending()` now completes such a
   request as `Cancelled`, and is called from both `unbindActivity()` and `detach()`.
   **Verified on device:** the dialog was started and then abandoned by leaving the app; the
   sheet recovered to "Grant 9 permission(s)" rather than hanging.

3. **The permission reply was not guarded against a detached channel** — the same defect
   already fixed for engine calls, but reintroduced on this path. Both now go through a shared
   `reply()` helper that drops the reply if the bridge has been detached.

The UI also now surfaces *why* a request did not happen, instead of silently showing an
unchanged sheet.

### ABI detection verified, not assumed

Modern apps commonly ship `extractNativeLibs=false`, which leaves the per-ABI directory empty.
Had detection regressed, arm64 apps would have been blocked outright with a false
`UNSUPPORTED`. A test now analyses up to 20 real installed apps that carry native code and
asserts none is blocked on ABI. It passes on the test device.

## Second review pass — an overclaim, and a real-world security miss

**The sheet presented unanalysed APKs as problem-free.** For an imported APK whose package was
not installed on the device there was nothing to inspect, so the import flow passed
`CompatibilityReport.unknown` — which carried `verdict: supported` and no findings, and
therefore rendered as **"Supported / No known compatibility problems."** A widget test
(`test/compatibility_sheet_test.dart`) was written to demonstrate this before it was changed.

Two things were done rather than one:

1. `AppCompatibilityAnalyzer.analyzeApk(apkPath, packageName)` now analyses the archive
   directly — secure-environment declaration, GMS markers, bridgeable permissions from the
   archive's requested permissions, and the ABIs actually shipped in its `lib/` entries. An
   imported APK is judged on evidence before anything is installed.
2. `CompatibilityReport.unknown` is no longer `supported`, and carries `analysed = false`. When
   analysis truly cannot run, the sheet shows **"Not analysed"** and says plainly that nothing
   is known and the clone may still be refused.

**A non-boolean property made the installed path miss a real app.** `REQUIRE_SECURE_ENV` is
compiled by aapt2 as the **integer 1**, not a boolean. The check required
`Property.isBoolean`, so Google Authenticator — which genuinely ships
`<property android:name="REQUIRE_SECURE_ENV" android:value="true"/>`, verified with
`aapt2 dump xmltree` — was offered for cloning with verdict "Limited". It is now refused, with
a disabled "Cannot clone" button. This also confirms the canonical property name, which had
until then been a guess.

Both were found by testing against real installed applications rather than fixtures alone.

## Third review pass

**A failed analysis was reported as "Unsupported".** `NativeBridge.analyzeApp` and
`analyzeApk` parsed `response.data` without checking `response.success`. On a bridge failure
the payload is empty, and `CompatibilityVerdict.parse(null)` returns `UNSUPPORTED` — so a
transient error rendered as badge **"Unsupported"**, the line **"No known compatibility
problems."**, and a disabled *Cannot clone* button. The user was blocked, told there were no
problems, and given no reason, all at once.

Both calls now return `CompatibilityReport.unknown` when the call did not succeed, so the
sheet says **"Not analysed"**. Covered by two tests in `test/native_bridge_test.dart` that
failed before the change.

### Fourth pass: a designed error path that could never run

`NativeBridge.listInstalledApps` also ignored `response.success` and returned an **empty
list** on failure. The picker renders an empty result as *"No matching apps — try a different
search, or import an APK instead"*, so a bridge failure told the user they had no apps.

`AppPickerController.loadApps` already catches `AppException` and the view already renders a
*"Could not list apps"* state — that path was simply unreachable, because a failure envelope
is data, not an exception. The call now raises `VirtualizationException` on failure, so the
error UI that was written for this finally runs.

A hard cast in the same method (`app as Map<Object?, Object?>`) would have thrown on a single
malformed entry and lost the whole listing; entries are now filtered by type instead.

Both covered by tests that failed before the change.

### Checks that found nothing

Recorded so they are not repeated blindly:

- **Differential analysis.** For 20 real installed apps, `analyze(package)` and
  `analyzeApk(sourceDir, package)` were compared on blocking findings and GMS verdict. They
  agree on every one. Kept as a permanent test.
- **GMS heuristic against real manifests**, verified with `aapt2 dump xmltree`: Drive and
  Telegram declare all three markers and are flagged; VLC and the controlled test app declare
  none and are not. VLC does contain a few incidental `com.google.android.gms` references
  without the markers, and not flagging it is the right call — it runs without Play Services.

## Known limitations

- **GMS is still not virtualized.** The layer reports the dependency; it does not fix it.
  Sign-in, push and maps will still fail inside clones of GMS-dependent apps.
- **GMS detection is heuristic** (see above).
- **Permission bridging is host-wide, not per-clone.** Granting the camera for one clone
  grants it to Virtual Space, and therefore to every clone. Per-clone permission scoping
  would require the engine to virtualize permission checks, which it does not.
- Imported APKs are now analysed from the archive itself (`analyzeApk`), so they no longer
  fall back to a clean bill of health. If analysis genuinely fails the sheet says
  **"Not analysed"** rather than "Supported".
- Banking, payment, authenticator and anti-cheat apps remain untested and out of scope.
- Verified on one device and one OEM build.
