# Phase 9 — cross-API comparison

Device: OnePlus CPH2605, Android 15 / API 35 / arm64-v8a, `KNOJORMFV4GERKHM`, 2026-09-09.
Same APK (`com.example.duplikaladder.level10gms`) in every cell. Host GMS 26.32.34.
Clones created through the ordinary flow, provisioning off, `selectedProvider=REAL_GMS`.

## The 2x2

| Cell | `checkApiAvailability(ActivityRecognition)` | `checkApiAvailability(LocationServices)` | P7 |
| --- | --- | --- | --- |
| Host Debug | **available** | **available** | PASS |
| Host Release (minified) | **available** | **available** | PASS |
| Guest Debug | **DEVELOPER_ERROR** | **DEVELOPER_ERROR** | FAIL |
| Guest Release (minified) | **DEVELOPER_ERROR** | **DEVELOPER_ERROR** | FAIL |

`removeActivityUpdates` end-to-end:

| Cell | Outcome | Elapsed |
| --- | --- | --- |
| Host Debug | `SecurityException: Activity detection usage requires the ACTIVITY_RECOGNITION permission` | 8 ms |
| Host Release | same `SecurityException` | 6 ms |
| Guest Debug | `ApiException statusCode=17` — API not available | 9 ms |
| Guest Release | `ApiException statusCode=17` — API not available | 8 ms |

On the host the client reaches the point of **enforcing the permission**. In the guest it
never gets that far: the API is refused before the permission is ever consulted.

## The control that matters

`ACTIVITY_RECOGNITION` was **DENIED in all four cells** — never granted anywhere.

- Host, permission DENIED  -> API **available**
- Guest, permission DENIED -> API **DEVELOPER_ERROR**

Permission state is therefore **held constant while the outcome flips**, which excludes
permission state as the cause for a second, independent API. (Phase 8 had already excluded
it for LocationServices by granting and re-running.)

## Focused table (Step 6 format)

| Property | Host | Guest | LocationServices Guest |
| --- | --- | --- | --- |
| Same APK | yes | yes | yes |
| GMS availability | SUCCESS(0) | SUCCESS(0) | SUCCESS(0) |
| GMS version | 26.32.34 | 26.32.34 | 26.32.34 |
| Permission state | DENIED | DENIED | n/a (none needed) |
| API result | available | DEVELOPER_ERROR | DEVELOPER_ERROR |
| Error/status | — | `ConnectionResult{DEVELOPER_ERROR}` / `ApiException 17` | identical |
| Timing | 6-8 ms | 8-9 ms | ~20 ms |
| Broker bind | reached permission check | none | none |
| Caller attribution | app's own uid | host uid `co.tdevs.duplika` | same |

## Pattern across every GoogleApi probed so far, in a guest

| Probe | Client layer | Permission-gated | Guest result |
| --- | --- | --- | --- |
| P1 AdvertisingId | direct AIDL | no | **PASS** |
| P2 AppSet ID | GoogleApi framework | no | **PASS** |
| P3 LocationServices | GoogleApi framework | **yes** | **FAIL** `DEVELOPER_ERROR` |
| P7 ActivityRecognition | GoogleApi framework | **yes** | **FAIL** `DEVELOPER_ERROR` |

Both non-permission-gated APIs succeed; both permission-gated APIs fail. The framework is
not the variable (P2 uses it and passes). The variable that tracks the outcome is whether
the API's access must be **attributed to the calling package**.

## The confound, stated plainly

Both failing APIs ship in `play-services-location:21.3.0`. So "permission-gated APIs are
refused" and "APIs from this one artifact are refused" both fit the data. This was
pre-registered as the known weakness of choosing ActivityRecognition, and it is why the
result is *strong support*, not proof.
