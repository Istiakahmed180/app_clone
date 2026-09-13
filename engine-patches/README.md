# Engine patches

Fixes for the vendored virtualization engine (NewBlackbox / Bcore,
commit `89b59836c66f173756a4ae258cf379a957649820`). These live here as source patches
because the engine ships as a prebuilt `android/app/libs/bcore.aar` and is not built from
source in this project.

## Runtime overrides (`overrides/`) — and a trap to avoid

`overrides/` holds whole Java classes that replace their vendored counterparts.
`apply-runtime-overrides.sh` recompiles them against the shipped `classes.jar` and rewrites
`android/app/libs/bcore.aar` in place. Unlike the `*.patch` files, which are applied by
`build-engine.sh` when the engine is rebuilt from source, **these are only present in the
binary if that script has been run since they were last edited.**

That trap was hit: `IActivityManagerProxy$checkPermission.java` had been written to handle
Android 15's `checkPermissionForDevice`, but the committed AAR still registered only the
older `checkPermission`. The result was that `Context.checkSelfPermission`,
`checkCallingOrSelfPermission` and `checkPermission(pid, uid)` all returned **DENIED** inside
a guest for permissions the app genuinely declared and had been granted — because those
resolve by UID, and the guest's virtual UID means nothing to the platform. The
`PackageManager.checkPermission(perm, packageName)` family was unaffected, which is why the
defect stayed hidden: most probes had used the package-name form.

Measured consequences (Pixel 9 / API 35, `level10_gms` P18): 3 of 7 lookup variants DENIED in
a guest against 7/7 GRANTED on the host. Downstream, the Google Maps SDK refused to construct
a `MapView` (`SecurityException: The Maps API requires ... INTERNET, ACCESS_NETWORK_STATE`),
and Level 6's runtime-permission probe reported `camera=false` even after the user granted it.
After running the script: 7/7 GRANTED, Maps completes end to end, Level 6 reports the grant.

The override maps the guest UID to the **host** UID — the UID the process genuinely runs
under — before the platform's check. It tells the platform the truth about who is asking and
changes only what an app is told about *its own* permissions. It does not affect what Play
services observes: the caller-identity refusals documented in
`docs/level10-gms-caller-identity-boundary.md` are unchanged, verified before and after.

**If you edit anything under `overrides/`, run `engine-patches/apply-runtime-overrides.sh`
and commit the resulting `bcore.aar`, or the change does not exist at runtime.**

## `overrides/…/BNotificationManager.java` — binder retry, and per-clone channel labels

Two things. The class re-fetches the notification service binder once from the registry
instead of dereferencing a cache the engine had cleared — a guest binding on Android 15 could
otherwise lose a channel read to a race between the health check and the call.

It also labels each clone's notification channel with its container number (`… · Clone 1`)
before the service creates it. That label is what makes per-clone muting usable: the engine
already gives every clone its own channel id (`<channel>@black-<userId>`, in
`IBNotificationManagerService.getBlackChannelId`), so muting one channel silences one clone —
but every clone of an app would otherwise show the guest's own channel name, so two clones of
Chrome both read "Browser" and the user cannot tell which row to turn off. The channel **id**
is deliberately untouched: it is the engine's key, and rewriting it here would break the
mapping the service depends on.

The label is applied when a guest creates its channel. Channels that already exist on a device
before this override is built keep their old name until the guest recreates them (Android
allows a name update on re-create; not every app re-calls `createNotificationChannel`).

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
