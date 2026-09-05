# Security Posture — Phase 2

## What Virtual Space deliberately does not do

The engine is used strictly as an application-level container. None of the following is
implemented, and none should be added without an explicit decision recorded here:

- root exploitation, SELinux bypass, signature-verification bypass
- Play Integrity / SafetyNet / anti-cheat / DRM bypass
- certificate-pinning bypass
- credential, cookie, token or private-app-data extraction
- stealth execution or hiding the container from the apps running inside it
- screenshot or `FLAG_SECURE` defeat

### Backend options pinned by Virtual Space

The backend exposes switches that would weaken this posture. `BlackBoxEngineAdapter`
pins them explicitly rather than accepting defaults:

| Option | Value | Reason |
| --- | --- | --- |
| `isDisableFlagSecure` | `false` | An app's `FLAG_SECURE` must keep working inside the container. |
| `isHideRoot` | `false` | No concealment of device state from the guest app. |
| `isUseVpnNetwork` | `false` | No traffic interception. |
| `isEnableDaemonService` | `false` | No background persistence beyond what the user starts. |
| `isEnableLauncherActivity` | `false` | The host UI is the only entry point. |

## REQUIRE_SECURE_ENV

Google requires on-device Android containers to honour an application's declaration that it
must not be virtualized. Virtual Space treats that declaration as binding.

`AppSecurityChecker` runs **before** any install into a container. If the target declares the
requirement, installation is rejected with `SECURE_ENV_REQUIRED` and no virtual user is created.

There is deliberately **no override, no manifest rewriting, no APK downgrade and no
environment spoofing** to defeat this flag.

### The property name — now confirmed by a real app

`REQUIRE_SECURE_ENV` is a Play-policy manifest declaration, not a platform SDK constant (it is
absent from `android.jar` on API 35, 36 and 37, checked directly). The name was previously a
guess. It no longer is.

**Google Authenticator ships it**, verified independently with `aapt2 dump xmltree`:

```
E: property (line=48)
  A: android:name="REQUIRE_SECURE_ENV"
  A: android:value=1
```

So the bare `REQUIRE_SECURE_ENV` is the real name. The two fully-qualified variants are kept in
the candidate list as cheap insurance.

### Two bugs this real-world case exposed

Both were found by testing against Authenticator rather than against fixtures alone:

1. **`<property>` was unreadable for an uninstalled APK.** `getProperty()` answers only for
   installed packages, so an imported APK declaring the requirement was admitted. Closed by
   `ApkManifestReader`, which decodes the archive's own compiled manifest.

2. **The installed path missed it too — the more serious of the two,** because it is the path
   the picker uses. The check required `Property.isBoolean`, but `android:value="true"` is
   compiled to the **integer 1**. Authenticator was therefore offered for cloning, verdict
   "Limited". The check now accepts boolean, integer and string encodings, and Authenticator
   is refused with `SECURE_ENV_REQUIRED` and a disabled "Cannot clone" button.

The check remains fail-closed, is applied to both installed apps and imported APKs, and has no
override path.

## Data boundaries

- Virtual Space never reads `/data/data/com.example.virtualtestapp` — the normally installed
  app's private directory. Only the package *identity* is passed to the engine, which resolves
  the APK through the platform's own `PackageManager`.
- Container data lives under the host's own sandbox at
  `/data/data/com.example.virtualspacedemo/blackbox/data/user/<virtualUserId>/`.
- Logging (`Slog`) records package names, profile ids and engine status only. Target
  application data, credentials and tokens are never logged.

## Package visibility

**Changed in Phase 3.** Cloning arbitrary apps requires enumerating them, and on Android 11+
`QUERY_ALL_PACKAGES` is the only way to do that. It is now requested.

This is a Play-policy-sensitive permission. A dual-app/cloning product is one of Google's
permitted use cases, but the declaration must be justified at review. Virtual Space uses it for
exactly one purpose — listing launchable apps for the clone picker — and never to inspect
another application's private data.

`InstalledAppsProvider` reads only what a launcher already sees: label, package name, icon and
version. Nothing else is collected.

Note that merging the engine AAR adds ~322 `uses-permission` entries and ~152 stub activities
to the host manifest — these come from the engine and are what allow guest apps to run. This
is a real distribution consideration: the permission list is large and will need review before
any store submission.

## Scope limit

**Changed in Phase 3.** The single-package allow-list is gone; arbitrary installed apps and
imported APKs may be cloned. The policy is now a deny-list plus the secure-environment rule:

- Virtual Space refuses to clone **itself** (it would recurse).
- It refuses **system/framework packages** (`android`, `com.android.systemui`,
  `com.android.settings`, `com.android.providers.*`) — cloning these yields a broken container.
- `REQUIRE_SECURE_ENV` rejection is unchanged. For an **installed** app it is read through
  `PackageManager.getProperty()` and application meta-data. For an **imported APK** it is read
  from the archive's application meta-data via `getPackageArchiveInfo(..., GET_META_DATA)`
  before the engine sees the file, and the installed declaration is honoured as well when the
  same package happens to be installed.

  **The `<property>` gap is now closed.** `PackageManager.getProperty()` answers only for
  installed packages, so an APK declaring the requirement solely as a `<property>` element used
  to be unscreenable. `ApkManifestReader` now decodes the archive's own compiled
  `AndroidManifest.xml` and reads both `<meta-data>` and `<property>` declarations directly, so
  an imported APK is screened whether or not it is installed. Both sources are consulted; a
  parse failure is treated as *no declaration found*, never as a pass.

  Proven, not assumed: `ApkManifestReaderTest` uses a purpose-built ~750-byte APK that really
  declares `<property android:name="REQUIRE_SECURE_ENV" android:value="true"/>`, and asserts
  both that the reader finds it and that `checkApk` rejects it with `SECURE_ENV_REQUIRED`.
  Without such a fixture a reader that always answered "not declared" would have passed every
  other test.

  There is still no override path for a declaration that is detected.

Banking, payment, authenticator, anti-cheat and Play-Integrity-dependent apps were deliberately
**not** tested and remain outside what this build can be said to support. Nothing prevents a
user from attempting them; nothing claims they will work.
