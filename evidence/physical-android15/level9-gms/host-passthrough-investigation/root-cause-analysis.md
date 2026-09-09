# Root-cause analysis — after host-platform package visibility

Supersedes nothing: `../root-cause-analysis.md` records the pre-fix classification and
remains valid. This file records what changed, and what the *new* boundary is.

Confidence uses the same four levels: **confirmed fact** (directly measured on device),
**strong evidence** (measured, one inference), **hypothesis**, **unknown**.

Device: OnePlus CPH2605, Android 15 / API 35 / arm64-v8a, serial `KNOJORMFV4GERKHM`.
Re-verified 2026-09-09 across four build combinations plus relaunches.

---

## Finding 1 — the PackageManager incoherence is fixed

**Confirmed fact.**

Every by-name query a guest makes about the three platform packages now returns the host's
real answer, and the three entry points agree with each other:

| Probe | Pre-fix guest | Post-fix guest | Host control |
| --- | --- | --- | --- |
| `getPackageInfo("…gms")` | `NameNotFoundException` | `26.32.34 (260400-968093310)` / `263234035` | identical |
| `getApplicationInfo("…gms")` | `NameNotFoundException` | OK, `enabled=true`, real `sourceDir` | identical |
| `getApplicationEnabledSetting("…gms")` | `0` | `0` | `0` |
| `getPackageInfo("com.android.vending")` | **`33.8.16-21`** (fabricated) | `53.0.27-34 [0] [PR] 973951861` / `85302740` | identical |
| `getApplicationInfo("com.android.vending")` | `NameNotFoundException` | OK, `enabled=true` | identical |
| GMS signing certs (sha256) | — | `f0fd6c5b…`, `7ce83c1b…`, `5f239127…` | identical |

Test A: **FAIL → PASS**. Test B: **`SERVICE_MISSING(1)` → `SUCCESS(0)`**. Test E: **PARTIAL
→ PASS** (E4, the sub-test that failed, was Play services discovery).

Finding 1 of the pre-fix analysis is therefore resolved, and Finding 3 (Test D as a
downstream consequence of Finding 1) is **falsified** — see Finding 2.

Evidence: `debug-package-detection.log`, `release-package-detection.log`,
`debug-gms-availability.log`, `release-gms-availability.log`.

---

## Finding 2 — Test D is NOT downstream of Test B; it is an independent identity boundary

**The pre-fix analysis got this wrong, and this is the substantive new result.**

Finding 3 pre-fix reasoned that `SettingsClient.checkLocationSettings` failed *because*
the availability check (Test B) had failed. That prediction is now testable: Test B passes
and Test D still fails. So availability was not the cause.

The failure also changed shape, which is itself informative:

| | Pre-fix (unprovisioned) | Pre-fix (provisioned) | Post-fix |
| --- | --- | --- | --- |
| Test D | no callback within 10 s | `17` | `17`, inner `ConnectionResult{DEVELOPER_ERROR}` |

`DEVELOPER_ERROR` is GMS rejecting the *client*, not GMS being absent.

### What was measured (confirmed fact)

1. **The guest process runs under the Duplika host UID.**
   ```
   ActivityManager: Start proc 20308:co.tdevs.duplika:p0/u0a962 …
   ActivityManager: … from uid: 10962. pid: 20308
   ```
   and `co.tdevs.duplika` is uid **10962** in the debug host build, **10963** in the
   release host build (`cmd package list packages -U`).

2. **The guest reports a different UID to itself.** Inside the container:
   `Duplika.GMS.UID: hostUid=10001`. The engine virtualizes `Process.myUid()`. (For
   reference, uid 10001 on this device really belongs to
   `com.google.android.overlay.gmsconfig.gsa` — the value is engine-supplied, not the
   guest's own.)

3. **The GMS process saw the host UID.** Play services' own broker logged the guest's
   binds:
   ```
   BoundBrokerSvc: onBind: Intent { act=com.google.android.gms.auth.api.signin.service.START
       cmp=com.google.android.gms/.chimera.GmsApiService mCallingUid=10962 }
   ```
   and `mCallingUid=10963` under the release host. Reproduced across both host builds.

4. **The client claims the guest package name.** The Play services client library sends
   `context.getPackageName()`, which inside the container is
   `com.example.duplikaladder.level9gms`.

5. **The host PackageManager does not associate that package with that UID.** uid
   10962/10963 owns `co.tdevs.duplika` and nothing else.

So GMS is handed the pair *(uid 10962, package `com.example.duplikaladder.level9gms`)*,
which is not a valid pairing on this device.

### The inference (this is why it is strong evidence, not confirmed fact)

GMS's internal caller-verification code was not instrumented, so "the mismatch in (5) is
what produces `DEVELOPER_ERROR`" remains an inference — a well-supported one, since
`DEVELOPER_ERROR` on a `GoogleApi` connect is the documented outcome for a client GMS
cannot validate, the transport underneath is proven working (Test C binds and receives
`IGmsServiceBroker` in every run), and availability now passes.

**Classification: strong evidence.**

### Why no PackageManager change can fix this

**Confirmed fact, architectural.** The engine's `IPackageManagerProxy` hooks run *inside
the guest process*. GMS resolves the caller *inside its own process* (pid 9797), against
the real host `PackageManager`, using the UID the kernel gives it over Binder. There is no
hook point in this architecture that can alter what the GMS process observes about the
caller. This is consistent with the measured outcome: package visibility was fixed, and
Test D was completely unmoved by it.

Closing it would require making the GMS process believe host UID 10962 owns the guest's
package name — caller-identity spoofing toward Google, which is on the forbidden list.
**Test D is therefore reclassified from FAIL to BLOCKED BY DESIGN.** It is not a defect
awaiting a fix; it is the boundary this project has chosen not to cross.

Evidence: `gms-caller-identity.log`, `debug-gms-client.log`, `release-gms-client.log`.

---

## Finding 3 — one fabrication was removed, and it was upstream's

**Confirmed fact.** The stale `com.android.vending` version `33.8.16-21` seen pre-fix was
not a virtualization artefact or a caching bug. It was a hardcoded
`createFakeGooglePlayServicesPackageInfo()` in upstream Bcore's `IPackageManagerProxy`,
returned unconditionally for `com.android.vending`, carrying an invented version *and* an
invented `uid = 10001`. The applied patch deletes it. The guest now reports the device's
real `53.0.27-34`.

---

## Finding 4 — GMS provisioning now shadows the fix

**Confirmed fact (code path), strong evidence (consequence).** Each hook consults the
container first and only falls back to the host. So in a container where Play services has
been *provisioned*, `BPackageManager` answers and the host is never consulted — the
container's own broken copy wins, and the pre-fix `SERVICE_INVALID(9)` /
`current_config.fb: ENOENT` Chimera failure returns.

The two mechanisms are mutually exclusive per container, and provisioning is the one that
wins. See `provisioning-review.md`.

---

## Confidence summary

| Claim | Confidence |
| --- | --- |
| Package visibility incoherence is fixed; A/B/E pass in a guest | **CONFIRMED FACT** |
| Guest-visible GMS metadata is byte-identical to the host | **CONFIRMED FACT** |
| Intent resolution and `bindService` still work (no regression) | **CONFIRMED FACT** |
| The guest process runs as the host app UID, and GMS observes that UID | **CONFIRMED FACT** |
| The upstream fabricated `PackageInfo` is gone | **CONFIRMED FACT** |
| Test D's `DEVELOPER_ERROR` is caused by the (uid, package) mismatch | **STRONG EVIDENCE** |
| No PackageManager-layer change can fix Test D | **CONFIRMED FACT** (architectural) |
| Provisioning shadows passthrough in a provisioned container | **CONFIRMED FACT** (code path) |
| The exact GMS internal check returning `DEVELOPER_ERROR` | **UNKNOWN** (not instrumented) |
| Whether any real-world Google-dependent app works end-to-end | **UNKNOWN** — not tested; needs owner approval (Phase 7) |
| Whether Google sign-in works in a clone | **UNKNOWN** — never tested, never attempted |
