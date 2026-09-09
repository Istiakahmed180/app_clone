# Level 10 — GMS provider migration notes

What changed, what did not, and how to extend it safely.

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
- **All Dart** (`lib/**`) — untouched. GetX intact, no second state-management system, no
  new method channel
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
