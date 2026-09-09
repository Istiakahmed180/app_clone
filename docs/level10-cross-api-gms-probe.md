# Level 10 Phase 9 — cross-API permission-gated GMS discrimination probe

Outcome: **Result A — general containerised-caller boundary strongly indicated. STOP.**
No production code changed.

## 1. Objective

One read-only experiment to separate the two hypotheses Phase 8 left standing:

- **H9** — a general containerised-caller attribution problem: Play services refuses any API
  whose access it must attribute to the calling package.
- **H10** — something specific to `play-services-location`'s client-side per-API decision.

Phase 8 could not separate them because its only permission-gated API *was* the failing one.

## 2. Selected API

`com.google.android.gms.location.ActivityRecognition` → `ActivityRecognitionClient`, from
`com.google.android.gms:play-services-location:21.3.0` — **already declared**, no new
dependency. Gated by `android.permission.ACTIVITY_RECOGNITION` (runtime, API 29+,
**non-location**). No account, no OAuth, no API key, no attestation.

Full selection record, including the candidates rejected and why:
`evidence/.../cross-api-probe/selected-api-rationale.md`.

## 3. Why selected

- Distinct `Api` object with its own GMS service, so it is not the same API under another name.
- **Permission-gated by a non-location runtime permission** — the literal criterion, and the
  right shape for testing attribution.
- Same `GoogleApi` framework as the failing `SettingsClient`, so the client layer is held
  constant.
- No credentials of any kind, so nothing forbidden is touched.
- Measured with `GoogleApiAvailability.checkApiAvailability(client)` — **the exact same
  measurement** Phase 8 used, asked of both clients in the same run, in the same process.
  Comparing like with like is what makes it a discriminator.

Pre-registered weakness: it ships in the **same artifact** as the failing API, so a guest
FAIL would not fully separate "permission-gated APIs are refused" from "this library is
refused". That caveat was written down before the run and is honoured in the conclusion.

## 4. Host control

| Cell | ActivityRecognition | LocationServices | P7 |
| --- | --- | --- | --- |
| Host Debug | **available** | **available** | PASS |
| Host Release (minified) | **available** | **available** | PASS |

Both build types succeed, so the API is a valid discriminator. `removeActivityUpdates`
returned `SecurityException: Activity detection usage requires the ACTIVITY_RECOGNITION
permission` in 6–8 ms — the client reached the point of **enforcing** the permission, which
confirms the API is genuinely permission-gated and that the path is healthy on the host.

## 5. Guest result

| Cell | ActivityRecognition | LocationServices | P7 |
| --- | --- | --- | --- |
| Guest Debug (virtual user 15) | **DEVELOPER_ERROR** | **DEVELOPER_ERROR** | FAIL |
| Guest Release (virtual user 14) | **DEVELOPER_ERROR** | **DEVELOPER_ERROR** | FAIL |

`removeActivityUpdates` → `ApiException statusCode=17` ("API not available") in 8–9 ms. In
the guest the client never reaches the permission check at all — the API is refused first.

## 6. LocationServices comparison

| Property | Host | Guest | LocationServices Guest |
| --- | --- | --- | --- |
| Same APK | yes | yes | yes |
| GMS availability | SUCCESS(0) | SUCCESS(0) | SUCCESS(0) |
| GMS version | 26.32.34 | 26.32.34 | 26.32.34 |
| Permission state | DENIED | DENIED | n/a (needs none) |
| API result | available | DEVELOPER_ERROR | DEVELOPER_ERROR |
| Error/status | — | `ConnectionResult{DEVELOPER_ERROR}` / `ApiException 17` | identical |
| Timing | 6–8 ms | 8–9 ms | ~20 ms |
| Broker bind | reached permission check | none | none |
| Caller attribution | app's own uid | host uid `co.tdevs.duplika` | same |

### The pattern across every GoogleApi probed in a guest

| Probe | Client layer | Permission-gated | Guest |
| --- | --- | --- | --- |
| P1 AdvertisingId | direct AIDL | no | **PASS** |
| P2 AppSet ID | GoogleApi framework | no | **PASS** |
| P3 LocationServices | GoogleApi framework | **yes** | **FAIL** |
| P7 ActivityRecognition | GoogleApi framework | **yes** | **FAIL** |

Both non-permission-gated APIs pass; both permission-gated APIs fail. The framework is not
the variable — P2 uses it and passes. The variable that tracks the outcome is whether the
API's access must be **attributed to the calling package**.

## 7. Permission analysis

`ACTIVITY_RECOGNITION` was **DENIED in all four cells** — never granted anywhere, and the
probe records that state each run.

- Host, DENIED → API **available**
- Guest, DENIED → API **DEVELOPER_ERROR**

Permission state is held constant while the outcome flips. That excludes permission state as
the cause for a second, independent API — Phase 8 had already excluded it for
LocationServices by granting the permission and re-running to an identical failure.

The permission was declared in the diagnostic manifest (a real consumer of this API would
declare it) but deliberately never granted, because `checkApiAvailability` needs neither.

## 8. Timing / IPC observations

Host: 6–8 ms to a `SecurityException` — the client connected far enough to enforce the gate.
Guest: 8–9 ms to `ApiException 17`, with **no broker bind**, mirroring LocationServices'
~20 ms no-bind refusal. Both guest refusals are local, pre-IPC, per-API decisions.

## 9. Caller attribution observations

Unchanged from Phase 8 and re-observed here: the guest reports `uid=10008` internally, its
virtualized PackageManager says that uid owns the guest package, and Play services observes
the bind as the **host** app's uid. The guest cannot read the kernel Binder calling UID, so
that half remains a host-side observation from Level 9. **Nothing was modified** — this
probe only records.

## 10. Hypothesis update

| Hypothesis | Before | After |
| --- | --- | --- |
| **H9** — general containerised-caller attribution | LIKELY, not confirmed | **STRONGLY SUPPORTED — likely security boundary** |
| **H10** — LocationServices/library-specific | UNKNOWN | **Reduced likelihood, NOT eliminated** |

H10 is not eliminated because both failing APIs share `play-services-location`. "Permission-
gated APIs are refused" and "APIs from this artifact are refused" both fit the data.

## 11. Security boundary assessment

**Likely UNSUPPORTED / SECURITY-BOUNDARY.**

If H9 is correct, the refusal turns on the calling package not belonging to the calling UID
from the GMS process's point of view. Making it pass would require caller-identity spoofing,
which is forbidden. The correct response is to classify and leave it, not to fix it.

Not yet stated as certain: the artifact confound above is a real alternative, and one more
read-only experiment would settle it.

Nothing in this phase attempted or required a bypass — no UID, signature, certificate or
package-identity spoofing; no Play Integrity or SafetyNet interaction; no account, OAuth or
token; no fake GMS response; no attempt to make the failing API pass.

## 12. Production-change assessment

**No production code changed.** Diagnostic-only:

| File | Kind |
| --- | --- |
| `compatibility_test_ladder/level10_gms/.../ProbeActivityRecognition.java` | diagnostic (new) |
| `compatibility_test_ladder/level10_gms/.../MainActivity.java` | diagnostic (wire P7) |
| `compatibility_test_ladder/level10_gms/.../ProbeApiFeature.java` | diagnostic (Phase 8 carry-over) |
| `compatibility_test_ladder/level10_gms/src/main/AndroidManifest.xml` | diagnostic (declare ACTIVITY_RECOGNITION) |
| `compatibility_test_ladder/level10_gms/proguard-rules.pro` | diagnostic (R8 keeps) |
| `docs/`, `evidence/` | documentation |

Existing regression status is therefore unchanged. `flutter analyze` (0 errors) and
`flutter test` (245/245) were run to confirm nothing drifted. **Level 6, 7 and 8 were NOT
executed in this phase** and are not claimed.

## 13. Limitations

1. **The artifact confound** — both failing APIs are in `play-services-location`, so H10 is
   reduced but not eliminated.
2. Only two permission-gated APIs sampled; "all permission-gated GMS APIs fail in a
   container" is an extrapolation from n=2.
3. The client library's internal decision was still not instrumented; the *mechanism* is
   inferred from timing plus absence of a bind, not observed directly.
4. The GMS-side reason stays unobservable because the calls never reach GMS.
5. `checkApiAvailability` could not be asked of AppSet symmetrically (`AppSetIdClient` does
   not implement `HasApiKey` in appset 16.0.2), so the passing framework API is compared on
   its end-to-end result rather than on the same availability call.

## 14. Classification

**PASS for the phase's objective** — a scientifically useful discriminator was produced,
under Step 7 **Result A**, and the phase stopped there as instructed.

The underlying LocationServices root cause remains **not fully confirmed**; that is the
expected outcome of a discrimination phase, not a failure of it.

## 15. Recommended next phase

One read-only experiment: probe a permission-gated GoogleApi from a **different artifact** —
`SmsRetrieverClient` in `play-services-auth-api-phone:18.0.2`, already in the resolved
dependency graph, caller-signature-scoped, needing no permission and no account.

- Refused too → the artifact confound is eliminated and H9 becomes the confirmed boundary →
  classify UNSUPPORTED / SECURITY-BOUNDARY and close the line of investigation.
- Works → the failure is confined to `play-services-location`, H9 collapses, and a
  library-specific compatibility investigation is warranted.

Either way the answer arrives without a code change. **Do not** modify Bcore, identity
handling or the engine before that result exists.
