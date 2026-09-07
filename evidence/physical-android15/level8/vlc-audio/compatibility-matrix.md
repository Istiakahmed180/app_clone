# Level 8D VLC compatibility matrix

| Application | Feature | Debug | Release | Result | Failure layer |
|---|---|---|---|---|---|
| VLC 3.7.1 | Single-APK import/install | PASS | PASS: existing imported profile reused after Release host install | PASS | Import/install layer did not fail |
| VLC 3.7.1 | Guest launch and main UI | PASS: onboarding/MainActivity reached | PASS: MainActivity reached | PASS | No launch failure |
| VLC 3.7.1 | Native media library loading | PARTIAL: native libraries loaded; first run crashed in storage permission check | PARTIAL: `libvlc.so`, `libvlcjni.so`, and `libmla.so` loaded | PARTIAL | Storage permission / virtual path handling |
| VLC 3.7.1 | Local media playback | FAIL: media library remained Loading; no playback verified | FAIL: media library remained unavailable; no playback verified | FAIL | MediaLibrary thumbnail directory `Permission denied` |
| VLC 3.7.1 | Media foreground service/notification | NOT VERIFIED | NOT VERIFIED | PENDING | Blocked by media-library function failure |
| VLC 3.7.1 | Relaunch and persistence | PARTIAL: guest relaunch reached VLC MainActivity | PARTIAL: guest relaunch reached VLC MainActivity | PARTIAL | Same storage boundary recurred |
