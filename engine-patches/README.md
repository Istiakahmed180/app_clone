# Engine patches

Fixes for the vendored virtualization engine (NewBlackbox / Bcore,
commit `89b59836c66f173756a4ae258cf379a957649820`). These live here as source patches
because the engine ships as a prebuilt `android/app/libs/bcore.aar` and is not built from
source in this project.

## 0001 — AppOps SyncNotedAppOp return type (fixes WhatsApp crash on API 30+)

**Symptom.** A cloned WhatsApp reaches onboarding but a background worker crashes:

```
java.lang.ClassCastException: Couldn't convert result of type java.lang.Integer
    to android.app.SyncNotedAppOp
    at $Proxy37.noteOperation
    at android.app.AppOpsManager.noteOpNoThrow
    at android.os.Environment.isExternalStorageLegacy
```

**Cause.** `IAppOpsManagerProxy.invoke()` answers every `check*`/`note*`/`start*` call with
the pre-Android-11 `int` `MODE_ALLOWED`. On API 30+ `noteOperation`, `startOperation`,
`noteProxyOperation`, `startProxyOperation` (and the API 34+ `*ForDevice` variants) are
declared to return `android.app.SyncNotedAppOp`, so the boxed `Integer` is cast to
`SyncNotedAppOp` and the guest crashes.

**Fix.** When the intercepted method's return type is `android.app.SyncNotedAppOp`, return a
correctly-typed MODE_ALLOWED `SyncNotedAppOp` instead of the int. This changes no behaviour —
the engine already allows every op — it only corrects the return type. `int`-returning methods
(`checkOperation`, `checkPackage`, …) are unaffected.

**Why it is not a runtime shim in this app.** It was attempted (wrapping `IAppOpsService` at
both the `AppOpsManager` instance and the `ServiceManager` cache level, in the guest process).
It does not hold: the engine re-installs its own AppOps hook every time it binds a guest
Application, overwriting any wrapper set earlier from the host's `Application.onCreate`. The
correct place is the engine itself.

### Applying / reproducing

`build-engine.sh` does the whole thing — clone at the pinned commit, apply every patch here,
reconcile the toolchain, build, sanity-check, and install `android/app/libs/bcore.aar`:

```bash
engine-patches/build-engine.sh
# needs: git, a JDK, the Android SDK, and NDK 29.0.13846066
```

The build is deterministic: re-running it reproduces the committed `bcore.aar` byte-for-byte
(sha256 verified). So the vendored binary is not an opaque blob — it is exactly what this
script generates from the upstream commit plus the patches here.

### Build note

Bcore's `compileOptions` pin `JavaVersion.VERSION_21`; the local JDK is 17, so they were
lowered to `VERSION_17` for the rebuild (the engine uses no Java 21 language features, so it
compiles unchanged). Built with `./gradlew :Bcore:assembleRelease` on NDK 29.0.13846066,
Gradle 8.14.5, AGP 8.13.2.

### Status: APPLIED and verified on device

`android/app/libs/bcore.aar` is the rebuilt, patched artefact (see
`android/app/libs/BCORE_SOURCE_COMMIT.txt`). On the OnePlus CPH2605 (Android 15) in a minified
release build:

- a cloned WhatsApp launches to "Welcome to WhatsApp" with **0 crashes** (previously one
  `ClassCastException: Integer -> SyncNotedAppOp` per launch); no AppOps error appears in logs.
- Telegram still launches cleanly (no regression).

The `.so` files (arm64-v8a, armeabi-v7a) are the freshly built ones; the engine's own consumer
proguard keeps `top.niunaijun.**`, so the fix survives its R8.
