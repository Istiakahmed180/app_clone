# Fossify Notes 1.5.0 — Level 8A evidence

- Package: `org.fossify.notes`
- Version: `1.5.0` / versionCode `11`
- APK: `compatibility_test_ladder/real_apps/org.fossify.notes_11.apk`
- Package type: single APK
- Device: OnePlus CPH2605, Android 15 / API 35 / arm64

## Verified flow

Release and Debug were both exercised through the Duplika guest profile:

1. Import APK through the user-facing picker.
2. Install and resolve `org.fossify.notes`.
3. Launch `org.fossify.notes.activities.MainActivity` through the proxy.
4. Enter and save the note `Level8_note`.
5. Close the guest.
6. Relaunch the same profile.
7. Confirm `Level8_note` was restored.

Result: PASS for install, launch, basic note functionality, persistence, and relaunch in both Debug and Release. No compatibility failure was observed.
