# Level 8D VLC compatibility matrix

| Application | Feature | Debug | Release | Result | Failure layer |
|---|---|---|---|---|---|
| VLC 3.7.1 | Single-APK import/install | PASS | PASS: existing imported profile reused after Release host install | PASS | Import/install layer did not fail |
| VLC 3.7.1 | Guest launch and main UI | PASS: onboarding/MainActivity reached | PASS: MainActivity reached | PASS | No launch failure |
| VLC 3.7.1 | Native media library loading | PARTIAL: native libraries loaded; first run crashed in storage permission check | PARTIAL: `libvlc.so`, `libvlcjni.so`, and `libmla.so` loaded | PARTIAL | Storage permission / virtual path handling |
| VLC 3.7.1 | Local media playback | FAIL: media library remained Loading; no playback verified | FAIL: media library remained unavailable; no playback verified | FAIL | MediaLibrary thumbnail directory `Permission denied` |
| VLC 3.7.1 | Media foreground service/notification | NOT VERIFIED | NOT VERIFIED | PENDING | Blocked by media-library function failure |
| VLC 3.7.1 | Relaunch and persistence | PARTIAL: guest relaunch reached VLC MainActivity | PARTIAL: guest relaunch reached VLC MainActivity | PARTIAL | Same storage boundary recurred |

## Controlled storage diagnostic

| Application | Feature | Debug | Release | Result | Failure layer |
|---|---|---|---|---|---|
| StorageProbe 1.1 | Host volume and app-specific storage | PASS: mounted primary volume; mkdir/write/read passed | PASS: mounted primary volume; mkdir/write/read passed | PASS | None observed |
| StorageProbe 1.1 | Guest volume and app-specific storage | PASS: one mounted virtual volume; exact nested `medialib/thumbnails` mkdir/write/read passed | PASS: one mounted virtual volume; exact nested `medialib/thumbnails` mkdir/write/read passed | PASS | None observed |
| StorageProbe 1.1 | Guest relaunch persistence | PASS: diagnostic profile relaunched | PASS: counter increased on same imported profile | PASS | None observed |

The diagnostic PASS does not change the VLC result. It shows that a minimal
guest can use the tested virtual storage surface; VLC playback remains
unverified and Level 8D remains PARTIAL.
