# Architecture — Phase 2

## Layering

```
Flutter UI (Material 3)
        │
      GetX controllers
        │
  VirtualizationEngine          <- abstraction, unchanged since Phase 1
        │
   ┌────┴─────────────────┐
   │                      │
RealVirtualizationEngine  DemoVirtualizationEngine (reference no-op)
   │
NativeBridge (Dart)  ──── MethodChannel "virtual_space/native_bridge" ────┐
                                                                          │
                                                     NativeBridge (Kotlin)│
                                                                          │
                                                  RealVirtualizationEngine (Kotlin)
                                                     │
                        ┌────────────────────────────┼───────────────────────┐
                  VirtualProfileManager      VirtualAppInstaller     VirtualAppLauncher
                                                     │
                                        AppSecurityChecker (admission)
                                                     │
                                     VirtualizationEngineAdapter   <- the swap point
                                                     │
                                          BlackBoxEngineAdapter
                                                     │
                                            NewBlackbox / Bcore
                                                     │
                                            Virtual Test App
```

## The replaceability rule

`VirtualizationEngineAdapter` is the boundary. **Exactly one file** in the project may import
`top.niunaijun.*`: `native/blackbox/BlackBoxEngineAdapter.kt`. Everything above it speaks in
package names and integer `virtualUserId`s, which every container engine exposes in some form.

Swapping backends means writing one new adapter and changing one line in
`DuplikaApplication.engine`.

## Why the engine is a prebuilt AAR

Bcore's Gradle scripts use `lintOptions`, `packagingOptions` and `aidlPackagedList`, all of
which predate AGP 9, and it compiles AIDL and ndkBuild sources. This project runs AGP 9.0.1 /
Gradle 9.1.0, so including Bcore as a source subproject would have forced either a project-wide
AGP downgrade or a fork of its build scripts.

Building Bcore once with its own toolchain and consuming the resulting AAR avoids both. The AAR
already contains the compiled AIDL, resources and `libblackbox.so`, and AAR consumption is
insensitive to the producing AGP version. This is also the integration path NewBlackbox
documents.

Reproduction steps are in `VIRTUALIZATION_ENGINE.md`.

## Host process model

The engine adds stub processes (`:p0` … `:pN`) and a `:black` service process to the host
manifest. The host `Application` class is instantiated in **all** of them, so
`DuplikaApplication` does engine attachment first and keeps everything else out of
`attachBaseContext`.

A guest app runs in one of those stub processes under the **host's** UID — not its own. That is
what makes the isolation real and also what bounds it: guests share the host's UID and
permission grants.

## Profile identity

Two ids exist and must not be conflated:

| Id | Owner | Purpose |
| --- | --- | --- |
| `VirtualProfileModel.id` (UUID) | Flutter repository | Stable user-facing profile identity |
| `virtualUserId` (int) | Native `VirtualProfileManager` | The engine's container id |

The mapping is owned **natively**, in its own `SharedPreferences` file. If Flutter and the
engine disagreed about this mapping, a profile could silently open another profile's data —
so the engine's own view is treated as authoritative.

## Consistency rules

- **Create**: metadata is written first (the engine needs a stable id), then the container is
  installed. If the install fails, the metadata is rolled back and the mapping released, so a
  profile is never shown as ready for a container that does not exist.
- **Delete**: the container is released first, then the metadata. If the engine fails, the
  profile stays visible so the user can retry rather than losing track of orphaned data.
- **Rename**: metadata only. Containers are keyed by profile id, so a rename cannot touch
  application data. This is asserted by a test.
- **Status**: `installed` / `running` are read back from the engine per profile. The UI never
  infers "Ready" from the existence of a row.
