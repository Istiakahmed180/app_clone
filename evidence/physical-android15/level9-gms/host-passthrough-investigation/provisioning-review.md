# Phase 9 — GMS provisioning feature review

Reviewed, not changed. No provisioning code was modified in this investigation.

## Where it is used

| Layer | Symbol | Note |
| --- | --- | --- |
| UI (sheet) | `compatibility_sheet.dart` — `_installGms` checkbox → `CloneDecision.installGms` | The only user-facing control |
| UI (view) | `app_picker_view.dart:395` — `cloneApk(candidate, installGms: decision.installGms)` | **APK-import route only** |
| UI (view) | `app_picker_view.dart:262` — `_quickClone` → `controller.cloneNow(app)` | **Installed-app route — never passes `installGms`** |
| Controller | `app_picker_controller.dart:358, 488` — `cloneInstalledApp(..., installGms)`, `cloneApk(..., installGms)` | `cloneInstalledApp` defaults to `false` and `cloneNow` never overrides it |
| Dart engine | `real_virtualization_engine.dart:101, 153` → metadata `installGms` | |
| Bridge | `native_bridge.dart:109, 287` → method-channel arg `installGms` | |
| Kotlin bridge | `NativeBridge.kt:280, 320` — `call.argument<Boolean>("installGms")` | |
| Installer | `VirtualAppInstaller.kt` — `provisionGmsIfRequested(virtualUserId, wanted)` | ANDs the opt-in with `analyzer…requiresGms`, then `isGmsSupported()` |
| Engine adapter | `BlackBoxEngineAdapter.kt:217` — `installGms()` → `BlackBoxCore.get().installGms(userId)` | Copies Google packages into the container |

## 1. Its opt-in path is unreachable for installed apps — confirmed on device

The code says so explicitly at `app_picker_view.dart:259-261`:

> *"the missing host permissions and the Play services option lived in the sheet this
> replaced, and there is no other route to either for an installed app."*

`cloneNow` → `cloneInstalledApp` leaves `installGms` at its `false` default. Only the
APK-import route (`cloneApk`) shows `CompatibilitySheet` and can set it true.

Measured today on the CPH2605 for four separate clone operations, on both host builds:

```
Duplika.Install: GMS provisioning for user 0: requested=false     (debug host)
Duplika.Install: GMS provisioning for user 1: requested=false     (debug host)
Duplika.Install: GMS provisioning for user 0: requested=false     (release host)
```

So for the ordinary user flow the feature is already dormant. Everything reported as
working in this investigation was measured with provisioning **off**.

## 2. Does it conflict with host passthrough? — Yes, and provisioning wins

**Confirmed from the code path.** Every patched hook is container-first:

```java
info = BlackBoxCore.getBPackageManager().get…Info(…);
if (info != null) return info;                       // container answers -> host never consulted
if (AppSystemEnv.isVisibleHostPackage(name)) return method.invoke(who, args);
```

In a container where Play services has been provisioned, `BPackageManager` *has* an answer
for `com.google.android.gms`, so the passthrough fallback is never reached. The container's
own copy answers instead — and that copy is the one the pre-fix diagnostics showed cannot
bootstrap its Chimera module set:

```
ChimeraCfgMgr: Failed to read module config: java.io.FileNotFoundException:
  …/blackbox/data/user_de/3/com.google.android.gms/app_chimera/current_config.fb
GmsProxy: Failed to get gms service binder
```

Result pre-fix in a provisioned container: `SERVICE_INVALID(9)`. Result in an unprovisioned
container post-fix: `SUCCESS(0)`.

So the two mechanisms are **mutually exclusive per container**, and the one that wins is
the one that does not work. Enabling provisioning on a clone would actively undo the fix
for that clone.

## 3. Can they coexist safely?

Not usefully, in the current ordering. They can coexist in the codebase — provisioning is
per-container and off by default, so a passthrough clone and a provisioned clone can both
exist on one device without interfering with each other. But within any single container
they cannot both apply, and provisioning takes precedence over the working path.

Making them coexist *usefully* would mean inverting the precedence for these three
packages (host first, container second), which is a larger change to the engine's core
container-first invariant than this investigation's minimal-scope rule allows, and it would
have no benefit while provisioning itself remains broken.

## 4. What it costs

- ~10 s added per clone (previously measured).
- A heavier container — a full copy of the Google packages per virtual user.
- Does not achieve its goal: the copy cannot initialise its Chimera module container, so
  it moves the failure (`SERVICE_MISSING` → `SERVICE_INVALID`) rather than removing it.

## 5. Recommendation

### **DISABLE BY DEFAULT**

Reasons, in order of weight:

1. **It shadows the mechanism that works.** Any clone with provisioning on loses the
   passthrough fix and returns to `SERVICE_INVALID`. That is now the strongest argument,
   and it did not exist before the passthrough landed.
2. **It does not achieve its own goal** — confirmed pre-fix, unchanged.
3. **It is already dormant** on the installed-app route, so defaulting it off matches the
   behaviour users actually get today. The change is small and low-risk.
4. **It costs ~10 s and container size** when it does run.

Concretely: leave the code in place, keep `installGms` defaulting to `false` everywhere,
and remove or disable the checkbox from `CompatibilitySheet` so the APK-import route stops
offering a path that degrades the clone.

### Why not REMOVE LATER (yet)

Removal is the likely end state, but two things are not yet evidenced:

- whether any app exists that genuinely needs a container-local GMS copy rather than host
  passthrough — unknown, and the real-world app test (Phase 7) has not been run;
- whether the Chimera bootstrap failure is fundamental or merely unimplemented. It looks
  fundamental (Play services resolves modules from its own data directory and expects to be
  the platform's singleton GMS), but that is a **hypothesis**, not a measurement.

Recommend revisiting for removal after the Phase 7 real-world test. Deleting it now would
discard the only alternative mechanism before its replacement has been tested against a
real Google-dependent application.

### Not recommended

- **KEEP** as-is — it can only make a clone worse than leaving it off.
- **REMOVE** now — premature, per above.
