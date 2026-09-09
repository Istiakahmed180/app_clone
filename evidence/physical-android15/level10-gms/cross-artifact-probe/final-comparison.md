# Phase 10 — final cross-artifact comparison

Device: OnePlus CPH2605, Android 15 / API 35 / arm64-v8a, `KNOJORMFV4GERKHM`, 2026-09-09.
Host GMS 26.32.34. Same APK in every cell. Clones via the ordinary flow, provisioning off,
`selectedProvider=REAL_GMS` on every clone.

## The full matrix — all cells measured

| API | Artifact | Host Debug | Host Release | Guest Debug | Guest Release |
| --- | --- | --- | --- | --- | --- |
| Advertising ID | ads-identifier (direct AIDL) | PASS | PASS | PASS | PASS |
| AppSet ID | appset (GoogleApi) | PASS | PASS | PASS | PASS |
| LocationServices | **play-services-location** | PASS | PASS | FAIL | FAIL |
| ActivityRecognition | **play-services-location** | PASS | PASS | FAIL | FAIL |
| **SmsRetriever** | **auth-api-phone 18.0.2** | **PASS** | **PASS** | **FAIL** | **FAIL** |

## Phase 10 detail

`checkApiAvailability`, all three clients measured in the same run and process:

| Cell | SmsRetriever | ActivityRecognition | LocationServices | P8 |
| --- | --- | --- | --- | --- |
| Host Debug | **available** | available | available | PASS |
| Host Release (minified) | **available** | available | available | PASS |
| Guest Debug | **DEVELOPER_ERROR** | DEVELOPER_ERROR | DEVELOPER_ERROR | UNSUPPORTED |
| Guest Release (minified) | **DEVELOPER_ERROR** | DEVELOPER_ERROR | DEVELOPER_ERROR | UNSUPPORTED |

`startSmsRetriever()` end-to-end:

| Cell | Outcome | Elapsed |
| --- | --- | --- |
| Host Debug | completed — self-expiring listener registered, no SMS read | 950 ms |
| Host Release | completed — self-expiring listener registered, no SMS read | 1733 ms |
| Guest Debug | `ApiException statusCode=17` — SmsRetriever.API not available | 6 ms |
| Guest Release | `statusCode=17` (minified `g`) — SmsRetriever.API not available | 10 ms |

Host: ~1–1.7 s, the call actually reaching Play services and registering.
Guest: 6–10 ms, refused locally before any IPC — the same pre-IPC refusal signature as
LocationServices (~20 ms) and ActivityRecognition (8–9 ms).

Debug and minified Release agree in every cell, so R8 is not a factor.

## The confound is eliminated

`SmsRetriever` lives in `play-services-auth-api-phone:18.0.2` — a different artifact, a
different API namespace, a different GMS service — and needs **no runtime permission at
all**. It is refused exactly like the two `play-services-location` APIs.

So "the failure is specific to `play-services-location`" no longer fits the data.

## What the pattern now is

| Probe | Client layer | Caller-scoped? | Artifact | Guest |
| --- | --- | --- | --- | --- |
| Advertising ID | direct AIDL | no | ads-identifier | **PASS** |
| AppSet ID | GoogleApi | no | appset | **PASS** |
| LocationServices | GoogleApi | yes (permission) | location | **FAIL** |
| ActivityRecognition | GoogleApi | yes (permission) | location | **FAIL** |
| SmsRetriever | GoogleApi | yes (signature) | **auth-api-phone** | **FAIL** |

Three attribution-sensitive GoogleApis across **two** artifacts, gated by **two different
mechanisms** (runtime permission and caller signature), all refused. Two
non-attribution-sensitive APIs, both served. The framework is not the variable — AppSet uses
it and passes. The variable is whether the API's access must be tied to the calling
identity.
