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
