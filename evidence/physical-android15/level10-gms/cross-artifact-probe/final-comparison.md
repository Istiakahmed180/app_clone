# Phase 10 — final cross-artifact comparison

Only measured results are entered.

| API | Artifact | Host Debug | Host Release | Guest Debug | Guest Release |
| --- | --- | --- | --- | --- | --- |
| Advertising ID | ads-identifier (direct AIDL) | PASS | PASS | PASS | PASS |
| AppSet ID | appset (GoogleApi) | PASS | PASS | PASS | PASS |
| LocationServices | **play-services-location** | PASS | PASS | FAIL | FAIL |
| ActivityRecognition | **play-services-location** | PASS | PASS | FAIL | FAIL |
| **SmsRetriever** | **auth-api-phone** | **NOT MEASURED** | **NOT MEASURED** | **NOT MEASURED** | **NOT MEASURED** |

The bottom row is the entire purpose of this phase, and it is empty: the physical device
disconnected before the host control could be run. See `decision.md`.

Consequently the Level 10 pattern is still exactly what Phase 9 left:

- non-attribution-gated GoogleApi in a guest -> PASS (2 of 2)
- permission-gated GoogleApi from play-services-location in a guest -> FAIL (2 of 2)
- both failing APIs share one artifact -> **confound outstanding**
