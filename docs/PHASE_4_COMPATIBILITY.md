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

## Consent-path coverage

The permission bridge began with no tests at all, on code that decides what the user is told
about their own consent. Coverage was added in stages, each closing a gap the previous one
left:

| Covered | Where |
| --- | --- |
| Already-granted / empty requests answer without a dialog | `PermissionBridgeTest` |
| Only missing permissions are asked for | `PermissionBridgeTest` |
| `Busy` and `Cancelled` are distinct from `Answered` | `PermissionBridgeTest` |
| A late system result cannot answer a cancelled request twice | `PermissionBridgeTest` |
| Per-permission grant/deny mapping | `PermissionBridgeTest` |
| Another component's request code is left alone | `PermissionBridgeTest` |
| **The production `request(Activity, …)` entry point** | `PermissionBridgeTest` |
| **Outcome → channel envelope mapping** | `PermissionEnvelopeTest` |
| **Dart side: granted/denied parsing, and raising on Busy/Cancelled** | `test/native_bridge_test.dart` |

The last three were added after noticing that the earlier tests all went through the
injectable seam, so the two lines wiring a real `Activity` into it were themselves untested —
as was `permissionEnvelope`, which is precisely where the original defect lived.

`Activity`'s constructor builds a `Handler`, so the entry-point test constructs it inside
`runOnMainSync`. `requestPermissions` is final and cannot be stubbed, so that test covers the
already-granted path, where the bridge correctly never asks.

**Validated by mutation:** re-introducing the original bug — `Busy` mapped to a success
envelope — fails `PermissionEnvelopeTest.aBusyRequestIsAFailureNotASuccess`. Reverted, and the
suite returns to green.

`pending` is `@Volatile`: it is written from the platform thread by `request` and from the main
thread by `onRequestPermissionsResult` and `cancelPending`.

## Home-screen shortcuts

A clone can be pinned to the launcher and opened directly, without passing through Virtual
Space — the thing that makes a dual-app product usable day to day.

| Piece | Role |
| --- | --- |
| `CloneLauncherActivity` | No-UI trampoline. Reads `profileId` + `packageName` from the shortcut intent, launches that container, finishes. |
| `CloneShortcutManager` | Builds the `ShortcutInfoCompat` (guest's own icon, clone's name) and asks the launcher to pin it. |
| Card menu → "Add to home screen" | Entry point. |

Points worth knowing:

- The shortcut carries the **profile id**, not just the package, so "WhatsApp 2" opens the
  second clone rather than the first.
- `requestPinShortcut` succeeding means the **launcher accepted the request**, not that the
  user confirmed it — the launcher shows its own dialog. The message says so rather than
  claiming the shortcut exists.
- Launchers that cannot pin are reported as `SHORTCUTS_UNSUPPORTED` instead of failing quietly.
- The icon falls back to Virtual Space's own when the guest package is not installed on the
  host, which is the normal case for a clone made from an imported APK.
- **Deleting a clone disables its shortcut** with a reason. An app cannot delete a shortcut the
  user pinned, so a stale tile that silently does nothing is the alternative.

Verified on device: the launcher's pin dialog appeared with VLC's icon and name; after
confirming, `dumpsys shortcut` shows it pinned with the intent
`cmp=…/.CloneLauncherActivity` carrying the profile id. Firing that intent from a **cold
start** (app force-stopped) brought up `ProxyActivity$P0` with `org.videolan.vlc` running.

## Guest notifications — measured, and they work

This was listed for several rounds as a missing feature. That was an **assumption, never
tested**. Measured on device, it turns out to work already, so nothing had to be built.

Method: a "Post notification" button was added to the controlled test app, posting text that
carries that instance's own `storedName` and `counter` — so a notification can be traced back
to the instance that sent it.

Result, with the normal installation and one clone both holding distinct state:

```
android.text=String (name=CloneA counter=3)    <- the clone
android.text=String (name=Normal counter=7)    <- the normal installation
```

Both coexist in the shade, each carrying its own isolated state. Tapping the clone's
notification opened `ProxyActivity$P1` showing `Counter: 3 / CloneA` — the clone, not the
normal app.

### How it actually works, and what that costs

| Observation | Evidence |
| --- | --- |
| A guest notification is posted under the **host's** package | `NotificationRecord(... pkg=com.example.virtualspacedemo ... uid 10910)` versus the normal app's `pkg=com.example.virtualtestapp ... uid 10806` |
| The engine **remaps notification ids** so clones cannot collide | guest posted id `1001`, system recorded `640142011` |
| Title and icon still come from the guest | `android.title=(Virtual Test App)`, `icon=Icon(... pkg=com.example.virtualtestapp)` |
| The permission is the **host's**, and the user is told so | the system dialog reads *"Allow **Virtual Space** to send you notifications?"* |
| Force-stopping the host clears guest notifications | they are the host's notifications as far as the system is concerned |

Two consequences worth stating plainly rather than discovering later:

- In notification settings the user manages these under **Virtual Space**, not under the
  cloned app, and cannot silence one clone without silencing all of them.
- `POST_NOTIFICATIONS` is a single host-wide grant. Denying it silences every clone at once.
  This is the same host-identity limit that applies to camera, microphone and storage, and
  the compatibility sheet already reports it: cloning the test app showed
  *"The clone needs 1 permission(s)"* before the grant, and the warning disappeared after.

## Known limitations

- **GMS is still not virtualized.** The layer reports the dependency; it does not fix it.
  Sign-in, push and maps will still fail inside clones of GMS-dependent apps.
- **GMS detection is heuristic** (see above).
- **Permission bridging is host-wide, not per-clone.** Granting the camera for one clone
  grants it to Virtual Space, and therefore to every clone. Per-clone permission scoping
  would require the engine to virtualize permission checks, which it does not.
- Compatibility is now shown on existing clones too, not only in the picker. `HomeController`
  analyses each **distinct** cloned package once per refresh and `ProfileCard` surfaces the most
  serious finding, blocking ones first.

  One trap was designed around: a clone created from an **imported APK** is normally not
  installed on the host, so a naive analysis reports `APP_NOT_FOUND` as a blocking problem.
  That clone has its own container and works fine, so flagging it would be a false alarm about
  the import feature itself. `HomeController.warningsFor` filters `APP_NOT_FOUND` out, and a
  report that could not be produced at all yields no warnings rather than a scary one. Covered
  by `test/home_controller_test.dart` and `test/profile_card_test.dart`.

- Imported APKs are now analysed from the archive itself (`analyzeApk`), so they no longer
  fall back to a clean bill of health. If analysis genuinely fails the sheet says
  **"Not analysed"** rather than "Supported".
- Banking, payment, authenticator and anti-cheat apps remain untested and out of scope.
- Verified on one device and one OEM build.

## Google Play services — measured, and what actually breaks

Until now the compatibility layer flagged GMS-dependent apps as "Limited" on the strength of
manifest markers alone. Nobody had measured what a guest actually sees, so the warning text was
a prediction. It is now a measurement.

### Method

`virtual_test_app` gained a `GmsProbe` that runs the same checks a real GMS-dependent app makes
— `GoogleApiAvailability.isGooglePlayServicesAvailable`, package lookups for
`com.google.android.gms` and `com.android.vending`, and building a Google Sign-In intent — and
logs each line under the `GmsProbe` tag. The app declares `<queries>` for both packages, so a
"not visible" result cannot be blamed on Android 11 package filtering.

The probe was run twice on the same device (emulator `sdk_gphone64_arm64`, Android 17 / API 37,
GMS 26.32.34 installed): once as a normal installation, once as a clone in virtual user 1. No
account is involved anywhere — building the sign-in intent stops short of any credential.

### Result

| Probe | Normal install | Inside a clone |
| --- | --- | --- |
| `isGooglePlayServicesAvailable` | `0` SUCCESS | **`1` SERVICE_MISSING** |
| `com.google.android.gms` | visible, 26.32.34 | **NOT VISIBLE** |
| `com.android.vending` | visible, 52.9.21-34 | visible, **33.8.16-21** |
| Google Sign-In intent | resolves | resolves |

### What this means

**GMS is not broken inside a container — it is invisible.** The guest's package manager does not
report `com.google.android.gms` at all, so every Google API fails its very first check and takes
the "Play services missing" path. This is one root cause, not a scattering of separate defects:
Google Sign-In, FCM push, the Maps SDK and Play Integrity all begin with exactly this call.

Two details sharpen the picture:

- The engine clearly *has* a mechanism for answering package queries on a guest's behalf: it
  reports `com.android.vending` as present, at **33.8.16-21 — a version that is not the one
  installed on this device** (52.9.21-34). That answer is synthesised, not passed through. GMS
  simply is not in whatever table produces it.
- The sign-in intent still **resolves**, because Google Sign-In targets an activity inside the
  calling app rather than GMS. So a cloned app does not fail cleanly at the button. It starts a
  flow that cannot complete, which is why these apps hang or show a generic error instead of
  saying "Google Play services is missing".

### Consequence for the warning text

The current wording — "Sign-in, push notifications and maps are likely to fail" — is accurate,
and "likely" is now the only inaccurate word. On this evidence they *do* fail. The wording is
left as-is until the same probe has run on more than one device.

### Cost of closing the gap

Making GMS visible is not a manifest change. The guest would need its package queries answered
for `com.google.android.gms` and its calls routed to the real service while still running under
the host's identity. That work sits directly against the security posture in `docs/SECURITY.md`:
Play Integrity and SafetyNet attest to *who is calling*, and a container cannot satisfy them
honestly. Any GMS support therefore has a hard ceiling — sign-in and push may be reachable,
attestation is not, and this project does not bypass attestation.

## Provisioning GMS into a container — implemented, and where it stops

The engine already ships the machinery: `BlackBoxCore.installGms(userId)`, `isSupportGms()`, and
a `GmsCore` that installs a set of Google packages (`com.google.android.gms`, `gsf`,
`com.android.vending` and others) into a container, plus `GmsProxy` and
`GoogleAccountManagerProxy` fakes. None of it was being called.

`VirtualAppInstaller` now provisions a container before installing a guest that needs GMS, and
only such containers — the set costs about 3 s on a OnePlus CPH2605, which is not worth paying
for every clone.

### What it changed

Same device, same app, `GmsProbe` inside the container:

| Probe | Not provisioned | Provisioned |
| --- | --- | --- |
| `isGooglePlayServicesAvailable` | `1` SERVICE_MISSING | `9` **SERVICE_INVALID** |
| `com.google.android.gms` | NOT VISIBLE | **visible, 26.32.34** |

Provisioning does what it claims: the guest can now see Google Play services, at the host's real
version. The failure moved from "absent" to "present but rejected".

### Where it stops: SERVICE_INVALID

`SERVICE_INVALID` is `GoogleApiAvailability` reporting that the Google Play services it found is
not authentic — an APK signature check, made by the client library before any Google API is
used. Provisioning cannot satisfy it by installing more packages: the container would have to
present the signing certificate of the real Google Play services.

That is a deliberate stopping point, not an oversight. **It has not been attempted, and should
not be without an explicit decision**, because "make an authenticity check pass" is the same
shape as the security constraints this project holds to in `docs/SECURITY.md`. The narrow,
arguable case — that the host genuinely does have authentic GMS installed and the container is
only failing to report its real certificate — is a judgement for the project owner, not
something to slip in as a bug fix.

So: sign-in, push and maps still fail. They fail one step later, and for a reason that is now
named rather than guessed.

### Two defects this uncovered

**A short-circuit that silently disabled the whole feature.** The first version skipped
provisioning when `isGmsInstalled(userId)` said the container already had it. Decompiling shows
`BlackBoxCore.isInstallGms` delegates to `isInstalled`, which this codebase already documents as
answering from the *host* package manager. The host has GMS, so every container claimed to be
provisioned and nothing ever ran. The check is gone, for the same reason `install()` has no
"already installed?" short-circuit. The provisioning decision is now logged unconditionally.

**R8 broke the guest bind path, but only with GMS present.** A provisioned clone died with

```
java.lang.ClassCastException: android.app.ContextImpl cannot be cast to android.app.Application
    at top.niunaijun.blackbox.app.BActivityThread.handleBindApplication
```

while the identical unprovisioned clone launched fine, and the same provisioned container
launched fine from an unminified build. Keep rules were not enough — the classes were kept and
R8's *optimisation* rewrote the reflection-heavy bind path around them. `-dontoptimize` in
`android/app/proguard-rules.pro` fixes it, verified on device in a minified release build. That
is a blunt instrument; a narrower rule would be better if anyone finds which optimisation is at
fault.

## Real-app test on a physical device (2026-09-06)

Two flagship dual-account apps, already installed on the host, cloned and launched on a
OnePlus CPH2605 (Android 15, arm64) from the minified release build.

| App | Verdict shown | Clone launched | First screen reached | App-process crash |
| --- | --- | --- | --- | --- |
| Telegram (`org.telegram.messenger` 12.10.1) | Limited | yes, `ProxyActivity$P0` | onboarding "Start Messaging" | none |
| WhatsApp (`com.whatsapp` 2.26.34.81) | Limited | yes, `ProxyActivity$P0` | onboarding "Welcome to WhatsApp" | none |

**Isolation, confirmed on real apps.** Both clones opened their own first-run onboarding while
the host's own Telegram and WhatsApp remain set up. A clone that shared the host's data would
show the user's chats, not a welcome screen; it shows the welcome screen, so the container is
genuinely separate. No account was signed into and no Terms were accepted during the test.

### GMS provisioning: what it costs on real apps

Both apps declare the GMS marker, so provisioning ran (~3 s each) and GMS became visible in the
container. At each clone's first launch, the provisioned Google processes threw one-time
background crashes:

- `com.android.vending:background` — `ClassCastException` between obfuscated Play classes
- `com.google.android.gms.persistent` — `SecurityException: Permission Denial ...
  INTERACT_ACROSS_USERS` (the guest runs under the host UID and cannot broadcast as another user)

These are the provisioned Google processes failing, not the guest app: Telegram and WhatsApp
both launched and ran to their onboarding regardless, and while idle nothing crash-loops.

This sharpens the earlier finding. Because the signature wall (SERVICE_INVALID) means
provisioning still delivers no working Google sign-in or push, and Telegram and WhatsApp both
run without GMS anyway, provisioning currently pays a cost (extra background crashes, ~3 s per
clone, a heavier container) for no functional gain on these apps. A reasonable next step is to
make GMS provisioning opt-in per clone rather than automatic, so only an app that genuinely
needs Google sign-in — and a user who accepts the trade — pays for it. That is a product
decision, recorded here rather than taken silently.


## GMS provisioning is now opt-in per clone (2026-09-06)

The measured cost/benefit above — provisioning delivers no working Google sign-in (the
SERVICE_INVALID signature wall) while adding weight and one-time background crashes, and the
flagship apps run without it — made automatic provisioning the wrong default. It is now off by
default and chosen per clone.

- The compatibility sheet shows a checkbox, **"Install Google Play services in this clone"**,
  only when the app declares a GMS dependency. It is unchecked by default and labelled as
  experimental (slower, heavier, sign-in may still fail).
- The choice threads through `createProfile`/`createProfileFromApk` → the bridge's
  `installGms` argument → `VirtualAppInstaller`, which provisions only when the user opted in
  *and* the app actually needs GMS. The decision is logged (`GMS provisioning for user N:
  requested=...`).
- The failed-launch repair path rebuilds without GMS: the opt-in is not persisted per profile,
  so repair cannot know it, and re-provisioning would re-add the non-functional Google packages
  and their crashes. If the opt-in is ever persisted on the profile, thread it through `repair`.

Verified on the OnePlus CPH2605 in a minified release build, cloning Discord (a GMS-marker
app) twice:

| Clone | Checkbox | Log | GMS packages installed |
| --- | --- | --- | --- |
| user 4 | unchecked | `requested=false` | no |
| user 5 | checked | `requested=true` → `Provisioned Google Play services` | yes |

Tests: `test/compatibility_sheet_test.dart` covers the checkbox's visibility and that the
returned decision defaults off and flips when ticked; `test/real_virtualization_engine_test.dart`
covers `installGms` defaulting false and being forwarded on both the installed-app and APK paths.

## Full real-app test matrix (2026-09-06, clean reinstall)

Virtual Space uninstalled (all containers dropped) and reinstalled from the release build, then
five real apps cloned with the default configuration (GMS opt-in OFF) and launched on the
OnePlus CPH2605 (Android 15 / API 35).

| App | Cloned | Launched | First screen | Result |
| --- | --- | --- | --- | --- |
| Telegram | yes | `ProxyActivity$P1` | "Start Messaging" onboarding | ✅ clean, 0 crashes |
| Discord | yes | `ProxyActivity$P0` | "Welcome to Discord" | ✅ clean, 0 crashes |
| VLC | yes | `ProxyActivity$P0` | "Welcome to VLC!" | ✅ clean, 0 crashes |
| WhatsApp | yes | `ProxyActivity$P0` | "Welcome to WhatsApp" | ⚠️ reaches onboarding; one background worker crash (see below); process survives |
| Facebook | yes | fell back to host UI | — | ❌ process crashes on startup (see below) |

So three of five (and the two flagship messengers minus WhatsApp's caveat) launch cleanly to
their first screen with isolated containers and no GMS provisioning.

### The two failures are engine/GMS-deep, not app-layer bugs

**WhatsApp — AppOps hook stale for API 30+.** A background worker crashes with:

```
java.lang.ClassCastException: Couldn't convert result of type java.lang.Integer
    to android.app.SyncNotedAppOp
    at $Proxy37.noteOperation
    at AppOpsManager.noteOpNoThrow
    at Environment.isExternalStorageLegacy
    at ...AbstractAppShellDelegate.lambda$performAsyncInit
```

The engine replaces `IAppOpsService` with its own proxy so guest app-ops resolve under the host
identity. That proxy returns the pre-Android-11 `int` from `noteOperation`, but API 30+ expects
a `SyncNotedAppOp`, so any guest that calls `Environment.isExternalStorageLegacy()` during init
(WhatsApp does; Telegram, Discord and VLC do not) hits a `ClassCastException`. WhatsApp's shell
tolerates it — the process stays up and onboarding is usable — but storage-dependent features
may be affected, and registration past the phone-number step is unverified.

**Facebook — Firebase InstanceID legacy path under GMS absence.** The process crashes with:

```
java.lang.IllegalArgumentException: com.facebook.katana: Targeting S+ requires that one of
    FLAG_IMMUTABLE or FLAG_MUTABLE be specified when creating a PendingIntent.
    at PendingIntent.getBroadcast
    at firebase-iid-executor
```

This is Facebook's own bundled Firebase code. With no reachable Google Play services, Firebase
InstanceID falls back to a legacy self-broadcast path that builds a `PendingIntent` without the
mutability flag Android 12+ requires, and throws. It is triggered by GMS absence but the faulty
call is inside the app, not the engine.

### Why these are not fixed here

Both live below the Flutter/adapter layer this project controls:

- The AppOps proxy is compiled into `libblackbox`/`classes.jar`. There is no `ClientConfiguration`
  switch for it, and the engine source is not vendored, so its return type cannot be corrected
  from the app. This is the same class of limitation as the GMS signature wall — it needs a
  newer or patched engine (which is also why apps like Phantom, on a more current core, run
  WhatsApp: their AppOps hook returns the modern `SyncNotedAppOp`).
- The Facebook crash is in a third-party app's own library reacting to GMS absence; the app layer
  cannot rewrite Facebook's PendingIntent call.

Neither was papered over. Recorded here so the engine-upgrade decision is made on evidence.
