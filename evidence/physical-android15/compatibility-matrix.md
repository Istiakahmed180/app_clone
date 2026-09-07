# Physical Android 15 compatibility matrix

Device: OnePlus CPH2605, Android 15 / API 35  
ADB serial: `KNOJORMFV4GERKHM`

The Level 2–4 APKs are controlled ordinary third-party-style test applications. They are single APKs, have no GMS dependency, and do not use vendor APIs or native libraries.

| App | Package type | Install | Launch | UI | Basic function | Relaunch | Debug | Release | Failure layer |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| Baseline APK | Single APK | PASS | PASS | PASS | PASS: activities, provider, service, preferences | PASS | PASS | PASS | None observed |
| Ladder Level 2 | Single APK | PASS | PASS | PASS | PASS: button and SharedPreferences counter | PASS | PASS | PASS | None observed |
| Ladder Level 3 | Single APK | PASS | PASS | PASS | PASS: HTTPS request returned 200; WebView activity reached | PASS | PASS | PASS | None observed |
| Ladder Level 4 | Single APK | PASS | PASS | PASS | PASS: foreground service and receiver; notification permission granted | PASS | PASS | PASS | None observed |
| AntennaPod 3.11.2 (`de.danoeh.antennapod`) | Single APK | PASS | PASS | PASS | PASS: Home, Subscriptions, Add Podcast activity, networking path reached | PASS | PASS | PASS | Non-fatal JobService/WorkManager scheduling warning; podcast discovery returned an app-level error |
| Markor 2.15.2 (`net.gsantner.markor`) | Single APK | PASS | PASS | PASS | PASS: file view, virtual Documents path, To-Do/QuickNote navigation | PASS | PASS | PASS | Limited host storage permissions; app still launched and functioned |
| OnePlus Calculator | OEM/system APK | PASS | FAIL | FAIL | Not reached | FAIL | FAIL | FAIL | Guest invokes unsupported Android 15/Oplus `IBinder.getExtension` path |
| Chrome | Split APK | PASS | FAIL | FAIL | Not reached | Not tested | FAIL | Not tested | Bcore split/package parsing and launch rebuild path; parser warnings for modern manifest elements |
| Level 7 split fixture (`com.example.duplikaladder.level7fixture`) | Base + ABI split (`base.apk` + `split_config.arm64_v8a.apk`) | PASS | PASS | PASS | PASS: native library loaded from ABI split; base resources resolved | PASS: Debug; Release relaunch not completed because ADB daemon became unavailable after Release launch | PASS | PASS: launch/UI verified; relaunch not verified | None observed during import/launch |

## Level 7 general split APK matrix

Physical device: OnePlus CPH2605, Android 15 / API 35. The fixture was installed on the host with Android's `install-multiple`, then cloned through the normal Duplika picker. The guest UI was required for PASS.

| Application | Package type | Android features | Install | Launch | UI | Functionality | Relaunch | Debug | Release | Failure layer |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| Level 7 fixture | Base + one ABI split | JNI library in `split_config.arm64_v8a.apk`; SharedPreferences | PASS | PASS | PASS | PASS: `native=abi-native-loaded` and split marker visible | PASS: `launches=2` | PASS | PASS | None observed |
| Level 7 fixture | Base + ABI split + language configuration split | JNI library; multiple split paths | PASS | PASS | PASS | PASS: native library loaded and UI reached with all three APK paths | PASS: `launches=4` | Not tested | PASS | None observed |
| Level 7 fixture imported through file picker | Base + ABI split selected as two files | Multi-select, staged APK set, manifest validation, package-set install | PASS | PASS | PASS: guest `MainActivity` visible; `split_marker` and `abi-native-loaded` displayed | PASS: Debug relaunch verified (`launches=2`); Release relaunch not verified | PASS | PASS: Release launch/UI verified; relaunch blocked by local ADB daemon failure | None observed in package-set path |
| Level 7D candidate | Complex real-world split APK | Not selected: only safe third-party split package found was Binance, which is out of scope for this ladder | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested | Not tested | No safe in-scope candidate available |

## Level 6 modern Android API matrix

The Level 6 probe is a single APK with no GMS dependency. It was installed and exercised inside virtual user 9 on the physical device. `PASS` below means the feature reached the expected system or guest UI; it does not imply that every related API is complete.

| Application | Feature/API | Install | Launch | Functionality | Relaunch | Debug | Release | Warnings | Failure layer |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Ladder Level 6 | Runtime camera/notification permissions | PASS | PASS | PASS: guest `checkSelfPermission` and `PackageManager.checkPermission` both returned GRANTED; callback returned `[0,0]`; real `CameraManager.openCamera` passed | PASS: status remained `notification=true camera=true` after relaunch | PASS | PASS | No artificial grant; host permission state was used | Android 15 `checkPermissionForDevice` UID translation |
| Ladder Level 6 | Notification channel, local notification, PendingIntent tap | PASS | PASS | PASS: notification posted and tap returned to guest UI | PASS | PASS | PASS | No new warning after notification fix | None observed |
| Ladder Level 6 | JobScheduler / JobService | PASS | PASS | PASS: schedule returned `1`; guest `onStartJob` reached | PASS | PASS | PASS | Android 15 `JobInfo` was found at `args[1]` | None observed |
| Ladder Level 6 | Storage Access Framework / `ACTION_OPEN_DOCUMENT` | PASS | PASS | PARTIAL: DocumentsUI opened and cancel returned to guest; selection/save persistence not completed | Not tested | PARTIAL | PARTIAL | DocumentsUI is host system UI | SAF result/path virtualization remains incomplete to classify |
| Ladder Level 6 | SQLite local persistence | PASS | PASS | PASS: value read and incremented | Debug PASS: persisted value increased across relaunch; Release value read as `4` after the Release run, but was not re-read after the final relaunch | PASS | PARTIAL | None material to the probe | None observed |
| Ladder Level 6 | Explicit and implicit internal intents | PASS | PASS | PASS: `LinkActivity` UI reached for both paths | PASS | PASS | PASS | None material to the probe | None observed |

## Evidence

- Level 2: `ladder-level2-debug-*` and `ladder-level2-release-*` logs in this directory. Release relaunch displayed the persisted counter (`count=2`; the release run was installed over the existing debug virtual profile).
- Level 3: `ladder-level3-debug-network.log`, `ladder-level3-debug-webview.log`, `ladder-level3-debug-relaunch.log`, `ladder-level3-release-function.log`, and `ladder-level3-release-relaunch.log`.
- Level 4: `ladder-level4-debug-function.log` lines containing `LadderLevel4Service` and `LadderLevel4Receiver`, plus the corresponding release function and relaunch logs.
- AntennaPod: `level5-antennapod-release-launch.log`, `level5-antennapod-release-function.log`, `level5-antennapod-release-relaunch.log`, and the independently repeated `level5-antennapod-debug-host-launch.log`.
- Markor: `level5-markor-debug-launch.log`, `level5-markor-debug-function.log`, `level5-markor-debug-relaunch.log`, `level5-markor-release-launch.log`, and `level5-markor-release-relaunch.log`.
- Calculator: `debug-calculator-launch.log` and `release-calculator-launch.log`.
- Chrome: `debug-chrome-launch.log` and `chrome-install.log`.
- Level 6 Debug: `level6-debug-launch.log`, `level6-debug-permissions-notification.log`, `level6-debug-notification-tap.log`, `level6-debug-job.log`, `level6-debug-open-document.log`, `level6-debug-create-document.log`, `level6-debug-sqlite.log`, `level6-debug-explicit-intent.log`, `level6-debug-implicit-intent.log`, and `level6-debug-relaunch.log`.
- Level 6 Release: `level6-release-build.log`, `host-release-build-level6.log`, `level6-release-launch.log`, `level6-release-permissions.log`, `level6-release-notification-post.log`, `level6-release-job.log`, `level6-release-open-document.log`, `level6-release-explicit-intent.log`, `level6-release-implicit-intent.log`, `level6-release-sqlite.log`, and `level6-release-relaunch.log`.
- Level 7 Debug ABI split: `level7a-debug-split-launch.log` and `level7a-debug-split-relaunch.log`; the fixture UI reported `native=abi-native-loaded` and `launches=2` after relaunch.
- Level 7 Release ABI split: `level7a-release-split-launch.log`; the fixture UI reported `native=abi-native-loaded` and `launches=3` after the Release run.
- Level 7 imported package-set verification: `level7-imported/level7a-debug-package-set.log`, `level7-imported/level7a-debug-launch.log`, `level7-imported/level7a-release-package-set.log`, `level7-imported/level7a-release-launch.log`, and `level7-imported/level7a-release-guest.png`. Release import and first guest launch passed; Release relaunch remains unverified because the local ADB daemon failed before the repeat.
- Level 7 Release three-APK run: `level7c-release-three-apk-launch.log`; the fixture UI reported `native=abi-native-loaded` and `launches=4` with `base.apk`, `split_config.arm64_v8a.apk`, and `split_config.en.apk` installed together.
- `level7c-debug-three-apk-launch.log` is retained as a non-result diagnostic; it captured the wrong existing profile after the home-screen scroll and is not counted as a Level 7C Debug test.

## Findings and limits

- The core engine architecture was not redesigned. The vendored Bcore AAR was rebuilt with one general Android 15 permission-hook override; the Level 6 APK was also extended with diagnostic logging and a real camera protected-API probe.
- Real-app APKs used for Level 5 were downloaded as single APKs from the F-Droid repository: AntennaPod 3.11.2 and Markor 2.15.2. Fossify Notes was selected but not included in the PASS matrix because its clone was not completed.
- The host Release build was installed after the Debug runs; Markor was independently relaunched and verified under both host variants. AntennaPod was independently verified under both host variants.
- `<queries>`, service-level `<property>`, and application-level `<uses-native-library>` generate Bcore parser warnings in the Chrome evidence. The current `ApkManifestReader` handles only narrow security metadata, not complete package parsing.
- The tested host-installed split path is working with the existing Bcore split-path plumbing: Android exposed `base.apk` plus `split_config.arm64_v8a.apk` (and, in the three-APK run, `split_config.en.apk`), Bcore opened both code paths, and Android's native loader loaded `liblevel7fixture.so` directly from the ABI split. No engine redesign or app-specific workaround was needed in this phase.
- Before this Level 7 change, the imported-APK path accepted and retained only one APK (`File`/`apkPath`) rather than a grouped base-plus-splits set. The first reproduced failure was split metadata inspection: Android's public archive API returned `null` for the standalone split, before Bcore installation.
- The imported-APK path now carries an ordered APK set, retains all selected files per profile, validates package/version/base/split uniqueness, and reads standalone split manifest identity when Android's public archive API rejects that split. The general Bcore package-set API installs the base and splits together, retains internal split paths, and copies native libraries from imported splits. Physical Debug and Release runs reached the guest UI; Debug relaunch passed. Release relaunch could not be completed because the local ADB daemon stopped accepting connections after the first Release launch, so Level 7 is not fully closed until that one step is repeated.
- Level 7A (base plus one non-ABI configuration split) and Level 7D (a complex safe real-world split app) remain unverified. The available physical third-party split package was Binance and was intentionally excluded as a financial application.
- GMS, OEM/system-app compatibility, Play Integrity, and security bypasses remain intentionally out of scope.
- The confirmed permission root cause was Android 15 routing `Context.checkSelfPermission()` through `IActivityManager.checkPermissionForDevice()`. Bcore translated the virtual UID (`10013`) only on the older `checkPermission()` path, so the host grant was not visible to the guest. The general hook now maps the virtual UID to the host UID while preserving the device ID and existing older-path behavior.
- Permission evidence: `level6-debug-permission-hook-result.log`, `level6-debug-permission-pass.log`, and `level6-release-permission-hook-result.log`. Regression evidence: `level6-release-permission-regression.log`.
