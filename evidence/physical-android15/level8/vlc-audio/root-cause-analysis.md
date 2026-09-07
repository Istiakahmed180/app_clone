# Level 8D root-cause analysis — current state

## VLC failures

### Debug

The first reproducible VLC failure is:

```text
java.lang.ArrayIndexOutOfBoundsException: length=0; index=0
    at android.os.Environment.isExternalStorageManager(Environment.java:1527)
    at org.videolan.resources.util.HelpersKt.isExternalStorageManager(Helpers.kt:113)
    at org.videolan.vlc.util.Permissions.canReadStorage(Permissions.kt:131)
    at org.videolan.vlc.gui.MainActivity.onPrepareOptionsMenu(MainActivity.kt:281)
```

Android 15 evaluates `sCurrentUser.getExternalDirs()[0]` in this framework
method. The VLC crash therefore proves that VLC observed an empty external
directory result in that execution path. It does not, by itself, prove that
the virtual storage service always returns an empty volume list.

### Release

The first media-specific VLC failure is:

```text
MediaLibrary.cpp:669 initialize Failed to create thumbnail directory
(/storage/emulated/0/Android/data/co.tdevs.duplika/files/blackbox/
storage/emulated/0/Android/data/org.videolan.vlc/files/medialib/thumbnails/):
Permission denied
```

VLC's native libraries load before this error. The failure occurs while the
native media library creates its thumbnail directory at a redirected virtual
external-data path.

## Controlled storage diagnostic

A minimal APK (`com.example.duplikaladder.storageprobe`) was built and tested
through the physical Duplika import flow on the OnePlus CPH2605, Android 15 /
API 35. It was tested in both Debug and Release, with the following results:

- standalone host Debug and Release each reported one mounted primary volume;
- guest Debug and Release each reported one mounted virtual volume;
- guest `Environment.isExternalStorageManager()` returned without throwing;
- guest external files, cache, media, and the exact nested
  `medialib/thumbnails` directory all passed mkdir/write/read checks;
- guest user-specific virtual paths were consistent across multiple imported
  profiles; and
- Release guest relaunch preserved the diagnostic counter.

These results disprove both of the currently broad hypotheses:

1. all guest apps receive no external storage volume on Android 15; and
2. guest app-specific external storage cannot create/write the nested VLC-like
   thumbnail path.

The diagnostic does not reproduce VLC's failure. Consequently, the exact
remaining boundary is unresolved: it may involve VLC's own permission/path
setup, its native media-library timing or path handling, or an interaction
specific to VLC's process/runtime behavior. The current evidence is not enough
to justify a general production storage or Bcore change.

## Decision

No production code, Bcore code, Flutter code, Kotlin engine code, or storage
redirection logic was changed for this investigation. Level 8D remains
**PARTIAL** because VLC local media playback was not verified in both Debug and
Release. Further work requires VLC-specific tracing against the controlled
diagnostic results, not a speculative global storage fix.
