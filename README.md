# Duplika — Phase 4

**Phase 4 adds an app compatibility layer: verdicts and honest warnings.**

**Any installed app can now be cloned, and APKs can be imported without installing them.**

**Arbitrary third-party application compatibility is still not guaranteed.** Verified on a
physical OnePlus CPH2605 (Android 15, arm64): the controlled test app, VLC, and — cloning and
launching to first-run onboarding in isolated containers — Telegram and WhatsApp. Google
sign-in inside a clone does not work (see the GMS findings in `docs/PHASE_4_COMPATIBILITY.md`).

> ## ⛔ This build must not be distributed
>
> The virtualization engine descends from projects that are **unlicensed or expressly
> commercial**. `asLody/VirtualApp` — credited upstream as the original framework — ships no
> LICENSE, requires purchased commercial authorisation, and threatens prosecution for
> app-store use. `FBlackBox/BlackBox`, source of the `top.niunaijun.blackbox` namespace used
> here, reports `license: null`. NewBlackbox nevertheless declares Apache-2.0 for the whole
> repository, which on this evidence it was very likely not in a position to grant.
>
> Separately, `android/app/libs/bcore.aar` is **already committed to a public repository**, so
> it also lives in Git history and in any fork taken.
>
> Nothing in this repository resolves that. It needs a lawyer, and then one of: purchased
> authorisation, a different engine behind the `VirtualizationEngine` adapter, or not shipping.
> Internal development and testing are unaffected. Details and evidence:
> `docs/DEPENDENCY_LICENSE_AUDIT.md` (findings 2 and 5) and the root `NOTICE`.

Clones run in real containers with isolated storage, verified on a physical Android 15 device:

| Container | App | State |
| --- | --- | --- |
| virtual user 0 | Virtual Test App | Ann / 11 |
| virtual user 1 | Virtual Test App (2nd clone) | Ben / 22 |
| virtual user 2 | VLC | fresh install |
| normal install | Virtual Test App | Normal / 5 |

All independent. Guests write through their own ordinary `SharedPreferences`; no per-clone
state is faked in Flutter.

## Documentation

| Document | Contents |
| --- | --- |
| `docs/ARCHITECTURE.md` | Layering, the backend swap point, profile identity, consistency rules |
| `docs/VIRTUALIZATION_ENGINE.md` | Engine selection, toolchain reconciliation, backend defects and workarounds |
| `docs/SECURITY.md` | Security posture, `REQUIRE_SECURE_ENV`, data boundaries |
| `docs/DEPENDENCY_LICENSE_AUDIT.md` | Licences, and **open provenance risk** |
| `docs/PHASE_2_TEST_PLAN.md` | Phase 2 test plan, results, evidence, performance baseline |
| `docs/PHASE_3_TEST_PLAN.md` | Phase 3 capabilities, results and defects fixed |
| `docs/PHASE_4_COMPATIBILITY.md` | Compatibility verdicts, limitations, and the later removal of permission bridging |
| `docs/RELEASE_BUILD.md` | Why release builds minify, and what the engine needs to survive it |
| `docs/ONBOARDING.md` | First-launch data disclosure (gates the app), the Doze exemption; what must change before release |
| `docs/PLAY_PERMISSION_DECLARATIONS.md` | Paste-ready Play Console declarations for the three restricted permissions |
| `docs/microg-integration.md` | The parked microG spike, and why signature verification blocks it |

> **Attribution:** the root `NOTICE` and `licenses/` now carry the required notices for xDL,
> Dobby, FreeReflection and toml4j, whose copies inside the vendored engine had none. That
> obligation is met; the blocker above is a separate question and is not affected by it.

---

## Phase 1 history

Phase 1 was a controlled prototype with metadata-only profiles that launched the test APK
normally. Its `DemoVirtualizationEngine` remains in the tree as the reference no-op
implementation of the same interface.

---

## 1. Project purpose

A long-term platform for Android application virtualization / multiple accounts, in the same
category as Parallel Space or Dual Space. This repository holds the foundation for that platform,
not the platform itself.

## 2. Phase 4 scope

| Delivered | Explicitly NOT delivered |
| --- | --- |
| Compatibility verdict per app before cloning | Making GMS-dependent apps actually work |
| Honest warnings in the picker and the clone's long-press sheet | Per-clone permission scoping |
| ABI / secure-env / system-component blocking | Any permission or security bypass |

Permission bridging — the sheet's "Grant N permission(s)" action — was part of Phase 4 and
has since been removed; see `docs/PHASE_4_COMPATIBILITY.md`. Verified support for banking
and anti-cheat apps remains out of scope.

## 3. Phase 3 scope

| Delivered | Explicitly NOT delivered |
| --- | --- |
| Clone any installed app (picker with search + icons) | GMS / Play Store / Firebase virtualization |
| Import and run an APK that is not installed | Camera / mic / location **data** virtualization (per-clone denial is supported — see §13) |
| Multiple independent instances of one app | Device-fingerprint or location spoofing |
| Isolated per-clone application storage | Any security bypass, VPN mode or anti-detection |
| `REQUIRE_SECURE_ENV` admission, incl. imported APKs | Remote APK download or code update |
| Self-healing containers (rebuild on failed launch) | Verified support for banking/anti-cheat/GMS apps |

## 4. Directory structure

```
Others/
├── virtual_space_demo/     Flutter host application (this repository)
└── virtual_test_app/       Native Kotlin test application (separate, not a Flutter package)
```

```
virtual_space_demo/lib/
├── main.dart
├── app/
│   ├── app.dart                       root widget, ScreenUtil init
│   ├── routes/app_routes.dart         GetX route table
│   ├── routes/app_bindings.dart       dependency injection
│   └── theme/app_theme.dart           Material 3 theme
├── core/
│   ├── constants/app_constants.dart
│   ├── constants/legal_constants.dart policy URLs + terms version (placeholders)
│   ├── errors/app_exception.dart      sealed application error hierarchy
│   ├── services/profile_storage.dart  storage interface + SharedPreferences impl
│   ├── services/onboarding_store.dart what the user has already been asked
│   ├── utils/app_logger.dart          dart:developer wrapper (no print())
│   └── virtualization/
│       ├── virtualization_engine.dart      the integration boundary
│       ├── real_virtualization_engine.dart container-backed implementation (production)
│       └── demo_virtualization_engine.dart no-op reference; not bound in production
├── data/
│   ├── models/{virtual_profile_model, test_app_model, platform_info, consent_state,
│   │           engine_result, compatibility_report, installed_app_model}.dart
│   └── repositories/virtual_profile_repository.dart
├── native/native_bridge.dart          the ONLY MethodChannel caller
├── features/
│   ├── apps/          clone picker, APK import, compatibility sheet
│   ├── home/          clone grid, action sheet, engine status notice
│   ├── onboarding/    consent, terms, Doze exemption (docs/ONBOARDING.md)
│   └── profiles/      rename and delete dialogs
└── widgets/{app_icon, empty_state}.dart
```

## 5. Flutter architecture

- Dart null safety, strong typing, `const` constructors where they apply.
- GetX for state management and routing; dependencies are registered in `AppBinding`.
- `flutter_screenutil` is initialised exactly once, in `DuplikaApp`.
- Widgets contain no business logic, no persistence and no platform-channel calls.
- Controllers translate `AppException` into user-facing strings; raw platform errors never reach
  the UI.

Layering: `View → Controller → VirtualizationEngine → Repository / NativeBridge`.

## 6. Kotlin architecture

```
android/app/src/main/kotlin/co/tdevs/duplika/
├── MainActivity.kt                 entry point; attaches and detaches the bridge
├── DuplikaApplication.kt           host Application; attaches the engine in every process
└── native/
    ├── NativeBridge.kt             MethodChannel handling and dispatch
    ├── BatteryOptimization.kt      Doze exemption prompt, with a settings fallback
    ├── RealVirtualizationEngine.kt application-facing virtualization API
    ├── VirtualizationEngineAdapter.kt  backend abstraction + error codes
    ├── VirtualProfileManager.kt    profile UUID <-> engine user id mapping
    ├── VirtualAppInstaller.kt      installs into a container (after admission check)
    ├── VirtualAppLauncher.kt       starts/stops the guest in a container
    ├── AppSecurityChecker.kt       deny-list + REQUIRE_SECURE_ENV admission
    ├── AppCompatibilityAnalyzer.kt compatibility verdict for an app or an APK
    ├── InstalledAppsProvider.kt    launchable apps and their icons, for the picker
    ├── ApkImporter.kt              identity of a picked APK file
    ├── ApkManifestReader.kt        decodes an APK's compiled AndroidManifest.xml
    ├── TestAppManager.kt           PackageManager reads
    ├── AppLauncher.kt              Phase 1 normal launcher intent (kept for comparison;
    │                               not reachable in production — see section 11)
    ├── Slog.kt                     controlled logging tags
    └── blackbox/
        └── BlackBoxEngineAdapter.kt  the ONLY file importing top.niunaijun.*
```

Android types (`Context`, `Intent`, `PackageManager`) never cross the channel; Flutter receives
plain maps of primitives which are converted into typed Dart models.

## 7. Flutter ↔ Kotlin bridge

Channel: `duplika/native_bridge`

| Method | Returns |
| --- | --- |
| `getPlatformInfo` | `{androidVersion, sdkInt, manufacturer, model}` |
| `isTestAppInstalled` | `bool` |
| `getTestAppInfo` | `{installed, packageName, appName?, versionName?, versionCode?}` |
| `launchTestApp` | Phase 1 normal launch: `{success, packageName}` or `{success:false, error}` |
| `isVirtualizationAvailable` | `{available, backend, code?, message?}` |
| `initializeVirtualization` | envelope |
| `isAppSupported` / `checkSecureEnvironmentRequirement` | envelope with `data` |
| `installAppToProfile` / `uninstallAppFromProfile` | envelope |
| `isAppInstalledInProfile` | envelope with `{installed, running, virtualUserId}` |
| `launchProfile` / `stopProfile` / `deleteProfile` | envelope |

Phase 2 calls return a structured envelope so a native failure can never read as success:

```json
{ "success": true, "code": "APP_INSTALLED", "message": "...", "data": {} }
```

Failures are returned as structured results or surfaced as typed Dart exceptions
(`NativeBridgeException`, `LaunchException`). Nothing is hardcoded to succeed.

Package visibility is declared as narrowly as Android 11+ allows — a single
`<package android:name="com.example.virtualtestapp" />` entry. `QUERY_ALL_PACKAGES` is not
requested.

## 8. Test APK

`../virtual_test_app` — a native Kotlin app, package `com.example.virtualtestapp`, label
"Virtual Test App". It exists solely as a controlled application whose behaviour we fully know,
so later phases can measure whether state is genuinely isolated.

It shows a counter and a stored name, persisted in `SharedPreferences`
(`virtual_test_app_state.xml`): counter defaults to `0`, stored name to `Test User`.

## 9. Profile model

`VirtualProfileModel { id, packageName, appName, profileName, createdAt, enabled }` — immutable,
UUID v4 id, JSON serialisable.

## 10. Repository

`VirtualProfileRepository` owns *all* profile persistence: `createProfile`, `getProfiles`,
`getProfile`, `updateProfile`, `deleteProfile`. Profiles are stored as a JSON array under the
`shared_preferences` key `duplika.profiles.v1`.

**Duplicate policy (chosen and enforced):** several profiles may reference the same package —
that is the point of the product. Profile *names*, however, must be unique after trimming and
case-folding. A duplicate name is rejected with a `ValidationException` and the existing profile
is never overwritten. Renaming a profile to its own current name is allowed.

Storage sits behind the `ProfileStorage` interface so repository behaviour is unit-testable
without a device.

## 11. Virtualization engines

`VirtualizationEngine` is an abstract interface: `createProfile`, `deleteProfile`,
`renameProfile`, `launchProfile`, `getProfiles`, `profileState`, `initialize` and
`providesRuntimeIsolation`.

`RealVirtualizationEngine` (Phase 2, active) backs each profile with a real container through
the native adapter. It reports `providesRuntimeIsolation == true`, but the UI only *claims*
isolation when the native backend also confirms it is available on the device.

`DemoVirtualizationEngine` (Phase 1) remains as the reference no-op implementation.

Deleting a profile removes the container and its isolated data. The normally installed test APK
is never uninstalled and its own data is never touched — verified on device.

## 12. Installation and testing instructions

Build and install the controlled test app first:

```bash
cd virtual_test_app && ./gradlew :app:assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

Then the host app:

```bash
cd virtual_space_demo
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

The suite is currently **364 Dart tests**; `flutter analyze` reports 0 errors and four
pre-existing info lints. The investigation and phase documents under `docs/` quote the count
as it was at *their* commit — that is a snapshot, not this figure.

Release builds minify, and the engine needs keep rules to survive that
(`android/app/proguard-rules.pro`). Without them the engine dies in
`attachBaseContext` and every clone is unusable — see `docs/RELEASE_BUILD.md`:

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

A release build is not debuggable, so `run-as` cannot inspect containers. Verify
it by launching a clone and confirming the foreground activity is a proxy:

```bash
adb shell dumpsys activity activities | grep topResumedActivity
```

Native instrumentation tests (require a device with the test APK installed):

```bash
cd virtual_space_demo/android && ./gradlew :app:connectedDebugAndroidTest
```

Manual acceptance walkthrough:

1. Open Virtual Test App → counter `0`, name `Test User`. Increase, edit the name, Save.
2. Close and reopen → both values persist. Reset → counter returns to `0`.
3. Open Duplika → the test app shows as **Installed** with its version.
4. Add "Profile 1" and "Profile 2". Restart → both persist.
5. Rename Profile 1, restart → the rename persists.
6. Delete Profile 2 (a confirmation dialog appears), restart → it stays deleted.
7. Launch any profile → the normal Virtual Test App opens; the test APK is still installed.

## 13. Current limitations

Phase 2 **does** provide isolated per-profile application storage, separate guest processes and
multiple simultaneous instances of one app.

It does **not** provide:

- guaranteed support for arbitrary apps. Verified working: the test app, VLC, Telegram and
  WhatsApp (launch + container isolation) on one device; other apps may still fail
- an independent Android UID — guests run under the **host's** UID and inherit its permission
  grants; isolation is at the container/storage level, not the kernel UID level. A clone's
  **Permissions** action can deny a dangerous permission for that clone, but that is a
  check-layer policy, not a sandbox — see `docs/PHASE_4_COMPATIBILITY.md`
- **caller-scoped Google APIs.** Superseded measurement, and the direction matters: the
  Phase 4 statement that `isGooglePlayServicesAvailable` returns `SERVICE_MISSING` and that
  `com.google.android.gms` is invisible to a guest was fixed by engine patch 0002 and is no
  longer true. Availability is now `SUCCESS(0)`, and the GMS availability check, the
  GoogleApi client framework, Advertising ID, App Set ID, Chimera module loading, the Play
  services security provider and the Maps SDK all work in a container.
  What does **not** work is any Google API whose access must be attributed to the calling
  package — LocationServices, ActivityRecognition, SmsRetriever and Google Sign-In. Play
  services refuses these with `SecurityException: Unknown calling package name`, because a
  guest's package does not belong to the Binder calling UID. That is Google's identity
  model working correctly, not a Duplika defect, and it must not be "fixed"
  (`docs/level10-gms-caller-identity-boundary.md`)
- Play Billing. The Play Store refuses a billing connection from a container
  (`BILLING_UNAVAILABLE`); root cause not yet established
- Firebase Messaging virtualization — not a dependency of this project and not tested.
  Firebase *initialization* (`firebase-common`) is measured and works in a guest
  (`compatibility_test_ladder/level9_gms` Test E)
- camera, mic or location **data** virtualization — no spoofed frames, audio or coordinates,
  and none is planned. **Denial** is the supported control: a clone's **Permissions** action
  can turn any of them off for that clone (a check-layer policy, not a hard sandbox)
- a working "Running" indicator (a Bcore defect; see `docs/VIRTUALIZATION_ENGINE.md`)
- any verified compatibility beyond the one device tested (OnePlus CPH2605, Android 15, arm64)

x86_64 is unsupported: Bcore ships no x86_64 native library.

## 14. Security constraints

- The host application never reads another application's private data — no passwords, tokens,
  databases, cookies, private files, other apps' `SharedPreferences`, or internal storage.
- No root, SELinux bypass, signature bypass, PackageManager bypass, Play Integrity or anti-cheat
  workaround, fingerprint spoofing, or stealth behaviour.
- Only public, documented Android APIs are used.
- Package visibility is scoped to one package; `QUERY_ALL_PACKAGES` is not requested.
- The virtualization backend is third-party (NewBlackbox/Bcore, Apache-2.0), vendored as a
  prebuilt AAR and confined behind `VirtualizationEngineAdapter`. See
  `docs/DEPENDENCY_LICENSE_AUDIT.md` for open provenance risk and `docs/SECURITY.md` for the
  backend options Duplika pins off (`FLAG_SECURE` defeat, root hiding, VPN mode).
- Applications declaring `REQUIRE_SECURE_ENV` are rejected, with no override path.

## 15. Recommended next direction

Not started. In rough priority order:

1. **Close the licence provenance question** in `docs/DEPENDENCY_LICENSE_AUDIT.md` and add the
   missing third-party attribution notices. This gates any distribution and may gate the
   backend choice itself — the upstream projects are unlicensed or expressly commercial.
2. **Broaden device coverage** — other vendors, Android 13/14/16 — before claiming support.
   Everything here is verified on one OnePlus device running Android 15.
3. **Decide on the backend**: patch Bcore's broken `isRunningApplication` upstream, or move to
   another backend behind the existing adapter.
4. **Decide what to do about Google Play Services**, which most popular apps depend on and
   which this build does not virtualize.

Resolved since this list was first written: the canonical `REQUIRE_SECURE_ENV` property name is
now confirmed against real apps (see `docs/SECURITY.md`), and multi-app support has shipped.
Per-clone notification control is also resolved: the engine namespaces and labels each
clone's notification channels, and a clone's **Notifications** action opens the screen where
one clone can be silenced on its own.
