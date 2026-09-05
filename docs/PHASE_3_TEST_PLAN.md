# Phase 3 — APK Import, Multi-App, Multi-Instance

Device of record: **OnePlus CPH2605, Android 15 (API 35), arm64-v8a**.

## What Phase 3 adds

| Capability | How it works |
| --- | --- |
| **Multi-app** | `InstalledAppsProvider` lists launchable apps (label, package, icon) for a picker. Any app may be cloned except Virtual Space itself and system components. |
| **Multi-instance** | Several profiles may share one package; each gets its own `virtualUserId`. Names auto-increment ("Telegram", "Telegram 2"). |
| **APK import** | The user picks an `.apk`; it is streamed to app storage, parsed with `getPackageArchiveInfo`, admitted by the same security policy, then installed into a container. |

## Automated results

| Suite | Command | Result |
| --- | --- | --- |
| Static analysis | `flutter analyze` | No issues |
| Dart unit tests | `flutter test` | 53 passed |
| Native instrumentation | `./gradlew :app:connectedDebugAndroidTest` | 19 passed on device |
| Host APK | `flutter build apk --debug` | Built |

## Manual results on device

| # | Check | Result |
| --- | --- | --- |
| 1 | App picker enumerates real installed apps with icons and search | PASS |
| 2 | Clone the controlled test app | PASS — auto-named, `user 0` |
| 3 | Add a second clone of the same app | PASS — confirmation shown, auto-named "Virtual Test App 2", `user 1` |
| 4 | Three clones created back-to-back without launching | PASS — all registered |
| 5 | Independent state across clones | PASS — see below |
| 6 | Clone a real third-party app (VLC) | PASS — `user 2`, runs with its own native libs |
| 7 | VLC clone is a fresh instance | PASS — shows first-run onboarding, not the host install's state |
| 8 | Two different guest apps running at once | PASS |
| 9 | Normal installs untouched | PASS |
| 10 | Clones survive host restart and APK upgrade | PASS |

### Isolation evidence

Three clones of one package, verified earlier in the session:

```
virtual user 0: Ann  / 11
virtual user 1: Ben  / 44
virtual user 2: Cara / 33
normal install: Normal / 5
```

Final state of record, with a second app added:

```
blackbox/data/user/0 -> com.example.virtualtestapp     Ann / 11
blackbox/data/user/1 -> com.example.virtualtestapp     Ben / 22
blackbox/data/user/2 -> org.videolan.vlc               (fresh install)
normal install       -> com.example.virtualtestapp     Normal / 5

u0_a823  21583  com.example.virtualspacedemo
u0_a823  28232  com.example.virtualspacedemo:black
u0_a823  26096  com.example.virtualtestapp     <- guest
u0_a823  28256  org.videolan.vlc               <- guest, different app, same time
```

## Defects found and fixed in this phase

1. **`isInstalled` is not trustworthy, and it was gating real work.** Bcore answers from the
   *host* package manager whenever its own service binder is unhealthy. That made it report
   every host-installed app as already present in every container — so `VirtualAppInstaller`
   skipped genuine installs, and `launch` refused perfectly good launches. Both call sites now
   ignore the predicate: installs always go through (re-installing is idempotent and does not
   clear container data — only the explicit `clearPackage` does), and launch attempts the real
   call and reacts to the result.

2. **Bcore drops per-user install records that have never been launched.** Creating several
   clones before launching any of them lost the earlier ones. Rather than depend on the user
   launching in a particular order, a failed launch now **rebuilds its own container and
   retries**. Imported APKs are retained in app storage so an imported clone can be rebuilt
   too, and the retained copy is deleted with the profile.

3. **Misleading clone labels.** Every card read "1 of N". Cards now carry a real 1-based
   instance index ("clone 2 of 3").

## Known limitations

- **The system file picker could not be automated.** ColorOS blocks synthetic input into
  `com.android.documentsui`, so the SAF selection step was not driven by script. Everything
  after the file is chosen — streaming to storage, parsing, admission, container install — is
  covered by instrumentation tests using a real APK file, but **the picker tap itself is
  verified only by manual use.**
- `QUERY_ALL_PACKAGES` is now requested so the picker can enumerate apps. This is
  Play-policy-sensitive and must be justified at review; see `SECURITY.md`.
- Apps depending on Google Play Services, push, or Play Integrity were **not** tested. VLC was
  chosen precisely because it has no account and no GMS dependency.
- Banking, payment, authenticator and anti-cheat apps were deliberately **not** tested and
  remain out of scope.
- The "Running" indicator is still unavailable (Bcore defect, see `VIRTUALIZATION_ENGINE.md`).
- Verified on one device and one OEM build only.
