# Engine patches

Fixes for the vendored virtualization engine (NewBlackbox / Bcore,
commit `89b59836c66f173756a4ae258cf379a957649820`). These live here as source patches
because the engine ships as a prebuilt `android/app/libs/bcore.aar` and is not built from
source in this project.

## 0005 — Permission-gated public media paths

`IOCore` previously redirected the complete shared-storage tree into each clone's private
`blackbox/storage/emulated/<user>` tree. That isolated app-specific data correctly, but it
also left media apps unable to see the host's existing `Music`, `Movies`, `DCIM`, `Pictures`,
`Download`, and related public directories. The patch adds native path rules for existing
public media directories before the broad redirect, but only when the host package has the
user-granted `android:manage_external_storage` app-op. It does not grant permissions or
expose media when that app-op is denied.

## 0002 — Host-platform package visibility (Google Play services, GSF, Play Store)

**Symptom.** A cloned app that declares a Play services dependency concluded Play services
was missing. Measured inside a container on the CPH2605:
`getPackageInfo("com.google.android.gms")` and `getApplicationInfo(...)` both threw
`NameNotFoundException`, while `getApplicationEnabledSetting(...)` for the same package in
the same process returned `0` (enabled) microseconds later, and
`getPackageInfo("com.android.vending")` reported version `33.8.16-21` on a device whose real
Play Store is `53.0.27-34`. `GoogleApiAvailability` therefore returned `SERVICE_MISSING(1)`.

**Cause.** Two separate upstream defects. First, `IPackageManagerProxy`'s by-name hooks fell
back to the host only for `AppSystemEnv.isOpenPackage()`, which does not include the Google
platform packages — so the container answered `null` for a package the device plainly has.
Second, upstream carried a hardcoded `createFakeGooglePlayServicesPackageInfo()` that
answered every `com.android.vending` query with an invented version and an invented
`uid = 10001`, which is where the stale `33.8.16-21` came from.

**Fix.** A new list `sHostPlatformPackages` (`com.google.android.gms`,
`com.google.android.gsf`, `com.android.vending`) plus `isVisibleHostPackage()`, consulted at
the 7 by-name fallback sites in `IPackageManagerProxy` (`getPackageInfo`,
`getApplicationInfo`, `get{Activity,Service,Receiver,Provider}Info`,
`getComponentEnabledSetting`). The host `IPackageManager`'s answer is returned verbatim —
real version, real certificate, real flags. The fabricated `PackageInfo` is deleted.

Deliberately **not** added to `sSystemPackages`: that list is also read by
`IActivityManagerProxy` when binding a service, and Level 9 diagnostics had already proven
the service-bind path healthy. Keeping the new list `IPackageManagerProxy`-only changes what
a guest can *see* and nothing about how it connects. This is why
`engine-patches/deferred/0002-gms-passthrough-to-host.patch.superseded`, which took the
`sSystemPackages` route, was rejected.

`getInstalledPackages` and `getInstalledApplications` are untouched, so a guest still
enumerates only its own container — the change is strictly by-name. No signature,
certificate, permission, UID, account, or device property is altered; see
`evidence/physical-android15/level9-gms/host-passthrough-investigation/security-review.md`.

### Status: APPLIED and verified on device

On the CPH2605 (Android 15), in both debug and minified release, in a guest clone: GMS
package detection, `GoogleApiAvailability` (`SUCCESS(0)`) and the Google/Firebase dependency
diagnostics all pass, with guest-visible GMS version and signing certificates byte-identical
to the host. Intent resolution and `bindService` show no regression.

One test still does not pass and is **not** a package-visibility problem: a `GoogleApi`
client connection returns `DEVELOPER_ERROR`, because the GMS process sees the guest's real
Binder UID (the Duplika host UID) paired with the guest's own package name. GMS resolves the
caller in its own process against the real host PackageManager, so no hook in the guest can
change it, and closing it would mean spoofing caller identity toward Google. Recorded as
BLOCKED BY DESIGN — see the investigation's `root-cause-analysis.md`.

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
