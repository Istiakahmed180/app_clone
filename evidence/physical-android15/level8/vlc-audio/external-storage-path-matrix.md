# VLC external-storage evidence matrix

Device: OnePlus CPH2605 / Android 15 / API 35  
Guest: VLC 3.7.1 / `org.videolan.vlc`  
Host: `co.tdevs.duplika`

| Layer | Observed value or behavior | Evidence | Interpretation |
|---|---|---|---|
| Android API | `Environment.isExternalStorageManager()` accesses `sCurrentUser.getExternalDirs()[0]` | SDK API 36 `android/os/Environment.java:1509-1511` | An empty external-volume array deterministically causes the observed `ArrayIndexOutOfBoundsException`. |
| Guest process | Guest is hosted as `co.tdevs.duplika:p0`, while ActivityManager identifies the virtual activity as `org.videolan.vlc` | `debug-launch.log`, `release-launch.log` | Guest code runs under the host process/UID; this is expected for this architecture. |
| Virtual storage root | Bcore initializes its external virtual root from host `Context.getExternalFilesDir("blackbox")` | Decompiled vendored `BEnvironment` | Guest external paths are redirected below host app-specific external storage. |
| Virtual guest external data | Bcore constructs `storage/emulated/<user>/Android/data/<guest package>` below that root | Decompiled vendored `BEnvironment.getExternalDataDir()` | The architecture creates a nested virtual path rather than a platform-owned guest package directory. |
| Debug permission query | `Environment.isExternalStorageManager()` throws before returning a boolean | `debug-storage-diagnostic.log`, `debug-isExternalStorageManager.log` | Confirmed storage-volume/query compatibility failure; not a VLC native-library failure. |
| Release media library | `Failed to create thumbnail directory (.../org.videolan.vlc/files/medialib/thumbnails/): Permission denied` | `release-storage-diagnostic.log`, `release-thumbnail-directory.log` | Confirmed write failure at the redirected native filesystem path. |
| Native loading | `libvlc.so`, `libvlcjni.so`, and `libmla.so` load successfully | `release-launch.log` | ABI/native loading is not the first Release failure. |
| Host all-files state | Bcore logs `All files access not granted for launching: org.videolan.vlc` | `debug-launch.log`, `release-launch.log` | A warning/preflight state, not evidence that Android permissions were silently granted. |

## Important non-findings

- No code was changed for VLC.
- No permission was artificially granted.
- No package name or VLC path was hardcoded.
- No scoped-storage protection was disabled.
- The current evidence does not prove that a single storage hook fixes both failures.
