# Phase 9 — decision

Applying the Step 7 framework, and only that framework.

## Observed

- Host Debug = **PASS**
- Host Release = **PASS**
- Guest Debug = **FAIL**
- Guest Release = **FAIL**

The failure is `ConnectionResult{DEVELOPER_ERROR}` on `ActivityRecognition.API`, refused
before any GMS broker bind and before the permission is consulted — meaningfully related to
caller authorization/attribution rather than to the permission grant, which was DENIED on
both sides.

## => Result A

> **A general containerised-caller compatibility/security boundary is strongly indicated.**

A second permission-gated GoogleApi, in a different API namespace from the first and gated
by a **non-location** runtime permission, is refused for a containerised caller in exactly
the same way and with exactly the same status.

This is **not claimed as mathematically proven.** Per Step 7's own caution, the second API
has its own client-side rules, and it ships in the same artifact as the first.

## Hypothesis status

| Hypothesis | Before Phase 9 | After Phase 9 |
| --- | --- | --- |
| **H9** — general containerised-caller attribution problem | LIKELY, not confirmed | **STRONGLY SUPPORTED — likely security boundary** |
| **H10** — specific to play-services-location's per-API decision | UNKNOWN | **Reduced likelihood, NOT eliminated** (both failing APIs share the artifact) |

## Consequence

**STOP.** No Bcore change, no engine change, no identity handling change.

If H9 is correct, the refusal turns on the calling package not belonging to the calling UID
from the GMS process's point of view. Making it pass would require caller-identity spoofing,
which is on the project's forbidden list — so the correct action is to classify it as
**UNSUPPORTED / SECURITY-BOUNDARY** and leave it.

What would still separate H9 from H10: a permission-gated GoogleApi in a **different
artefact**. `play-services-auth-api-phone:18.0.2` (`SmsRetrieverClient`) is already in the
resolved dependency graph and is caller-signature-scoped; it was deliberately held back
because Step 2 asked for exactly one API. That is the single cheapest next experiment, and
it is read-only.
