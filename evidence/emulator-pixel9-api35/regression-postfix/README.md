# Regression — after the engine permission fix

A production change was made this phase (`android/app/libs/bcore.aar` rebuilt with the
repository's own runtime overrides), so this is a real regression run, not a formality.

Engine: `23689bce6d76f144f9c2b6c17745fa79abc26a04a3aaae5ec8bf4a39031da6b9`
(previous: `7769e0d4cfa09ee1d9b42d76d74b6c7761602546734c49715cb6228329df160d`).

| Check | Result | Evidence |
| --- | --- | --- |
| `flutter analyze` | 4 pre-existing info lints, 0 errors | — |
| `flutter test` | **298/298 passed** | — |
| `:app:testDebugUnitTest` (JVM, incl. GMS provider tests) | BUILD SUCCESSFUL | — |
| Debug APK build | OK | — |
| Release APK build | OK (56.9 MB) | — |
| Level 10 GMS probes, host Debug + Release | 18 probes, expected verdicts | `../level10-gms/host/` |
| Level 10 GMS probes, guest Debug + Release | identical in both build types | `../level10-gms/guest/` |
| Caller-identity boundary still enforced | 28-29 refusals per guest run, unchanged | `../level10-gms/expansion-matrix.md` |
| UserManager API 35 fix | **PASS** — 3/3 probes SUCCESS | `usermanager-probe-guest.txt` |
| Level 6 (modern API / runtime permissions) | **PASS**, and improved: header now reads `notification=true camera=true` after granting, where it previously stayed `false` | — |
| Level 6 SQLite / notification / job probes | PASS, 0 `RemoteException`/`DeadObjectException` | — |
| Level 7 (split APK) | **PASS** — `launches=1 marker=split_marker native=abi-native-loaded`, 0 crashes | `level7-split-guest.txt` |

## Not run, and not claimed

- **Level 8** (real apps) and **Level 11** (isolated split feature) were not re-run.
- **Level 12** (isolated service, patch 0008) was verified in the previous phase on the
  pre-fix engine, not re-run against this build.
- **Physical OnePlus CPH2605: NOT TESTED** — no device attached during this phase.

## Note on the freezer anomaly

The previous phase recorded `DeadObjectException` storms caused by Android 15's freezer
killing Duplika's `:black` server process (`Sync transaction while frozen`) under repeated
backgrounding. It did not recur in this phase's runs. It is a process-lifecycle issue
unrelated to the permission fix and remains open.
