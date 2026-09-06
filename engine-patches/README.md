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

### Applying

```bash
git clone https://github.com/ALEX5402/NewBlackbox.git
cd NewBlackbox && git checkout 89b59836c66f173756a4ae258cf379a957649820
git apply /path/to/engine-patches/0001-appops-syncnotedappop-return-type.patch
# then rebuild the :Bcore AAR (needs the NDK version pinned in Bcore/build.gradle:
# ndkVersion 29.0.13846066) and replace android/app/libs/bcore.aar
```

The patch is verified to compile against the vendored `classes.jar` + Android API 36.
It has NOT been run on device, because building the engine AAR needs the NDK toolchain that
is the reason the engine is vendored prebuilt in the first place.
