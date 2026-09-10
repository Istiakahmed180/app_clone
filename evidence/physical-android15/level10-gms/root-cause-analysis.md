# Level 10 — root-cause analysis

> **Findings 3 and 4 are SUPERSEDED.** See
> [`docs/level10-gms-caller-identity-boundary.md`](../../../docs/level10-gms-caller-identity-boundary.md)
> and `evidence/emulator-pixel9-api35/level10-gms/`.
>
> - **Finding 4 ("what the local decision is made from is NOT yet identified") is answered.**
>   Play services throws `SecurityException: Unknown calling package name '<guest package>'`
>   from `IGmsServiceBroker.getService`; the client library converts it to
>   `DEVELOPER_ERROR`. Of the two candidates listed there, the `ClientSettings`
>   calling-package one is right and the Chimera/Feature-metadata one is wrong.
>   Classification: **UNSUPPORTED / SECURITY BOUNDARY**.
> - **Finding 3 ("the boundary is decided client-side, before any IPC") is falsified.** The
>   call reaches Play services. `Parcel.createException` in the captured stack proves the
>   exception was unparceled from another process. Both supporting observations still hold
>   and simply do not imply a local decision: a rejected Binder call is fast, and
>   `BoundBrokerSvc` logs new bindings rather than `getService` transactions.
> - Finding 5's classification of account-bound APIs is **confirmed by measurement** rather
>   than by reasoning: Google Sign-In is refused at connection time with the same
>   `DEVELOPER_ERROR`, before any authentication question is posed.
>
> Findings 1 and 2 stand unchanged.

Confidence uses the project's four levels: **confirmed fact** (directly measured on the
device), **strong evidence** (measured, one inference), **hypothesis**, **unknown**.

Device: OnePlus CPH2605, Android 15 / API 35 / arm64-v8a, `KNOJORMFV4GERKHM`.
No production or engine code was changed to produce any result here.

---

## Finding 1 — the Level 9 root cause is falsified as a general explanation

**Confirmed fact.**

Level 9 concluded that the GoogleApi boundary was Play services validating the caller's
package name against the Binder calling UID, which in a container do not correspond. That
predicts every `GoogleApi` client call fails from a guest.

It does not. P2 (AppSet ID) is a `GoogleApi` subclass, needs no account/key/permission, and
in a guest:

- the client was constructed and the task submitted through `GoogleApiManager`;
- Play services **bound it** — visible in its own broker log as
  `BoundBrokerSvc: onBind: … act=com.google.android.gms.appset.service.START`;
- a real App Set ID came back, scope 1, in **both** Debug and minified Release.

A containerised caller was therefore accepted and served by Play services through the
GoogleApi framework. The Level 9 explanation cannot be the general cause.

**Why Level 9 got it wrong, and it is worth being precise about this:** Level 9 measured a
single API and reasoned from one data point. The observation it built on — that Play
services sees `mCallingUid=<Duplika host uid>` — is *itself still true and still confirmed*.
What was wrong was the inference that this mismatch is what rejects the call. It does not;
P2 succeeds with exactly the same mismatch present.

Evidence: `google-api/guest-debug.log`, `google-api/guest-release-full-report.txt`,
`binder/gms-side-binds.log`.

---

## Finding 2 — transport, framework and package visibility are all fine

**Confirmed fact.** In a guest, in both build types:

| Layer | State |
| --- | --- |
| Package metadata coherence (`getPackageInfo` / `getApplicationInfo` / `getApplicationEnabledSetting` agree) | working |
| `isGooglePlayServicesAvailable` | `SUCCESS(0)` |
| GMS component surface visible | 370 declared services, same as host |
| Direct `bindService` + own AIDL to a GMS service (P1) | working — real advertising ID, 137 ms |
| GoogleApi client framework end to end (P2) | working — real App Set ID |
| Container isolation | intact: `getInstalledPackages` returns **1** in the guest vs **208** on the host |

The last row matters as much as the others: the Level 9 package-visibility patch did not
leak host enumeration into the guest, confirmed independently here.

---

## Finding 3 — the boundary is per-API and decided client-side, before any IPC

**Confirmed fact (the behaviour). Strong evidence (that it is a local pre-connection
decision).**

Three measurements, all from the guest:

1. **Timing.** P2 submits and answers in ~100 ms (`19.166` → `19.268`). P3 submits and fails
   in ~20 ms (`19.279` → `19.299`).
2. **No bind.** Play services' broker log shows the AppSet bind for P2. For P3 there is
   **no bind of any kind** — the client library never opened a connection.
3. **The framework's own verdict.** `GoogleApiAvailability.checkApiAvailability` for the
   LocationServices client returns `available` on the host and, in the guest:
   `AvailabilityException: None of the queried APIs are available. LocationServices.API:
   ConnectionResult{statusCode=DEVELOPER_ERROR}`.

So the client library decides `LocationServices.API` is unavailable locally, and the
`DEVELOPER_ERROR` surfaced to the app is that local decision, not a Play services rejection.

The single inference (hence strong evidence rather than confirmed fact): the client
library's internals were not instrumented, so "the decision is made locally from data the
client can read without IPC" is read from the timing plus the absent bind plus the
`checkApiAvailability` result, not from inside the library.

---

## Finding 4 — what the local decision is made from is NOT yet identified

**Unknown. Deliberately not guessed, and no fix attempted.**

P6 was written to find the input. One of its two arms was decisive, the other turned out to
be the wrong instrument, and both outcomes are worth recording:

- **`checkApiAvailability` (decisive).** Differs exactly as the failure does: `available` on
  host, `DEVELOPER_ERROR` in guest. Confirms the decision is per-API and reproducible.
- **`queryIntentServices` (wrong instrument).** The probe queried four GMS service actions.
  All four returned **0 matches on the host as well**, while LocationServices works there.
  So these APIs are dispatched through GMS's Chimera broker at runtime rather than resolved
  from manifest intent filters, and `queryIntentServices` cannot see them. The arm therefore
  measures nothing about this failure, on host or guest. It is left in place with this note
  rather than quietly deleted, because "component resolution is not the difference" is
  itself a real negative result — and because a probe whose host and guest answers agree
  cannot be the explanation for a host/guest difference.

Candidates that remain, none of them measured:

- per-API `Feature` / Chimera module metadata that the client reads about the local GMS
  installation;
- something in `ClientSettings` — the framework passes the calling package and its
  signature set for some APIs;
- a permission-attribution precondition specific to location (`LocationServices` is the
  only permission-gated API in the set, which is suggestive but is a **hypothesis** and
  nothing more).

Distinguishing these needs instrumentation of the client library's availability path. That
is the next precise step, and per the project's failure rule the work stops here rather than
patching a subsystem on a guess.

**Note on scope for whoever picks this up:** whatever the input turns out to be, a fix is
only legitimate if it corrects a *wrong answer* the virtualization layer is giving about the
real host GMS installation — the same shape as the Level 9 fix. If instead the input is the
calling package's signature or an identity assertion, the honest classification is
UNSUPPORTED / SECURITY-BOUNDARY, not a bug.

---

## Finding 5 — account-bound APIs are a security boundary, not a defect

**Confirmed fact (the observations). Classification, not a test result.**

P5 makes two read-only observations and stops: 0 visible `com.google` accounts, **no
engine-fabricated account** (checked for explicitly — some virtualization engines inject a
`mock.user@…`, which this project must not), and no cached `GoogleSignInAccount`.

No `signIn`, `silentSignIn`, token request or `GoogleAuthUtil` call is made anywhere in
Level 10. Google account sign-in inside a third-party container requires an identity
guarantee the container cannot legitimately provide, so it is recorded
**UNSUPPORTED / SECURITY-BOUNDARY**. It is not a FAIL, because there is nothing to fix, and
making it pass would mean spoofing.

Play Integrity was not tested and is not targeted. A virtualized caller should fail it; that
remains the correct outcome.

---

## Confidence summary

| Claim | Confidence |
| --- | --- |
| Level 9's caller-identity explanation is falsified as the general cause | **CONFIRMED FACT** |
| Play services accepts and serves a containerised GoogleApi caller (P2) | **CONFIRMED FACT** |
| Direct-AIDL GMS services work in a guest (P1) | **CONFIRMED FACT** |
| Package metadata coherence and `SUCCESS(0)` availability hold | **CONFIRMED FACT** |
| Container isolation intact (`getInstalledPackages` = 1 vs 208) | **CONFIRMED FACT** |
| Guest process runs under the host app UID and GMS observes that UID | **CONFIRMED FACT** (Level 9, unchanged) |
| `LocationServices` fails identically in Debug and Release | **CONFIRMED FACT** |
| Its `DEVELOPER_ERROR` is a client-side pre-connection decision | **STRONG EVIDENCE** |
| Component resolution is *not* the difference | **CONFIRMED FACT** (host also 0 matches) |
| Which input drives that decision | **UNKNOWN** — not instrumented, not guessed |
| Location being permission-gated is the reason | **HYPOTHESIS** only |
| Whether any real Google-dependent app works end to end | **UNKNOWN** — not tested |
| Whether Google sign-in works | **UNKNOWN** — never tested, never attempted |
