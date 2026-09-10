# FCM in a clone — Cabex FX, measured

**Result: UNSUPPORTED / SECURITY BOUNDARY.** Firebase Cloud Messaging token retrieval fails
inside a Duplika clone because Play services refuses to attribute the registration to a
package that does not belong to the Binder calling UID. This is the boundary already
documented in `docs/level10-gms-caller-identity-boundary.md` §5, reached through a different
code path and reported in different words.

Device: emulator `sdk_gphone64_arm64`, Android 15 / API 35, GMS present. Reproduced from the
user's own report on the same setup.

## What was measured

| Fact | Value |
| --- | --- |
| Guest package | `com.moneyin.cabex.fx` |
| Its own UID when installed on the host | **10222** |
| `co.tdevs.duplika` UID | **10234** |
| Process that logged the refusal | pid **1052** = `com.google.android.gms` |

```
16:58:35.450  4387  D PackageManagerStub  : queryIntentReceivers: []
16:58:35.451  4387  W FirebaseMessaging   : Failed to resolve IID implementation package, falling back
16:58:35.705  1052  W GCM                 : Invalid caller: com.moneyin.cabex.fx 10234
16:59:05.702  4387  E FirebaseMessaging   : Topic sync or token retrieval failed on hard failure
                                            exceptions: java.io.IOException: SERVICE_NOT_AVAILABLE.
                                            Won't retry the operation.
```

Play services is told the caller is `com.moneyin.cabex.fx` while the Binder UID is 10234,
which owns only `co.tdevs.duplika`. It refuses. Thirty seconds later the client library gives
up and surfaces `SERVICE_NOT_AVAILABLE`.

**That 30-second gap is the user-visible symptom** — the clone appears to hang on launch. It is
the FCM registration timeout, not slow startup.

## Why this was nearly misclassified

The refusal carries **no** `SecurityException: Unknown calling package name`, no
`Failed to get service from broker`, and no `DEVELOPER_ERROR` — the three signatures §1 of the
caller-identity document records. Searching for those alone returns zero matches and points
at a fixable defect.

Play services validates caller identity in more than one place. The GCM subsystem does its own
check and reports it as `GCM: Invalid caller: <package> <uid>`, from the GMS process rather
than through the client's broker call. `classify.sh` now matches both wordings; its first
version did not, and returned the wrong verdict.

## Why it cannot be fixed

Identical to §5 of the caller-identity document. Making this pass would require Play services
to accept `com.moneyin.cabex.fx` as belonging to UID 10234 — package-identity spoofing, UID
spoofing, or intercepting and answering the check inside the container. All three are on the
forbidden list.

Duplika is not answering anything incorrectly here, and neither is Play services.

## A real defect found alongside, and why it is not the cause

```
D PackageManagerStub: queryIntentReceivers: []
W FirebaseMessaging: Failed to resolve IID implementation package, falling back
```

The container answers `queryIntentReceivers` with an empty list, so FirebaseMessaging cannot
resolve the InstanceID implementation package. `engine-patches/0002-host-platform-package-visibility.patch`
covers the by-name and by-component lookups but **not** `queryIntentReceivers` or
`queryIntentServices`. This is a wrong answer about the host of the same shape as the Level 9
defect, and correcting it would involve no identity assertion.

**It is not the cause of this failure and must not be presented as a fix for it.** The client
logs "falling back" and proceeds; the fatal refusal comes from Play services 250 ms later and
would come regardless. Recorded here — with a demonstrated real guest caller, which is what
§6b asks for — so a future phase that finds a caller genuinely blocked by it has the
measurement already.

## What should change in the product

Nothing in the engine. The compatibility layer should tell the user **before** they clone that
push notifications will not work in a clone of an FCM-dependent app, in the same honest style
as the existing GMS warnings. The current behaviour — a 30-second hang and silence — is the
worst version of a limitation the project already knows about and already discloses elsewhere.

## Files

| Path | What |
| --- | --- |
| `capture.sh` | reproduces and captures a full `logcat -v threadtime` |
| `classify.sh` | classifies a capture; matches every known refusal wording |
| `raw-emulator-api35.log` | the capture this document is written from |
