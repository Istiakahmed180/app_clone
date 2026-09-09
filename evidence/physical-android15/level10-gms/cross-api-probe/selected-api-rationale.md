# Phase 9 — selection of the second API

Written **before** implementation, per Step 2.

## Candidates already in the resolved dependency graph

`./gradlew :level10_gms:dependencies --configuration releaseRuntimeClasspath` resolves:

| Artifact | Present via | Candidate API | Verdict |
| --- | --- | --- | --- |
| `play-services-location:21.3.0` | direct | **`ActivityRecognition`** | **SELECTED** |
| `play-services-auth-api-phone:18.0.2` | transitive of `play-services-auth:21.2.0` | `SmsRetrieverClient` | Strong runner-up — held for the next phase |
| `play-services-fido:20.0.1` | transitive of `play-services-auth:21.2.0` | `Fido2ApiClient` | Rejected — attestation-adjacent, too close to integrity checks |
| `play-services-appset:16.0.2` | direct | AppSet ID | Already probed (P2), no authorization semantics |
| `play-services-ads-identifier:18.0.1` | direct | AdvertisingIdClient | Already probed (P1), not the framework |
| `play-services-auth:21.2.0` | direct | GoogleSignIn / Credentials | Rejected — account/OAuth bound |

**No new dependency is added.** The experiment is performed entirely within the existing graph.

## Selected: `ActivityRecognition` / `ActivityRecognitionClient`

| Property | Value |
| --- | --- |
| API | `com.google.android.gms.location.ActivityRecognition` → `ActivityRecognitionClient` |
| Artifact | `com.google.android.gms:play-services-location` |
| Version | `21.3.0` (already declared) |
| Required permission | `android.permission.ACTIVITY_RECOGNITION` (runtime, API 29+) — **non-location** |
| Manifest configuration | that one `<uses-permission>`; nothing else |
| Google account required | **No** |
| OAuth required | **No** |
| Play Integrity / attestation | **No** |
| Host test without credentials | **Yes** |

### Why it satisfies every constraint

- **Non-location API.** `ActivityRecognition.API` is a distinct `Api` object from
  `LocationServices.API`, backed by a different GMS service, and its permission is the
  activity-recognition runtime permission, not a location one.
- **Permission-gated with meaningful caller-authorization semantics.** `ACTIVITY_RECOGNITION`
  is a real runtime permission that GMS must attribute to the calling package — the same
  class of attribution that hypothesis 9 is about.
- **Same client framework.** `ActivityRecognitionClient` is a `GoogleApi` subclass, so it
  travels the identical `GoogleApiManager` path as the failing `SettingsClient`.
- **No credentials of any kind**, so nothing in the forbidden list is touched.
- **Safe on the device.** The primary measurement is
  `GoogleApiAvailability.checkApiAvailability(client)` — read-only, needs no granted
  permission, starts no tracking, and is the *exact same measurement* that returned
  `available` on the host and `DEVELOPER_ERROR` in the guest for LocationServices. Comparing
  like with like is what makes it a discriminator. A `removeActivityUpdates` call on a
  never-registered PendingIntent is additionally attempted to get an end-to-end Task result
  and timing; removing a non-existent registration is a no-op.

### Expected conditions

- **Success:** `checkApiAvailability` completes (API reported available) and/or the Task
  completes with a real status from Play services.
- **Failure:** `AvailabilityException` naming `ActivityRecognition.API` with a
  `ConnectionResult`, or an `ApiException` — recorded with its status code.

### Why it distinguishes hypothesis 9 from 10

| Outcome | Reading |
| --- | --- |
| Host PASS, guest **FAIL** with an attribution-shaped error | A second permission-gated, attribution-sensitive GoogleApi also refuses a containerised caller → **hypothesis 9 strongly supported**, likely security boundary → STOP. |
| Host PASS, guest **PASS** | A permission-gated GoogleApi *does* work for a containerised caller, so caller attribution alone cannot explain the LocationServices refusal → **hypothesis 9 weakened, hypothesis 10 strongly supported**, and the problem is isolated to `LocationServices.API` specifically. |

### Stated weakness of this choice, up front

`ActivityRecognition` ships in the **same artifact** as the failing API
(`play-services-location`). So a guest FAIL would be consistent with *either* a general
containerised-caller boundary *or* something library-wide, and would not fully separate
them. A guest PASS, by contrast, is unambiguous and maximally informative — it would isolate
the fault to `LocationServices.API` alone, not even the whole library.

`SmsRetrieverClient` (different artifact, caller-signature-scoped) is the cleaner probe for
the FAIL branch and is deliberately held in reserve for the next phase rather than bundled
into this one, since Step 2 asks for exactly one API.
