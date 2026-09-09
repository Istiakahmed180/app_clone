# Patch 0006 validation — UserManager application restrictions, API 35

Device: OnePlus CPH2605, Android 15 / API 35 / arm64-v8a, `KNOJORMFV4GERKHM`, 2026-09-09.
Probe: `compatibility_test_ladder/usermanagerprobe` — zero dependencies, identical APK in
every cell, always asks about its **own** package.

## Bcore artifact

| | sha256 | bytes |
| --- | --- | --- |
| before (pre-0006) | `0178aa0b0fe23aec77fb1ef13bab04f981f4d146297c211ccc151a7f45076770` | 2 102 254 |
| **after (with 0006)** | **`d9b7f36b094eab00c514ecb002371eec6af70154fd3f4cb6a50ce0be328f8175`** | 2 093 182 |

Upstream commit `89b59836c66f173756a4ae258cf379a957649820`, NDK 29.0.13846066, JDK 17,
built by `engine-patches/build-engine.sh` with all six patches applied.

Verified in the produced binary:
```
RuntimeVisibleAnnotations:
  top.niunaijun.blackbox.fake.hook.ProxyMethods(
    value=["getApplicationRestrictions","getApplicationRestrictionsForUser"])
```
Hook body unchanged — still `getHostPkg()` → `aastore` (args[0]) → `Method.invoke` → return.
Both ABIs (`arm64-v8a`, `armeabi-v7a`) present.

## Required matrix — ALL PASS

| Cell | P1 `getApplicationRestrictions(own pkg)` | P2 `getUserRestrictions()` | P3 `isSystemUser()` |
| --- | --- | --- | --- |
| Host Debug | **SUCCESS** 2 ms, keyCount=0 | SUCCESS keyCount=1 | SUCCESS |
| Host Release (minified) | **SUCCESS** 1 ms, keyCount=0 | SUCCESS keyCount=1 | SUCCESS |
| Guest Debug (virtual user 3) | **SUCCESS** 1 ms, keyCount=0 | SUCCESS keyCount=1 | SUCCESS |
| Guest Release (virtual user 4, minified) | **SUCCESS** 1 ms, keyCount=0 | SUCCESS keyCount=1 | SUCCESS |

Both guest cells used a **fresh virtual user** created after the patched engine was installed.

## Before vs after, guest

| | P1 result |
| --- | --- |
| before | `SecurityException: Only system may: get application restrictions for other user/app com.example.duplikaladder.umprobe` |
| **after** | **SUCCESS — `bundleNull=false keyCount=0`** |

## Security checks required by the task

| Check | Result |
| --- | --- |
| Guest returns SUCCESS rather than SecurityException | **yes** |
| `getUserRestrictions()` still succeeds | **yes**, keyCount=1, all four cells |
| `isSystemUser()` still succeeds | **yes**, all four cells |
| No other Android user accessed | **yes** — `userId` (arg index 1) is never touched by the hook; only arg[0], the package name, is rewritten |
| No cross-app restriction data exposed | **yes** — the returned Bundle is **empty** (`keyCount=0`), identical to what the host returns; the rewritten package is the container owner's, which the calling UID genuinely owns |

The empty Bundle is the expected answer on this device: there is no managed profile, so no
restrictions are set for anyone. The guest now receives exactly what the host receives.

## Chrome — still blocked, separate issue

Chrome was attempted only after the probe matrix passed, on a fresh clone (virtual user 5)
with the patched engine:

```
Starting com.android.chrome in virtual user 5
Rebuilding the container for com.android.chrome before a second launch attempt
Launch of com.android.chrome failed after a rebuild:
    The engine refused to launch the virtual application.
```

`grep -c "Only system may: get application restrictions"` → **0**, but that is **not**
evidence the fix helps Chrome: Chrome never reaches that call because it never starts.
**Chrome is NOT fixed by this patch**, and no such claim is made. Issue (B), the 6-way
split-APK launch refusal, is untouched and remains open.
