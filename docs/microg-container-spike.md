# microG in a Duplika container — spike result

Status: **SPIKE — measured on an emulator, not a shipped feature.** Lives on branch
`spike/microg-container`, not merged. It **supersedes** the conclusion in
`docs/microg-integration.md` (which said the path is blocked by signature verification); the
measurement below contradicts that and, after two small engine fixes, obtained a real FCM
token for a cloned app.

## Result

A cloned Cabex FX (`com.moneyin.cabex.fx`) inside a Duplika container, with official microG
provisioned as its `com.google.android.gms`, **registered with Google's FCM backend and
persisted an FCM token**:

```
D GmsHttpFormClient: token=c-woxbNvQSeX4EYZpsOT9w:APA91bGhJOte3AbUoSCOMoPhXl8oUcIP1mQvZ2keyhzZeGIb9l6aswufmG1z8c1Os2Ht1fTrmE0YNwmcyu4se43nyJQDrZtfIOFhOnTFYSkVCKUzFVFUhGY
W GmsGcmRegister: completeRegisterRequest error: null        # null == no error
```

and the app stored it under its own data
(`.../com.moneyin.cabex.fx/shared_prefs/com.google.android.gms.appid.xml`,
sender `876317137724` = Cabex FX's Firebase project). Evidence:
`evidence/emulator-api35/microg-container-spike/fcm-success.txt` and
`.../logcat-excerpts.txt`.

## What was done

An adb-driven spike installed official microG into an existing container and launched a
Firebase-dependent app:

| Piece | Where |
| --- | --- |
| microG GmsCore `com.google.android.gms` v0.3.16.252432 (official, NOGAPPS-signed, Apache-2.0) | pushed to the app's internal `files/microg/` |
| microG Companion `com.android.vending` (FakeStore) | same |
| Spike trigger | `native/spike/MicroGSpike.kt`, `MicroGSpikeActivity.kt`, `MicroGSpikeReceiver.kt` (debug-only; `am start … --es op {clone,install,launch,cleardata,status}`) |

`AppSecurityChecker` is bypassed only by the spike driving the engine's install path directly;
it is a host-layer pre-check, not an engine constraint. No production flow was changed.

## Why it works — three findings

### 1. Signature verification is not the wall

The earlier spike concluded that `GoogleSignatureVerifier.isGooglePublicSignedPackage` rejects
an honestly-signed microG. That is true only for a *normally installed* microG. In a container
it does not apply, because the engine already answers with the **host package's** certificate:

`PackageManagerCompat.generatePackageInfo(...)`:

```java
PackageInfo base = BlackBoxCore.getContext().getPackageManager().getPackageInfo(p.packageName, flags);
...
if ((flags & PackageManager.GET_SIGNATURES) != 0)
    pi.signatures = (base == null) ? p.mSignatures : base.signatures;   // host's when names collide
if (BuildCompat.isPie() && (flags & PackageManager.GET_SIGNING_CERTIFICATES) != 0)
    pi.signingInfo = (base == null) ? <container details> : base.signingInfo;
```

For a container package named `com.google.android.gms`, the host also has it, so the guest is
handed Google's genuine certificate for microG — no spoofing code. This is why Duplika does
not need Parallel Space's `FAKE_PACKAGE_SIGNATURE` + `libsigner.so` trick (see below). No
signature rejection appeared in the guest logs.

### 2. microG's providers were invisible in the container — engine fix A

microG stores its configuration behind content providers
(`com.google.android.gms.microg.settings`, `.profile`). The engine's
`IActivityManagerProxy.GetContentProvider` routed **any** authority whose name *contains*
`com.google.android.gms` straight to the host, which does not define microG's authorities:

```
E ActivityThread: Failed to find provider info for com.google.android.gms.microg.settings
```

Fix: `engine-patches/overrides/…/IActivityManagerProxy$GetContentProvider.java` resolves
Google-service authorities **container-first**, falling back to the host only when the
container has no provider. Non-Google host authorities (`settings`, `media`, `telephony`, OEM
launcher settings) are untouched. Measured after the fix:
`authority=com.google.android.gms.microg.settings containerProvider=true`.

### 3. Framework attribution-source UID mismatch — engine fix B

With the provider visible, the framework still rejected the call:

```
W ContentProviderStub: UID mismatch … Calling uid: 10002 doesn't match source uid: 10257
```

(10002 = the guest's virtual uid, 10257 = the host uid the engine's
`AttributionSourceUtils` writes into the source.) The engine's `ContentProviderStub` turns
this into a safe default — `null` for `query` — so microG read "Checkin disabled".
Fix: `engine-patches/overrides/…/context/providers/ContentProviderStub.java` retries the call
once with the attribution source's uid rewritten to the *calling* uid the framework named.
Measured: `UID mismatch; retrying query with source uid 10002`, then no null cursor.

### Checkin and push then completed

Enabling microG's checkin (`checkin_enable_service`) produced a successful Google checkin
(`androidId`, `securityToken`, `lastCheckin` in `checkin.xml`), after which
`PushRegisterService` registered and received the FCM token above.

### Push *delivery* — works on the emulator, blocked by the OEM on OnePlus

Registration is not delivery. Sending an actual message with the app's own service account
(Firebase HTTP v1) is accepted by Google every time — a valid token returns a message name,
an unregistered one returns `UNREGISTERED`.

**The missing piece was microG's MCS receive connection.** microG only opens it (to
`mtalk.google.com:5228`) when something starts its MCS service. `RealVirtualizationEngine
.launchProfile` now does exactly that on every successful clone launch
(`MicroGProvider.wakeReceiveChannel` → `org.microg.gms.gcm.McsService` with
`org.microg.gms.gcm.mcs.CONNECT`), because the connection dies with the guest process.

Measured on the emulator (Android 15): MCS `Logged in`, and a message sent from the app's
project was delivered in real time —
`GmsGcmMcsInput: Incoming message: DataMessageStanza{… title=Final product test …}` →
`Deliver message to all receivers in package com.digibank.mobile`, with the notification in
the shade. Evidence: `evidence/emulator-api35/microg-container-spike/push-delivery-success.txt`.

**On the OnePlus CPH2605 it still fails at first**, for an OEM reason recorded in
`evidence/physical-oneplus-cph2605/microg-push-delivery/limitation.txt`: the container's
microG process is SIGKILLed by the OEM's process manager (`exited due to signal 9`), so the
MCS connection does not survive long enough to receive. Two bounded reconnect mechanisms were
added for this: `CloneKeepAliveService` re-wakes the MCS every 30 s while a clone is open,
and `ClonePushRefreshWorker` (WorkManager, ≥15 min) does the same while nothing is open — FCM
stores undelivered messages, so they arrive in a batch at the next reconnect rather than
instantly. These are recorded in `docs/SECURITY.md`; on this OEM even the reconnect may be
deferred by the system's background restrictions. The engine daemon
(`isEnableDaemonService=true`) stretched survival from ~30 s to ~70 s but did not fix
delivery; it was tried on a branch and reverted, because it contradicts `docs/SECURITY.md`.
The host's own `CloneKeepAliveService` does not help either — it protects the host process,
and the OEM kills the guest microG process separately.

**Status:** push registration works everywhere; push delivery works on a device that does not
kill the container's microG process (emulator verified) and is unreliable on aggressive OEM
builds. In-app notifications are unaffected.

**Checkin is warmed during provisioning.** microG only checks in when something asks it to,
and the push registration that does ask has a 10 s timeout — so on a fresh container the
first launch used to fail registration once (`No checkin available` →
`SERVICE_NOT_AVAILABLE`) and the app had to be reopened. `MicroGProvider` now starts
`org.microg.gms.checkin.CheckinService` in the container right after provisioning
(`VirtualizationEngineAdapter.startContainerService`), while the user is still in the clone
flow. Measured on the OnePlus CPH2605: checkin completed ~7 s after provisioning, and the
**first** launch of the clone obtained its FCM token with no relaunch.

## The provider layer and the bundle

The artefact is now bundled and provisioned through the real layer, not installed by hand:

- `android/app/src/main/assets/microg/com.google.android.gms.apk` — official microG GmsCore
  v0.3.16.252432, ABI-trimmed to arm64 (108 MB → 37 MB) and re-signed only because the trim
  requires it (Apache-2.0; attribution goes in `NOTICE`).
- `native/gms/MicroGArtifactSource.kt` — the asset seam.
- `native/gms/MicroGProvider.kt` — real detection, `CONTAINER_GMS_PROVISIONING` when bundled,
  materialise + install via the engine, then `MicroGCheckinSeeder`.
- `native/gms/MicroGCheckinSeeder.kt` — writes microG's `checkin_enable_service` and
  `gcm_enable_mcs_service` before first launch (both default to off).
- `RealVirtualizationEngine.provisionMicroG(profileId)` and the `provisionMicroG` bridge
  method — the entry points.

Reproduce with the bundled artefact:

```bash
flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n co.tdevs.duplika/.native.spike.MicroGSpikeActivity --es op clone --es profileId spike-mg --es package com.moneyin.cabex.fx
adb shell am start -n co.tdevs.duplika/.native.spike.MicroGSpikeActivity --es op install --es profileId spike-mg
adb shell am start -n co.tdevs.duplika/.native.spike.MicroGSpikeActivity --es op launch --es profileId spike-mg --es package com.moneyin.cabex.fx
# provisioning warms microG's checkin, so the first launch registers immediately
```

`docs/microg-container-spike.md` and
`evidence/emulator-api35/microg-container-spike/provider-layer-success.txt` record the
provider-layer result.

## What Parallel Space does (for comparison)

Confirmed by pulling the installed APK (`com.lbe.parallel.intl`):

- Bundles microG GmsCore as `assets/mgs/mgs.so` (27 MB APK; package
  `com.google.android.gms`, re-signed with LBE's own `CN=lbesec` cert).
- Ships `lib/libsigner.so` and `Lcom/lbe/doubleagent/b0;` carrying
  `android.permission.FAKE_PACKAGE_SIGNATURE` and `"fake-signature"` — i.e. signature spoofing.

Duplika does not need that trick (finding 1) and the two fixes above are provider plumbing,
not identity or signature manipulation.

## Security and policy notes

- The spike bypassed `AppSecurityChecker`, which correctly refuses microG because its package
  name resolves to the host's real Play services declaring `REQUIRE_SECURE_ENV`. Nothing in
  production was changed; the bundle is on a spike branch.
- Neither fix spoofs identity, UID or signature, and nothing touches Play Integrity. Fix B
  rewrites an attribution-source uid only on a retry, after the framework has named it.
- If this ever ships: microG is Apache-2.0 (attribution notice needed); Play policy on
  shipping a Google-services reimplementation, and the caller-identity ceiling in
  `docs/level10-gms-caller-identity-boundary.md`, remain open. Play Integrity / SafetyNet
  would still fail for a virtualized caller.

## Open items

1. **Regression coverage of the two engine overrides is partial.** A normal clone
   (`com.example.duplikabaseline`) launched with its provider working and no provider errors,
   which exercises both fixes. The Android `connectedDebugAndroidTest` suite cannot currently
   run green in this repo because it expects `com.example.virtualtestapp`
   (`TestAppManager.TEST_APP_PACKAGE`) and `baseline_test_app` builds
   `com.example.duplikabaseline` — a pre-existing mismatch, not a regression from these
   changes. Wiring the suite to the current test app (or bundling the expected one) is worth
   doing before this leaves the spike branch.
2. **Attribution and packaging.** The bundled microG needs its Apache-2.0 attribution in the
   repository `NOTICE`. For a real build, consider per-ABI splits rather than the trimmed
   universal artefact.
3. **Checkin is seeded, not user-configurable.** `MicroGCheckinSeeder` writes microG's
   prefs directly. If microG's own settings UI is ever exposed, the two should not fight.
4. **Push delivery is measured** (see "Push *delivery*" above). It works on the emulator —
   `launchProfile` opens microG's MCS connection and a message sent from the app's project
   arrives in real time — and remains blocked on an OnePlus CPH2605 because the OEM SIGKILLs
   the container's microG process. Closing that gap needs engine/OS-level work (keeping the
   guest process alive), not app logic.

## Bottom line

The microG path is **not blocked by signatures** and **push registration is demonstrated on an
emulator and on a physical device**: a cloned Firebase app in a Duplika container obtained a
real FCM token on its first launch. The work that got there was two small, identity-neutral
engine provider fixes plus microG's own checkin configuration and warm-up — not signature
spoofing.

**Push *delivery* is measured too.** `launchProfile` now opens microG's MCS receive
connection on every clone launch, and on the emulator a message sent from the app's own
Firebase project is delivered in real time and shown as a notification. On an aggressive OEM
build (OnePlus CPH2605) the same attempt still fails because the OEM SIGKILLs the container's
microG process; that is an engine/OS-level limitation, not app logic. What remains is
regression testing, packaging, that OEM gap, and the product/policy decision.
