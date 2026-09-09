# Security review — `0002-host-platform-package-visibility.patch`

Reviewed against the Phase 1 stop-conditions. Every answer below is derived from the patch
text and from the shipped `bcore.aar`, and cross-checked against what the device actually
reported.

## Stop-condition checklist

| Question | Answer | Basis |
| --- | --- | --- |
| Changes signatures? | **NO** | The patch never touches a `Signature`/`SigningInfo` object. `GET_SIGNATURES` / `GET_SIGNING_CERTIFICATES` requests fall through to the real host `IPackageManager`, so the certificate history returned is Google's own. |
| Changes certificates? | **NO** | Same path. Guest-observed GMS cert sha256 values are byte-identical to the host control: `f0fd6c5b…`, `7ce83c1b…`, `5f239127…`. |
| Changes Google account identity? | **NO** | No `AccountManager` code in the patch. Test F measured `accountsByType("com.google") count=0, fabricatedAccountObserved=false` in every guest run. |
| Changes authentication? | **NO** | No auth code path is touched. No test in this investigation authenticated, and none was made to succeed. |
| Changes Play Integrity? | **NO** | Nothing in the patch touches attestation, and the guest's caller identity is *unchanged* — GMS still sees the Duplika host UID (see below), which is exactly why an integrity verdict for a virtualized caller would still fail. |
| Changes device identity? | **NO** | No `Build`, fingerprint, or device-property code in the patch. |
| Changes UID identity? | **NO** | `getPackageUid` and `getPackagesForUid` are not in the patch. Confirmed on device: GMS observed `mCallingUid=10962` (debug host) / `10963` (release host) for the guest's binds — the real host UID, unspoofed. |
| Changes permissions? | **NO** | No permission API is hooked by this patch. No `SecurityException` and no permission grant/denial change was observed. |
| Contains spoofing? | **NO — it removes some.** The patch *deletes* upstream's `createFakeGooglePlayServicesPackageInfo()`, which fabricated Play Store version `33.8.16-21` and `uid = 10001`. |
| Contains application-specific hacks? | **NO** | No third-party package name appears. The three entries are platform dependency packages (Play services, GSF, Play Store), handled generically. |

**Verdict: no stop-condition triggered. Safe to keep.**

## Explicit statements requested by Phase 11

- Signature spoofing: **NO**
- Certificate spoofing: **NO**
- Account spoofing: **NO**
- Play Integrity bypass: **NO**
- Authentication bypass: **NO**

## Why "the guest can now see Play services" is not a bypass

The change makes a *true* statement true. The device genuinely has Google Play services
26.32.34 installed and enabled. Before the patch the virtualized `PackageManager` answered
`getPackageInfo("com.google.android.gms")` with `NameNotFoundException` while, in the same
process microseconds later, `getApplicationEnabledSetting` for the same package returned
`0` (enabled) — and `com.android.vending` was reported at a fabricated version that did not
match the device. The patch replaces incoherent and partly invented answers with the host's
real ones.

What it does **not** do is make the guest look like something it is not:

- the guest's Binder calling identity is untouched — GMS sees the Duplika host UID;
- no certificate, account, or device property is altered;
- `GoogleApiAvailability` now returns `SUCCESS(0)` because Play services genuinely *is*
  present and reachable, not because a check was defeated.

The one Google-side check that does still reject the guest — the `GoogleApi` client
connection, `DEVELOPER_ERROR` — rejects it **because** the caller identity was not spoofed.
Making that test pass would require convincing the GMS process that the host UID owns the
guest's package name. That is caller-identity spoofing, it is on the forbidden list, and it
was not attempted. See `root-cause-analysis.md`.

## Residual risk accepted

- **Version/enabled-state disclosure.** A guest can learn the real version and enabled
  state of three named Google packages. This is information any app on the host can read
  with a `<queries>` declaration, so it is not a privilege gain — but it is strictly more
  than the container disclosed before.
- **No enumeration change.** `getInstalledPackages` / `getInstalledApplications` remain
  container-only, so the guest cannot sweep the host's app list.
- **Play Integrity remains failed for virtualized callers, by design.** Nothing here is
  intended to change that, and the caller-identity evidence shows it has not.
