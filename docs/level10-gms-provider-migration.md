# Level 10 — GMS provider migration notes

What changed, what did not, and how to extend it safely.

> This file covers two phases. The sections up to the divider describe the **provider
> abstraction** phase; **Phase 7 — Legacy GMS provisioning retirement** is at the end and
> supersedes the abstraction phase's "no Dart changed" statement.

## What changed

### New: `android/app/src/main/kotlin/co/tdevs/duplika/native/gms/` (8 files)

| File | Role |
| --- | --- |
| `GmsCapability.kt` | The two capabilities Duplika actually uses |
| `ProviderResult.kt` | Structured outcomes + diagnostics redaction |
| `GoogleServiceProvider.kt` | Provider interface + `ProviderAvailability` |
| `RealGmsProvider.kt` | Adapter over the existing engine calls — the default |
| `MicroGProvider.kt` | Placeholder, no implementation |
| `UnsupportedProvider.kt` | Deterministic refusals |
| `GmsProviderMode.kt` | `AUTO` / `REAL_GMS` / `MICROG` / `DISABLED` |
| `GoogleServiceProviderResolver.kt` | The single selection point |
| `GmsProviderLog.kt` | Injectable diagnostics sink + selection-line formatter |

### New: `android/app/src/test/kotlin/.../gms/GoogleServiceProviderTest.kt`

22 JVM unit tests. First unit-test source set in the Android module.

### Modified: `android/app/src/main/kotlin/co/tdevs/duplika/native/VirtualAppInstaller.kt`

The **only** production behaviour touched. Two changes:

1. Two constructor parameters with defaults — `providerResolver` (defaulting to
   `RealGmsProvider` over the same `adapter` this class already held) and `providerMode`
   (defaulting to `AUTO`). Defaults mean **every existing construction site compiles and
   behaves unchanged**; no caller was edited.
2. `provisionGmsIfRequested` asks the provider instead of the engine directly.

Before:

```kotlin
if (!adapter.isGmsSupported()) { warn; return }
when (adapter.installGms(virtualUserId)) { Success -> Unit; Failure -> error(...) }
```

After:

```kotlin
val provider = providerResolver.resolve(providerMode)   // logs the selection
if (!wanted) return
when (provider.provisionContainerGms(virtualUserId)) {
    Success -> Unit
    Unavailable -> warn(...)          // same warn-and-skip as the old !isGmsSupported branch
    NotImplemented, Unsupported -> warn(...)
    else -> error(...)                // same as the old Failure branch
}
```

With `AUTO` + host GMS present, the engine calls made are the same two, in the same order.

### Modified: `android/app/build.gradle.kts`

One line: `testImplementation("junit:junit:4.13.2")`.

An explicit `sourceSets { getByName("test") { java.srcDir("src/test/kotlin") } }` was added
during the phase and then **removed after verifying it was unnecessary** — the Kotlin
Android plugin already picks up `src/test/kotlin`. Confirmed by re-running the suite without
it: 22 tests still collected. Keeping it would have been dead configuration.

## One deliberate behavioural addition

Provider selection is resolved — and therefore logged — **before** the `if (!wanted) return`
early exit, so "which provider is active, and why" is answerable for *every* clone rather
than only for the rare one that opted into provisioning. Emitting it only on the opt-in path
would have left the normal path silent, which defeats the phase's diagnostic requirement.

Cost: **one extra read-only engine query (`isGmsSupported`) per clone install.** It changes
no outcome — nothing is provisioned unless `wanted`, exactly as before. This is the only
respect in which the code does something it did not do before, and it is stated here rather
than buried.

## What did NOT change

- `android/app/libs/bcore.aar` — untouched, sha256 `0178aa0b0fe2…`
- `engine-patches/**` — untouched
- `BlackBoxEngineAdapter.kt`, `VirtualizationEngineAdapter.kt` — untouched; the provider
  wraps the *interface*, so neither needed an edit
- `AppCompatibilityAnalyzer.kt` — untouched; detecting a guest APK's declared dependency is
  not a Google API call and is not provider-dependent
- `NativeBridge.kt`, `RealVirtualizationEngine.kt` — untouched; they only thread a boolean
- **All Dart** (`lib/**`) — untouched *in the abstraction phase*. Phase 7 below does change
  Dart (the sheet, its call site, and doc comments). GetX stays intact throughout, with no
  second state-management system and no new method channel.
- UID mapping, PackageManager identity, signatures, certificates, account identity, Play
  Integrity, SafetyNet, OAuth, WebView isolation, storage virtualization — untouched
- `compatibility_test_ladder/**` — untouched in this phase

## Migration points for callers

**None.** The new constructor parameters have defaults, so no call site changed and none
needs to. A caller wanting non-default behaviour passes a `providerMode`:

```kotlin
VirtualAppInstaller(context, adapter, securityChecker, analyzer,
    providerMode = GmsProviderMode.DISABLED)
```

## How to add a future provider safely

1. Implement `GoogleServiceProvider`.
2. Make `availability()` reflect the **real** environment — never a constant `AVAILABLE`.
3. Report a capability in `capabilities()` **only** when it genuinely works, verified on a
   device. Reporting one early makes `AUTO` prefer a backend that cannot serve; this is the
   one mistake that breaks the whole layer.
4. Return a modelled `ProviderResult` from every method — never throw, never a plausible
   default.
5. Pass it to `GoogleServiceProviderResolver`; add a mode to `GmsProviderMode` if it needs
   to be requestable.
6. Add unit tests mirroring the existing ones, including that `AUTO` does not select it
   while it reports no capabilities.

## Verification performed

- 22 JVM unit tests — pass, no device
- `flutter analyze` — 4 pre-existing info lints, 0 errors
- `flutter test` — 246/246
- Android Debug + Release builds (minification on) — pass
- Physical, OnePlus CPH2605 / Android 15 / API 35, release build:
  `GMS_PROVIDER requestedProvider=AUTO selectedProvider=REAL_GMS availability=AVAILABLE
  capabilities=[HOST_GMS_PRESENCE,CONTAINER_GMS_PROVISIONING] reason="AUTO selected Real GMS
  because the host has it"`
- Level 10 GMS diagnostic in a fresh clone post-refactor: every probe verdict identical to
  the pre-refactor run

---

# Phase 7 — Legacy GMS provisioning retirement (2026-09-09)

## Why it was retired

Two measured reasons, both from `evidence/physical-android15/level9-gms/`:

1. **It shadowed the mechanism that works.** Every hook in the engine's
   `IPackageManagerProxy` answers from the container first and only then falls back to the
   host. A provisioned container therefore answered GMS queries from its own copy, and the
   host's genuine, Google-signed Play services was never consulted. Ticking the box
   *removed* working host passthrough from that clone — it made the clone worse.
2. **The copy could not start.** It failed its Chimera module bootstrap
   (`app_chimera/current_config.fb: ENOENT`, then `GmsProxy: Failed to get gms service
   binder`), because Play services resolves its real implementation from its own data
   directory and expects to be the platform's singleton. Availability came back
   `SERVICE_INVALID(9)` — versus `SUCCESS(0)` for an unprovisioned container using
   passthrough.

It also cost roughly 10 s per clone and a heavier container.

## Reachability, verified before removing anything

| Route | Before Phase 7 | After |
| --- | --- | --- |
| Installed app (`_quickClone` → `cloneNow` → `cloneInstalledApp`) | `installGms` never set; always `false` | unchanged, `false` |
| **APK import** (`_importApk` → `CompatibilitySheet` → `cloneApk`) | **checkbox could set `true`** — genuinely reachable | checkbox removed; `false` |

So the opt-in was *not* dead code: it was live on one of the two routes. That is why the UI
had to be removed rather than merely defaulted off.

## What replaced it

Nothing new. Host GMS passthrough — already shipped in
`engine-patches/0002-host-platform-package-visibility.patch` — is the mechanism, and it was
already the default for every clone. Phase 7 removed the only way to *opt out* of it.

```
Guest App -> Duplika virtual environment -> Host Android GMS -> Google Play Services
```

## What changed

| File | Change |
| --- | --- |
| `lib/features/apps/widgets/compatibility_sheet.dart` | Removed the `CheckboxListTile`, the `_installGms` state, and `CloneDecision.installGms`. `CloneDecision` is now just `proceed`. |
| `lib/features/apps/views/app_picker_view.dart` | `cloneApk(candidate)` — no GMS argument. Both routes now behave identically. |
| `lib/core/virtualization/virtualization_engine.dart` | Doc comments marking the retained `installGms` parameters as retired / diagnostics-only. |
| `android/.../native/VirtualAppInstaller.kt` | Rewrote the `provisionGmsIfRequested` doc comment: states that provisioning is retired and `wanted` is false on every production path, and **corrects** the old claim that provisioning failed because the container "cannot present Google's signing certificate" — that was falsified. |
| `test/compatibility_sheet_test.dart` | Four obsolete checkbox tests replaced by three guards: the opt-in is gone, the REQUIRES_GMS warning is still shown, a GMS app can still be cloned. |
| `test/real_virtualization_engine_test.dart` | Renamed two tests so they describe the retained diagnostics path rather than a UI opt-in. |

## What was intentionally NOT removed

- **`RealGmsProvider`** and **host GMS availability detection** (`isGmsSupported`) — this is
  how passthrough is gated.
- **`GmsCapability.CONTAINER_GMS_PROVISIONING`** and
  `RealGmsProvider.provisionContainerGms` — retired means unreachable from production, not
  deleted. Modelling it lets a provider *decline* it explicitly, and it is the hook a future
  provider would use if it ever had a legitimate reason to provision.
- **`adapter.installGms` / `BlackBoxCore.installGms`** — engine capability untouched. No
  Bcore change was needed or made.
- **The `installGms` parameter** through the Dart engine interface, bridge, controllers and
  the `NativeBridge` channel argument — retained, defaulting false, documented as retired.
- **The REQUIRES_GMS compatibility warning.** Removing the opt-in must not remove the user's
  only signal that an app depends on Google Play services; a test now guards this.
- **microG architecture** — entirely independent of this phase and unchanged.

## Known imprecision — RESOLVED after Level 10

`AppCompatibilityAnalyzer.kt`'s REQUIRES_GMS message used to read "…which is not virtualized
in this build. Sign-in, push notifications and maps are likely to fail." That was left
untouched during this phase, because rewording a user-facing warning is a separate decision
from retiring a provisioning path, and it was recorded here as a follow-up.

It has since been **corrected**, once Level 10 had the evidence to state the boundary
precisely. "Not virtualized in this build" was measurably wrong: availability returns
`SUCCESS(0)` in a guest and non-identity-scoped Google APIs work (Advertising ID, AppSet ID).
The message now says that Play services *is* available in a clone but that Google features
requiring the app's own identity are not supported — naming sign-in, and location and SMS
verification as identity-bound examples — and that other Google features are unaffected.

Evidence: `evidence/physical-android15/level10-gms/cross-artifact-probe/` and
`docs/level10-cross-artifact-gms-probe.md`. Message only; detection logic unchanged.

## Verification

- `flutter analyze` 4 pre-existing info lints, 0 errors · `flutter test` 245/245 ·
  22 Kotlin unit tests · Debug + Release builds (minification on)
- Physical, OnePlus CPH2605 / Android 15 / API 35, release build:
  - installed-app route (user 11): `requested=false`, `selectedProvider=REAL_GMS`
  - **APK-import route with a GMS-dependent app** (user 12): `requested=false`,
    `selectedProvider=REAL_GMS`, sheet shows the warning and **no checkbox**
  - provisioning actually executed on either route: **0**
  - GMS diagnostic post-retirement: every probe verdict identical to pre-retirement
  - Level 6: job `result=0`, notification posted, `SQLite value=1` (fresh container), 0
    crashes/ANRs
- Evidence: `evidence/physical-android15/level10-gms/provisioning-retirement/`
