# Chrome split-APK launch refusal — investigation

**Status: root cause CONFIRMED. No fix implemented — awaiting explicit authorization.**

Chrome is refused at launch with *"The engine refused to launch the virtual application."*
The cause is a real, general Bcore compatibility defect: **Bcore parses only `base.apk`, so
an app that declares its components in a feature split has no components at all inside the
container.** It is not Chrome-specific and needs no security bypass to fix.

## 1. The failure chain, end to end

| # | Location | Behaviour |
| --- | --- | --- |
| 1 | `BlackBoxCore.installPackageAsUser(String, int)` | installs a host app by handing `applicationInfo.sourceDir` — the **base APK** — to the service |
| 2 | `BPackageManagerService.installPackageAsUserLocked` | `parserApk(apkFile)` parses **that one file only**; split manifests are never opened |
| 3 | same, a few lines later | `mComponentResolver.addAllComponents(pkg)` registers **only base.apk's** components |
| 4 | `BPackageManager.getLaunchIntentForPackage` | `queryIntentActivities` for MAIN+INFO, then MAIN+LAUNCHER, finds nothing → `return null` |
| 5 | `BlackBoxCore.launchApk` | `launchIntentForPackage == null` → `return false` |
| 6 | `BlackBoxEngineAdapter.kt:357` `doLaunch` | maps `false` → `VIRTUAL_APP_LAUNCH_FAILED`, the message the user sees |

`launchApk` has exactly two `return false` branches. **Branch 1 (storage) is ruled out**:
Duplika registers no `AppLifecycleCallback` (grep over `android/app/src/main/kotlin` finds
no `onStoragePermissionNeeded` / `addAppLifecycleCallback`), so the callback loop is empty,
and the device log shows **both** `All files access not granted for launching:
com.android.chrome` **and** `Launching without all files access — some file operations may
fail`, proving it fell through. The refusal is therefore branch 2.

## 2. Direct evidence — Chrome's APKs

Pulled from the device of record and dumped with `aapt2 dump xmltree`:

| APK | Activities declared | Declares MAIN+LAUNCHER? |
| --- | --- | --- |
| `base.apk` (212 MB) | **3** | **No** |
| `split_chrome.apk` (8 MB) | **55** | **Yes** — `com.google.android.apps.chrome.Main` |

The only three activities in `base.apk` are helpers:

```
com.google.android.play.core.common.PlayCoreDialogWrapperActivity
com.google.android.play.core.missingsplits.PlayCoreMissingSplitsActivity
com.google.android.gms.common.api.GoogleApiActivity
```

`base.apk`'s manifest also sets:

```
android:isolatedSplits="true"
```

and `split_chrome.apk` declares `android:splitTypes="chrome__module"` — a **feature/module
split**, not a configuration split.

The host resolves the launcher correctly, which confirms the activity exists and that only
the container's view of it is missing:

```
$ cmd package resolve-activity --brief -a android.intent.action.MAIN \
      -c android.intent.category.LAUNCHER com.android.chrome
com.android.chrome/com.google.android.apps.chrome.Main
```

Host install set: `base`, `split_chrome`, `split_config.en`, `split_dev_ui`,
`split_on_demand`, `split_stack_unwinder`; `primaryCpuAbi=arm64-v8a`;
`versionName=152.0.7977.75`.

## 3. Why the existing split patches do not cover this

Patches 0003/0004 are real split support, but for a **different dimension** of splitting:

| Patch | What it makes work | Where |
| --- | --- | --- |
| 0003 | guest sees split **code** paths (`ai.splitSourceDirs` / `splitPublicSourceDirs`), read back from the host PM when `splitCodePaths` is empty | `PackageManagerCompat` |
| 0003 | native libraries extracted from the **ABI** split, not just base | `CopyExecutor` |
| 0004 | imported (`installApkFiles`) multi-APK installs carry their split list | `BPackageManagerService`, `CopyExecutor` |

All of that concerns **class loading and native libraries at runtime**. None of it concerns
**manifest component registration at install time**. `splitCodePaths` reaches the guest's
ClassLoader; it never reaches `parserApk` or `mComponentResolver`. So Chrome's
`Main` class would in fact be *loadable* once launched — the engine simply never learns the
activity exists, so it cannot build an intent to launch it.

Note also that `CopyExecutor`'s split branch sits inside `if
(!option.isFlag(InstallOption.FLAG_SYSTEM))`, while the host-app route uses
`InstallOption.installBySystem()` — so that branch is skipped for host-installed apps
anyway. This is not the Chrome cause (0003 handles the FLAG_SYSTEM case in
`PackageManagerCompat` instead) but it is worth knowing when scoping the fix.

## 4. Why Level 7 passing did not catch this

The first meaningful divergence, as asked:

| Property | Level 7 fixture | Chrome |
| --- | --- | --- |
| How it is split | `splits { }` in Gradle — **ABI / density configuration splits** | **isolated feature splits** |
| `isolatedSplits` | not set | **`true`** |
| Where components are declared | single manifest → **`base.apk`** | **`split_chrome.apk`** |
| Install route exercised | `installApkFiles(paths, userId)` (import) | `installPackageAsUser(String, userId)` (host app) |

A configuration split has exactly one manifest, which is compiled into the base. So Level 7
proves splits *load*, and proves nothing about split *manifests* — the assumption Chrome
violates was never under test. Two independent variables differ at once (split kind and
install route), and it is the **split kind** that matters here: the same defect would appear
on the import route, because `parserApk` is shared.

## 5. (E) The `ActivityStack` cast error — unrelated

Traced as instructed, and it is **not** on the launch path.

`BlackBoxCore.isRunningApplication(String, int)` (line ~1780) does:

```java
ActivityStack stack = (ActivityStack) ServiceManager.getService(ServiceManager.ACTIVITY_MANAGER);
```

`ACTIVITY_MANAGER` resolves to `BActivityManagerService`, which is not an `ActivityStack`, so
this cast **always** throws `ClassCastException`. It is swallowed by the method's own
`catch (Exception)`, logged, and returns `false`.

Its only caller is `BlackBoxEngineAdapter.kt:369` (`isVirtualAppRunning`), which is a
**state query**, not part of `launchApk`. Consequence: Duplika always believes no clone is
running. That is a separate upstream bug worth its own fix; **it does not cause and does not
contribute to the Chrome refusal.** No assumption was made either way — the caller set was
enumerated to establish it.

## 6. Root cause statement

**Bcore registers Android components from `base.apk`'s manifest only. An app using isolated
feature splits (`android:isolatedSplits="true"`) declares its components in a split manifest,
so inside a container it has no launcher activity — and no services, receivers or providers
either. `getLaunchIntentForPackage` correctly returns null for a package that, as far as the
virtual PackageManager knows, has no launchable activity.**

- **File:** `Bcore/src/main/java/top/niunaijun/blackbox/core/system/pm/BPackageManagerService.java`
- **Method:** `installPackageAsUserLocked(String file, String[] splitFiles, InstallOption, int)`
- **Line:** the `parserApk(apkFile.getAbsolutePath())` call and the `addAllComponents` that follows
- **Scope:** general — every isolated-split app, not just Chrome

## 7. Smallest possible fix

Parse each split APK's manifest at install time and merge its components into the same
`BPackage` before `addAllComponents` runs.

Concretely, in `installPackageAsUserLocked`, after `parserApk` succeeds and after the split
paths are known (`splitFiles`, or the host PM's `splitSourceDirs` for the FLAG_SYSTEM route),
run the existing `PackageParserCompat` over each split and append the parsed
`activities` / `services` / `receivers` / `providers` to the base `BPackage`. Nothing else
changes: `mComponentResolver.addAllComponents` then indexes the full set and
`queryIntentActivities` resolves the launcher.

Properties of this fix:

- reuses the parser already in the file; **no new parsing code**
- **no** change to `launchApk`, `getLaunchIntentForPackage`, or any launch-path logic
- **no** Chrome-specific branch — keyed on the package having splits, nothing else
- **no** UID, package, signature or certificate handling touched
- **no** exception suppressed — a split that fails to parse should be logged and skipped, and
  the install should still fail loudly if the *base* fails
- patch 0006 (UserManager) untouched

## 8. Security impact

**None identified.** The change makes the container's component table match what the host
platform already parsed from APKs the host itself installed and verified. It grants no new
capability, crosses no privilege boundary, and spoofs no identity:

- no UID, package-identity, signature or certificate spoofing
- no Binder caller-identity manipulation
- no Play Integrity / SafetyNet / GMS interaction
- no system-app impersonation
- no framework security check bypassed or exception suppressed

The one thing to get right is that split components must be merged **only** from splits
belonging to that same package's install (the paths the host PM reports), never from an
arbitrary file path — otherwise the parser becomes a way to inject components from an
unrelated APK. That is a constraint on the implementation, not a risk of the approach.

## 9. Regression risk

| Risk | Assessment |
| --- | --- |
| Non-split apps | **None** — the split list is empty, so the new code does not run |
| Configuration-split apps (Level 7) | **Low** — their splits carry no components; parsing yields nothing to merge |
| Duplicate components | **Medium, must be handled** — a split manifest repeats `<application>` attributes; merge components only, and de-duplicate by class name |
| Install time | **Low–medium** — one extra parse per split; Chrome has 5, and the large file (base) is already parsed today |
| `BPackage` Parcel layout | **Watch** — components are already parcelled; adding no new field keeps the layout stable. Existing clones' persisted settings should be checked for staleness, since they were written by the old parser |
| Engine artifact | Requires a `bcore.aar` rebuild, so Levels 6/7/8 must be re-run |

## 10. Proposed validation matrix

| # | Cell | Expectation |
| --- | --- | --- |
| 1 | Non-split app, Debug + Release | unchanged (no regression) |
| 2 | Level 7 config-split fixture, Debug + Release | still PASS — guards the known-good path |
| 3 | Level 6 / Level 8 ladder | still PASS — engine artifact changed |
| 4 | `usermanagerprobe`, host + guest | still PASS — proves 0006 intact |
| 5 | **Chrome, fresh virtual user, Debug** | launcher resolves; Chrome **actually starts** |
| 6 | **Chrome, fresh virtual user, Release (minified)** | same |
| 7 | Chrome clone, virtual PM state | activity count > 3; `Main` present |
| 8 | A second isolated-split app (chosen with approval) | generality, not a one-app fix |

Cell 5/6 is the only acceptance criterion that counts: **Chrome is not fixed until Chrome
launches.** Nothing below that will be reported as a pass.

## 11. Scope discipline

Changed in this phase: **nothing.** `git status` clean; `bcore.aar` still
`d9b7f36b094eab00c514ecb002371eec6af70154fd3f4cb6a50ce0be328f8175` (the patch-0006 build).
No Bcore edit, no Chrome edit, no Chrome-specific hack, no security bypass, no
UID/package/signature change, no Play Integrity / SafetyNet / GMS / microG interaction, no
exception suppressed, no commit. No private Chrome data was read — only manifest structure
from APKs, and component counts.

Reproduction of record: Chrome refused to launch on a **fresh** virtual user (user 5) on the
physical Android 15 device earlier in this session. Duplika has since been uninstalled from
that device (reinstalling wipes all clones), so no new on-device datapoint was added here;
the static evidence in §2 is what makes the cause conclusive, and it is independent of the
device state.

## 12. Limitations

1. The virtual component table was not dumped directly from a live clone — the release build
   is not debuggable, so `run-as` is unavailable. The component set is established from the
   parser's input (base.apk only) plus the manifests themselves, not read back from the
   container's own database.
2. Only Chrome was examined as an isolated-split app (n=1), so "every isolated-split app is
   affected" follows from the code path, not from a survey of apps.
3. Whether Chrome launches *successfully once the intent resolves* is unknown. This
   investigation explains the refusal; it does not promise Chrome then runs. Chrome may well
   hit further container issues after starting, and cell 5/6 above is what would tell us.

---

# Part 2 — fix implemented and validated

Authorized after the investigation above. **Outcome: the launch refusal is FIXED and Chrome
launches and runs. A separate, previously hidden post-launch defect is now the blocker, and
it is reported, not fixed.**

## 13. What was actually implemented — and why it is smaller than §7 proposed

§7 proposed parsing each split and merging components by hand. The implementation does
something smaller and safer, discovered while reading the framework parser on the device:

`PackageParser.parsePackage(File, int)` already dispatches on `File.isDirectory()`:

```
0000: invoke-virtual {v2}, Ljava/io/File;.isDirectory:()Z
0004: if-eqz v0, 000b
0006: invoke-direct {v1, v2, v3}, PackageParser;.parseClusterPackage:(Ljava/io/File;I)…
```

So handing it the install's **directory** instead of its base APK makes it take its own
cluster path, which parses the base plus every split and merges the components itself.
`parseClusterPackage`, `parseSplitApk` and `parseSplitApplication` are all present and
greylisted (`hiddenapi: UNSUPPORTED`) on this device's `framework.jar`, and
`parseClusterPackage` handles `isolatedSplits` natively via `SplitAssetDependencyLoader`.

That means **no hand-written merge, no de-duplication logic, and no component-identity
rules of our own** — the platform's own installer code does it, and
`BPackage(PackageParser.Package)` then converts the merged result exactly as it already
converted a monolithic one. This is strictly less code and strictly less risk than §7's plan.

One assumption in §3 was also wrong and worth recording: patch 0003's comment says
`File.listFiles()` on the install directory "returns null for us". On Android 15 the
package's own directory is `drwxrwxr-x system:system` — world-readable and listable; only
the parent `/data/app` and `~~hash` levels are `--x`. Verified from an app's own SELinux
domain with `run-as`, which listed all six of Chrome's files. The patch-0003 note referred
to the pre-Android-11 `/data/app/<pkg>/` layout.

### Source change

One file: `Bcore/src/main/java/top/niunaijun/blackbox/core/system/pm/BPackageManagerService.java`.

- **Call site**, in `installPackageAsUserLocked`:
  `parserApk(apkFile.getAbsolutePath())` → `parserApk(apkFile.getAbsolutePath(), packageName)`
- **New `parserApk(String, String)`** — cluster-parses when eligible, verifies the parsed
  package name matches what was expected, collects certificates, logs the component counts,
  and otherwise falls back to the existing single-file `parserApk(String)`.
- **New `hostSplitClusterDir(String, String)`** — decides eligibility, and is the security
  boundary (§15).

The existing `parserApk(String)` is untouched and is still the path for everything else.

Patch: `engine-patches/0007-isolated-split-manifest-components.patch` (150 lines), verified
to apply cleanly on top of 0001–0006.

## 14. Why it is general, not Chrome-specific

There is no reference to Chrome, to any package name, or to any split name anywhere in the
change. Eligibility turns on two package-agnostic facts: the APK being installed *is* the
host's own base APK for this package, and the host reports at least one split for it. Chrome
is simply the first app anyone tried that declares components in a split.

Demonstrated on three unrelated apps in one session: the purpose-built fixture (2 APKs,
12 KB, no native code, no GMS), Chrome (6 APKs, isolated feature splits), and VLC (3 APKs,
ABI + density config splits). The fixture is the proof of generality that matters — it
shares nothing with Chrome but the manifest shape.

## 15. Security assessment

**No new capability, no bypass, no spoofing.** The change makes the container's component
table match the manifests the host platform already parsed and verified for an app the host
itself installed.

Not touched: `launchApk`, `getLaunchIntentForPackage`, `queryIntentActivities`, UID handling,
package identity, signatures, certificates, GMS, microG, Play Integrity, SafetyNet. No
`SecurityException` is caught or suppressed anywhere in the change.

**Why it cannot become a component-injection mechanism** — the directory is never supplied by
a caller. `hostSplitClusterDir` requires all of:

1. the host PackageManager resolves `packageName` to an `ApplicationInfo`;
2. `hostInfo.sourceDir` **equals** the path we were asked to install — so an imported APK, a
   `FLAG_URI_FILE` copy in Duplika's cache, or any other guest-supplied path never qualifies;
3. `hostInfo.splitSourceDirs` is non-empty;
4. every one of those split paths has that same directory as its parent;
5. after parsing, `aPackage.packageName` must equal the expected package name, or the result
   is discarded and the base APK is parsed instead.

Independently of all five, that directory is `system:system` with no write permission for
apps, so nothing an app controls can be placed in it.

The fallback on failure is a parse-strategy fallback with a logged warning, not a suppressed
security check: the worst case is exactly today's behaviour.

## 16. Validation matrix — as executed

Every row below was run on the physical device. Nothing is claimed that was not executed.

| # | Cell | Result |
| --- | --- | --- |
| 1 | **Isolated-split fixture, BEFORE the fix** | **FAIL as predicted** — refused twice, incl. after container rebuild |
| 2 | **Isolated-split fixture, AFTER** | **PASS** — `splits=1 activities=2`, guest UI, `virtualized=true virtualUserId=0` |
| 3 | Level 7 — config-split app (VLC, 3 APKs), fresh user 2 | **PASS** — `splits=2 activities=41`; `libvlc 3.0.23`, **370 plug-in modules** loaded from the ABI split; guest UI reached |
| 4 | Level 6 — advanced APIs, fresh user 5 | **PASS** — guest UI; `SQLite value=1`; notification posted; job scheduled; **explicit and implicit** activity resolution both reached `LinkActivity` |
| 5 | Level 8 — VLC (real app, native, splits) | **PASS** (row 3) |
| 6 | Level 8 — Markor (real app, single APK), fresh user 6 | **PASS** — guest UI reached |
| 7 | UserManager probe — host Debug | **PASS** — P1 SUCCESS 8 ms, P2, P3 SUCCESS |
| 8 | UserManager probe — host Release (minified) | **PASS** — P1 SUCCESS 2 ms |
| 9 | UserManager probe — guest Debug, fresh user 3 | **PASS** — `virtualized=true`, P1 SUCCESS 1 ms |
| 10 | UserManager probe — guest Release (minified), fresh user 4 | **PASS** — `virtualized=true`, P1 SUCCESS 1 ms |
| 11 | Single-APK no-splits fast path | **PASS** — no cluster-parse log emitted; old path taken unchanged |
| 12 | **Chrome, fresh virtual user 1, Release** | **LAUNCHES** — `splits=5 activities=62 services=93 receivers=30 providers=8`; `Launched com.android.chrome in user 1` first attempt; real first-run UI rendered |
| 13 | Chrome relaunch | Launch **succeeds** again; renderer never starts, so the window stays blank |
| 14 | `flutter analyze` | 0 errors, 4 pre-existing info lints |
| 15 | `flutter test` | **245/245** |

**Not executed, and therefore not claimed:** a Duplika **Debug** build was not installed, so
rows 3, 4, 6 and 12 were measured in **Release (minified)** only — except the UserManager
probe, whose own Debug/Release APKs gave all four cells. Level 8's Fossify Notes and
AntennaPod were not re-run. Level 2/3/4 were not re-run.

## 17. Chrome: launch fixed, and a NEW post-launch defect

**The authorized scope is done: Chrome launches.** It is not "fixed" as a product, and is
not claimed to be.

What works now: the launcher resolves, `launchApk` returns true, the Chrome guest process
starts, and Chrome renders its genuine first-run sign-in screen — so the split's dex and its
native code both loaded. The patch-0006 UserManager fix is also confirmed *inside Chrome
itself*, which no earlier test could do:

```
I cr_AppResProvider: #getApplicationRestrictionsFromUserManager() Bundle[EMPTY_PARCEL]
```

— Chrome's own call succeeded, with no `SecurityException`.

**Then, ~35 s in, the browser process aborts.** Reproducible; identical on relaunch (4
occurrences logged). The cause is **not** splits and **not** GMS:

```
java.lang.IllegalArgumentException: Can't use instance name '0' with non-isolated
    non-sdk sandbox service 'top.niunaijun.blackbox.proxy.ProxyService$P1'
  at android.app.IActivityManager$Stub$Proxy.bindServiceInstance
  … top.niunaijun.blackbox.fake.service.IActivityManagerProxy.BindServiceCommon
  … android.content.ContextWrapper.bindIsolatedService
  … org.chromium.content.browser.ChildProcessLauncherHelperImpl.createAndStart
→ FATAL [base/android/jni_android.cc:203] Uncaught Java exception in native code
→ Fatal signal 5 (SIGTRAP) in tid … (Chrome_ProcessL)
```

Chrome starts each renderer with `bindIsolatedService(..., instanceName, ...)`.
`IActivityManagerProxy.BindServiceCommon` redirects the bind to Bcore's own
`ProxyService$P1`, which is **not** declared `android:isolatedProcess="true"`, so the
framework rejects an instance name on it. Chrome's child-process launcher cannot start a
renderer, and the browser process aborts. On relaunch the window is simply blank for the
same reason.

**Classification: NEW post-launch compatibility issue — Bcore proxy-service architecture vs
`bindIsolatedService` instance names.** Separate defect, separate root cause, needs its own
investigation and its own authorization. Not touched here.

Also observed and *not* the crash: `GoogleApiManager: SecurityException: Unknown calling
package name 'com.android.chrome'`, repeatedly. That is the identity-scoped GMS boundary
already classified UNSUPPORTED / SECURITY-BOUNDARY in
[level10-cross-artifact-gms-probe.md](level10-cross-artifact-gms-probe.md). Chrome catches
it and keeps running; it is noise here, not the fault. It is also further confirmation of
that classification from an app nobody wrote for this purpose.

## 18. Regression notes worth keeping

**Stale persisted settings are real, and self-heal.** The isolated-split fixture's clone had
been created *before* the fix, so its stored `BPackage` still held the base-only component
list. Its first post-fix launch was refused; Duplika's own "rebuild the container before a
second launch attempt" then re-installed it, the new parser ran, and it launched. So existing
clones of isolated-split apps recover automatically on the second attempt — no user action,
no migration code. Worth knowing rather than being surprised by.

**Install cost.** Chrome's cluster parse (222 MB base + 5 splits) took **536 ms** end to end,
VLC's **373 ms**. Not a concern.

**The `ActivityStack` cast bug is untouched**, as instructed. It still logs
`BActivityManagerService cannot be cast to ActivityStack` from
`isRunningApplication`, it is still only reached from `BlackBoxEngineAdapter.kt:369`, and
Chrome launched without it being addressed — which confirms it does not block the launch
path. It remains a separate issue.

## 19. Remaining limitations

1. The **import route is unchanged and still base-only.** `installApkFiles` deliberately does
   not qualify for cluster parsing (§15, condition 2), so an isolated-split app *imported* as
   loose APKs would still fail to launch. That is outside the authorized scope, which was
   explicitly the host-PackageManager-reported paths, and it is a real remaining gap.
2. Duplika **Debug** was not built or installed, so most guest cells are Release-only.
3. The virtual component table was still not dumped from a live clone; the counts come from
   the installer's own log line rather than from reading the container's database.
4. Chrome beyond ~35 s is unknown, because it aborts. Nothing about Chrome's steady-state
   behaviour in a container is established by this work.
5. `BPackage` is now substantially larger for apps like Chrome (62 activities, 93 services).
   No `TransactionTooLargeException` was seen, but the Binder-size headroom was not measured.

## 20. Is another Bcore change required?

**Yes — but a different one, and not yet authorized.** Chrome needs the
`bindIsolatedService` instance-name defect in §17 resolved before it is usable. That is a
change to `IActivityManagerProxy` / the proxy-service declarations, not to package parsing,
and it should get its own investigation-first phase.

Nothing further is required for the isolated-split defect itself: it is fixed, general, and
regression-tested.
