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

### An honest limitation

`REQUIRE_SECURE_ENV` is a Play-policy manifest declaration, not a platform SDK constant — it
is absent from `android.jar` on API 35, 36 and 37, which were checked directly. The checker
therefore probes a defensive list of candidate property names via
`PackageManager.getProperty()` (API 31+) and falls back to application `metaData`:

```
REQUIRE_SECURE_ENV
android.content.pm.REQUIRE_SECURE_ENV
android.app.REQUIRE_SECURE_ENV
```

The check is fail-closed: any positive declaration found through either mechanism rejects the
install. **The canonical property name must be confirmed against Google's published
requirement before release**, because a declaration under a name not on this list would not be
detected. This is a known gap, recorded rather than papered over.

## Data boundaries

- Virtual Space never reads `/data/data/com.example.virtualtestapp` — the normally installed
  app's private directory. Only the package *identity* is passed to the engine, which resolves
  the APK through the platform's own `PackageManager`.
- Container data lives under the host's own sandbox at
  `/data/data/com.example.virtualspacedemo/blackbox/data/user/<virtualUserId>/`.
- Logging (`Slog`) records package names, profile ids and engine status only. Target
  application data, credentials and tokens are never logged.

## Package visibility

The manifest declares visibility for exactly one package, `com.example.virtualtestapp`.
`QUERY_ALL_PACKAGES` is not requested.

Note that merging the engine AAR adds ~322 `uses-permission` entries and ~152 stub activities
to the host manifest — these come from the engine and are what allow guest apps to run. This
is a real distribution consideration: the permission list is large and will need review before
any store submission.

## Scope limit

Phase 2 admits exactly one package. `AppSecurityChecker` rejects everything else with
`APP_NOT_SUPPORTED`. Banking, payment, anti-cheat and Play-Integrity-dependent apps are out of
scope and were not tested.
