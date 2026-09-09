# Chrome isolated-feature-split fix — evidence

Device: OnePlus CPH2605, Android 15 / API 35 / arm64-v8a, ADB serial `KNOJORMFV4GERKHM`.
All cells executed on that physical device. `emulator-5554` was not used.

## Engine provenance

| Item | Value |
| --- | --- |
| Upstream | `https://github.com/ALEX5402/NewBlackbox` |
| Pinned commit | `89b59836c66f173756a4ae258cf379a957649820` |
| Patches applied | 0001 … 0007 (0007 added by this phase) |
| New patch | `engine-patches/0007-isolated-split-manifest-components.patch` |
| NDK | 29.0.13846066 |
| JDK | 17 (Bcore's Java 21 pin downgraded by `build-engine.sh`, as for every prior build) |
| R8 / minify | ON |

### bcore.aar

| | SHA-256 | Bytes |
| --- | --- | --- |
| Before (patches 0001–0006) | `d9b7f36b094eab00c514ecb002371eec6af70154fd3f4cb6a50ce0be328f8175` | 2,093,182 |
| After (patches 0001–0007) | `f38fa7d3ef7a08f6defe61a95c11eb1f99ef2adb3617b47f62fb1726c10be4af` | 2,083,827 |

Backup of the previous artifact: `/tmp/bcore.aar.pre0007.bak`.
Post-R8 presence of the new code confirmed with `javap`:
`parserApk(String, String)` and `hostSplitClusterDir(String, String)` are both in the AAR.

## Chrome package set (host, unchanged by this work)

`base.apk`, `split_chrome.apk`, `split_config.en.apk`, `split_dev_ui.apk`,
`split_on_demand.apk`, `split_stack_unwinder.apk`; `primaryCpuAbi=arm64-v8a`;
`versionName=152.0.7977.75`. `base.apk` sets `android:isolatedSplits="true"`.

## Before / after: component registration

Measured from `BPackageManagerService` at install time.

| Package | Before | After |
| --- | --- | --- |
| `com.android.chrome` | 3 activities (base only), **no launcher** | **62 activities, 93 services, 30 receivers, 8 providers, splits=5** |
| `com.example.duplikaladder.isosplit` | 0 activities in base, **no launcher** | **2 activities, splits=1** |
| `org.videolan.vlc` | (config splits; launcher was already in base) | 41 activities, 7 services, 8 receivers, 5 providers, splits=2 |

## Before / after: launcher query and launch

| Subject | Before | After |
| --- | --- | --- |
| isolated-split fixture | `The engine refused to launch the virtual application.` (twice, incl. after container rebuild) | launcher resolved, guest UI reached, `VERDICT: PASS` |
| Chrome | same refusal, incl. on a fresh virtual user | `Launched com.android.chrome in user 1` on the **first** attempt |

## Files

| File | What it holds |
| --- | --- |
| `prefix-isosplit-launch.log` | pre-fix refusal of the isolated-split fixture |
| `key-lines-transcript.log` | **the decisive lines**, transcribed verbatim from the live reads (the device's ring buffer rotates within minutes, so the bulk dumps below lost them) |
| `postfix-isosplit-guest-ui.png` | fixture guest UI, `virtualized=true virtualUserId=0` |
| `postfix-chrome-launch-and-postlaunch.log` | Chrome launch, run, and the post-launch crash |
| `postfix-chrome-firstrun-ui.png` | Chrome's real first-run screen inside the clone |
| `postfix-vlc-guest-configsplit.png` | VLC guest UI (config-split regression) |
| `postfix-umprobe-guest-debug.png` | UserManager probe, guest Debug |
| `postfix-umprobe-guest-release.png` | UserManager probe, guest Release (minified) |
| `postfix-level6-guest.png` | Level 6 guest, `SQLite value=1` |
| `postfix-markor-guest.png` | Markor guest UI |
| `postfix-regression-session.log` | full logcat of the regression session |

Earlier investigation evidence in this directory was not modified.

## Virtual users used

Fresh clones created for this phase: Chrome **1**, VLC **2**, umprobe **3** (Debug) and
**4** (Release), Level 6 **5**, Markor **6**. The isolated-split fixture used virtual user
**0**, created *before* the fix — deliberately kept, because it also demonstrates the
stale-settings behaviour (see the report's regression notes).
