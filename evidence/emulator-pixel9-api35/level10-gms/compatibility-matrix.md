# GMS capability matrix — Pixel 9 / Android 15 / API 35 emulator

Every cell below was measured on this device in this phase. Nothing is inferred; anything
not run says **NOT TESTED**.

Device: AVD `Pixel_9`, `ro.build.version.sdk=35`, `ro.build.version.release=15`,
`ro.product.cpu.abi=arm64-v8a`, `ro.product.model=sdk_gphone64_arm64` (the generic emulator
model string — the AVD device profile is Pixel 9).
Play services **26.33.32** (`263332035`), Play Store 53.0.27-34.
Fixture: `compatibility_test_ladder/level10_gms`, identical APK in host and guest columns,
Debug and minified Release both run. Clones created through Duplika's ordinary flow;
`GMS_PROVIDER requestedProvider=AUTO selectedProvider=REAL_GMS availability=AVAILABLE`.

## Matrix

| API | Host | Guest | Current result | Failure reason | Fixable? |
| --- | --- | --- | --- | --- | --- |
| GMS availability (`isGooglePlayServicesAvailable`) | PASS `SUCCESS(0)` | PASS `SUCCESS(0)` | works | — | n/a |
| Package metadata coherence (P0) | PASS | PASS | works | — | n/a |
| GoogleApi framework (AppSet ID, P2) | PASS | PASS | works | — | n/a |
| Advertising ID (direct AIDL, P1) | PASS | PASS | works | — | n/a |
| App Set ID | PASS | PASS | works | — | n/a |
| LocationServices (`SettingsClient`, P3) | PASS | **FAIL** | `ApiException 17` / `DEVELOPER_ERROR` | Play services: `SecurityException: Unknown calling package name` from `IGmsServiceBroker.getService` | **No — security boundary** |
| ActivityRecognition (P7) | PASS | **FAIL** | same | same | **No — security boundary** |
| SmsRetriever (P8) | PASS | **FAIL** | same | same | **No — security boundary** |
| Google Sign-In (availability only, P12) | PASS `available` | **FAIL** | same, at connection time before any authentication | same | **No — security boundary** |
| Play Integrity | NOT TESTED | NOT TESTED | — | not a dependency; a virtualized caller should fail attestation and it is not targeted | Not targeted |
| Firebase Messaging | NOT APPLICABLE | NOT APPLICABLE | — | Firebase is not a dependency of Duplika or the fixture | n/a |
| Direct service bind to the failing APIs' services (P10) | PASS | **PASS** | binds, real `IGmsServiceBroker` | — | n/a — this is what excludes a transport cause |
| Container isolation (`getInstalledPackages`) | 88 | **1** | intact | — | n/a |

## Debug / Release parity

Every guest cell above was measured in both Debug and minified Release and agrees. R8 is not
a factor.

| Column | P3 | P7 | P8 | P12 |
| --- | --- | --- | --- | --- |
| Host Debug | PASS | PASS | PASS | PASS |
| Host Release | PASS | PASS | PASS | PASS |
| Guest Debug | FAIL | FAIL | FAIL | FAIL |
| Guest Release | FAIL | FAIL | FAIL | FAIL |

## Root cause

Confirmed, with the exception captured from the guest process:

```
GoogleApiManager: Failed to get service from broker.
java.lang.SecurityException: Unknown calling package name 'com.example.duplikaladder.level10gms'.
    at android.os.Parcel.createExceptionOrNull(Parcel.java:3242)
    …
    at com.google.android.gms.common.internal.zzad.getService(play-services-basement@@18.3.0:9)
    at com.google.android.gms.common.internal.BaseGmsClient.getRemoteService(play-services-basement@@18.3.0:14)
```

Host control: **0** occurrences. Guest: 15-16 per run, one per caller-scoped API.

Full analysis: [`docs/level10-gms-caller-identity-boundary.md`](../../../docs/level10-gms-caller-identity-boundary.md).

## Files

| Path | What |
| --- | --- |
| `host/host-debug-report.txt` | full host Debug run |
| `host/host-release-full-report.txt` | full host Release run |
| `host/host-p9-local-inputs.txt` | host local-input differential |
| `host/host-p10-service-bind.txt` | host bind differential |
| `host/host-p11-attribution.txt` | host attribution control (wrapper inert) |
| `host/host-p12-capability.txt` | host sign-in / integrity capability |
| `guest/guest-debug-full-report.txt` | full guest Debug run |
| `guest/guest-release-full-report.txt` | full guest Release run |
| `guest/guest-p9-local-inputs.txt` | guest local-input differential |
| `guest/guest-p10-service-bind.txt` | guest bind differential — the exclusion of transport causes |
| `guest/guest-p11-attribution.txt` | guest attribution experiment — REJECTED |
| `guest/guest-p12-capability.txt` | guest sign-in refusal |
| `root-cause/guest-getservice-securityexception.txt` | **the confirming evidence** |
| `root-cause/guest-gms-side-binds.txt` | Play services' own record of the guest's binds |
| `root-cause/host-control-no-securityexception.txt` | paired host control |
