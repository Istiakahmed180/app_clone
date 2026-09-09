# Chrome crash on Android 15 — UserManager application restrictions

**Root cause: CONFIRMED.** Duplika is missing virtualization for one Binder method name.
The hook that should handle it already exists in Bcore, is installed in the guest process,
and has the correct body — it is simply registered under the method name Android used
*before* the platform renamed it. **No production code was changed in this phase.**

Device: OnePlus CPH2605, Android 15 / API 35 / arm64-v8a, `KNOJORMFV4GERKHM`.

## 1. Root cause in one paragraph

`UserManager.getApplicationRestrictions(String)` on API 35 invokes the Binder method
**`getApplicationRestrictionsForUser`**. Bcore's hook is registered as
`@ProxyMethod("getApplicationRestrictions")` — the short name — and Bcore dispatches hooks
by method name. The names do not match, so the hook never runs, the call reaches the real
`IUserManager` unmodified, and the platform refuses it because the calling UID (the Duplika
host app) does not own the guest package that was passed. Chrome asks only about **its own**
package, which any app may do; it only looks like a cross-app request from inside a
container.

## 2. Reproduction

`compatibility_test_ladder/usermanagerprobe` — a new diagnostic with **no dependencies at
all** (not even Duplika's), so the identical APK runs on the host and in a container and any
difference is attributable to the virtualization layer. It calls
`getApplicationRestrictions(getPackageName())` — always its **own** package. It never queries
another app, never another Android user, never reads Chrome data, and records only whether
the call succeeded, the returned Bundle's key count, and the exception.

| Cell | P1 `getApplicationRestrictions(own package)` |
| --- | --- |
| **Host** (uid 10965) | **SUCCESS** in 1 ms — `bundleNull=false keyCount=0` |
| **Guest** (virtual user 1) | **SecurityException** after 2 ms |

Guest exception, verbatim:

```
java.lang.SecurityException: Only system may: get application restrictions for other
    user/app com.example.duplikaladder.umprobe
  at android.os.Parcel.createExceptionOrNull(Parcel.java:3271)
  …
```

Same message shape as Chrome's, with the probe's package substituted for
`com.android.chrome`. So the failure is **not Chrome-specific**.

### The controls that make this diagnostic rather than anecdotal

In the **same guest process**, immediately after P1 failed:

| Control | Guest result |
| --- | --- |
| P2 `getUserRestrictions()` — own user, no package argument | **SUCCESS**, keyCount=1 |
| P3 `UserManager.isSystemUser()` | **SUCCESS** |

`UserManager` is reachable and usable in the container. Only the **package-scoped**
restrictions call fails.

## 3. Why Chrome reaches the real UserManager — answer: (C)

**C — a partially hooked path where this specific method is not intercepted.**

Evidence, in order of strength:

1. **The exception names the guest package, not the host package.** This is the decisive
   point. Bcore's hook body is `args[0] = BlackBoxCore.getHostPkg()`. Had the hook run, the
   platform would have been asked about `co.tdevs.duplika` and the message — if any — would
   have named it. The message names `com.example.duplikaladder.umprobe`, so `args[0]` was
   never rewritten and **the hook did not execute**.
2. **The proxy is installed.** `HookManager: hook:
   top.niunaijun.blackbox.fake.service.IUserManagerProxy@f6019d` in the guest process, and
   `getWho()` resolves service name `"user"`. So the binder is hooked; the method is not.
3. **No hook registers the API 35 name.** The string
   `getApplicationRestrictionsForUser` does not appear anywhere in `bcore.aar`.
4. **Chrome's own stack** (supplied) shows
   `IUserManager$Stub$Proxy.getApplicationRestrictionsForUser` under
   `UserManager.getApplicationRestrictions` — i.e. the long name is what is invoked.

## 4. Bcore hook audit

Full output: `evidence/physical-android15/chrome-user-manager/bcore-hook-audit.txt`.

| Hook | Registered name |
| --- | --- |
| `IUserManagerProxy$GetApplicationRestrictions` | `getApplicationRestrictions` |
| `IUserManagerProxy$getUsers` | `getUsers` |
| `IUserManagerProxy$GetProfileParent` | `getProfileParent` |

All three use short names. Decompiled hook body:

```java
// IUserManagerProxy$GetApplicationRestrictions
args[0] = BlackBoxCore.getHostPkg();
return method.invoke(who, args);
```

That intent is correct and is **not** spoofing: the guest asks about itself, and the request
is normalised to the container owner's package, which the calling UID genuinely owns.

## 5. Android 15 / API 35 API comparison

| Layer | Signature | Notes |
| --- | --- | --- |
| SDK (public) | `Bundle UserManager.getApplicationRestrictions(String packageName)` | Callable by any app **for its own package**; no permission required — confirmed by the host cell passing with zero permissions declared |
| Binder (`@hide`) | `Bundle IUserManager.getApplicationRestrictionsForUser(String packageName, int userId)` | The name actually invoked on API 35, per Chrome's stack and the probe's stack |
| Enforcement | caller must be system **or** own `packageName` for `userId` | Produces `"Only system may: get application restrictions for other user/app <pkg>"` |

`userId` semantics: the *real* Android user (0 here), not Duplika's virtual user id — the two
namespaces are unrelated. `packageName` semantics: the package whose restrictions are asked
for; ownership is checked against the Binder calling UID.

`getApplicationRestrictionsForUser` is not new in Android 15 — the short-vs-long asymmetry
is long-standing. What matters is only that Bcore registers the short name while the
platform invokes the long one, on this platform version.

## 6. Hypothesis table

| # | Hypothesis | Evidence for | Evidence against | Status |
| --- | --- | --- | --- | --- |
| 1 | Bcore lacks any UserManager virtualization | — | `IUserManagerProxy` exists and is installed in the guest | **REJECTED** |
| 2 | `UserManager` is unreachable in the container | — | P2 and P3 succeed in the same guest process | **REJECTED** |
| 3 | Chrome-specific defect | — | A dependency-free probe reproduces it with its own package name | **REJECTED** |
| 4 | Missing manifest permission in the caller | — | Host passes with **no** permissions declared; identical APK both sides | **REJECTED** |
| 5 | `All files access not granted` (the secondary warning) causes it | Appears in the same launch | It is a storage warning; the failure is an `IUserManager` ownership check. Guest P2/P3 succeed with the same warning present | **REJECTED** as the cause of this SecurityException |
| 6 | Android 15 tightened this specific check | Message is API-35 wording | Not needed to explain anything — the hook simply never runs, so no tightening is required for the failure | **UNKNOWN / not required** |
| 7 | **Hook registered under the wrong Binder method name, so the call is never intercepted** | Exception names the *guest* package → `args[0]` unrewritten → hook did not run; no hook registers `…ForUser`; proxy demonstrably installed; Chrome's stack shows the long name | none found | **CONFIRMED** |

## 7. Security assessment

The proposed fix is **not** a security bypass, and this matters enough to be explicit:

- It does **not** spoof UID, package identity, signature or certificate.
- It does **not** make Chrome look like a system app.
- It does **not** suppress `SecurityException` anywhere.
- It does **not** grant access to another *real* Android user — `userId` is left untouched.
- It does **not** let a guest read another app's restrictions: the rewritten package is the
  container owner's, which the calling UID actually owns. The platform check still runs and
  still passes on its own terms.

The platform's rule is "the caller must own the package it asks about". Inside a container
the caller genuinely is Duplika, so asking about Duplika is the *truthful* request. The
guest's own restrictions do not exist as a separate platform concept — a virtual user is not
an Android user — so the container owner's restrictions are the correct and only legitimate
answer.

Return-value note: on this device the host returns an **empty** Bundle (`keyCount=0`) because
there is no managed profile. So the practical effect of the fix here is "Chrome receives an
empty restrictions Bundle instead of crashing", which is exactly what it receives on the host.

## 8. Proposed fix — smallest possible, not applied

One annotation, in Bcore source, using the project's existing `@ProxyMethods` idiom:

```java
// top/niunaijun/blackbox/fake/service/IUserManagerProxy.java
-   @ProxyMethod("getApplicationRestrictions")
+   // API 35's UserManager.getApplicationRestrictions(String) invokes the Binder method
+   // getApplicationRestrictionsForUser(packageName, userId); older platforms used the short
+   // name. Hooks dispatch by name, so both must be registered or the call falls through to
+   // the real service and is refused for a containerised caller.
+   @ProxyMethods({"getApplicationRestrictions", "getApplicationRestrictionsForUser"})
    public static class GetApplicationRestrictions extends MethodHook {
```

The existing body needs no change: `args[0]` is the package name in **both** signatures, so
rewriting index 0 is correct for each. `userId` (index 1 on the long form) is deliberately
left alone.

**Not applied in this phase**, for two stated reasons:

1. The brief is investigation-first and says not to patch Bcore before proving the gap. The
   gap is now proven; applying it is a separate, authorised step.
2. Applying it means rebuilding `bcore.aar` via `engine-patches/build-engine.sh` (NDK
   29.0.13846066), which replaces the artefact every Level 6–10 result rests on
   (sha256 `0178aa0b0fe2…`). That deserves an explicit go-ahead, and it should land as a
   numbered patch in `engine-patches/` like the other engine fixes.

Validation would not need Chrome: `usermanagerprobe` reproduces the failure on its own, so
the fix can be verified guest-side directly.

## 9. Chrome itself could not be launched today — separate blocker

Chrome's crash could **not** be reproduced first-hand, because Chrome no longer launches in a
container at all:

```
Duplika.VIRTUAL_ENGINE: Starting com.android.chrome in virtual user 2
Duplika.VIRTUAL_ENGINE: Rebuilding the container for com.android.chrome before a second launch attempt
Duplika.VIRTUAL_ENGINE: Launch of com.android.chrome failed after a rebuild:
                        The engine refused to launch the virtual application.
```

Reproduced on a **fresh** clone (virtual user 2), so it is not stale-container state. Chrome
on this device is a **6-way split** install (`base, chrome, config.en, dev_ui, on_demand,
stack_unwinder`), which is the obvious first thing to look at, but that is a hypothesis and
was not tested here.

Context: Duplika had been uninstalled from the device before this session, so it was
reinstalled (fresh, uid 10966) and clones recreated. The SecurityException finding does not
depend on Chrome launching — the probe reproduces it directly.

## 10. Separate bug — `BActivityManagerService cannot be cast to ActivityStack`

Kept separate, as instructed. Observed repeatedly:

```
W BlackBoxCore: isRunningApplication failed:
  top.niunaijun.blackbox.core.system.am.BActivityManagerService cannot be cast to
  top.niunaijun.blackbox.core.system.am.ActivityStack
```

- **Where:** inside Bcore's `isRunningApplication`, i.e. its own service-registry lookup
  returning `BActivityManagerService` where `ActivityStack` is expected. A Bcore-internal
  type mismatch, not Duplika code.
- **Duplika's exposure:** `BlackBoxEngineAdapter.listVirtualUserIds()` wraps its engine call
  in `runCatching { … }.getOrDefault(emptyList())`, and `SystemDiagnostics.collect` wraps it
  again — so it degrades to an empty list rather than propagating.
- **Classification:** **stale/incorrect Bcore service type**, surfaced as diagnostic noise.
  Not an Android 15 incompatibility as far as this evidence shows.
- **Honest caveat:** it appears *during* the Chrome launch sequence, and Chrome fails to
  launch. I am **not** asserting a causal link — the brief rightly says not to conflate them
  — but the co-occurrence is recorded because anyone investigating §9 should see it. If
  `isRunningApplication` always throws, a launch path that consults it may take a wrong
  branch. That is a hypothesis for a separate investigation.

## 11. Test results

No production code changed, so nothing to regress. Verified anyway:

- `flutter analyze` — 0 errors (4 pre-existing info-level lints)
- `flutter test` — **245/245**
- `usermanagerprobe` Debug **and** Release built, minification retained
- Host and guest probe cells run on the device of record

**Level 6/7/8 regression: NOT executed** in this phase and not claimed.

## 12. Limitations

1. Chrome's own crash was not reproduced first-hand — Chrome will not launch in a container
   right now (§9). The SecurityException was reproduced with an equivalent probe instead.
2. The fix is **proposed, not applied or validated**; no engine rebuild was performed.
3. Only the Debug probe variant was run on device; the Release variant was built but the
   host/guest cells were run in Debug. The failure is a framework ownership check, so R8 is
   not plausibly implicated, but that is reasoning rather than measurement.
4. Whether Android 15 *changed* anything here is UNKNOWN and not needed — hypothesis 7
   explains the failure without it.
5. `getUsers` and `getProfileParent` may have the same short-vs-long exposure; not tested.
