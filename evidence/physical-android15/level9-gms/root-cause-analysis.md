# Level 9 — root-cause analysis and failure classification

Classified before any fix, per Phase 2. No production virtualization code was changed to
produce any result here.

Confidence is stated for each finding using the four levels the investigation is held to:
**confirmed fact** (directly measured on the device), **strong evidence** (measured, with
one inference), **hypothesis**, **unknown**.

---

## Finding 1 — Play services is invisible to an unprovisioned guest, but only to some of the PackageManager

**Category A (package visibility) + Category B (PackageManager virtualization).**
**Confirmed fact.**

`getPackageInfo` and `getApplicationInfo` both throw `NameNotFoundException` for
`com.google.android.gms` inside a container, while `getApplicationEnabledSetting` returns
`0` for the same package in the same process, microseconds apart. `com.android.vending` is
visible to `getPackageInfo` at version **33.8.16-21** while the host has **53.0.27-34**,
and invisible to `getApplicationInfo`.

The diagnostic declares `<queries>` for all three packages, so Android 11 package filtering
is excluded as the explanation — the host control with the identical APK sees all three.

This is not "GMS is hidden". It is one virtualized PackageManager giving different answers
to different entry points for the same package, and synthesising a version number for one
of them that does not match the device. Any client library that cross-checks two of these
entry points gets an incoherent picture.

Evidence: `package-detection/release-guest-clone.log`,
`package-detection/debug-guest-clone.log`.

---

## Finding 2 — Intent resolution and Binder are NOT broken

**Categories C, D and E are ruled out.** **Confirmed fact.**

Inside the same unprovisioned container where Play services is invisible to
`getPackageInfo`:

- all five probed public GMS intent actions resolve, to real GMS components
  (`com.google.android.gms/.chimera.GmsApiService`,
  `.auth.api.proxy.AuthService`, `.measurement.service.MeasurementBrokerService`,
  `.gcm.PushMessagingRegistrarProxy`);
- `bindService` to `.chimera.GmsApiService` returns true and `onServiceConnected`
  delivers a live binder whose interface descriptor is
  `com.google.android.gms.common.internal.IGmsServiceBroker`.

A guest can therefore reach the host's genuine Play services over Binder today. The
blocker is above that layer, not at it. This is the single most useful result in Level 9,
because it removes the whole Binder/intent branch of the search.

Evidence: `service-resolution/release-guest-clone.log`, `binder/release-guest-clone.log`.

---

## Finding 3 — Test D's failure is a consequence of Finding 1, not an independent defect

**Category B, downstream.** **Strong evidence.**

`SettingsClient.checkLocationSettings` never produces a callback inside an unprovisioned
container (10 s timeout), and returns `API_NOT_CONNECTED(17)` inside a provisioned one.
Both are the client library refusing to proceed after its own availability check failed,
which is the check measured directly in Test B. The Binder path it would have used is
proven working by Finding 2.

The one inference: the client library's internals were not instrumented, so this is read
from its documented behaviour plus the Test B result rather than from inside the library.

---

## Finding 4 — `SERVICE_INVALID` is not a certificate problem

**Category J (virtualization architecture limitation).** **Confirmed fact that the
previously recorded cause is wrong; strong evidence for the replacement.**

`docs/PHASE_4_COMPATIBILITY.md` records that provisioning stops at `SERVICE_INVALID`
because "the container would have to present the signing certificate of the real Google
Play services". That is measured here and it is **not what happens**.

Inside the provisioned container the guest's PackageManager reports, for
`com.google.android.gms`:

- versionCode `263234035` — identical to the host;
- signing certificate history sha256 `f0fd6c5b…`, `7ce83c1b…`, `5f239127…` — **byte-identical
  to the host control**.

So the container does present the genuine Google certificate, and availability still
returns `SERVICE_INVALID(9)`.

What the logs show instead is that provisioning makes the container run **its own copy of
Play services as a guest process**, and that copy cannot bootstrap:

```
ChimeraCfgMgr: Failed to read module config: java.io.FileNotFoundException:
  /data/data/co.tdevs.duplika/blackbox/data/user_de/3/com.google.android.gms/app_chimera/current_config.fb
GmsProxy: Failed to get gms service binder
```

Play services is a Chimera module container: its real implementation lives in dynamically
loaded modules resolved from its own data directory. A container copy starts with an empty
`app_chimera` state, so the module set has to be recomputed inside the container, and the
engine's own `GmsProxy` cannot obtain a service binder for it.

The inference (hence "strong evidence" rather than "confirmed fact"): the exact internal
check inside `GoogleApiAvailability` that returns `9` was not instrumented. What is
confirmed is that the certificate and version are correct and that the container's Play
services instance is failing to initialise its module container.

Evidence: `package-detection/guest-provisioned-package-and-signature.log`,
`binder/provisioned-gms-guest-process.log`,
`controlled-diagnostic/release-provisioned/guest-clone-gms-provisioned.log`.

---

## Finding 5 — the guest's own ContentProvider and class-loading layers are healthy

**No category — this is a pass.** **Confirmed fact.**

Test E separates four layers that all present as "Firebase does not work":

| Layer | Unprovisioned guest | Provisioned guest |
| --- | --- | --- |
| E1 class loading of six Google/Firebase classes | PASS | PASS |
| E2 `FirebaseInitProvider` registered and resolvable | PASS | PASS |
| E3 configuration (no `google-services.json`, by design) | not initialised, as on the host | same |
| E4 Play services discovery | FAIL | PASS |

A third-party library's auto-installed ContentProvider registers and resolves correctly
inside a container, and its classes load. So "Firebase is broken in a clone" reduces
entirely to E4, which is Finding 1.

---

## Categories not observed

| Category | Status |
| --- | --- |
| C — intent resolution | **Not a cause.** All probed actions resolve (Finding 2). |
| D — service binding | **Not a cause.** Bind succeeds with a live binder (Finding 2). |
| E — Binder communication | **Not a cause.** Same. |
| F — guest/host UID mapping | Not implicated. The guest runs under host uid 10001 and Binder works from it. |
| G — permission | Not observed. No `SecurityException` was thrown anywhere in Level 9. |
| H — signature/security restriction | **Ruled out for the provisioned case** (Finding 4). |
| I — Google account / authentication | Not reached. No test required an account, and none failed for wanting one. |
| K — unknown | The specific internal check returning `SERVICE_INVALID(9)`. |

---

## What this does and does not license

The two changes that would follow from this analysis are **not** implemented, and are
recorded here as options for the project owner rather than as work in progress:

1. **Making the virtualized PackageManager answer consistently** for packages it already
   lets through at the Binder layer. This is a general correctness fix — the same
   inconsistency (visible to one entry point, invisible to another, stale version on a
   third) would affect any host package a guest legitimately queries, not just Google's.
   `engine-patches/deferred/0002-gms-passthrough-to-host.patch` is one existing
   implementation of this, via the engine's own `isOpenPackage()` whitelist.

2. **Not provisioning a container copy of Play services.** Finding 4 shows the copy cannot
   initialise its Chimera module container, so the feature currently moves the failure
   rather than fixing it, at the cost of ~10 s per clone and a heavier container.

Neither is a security bypass and neither is proposed as one: Finding 2 shows the host's
genuine, Google-signed Play services is already reachable over Binder from a guest today.
Nothing here spoofs an identity, forges a signature, or defeats a check — and Play
Integrity would still correctly fail for a virtualized caller, which is the right outcome
and is not something this investigation attempts to change.

Applying either change is a Phase 7 decision and requires the owner's explicit
authorisation, because it enables Google-account applications to run inside a cloned
environment. That is the same decision already flagged in
`engine-patches/deferred/README.md`.
