# Level 10 Phase 10 — cross-artifact permission/caller-scoped GMS probe

**Outcome: Case A — H9 CONFIRMED, H10 REJECTED as the primary explanation. The GMS
limitation is classified UNSUPPORTED / SECURITY-BOUNDARY. Investigation line STOPS.**

*(Earlier revision of this document recorded BLOCKED: the device disconnected before the
first cell. It was reattached and all four cells were then measured with the same
already-built APKs, no code change.)*

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

**Both host cells PASS**, so the API is a valid discriminator (Step 5 satisfied).

| Cell | SmsRetriever | ActivityRecognition | LocationServices | P8 |
| --- | --- | --- | --- | --- |
| Host Debug | **available** | available | available | PASS |
| Host Release (minified) | **available** | available | available | PASS |

`startSmsRetriever()` completed on both — the listener actually registered (950 ms Debug,
1733 ms Release), so the call genuinely reached Play services.

## 7. Guest result

**Both guest cells FAIL**, identically.

| Cell | SmsRetriever | ActivityRecognition | LocationServices | P8 |
| --- | --- | --- | --- | --- |
| Guest Debug (user 23) | **DEVELOPER_ERROR** | DEVELOPER_ERROR | DEVELOPER_ERROR | UNSUPPORTED |
| Guest Release (user 24) | **DEVELOPER_ERROR** | DEVELOPER_ERROR | DEVELOPER_ERROR | UNSUPPORTED |

`startSmsRetriever()` → `ApiException statusCode=17`, *SmsRetriever.API is not available on
this device*.

## 8. Timing

| Cell | `startSmsRetriever` | Elapsed |
| --- | --- | --- |
| Host Debug | completed | 950 ms |
| Host Release | completed | 1733 ms |
| Guest Debug | refused, status 17 | **6 ms** |
| Guest Release | refused, status 17 | **10 ms** |

Host ~1–1.7 s (real round trip) versus guest 6–10 ms (local refusal). The same pre-IPC
signature as LocationServices (~20 ms) and ActivityRecognition (8–9 ms).

## 9. IPC / broker observations

No broker bind in either guest cell — the API is refused before any IPC, exactly as in
Phases 8 and 9. On the host the call reached Play services and registered a listener.

## 10. Caller attribution observations

Unchanged and re-observed: guests run under the host app's UID, Play services resolves the
caller to `co.tdevs.duplika`, and the client names the guest package. Nothing was modified;
the probe only records.

## 11. Cross-artifact comparison

| API | Artifact | Host Debug | Host Release | Guest Debug | Guest Release |
| --- | --- | --- | --- | --- | --- |
| Advertising ID | ads-identifier (direct AIDL) | PASS | PASS | PASS | PASS |
| AppSet ID | appset | PASS | PASS | PASS | PASS |
| LocationServices | **play-services-location** | PASS | PASS | FAIL | FAIL |
| ActivityRecognition | **play-services-location** | PASS | PASS | FAIL | FAIL |
| **SmsRetriever** | **auth-api-phone 18.0.2** | **PASS** | **PASS** | **FAIL** | **FAIL** |

All cells measured. Three attribution-sensitive GoogleApis across **two** artifacts, gated
by **two different mechanisms** (runtime permission and caller signature), all refused in a
container. Two non-attribution-sensitive APIs, both served.

## 12. H9 update

**CONFIRMED.** An attribution-sensitive GoogleApi from a different artifact, gated by a
different mechanism, is refused identically. The boundary is general to containerised
callers, not tied to one library.

## 13. H10 update

**REJECTED as the primary explanation.** `SmsRetriever` is outside
`play-services-location` and fails the same way, so "specific to that library" no longer
fits the data.

### The pre-registered caveat, and why it is now closed

Phase 10 recorded, before running, that the two branches were not symmetric because
`SmsRetriever` is signature-scoped rather than permission-gated:

- **Guest FAIL** → confound eliminated cleanly. An attribution-sensitive GoogleApi in a
  different artifact is also refused → **H9 confirmed, H10 rejected** as primary
  explanation → classify UNSUPPORTED / SECURITY-BOUNDARY.
- **Guest PASS** → confound eliminated in the other direction, but a pass *also* fits a
  refinement this probe cannot exclude: "APIs requiring **runtime-permission** attribution
  are refused; APIs requiring only **signature** scoping are served." Under that reading
  H10 would **not** be strongly supported, because the discriminating property would be the
  kind of attribution, not the library.

**The measured result is FAIL, so that open question is closed rather than inherited.** The
signature-scoped API fails alongside the permission-gated ones, which means the boundary is
not "permission-attributed APIs" but the broader "identity-scoped APIs" — and both
attribution mechanisms are now covered by evidence rather than one of them being assumed.

## 14. Security-boundary assessment

**UNSUPPORTED / SECURITY-BOUNDARY — now the classification, not a suspicion.**

The refusal turns on the calling package not corresponding to the calling UID from the GMS
process's view. Duplika runs guests under the host app's UID — that is what virtualization
is — and Play services is correctly declining to attribute an identity-scoped capability to
a caller it cannot verify. This is Google behaving properly, not a Duplika defect.

Making these APIs pass would require UID, package-identity, signature, certificate or Binder
caller-identity spoofing, a fake GMS identity, or a Play Integrity / SafetyNet / GMS-response
bypass. **All forbidden; none attempted.** The line stops here.

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

1. **n=3** attribution-sensitive APIs across 2 artifacts. Strong, but a sample — "every
   identity-scoped GMS API fails in a container" is an extrapolation, not an enumeration.
2. The client library's internal decision was never instrumented; the mechanism is inferred
   from timing plus the absence of a bind, not observed directly.
3. Google account sign-in and OAuth-bound APIs were never tested; they remain separately
   classified UNSUPPORTED / SECURITY-BOUNDARY.
4. `emulator-5554` was deliberately **not** used at any point — a different Android image
   with a different GMS build and no clone set would not be comparable with the Phase 8/9
   baselines.

## 17. Final classification

**Case A — H9 CONFIRMED, H10 REJECTED as primary explanation.
GMS limitation = UNSUPPORTED / SECURITY-BOUNDARY. Investigation line STOPS.**

Verified:

- API validated against the resolved graph; **no dependency added or changed**
- `GoogleApi` inheritance confirmed by `javap`, so the measurement is symmetric with
  Phases 8/9
- All four cells measured on the device of record, Debug and Release agreeing
- `flutter analyze` 0 errors (4 pre-existing info lints); `flutter test` **245/245**
- Production behaviour changed: **NO**

## 18. Recommended next step

**Not another experiment on this question — it is answered.**

The right follow-up is a *product* decision, not an engineering one: record the boundary
where users and future contributors will meet it. Concretely, Duplika's REQUIRES_GMS
compatibility warning (`AppCompatibilityAnalyzer.kt`) still says Play services "is not
virtualized in this build", which is now measurably wrong — availability is `SUCCESS(0)` and
non-identity-scoped Google APIs work. The accurate statement is narrower and more useful:
Google APIs that must be tied to the calling app's identity — sign-in, and anything
permission- or signature-scoped such as location and SMS retrieval — cannot work in a
clone, while other Google APIs can.

That was already flagged as a follow-up in Phase 7 and is now fully evidenced.

**Do not** modify Bcore, identity handling or the engine on the basis of this line of
investigation. There is nothing left to fix here — only something to state honestly.
