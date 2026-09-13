# microG integration — investigated, and parked

Status: **PARKED — the path is blocked by signature verification.** Implemented on branch
`spike/microg-provider` (commit `f9fb159`), not merged. This document is what that commit
referred to as `docs/microg-integration.md`; it was referenced before it was committed, and
is written here so the measurement is not lost with the branch.

The main branch ships **no** microG: `MicroGProvider` remains the architectural placeholder
described in `docs/level10-gms-provider-architecture.md` — always `NOT_IMPLEMENTED`, no
capabilities, every operation refused. Nothing in this document is current behaviour. It
records an experiment and why it was stopped.

## What the spike attempted

Provision a **bundled** microG artefact into a guest container as that guest's
`com.google.android.gms`, so a cloned app's Google client libraries bind a container-local
Google-services implementation instead of the host's Play services — the route that would,
in principle, reach Google/Firebase sign-in without the caller-identity refusal documented
in `docs/level10-gms-caller-identity-boundary.md`.

It was a real implementation, not a sketch:

| File (on the spike branch) | Role |
| --- | --- |
| `native/gms/MicroGProvider.kt` | Real detection of the bundled artefact; `CONTAINER_MICROG_PROVISIONING` only when an artefact is present; host-GMS operations permanently refused |
| `native/gms/MicroGArtifact.kt` | The artefact's identity (`com.google.android.gms`, version, APK asset names) and the `MicroGArtifactSource` seam |
| `native/AssetMicroGArtifactSource.kt` | Reads the artefact out of the APK's own `assets/microg/` — base APK first |

Bundling is required because microG's package name is `com.google.android.gms`: on any device
that has Google's Play services that name is already taken, so microG can only be installed
**inside a container**. microG is Apache-2.0, so bundling carries an attribution obligation
(goes in the root `NOTICE`) and no distribution restriction — a separate question from the
engine provenance issue in `docs/DEPENDENCY_LICENSE_AUDIT.md`.

The spike compiled and its provider-layer tests passed (29 Kotlin unit tests, 12 of them
new). That is not why it was parked.

## Why it is parked — three measured findings

### 1. Admission blocked by Duplika's own policy

`AppSecurityChecker` refuses microG. Its package name is `com.google.android.gms`, and the
real installed Play services declares `REQUIRE_SECURE_ENV=1`, which `checkApk` honours for
an installed package of the same name. Duplika's own rule — refuse anything declaring that
requirement, with no override (`docs/SECURITY.md`) — works exactly as designed and stops the
artefact at the door.

### 2. Signature blocked — and this is the wall

Guest apps verify their Google-services implementation with
`GoogleSignatureVerifier.isGooglePublicSignedPackage` (via the
`com.google.android.gms` signature check baked into the Google client libraries). microG's
**real, honest** certificate fails that check — with both control columns (a genuine Google
app, and microG) behaving correctly. A guest using Google's client libraries therefore
rejects an honestly-signed microG no matter how the container routes the call.

The two ways past it are **presenting Google's certificate** or **copying its signature
block**. Both are signature spoofing or forgery, and both are forbidden by
`docs/SECURITY.md`.

### 3. Routing was never the problem (worth keeping)

One negative result is useful: **no engine change is needed for a container-side GMS to be
found.** `IPackageManagerProxy` asks the container first on every hooked method and only
falls through to the host platform packages when the container has no answer, so patch 0002
does not shadow a provisioned copy. The artifact is discoverable; it is not *trusted*.

## What would have to change to revive this

Either of these, and both are product/legal decisions, not bugs:

1. **An explicit decision to present Google's certificate to guests** — signature spoofing,
   with Play Store consequences, contradicting the project's stated security posture; or
2. **Distribution outside Play**, where the Play consequence does not apply.

Even then, the ceiling from the caller-identity work still holds: whatever is installed at
`com.google.android.gms`, **Play Integrity / SafetyNet still fail** for a virtualized caller.
A build that ships microG is no closer to running a banking or anti-cheat app. microG's own
push and sign-in are partial and Google-side fragile, so it is not a clean fix for FCM
either (`evidence/physical-android15/fcm-cabexfx/`).

## How to look at the spike

```bash
git log --oneline main..spike/microg-provider
git show spike/microg-provider:android/app/src/main/kotlin/co/tdevs/duplika/native/gms/MicroGProvider.kt
```

The branch is parked, not deleted: the provider seam, the artifact source and the tests are
the starting point if the certificate decision above is ever made.
