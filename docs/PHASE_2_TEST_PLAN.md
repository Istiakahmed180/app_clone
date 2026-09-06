# Phase 2 Test Plan and Results

> **Note on the captured output below.** These runs predate the rename from *Virtual Space*
> to **Duplika**, so device transcripts here still show the old host package
> `com.example.virtualspacedemo` and the old app label. Nothing else about them changed; the
> host package is now `co.tdevs.duplika`.

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
2. **Second profile creation failed with a null service binder** — caused by calling the
   backend's `forceReinitialize()` twice inside its 50 ms rate-limit window. Fixed with an
   interval guard plus a bounded retry past the backend's 2 s backoff; engine calls now run on
   a background executor so the retry cannot block the UI. Re-verified: two profiles created
   back-to-back, both `Ready` with `user 0` / `user 1`.
3. **Rename dialog crash** — `_dependents.isEmpty` assertion in `InheritedElement`. The rename
   dialog now owns its `TextEditingController` in a `StatefulWidget` instead of disposing it
   from the dialog future. Verified 3/3 plus a clean-install run.

## Additional checks from the Phase 2 review pass

| Check | Expected | Result |
| --- | --- | --- |
| Delete a profile, create a new one that reclaims the same `virtualUserId` | New profile starts clean, does **not** inherit the deleted profile's data | PASS — reclaimed `user 0` opened at Counter=0 / Test User, not the deleted 10/Alice |
| Other profiles after a delete | Untouched | PASS — `user 1` still Bob/20 |
| Normal install after a delete | Untouched | PASS — Normal/5 |
| Host force-stop and restart | Profiles and the profile→user mapping survive | PASS |
| APK upgrade over an existing install | Profiles, mapping and container data survive | PASS |

Two defects were found by code review in the same pass and fixed:

1. **Unguarded channel reply.** `NativeBridge` replied on the main looper without checking the
   channel was still attached. An activity destroyed during a long install would have thrown.
   Now the reply is dropped with a log if the bridge has detached.
2. **Launch lacked the install path's service retry.** Launch reads the same package service
   that install does, so it was exposed to the same null-binder window. It now shares
   `withServiceRetry`.

While adding that retry, `withServiceRetry` was corrected to retry **only when the engine call
throws**. A returned `Failure` is a definitive answer ("not installed", "refused") and must not
be delayed by the 2 s backoff or repeated.

## Automated isolation coverage (added after the Phase 1-4 audit)

Until this was added, the central claim — two clones of one app do not share data — was
supported **only by manual observation**. An engine or adapter regression could have removed
isolation without any suite noticing. `ContainerIsolationTest`
(`android/app/src/androidTest/.../native/ContainerIsolationTest.kt`) now asserts it:

| Test | Asserts |
| --- | --- |
| `twoClonesOfOnePackageGetSeparateContainers` | Distinct `virtualUserId` and distinct container paths for the same package |
| `dataWrittenInOneContainerIsNotVisibleInTheOther` | Each container keeps its own value |
| `writingToOneContainerDoesNotCreateTheFileInAnUnwrittenOne` | No leakage into an untouched container |
| `aLaunchedGuestWritesOnlyIntoItsOwnContainer` | The **guest process** writes only into its own container — the redirection proof |
| `deletingOneCloneLeavesTheOthersDataIntact` | Deleting one clone does not disturb another |
| `containersLiveInsideTheHostSandboxNotTheNormalInstallation` | A clone never resolves to `/data/data/<package>` |

`@Before requireAWorkingEngine` fails the class outright when the backend did not start, so a
device where nothing is virtualized cannot produce a green run that proved nothing.

### Validated by mutation, not just by passing

A passing test proves nothing unless it can fail. `VirtualProfileManager.getOrCreate` was
temporarily mutated to map every profile to virtual user 0 — i.e. all clones sharing one
container. **Five of the six tests failed**, as did the pre-existing
`VirtualProfileManagerTest.allocatesDistinctIdsAndReusesFreedOnes`. The mutation was reverted
and the suite returned to green (35 instrumentation tests).

The one test that correctly did *not* fail is
`containersLiveInsideTheHostSandboxNotTheNormalInstallation`, which does not depend on clones
having distinct users.

### An intermittent install failure this test exposed — and its fix

The first mutation run surfaced a genuine product bug rather than a test problem: one
`installAppToProfile` returned `APP_INSTALL_FAILED / "unknown engine error"` and the isolation
test failed spuriously (once in roughly five runs).

Cause: `BlackBoxCore.installPackageAsUser` returns **null** when its package service is
momentarily unhealthy. `BlackBoxEngineAdapter.doInstall` collapsed that into
`APP_INSTALL_FAILED`, indistinguishable from a genuine refusal — and `withServiceRetry`
deliberately does not retry returned failures, so the install never recovered.

A null result is the engine saying *nothing*, not saying *no*. It now returns its own
`ENGINE_NO_RESPONSE` code, which `withServiceRetry` treats as transient and retries, while a
refusal carrying a reason stays definitive and is not retried.

Verified by injection, both directions:

| Injected behaviour | Expected | Observed |
| --- | --- | --- |
| First install returns no-response | Retry recovers, suite green | 47/47 passed |
| Every install returns no-response | Failure propagates with the new code | Isolation tests failed with `ENGINE_NO_RESPONSE` |

The test was **not** given a retry of its own; the fix is in the product.

### Coupling note

`ContainerIsolationTest.containerDir()` encodes the backend's on-disk layout
(`blackbox/data/user/<id>/<package>`). If the virtualization backend is replaced, that helper
is the single place the test needs updating.

## Known open issues

- `isRunningApplication` always throws inside Bcore, so cards show **Ready** and never
  **Running**.
- `REQUIRE_SECURE_ENV` property name is unconfirmed (see `SECURITY.md`).
- Only `com.example.virtualtestapp` is admitted; no third-party app has been tested.
- Verified on one device and one OEM build. No claim is made about other vendors or versions.
