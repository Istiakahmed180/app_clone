# Phase 2 Test Plan and Results

Device of record: **OnePlus CPH2605, Android 15 (API 35), arm64-v8a**.
Emulators were used for build validation only — Bcore ships no x86_64 native library, and an
emulator is not evidence of production behaviour.

## Automated

| Suite | Command | Result |
| --- | --- | --- |
| Static analysis | `flutter analyze` | No issues |
| Dart unit tests | `flutter test` | 45 passed |
| Native instrumentation | `cd android && ./gradlew :app:connectedDebugAndroidTest` | 11 passed on device |
| Host APK | `flutter build apk --debug` | Built |
| Test APK | `cd ../virtual_test_app && ./gradlew :app:assembleDebug` | Built |

Note: `connectedDebugAndroidTest` uninstalls the host app afterwards, which destroys existing
container data. Run it before manual isolation testing, not after.

## Manual isolation checklist (the Phase 2 acceptance test)

| # | Step | Expected | Result |
| --- | --- | --- | --- |
| 1 | Open the normally installed Test App; set Counter=5, Name=Normal | Persists | PASS |
| 2 | Create Profile 1 | Card shows **Ready**, `user 0` | PASS |
| 3 | Launch Profile 1 | Opens as `ProxyActivity$P0` under the host UID | PASS |
| 4 | Profile 1 initial state | Counter=0, Test User (**not** the normal app's 5/Normal) | PASS |
| 5 | Set Profile 1 to Counter=10, Name=Alice | Persists | PASS |
| 6 | Create Profile 2 | Card shows **Ready**, `user 1` | PASS |
| 7 | Profile 2 initial state | Counter=0, Test User (**not** 10/Alice) | PASS |
| 8 | Set Profile 2 to Counter=20, Name=Bob | Persists | PASS |
| 9 | Reopen the normal app | Counter=5, Normal | PASS |
| 10 | Reopen Profile 1 | Counter=10, Alice | PASS |
| 11 | Reopen Profile 2 | Counter=20, Bob | PASS |
| 12 | Rename Profile 1 → Personal | Name changes, Counter=10/Alice intact | PASS |
| 13 | Delete Profile 2 | `user 1` directory removed | PASS |
| 14 | After delete: Profile 1 | Counter=10, Alice intact | PASS |
| 15 | After delete: normal app | Counter=5, Normal intact, still installed | PASS |
| 16 | Two profiles launched | Two simultaneous `com.example.virtualtestapp` processes | PASS |

## Evidence

UI round-trip:

```
NORMAL    : Counter: 5  Normal
PERSONAL  : Counter: 10 Alice
PROFILE 2 : Counter: 20 Bob
```

On-disk, read directly from the device — the guest wrote these through its own ordinary
`SharedPreferences`, with no host involvement:

```
/data/data/com.example.virtualspacedemo/blackbox/data/user/0/com.example.virtualtestapp/shared_prefs/virtual_test_app_state.xml
    stored_name=Alice   counter=10
/data/data/com.example.virtualspacedemo/blackbox/data/user/1/com.example.virtualtestapp/shared_prefs/virtual_test_app_state.xml
    stored_name=Bob     counter=20
/data/data/com.example.virtualtestapp/shared_prefs/virtual_test_app_state.xml     (uid u0_a806)
    stored_name=Normal  counter=5
```

Process and UID evidence:

```
topResumedActivity = com.example.virtualspacedemo/top.niunaijun.blackbox.proxy.ProxyActivity$P0

u0_a809  4528  com.example.virtualspacedemo          <- host
u0_a809  4602  com.example.virtualspacedemo:black    <- engine service process
u0_a809  6202  com.example.virtualtestapp            <- guest, profile 1  (host UID)
u0_a809  7528  com.example.virtualtestapp            <- guest, profile 2  (host UID)
u0_a806  8814  com.example.virtualtestapp            <- normal install    (own UID)
```

Two guests run at once, both under the host UID; the normal install keeps its own UID.

## Performance baseline

Indicative, from device runs — wall-clock, not instrumented:

| Operation | Observed |
| --- | --- |
| Engine attach + create (cold host start) | ~1.5 s |
| Profile create incl. container install | ~1 s |
| First virtual launch (cold guest process) | ~2 s |
| Subsequent virtual launch | < 1 s |
| Host APK size (debug, all ABIs) | ~179 MB (Flutter debug; `libblackbox.so` is ~346 KB arm64) |
| Crashes during the isolation run | 0 after the rename-dialog fix |

## Defects found and fixed during Phase 2

1. **Cold-start engine fallback** silently defeated virtualization — reported success while
   launching the app unvirtualized. Fixed via a public-API warm-up. See
   `VIRTUALIZATION_ENGINE.md`.
2. **Rename dialog crash** — `_dependents.isEmpty` assertion in `InheritedElement`. The rename
   dialog now owns its `TextEditingController` in a `StatefulWidget` instead of disposing it
   from the dialog future. Verified 3/3 plus a clean-install run.

## Known open issues

- `isRunningApplication` always throws inside Bcore, so cards show **Ready** and never
  **Running**.
- `REQUIRE_SECURE_ENV` property name is unconfirmed (see `SECURITY.md`).
- Only `com.example.virtualtestapp` is admitted; no third-party app has been tested.
- Verified on one device and one OEM build. No claim is made about other vendors or versions.
