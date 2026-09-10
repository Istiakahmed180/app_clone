# Level 10 Phase 8 — LocationServices root-cause investigation

> **SUPERSEDED — the root cause is now CONFIRMED.** See
> [`level10-gms-caller-identity-boundary.md`](level10-gms-caller-identity-boundary.md).
>
> Hypothesis 9 (§11) is **confirmed**: Play services throws
> `SecurityException: Unknown calling package name '<guest package>'` from
> `IGmsServiceBroker.getService`, which the client library converts to `DEVELOPER_ERROR`.
> Classification is **UNSUPPORTED / SECURITY BOUNDARY** — §13's "if hypothesis 9 is ever
> confirmed" branch.
>
> One conclusion below is **wrong** and is kept for the record rather than edited away:
> §4/§12's "the refusal is a local, pre-IPC decision inside the client library". The call
> does reach Play services. `Parcel.createException` in the captured stack proves the
> exception was unparceled from another process. The two observations that supported the
> old reading (fast failure; no `BoundBrokerSvc` bind) are both consistent with a refused
> `getService` on an established connection.
>
> §19's recommended next step was carried out and is also superseded: the cross-API and
> cross-artifact probes (P7/P8) confirmed the pattern, and P9-P12 identified the mechanism.

Status: **PARTIAL** *(at the time of writing; now superseded — see above).* Two concrete
hypotheses were tested and **rejected** with device evidence. The boundary is substantially
narrowed but the root cause is **not confirmed**, so no code was changed.

## 1. Problem statement

Inside a Duplika container, `SettingsClient.checkLocationSettings` fails with
`ApiException 17` wrapping `ConnectionResult{statusCode=DEVELOPER_ERROR}` —
*"LocationServices.API is not available on this device"* — while the **identical APK**
installed normally on the same device succeeds. Other Google APIs work in the container.

## 2. Existing evidence reviewed

`docs/level10-gms-provider-{audit,architecture,migration}.md`,
`evidence/physical-android15/level10-gms/{compatibility-matrix,root-cause-analysis}.md`,
and the Phase 7 `provisioning-retirement/` set. Prior findings confirmed, not assumed:
availability `SUCCESS(0)`, direct-AIDL GMS works, the GoogleApi *framework* works (AppSet
ID), package metadata coherent, Debug and Release identical.

## 3. Reproduction steps

Device: OnePlus CPH2605, Android 15 / API 35 / arm64-v8a, `KNOJORMFV4GERKHM`.

1. Install `compatibility_test_ladder/level10_gms` release APK on the host; `am start` it →
   host control.
2. Clone the same package through Duplika's ordinary flow (provisioning off) → guest.
3. Launch the clone; read the report via the app's "DUMP FULL LOG TO LOGCAT" button.

Reproduced this phase on both variants: **guest Debug FAIL, guest Release FAIL, host Debug
PASS, host Release PASS.** Provider selection during every clone:
`GMS_PROVIDER requestedProvider=AUTO selectedProvider=REAL_GMS availability=AVAILABLE`.

## 4. Client-side call path

```
ProbeLocationSettings.run(context)
  LocationServices.getSettingsClient(context)        -> SettingsClient (a GoogleApi subclass)
  new LocationSettingsRequest.Builder()
        .addLocationRequest(new LocationRequest.Builder(10000).build()).build()
  client.checkLocationSettings(request)              -> Task<LocationSettingsResponse>
  Tasks.await(task, 10_000 ms)
        -> ApiException(17) / ConnectionResult{DEVELOPER_ERROR}
```

- API: `com.google.android.gms:play-services-location:21.3.0`
- Caller package: `com.example.duplikaladder.level10gms`
- Needs no Google account, no API key, **no runtime permission** — proven by the host
  control, which declares no location permission and passes.
- Failure timing: **~20 ms, with no bind at all** in Play services' `BoundBrokerSvc` log,
  whereas AppSet ID binds and answers in ~100 ms through the same framework. So the refusal
  is a **local, pre-IPC, per-API decision inside the client library**.

## 5. Host vs guest comparison

Full table in
`evidence/physical-android15/level10-gms/location-services-investigation/host-vs-guest-comparison.md`.

**The same APK is used in both columns**, so everything static about the app — manifest,
declared permissions, `targetSdk`, GMS library versions — is identical *by construction*
and logically cannot be the differentiator. That constraint drove the whole investigation.

| Measurement | Host | Guest |
| --- | --- | --- |
| `isGooglePlayServicesAvailable` | `0` SUCCESS | `0` SUCCESS |
| GMS versionName | 26.32.34 | identical |
| PackageManager coherence (P0) | PASS | PASS |
| GMS declared services visible | 370 | 370 |
| `…location.internal.GoogleLocationManagerService.START` | matches=1 | **matches=1, same component** |
| `auth.api.signin.service.START` / `common.service.START` | 1 / 1 | 1 / 1 |
| Direct-AIDL GMS (P1) | PASS | PASS |
| GoogleApi framework, AppSet (P2) | PASS | PASS |
| **LocationServices (P3)** | **PASS** | **FAIL `DEVELOPER_ERROR`** |
| `checkApiAvailability(LocationServices)` | `available` | `DEVELOPER_ERROR` |
| Device `location_mode` | 3 (on) | 3 (same device) |
| Caller uid GMS observes | the diagnostic's own uid | `co.tdevs.duplika` uid 10963 |

## 6. Permission analysis

The diagnostic declares only `INTERNET` and `ACCESS_NETWORK_STATE` — **no location
permission** — and passes on the host. So `checkLocationSettings` genuinely requires none.

Duplika itself **does** request `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`,
`ACCESS_LOCATION_EXTRA_COMMANDS`, `ACCESS_BACKGROUND_LOCATION`, `ACCESS_MEDIA_LOCATION`
(inherited from Bcore's merged manifest and deliberately *not* stripped — the manifest's own
comment explains that removing a permission the host declares would permanently deny that
capability to every clone). Only the `com.google.android.gms.permission.*` variants are
removed, as ungrantable noise.

At baseline these were `granted=false`, with appops `FINE_LOCATION: ignore`. That asymmetry
looked like the answer, so it was tested — see §11 Experiment 1. It is **not** the cause.

## 7. Location provider analysis

`settings get secure location_mode` = **3** (on). GPS, network, fused and passive providers
all present in `dumpsys location`. Same physical device for both columns, so provider state
is held constant and cannot explain a host/guest difference.

## 8. GMS analysis

Host GMS `26.32.34` (`versionCode 263234035`), the only GMS on the device; both columns talk
to it. Availability `SUCCESS(0)` in the guest. `RealGmsProvider` selected in every clone.
Provisioning retired in Phase 7, so no container-local GMS copy exists to shadow it.

## 9. Package / manifest analysis

| Property | Value |
| --- | --- |
| Package | `com.example.duplikaladder.level10gms` |
| `minSdk` / `targetSdk` | 23 / 35 |
| Permissions | `INTERNET`, `ACCESS_NETWORK_STATE` |
| `<queries>` | `com.google.android.gms`, `com.android.vending`, `com.google.android.gsf` |
| GMS libraries | base 18.5.0, ads-identifier 18.0.1, appset 16.0.2, **location 21.3.0**, auth 21.2.0 |

No missing legitimate configuration was found: the same configuration succeeds on the host.
A missing manifest declaration would fail in *both* columns.

## 10. Error / status details

```
ApiException statusCode=17
message: 17: API: LocationServices.API is not available on this device.
         Connection failed with: ConnectionResult{statusCode=DEVELOPER_ERROR,
         resolution=null, message=null}
checkApiAvailability(LocationServices/Settings)
  = AvailabilityException: None of the queried APIs are available.
    LocationServices.API: ConnectionResult{statusCode=DEVELOPER_ERROR}
```

Debug (`ApiException`) and Release (`com.google.android.gms.common.api.e`, the minified
name) are the same class — R8 is not a factor.

## 11. Hypothesis table

| # | Hypothesis | Evidence for | Evidence against | Status |
| --- | --- | --- | --- | --- |
| 1 | Host caller lacks granted location permission | Duplika declares them but `granted=false`; appops `ignore`; LocationServices is the only permission-gated API in the probe set | **Granted them via the Settings UI and re-ran: identical `DEVELOPER_ERROR`.** Also the host control declares *no* location permission and passes | **REJECTED** |
| 2 | Guest cannot resolve the LocationServices service component | The 0002 patch does not cover `queryIntentServices`/`resolveService`, so this was a live gap | **Guest resolves the real action `…GoogleLocationManagerService.START` with `matches=1` and the same component as the host.** The earlier "0 matches" was a wrong action name that also returned 0 on the host | **REJECTED** |
| 3 | Client-side API misuse / configuration (A) | — | Identical APK and identical call succeed on the host | **REJECTED** |
| 4 | Location provider disabled (C) | — | `location_mode=3`, same device both columns | **REJECTED** |
| 5 | Package metadata / visibility (E) | — | P0 PASS; 370 services; version and certs identical to host | **REJECTED** |
| 6 | GMS unavailable / wrong version (D) | — | `SUCCESS(0)`; single GMS 26.32.34 serving both | **REJECTED** |
| 7 | Binder/service transport (H) | — | Direct-AIDL (P1) and framework AppSet (P2) both work; and P3 never binds at all | **REJECTED** |
| 8 | Build/minification dependent | — | Guest fails in Debug *and* Release; host passes in both | **REJECTED** |
| 9 | Caller identity / package↔uid correspondence as the GMS process resolves it (F/G) | The only measured difference left. GMS observes `mCallingUid=10963` (`co.tdevs.duplika`) while the client names `com.example.duplikaladder.level10gms`; host PM does not associate that pair. Would explain a per-API refusal for an API whose access must be attributed | AppSet ID succeeds through the **same** framework with the **same** mismatch present, so mismatch alone is plainly not sufficient. No instrumentation of the client library's decision was achieved | **LIKELY, NOT CONFIRMED** |
| 10 | Per-API `Feature` / Chimera module metadata read locally by the client | Consistent with a ~20 ms no-bind refusal and with `checkApiAvailability` answering locally | Not measured — the probe cannot read GMS's per-API feature table | **UNKNOWN** |

## 12. Confirmed boundary

**Root cause remains UNKNOWN. The narrowed boundary is:**

> A **per-API, client-side, pre-IPC availability decision inside
> `play-services-location`** that refuses `LocationServices.API` for a containerised
> caller. It is not package visibility, not component resolution, not permissions, not
> provider state, not GMS version, not transport, and not R8 — each measured and rejected.
> The only remaining measured difference between the passing and failing runs is the caller
> identity the GMS process resolves over Binder, and that alone is demonstrably not
> sufficient (AppSet ID succeeds with the identical mismatch).

## 13. Security-boundary assessment

**Not yet classifiable, and deliberately not forced into a classification.**

If hypothesis 9 is ever confirmed — that the refusal turns on the calling package not
belonging to the calling UID from the GMS process's view — then it is
**UNSUPPORTED / SECURITY-BOUNDARY** and must not be "fixed": making it pass would require
caller-identity spoofing, which is on the project's forbidden list.

If hypothesis 10 is confirmed and the guest is giving a *wrong answer* about the real host
GMS installation, that would be an ordinary compatibility defect of the same shape as the
Level 9 package-visibility fix, and legitimately fixable.

**Distinguishing the two is the prerequisite for any code change.** Nothing in this phase
attempted or required a bypass: no UID, signature, certificate or package-identity spoofing,
no Play Integrity / SafetyNet interaction, no account or OAuth credential, no fake GMS
response.

One note on Experiment 1's method: granting Duplika a location permission it already
declares, through the system Settings UI, is an ordinary user action — not a bypass. The
grant was **reverted** afterwards and the device left as found (`granted=false`).

## 14. Root cause

**UNKNOWN.** See §12 for the narrowed boundary. Two plausible causes were tested and
rejected; the two survivors are not separable with the instrumentation available.

## 15. Fix

**None. No production code was changed**, per the phase's stop condition
("evidence is insufficient to justify a code change"). Changing Bcore here would be exactly
the speculative patch the brief forbids.

The only edit is to a **diagnostic**: `ProbeApiFeature.java`'s action list was corrected
from guessed action names (which returned 0 matches on the *host* too, so measured nothing)
to the real ones. The wrong-name result is documented rather than quietly deleted, because
"component resolution is identical" is a real finding and a probe whose host and guest
answers agree cannot explain a host/guest difference.

## 16. Why the fix is legitimate

N/A — no fix was made.

## 17. Regression results

No production code changed, so no regression risk was introduced. Verified anyway:

- `flutter analyze` — 4 pre-existing info lints, 0 errors
- `flutter test` — 245/245
- Duplika release build launches on device, all pre-existing clones intact, installed-app
  and APK-import clone flows both work, `RealGmsProvider` still selected, GMS diagnostic
  otherwise unchanged (P0/P1/P2 PASS), 0 crashes/ANRs

**NOT RE-RUN this phase:** Level 6, Level 7, Level 8. No production change was made, but
they were not executed here and are not claimed.

## 18. Remaining limitations

1. Root cause unconfirmed; hypotheses 9 and 10 are not separable without visibility into
   the client library's availability decision.
2. `checkApiAvailability` for AppSet could not be asked symmetrically —
   `AppSetIdClient` does not implement `HasApiKey` in play-services-appset 16.0.2 — so the
   working/failing comparison is asymmetric at that one point.
3. Only `SettingsClient` was probed within play-services-location;
   `FusedLocationProviderClient` was not, so "all of LocationServices fails" is inferred
   from one entry point.
4. The GMS-side reason is unobservable: Play services logs no rejection for P3 because the
   call never reaches it.

## 19. Recommended next step

Separate hypotheses 9 and 10 with a **read-only** experiment before touching any code —
for example probing a second permission-gated non-location GoogleApi (does *it* also refuse
in a container?), which would distinguish "permission-attributable APIs refuse containerised
callers" (security boundary → stop) from "something specific to play-services-location"
(possible compatibility defect → investigate further).
