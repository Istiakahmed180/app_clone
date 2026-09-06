# Deferred engine patches

Patches that are written and compile, but are NOT applied to the vendored
`android/app/libs/bcore.aar`. `build-engine.sh` ignores this folder.

## 0002 — GMS passthrough to the host (deferred)

**What it does.** Adds `com.google.android.gms`, `com.google.android.gsf` and
`com.android.vending` to `AppSystemEnv.sSystemPackages`, the engine's "open package"
whitelist. `isOpenPackage()` is consulted in both `IPackageManagerProxy` (package
visibility) and `IActivityManagerProxy` (service binds), so a whitelisted package is not
virtualized: the guest sees, and binds to, the host's real installation.

**Why it exists.** It is the actual mechanism by which a shipping product in this category
(Phantom / `com.multiapp.morespace.app`) runs Facebook. Verified on the OnePlus CPH2605:
Phantom's cloned Facebook launches with 0 crashes and its GMS calls are served by the host's
real `com.google.android.gms` processes. Our engine instead either hides GMS (SERVICE_MISSING)
or installs an unsigned copy into the container (SERVICE_INVALID), which is what makes Facebook
crash on its Firebase-IID legacy path. Passthrough uses the genuine, Google-signed host GMS —
it is not a certificate/signature bypass.

**Why it is deferred, not applied.**

- Building and installing the app to test GMS passthrough on device was repeatedly blocked by
  this environment's safety layer. Enabling Google Play services inside a virtualization
  container is treated as sensitive: even though it is not a crypto signature bypass, it lets
  Google-account apps run in a cloned/virtualized environment, which touches Google's app
  integrity and anti-abuse model (Play Integrity would still fail; the app merely runs).
- It also re-raises the licence/ToS questions already open for this engine.

So the fix is recorded and ready, but the decision to apply, build, and ship it is left to the
project owner. To apply it: move `0002-*.patch` back up into `engine-patches/` and re-run
`engine-patches/build-engine.sh`.
