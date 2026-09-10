# Level 10 — the GMS caller-identity boundary (root cause CONFIRMED)

Status: **CONFIRMED — UNSUPPORTED / SECURITY BOUNDARY.**

The boundary itself is unchanged and unfixable by design. One production change was made in
the later compatibility-expansion phase, and it is deliberately unrelated to the boundary:
`android/app/libs/bcore.aar` was rebuilt so that the repository's own, previously
uncompiled, `checkPermissionForDevice` override is actually present (§6a). It changes what a
guest app is told about **its own** permissions and nothing about what Play services
observes.

This document closes the question left open as "Finding 4 — UNKNOWN" in
`evidence/physical-android15/level10-gms/root-cause-analysis.md` and as "root cause
UNKNOWN" in `docs/level10-location-services-investigation.md`. It also **corrects** a
finding those documents recorded as strong evidence.

Device: Android 15 emulator, AVD `Pixel_9`, API 35, `arm64-v8a`, Play services **26.33.32**
(`263332035`), Play Store 53.0.27-34. Same APK in every cell.
Evidence: `evidence/emulator-pixel9-api35/level10-gms/`.

---

## 1. The answer

A guest app's `GoogleApi` client **does** bind Play services and **does** call
`IGmsServiceBroker.getService(...)`. Play services answers by throwing:

```
java.lang.SecurityException: Unknown calling package name 'com.example.duplikaladder.level10gms'.
    at android.os.Parcel.createExceptionOrNull(Parcel.java:3242)
    at android.os.Parcel.createException(Parcel.java:3226)
    at android.os.Parcel.readException(Parcel.java:3209)
    at com.google.android.gms.common.internal.zzad.getService(play-services-basement@@18.3.0:9)
    at com.google.android.gms.common.internal.BaseGmsClient.getRemoteService(play-services-basement@@18.3.0:14)
    at com.google.android.gms.common.api.internal.zabt.run(play-services-base@@18.4.0:7)
```

The client library catches it, logs `GoogleApiManager: Failed to get service from broker`,
and converts it into `ConnectionResult{statusCode=DEVELOPER_ERROR}` — which surfaces to the
app as `ApiException 17: API: <X>.API is not available on this device`.

**The refusal is Play services declining to attribute a caller-scoped request to a package
that does not belong to the Binder calling UID.** In a container the guest process runs
under Duplika's UID, and `com.example.duplikaladder.level10gms` genuinely is not installed
under that UID as far as the platform is concerned. Play services is not malfunctioning and
Duplika is not answering anything incorrectly: both are behaving correctly, and the
requirement is simply one a container cannot satisfy.

Paired control, same device, same APK, same run sequence:

| | Host | Guest |
| --- | --- | --- |
| `GoogleApiManager` log lines | **0** | 15-16 |
| `Unknown calling package name` | **0** | 15-16 |

`evidence/emulator-pixel9-api35/level10-gms/root-cause/`.

## 2. What this corrects

Two prior conclusions do not survive.

**Corrected — "the decision is client-side and pre-IPC" (was: STRONG EVIDENCE).** It is
not. `Parcel.createException` only ever appears when an exception is unparceled from
*another process*, so the round trip demonstrably happened. The two observations that
grounded the old reading were both real but did not imply it:

- *"Fails in 1-20 ms."* A rejected Binder call is fast. Speed distinguishes nothing.
- *"No bind in `BoundBrokerSvc`."* That log records new bindings. It does not record a
  `getService` transaction on a connection, so a refusal at `getService` is invisible to
  it. In the emulator capture Play services **does** log guest binds
  (`appset.service.START`, `SmsRetrieverApiService.START`, `common.service.START`).

**Confirmed — hypothesis 9** (`docs/level10-location-services-investigation.md` §11), which
stood at "LIKELY, NOT CONFIRMED". The objection recorded against it was that AppSet ID
succeeds with the identical UID/package mismatch present, so mismatch alone is not
sufficient. That objection was correct and is now explained rather than dismissed: the
mismatch is only *consulted* for caller-scoped requests. APIs that need no caller
attribution never trigger the check, which is exactly the observed split.

## 3. How the field was cleared

Every category in the phase brief's Step 7 list was measured, not assumed. New probes are
in `compatibility_test_ladder/level10_gms`.

| # | Category | Status | Measured by |
| --- | --- | --- | --- |
| A | Missing service virtualization | **EXCLUDED** | P10 — the services behind the failing APIs bind from the guest and return a real `IGmsServiceBroker` |
| B | Missing provider virtualization | **EXCLUDED** | P9 — phenotype, chimera-modules and settings/broker providers all acquire in the guest; the Chimera component router is refused on the **host too** (`exported=false`), so it is not a difference |
| C | Missing Binder forwarding | **EXCLUDED** | P10 — `bindService=true`, `onServiceConnected=true`, real binder interface |
| D | Incorrect service registration | **EXCLUDED** | P9 — identical components and meta-data key counts, host vs guest |
| E | Missing package visibility | **EXCLUDED** | P0/P9 — identical GMS version, uid, sourceDir, signing digests, `com.google.android.gms.version` |
| F | Incorrect permission handling | **EXCLUDED** | Phase 8 grant experiment; P7 held permission state constant while the outcome flipped |
| G | Incorrect application context | **EXCLUDED** | P11 — see below |
| H | **Genuine GMS security restriction from guest/host identity** | **CONFIRMED** | the `getService` `SecurityException` above |
| I | Unsupported by the architecture | follows from H | — |

### P9 — the local-input differential

Host and guest differ on exactly four lines, and only two are substantive:

```
- caller.opPackageName = com.example.duplikaladder.level10gms
+ caller.opPackageName = co.tdevs.duplika
- gms.getPackagesForUid = [com.google.android.gms, com.google.android.gsf]
+ gms.getPackagesForUid = [com.example.duplikaladder.level10gms]
```

(the other two are the expected UID difference, and the Chimera router provider, which is
refused in both columns). Signing certificates, `checkSignatures`, GMS metadata, service
resolution and provider acquisition are **identical**.

### P11 — and why the surviving candidate was rejected

`getOpPackageName()` returning the *container host's* package looked like the answer: it is
an attribution value, and the failing set is exactly the attribution-sensitive APIs. It was
tested rather than assumed. Handing the clients a `ContextWrapper` whose only difference is
that `getOpPackageName()` returns the app's own real package changed **nothing** — both APIs
still `DEVELOPER_ERROR`. On the host the same wrapper is inert, which is what makes the
guest result meaningful. **REJECTED.**

That negative result matters: it is what forced the search past locally-readable data and on
to capturing the remote exception.

## 4. What works, and what the boundary covers

### Legitimately supported in a guest — measured, host and guest, Debug and Release

| Capability | Guest | Caller-scoped | Note |
| --- | --- | --- | --- |
| `isGooglePlayServicesAvailable` | PASS `SUCCESS(0)` | no | |
| Package metadata coherence | PASS | no | |
| GoogleApi client framework | PASS | no | via AppSet ID |
| Advertising ID (direct AIDL) | PASS | no | |
| App Set ID | PASS | no | |
| **Chimera / Dynamite module loading** | **PASS** | no | Play services serves module code into the guest process; gates Maps, ML Kit, Cast |
| **Play services security provider** | **PASS** | no | `ProviderInstaller.installIfNeeded`; `GmsCore_OpenSSL` visibly installed |
| **Google Maps SDK** | **PASS** | no | SDK init, MapView, GoogleMap, camera op — after the permission fix below |
| Firebase initialization (`firebase-common`) | PASS | no | Level 9 Test E; Firebase *Messaging* is not a dependency and is NOT TESTED |

### Scope of the boundary

Measured on Pixel 9 / API 35, Debug and minified Release, both columns:

| API | Artifact | Caller-scoped | Host | Guest |
| --- | --- | --- | --- | --- |
| Advertising ID | ads-identifier (direct AIDL) | no | PASS | **PASS** |
| AppSet ID | appset (GoogleApi) | no | PASS | **PASS** |
| LocationServices | play-services-location | yes (permission) | PASS | FAIL |
| ActivityRecognition | play-services-location | yes (permission) | PASS | FAIL |
| SmsRetriever | auth-api-phone | yes (signature) | PASS | FAIL |
| **Google Sign-In** | play-services-auth | yes (account) | PASS | FAIL |

Google Sign-In is new here (P12) and is worth stating precisely: it is refused **at
connection time, with the same `DEVELOPER_ERROR`**, before any authentication question is
posed. Sign-in has been classified UNSUPPORTED since Level 10 Phase 5, but by reasoning
about accounts. It is now measured, and the reason turns out to be the ordinary
caller-identity boundary rather than anything account-specific. No sign-in, silent sign-in,
token request or `GoogleAuthUtil` call was made — only `checkApiAvailability`.

## 5. Why there is nothing to fix

Making these APIs work would require Play services to accept
`com.example.duplikaladder.level10gms` as belonging to Duplika's UID. Every route to that is
on the project's forbidden list:

| Route | Forbidden by |
| --- | --- |
| Make the platform report the guest package under Duplika's UID | rule 3 (package identity spoofing), rule 4 (UID spoofing to fool Google services) |
| Send a package name the container does not own | rule 3 |
| Intercept and answer `getService` inside the container | rule 1 (security bypass), rule 7 (fake Google authentication) |
| Give the guest its own real UID | not possible in this architecture; that is what a container is |

The distinguishing test set in
`docs/level10-location-services-investigation.md` §13 was: *is Duplika giving a wrong answer
about the real host GMS installation (fixable, like the Level 9 fix), or is the input an
identity assertion (unsupported)?* P9 answers it directly — every value Duplika reports
about the GMS installation is identical to the host's. Duplika is not giving a wrong answer.
The refusal is an identity assertion the container legitimately cannot make.

**Classification: UNSUPPORTED / SECURITY BOUNDARY. This must not be "fixed".**

## 6a. A legitimately fixable defect, found and fixed (permission lookup)

The compatibility-expansion phase found a defect that is **not** this boundary and is
squarely fixable. It is recorded here because it was initially easy to mistake for one.

The Maps SDK refused to construct a `MapView` in a guest:

```
SecurityException: The Maps API requires the additional following permissions ...
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
  <uses-permission android:name="android.permission.INTERNET"/>
```

The fixture declares both, and the identical APK passed on the host. Two probes separated
the cause:

- **P17** — `getPackageInfo(self, GET_PERMISSIONS)` returns all five declared permissions in
  a guest, identically to the host. The obvious explanation was **wrong**.
- **P18** — asked the same question seven ways. The split was exact:

  | Lookup family | Host | Guest (before) |
  | --- | --- | --- |
  | `Context.checkSelfPermission` / `checkCallingOrSelfPermission` / `checkPermission(pid,uid)` | GRANTED | **DENIED** |
  | `PackageManager.checkPermission(perm, package)` / `getPackageInfo` | GRANTED | GRANTED |

The `Context` family resolves by **pid/uid**. A guest runs with a virtual UID, so the call
reached the real platform with a UID it does not know, and the platform correctly answered
DENIED. Nothing about Google, nothing about identity assertion: the app was asking about
itself and getting a wrong answer.

**The fix was already written in this repository and had never been compiled into the
shipped binary.** `engine-patches/overrides/…/IActivityManagerProxy$checkPermission.java`
adds a `checkPermissionForDevice` hook that maps the guest UID to the host UID before the
platform check — the Android 15 path that `Context.checkSelfPermission` now takes. The
shipped `bcore.aar` registered only the older `checkPermission` method. Running
`engine-patches/apply-runtime-overrides.sh` installed it.

After the fix, in a guest: all seven lookups GRANTED, the Maps SDK completes all four
stages, and Level 6's runtime-permission probe reports `notification=true camera=true`
where it previously stayed `false` after the user granted.

**Why this is not identity spoofing.** The UID mapping is guest→**host**, i.e. to the UID
the process genuinely runs under. It tells the platform the truth about who is asking, and
it changes only what *this app* is told about *its own* permissions. It does not touch what
Play services observes: the caller-identity refusals are unchanged (28-29 per run, before
and after), and every caller-scoped API still fails exactly as documented above.

## 6b. Legitimately fixable, and deliberately not fixed here

P9 did find one value that is objectively wrong, unrelated to this boundary:

```
guest: pm.getPackagesForUid(<GMS's uid 10144>) = [com.example.duplikaladder.level10gms]
host : pm.getPackagesForUid(<GMS's uid 10144>) = [com.google.android.gms, com.google.android.gsf]
```

The virtualized PackageManager answers `getPackagesForUid` with the guest's own package
regardless of the UID asked about. That is a wrong answer about another package, of the same
shape as the Level 9 package-visibility defect, and correcting it would involve no identity
assertion — it would report the host's true mapping for a UID the caller did not claim.

**TODO (open, deliberately deferred):** *correct `getPackagesForUid` virtualization when a
real guest caller path demonstrates dependency on it.*

It is **not** fixed, for the reason the project's own rules require: it is not
the cause of any measured failure. P11 and the confirmed root cause show the GMS path does
not depend on it. Changing engine behaviour to correct a value nothing is known to read
would be exactly the speculative patch the brief forbids. It is recorded here so a future
phase that finds a caller which *does* read it has the measurement already.

## 6c. Play Billing — an open question, not a classified boundary

The Play Store refuses a billing connection from a guest:
`responseCode=3 BILLING_UNAVAILABLE, "Google Play In-app Billing API version is less than 3"`,
against `OK` on the host, in both Debug and Release. Connection only was tested; no purchase
flow exists in the fixture.

This is **not** classified. It is a different host app (`com.android.vending`), a different
Binder path, and the message is about an API version rather than a caller identity, so
assuming it is the same boundary would be exactly the inference this project keeps having to
undo. It is recorded as the strongest open lead for a future phase.

## 7. Play Integrity and Firebase

- **Play Integrity — NOT TESTED, by design.** Not a dependency of Duplika or the fixture.
  A virtualized caller should fail attestation; that is the correct outcome and is not
  targeted. A real token request additionally needs a Cloud project number the fixture does
  not carry and must not fabricate. P12 records only that the API is absent from the
  classpath.
- **Firebase — NOT APPLICABLE.** Firebase is not a dependency anywhere in Duplika
  (`pubspec.yaml`, Gradle, or the fixture), so there is no host/guest token to compare.

## 8. Reproduction

1. Build and install `compatibility_test_ladder/level10_gms` (Debug or Release) on the host;
   `am start` it. It self-runs.
2. Clone the same package through Duplika's ordinary flow and launch the clone.
3. `adb logcat -v threadtime "*:V" | grep -E "GoogleApiManager|Unknown calling package"`.

Host: zero matches. Guest: the `SecurityException` above, once per caller-scoped API.
