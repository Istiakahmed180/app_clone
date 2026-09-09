# Level 9 — GMS host passthrough investigation

Device: OnePlus CPH2605, Android 15 / API 35 / arm64-v8a, serial `KNOJORMFV4GERKHM`.
Engine artefact under test: `android/app/libs/bcore.aar`, sha256 `0178aa0b0fe23aec77fb1ef13bab04f981f4d146297c211ccc151a7f45076770`.

## One-paragraph summary

The deferred patch was **rejected**, not applied: it widened the engine's `sSystemPackages`
list, which also governs service binding — a path the Level 9 diagnostics had already proven
healthy. It was replaced by a narrower change, `engine-patches/0002-host-platform-package-visibility.patch`,
which adds a separate list read *only* by `IPackageManagerProxy`. A guest that asks by name
about Play services, GSF, or the Play Store now gets the host PackageManager's own answer,
verbatim; the patch also deletes an upstream hardcoded fake `PackageInfo` that had been
reporting an invented Play Store version. Package detection, Play services availability, and
the Firebase dependency diagnostics went from FAIL/PARTIAL to **PASS** in a guest, in both
debug and minified release. One test still fails, and the reason is the substantive finding:
the `GoogleApi` client connection returns `DEVELOPER_ERROR` because the GMS process sees the
guest's real Binder UID (the Duplika host UID) paired with the guest's own package name, a
pairing the host PackageManager does not recognise. No change at the PackageManager layer can
alter that, and closing it would require caller-identity spoofing toward Google — so it is
recorded as **BLOCKED BY DESIGN**, not as a defect to fix.

## Result

| Test | Debug | Release | Note |
| --- | --- | --- | --- |
| A — GMS package detection | PASS | PASS | was FAIL |
| B — `GoogleApiAvailability` | PASS `SUCCESS(0)` | PASS `SUCCESS(0)` | was `SERVICE_MISSING(1)` |
| C — intent resolution + bind | PASS | PASS | no regression |
| D — GoogleApi client connection | **BLOCKED** | **BLOCKED** | `DEVELOPER_ERROR`; caller identity, not visibility |
| E — Google/Firebase diagnostics | PASS | PASS | was PARTIAL |
| F — no fabricated Google account | PASS | PASS | 0 accounts, none invented |
| G — caller identity coherence | PASS | PASS | self-consistent *inside* the guest only |

Security review: signature spoofing **NO**, certificate spoofing **NO**, account spoofing
**NO**, Play Integrity bypass **NO**, authentication bypass **NO**.

## Documents

| File | Contents |
| --- | --- |
| `patch-analysis.md` | Both patches, why the deferred one was rejected, exact APIs affected |
| `security-review.md` | Stop-condition checklist and residual risk |
| `root-cause-analysis.md` | Findings with confidence levels; the Test D identity boundary |
| `provisioning-review.md` | Phase 9 — where provisioning is used, the conflict, recommendation |
| `regression-matrix.md` | Levels 6/7/8/9, separating verified from not-re-run |

## Logs

Test-surface extracts (Phase 10 naming; `debug`/`release` = diagnostic app build type):

```
debug-package-detection.log     release-package-detection.log
debug-gms-availability.log      release-gms-availability.log
debug-gms-client.log            release-gms-client.log
gms-caller-identity.log         <- the Test D root-cause evidence
```

Full runs from the 2026-09-09 re-verification, named `<host build>-<diagnostic build>`:

```
2026-09-09-reverification/
├── debughost-debugdiag-full.log
├── debughost-releasediag-full.log
├── debughost-releasediag-relaunch.log
├── releasehost-debugdiag-full.log
├── releasehost-releasediag-full.log
└── releasehost-releasediag-relaunch.log
```

Regression:

```
regression-level6-launch.log    regression-level6-actions.log   regression-level6-guest.png
regression-level7.log           regression-level8-markor.log     (both 2026-09-08)
```

From the 2026-09-08 session, against the same engine artefact:

```
debug-host-control.log          release-host-control.log         <- non-virtualized baseline
debug-guest-passthrough.log     release-guest-passthrough.log
debug-guest-relaunch.log        release-guest-relaunch.log
release-guest-passthrough.png
```

## Method

The same diagnostic APK is run twice — installed normally on the host (control), and cloned
into a Duplika container (guest) — so the only difference between the two runs is the
virtualization layer. The diagnostic app has no Duplika dependency.

Clones were created through the ordinary user-facing flow (app picker → Add clone), which
takes the installed-app route and passes `installGms: false`. Every result here is therefore
with **GMS provisioning off**; that was confirmed in the logs for each clone
(`GMS provisioning for user N: requested=false`).

Four combinations were measured — {debug, release} host app × {debug, release} diagnostic app
— plus a full `force-stop` and relaunch on each host build. `isMinifyEnabled = true` was
never turned off.

## Not done

- **Real-world third-party app test — NOT RUN.** Phase 7 requires the owner's approval
  before downloading or testing a new APK. See the final report for recommended categories.
- **Google sign-in / authentication — NEVER TESTED.** No claim is made about it.
- **Play Integrity — NOT TESTED and not targeted.** A virtualized caller should still fail
  it; nothing here attempts to change that.
