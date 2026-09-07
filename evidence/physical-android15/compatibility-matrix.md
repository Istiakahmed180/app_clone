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
| OnePlus Calculator | OEM/system APK | PASS | FAIL | FAIL | Not reached | FAIL | FAIL | FAIL | Guest invokes unsupported Android 15/Oplus `IBinder.getExtension` path |
| Chrome | Split APK | PASS | FAIL | FAIL | Not reached | Not tested | FAIL | Not tested | Bcore split/package parsing and launch rebuild path; parser warnings for modern manifest elements |

## Evidence

- Level 2: `ladder-level2-debug-*` and `ladder-level2-release-*` logs in this directory. Release relaunch displayed the persisted counter (`count=2`; the release run was installed over the existing debug virtual profile).
- Level 3: `ladder-level3-debug-network.log`, `ladder-level3-debug-webview.log`, `ladder-level3-debug-relaunch.log`, `ladder-level3-release-function.log`, and `ladder-level3-release-relaunch.log`.
- Level 4: `ladder-level4-debug-function.log` lines containing `LadderLevel4Service` and `LadderLevel4Receiver`, plus the corresponding release function and relaunch logs.
- Calculator: `debug-calculator-launch.log` and `release-calculator-launch.log`.
- Chrome: `debug-chrome-launch.log` and `chrome-install.log`.

## Findings and limits

- No core-engine source files were modified for this ladder.
- `<queries>`, service-level `<property>`, and application-level `<uses-native-library>` generate Bcore parser warnings in the Chrome evidence. The current `ApkManifestReader` handles only narrow security metadata, not complete package parsing.
- No general split-APK implementation was added. Chrome remains a separate split-APK investigation.
- GMS, OEM/system-app compatibility, Play Integrity, and security bypasses remain intentionally out of scope.
- The next untested rung is a real, non-GMS, single-APK third-party app; the installed candidates inspected so far were excluded when they were split APKs, GMS-dependent, or vendor/system applications.
