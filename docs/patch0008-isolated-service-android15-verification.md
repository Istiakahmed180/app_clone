# Patch 0008 — Android 15 isolated-service instance name: implementation and verification

**Status: PARTIAL.**

The confirmed defect is fixed and stays fixed: the `IllegalArgumentException` that killed
Chrome is gone, and Chrome now reaches a working New Tab page with a real renderer and GPU
process — something previously impossible. It is not reliable, because a **pre-existing,
separately-documented defect** (Defect B, `Unable to makeApplication`) now sits on the
critical path and fails roughly half of guest launches.

**Chrome is NOT declared fixed.**

| Artifact | Value |
|---|---|
| Engine before | `f38fa7d3ef7a08f6defe61a95c11eb1f99ef2adb3617b47f62fb1726c10be4af` |
| Engine after | `7769e0d4cfa09ee1d9b42d76d74b6c7761602546734c49715cb6228329df160d` |
| Patch | `engine-patches/0008-isolated-service-android15.patch` |
| Device | OnePlus CPH2605, Android 15 / API 35, arm64-v8a |
| App build | release, R8 minified (`isMinifyEnabled = true`) |
| Chrome | 152.0.7977.82 (797708204), 6 splits |

---

## 1. Argument index — verified, not assumed

Read from the device's own `/system/framework/framework.jar` (`dexdump` of `classes.dex`),
`android.app.IActivityManager.bindServiceInstance`:

```
(Landroid/app/IApplicationThread;   0 caller
 Landroid/os/IBinder;               1 token
 Landroid/content/Intent;           2 service
 Ljava/lang/String;                 3 resolvedType
 Landroid/app/IServiceConnection;   4 connection
 J                                  5 flags
 Ljava/lang/String;                 6 instanceName     ← cleared by this patch
 Ljava/lang/String;                 7 callingPackage   ← already rewritten by BindServiceCommon
 I)I                                8 userId
```

Exactly 9 parameters. `args[6]` is the instance name.

**The sibling hook is provably dead on API 35.** In the same framework image,
`bindIsolatedService` is declared only on caller-side classes —
`android.content.Context`, `android.app.ContextImpl`, `android.content.ContextWrapper`,
`android.app.ReceiverRestrictedContext` — and **not** on `android.app.IActivityManager`.
`ClassInvocationStub#initAnnotation` binds hooks by name against the proxied interface, so
`@ProxyMethod("bindIsolatedService")` binds to nothing. Every isolated bind arrives at the
`bindServiceInstance` hook.

---

## 2. The diff

```diff
--- a/Bcore/src/main/java/top/niunaijun/blackbox/fake/service/IActivityManagerProxy.java
+++ b/Bcore/src/main/java/top/niunaijun/blackbox/fake/service/IActivityManagerProxy.java
@@ -426,6 +426,12 @@ public class IActivityManagerProxy extends ClassInvocationStub {
     public static class bindServiceInstance extends MethodHook {
         @Override
         protected Object hook(Object who, Method method, Object[] args) throws Throwable {
+            // args[6] is instanceName. Context.bindIsolatedService() reaches
+            // IActivityManager through this method -- IActivityManager itself declares no
+            // bindIsolatedService, so the sibling hook below never runs -- and the guest's
+            // instance name would then be applied to a ProxyService$PN, which is not an
+            // isolated service. ActivityManagerService rejects that combination.
+            args[6] = null;
             return BindServiceCommon(who,method,args,7);
         }
```

One statement plus a comment. Patches 0001–0007 untouched; all eight apply cleanly in order
onto the pinned upstream commit, and the only file 0008 changes is
`IActivityManagerProxy.java` (`6 +`).

---

## 3. Isolated-service fixture (`level12_isolatedservice`)

| Cell | Call | Host (reference) | Guest, pre-0008 (recorded §9 of the stay-signed-out doc) | Guest, post-0008 (measured) |
|---|---|---|---|---|
| **P1** | `bindIsolatedService`, isolated svc, `instanceName="0"` — Chrome's shape | connected, isolated uid **99020** | **THREW** `IllegalArgumentException` | **no longer throws**; `accepted=true connected=false` (6188 ms) |
| **P2** | `bindService`, isolated svc, no instance name | connected, isolated uid 99021 | accepted, never connected | accepted, never connected (6170 ms) — **unchanged** |
| **P3** | `bindIsolatedService`, non-isolated svc + instance name | **THREW** (the platform's own rule) | THREW | **still THREW** (41 ms) — but a *different* exception, see below |
| **P4** | `bindService`, non-isolated svc | connected, app uid 10973 | accepted, never connected | not reached (run aborted by the crash dialog) |

Two things matter here.

**P1 is fixed at the layer this patch targets.** The AMS rejection is gone.

**P2 is the proof that what remains is not this patch's doing.** P2 passes no instance name
at all and goes through the untouched `bindService` hook, yet fails identically. Its failure
was already recorded before 0008 existed.

**P3 still throws, which satisfies the pre-existing acceptance matrix — but not for the
original reason.** On the host it throws AMS's `IllegalArgumentException`. In the guest
post-0008 it throws `SecurityException: Not allowed to bind to service …PlainService` from
`ContextImpl.bindServiceCommon(ContextImpl.java:2209)`, i.e. AMS returned a negative result
rather than refusing on instance-name grounds. **Why is not established.** It plausibly
follows from the two preceding failed binds in the same run having poisoned the `:p1` slot,
rather than from a semantic change. Recorded as unexplained.

This is worth flagging against §15 of the stay-signed-out investigation, which predicted that
clearing the instance name unconditionally "would be a real regression" for pass-through
binds. In measurement, P3 did **not** become permissive. The prediction did not materialise,
but the mechanism that prevented it is not understood, so the concern is not fully retired.

---

## 4. Chrome — five runs, measured

| Run | Launch | Outcome |
|---|---|---|
| 1 | 10:03:44 | FRE at 10:04:19. "Stay signed out" tapped 10:04:30. Renderer bind **accepted**; proxy process started; `makeApplication` failed → no renderer. **Chrome stayed alive 278 s** (to 10:08:22+), FRE never advanced. |
| 2 | 10:08:48 | Guest never started — `makeApplication` failure on the browser process itself. |
| 3 | 10:10:17 | **Full success.** Browser + GPU + renderer all up; FRE completed; **New Tab page reached** with live Discover content; navigation to `example.com` committed and spawned a fresh renderer. |
| 4 | 10:15:20 | Guest never started — `makeApplication` failure at `ProxyActivity$P1`. |
| 5 | 10:17:40 | Browser + GPU + renderer up; Chrome restored its `example.com` session across relaunch; the page itself did not render — that tab's renderer died. |

### Run 1 — the fix working, and the next wall

```
10:04:26.132  BProcessManager: initProcess: com.android.chrome:sandboxed_process0
10:04:27.597  ActivityManager: Start proc 15015:co.tdevs.duplika:p1/u0a977
                  for service {co.tdevs.duplika/…ProxyService$P1}      ← BIND ACCEPTED
10:04:27.830  RuntimeException: Unable to bind to service ProxyService$P1 : Unable to makeApplication
              Caused by: RuntimeException: Unable to makeApplication              (handleBindApplication:521)
              Caused by: RuntimeException: Unable to makeApplication - all fallback attempts failed (:426)
              Caused by: ClassCastException: android.app.ContextImpl cannot be cast to
                         android.app.Application                                  (:394)
              → proxy process 15015 dies; retried 10:04:27.965, 10:04:52.793
```

Before 0008, AMS refused the bind and **no proxy process was ever created**. Now the process
is created and execution proceeds to the next stage. This is exactly the predicted
"instanceName null → Android accepts → next observable Chrome stage".

Because the failure is now in a *separate* process rather than an exception thrown back into
Chrome's launcher thread, Chrome no longer aborts — it simply waits for a renderer that never
arrives. That is the "Stay signed out does nothing" symptom, with the crash removed.

### Run 3 — guest renderer and GPU, at Duplika's uid

```
21837  u0_a977  co.tdevs.duplika
21862  u0_a977  co.tdevs.duplika:black
22105  u0_a977  com.android.chrome
22211  u0_a977  com.android.chrome:privileged_process0     ← GPU process
22789  u0_a977  com.android.chrome:sandboxed_process0      ← renderer
```

All at `u0_a977`, Duplika's own uid — these are the guest's processes, not host Chrome's.
This is the same externally-visible process set that MultiApp Ultra showed at its own uid.
Across the session the guest also produced `privileged_process1`.

The New Tab page rendered the Google omnibox, shortcut tiles, tab counter, and a live
Discover feed with network-fetched content — which requires a working renderer.

### Marker counts

| Marker | Pre-0008 (09:27–09:34) | Post-0008 (10:03–10:20) |
|---|---|---|
| `Can't use instance name` | 8 | **0** |
| `cr_JniAndroid: Handling uncaught` | 2 | **0** |
| SIGTRAP browser aborts | 4 of 4 launches | **0** |
| `Unable to makeApplication` | 0 | 41 |
| `ContextImpl cannot be cast to Application` | 0 | 28 |
| Guest child processes seen | `sandboxed_process0` (name only, never created) | `sandboxed_process0`, `privileged_process0`, `privileged_process1` (**created**) |

---

## 5. Criteria

| # | Criterion | Result |
|---|---|---|
| 1 | Launch Chrome inside Duplika | **PASS** (intermittent, see 9) |
| 2 | First-run experience renders | **PASS** |
| 3 | "Stay signed out" completes without Chrome exiting | **PASS** — completed in run 3; Chrome never exited in any run |
| 4 | Chrome reaches normal New Tab | **PASS** — run 3, with live content |
| 5 | Renderer process starts | **PASS** — `sandboxed_process0` at `u0_a977`, runs 3 and 5 |
| 6 | GPU/renderer behaviour remains stable | **FAIL** — renderers die; not stable |
| 7 | Browse a simple HTTPS page | **FAIL** — `example.com` committed and spawned a renderer, but never rendered |
| 8 | Relaunch Chrome | **PARTIAL** — works, ~50% of the time |
| 9 | Chrome starts again and remains alive | **PARTIAL** — same |

The five original Phase 10 criteria: alive ≥60 s **PASS** (278 s), renderer starts **PASS**,
Stay signed out completes **PASS**, New Tab appears **PASS**, relaunch works **PARTIAL**.
Four of five pass outright; the fifth is unreliable. Hence PARTIAL, not PASS.

---

## 6. Regression results

| Check | Result |
|---|---|
| `usermanagerprobe` — patch 0006 guard | **PASS** — P1 `getApplicationRestrictions(OWN)` SUCCESS (`bundleNull=false keyCount=0`), P2 `getUserRestrictions()` SUCCESS (`keyCount=1`), P3 `isSystemUser()` SUCCESS; `virtualized=true virtualUserId=2`, release/minified |
| `level11_isosplit` — patch 0007 guard | **PASS** — "VERDICT: PASS — split-manifest component registration works"; launched `isosplit.feature.MainActivity` from the feature split; `splitSourceDirs=1` |
| Level 6 — modern-API fixture | **PASS** — guest UI reached; `SQLite value=1`; `notification posted channel=level6`; `job schedule result=0`, which is the **modal historical value** (13 recorded `=0` vs 4 `=1`), so not a change |
| Level 7 / 8 — VLC (real app, native, config splits) | **PASS** — guest UI (`StartActivity` → `OnboardingActivity`); `libvlc.so` and `libvlcjni.so` loaded from `split_config.arm64_v8a.apk`; `libvlc 3.0.23 Vetinari` initialised |
| `flutter analyze` | **0 errors** (4 pre-existing info lints) |
| `flutter test` | **276/276 passed**, 0 failed, 0 skipped |

Level 8's Markor / Fossify Notes / AntennaPod cells and the WebView-isolation tests were
**not** run. Debug-build runs were **not** performed; everything above is release + R8.

> The test count rose from 240 to 276 because an unrelated settings feature landed in the
> working tree from outside this work during the session. Those 36 tests are not mine and
> all pass.

---

## 7. Newly discovered blocker — Defect B, with its root cause

This is not a new defect. §10 of `chrome-stay-signed-out-android15-investigation.md` already
named it ("**Defect B — guest binds never connect (API 35)**… `Unable to makeApplication`")
and §21 recorded that its root cause "was not investigated". This run supplies that root
cause:

```
BActivityThread.handleBindApplication
  ├─ BRLoadedApk.get(loadedApk).makeApplication(false, null)   → null / threw
  ├─ BRLoadedApk.get(loadedApk).makeApplication(true, null)    → null / threw
  └─ application = (Application) packageContext;               ← ClassCastException, always
```

The final fallback casts the guest's `ContextImpl` to `Application`. A `ContextImpl` is never
an `Application`, so **this fallback cannot succeed under any circumstances** — it is a
dead-end that converts "makeApplication returned null" into a fatal `ClassCastException`.
The observable crash is therefore the broken fallback, not the underlying cause.

The underlying cause — why both `LoadedApk.makeApplication()` attempts fail — is **still not
determined**. Bcore logs it (`Slog.e(TAG, "Failed to makeApplication…")`, and `Slog` is not
gated), but no such line appeared in this release run, so the branch taken is unknown from
this evidence.

**Scope.** Defect B is not confined to services. It also killed the guest **activity** path
(`Start proc …:p1 for next-top-activity {ProxyActivity$P1}` → same `ClassCastException`),
which is what makes launches intermittent.

**Attribution.** Defect B's counts went 0 → 41 across the patch, which needs care:

- Pre-0008, AMS refused the bind *before* any proxy process existed, so `makeApplication` was
  never reached. Post-0008 the bind is accepted, so execution reaches that stage for the
  first time. This accounts for the service-path instances.
- The **activity-path** instances are *not* explained that way — `ProxyActivity$P1` involves
  no `bindServiceInstance` — and pre-0008 the browser activity launched in 2 of 2 attempts.
- Memory pressure was checked and does **not** explain it: LMK/CEM app deaths ran at
  ~5.1/min pre-0008 versus ~4.4/min post-0008, and `:black` died once pre versus twice post
  over twice the duration.

So whether 0008 contributes to the activity-path failures is **open**. Settling it needs an
A/B: restore the 0007 AAR and measure launch success over N matched attempts. **That A/B was
not run.** Until it is, I do not claim 0008 is free of responsibility here.

---

## 8. Security impact

None introduced. The change **removes** a parameter from a request the guest makes of the
host, which narrows rather than widens what the guest can ask for. Specifically, nothing in
this patch touches:

- uid or package identity — untouched; guest processes still run at the container's own uid
- caller identity — `callingPackage` handling is unchanged (`args[7]`, pre-existing)
- signatures, certificates, or signature verification
- Play Integrity / SafetyNet
- SELinux
- GMS identity handling
- `ProxyService` isolation attributes — no `android:isolatedProcess` was added; nothing
  pretends to be an isolated process
- exception handling — no broad `catch` was added or widened

There is no Chrome-specific branch, no package-name check, and no behaviour copied from any
third-party container. AMS continues to apply all of its own checks to the proxy component;
the host-side isolated-process rule is confirmed still enforced against the host (fixture P3
on the host still throws).

The one honest semantic caveat: a guest that legitimately relies on **distinct** isolated
service instances now gets them coalesced onto one proxy slot instead of an exception.
`ActiveServices#bindService` picks the slot from `serviceInfo.processName` alone, so all
instances of `SandboxedProcessService0` share `:p1`. This patch does **not** provide real
isolated processes and does not attempt MultiApp's ~20 concurrent renderers.

---

## 9. Files changed

| File | Kind |
|---|---|
| `engine-patches/0008-isolated-service-android15.patch` | new patch |
| `android/app/libs/bcore.aar` | rebuilt (`f38fa7d3…` → `7769e0d4…`) |
| `docs/patch0008-isolated-service-android15-verification.md` | this document |
| `evidence/physical-android15/patch0008/**` | evidence (new) |

Patches 0001–0007 unmodified. The concurrent settings feature in the working tree was not
touched. Nothing committed.

---

## 10. Recommended next step — reported, not taken

Defect B is now the sole blocker on the Chrome path and its observable failure is a fallback
that can never succeed. The smallest useful next move is diagnostic, not corrective: make the
`makeApplication` failure legible before changing it.

The `(Application) packageContext` fallback should also be deleted rather than repaired — it
cannot work — but doing so only changes which exception is thrown, and would remove the one
marker currently making Defect B visible. Both are separate decisions and are **not** made
here.
