# Level 9 regression evidence

Run on the OnePlus CPH2605 (Android 15 / API 35 / arm64) on 2026-09-08, after the Level 9
work, from the Duplika Debug build.

No production virtualization code was changed in Level 9, so this checks that the shared
ladder build change (`android.useAndroidX=true`, needed by the new module) and the new
module itself did not disturb anything.

| Area | Result | How it was verified |
| --- | --- | --- |
| Ladder Level 6 clone launch | PASS | Guest UI reached through `ProxyActivity$P0`, virtual user 4 |
| Activities | PASS | Level 6 `MainActivity` rendered with all controls |
| SQLite persistence | PASS | `READ SQLITE VALUE` showed `SQLite value=1` |
| JobScheduler | PASS | `LadderLevel6: job schedule result=0` |
| Notifications | PASS | `notification posted channel=level6`, accepted by the system as `level6@black-4` |
| Runtime permissions | PASS | Permission state queried and displayed by the guest |
| ContentProviders | PASS | `FirebaseInitProvider` registered and resolvable inside every Level 9 container |
| Import / install / launch / relaunch | PASS | Four Level 9 clones created by import and by installed-app clone; provisioned clone relaunched with identical results |
| Split APK / native ABI split (Level 7) | NOT RE-RUN | No engine or installer code was touched; `:level7fixture` still builds. Stated rather than claimed. |
| `flutter test` | PASS | 246 tests |
| `flutter analyze` | PASS | 4 pre-existing info-level lints, all in files not touched here |
| `flutter build apk --debug` / `--release` | PASS | Both built and the Debug build was installed and used for this run |
| `./gradlew assembleDebug` (whole ladder) | PASS | All modules including the pre-existing ones |
