# Level 10 Phase 10 — cross-artifact permission/caller-scoped GMS probe

**Outcome: BLOCKED — the physical device disconnected before any cell could be measured.
No conclusion is drawn. H9/H10 status is unchanged from Phase 9.**

## 1. Objective

One final read-only experiment to eliminate the remaining `play-services-location` artifact
confound, by probing `SmsRetrieverClient` from `play-services-auth-api-phone`.

## 2. Existing H9/H10 state (entering this phase)

| Hypothesis | Status after Phase 9 |
| --- | --- |
| **H9** — general containerised-caller attribution problem | STRONGLY SUPPORTED |
| **H10** — `play-services-location`-specific behaviour | Reduced likelihood, NOT eliminated |

The confound: both APIs that failed (Phase 8 `LocationServices`, Phase 9
`ActivityRecognition`) ship in `play-services-location:21.3.0`.

Established guest results, for reference: Advertising ID **PASS**, AppSet ID **PASS**,
LocationServices **FAIL**, ActivityRecognition **FAIL** — all with
`ApiException 17 / DEVELOPER_ERROR` and no broker bind for the failures.

## 3. Selected API

`com.google.android.gms.auth.api.phone.SmsRetrieverClient`.

`javap` on the resolved AAR confirms:

```
public abstract class SmsRetrieverClient
    extends com.google.android.gms.common.api.GoogleApi<Api$ApiOptions$NoOptions>
    implements SmsRetrieverApi
```

Because it extends `GoogleApi` it implements `HasApiKey`, so
`GoogleApiAvailability.checkApiAvailability(client)` applies — the identical measurement
used in Phases 8 and 9.

## 4. Artifact / version

| Property | Value |
| --- | --- |
| Artifact | `com.google.android.gms:play-services-auth-api-phone` |
| Version in the brief | 18.0.2 |
| **Version actually resolved** | **18.0.2** — matches |
| Origin | transitive of `play-services-auth:21.2.0`, already declared |
| `releaseCompileClasspath` | present |
| `releaseRuntimeClasspath` | present |

**No dependency added, upgraded or downgraded.**

## 5. Credential-free operation

**Primary:** `checkApiAvailability(smsRetrieverClient)` — read-only, no credentials, no side
effects, symmetric with Phases 8/9.

**Secondary:** `startSmsRetriever()` — for an end-to-end Task status and timing. Needs no
account, no OAuth, no API key, no attestation and **no runtime permission**. Its only side
effect is a self-expiring 5-minute listener scoped to the app's own signature; it sends no
SMS, reads no SMS, and needs no incoming message to return. No retrieval workflow is
performed and no message content is touched.

`SmsRetriever` is **caller-signature-scoped, not permission-gated** — see §12/§13 for why
that constrains the reading.

## 6. Host control

**NOT MEASURED.** The CPH2605 dropped off ADB immediately before the host Debug run
(`adb: device 'KNOJORMFV4GERKHM' not found`) and did not return across three
`kill-server`/`start-server` cycles with waits. Only `emulator-5554` remained attached.

Step 5 requires both host cells to succeed before proceeding; neither could be attempted.

## 7. Guest result

**NOT MEASURED** — blocked by the same cause.

## 8. Timing

**NOT MEASURED.**

## 9. IPC / broker observations

**NOT MEASURED.**

## 10. Caller attribution observations

**NOT MEASURED** in this phase. Phase 9's observations stand unchanged.

## 11. Cross-artifact comparison

| API | Artifact | Host Debug | Host Release | Guest Debug | Guest Release |
| --- | --- | --- | --- | --- | --- |
| Advertising ID | ads-identifier (direct AIDL) | PASS | PASS | PASS | PASS |
| AppSet ID | appset | PASS | PASS | PASS | PASS |
| LocationServices | **play-services-location** | PASS | PASS | FAIL | FAIL |
| ActivityRecognition | **play-services-location** | PASS | PASS | FAIL | FAIL |
| **SmsRetriever** | **auth-api-phone** | **NOT MEASURED** | **NOT MEASURED** | **NOT MEASURED** | **NOT MEASURED** |

Only measured results are entered. The bottom row is the point of the phase and it is empty.

## 12. H9 update

**UNCHANGED — STRONGLY SUPPORTED, not confirmed.** No new evidence was produced.

## 13. H10 update

**UNCHANGED — reduced likelihood, not eliminated.** The artifact confound this phase exists
to remove is still present.

### Interpretation caveat that will apply when the phase is re-run

Recorded now so the conclusion cannot be over-fitted after the fact. `SmsRetriever` is
signature-scoped, **not** permission-gated, so the two branches are not symmetric:

- **Guest FAIL** → confound eliminated cleanly. An attribution-sensitive GoogleApi in a
  different artifact is also refused → **H9 confirmed, H10 rejected** as primary
  explanation → classify UNSUPPORTED / SECURITY-BOUNDARY.
- **Guest PASS** → confound eliminated in the other direction, but a pass *also* fits a
  refinement this probe cannot exclude: "APIs requiring **runtime-permission** attribution
  are refused; APIs requiring only **signature** scoping are served." Under that reading
  H10 would **not** be strongly supported, because the discriminating property would be the
  kind of attribution, not the library. So Case B's mapping applies only with that
  qualification — which is why `ProbeSmsRetriever` returns `PARTIAL` rather than `PASS` in
  that branch, and says so in its own verdict text.

## 14. Security-boundary assessment

No change. Phase 9's assessment stands: **likely UNSUPPORTED / SECURITY-BOUNDARY**, not yet
certain. This phase produced no evidence either way.

Nothing here attempted or required a bypass: no UID, package-identity, signature or
certificate spoofing; no Binder caller-identity manipulation; no Play Integrity or SafetyNet
interaction; no account, OAuth or token; no fake GMS response; no attempt to make a failing
API pass.

## 15. Production-change assessment

**Production behaviour changed: NO.**

Diagnostic-only:

| File | Kind |
| --- | --- |
| `compatibility_test_ladder/level10_gms/.../ProbeSmsRetriever.java` | diagnostic (new) |
| `compatibility_test_ladder/level10_gms/.../MainActivity.java` | diagnostic (wire P8) |
| `compatibility_test_ladder/level10_gms/proguard-rules.pro` | diagnostic (R8 keeps) |
| `docs/level10-cross-artifact-gms-probe.md` | documentation |
| `evidence/.../cross-artifact-probe/` | evidence |

No Bcore, engine, UID-mapping, package-identity, signature, GMS, authentication or microG
change. **Existing regression status remains unchanged.** Level 6/7/8 were **NOT executed**
in this phase and are not claimed.

## 16. Limitations

1. **The experiment did not run.** Everything below is capability, not result.
2. The artifact confound remains, so Level 10's overall conclusion is still Phase 9's.
3. When re-run, the signature-vs-permission asymmetry in §13 limits what a guest PASS can
   establish.
4. `emulator-5554` was deliberately **not** substituted: a different Android image with a
   different GMS build and no existing clone set would not be comparable with the Phase 8/9
   baselines this phase depends on.

## 17. Final classification

**BLOCKED (device unavailable).**

Not Case A, B or C — all three presuppose measured results. Not PARTIAL/INCONCLUSIVE
either, since that describes an API that failed to give a usable signal, whereas this API
was never exercised.

Ready and verified without the device:

- API validated against the resolved graph; no dependency change
- `GoogleApi` inheritance confirmed by `javap`, so the measurement is symmetric
- P8 probe written and wired; checks all three APIs in one run
- Debug + Release APKs built, minification retained, `ProbeSmsRetriever` verified present in
  the minified release dex
- `flutter analyze` 0 errors (4 pre-existing info lints); `flutter test` **245/245**

## 18. Recommended next step

Reattach the OnePlus CPH2605 and run the four cells with the **already-built** APKs — host
Debug, host Release, then clone and run guest Debug, guest Release. No code change is
required; the probe reports the discrimination itself.

Until then: **no engine change, no Bcore change, no microG, no attempt to make a failing API
pass.** Level 10's standing position remains Phase 9's — H9 strongly supported, likely a
security boundary, artifact confound outstanding.
