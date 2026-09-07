# Level 8 real-world application compatibility matrix

Device: OnePlus CPH2605, Android 15 / API 35 / arm64  
ADB serial: `KNOJORMFV4GERKHM`

`PASS` requires physical guest UI and basic functionality. A successful build, host installation, or APK staging alone is not a pass.

| Application | Package | Category | APK type | Install | Launch | Function | Relaunch | Debug | Release | Status | Failure category |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Fossify Notes 1.5.0 | `org.fossify.notes` | Productivity / database / storage | Single APK | PASS | PASS | PASS: created `Level8_note`, restored after relaunch | PASS: note restored | PASS | PASS | PASS | None observed |
| AntennaPod 3.11.2 | `de.danoeh.antennapod` | Networking / media / native libraries | Single APK | PASS: actual user-facing import and install | PASS: guest `MainActivity` visible | PASS: public HTTPS podcast search for `science` returned visible results | PASS: same profile relaunched and UI visible | PASS | PASS | PASS | No core failure; one remote artwork URL logged a Glide load warning |
| Markor 2.15.2 | `net.gsantner.markor` | Productivity / storage / multi-activity | Single APK | Previously verified Level 5; Level 8 batch pending | Pending | Pending | Pending | Pending | Pending | PENDING | — |
| Level 7 split fixture | `com.example.duplikaladder.level7fixture` | Split / ABI native library | Base + ABI split | Level 7 PASS | Level 7 PASS | Level 7 PASS | Level 7 PASS | PASS | PASS | Regression reference | — |

## Selected first batch

- Fossify Notes is the first new Level 8 target because it is a legitimate ordinary single APK with local note/database functionality and no GMS requirement in the selected artifact.
- AntennaPod and Markor are retained as Level 5 real-world regression references, not counted as new Level 8 passes until their Level 8 basic-function flows are repeated and logged.
- Banking, payment, GMS-dependent, integrity-protected, OEM/system, and security-sensitive applications are excluded from this batch.

## Evidence layout

Each application gets separate Debug and Release evidence files:

- `install.log`
- `launch.log`
- `function.log`
- `relaunch.log`
- `failure.log` when applicable

No compatibility fixes are authorized from this matrix alone. Any failure must first be classified from logcat and package/process evidence.
