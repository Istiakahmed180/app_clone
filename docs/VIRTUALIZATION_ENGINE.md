# Virtualization Engine — Selection, Build and Behaviour

## Selected backend

| | |
| --- | --- |
| Engine | NewBlackbox `Bcore` (VirtualApp/VirtualAPK lineage) |
| Repository | https://github.com/ALEX5402/NewBlackbox |
| Commit | `89b59836c66f173756a4ae258cf379a957649820` (2026-07-19) |
| Licence | Apache-2.0 — see `DEPENDENCY_LICENSE_AUDIT.md` for open provenance questions |
| Namespace | `top.niunaijun.blackbox` |

## Toolchain reconciliation

Measured, not assumed:

| | NewBlackbox declares | Virtual Space uses | Resolution |
| --- | --- | --- | --- |
| Gradle | 8.14.5 | 9.1.0 | Kept separate — Bcore built by its own wrapper, consumed as an AAR |
| AGP | 8.13.2 | 9.0.1 | Same |
| Kotlin | 1.9.23 | 2.3.20 | Same |
| Java | 21 in `Bcore/build.gradle` | 17 | **Java 21 was not actually required.** Bcore compiles cleanly at 17, which matches NewBlackbox's own README ("JDK 17"). The declaration is inconsistent with its documentation. |
| NDK | 29.0.13846066 | 29.0.14206865 installed | Patched to the installed patch release; built without issue |
| compileSdk | 35 | 36 | No conflict — AAR metadata declares `minCompileSdk=1` |
| targetSdk | 28 (their sample app) | **36 (unchanged)** | See below |

### The targetSdk finding

VirtualApp-derived engines are usually run from a `targetSdk 28` host to soften hidden-API and
scoped-storage enforcement, and NewBlackbox's own sample app targets 28. Lowering Virtual
Space to 28 would have been a large, Play-hostile change.

It proved unnecessary. The engine initialises, installs and launches correctly with the host at
**targetSdk 36 on Android 15**, verified on device. Logcat shows the platform granting the
hidden-API reflection Bcore needs (`TargetSdkVersion=36 ... using reflection: allowed`).

This is a device-verified result on one OEM build, not a general guarantee.

## Reproducing the vendored artefacts

```bash
git clone https://github.com/ALEX5402/NewBlackbox.git
cd NewBlackbox && git checkout 89b59836c66f173756a4ae258cf379a957649820
echo "sdk.dir=$HOME/Library/Android/sdk" > local.properties

# Local modifications, both recorded here:
#  1. Bcore/build.gradle: JavaVersion.VERSION_21 -> VERSION_17
#  2. Bcore/build.gradle: ndkVersion -> the NDK patch release installed locally
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
./gradlew :Bcore:assembleDebug :black-reflection:jar
```

Copy to `android/app/libs/` as `bcore.aar` and `black-reflection.jar`. The source commit is
recorded in `android/app/libs/BCORE_SOURCE_COMMIT.txt`.

Bcore ships native code for **arm64-v8a and armeabi-v7a only**. There is no x86_64
`libblackbox.so`, so x86_64 emulators cannot run the engine; testing needs an arm64 device or
an arm64 emulator image.

## Engine API actually used

Verified against source, not the project's `Docs.md`:

| Call | Purpose |
| --- | --- |
| `doAttachBaseContext(Context, ClientConfiguration)` / `doCreate()` | Host lifecycle attachment |
| `installPackageAsUser(String, int)` → `InstallResult{success,msg}` | Install into a container |
| `uninstallPackageAsUser(String, int)` | Remove from a container |
| `isInstalled(String, int)` | Container membership |
| `launchApk(String, int)` | Start the guest |
| `stopPackage(String, int)` | Stop the guest |
| `getUsers()` → `List<BUserInfo{id,...}>`, `deleteUser(int)` | Container lifecycle |
| `getBPackageManager().forceReinitialize()` | Service warm-up — see below |

## Backend defects found and worked around

### 1. Cold-start fallback silently defeats virtualization (worked around)

`BPackageManager.shouldUseFallbackMode()` calls `isServiceHealthy()`, which inspects a
**lazily-cached** binder without fetching it first. On a cold process that cache is still null,
so the first call degrades to a host-`PackageManager` fallback.

The consequences were not cosmetic. Observed before the fix:

```
W BlackManager: Using fallback isInstalled check ... due to service failures
W BlackManager: Using fallback launch intent ... due to service failures
```

`isInstalled` then answered from the *host* package manager — reporting the app as installed in
every virtual user, including ones that had never been provisioned — and the launch produced an
ordinary, unvirtualized activity. The engine reported success throughout.

**Workaround:** `BlackBoxEngineAdapter.warmUpPackageService()` calls Bcore's own public
`forceReinitialize()` before package-manager work. The engine is not patched or reflected into.
After the fix the log reads `Installed com.example.virtualtestapp into user 0` and the launch
produces `ProxyActivity$P0`.

This is why the adapter never treats an engine "success" as proof on its own.

### 1b. Service-creation rate limiting (worked around)

`forceReinitialize()` must not be called back-to-back. It clears the binder cache and then
re-fetches, but Bcore rate-limits service creation to one attempt per 50 ms and returns the
just-cleared (null) reference inside that window. Two rapid warm-ups therefore leave the
service null, and the next call throws:

```
Attempt to invoke interface method '...IBPackageManagerService.installPackageAsUser(...)'
on a null object reference
```

This was self-inflicted: the first version of the warm-up called `forceReinitialize()` from
both `isPackageInstalled` and `installPackage`, which are invoked microseconds apart when a
profile is created. It surfaced as the *second* profile creation failing while the first
succeeded.

**Workaround:** the adapter guards warm-ups behind a 1 s interval, no longer warms up in
`isPackageInstalled`, and retries once past Bcore's own 2 s failure backoff
(`RETRY_TIMEOUT_MS`) before giving up. Because that retry sleeps, all engine calls were moved
off the platform thread onto a single background executor in `NativeBridge`, with results
posted back to the main looper.

Note the failure was reported honestly throughout: the error reached the UI and the profile was
rolled back rather than left half-created.

### 2. `isRunningApplication` always fails (accepted limitation)

```
W BlackBoxCore: isRunningApplication failed:
  ...am.BActivityManagerService cannot be cast to ...am.ActivityStack
```

An unconditional bad cast inside Bcore. The adapter catches it and reports `running = false`,
so profile cards show **Ready** rather than **Running** even while a guest is on screen.
Launch and isolation are unaffected. Fixing this requires patching the backend and is deferred.

### 3. Benign initialisation warnings

Present on Android 15 / ColorOS and not affecting the tested behaviour:

- `BootstrapClass: reflect bootstrap failed: NoSuchMethodException dalvik.system.VMRuntime.setHiddenApiExemptions`
  — FreeReflection's bulk exemption path is unavailable; the reflection Bcore actually needs is
  still permitted by the platform.
- `Could not access ResourcesManager overlay field` / `WindowManager leak field` — optional
  fields absent on this build.
- `GmsProxy: Failed to get gms service binder`, `WorkManagerProxy: ClassNotFoundException
  androidx.work.WorkManager` — GMS and WorkManager virtualization are out of Phase 2 scope.
