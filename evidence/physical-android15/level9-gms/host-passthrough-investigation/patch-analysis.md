# Patch analysis — GMS host passthrough

Analysed before deciding to keep the change. Two patches are involved and they are **not
the same patch**; the distinction is the main finding of this phase.

| File | State |
| --- | --- |
| `engine-patches/deferred/0002-gms-passthrough-to-host.patch.superseded` | **Rejected.** Never applied. Renamed `.superseded`. |
| `engine-patches/0002-host-platform-package-visibility.patch` | **Applied.** In the shipped `bcore.aar`. |

## Why the deferred patch was rejected

The deferred patch added `com.google.android.gms`, `com.google.android.gsf` and
`com.android.vending` to `AppSystemEnv.sSystemPackages` — the engine's existing
"open package" list.

That list is the problem. `isOpenPackage()` is read by **two** proxies:

- `IPackageManagerProxy` — package visibility, which is what the fix needs;
- `IActivityManagerProxy` — service binding, which the fix does **not** need.

Level 9 diagnostics had already established (Finding 2 in `../root-cause-analysis.md`)
that intent resolution and `bindService` to the host's real GMS **already work** from a
guest. Putting these three packages into `sSystemPackages` would therefore have changed
the service-bind path that was already proven healthy, to fix a problem that lives
entirely in package visibility. That is a wider blast radius than the defect justifies, so
the patch was replaced rather than applied.

## What the applied patch actually changes

### Modified files

| File | Change |
| --- | --- |
| `Bcore/.../core/env/AppSystemEnv.java` | Adds a new list `sHostPlatformPackages` + `isHostPlatformPackage()` and `isVisibleHostPackage()` (String and ComponentName overloads). `sSystemPackages` is **untouched**. |
| `Bcore/.../fake/service/IPackageManagerProxy.java` | Swaps `isOpenPackage(...)` → `isVisibleHostPackage(...)` at 7 fallback sites, and **deletes** an upstream hardcoded fake `PackageInfo`. |

### Modified classes / methods

`isVisibleHostPackage` is consulted at exactly these 7 hook sites, all inside
`IPackageManagerProxy`:

1. `GetPackageInfo`
2. `GetApplicationInfo`
3. `GetActivityInfo`
4. `GetServiceInfo`
5. `GetReceiverInfo`
6. `GetProviderInfo`
7. `getComponentEnabledSetting`

Verified against the shipped binary, not just the patch text:

```
$ javap -p AppSystemEnv       -> isHostPlatformPackage, isVisibleHostPackage present
$ javap -c IPackageManagerProxy*  -> "isVisibleHostPackage" referenced 7 times
```

### The control flow at each site

Unchanged in shape — only the predicate on the fallback branch is wider:

```java
info = BlackBoxCore.getBPackageManager().get…Info(…);  // container first
if (info != null) return info;                          // container wins
if (AppSystemEnv.isVisibleHostPackage(name))            // NEW: also host-platform pkgs
    return method.invoke(who, args);                    // host PM answers verbatim
return null;
```

Two consequences worth stating explicitly:

- **The container still takes precedence.** The host is only consulted when the container
  has no answer. This is what makes the GMS-provisioning feature and this patch collide
  (see `provisioning-review.md`).
- **The host's answer is returned verbatim** — `method.invoke(who, args)` is the real
  binder call to the real `IPackageManager`. Nothing is constructed, edited, or filtered
  on the way back.

### Legacy removal — a fabrication that was there before

The patch deletes this upstream method and its call site:

```java
private PackageInfo createFakeGooglePlayServicesPackageInfo() {
    packageInfo.versionName = "33.8.16-21";
    packageInfo.versionCode = 83381621;
    appInfo.uid = 10001;
    …
}
```

Upstream answered `getPackageInfo("com.android.vending")` with this hardcoded object —
which is why the pre-fix diagnostics saw the Play Store reported as **33.8.16-21** on a
device whose real Play Store is **53.0.27-34**. So the applied patch *removes* invented
metadata; it does not add any. Confirmed absent from the shipped `bcore.aar`
(no `33.8.16-21` / `createFakeGooglePlayServices` string in any `IPackageManagerProxy`
class).

## APIs affected — measured, not assumed

The Phase 1 brief listed candidate APIs. Only these are actually touched:

| API | Affected? |
| --- | --- |
| `getPackageInfo` | **YES** — host fallback added |
| `getApplicationInfo` | **YES** — host fallback added |
| `getActivityInfo` / `getServiceInfo` / `getReceiverInfo` / `getProviderInfo` | **YES** — host fallback added |
| `getComponentEnabledSetting` | **YES** — host fallback added |
| `getApplicationEnabledSetting` | **NO** — not in the patch. It already returned `0`; that inconsistency was a *symptom*, and this API is not modified. |
| `getInstalledPackages` | **NO** — still container-only |
| `getInstalledApplications` | **NO** — still container-only |
| `getPackageArchiveInfo` | **NO** — not hooked by this patch |
| `resolveActivity` / `resolveService` | **NO** |
| `queryIntentActivities` / `queryIntentServices` | **NO** — these already resolved before the fix |
| `getPackageUid` / `getPackagesForUid` | **NO** |

The last row matters for interpreting the residual Test D failure: the patch changes
nothing about UID→package mapping.

## Enumeration is not widened

`getInstalledPackages` and `getInstalledApplications` are not in the patch, so a guest
still enumerates only its own container. The change is strictly *by-name*: a guest that
asks about one of three named platform packages gets a real answer. A guest that asks
"what is installed on this device?" gets the same container-only list as before.

## Package scope, and why it is a list at all

Three entries: `com.google.android.gms`, `com.google.android.gsf`, `com.android.vending`.

The Phase 3 rule forbids third-party app-specific branching, and this patch contains
none — there is no `if (packageName == "some.third.party.app")` anywhere. The filtering
that does exist is on *platform dependency* packages, not on applications. The
justification for keeping it a list rather than "consult the host for anything" is
containment: an unrestricted host fallback would let a guest probe the presence of every
package on the device by name, which is a privacy regression and is not needed to fix the
defect. The engine already maintains exactly this kind of list for WebView
(`sSystemPackages` holds `com.google.android.webview` and friends) for the same reason.
