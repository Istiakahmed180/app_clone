# Phase 10 — decision

## Case A — SmsRetriever also fails in the guest

Measured:

- Host Debug = **PASS**
- Host Release = **PASS**
- Guest Debug = **FAIL**
- Guest Release = **FAIL**

The failure is a comparable local, pre-IPC refusal: `ConnectionResult{DEVELOPER_ERROR}` in
6–10 ms with no broker bind, versus ~1–1.7 s for the host call that actually reaches Play
services. Same signature as LocationServices and ActivityRecognition.

## Classification

| Hypothesis | Status |
| --- | --- |
| **H9** — general containerised-caller attribution problem | **CONFIRMED** |
| **H10** — `play-services-location`-specific behaviour | **REJECTED** as the primary explanation |

**The GMS limitation is classified: UNSUPPORTED / SECURITY-BOUNDARY.**

## Why this is now confirmed rather than merely supported

Phase 9's weakness was that both failing APIs shared one artifact. Phase 10 removes it, and
does so on two independent axes at once:

1. **Different artifact** — `play-services-auth-api-phone:18.0.2`, not
   `play-services-location`.
2. **Different attribution mechanism** — `SmsRetriever` is scoped by the caller's
   **signature**, not by a runtime permission. So the pattern is not "permission-gated APIs
   fail"; it is the broader "APIs whose access must be tied to the calling identity fail".

That second point matters: it also closes the refinement pre-registered in Phase 10's
`selected-api.md` as the thing a guest PASS would have left open. A guest FAIL closes it
instead, because signature-scoped and permission-gated attribution both fail while
non-attribution-sensitive APIs both succeed.

Three attribution-sensitive APIs, two artifacts, two mechanisms — all refused. Two
non-attribution-sensitive APIs — both served, in the same containers.

## Consequence — the investigation line stops here

The refusal turns on the calling package not corresponding to the calling UID from the GMS
process's point of view. Duplika runs guests under the host app's UID; that is what
virtualization *is*, and Play services is correctly declining to attribute a
permission- or signature-scoped capability to a caller it cannot verify.

Making these APIs pass would require one of the following, **all forbidden and none
attempted**:

- UID spoofing
- package identity spoofing
- signature spoofing
- certificate spoofing
- Binder caller identity spoofing
- fake GMS identity
- Play Integrity bypass
- SafetyNet bypass
- GMS response spoofing

Therefore: **no engine change, no Bcore change, no microG in this phase.** This is a
boundary to be documented and respected, not a defect to be fixed.

## What remains genuinely supported in a container

Confirmed working and unaffected: package visibility and metadata coherence,
`isGooglePlayServicesAvailable() = SUCCESS(0)`, direct-AIDL GMS services (Advertising ID),
and the GoogleApi client framework itself for non-attribution-sensitive APIs (AppSet ID).
The framework is not broken; only identity-scoped APIs are out of reach.

## Honest residue

- n=3 attribution-sensitive APIs across 2 artifacts. Strong, but still a sample — "every
  identity-scoped GMS API fails in a container" is an extrapolation, not an enumeration.
- The client library's internal decision was never instrumented; the mechanism is inferred
  from timing plus the absence of a bind, not observed directly.
- Google account sign-in and OAuth-bound APIs were never tested and remain separately
  classified UNSUPPORTED / SECURITY-BOUNDARY.
