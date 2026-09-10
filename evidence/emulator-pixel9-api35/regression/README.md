# Regression run — Pixel 9 / Android 15 / API 35 emulator

No production or engine code was changed in this phase (only the `level10_gms` diagnostic
fixture), so these were run to confirm the environment rather than to clear a change.

| Check | Result | Evidence |
| --- | --- | --- |
| `flutter analyze` | 4 pre-existing info lints, 0 errors | — |
| `flutter test` | **298/298 passed** | — |
| `:app:testDebugUnitTest` (JVM, incl. GMS provider tests) | BUILD SUCCESSFUL | — |
| Debug APK build | OK | — |
| Release APK build | OK (56.9 MB) | — |
| Release Duplika installed over Debug; existing clone survived and launched | PASS | `../level10-gms/guest/guest-release-full-report.txt` |
| UserManager API 35 fix | PASS — 3/3 probes SUCCESS | `usermanager-probe-guest.txt` |
| Isolated service / split manifest (patch 0008) | PASS — 4/4 bind shapes connected, incl. `bindIsolatedService` + instanceName | `isolated-service-guest.txt` |
| Level 6 (modern API / runtime permissions) | PASS on a clean run — clone launches, virtualized runtime-permission dialogs dispatch and resolve, probes run with 0 `RemoteException`/`DeadObjectException` | — |

## One anomaly, characterised

A first Level 6 attempt produced `DeadObjectException` from every `IBPackageManagerService`
call. Cause, from the same logcat:

```
ActivityManager: Killing <pid>:co.tdevs.duplika:black/u0a215 (adj 905): Sync transaction while frozen
```

The Android 15 freezer killed Duplika's `:black` server process while it was backgrounded,
after which the guest's PackageManager hooks had no server to talk to. Re-running with a
fresh Duplika process gave **0** such errors.

This is a process-lifecycle observation, not a functional regression, and it is not
attributable to this phase — no production code was changed. It is recorded because it is
real and reproducible under repeated background/foreground cycling, and because it is the
kind of thing that would otherwise be misread as a GMS failure. Investigating it belongs to
a separate phase.

## Not run

Level 7 (split APK), Level 8 (real apps), Level 11 (isolated split feature) were **NOT
RE-RUN** here and are not claimed. Physical OnePlus CPH2605: **NOT TESTED** — no device
attached during this phase.
