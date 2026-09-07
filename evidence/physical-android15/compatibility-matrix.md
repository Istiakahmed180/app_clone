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

## Level 6 modern Android API matrix

The Level 6 probe is a single APK with no GMS dependency. It was installed and exercised inside virtual user 9 on the physical device. `PASS` below means the feature reached the expected system or guest UI; it does not imply that every related API is complete.

| Application | Feature/API | Install | Launch | Functionality | Relaunch | Debug | Release | Warnings | Failure layer |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| Ladder Level 6 | Runtime camera/notification permissions | PASS | PASS | PARTIAL: Android permission UI opened as Duplika, but guest status remained `false` after the camera result | PASS: relaunch retained the observed guest state | PARTIAL | PARTIAL | Host-identity permission behavior; no artificial grant applied | Permission virtualization / host identity |
| Ladder Level 6 | Notification channel, local notification, PendingIntent tap | PASS | PASS | Debug PASS: notification posted and tap returned to guest UI; Release FAIL: `BNotificationManager.createNotificationChannel` dereferenced a null `IBNotificationManagerService` stub | Debug PASS; Release relaunch PASS before notification test | PASS | FAIL | Release produced guest `FATAL EXCEPTION` | Bcore notification service initialization |
| Ladder Level 6 | JobScheduler / JobService | PASS | PASS | FAIL: `JobServiceStub: Schedule: args[0] is null, returning RESULT_FAILURE`; no guest `onStartJob` | PASS | FAIL | FAIL | Same failure in both variants | Bcore JobScheduler hook/proxy |
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

## Findings and limits

- No core-engine source files were modified for this ladder.
- Real-app APKs used for Level 5 were downloaded as single APKs from the F-Droid repository: AntennaPod 3.11.2 and Markor 2.15.2. Fossify Notes was selected but not included in the PASS matrix because its clone was not completed.
- The host Release build was installed after the Debug runs; Markor was independently relaunched and verified under both host variants. AntennaPod was independently verified under both host variants.
- `<queries>`, service-level `<property>`, and application-level `<uses-native-library>` generate Bcore parser warnings in the Chrome evidence. The current `ApkManifestReader` handles only narrow security metadata, not complete package parsing.
- No general split-APK implementation was added. Chrome remains a separate split-APK investigation.
- GMS, OEM/system-app compatibility, Play Integrity, and security bypasses remain intentionally out of scope.
- Level 6 has not changed the core engine. The first confirmed modern-API failures are permission state virtualization, JobScheduler dispatch, and Release notification-service initialization. No speculative core fix was applied.
