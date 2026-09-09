# Chrome "Stay signed out" post-launch crash — investigation

**Investigation only. No Bcore change made. Awaiting authorization.**

## Headline

**"Stay signed out" does not cause the crash.** On the Android 15 device of record, Chrome's
browser process is already dead **~6 seconds before the button is pressed**, killed on its
own `Chrome_ProcessL` (ProcessLauncher) thread. What the user taps is a stale surface of a
dead process — which is exactly why the button "sometimes does nothing" and why Chrome
"sometimes closes". The button is the first thing anyone naturally touches, so it looked
causal.

The bindIsolatedService hypothesis is **CONFIRMED as a real, general Bcore defect** — proved
independently with a purpose-built fixture containing no Chrome, no GMS and no credentials —
and it is the failure on the device. It is **not** the whole story: three further distinct
failure modes were found on the same path.

## 1. Exact reproduction result

| # | Platform | Chrome | Click landed? | Outcome |
| --- | --- | --- | --- | --- |
| 1 | Emulator API 37 | 152.0.7977.75, 6 splits | yes | activity gone, process **alive**, no exception |
| 2 | Emulator API 37 | same | yes (`signin_fre_dismiss_button`, verified via uiautomator) | process **gone < 2 s** |
| 3 | Emulator API 37 | same | yes | process **gone**, full event chain captured |
| 4 | **Device API 35** | same | yes (bounds `[61,2103][1019,2225]`) | process **gone < 3 s** |

Reproducible in 3 of 4 attempts; attempt 1 left the process alive with the activity gone, so
the symptom is genuinely variable — matching the report.

The click target was confirmed by dumping the view hierarchy rather than guessed:
`com.android.chrome:id/signin_fre_dismiss_button`, `clickable="true"`, hosted inside
`co.tdevs.duplika/ProxyActivity$P0`.

## 2. Does "Stay signed out" actually trigger the crash? — **No**

Device timeline, from the DropBox crash record and the shell clock:

| Time | Event |
| --- | --- |
| ~17:31:31 | Chrome launched, virtual user 2 (fresh clone) |
| ~17:32:0x | `pidof com.android.chrome` = 20263, first-run UI captured, button located |
| **17:32:14.644** | **native crash**, `co.tdevs.duplika:p0`, thread `Chrome_ProcessL`, SIGTRAP |
| **17:32:21** | **the click** |
| 17:32:24 | polling shows no Chrome pid, Duplika home foreground |

The crash precedes the click by **~6.4 s**. The button press cannot have caused it.

`Process-Runtime: 43174` ms in the record confirms the crash was ~43 s into Chrome's life —
i.e. during its own start-up, unprompted.

## 3. First meaningful failure

### Device (API 35) — the platform of record

`evidence/.../device-chrome-native-crash-1732.txt`:

```
Process: co.tdevs.duplika:p0     PID: 20263     UID: 10971
Process name is com.android.chrome
pid: 20263, tid: 21044, name: Chrome_ProcessL  >>> com.android.chrome <<<
signal 5 (SIGTRAP), code 1 (TRAP_BRKPT)
Abort message: '[FATAL:base/android/jni_android.cc:203] Uncaught Java exception in native
    code and the Java uncaught exception handler did not terminate the process...'
23 frames, all libchrome.so
```

`Chrome_ProcessL` is Chromium's **ProcessLauncher** thread — the thread that runs
`ChildProcessLauncherHelperImpl.createAndStart()` and therefore
`Context.bindIsolatedService()`. Earlier in this same session the full Java stack for an
identical abort was captured on this device:

```
IllegalArgumentException: Can't use instance name '0' with non-isolated non-sdk
    sandbox service 'top.niunaijun.blackbox.proxy.ProxyService$P1'
  at IActivityManager$Stub$Proxy.bindServiceInstance
  … IActivityManagerProxy.BindServiceCommon
  … ContextWrapper.bindIsolatedService
  … ChildProcessLauncherHelperImpl.createAndStart
```

Same thread name, same abort message, same signal. **The device's first meaningful failure is
the child-process bind.**

### Emulator (API 37) — a different first failure

`evidence/.../emulator-att3-postclick-events.log`:

```
17:27:37.416  ActivityManager: freezing 29959 co.tdevs.duplika:black
17:27:37.418  am_freeze     [29959, co.tdevs.duplika:black]
17:27:37.802  GoogleApiManager(29973): SecurityException: Unknown calling package name …
17:27:39.903  am_kill       [29959, co.tdevs.duplika:black, "Sync transaction while frozen"]
17:27:39.919  am_proc_died  [29959, co.tdevs.duplika:black]
17:27:40.341  am_crash      [co.tdevs.duplika:p0, Native crash, Trap]
17:27:40.368  am_proc_died  [29973, co.tdevs.duplika:p0]
```

Here Android's **cached-app freezer** froze Bcore's `:black` server process; a synchronous
binder transaction then arrived for it and the platform killed it ("Sync transaction while
frozen"); with the server gone the guest process took a native Trap. This is a **fourth,
separate** problem and it is not the device's failure — recorded, not conflated.

## 4. Which process dies

| Platform | Process that dies | Kind |
| --- | --- | --- |
| Device API 35 | `co.tdevs.duplika:p0` — the Chrome **browser** guest process | native SIGTRAP from a Java exception on the ProcessLauncher thread |
| Emulator API 37 | `co.tdevs.duplika:black` (Bcore server) **first**, then `co.tdevs.duplika:p0` | platform kill, then native Trap |

No renderer or GPU child process dies, because **none is ever created** — that is the whole
problem. Chrome never gets a renderer.

## 5. Is bindIsolatedService involved? — **Yes, confirmed**

Not assumed. Proved twice over:

1. **Source audit (Phase 7).** On API 35, `IActivityManager` exposes `bindService` and
   `bindServiceInstance` and **no `bindIsolatedService`** — verified by dumping the device's
   own `/system/framework/framework.jar`:

   ```
   IActivityManager$Stub$Proxy → [bindService, bindServiceInstance, unbindService, …]
   bindServiceInstance(IApplicationThread, IBinder, Intent, String, IServiceConnection,
                       long flags, String instanceName, String callingPackage, int userId)
   ```

   `bindIsolatedService` is a `Context` method, not a Binder method. Bcore dispatches hooks by
   Binder method name, so `@ProxyMethod("bindIsolatedService")` — the hook whose body does
   `args[6] = null` to strip the instance name — **can never fire**. The hook that does fire is
   `@ProxyMethod("bindServiceInstance")`, which passes the instance name straight through.

2. **Minimal reproduction (Phase 6).** See §11 — the fixture reproduces the identical
   exception with Chrome absent, and the stack names the hook that fires.

This is the **same bug class as the already-fixed patch 0006**: a hook registered under a name
the platform never calls, so the intended normalisation silently never happens.

## 6. Chrome's service and process

Chrome's `base.apk` declares **52 isolated services**: 40
`org.chromium.content.app.SandboxedProcessService0..39`, 10 `PrivilegedProcessService0..9`,
2 `NativeOnlySandboxedProcessService0..1`. Each is:

```
android:isolatedProcess="true"   android:useAppZygote="true"
android:process=":sandboxed_processN"   android:exported="false"
android:permission="com.android.chrome.permission.CHILD_SERVICE"
```

`split_chrome.apk` adds one more (`photo_picker.DecoderService`). Chrome binds these with
`bindIsolatedService(intent, flags, instanceName, executor, conn)`; the observed instance name
was `"0"`.

## 7. Bcore's transformation

`IActivityManagerProxy.BindServiceCommon(who, method, args, callingPackageIndex=7)`:

| Step | Value |
| --- | --- |
| Chrome's request | `SandboxedProcessService0`, `isolatedProcess=true`, `useAppZygote=true`, instanceName `"0"` |
| `resolveService` in the virtual PM | resolves (the service is declared in `base.apk`) |
| `ActiveServices.bindService` → `ActiveServices.java:199` | `ProxyManifest.getProxyService(processRecord.bpid)` |
| Redirected component | `co.tdevs.duplika/top.niunaijun.blackbox.proxy.ProxyService$P1` |
| That declaration (Bcore manifest) | `android:exported="true" android:process=":p1"` — **no `isolatedProcess`** |
| instanceName after Bcore | **unchanged, still `"0"`** |
| Final call | `IActivityManager.bindServiceInstance(…, instanceName="0", …)` |
| Platform verdict | `IllegalArgumentException` — instance names are only allowed on isolated services |

`grep -c isolatedProcess` over Bcore's `AndroidManifest.xml` returns **0**: not one of the
~50 `ProxyService$Pn` declarations is isolated. So the platform's refusal is correct and
unavoidable while an instance name is passed with a non-isolated target.

Note Bcore already separates instances by a different axis — one `ProxyService$Pn` **per guest
process** (`bpid`). Chrome's instance name is redundant in that model, which is why the dead
hook's intent (drop the instance name) is architecturally sound.

## 8. Is the previous `ProxyService$P1` error reproduced? — **Yes, exactly**

Byte-for-byte the same message, on both platforms, from the fixture:

```
Caused by: java.lang.IllegalArgumentException: Can't use instance name '0' with non-isolated
    non-sdk sandbox service 'top.niunaijun.blackbox.proxy.ProxyService$P1'
  at android.app.IActivityManager$Stub$Proxy.bindServiceInstance
Caused by: java.lang.reflect.InvocationTargetException
  at top.niunaijun.blackbox.fake.service.IActivityManagerProxy.BindServiceCommon
  at top.niunaijun.blackbox.fake.service.IActivityManagerProxy$bindServiceInstance.hook
```

That last frame is the proof of §5: the hook that fires is `bindServiceInstance`.

## 9. Are the GMS errors causal? — **No, incidental**

`GoogleApiManager: SecurityException: Unknown calling package name 'com.android.chrome'`
appears on both platforms. It is **not** the cause:

- On the emulator it is logged at 17:27:37.802 and Chrome kept running for **2.5 more
  seconds**, through further work, before anything died.
- On the device the fatal is on `Chrome_ProcessL` with a JNI abort — a different thread and a
  different mechanism from a caught `SecurityException`.
- Chrome demonstrably catches it: `GoogleApiManager` logs it as "Failed to get service from
  broker" and continues.

This is the identity-scoped GMS boundary already classified UNSUPPORTED / SECURITY-BOUNDARY in
[level10-cross-artifact-gms-probe.md](level10-cross-artifact-gms-probe.md). Recorded
separately in the evidence directory; **no attempt was made to authenticate, obtain a token,
or spoof any identity.**

## 10. Is the `ActivityStack` error causal? — **No, incidental**

`grep` for `ActivityStack` across every post-click capture on both platforms: **not present in
any crash path**. Its only known caller remains
`BlackBoxEngineAdapter.kt:isVirtualAppRunning`, a state query. Untouched, still a separate
issue.

## 11. Minimal reproduction — `compatibility_test_ladder/level12_isolatedservice`

A ~20 KB app: one isolated service, one non-isolated control service, one activity. **No
Chrome, no GMS, no account, no credentials, no permissions, no native code.** Four cells so a
failure can be attributed precisely.

| Cell | What it does | Device host (API 35) | Device guest (API 35) | Emu host (API 37) | Emu guest (API 37) |
| --- | --- | --- | --- | --- | --- |
| **P1** | `bindIsolatedService`, isolated svc, instanceName `"0"` — **Chrome's exact shape** | **connected**, isolated uid 99645 | **THREW** (199 ms) | **connected**, isolated uid 99004 | **THREW** (7–8 ms) |
| **P2** | `bindService`, isolated svc, **no** instance name | connected, uid 99646 | accepted, **never connected** | connected, uid 99005 | onBind reached, then **fatal** |
| **P3** | `bindIsolatedService`, **non-isolated** svc + instanceName | **THREW** (platform's own rule) | THREW | **THREW** | — |
| **P4** | `bindService`, non-isolated svc | connected, app uid | accepted, **never connected** | connected | — |

What this establishes:

- **P1 host vs guest** is the whole finding: the platform fully supports Chrome's call shape;
  only the container breaks it. Not a Chrome bug, not an Android limitation.
- **P1 vs P2** isolates the variable to the **instance name**, not "isolated services".
- **P3 on the host** reproduces the exact container error message with a non-isolated target,
  proving the rule being violated is the platform's and that Bcore's substitution of a
  non-isolated `ProxyService` is what violates it.
- Identical on API 35 and API 37 → **generic Android compatibility defect**, not version-specific.

### Two further defects the fixture exposed

**Defect B — guest binds never connect (API 35).** P2 and P4 are accepted but
`onServiceConnected` never arrives. DropBox shows why
(`device-proxyservice-makeapplication-crash.txt`):

```
Process: co.tdevs.duplika:p1
java.lang.RuntimeException: Unable to bind to service
    top.niunaijun.blackbox.proxy.ProxyService$P1@… : java.lang.RuntimeException:
    Unable to makeApplication
  at android.app.ActivityThread.handleBindService(ActivityThread.java:5386)
Crash-Handler: top.niunaijun.blackbox.core.CrashHandler
```

The proxy service's process fails to construct the guest `Application`, so the bind never
completes and the caller waits forever. **This is the second silent-failure path behind
"the button does nothing", and it means fixing the instance name alone may not be enough for
Chrome.**

**Defect C — `IServiceConnection` signature drift (API 37 only).**

```
java.lang.AbstractMethodError: abstract method
    "void android.app.IServiceConnection.connected(ComponentName, IBinder, …)"
  at android.app.IServiceConnection$Stub.onTransact  → FATAL → JNI FatalError
```

`ServiceConnectionDelegate` implements only `connected(ComponentName, IBinder)` and
`connected(ComponentName, IBinder, boolean)`. Newer Android added a parameter. **Not present
on API 35**, so it is a forward-compatibility issue, not part of the Android 15 report.

**Defect D — `:black` frozen then killed (API 37 observed).** §3.

## 12. Root-cause confidence

| Claim | Confidence | Basis |
| --- | --- | --- |
| "Stay signed out" is not the trigger | **High** | Crash timestamp precedes the click by 6.4 s in the DropBox record |
| Chrome's browser process dies on the ProcessLauncher thread | **High** | Tombstone: `tid 21044, name Chrome_ProcessL`, SIGTRAP, JNI abort |
| bindIsolatedService + instance name is a real Bcore defect | **High** | Minimal fixture, 2 platforms, host/guest contrast, plus source audit |
| It is the device's first meaningful failure | **Medium-high** | Thread identity + abort message + earlier full Java stack on this device. The guest's own logcat is dropped by OEM flow control (`LOGS OVER PROC QUOTA(300) … DROPPED`), so the Java stack for *this specific* crash was not re-captured |
| Fixing it alone makes Chrome work | **Low** | Defect B (Unable to makeApplication) sits on the same path and is unresolved |
| API 37 first failure is the freezer kill | **High** | `am_freeze` / `am_kill` / `am_crash` event chain |

## 13. Proposed fix — NOT implemented

**Smallest legitimate change.** In
`Bcore/src/main/java/top/niunaijun/blackbox/fake/service/IActivityManagerProxy.java`:

Move the instance-name normalisation onto the Binder method that the platform actually calls,
and do it **only when Bcore has redirected the Intent to its own ProxyService**.

- `@ProxyMethod("bindServiceInstance")` is the hook that fires. It must clear the instance name
  (`args[6]`) on the redirect path, exactly as the dead `bindIsolatedService` hook intended.
- Do it **inside** `BindServiceCommon`, at the point where `args[2]` is replaced with
  `proxyIntent` and the target is confirmed to be the host's own `ProxyService` — not
  unconditionally at hook entry. The existing dead hook clears it before any decision, which
  would also strip a legitimate instance name from a pass-through bind that Bcore does not
  redirect.
- The now-unreachable `@ProxyMethod("bindIsolatedService")` class should be removed or
  re-pointed, so the next reader is not misled into thinking the case is handled.

Why clearing it is correct rather than a bypass: Bcore already provides per-instance separation
on a different axis — `ActiveServices.java:199` allocates a distinct `ProxyService$P<bpid>` per
guest process. The platform's instance-name mechanism is redundant inside the container, and
the value is meaningless to the real service being bound.

**Rejected alternatives**, and why:

| Alternative | Why not |
| --- | --- |
| Declare `ProxyService$Pn` as `isolatedProcess="true"` | An isolated process gets no data access, no permissions and its own ephemeral uid — Bcore's guest processes need all of those. It would break every service bind, not fix one |
| Catch and swallow the `IllegalArgumentException` | Forbidden, and it would leave Chrome with no renderer |
| Add isolated `ProxyService` variants alongside the normal ones | Larger architectural change; deferred until the simpler fix is measured. **A STOP-and-report candidate, not something to attempt unasked** |

**Defect B must be investigated before Chrome can be called fixed**, and it is a separate
change in the `ProxyService` / `makeApplication` path.

## 14. Security assessment

The proposed change drops a redundant instance-name string on a path Bcore already controls.
It does not touch UID, package identity, signatures, certificates, permissions, SELinux, Play
Integrity, SafetyNet or GMS, and grants the guest nothing it did not already have. It does
**not** make a non-isolated process appear isolated — the opposite: it stops asking the
platform for isolated-instance semantics that the target cannot provide, which is why the
platform is refusing.

No exception is suppressed: the failing call stops being made in an invalid form.

Nothing in this investigation attempted authentication, token acquisition, or any spoofing;
the fixture uses no account and no credentials.

## 15. Regression risk

| Risk | Assessment |
| --- | --- |
| Apps relying on genuinely distinct isolated instances | **Medium** — they would get Bcore's per-`bpid` separation instead of per-instance-name. Chrome may want more concurrent renderers than Bcore has proxy slots |
| Non-instanced binds (`bindService`) | **None** — different hook, untouched |
| Pass-through binds Bcore does not redirect | **None if the clearing is scoped to the redirect path**; would be a real regression if done unconditionally |
| Engine artifact | Requires a `bcore.aar` rebuild → Levels 6/7/8 must be re-run |
| Defect B | Unchanged by this fix; Chrome may still fail after it |

## 16. Test matrix required for the fix

| # | Cell | Expectation |
| --- | --- | --- |
| 1 | `level12_isolatedservice` P1, guest, both platforms | **THREW → connected** |
| 2 | P2/P3/P4, guest | unchanged (P3 must still throw — it is the platform's rule) |
| 3 | P1–P4, host, both platforms | unchanged |
| 4 | `level11_isosplit` fixture | still PASS (0007 intact) |
| 5 | `usermanagerprobe` 4 cells | still PASS (0006 intact) |
| 6 | Level 6 / 7 / 8 | re-run — artifact changed |
| 7 | Chrome, fresh virtual user, Debug + Release | renderer starts; **survives past 43 s unprompted**, then the button is pressed |
| 8 | Chrome post-click | New Tab page reached, or the next distinct defect identified |
| 9 | `flutter analyze` / `flutter test` | 0 errors / 245 passing |

Acceptance is cell 7 **and** 8. Chrome is not fixed until it reaches the New Tab page.

## 17. Files changed in this phase

Diagnostic and documentation only — **no engine, no production code, no `bcore.aar` rebuild**:

| File | Kind |
| --- | --- |
| `compatibility_test_ladder/level12_isolatedservice/**` | diagnostic fixture (new) |
| `compatibility_test_ladder/settings.gradle.kts` | registers the fixture |
| `docs/chrome-stay-signed-out-android15-investigation.md` | this document |
| `evidence/physical-android15/chrome-stay-signed-out/**` | evidence (new directory; earlier Chrome evidence untouched) |

Patches 0001–0007 unmodified; `bcore.aar` still
`f38fa7d3ef7a08f6defe61a95c11eb1f99ef2adb3617b47f62fb1726c10be4af`.

## 18. Environments used

| | Device of record | Emulator |
| --- | --- | --- |
| Model | OnePlus CPH2605 | `sdk_gphone64_arm64` (Medium_Phone AVD) |
| Android | **15 / API 35** | **17 / API 37** |
| ABI | arm64-v8a | arm64-v8a |
| Chrome | 152.0.7977.75, 6 splits | **152.0.7977.75, 6 splits** — the device's own APK set installed onto the emulator so the Chrome variable is held constant |
| Duplika | release, engine `f38fa7d3…` | release, engine `f38fa7d3…` |

An API 35 emulator image was attempted first (so the emulator would match the brief exactly)
but the host disk had only ~5 GB free and the unzip failed with *No space left on device*; a
new AVD needs roughly 14 GB. Rather than delete the user's existing 16 GB AVD, the existing
API 37 emulator was used and **the device's real Chrome 152 split set was installed onto it**,
so only the Android version differs. Every Chrome-relevant conclusion is stated per platform,
and the fixture was run on both — which is how Defects A (both) and C (API 37 only) were told
apart.

## 19. Limitations

1. The Java stack for the *specific* device crash at 17:32:14 was not re-captured: ColorOS
   drops guest logcat output (`LOGS OVER PROC QUOTA(300) … DROPPED`). The attribution rests on
   the tombstone's thread name and abort message plus an identical, fully-stacked crash
   captured earlier on the same device.
2. Only one device attempt reached a fresh-clone first-run screen; the brief asked for three.
   Each launch of a crashed clone leaves it in the black-screen state, so a fresh clone is
   needed per attempt. Three attempts were completed on the emulator.
3. Defect B's root cause (`Unable to makeApplication`) was not investigated — it is named, not
   explained.
4. Whether Chrome needs more concurrent isolated instances than Bcore has proxy slots is
   unknown and would only surface after the fix.
5. `useAppZygote="true"` on Chrome's services was not investigated as a separate variable; the
   fixture deliberately omits it to keep one variable at a time.
