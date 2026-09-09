# Phase 10 — selected API

Written **before** running, per Step 2.

## Validation against the resolved graph

| Property | Value |
| --- | --- |
| Artifact | `com.google.android.gms:play-services-auth-api-phone` |
| Version requested by the brief | 18.0.2 |
| **Version actually resolved** | **18.0.2** — matches |
| How it arrives | transitive of `play-services-auth:21.2.0`, already declared |
| On `releaseRuntimeClasspath` | yes |
| On `releaseCompileClasspath` | **yes** — so it is usable without touching `build.gradle.kts` |

**No dependency was added, upgraded or downgraded.** Verified with
`./gradlew :level10_gms:dependencies` on both configurations.

## API

| Property | Value |
| --- | --- |
| Class | `com.google.android.gms.auth.api.phone.SmsRetrieverClient` |
| GoogleApi implementation | `extends GoogleApi<Api.ApiOptions.NoOptions> implements SmsRetrieverApi` (confirmed by `javap` on the resolved AAR) |
| Required manifest permission | **none** |
| Google account | **not required** |
| OAuth | **not required** |
| API key | **not required** |
| Play Integrity / SafetyNet / attestation | **not required** |
| Exercisable without credentials | **yes** |

Because it extends `GoogleApi`, it implements `HasApiKey`, so
`GoogleApiAvailability.checkApiAvailability(client)` applies — the **same** read-only
measurement used for LocationServices (Phase 8) and ActivityRecognition (Phase 9). The
comparison is therefore exactly symmetric across all three.

## Why it eliminates the play-services-location confound

Phases 8 and 9 both failed, but both failing APIs
(`LocationServices`, `ActivityRecognition`) ship in **`play-services-location:21.3.0`**. So
two readings fit the data equally well:

- **H9** — any GoogleApi whose access must be attributed to the calling package is refused
  for a containerised caller;
- **H10** — something about `play-services-location` specifically.

`SmsRetrieverClient` is in a **different artifact** (`play-services-auth-api-phone`), a
different API namespace, and a different GMS service. Measuring it separates the artifact
from the attribution property.

## Credential-free operation (Step 3)

**Primary — `GoogleApiAvailability.checkApiAvailability(smsRetrieverClient)`.** Read-only,
no credentials, no side effects, and identical in form to the Phase 8/9 measurements. This
is the preferred probe the brief asks for.

**Secondary — `startSmsRetriever()`.** Included for an end-to-end Task status and a timing
figure, the same role `removeActivityUpdates` played in Phase 9. It needs no account, no
OAuth, no API key and no attestation. Its only side effect is registering a **self-expiring
5-minute listener** scoped to this app's own signature; it sends no SMS, reads no SMS, needs
no incoming message to return (the Task completes on registration), and requires no
permission. No SMS retrieval workflow is performed and no message content is ever touched.

## Interpretation caveat, stated up front

`SmsRetriever` is **caller-signature-scoped, not permission-gated.** It needs no runtime
permission at all. That asymmetry matters for reading the result and is recorded now so the
conclusion cannot be quietly over-fitted later:

- **Guest FAIL** → the artifact confound is eliminated cleanly. An attribution-sensitive
  GoogleApi from a different artifact is also refused → **H9 confirmed, H10 rejected** as
  the primary explanation.
- **Guest PASS** → the artifact confound is eliminated in the other direction, but a pass is
  *also* consistent with a refined hypothesis that Phase 10 cannot exclude: "APIs requiring
  **runtime-permission** attribution are refused, while APIs requiring only **signature**
  scoping are served." Under that reading H10 would **not** be strongly supported, because
  the discriminating property would be permission-attribution rather than the library. The
  brief's Case B mapping is therefore applied with that qualification rather than
  mechanically.

## Expected conditions

- Success: `checkApiAvailability` completes, and/or `startSmsRetriever` returns a real
  status from Play services.
- Failure: `AvailabilityException` naming `SmsRetriever.API` with a `ConnectionResult`, or an
  `ApiException` — recorded with its status code.
