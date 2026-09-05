# Virtual Space Demo — Phase 1

**Phase 1 is a controlled prototype. It does not yet provide true Android application virtualization.**

The current profiles are metadata-level virtual profiles. The controlled test APK is launched
normally through Android's official launcher APIs.

---

## 1. Project purpose

A long-term platform for Android application virtualization / multiple accounts, in the same
category as Parallel Space or Dual Space. This repository holds the foundation for that platform,
not the platform itself.

## 2. Phase 1 scope

Phase 1 establishes the skeleton that a real engine can later be dropped into:

| Delivered | Explicitly NOT delivered |
| --- | --- |
| Clean Flutter + Kotlin architecture | Any real virtualization |
| A single `MethodChannel` bridge | UID / process / package / storage isolation |
| A controlled native test APK with persistent state | Android framework or Binder hooks |
| Virtual profile CRUD + local persistence | APK cloning or injection |
| Package detection via `PackageManager` | Sandboxing, permission virtualization |
| Normal launch of the test APK | Third-party engines (BlackBox, VirtualApp, …) |
| A replaceable `VirtualizationEngine` abstraction | Multiple simultaneous runtime instances |

## 3. Directory structure

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
│   ├── errors/app_exception.dart      sealed application error hierarchy
│   ├── services/profile_storage.dart  storage interface + SharedPreferences impl
│   ├── utils/app_logger.dart          dart:developer wrapper (no print())
│   └── virtualization/
│       ├── virtualization_engine.dart      the Phase 2 integration boundary
│       └── demo_virtualization_engine.dart Phase 1 metadata-only implementation
├── data/
│   ├── models/{virtual_profile_model, test_app_model, platform_info}.dart
│   └── repositories/virtual_profile_repository.dart
├── native/native_bridge.dart          the ONLY MethodChannel caller
├── features/
│   ├── home/{controllers,views,widgets}
│   └── profiles/{controllers,views,widgets}
└── widgets/{profile_card, empty_state}.dart
```

## 4. Flutter architecture

- Dart null safety, strong typing, `const` constructors where they apply.
- GetX for state management and routing; dependencies are registered in `AppBinding`.
- `flutter_screenutil` is initialised exactly once, in `VirtualSpaceApp`.
- Widgets contain no business logic, no persistence and no platform-channel calls.
- Controllers translate `AppException` into user-facing strings; raw platform errors never reach
  the UI.

Layering: `View → Controller → VirtualizationEngine → Repository / NativeBridge`.

## 5. Kotlin architecture

```
android/app/src/main/kotlin/com/example/virtualspacedemo/
├── MainActivity.kt          entry point; attaches and detaches the bridge
└── native/
    ├── NativeBridge.kt      MethodChannel handling and dispatch
    ├── TestAppManager.kt    PackageManager reads (detection, metadata, device info)
    └── AppLauncher.kt       launcher-intent creation and startActivity
```

Android types (`Context`, `Intent`, `PackageManager`) never cross the channel; Flutter receives
plain maps of primitives which are converted into typed Dart models.

## 6. Flutter ↔ Kotlin bridge

Channel: `virtual_space/native_bridge`

| Method | Returns |
| --- | --- |
| `getPlatformInfo` | `{androidVersion, sdkInt, manufacturer, model}` |
| `isTestAppInstalled` | `bool` |
| `getTestAppInfo` | `{installed, packageName, appName?, versionName?, versionCode?}` |
| `launchTestApp` | `{success: true, packageName}` or `{success: false, error: "TEST_APP_NOT_INSTALLED"}` |

Failures are returned as structured results or surfaced as typed Dart exceptions
(`NativeBridgeException`, `LaunchException`). Nothing is hardcoded to succeed.

Package visibility is declared as narrowly as Android 11+ allows — a single
`<package android:name="com.example.virtualtestapp" />` entry. `QUERY_ALL_PACKAGES` is not
requested.

## 7. Test APK

`../virtual_test_app` — a native Kotlin app, package `com.example.virtualtestapp`, label
"Virtual Test App". It exists solely as a controlled application whose behaviour we fully know,
so later phases can measure whether state is genuinely isolated.

It shows a counter and a stored name, persisted in `SharedPreferences`
(`virtual_test_app_state.xml`): counter defaults to `0`, stored name to `Test User`.

## 8. Profile model

`VirtualProfileModel { id, packageName, appName, profileName, createdAt, enabled }` — immutable,
UUID v4 id, JSON serialisable.

## 9. Repository

`VirtualProfileRepository` owns *all* profile persistence: `createProfile`, `getProfiles`,
`getProfile`, `updateProfile`, `deleteProfile`. Profiles are stored as a JSON array under the
`shared_preferences` key `virtual_space.profiles.v1`.

**Duplicate policy (chosen and enforced):** several profiles may reference the same package —
that is the point of the product. Profile *names*, however, must be unique after trimming and
case-folding. A duplicate name is rejected with a `ValidationException` and the existing profile
is never overwritten. Renaming a profile to its own current name is allowed.

Storage sits behind the `ProfileStorage` interface so repository behaviour is unit-testable
without a device.

## 10. DemoVirtualizationEngine

`VirtualizationEngine` is an abstract interface: `createProfile`, `deleteProfile`,
`renameProfile`, `launchProfile`, `getProfiles`, and `providesRuntimeIsolation`.

`DemoVirtualizationEngine` is the only Phase 1 implementation. It delegates persistence to the
repository and, on launch, starts the real installed package through `AppLauncher`. It reports
`providesRuntimeIsolation == false`, and the home screen states that fact permanently in the UI.

Deleting a profile removes metadata only. The test APK is never uninstalled and its data is never
touched.

## 11. Installation and testing instructions

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

Native instrumentation tests (require a device with the test APK installed):

```bash
cd virtual_space_demo/android && ./gradlew :app:connectedDebugAndroidTest
```

Manual acceptance walkthrough:

1. Open Virtual Test App → counter `0`, name `Test User`. Increase, edit the name, Save.
2. Close and reopen → both values persist. Reset → counter returns to `0`.
3. Open Virtual Space → the test app shows as **Installed** with its version.
4. Add "Profile 1" and "Profile 2". Restart → both persist.
5. Rename Profile 1, restart → the rename persists.
6. Delete Profile 2 (a confirmation dialog appears), restart → it stays deleted.
7. Launch any profile → the normal Virtual Test App opens; the test APK is still installed.

## 12. Current limitations

Phase 1 does **not** provide:

- independent APK runtime state
- an independent Android UID or Linux process
- an independent package installation
- virtual storage or virtual permissions
- framework or Binder virtualization, process hooks, APK cloning, real sandboxing
- multiple simultaneous runtime instances

The following is expected and correct behaviour today:

> Profile 1 → normal Test App. Profile 2 → normal Test App. Both use the same real Android
> application state.

Profile separation exists **only** inside this application's own metadata store.

## 13. Security constraints

- The host application never reads another application's private data — no passwords, tokens,
  databases, cookies, private files, other apps' `SharedPreferences`, or internal storage.
- No root, SELinux bypass, signature bypass, PackageManager bypass, Play Integrity or anti-cheat
  workaround, fingerprint spoofing, or stealth behaviour.
- Only public, documented Android APIs are used.
- Package visibility is scoped to one package; `QUERY_ALL_PACKAGES` is not requested.
- No third-party virtualization or hooking framework is present, and no code from such a project
  has been copied.

## 14. Future Phase 2 direction

Research and prototype a real Android application virtualization engine using a legally
compatible open-source foundation, with the current `VirtualizationEngine` abstraction acting as
the integration boundary.

Phase 2 is investigation, not implementation. It should establish, before any code is written:
licence compatibility of any candidate foundation; what a real engine must do about UID, process,
storage and permission isolation; which Android versions and OEM builds it can support; how
Google Play policy and Play Integrity affect distribution; and what the maintenance cost is when
a new Android release changes the private framework surface such an engine depends on.
