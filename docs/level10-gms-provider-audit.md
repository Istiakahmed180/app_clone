# Level 10 — GMS provider audit

Audit completed before any code was written, per the phase brief. Everything below was
established by reading the repository, not from summaries.

## Headline finding: Duplika's production code makes no Google API calls at all

This is the finding that shapes the whole design, so it comes first.

Searched `lib/**/*.dart` and `android/app/src/main/kotlin/**/*.kt` for
`GoogleApi`, `GoogleApiAvailability`, `play-services`, `LocationServices`, `firebase`,
`com.google.android.gms` as a *call target*. Results:

| Surface | Direct GMS usage in production code |
| --- | --- |
| `pubspec.yaml` | **none** — no Firebase, Google, GMS, maps or location package |
| `lib/**` (Dart) | **none** — 3 hits, all comments or a UI string |
| `android/app/src/main/kotlin/**` | **none** — no `GoogleApiAvailability`, no client library import |
| Firebase | **not a dependency anywhere in the app** |

So there is **no `GoogleApiAvailability` check, no `GoogleApi` client, no
`LocationServices` use, and no Firebase initialisation in Duplika itself.**

Why: Duplika is the *host* of a virtualization container. Google APIs are called by the
**guest apps** running inside containers, directly against the host's real Play services,
through the engine's IPC. Duplika is not a participant in that call path — it is the
substrate underneath it. The Level 9/Level 10 GMS results (availability `SUCCESS(0)`,
direct-AIDL services working, AppSet working, LocationServices failing) were all measured
by **standalone diagnostic APKs** (`compatibility_test_ladder/level9_gms`,
`level10_gms`) that deliberately carry no Duplika dependency, precisely so the identical
binary can run on the host and in a container.

**Consequence for this phase:** there is no location, messaging, or GoogleApi-client
functionality in Duplika to put behind a provider interface. Creating
`LocationServiceCapability` / `MessagingServiceCapability` / `GoogleApiCapability` now
would be abstracting nothing — the brief's own rule ("only abstract functionality that
Duplika currently needs", "do not blindly create dozens of interfaces") rules it out. Those
interfaces are named in the architecture document as the extension points to add *if and
when* Duplika itself ever calls such an API, and are not created.

## What Duplika's real GMS surface is

Exactly two operations, both about the *container*, not about calling a Google API:

| # | Operation | Declared at | Meaning |
| --- | --- | --- | --- |
| 1 | `isGmsSupported(): Boolean` | `VirtualizationEngineAdapter.kt:40` | Does the **host** have Google Play services at all. A container can only ever be given what the host already has. |
| 2 | `installGms(virtualUserId): EngineResult<Unit>` | `VirtualizationEngineAdapter.kt:51` | Provision Google packages **into a container** (the experimental path). |

Plus one adjacent concern that is *detection of a third-party APK*, not a GMS call:

| Operation | Declared at | Meaning |
| --- | --- | --- |
| `requiresGooglePlayServices(packageName, info)` | `AppCompatibilityAnalyzer.kt:263` | Heuristic: does the guest app declare a GMS dependency (GMS permission markers, or the `com.google.android.gms.version` meta-data). Used to warn the user and to gate provisioning. |

## Current architecture and entry points

```
Flutter (Dart, GetX)
  app_picker_view / compatibility_sheet   -- user opts a clone into GMS provisioning
        |  CloneDecision.installGms : bool
        v
  app_picker_controller.cloneInstalledApp / cloneApk   (installGms defaults false)
        v
  real_virtualization_engine.dart -> native_bridge.dart   ('installGms' channel arg)
        v
=== MethodChannel boundary ===
        v
  NativeBridge.kt:280,320   call.argument<Boolean>("installGms") ?: false
        v
  RealVirtualizationEngine.kt:119,287   provisionGms: Boolean
        v
  VirtualAppInstaller.kt:36,110   provisionGms && analyzer...requiresGms
        v
  VirtualAppInstaller.provisionGmsIfRequested (:67)
        |-- adapter.isGmsSupported()      (:75)   <-- GMS surface #1
        |-- adapter.installGms(userId)    (:84)   <-- GMS surface #2
        v
  BlackBoxEngineAdapter.kt:214,217  -> BlackBoxCore.get().isSupportGms() / .installGms()
        v
  bcore.aar  (vendored engine)
```

`provisionGmsIfRequested` is therefore the **single integration point** where Duplika
decides anything about Google services. That is where the provider abstraction belongs.

## Current working functionality (physically verified, unchanged by this phase)

From `evidence/physical-android15/level9-gms/` and `level10-gms/`, on OnePlus CPH2605 /
Android 15 / API 35, engine `bcore.aar` sha256 `0178aa0b0fe2…`:

- guest package metadata for `com.google.android.gms` / `com.android.vending` is coherent
  and matches the host (Level 9 patch `0002-host-platform-package-visibility`);
- `isGooglePlayServicesAvailable` = `SUCCESS(0)` in a guest, Debug and minified Release;
- direct-AIDL GMS services work in a guest (`AdvertisingIdClient`);
- the GoogleApi client framework works in a guest (AppSet ID);
- container isolation intact (`getInstalledPackages` = 1 in guest vs 208 on host).

## Known limitations (carried in, not introduced here)

- `LocationServices` fails in a guest with `DEVELOPER_ERROR`, decided client-side before
  any IPC. Root cause narrowed, **not** confirmed — see `level10-gms/root-cause-analysis.md`.
- Google account sign-in / OAuth-bound APIs: **UNSUPPORTED / SECURITY-BOUNDARY**.
- GMS provisioning (surface #2) does not work: the container copy cannot bootstrap its
  Chimera modules, and it **shadows** the working host-passthrough path because the
  PackageManager hooks are container-first. Standing recommendation: DISABLE BY DEFAULT.
  It is also already unreachable on the installed-app route (`installGms` stays `false`).
- `requiresGooglePlayServices` is a declared-marker heuristic and can miss an app that
  reaches GMS without declaring them (documented at `AppCompatibilityAnalyzer.kt:260-262`).

## Files that should be abstracted

| File | Change |
| --- | --- |
| `VirtualAppInstaller.kt` | `provisionGmsIfRequested` should ask a provider rather than the engine adapter directly. This is the only production behaviour change in the phase. |

## Files that must NOT be changed

| File / area | Why |
| --- | --- |
| `android/app/libs/bcore.aar` + `engine-patches/**` | Engine behaviour is out of scope; the artefact is the physically verified one. |
| `BlackBoxEngineAdapter.kt` | Already the thin adapter over `BlackBoxCore`. `RealGmsProvider` wraps the *interface*, so this needs no edit. |
| `VirtualizationEngineAdapter.kt` | The interface contract is what `RealGmsProvider` adapts; changing it would ripple into the engine adapter for no benefit. |
| `AppCompatibilityAnalyzer.kt` | Detects a guest APK's declared dependency. Not a Google API call and not provider-dependent. |
| `NativeBridge.kt`, `RealVirtualizationEngine.kt` | Only thread a boolean through. Provider selection is below them. |
| Dart: `lib/**` | No GMS calls to abstract; GetX architecture stays as is, no second state system. |
| UID mapping, PackageManager identity, signatures, certificates, account identity, Play Integrity, SafetyNet, OAuth, WebView isolation, storage virtualization | Explicitly out of scope, and untouched. |

## Design consequences

1. Two real capabilities: **host GMS presence** and **container GMS provisioning**. Nothing
   else exists to model.
2. Providers must be JVM-unit-testable, so they must not touch Android framework types.
   `EngineResult` (`VirtualizationEngineAdapter.kt:98`) is pure Kotlin — usable. `Slog`
   (`native/Slog.kt`) imports `android.util.Log` — **not** usable directly, so diagnostics
   go through a small injectable sink with a Slog-backed default.
3. There is no `src/test` source set yet (only `androidTest`, which needs a device, and the
   brief forbids device-dependent unit tests). One is added, with JUnit.
4. No user-facing provider toggle is added. The four modes exist and the resolver honours
   all of them, but exposing a switch to Flutter while only one provider actually works
   would be UI for a choice that has one legitimate answer.
