# MultiApp Ultra vs Duplika — Chrome behavioural compatibility study

**Device.** OnePlus CPH2605, Android 15 / API 35, arm64-v8a.
**Guest.** `com.android.chrome`, split APK, 6 splits (`base, chrome, config.en, dev_ui,
on_demand, stack_unwinder`).
**Duplika.** `co.tdevs.duplika`, release build (R8 minified) at `70b6431`, engine
`android/app/libs/bcore.aar` (`sha256 f38fa7d3…be4af`, unchanged since `9387659`,
patches 0001–0007 applied).
**Reference container.** MultiApp Ultra, package `com.waxmoon.ma.nova.gp` v1.3.1
(`versionCode 1301`). Used strictly as a black box: launched, observed through
`ps`, `dumpsys` and `logcat`, and screenshotted. Nothing was decompiled, extracted,
modified, or read from its private storage.

**Runs covered here.**

| Run | Date | Container | Chrome |
|---|---|---|---|
| A | 2026-09-09 17:49–17:56 | MultiApp Ultra | 152.0.7977.75 (797707504) |
| B | 2026-09-09 17:57–18:10 | Duplika (2 attempts) | 152.0.7977.75 (797707504) |
| C | 2026-09-10 09:27–09:34 | Duplika (2 attempts, fresh clone) | 152.0.7977.82 (797708204) |

Runs A and B are the same-day, same-Chrome-version head-to-head. Run C is today's
live re-confirmation on the current build; Chrome had auto-updated to `.82` in the
interim, and the failure is byte-for-byte identical, so the defect is not
version-specific.

A live re-run of MultiApp Ultra was attempted today (09:25:57) and **stopped at its
first-run Terms-of-Service / privacy-consent gate**. Accepting a third party's terms
on the user's behalf was not authorised, so the app was backed out of without
tapping Accept or Decline. The MultiApp baseline below is therefore run A only.
Screenshot: `evidence/physical-android15/multiapp-reference/run-2026-09-10/ma_10_consent_gate_NOT_ACCEPTED.png`.

---

## 1. MultiApp Ultra — observed Chrome flow (run A)

| Time | Observation |
|---|---|
| 17:49:36 | Container launched |
| 17:50:12 | `Start proc 11049:com.waxmoon.ma.nova.gp:proxy.p0/u0a967 for next-top-activity {…AssistActivity$P0}` — Chrome browser process |
| 17:50:15 | Guest reports `processName=com.android.chrome isIsolatedProcess=false` |
| 17:50:38–17:52:20 | ~20 further guest processes created, **each `for content provider {…ProxyProvider$PN}`** |
| 17:50:43 | Chrome first-run UI visible |
| 17:52:08 | FRE button tapped, bounds `[61,2103][1019,2225]` |
| 17:52:38 | Normal Chrome New Tab page reached |
| 17:54:19 | Browser pid 11049 killed (signal 9) — coincides with the tester's relaunch at 17:54:17 |
| 17:56:14 | Relaunch verified |

**Browser lifetime: 17:50:12 → 17:54:19 = 247 s**, ended only by the operator's own
relaunch, not by a crash.

Child processes observed while Chrome was running (`ps`, all at uid `u0_a967` =
MultiApp's own uid):

```
11049  u0_a967  com.android.chrome
14821  u0_a967  com.android.chrome:sandboxed_process0:org.chromium.content.app.SandboxedProcessService0:14
14985  u0_a967  com.android.chrome:privileged_process0
```

Guest-side self-reports from those processes:

```
processName=com.android.chrome:sandboxed_process0:org.chromium.content.app.SandboxedProcessService0:0 … isIsolatedProcess=false
…:1 … isIsolatedProcess=false        (instance numbers observed 0 through 19)
processName=com.android.chrome:privileged_process0                  isIsolatedProcess=false
```

Observed externally, in run A's logs: **0** occurrences of `Can't use instance name`,
**0** occurrences of `cr_JniAndroid: Handling uncaught`, **0** occurrences of
`bindServiceInstance`, and **0** `Unknown calling package name` GMS errors.

Two facts are worth stating carefully, because they are the ones easiest to
over-read:

- The `ps` name (`com.android.chrome:sandboxed_process0:…:14`) and the AMS name for
  the same pid (`com.waxmoon.ma.nova.gp:proxy.p1`) **disagree**. The process was
  created by AMS as a MultiApp proxy process and presents a Chrome process name at
  runtime. This is a name observation; it is not evidence about how the rename is
  performed.
- The absence of `bindServiceInstance` in MultiApp's logs means no such call was
  *logged or rejected*. It is **not** proof that MultiApp never calls it.

What *is* directly observable: MultiApp's Chrome child processes are created
**for content providers**, run under MultiApp's ordinary app uid, and report
`isIsolatedProcess=false`, while carrying the instance number in their process-name
string.

---

## 2. Duplika — observed Chrome flow (runs B and C)

Every attempt across both runs ends the same way.

Run C, attempt 2 (the flow exactly as specified, including the
`signin_fre_dismiss_button` "Stay signed out" tap):

| Time | Observation |
|---|---|
| 09:32:13 | Step A — Chrome launched from a fresh clone |
| 09:32:23 | Step B — first-run UI visible |
| 09:32:41 | Step C/D — browser alive; **"Stay signed out" tapped** (`signin_fre_dismiss_button`, `[61,2103][1019,2225]`) |
| 09:32:53.904 | `IllegalArgumentException: Can't use instance name '0' with non-isolated non-sdk sandbox service 'top.niunaijun.blackbox.proxy.ProxyService$P1'` |
| 09:32:53.914 | `chromium: [ERROR:jni_android.cc:142] Crashing due to uncaught Java exception` |
| 09:32:53.978 | `cr_JniAndroid: Handling uncaught Java exception` … `at ChildProcessLauncherHelperImpl.createAndStart` |
| 09:32:55.396 | `cr_JniAndroid: Global uncaught exception handler did not terminate the process.` |
| 09:32:55.401 | `F chromium: [FATAL:jni_android.cc:203] Uncaught Java exception in native code…` |
| 09:32:55.872 | `F libc: Fatal signal 5 (SIGTRAP) … tid 22044 (Chrome_ProcessL), pid 20132` |
| 09:32:57.631 | `Zygote: Process 20132 exited due to signal 5 (Trap)` |

**Browser lifetime: 44.6 s.** Step E (60 s hold) could not be satisfied. The browser
was still alive 5 s after the tap (09:32:46, pid 20132); the fatal exception landed
12.9 s after the tap and the process was gone 16.6 s after it, leaving only
`co.tdevs.duplika:p1`. The 60 s hold ran to completion against an already-dead
browser. Steps F, G, H all negative; step I (relaunch) reproduces identically.

Measured lifetimes, all four attempts: 42–47 s (run B), 43.9 s (run C #1),
44.6 s (run C #2).

The renderer bind is attempted ~41 s after launch in every attempt **whether or not
the button is tapped** — run C attempt 1 never received a tap and still hit the same
exception at the same offset. The "Stay signed out" click is therefore *not* the
trigger; it is coincidental. This matches the earlier observation that the browser
process can die before the click.

Child processes: **none**. Across run C, the guest reported exactly one
`cr_SplitCompatApp` line — `processName=com.android.chrome isIsolatedProcess=false`,
the browser — and no `com.android.chrome:sandboxed_process0…` or
`:privileged_process0` process was ever created. No renderer, no GPU process, no New
Tab page, in any attempt.

---

## 3. Side-by-side

| Category | MultiApp Ultra (run A) | Duplika (runs B, C) |
|---|---|---|
| Chrome package | `com.android.chrome` | `com.android.chrome` |
| Chrome version | 152.0.7977.75 | 152.0.7977.75 (B) / .82 (C) |
| APK split count | 6 | 6 |
| Launch activity | `com.google.android.apps.chrome.Main` | `com.google.android.apps.chrome.Main` |
| Browser process | created, `isIsolatedProcess=false` | created, `isIsolatedProcess=false` |
| Renderer process | **created** (instances 0–19 observed) | **never created** |
| GPU process | `…:privileged_process0` created | never created |
| Other child processes | `…:privileged_process2` observed | none |
| Isolated-service behaviour | children run non-isolated under container uid | bind rejected before any child exists |
| `bindServiceInstance` | not logged, no rejection observed | called; **rejected every time** |
| `instanceName` | carried in the process-name string; no AMS rejection | `'0'` forwarded verbatim to AMS |
| Service component | proxy process started *for content provider* `ProxyProvider$PN` | `top.niunaijun.blackbox.proxy.ProxyService$P1` (non-isolated) |
| Process creation timing | browser +26 s → first child | browser +41 s → bind attempt → abort |
| Service connection | established | never established |
| Renderer startup | yes | no |
| First-run completion | yes | UI renders; flow never completes |
| Stay signed out | completes, Chrome continues | tap registers; fatal 12.9 s later, process gone at 16.6 s — on an unrelated timer |
| New Tab page | reached 17:52:38 | never reached |
| Relaunch | verified 17:56:14 | reproduces the same crash |
| Crashes | none observed | `SIGTRAP` every attempt (4/4) |
| Exceptions | none of interest | `IllegalArgumentException` ×4 per attempt |

---

## 4. Duplika failure trace (Phase 6)

```
org.chromium.content.browser.ChildProcessLauncherHelperImpl.createAndStart
  → ContextWrapper.bindIsolatedService(ContextWrapper.java:897)
  → ContextImpl.bindIsolatedService(ContextImpl.java:2095)
  → ContextImpl.bindServiceCommon(ContextImpl.java:2204)
  → $Proxy27.bindServiceInstance                                   ← Bcore hook entry
      → IActivityManagerProxy$bindServiceInstance.hook
      → IActivityManagerProxy.BindServiceCommon(args, callingPackageIndex=7)
      → IActivityManager$Stub$Proxy.bindServiceInstance(IActivityManager.java:6490)
      → ActivityManagerService.bindServiceInstance(ASM.java:15388)
        ✗ IllegalArgumentException: Can't use instance name '0' with
          non-isolated non-sdk sandbox service
          'top.niunaijun.blackbox.proxy.ProxyService$P1'
  → InvocationTargetException → UndeclaredThrowableException
  → cr_JniAndroid uncaught handler → SIGTRAP → browser process dies
```

Request as transformed:

| Field | Value |
|---|---|
| Original component | `com.android.chrome/org.chromium.content.app.SandboxedProcessService0` |
| Original declaration | `isolatedProcess=true`, `process=":sandboxed_process0"`, `useAppZygote=true`, `exported=false`, `permission=…CHILD_SERVICE` (40 such services declared) |
| Original `instanceName` | `"0"` |
| Bcore-resolved component | `co.tdevs.duplika/top.niunaijun.blackbox.proxy.ProxyService$P1` |
| Proxy declaration | `exported=true`, `process=":p1"`, **no `isolatedProcess`** |
| `callingPackage` | rewritten to host package (`args[7]`) — correct |
| Flags | `BIND_EXTERNAL_SERVICE` cleared for host-package targets — correct |
| **`instanceName` (final)** | **`"0"` — forwarded unchanged** |
| Guest process allocation | `BProcessManager: initProcess: com.android.chrome:sandboxed_process0` → slot `co.tdevs.duplika:p1` (observed) |
| Service connection | never established |
| Guest application creation | never reached |

So Bcore gets as far as allocating the proxy slot, then AMS refuses the bind.

### The defect

`IActivityManagerProxy` carries two sibling hooks:

```java
@ProxyMethod("bindIsolatedService")
public static class BindIsolatedService extends MethodHook {
    protected Object hook(Object who, Method method, Object[] args) throws Throwable {
        args[6] = null;                                   // clears instanceName
        return BindServiceCommon(who, method, args, 7);
    }
}

@ProxyMethod("bindServiceInstance")
public static class bindServiceInstance extends MethodHook {
    protected Object hook(Object who, Method method, Object[] args) throws Throwable {
        return BindServiceCommon(who, method, args, 7);   // instanceName forwarded
    }
}
```

The `bindIsolatedService` hook already does the right thing. On API 35 it is never
invoked: the device-observed stack shows `Context.bindIsolatedService()` reaching
`IActivityManager` through **`bindServiceInstance`**, so the isolated path lands on
the sibling hook that leaves `args[6]` intact. Both hooks pass
`callingPackageIndex = 7`, i.e. both assume the same 9-argument layout
(`…, 5 flags, 6 instanceName, 7 callingPackage, 8 userId`), and that layout is
confirmed empirically twice over: AMS received the instance name `'0'` from
`args[6]`, and the `callingPackage` rewrite at `args[7]` produced no complaint.

A second, smaller defect compounds it. `BindServiceCommon`'s catch-all is:

```java
} catch (Exception e) {
    Slog.e(TAG, "BindServiceCommon: Unexpected error", e);
    return method.invoke(who, args);   // retries the same failing call
}
```

The retry throws again, and because the re-thrown `InvocationTargetException` is not
declared on the interface method, the `Proxy` machinery converts a plain
`IllegalArgumentException` into an `UndeclaredThrowableException`. That is the type
Chrome's launcher thread actually sees, and it is what its uncaught-exception path
reports before aborting.

---

## 5. The externally observable difference (Phase 7)

> **Observed externally:** in MultiApp Ultra, Chrome's sandboxed child processes come
> into existence as ordinary, non-isolated container processes — created *for a
> content provider*, running under the container's own app uid, self-reporting
> `isIsolatedProcess=false` — and Chrome's per-child instance number survives only as
> part of the process-name string. No instance name reached `ActivityManagerService`
> in a form it rejected, and no bind rejection occurred.
>
> **Observed externally:** in Duplika, the same Chrome request reaches
> `ActivityManagerService` **with `instanceName = "0"` still attached**, aimed at a
> non-isolated proxy service, and is refused.

The missing capability is therefore narrow and concrete: **on the isolated-service
bind path, the guest's `instanceName` must not be forwarded to a non-isolated proxy
target.** Everything else on that path — component resolution, proxy-slot allocation,
`callingPackage` rewriting, `BIND_EXTERNAL_SERVICE` clearing — already works.

---

## 6. Android 15 framework contract (Phase 8)

Verified against the platform, not against MultiApp:

- `ActivityManagerService.bindServiceInstance` rejects a non-null `instanceName`
  when the target service is neither isolated nor an SDK-sandbox service. Observed
  directly on this device, with the framework's own message and line number
  (`ASM.java:15388`).
- `Context.bindIsolatedService()` on API 35 reaches `IActivityManager` via
  `bindServiceInstance`, not via a distinct `bindIsolatedService` AIDL method.
  Observed directly in the crash stack (`ContextImpl.java:2095 → 2204 → $Proxy27.bindServiceInstance`).
- The platform's own naming for a genuine isolated service instance is
  `<processName>:<instanceName>`, at an isolated uid. Captured incidentally on this
  device from host WebView:
  `com.google.android.webview:sandboxed_process0:org.chromium.content.app.SandboxedProcessService0:0`
  at **uid 99017** — inside the 99000+ isolated range.

The last point matters for ruling out the obvious alternative fix: Duplika's guest
processes must hold the container's uid to reach its storage and services, so making
`ProxyService$PN` genuinely isolated is not an option — an isolated process gets a
99000-range uid with no such access, and could not host the guest runtime at all.
Dropping the instance name is the only route consistent with the framework contract.

---

## 7. GMS and microG (Phase 9)

Nothing was modified in GMS or microG.

GMS errors do appear in Duplika's Chrome run:

```
09-09 18:05:10.860  GoogleApiManager: Failed to get service from broker.
    java.lang.SecurityException: Unknown calling package name 'com.android.chrome'.
```

**This is not the cause of the crash.** It is timestamped 54 ms *after* the fatal
`cr_JniAndroid` handler had already fired (18:05:10.806), it appears on a different
thread (`5123`, not the launcher thread `6547`), and it is the known
BLOCKED-BY-DESIGN caller-identity limitation documented under engine patch 0002 —
GMS resolves the caller in its own process against the real PackageManager. Chrome
tolerates GMS failures during a signed-out first run.

MultiApp's run A shows no `Unknown calling package name` errors, which is a real
difference in GMS-visible behaviour — but it is a *separate* observation, and the
crash correlates with the bind rejection, not with GMS.

---

## 8. ActivityStack (kept separate)

```
W BlackBoxCore: isRunningApplication failed:
  BActivityManagerService cannot be cast to
  top.niunaijun.blackbox.core.system.am.ActivityStack
```

Occurs in the **Duplika UI process** (`co.tdevs.duplika`, pids 25039/29927 in run B,
2 occurrences in run C), inside a caught `isRunningApplication` probe, at
launcher-refresh moments. It never appears in the Chrome guest process, in `:black`,
or anywhere on the service-bind path. The comparison does **not** put it on the
Chrome path. It remains a separate issue.

---

## 9. Unconfirmed observations

Recorded, not relied on:

- In run B attempt 1 only, `co.tdevs.duplika:black` was SIGKILLed at 18:00:06,
  *before* the bind rejections at 18:00:10. In run B attempt 2 and both run C
  attempts the ordering is the reverse — the bind rejection comes first and `:black`
  dies afterwards, as fallout. The attempt-1 ordering is most likely low-memory
  pressure and is not required to explain the failure.
- Duplika's "allow background execution" prompt was declined in run C, to keep
  parity with run B. Whether granting it changes `:black`'s survival is untested.
- MultiApp starts guest processes *for content providers*; Duplika starts them via
  service binds. Whether that difference matters beyond the instance-name issue is
  not established.

---

## 10. Smallest legitimate fix — proposed, NOT implemented

Bring the `bindServiceInstance` hook in line with its `bindIsolatedService` sibling
by clearing the instance name before delegating:

```java
@ProxyMethod("bindServiceInstance")
public static class bindServiceInstance extends MethodHook {
    @Override
    protected Object hook(Object who, Method method, Object[] args) throws Throwable {
        args[6] = null;                                   // ← added
        return BindServiceCommon(who, method, args, 7);
    }
}
```

One line, in
`Bcore/src/main/java/top/niunaijun/blackbox/fake/service/IActivityManagerProxy.java`,
as a new engine patch `0008`. It does not touch patches 0006 or 0007.

**Why this is the right shape.** It restores an intent the engine already expresses;
it does not invent behaviour copied from MultiApp. Ordinary `bindService()` on API 31+
also reaches AMS through `bindServiceInstance`, always with `instanceName = null`, so
clearing an already-null field is a no-op on the common path. Only isolated binds
change.

**What it will and will not achieve.** It removes the rejection and should let the
first renderer start. It does **not** give Chrome multiple concurrent renderers:
`ActiveServices.bindService` allocates a proxy slot from `serviceInfo.processName`
alone, so every instance of `SandboxedProcessService0` collapses into the single
`:p1` slot. MultiApp was observed running instances 0–19 in distinct processes;
matching that needs instance-aware slot allocation, which is a larger change and
should be a separate decision.

**Security impact.** None identified. Clearing `instanceName` narrows what the guest
can ask the host AMS for; no uid, package name, signature, permission, or caller
identity is altered. It cannot make a bind succeed that would otherwise be refused on
identity grounds — AMS still applies its own checks to the proxy component.

**Regression risk.** Low but not zero. Any guest that legitimately relies on distinct
isolated service instances would see them coalesce rather than fail — a behaviour
change from "crash" to "shared process". The failure mode being replaced is a hard
crash, so the trade is favourable, but it warrants the multi-renderer caveat above.

**Verification bar before claiming Chrome is fixed** (none of it met yet): Chrome
alive ≥60 s, renderer process created, "Stay signed out" completes, normal New Tab
page renders, relaunch works.

**Bcore patch required:** yes. The change is inside the prebuilt engine, so it means
a new `engine-patches/0008-*.patch` plus a rebuild of `bcore.aar` via
`engine-patches/build-engine.sh`. Not done — per the task, this is reported and
stopped here.

---

## 11. Test status

Run at 09:22 on 2026-09-10, against the tree as it stood at commit `70b6431` with
no working-tree changes:

| Check | Result |
|---|---|
| `flutter analyze` | **0 errors** (4 pre-existing info lints) |
| `flutter test` | **240/240 passed**, 0 failed, 0 skipped |

> **Caveat.** From roughly 09:26 onward — while the device runs were in progress — an
> unrelated settings feature began appearing in the working tree from outside this
> session (`lib/features/settings/`, `lib/core/services/settings_store.dart`,
> `test/settings_test.dart`, plus edits to five existing `lib/` files). Those changes
> are **not** part of this study and were not touched by it. The figures above are a
> snapshot taken before they landed; re-running the suite now would also exercise
> that in-progress work.

The task sheet expected 245. The current tree contains exactly 240 `test(` /
`testWidgets(` declarations, matching the 240 reported, so 245 is a stale figure
carried in older docs (`level10-*`, `chrome-split-apk-launch-investigation.md`); it
predates test removals such as commit `458f4e1` "Retire legacy GMS provisioning".
Nothing is failing or skipped.

No `bcore.aar` was replaced. No code was modified. Nothing was committed.

---

## Evidence

```
evidence/physical-android15/multiapp-reference/
    ma_0*.png, multiapp-flow-timestamps.txt,
    multiapp-focused-excerpt.txt, multiapp-process-timeline.log      (run A)
    run-2026-09-10/ma_10_consent_gate_NOT_ACCEPTED.png, ma-timestamps.txt

evidence/physical-android15/duplika-chrome-reference/
    dup_0*.png, duplika-flow-timestamps.txt,
    duplika-process-timeline.log, duplika-attempt2-window.log        (run B)
    run-2026-09-10/dup_1*.png, dup_2*.png, dup-timestamps.txt,
                   dup-focused-excerpt.txt, dup-process-timeline.log,
                   chrome-base-manifest-xmltree.txt                  (run C)
```

`*.log` files are gitignored by the repo-wide `*.log` rule; the `.txt` excerpts and
timestamps carry the cited lines. No account, credential, cookie, token, or private
app data was read or recorded from either container.
