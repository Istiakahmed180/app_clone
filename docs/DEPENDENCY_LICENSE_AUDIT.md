# Dependency and Licence Audit — Phase 2

Audited on 2026-09-05 against the artefacts actually vendored into this build. Everything
below was read from the source tree or the resolved POMs, not from project marketing text.

## Direct dependencies introduced by Phase 2

| Dependency | Version / Commit | Licence | Source | How it is used | Redistribution requirements |
| --- | --- | --- | --- | --- | --- |
| NewBlackbox `Bcore` | commit `89b59836c66f173756a4ae258cf379a957649820` (2026-07-19) | Apache-2.0 (`LICENSE` at repo root) | https://github.com/ALEX5402/NewBlackbox | The virtualization engine. Built from source to `android/app/libs/bcore.aar` and consumed as a prebuilt AAR. | Retain `LICENSE`, state changes made, include NOTICE if shipped. Licence copy kept at `android/app/libs/LICENSE-NewBlackbox-Apache-2.0.txt`. |
| NewBlackbox `black-reflection` | same commit | Apache-2.0 (repo licence) | same repository | Reflection helper Bcore compiles against. Vendored as `android/app/libs/black-reflection.jar`. | As above. |
| FreeReflection | 3.2.2 | MIT (verified in POM) | `com.github.tiann:FreeReflection` via JitPack | Bcore runtime dependency for hidden-API access. | Retain copyright and MIT notice. |
| toml4j | 0.7.2 | MIT (verified in POM) | Maven Central | Bcore configuration parsing. | Retain copyright and MIT notice. |

`androidx.appcompat`, `com.google.android.material` — Apache-2.0, already normal Android
dependencies.

## Transitively bundled native components (inside Bcore)

These are compiled into `libblackbox.so`; they are not separate Gradle dependencies.

| Component | Upstream licence | Location in source | Finding |
| --- | --- | --- | --- |
| Dobby | Apache-2.0 upstream | `Bcore/src/main/cpp/Dobby` | **No licence header present** in the vendored copy inspected. |
| xDL | MIT upstream | `Bcore/src/main/cpp/xdl` | **Licence header appears stripped** — `xdl.c` begins with ~22 blank lines where the upstream MIT notice normally sits. |
| JniHook / Hook / Utils | Not stated | `Bcore/src/main/cpp/*` | No licence headers found. |

## Findings and open risks

1. **Stripped attribution in vendored native code (must resolve before any distribution).**
   The MIT licence for xDL and the Apache-2.0 licence for Dobby both require their notices to
   travel with the code. The copies inside Bcore do not carry them. Virtual Space did not remove
   these notices — they were already absent upstream — but shipping this build would still
   redistribute them without attribution. Before release, restore the upstream notices in a
   `NOTICE` file listing Dobby, xDL, FreeReflection, toml4j and VirtualApp/VirtualAPK.

2. **VirtualApp / VirtualAPK ancestry — since traced, and the result is worse than "unverified".**

   The chain was followed to its sources:

   - `asLody/VirtualApp` carries **no LICENSE file**, and its README states that commercial
     authorisation must be purchased ("请购买商业授权"), that the technology belongs to a named
     company, and that unauthorised internal, commercial or app-store use will be met with
     prosecution for copyright infringement. It is proprietary, not open source.
   - `FBlackBox/BlackBox` (the origin of the `top.niunaijun.blackbox` namespace used here)
     carries **no LICENSE file either** — the GitHub API reports `license: null` and no licence
     file exists at the repository root. The original `niunaijun/BlackBox` repository now
     returns 404; a surviving fork's README says the author deleted the project.
   - Bcore's Java sources carry **no copyright headers at all**.

   NewBlackbox nonetheless declares Apache-2.0 for the whole repository. On this evidence that
   is a licence it was very likely not in a position to grant, which means the Apache-2.0 text
   shipped in `android/app/libs/` may not confer the rights it appears to.

   **This is not legal advice and should be confirmed by a lawyer.** But it is no longer an
   open question of fact: the upstream projects are unlicensed or expressly commercial.

   *(Superseded note, kept for history)* **VirtualApp / VirtualAPK ancestry was unverified.** NewBlackbox's README credits
   "Original Framework: VirtualApp, VirtualAPK". Some historical VirtualApp releases were
   published under GPL-3.0 before later commercial relicensing. NewBlackbox declares Apache-2.0
   for the whole repository, but **that declaration has not been traced back to the origin of
   each derived file.** If any Bcore file descends from a GPL-3.0 VirtualApp revision, the
   Apache-2.0 declaration would not be sufficient and Virtual Space could inherit copyleft
   obligations. This is the single largest legal risk in Phase 2 and is unresolved.

3. **JitPack in the build.** FreeReflection resolves from `jitpack.io`, which builds artefacts
   from a Git tag rather than serving a signed, immutable release. The version is pinned to
   3.2.2. Consider vendoring the artefact so builds do not depend on a third-party build service.

4. **No runtime code download.** The engine, its native libraries and all dependencies are
   part of the APK. Nothing executable is fetched at runtime, in line with the Phase 2 rules.

## Recommendation

Do not distribute this build publicly until findings 1 and 2 are closed. For internal
development and testing the current state is workable, and the
`VirtualizationEngineAdapter` boundary means the backend can be replaced if the provenance
question cannot be resolved.
