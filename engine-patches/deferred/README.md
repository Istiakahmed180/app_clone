# Deferred engine patches

Patches that are written and compile, but are NOT applied to the vendored
`android/app/libs/bcore.aar`. `build-engine.sh` ignores this folder.

## 0002 — GMS passthrough to the host — **SUPERSEDED, do not apply**

File: `0002-gms-passthrough-to-host.patch.superseded`

**What it did.** Added `com.google.android.gms`, `com.google.android.gsf` and
`com.android.vending` to `AppSystemEnv.sSystemPackages`, the engine's "open package"
whitelist.

**Why it was rejected.** `sSystemPackages` is consulted by *two* proxies:
`IPackageManagerProxy` (package visibility) **and** `IActivityManagerProxy` (service binds).
Level 9 diagnostics on the CPH2605 established that intent resolution and `bindService` to
the host's real Play services **already worked** from a guest — the defect was entirely in
package visibility. Routing service binds through `isOpenPackage()` as well would have
changed a proven-healthy path to fix a problem that does not live there.

**What replaced it.** `engine-patches/0002-host-platform-package-visibility.patch`, which
introduces a separate `sHostPlatformPackages` list read *only* by `IPackageManagerProxy`,
and additionally deletes an upstream hardcoded fake `PackageInfo` for `com.android.vending`.
That patch is applied, and is verified on device in both debug and minified release. See
`engine-patches/README.md` and
`evidence/physical-android15/level9-gms/host-passthrough-investigation/`.

**Kept for the record only.** It documents the route considered and the reason it was not
taken. Do not move it back up into `engine-patches/`; doing so would conflict with the
applied patch and widen the change beyond what the diagnostics justify.
