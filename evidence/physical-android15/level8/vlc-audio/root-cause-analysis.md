# Level 8D root-cause analysis — current state

## Debug

The first reproducible failure is:

```text
java.lang.ArrayIndexOutOfBoundsException: length=0; index=0
    at android.os.Environment.isExternalStorageManager(Environment.java:1527)
    at org.videolan.resources.util.HelpersKt.isExternalStorageManager(Helpers.kt:113)
    at org.videolan.vlc.util.Permissions.canReadStorage(Permissions.kt:131)
    at org.videolan.vlc.gui.MainActivity.onPrepareOptionsMenu(MainActivity.kt:281)
```

The Android 15 framework implementation first evaluates
`sCurrentUser.getExternalDirs()[0]`. Therefore the immediate failure is an
empty external-directory result exposed to the guest framework state. The
failure is reached through VLC's permission-status query, but it is not a
VLC-specific native crash.

The vendored Bcore binary confirms that its virtual storage service rewrites
the returned `StorageVolume` path to `BEnvironment.getExternalUserDir(user)`.
That service can therefore affect the external-directory state used by the
framework. The existing log does not yet prove whether the empty result is
caused by the service returning no volumes, an Android 15 API-shape mismatch,
or a later framework transformation. No fix is claimed at this stage.

## Release

The first media-specific failure is:

```text
MediaLibrary.cpp:669 initialize Failed to create thumbnail directory
(/storage/emulated/0/Android/data/co.tdevs.duplika/files/blackbox/
storage/emulated/0/Android/data/org.videolan.vlc/files/medialib/thumbnails/):
Permission denied
```

This occurs after VLC's native libraries load. Bcore's decompiled
`BEnvironment` shows that the guest external data path is composed beneath
the host's `getExternalFilesDir("blackbox")`. The native media library then
attempts to create its thumbnail directory at that redirected path and gets
`EACCES`. The evidence establishes a general virtual external-storage write
boundary, but does not yet identify whether the denial is from the Android 15
external-storage provider, directory provisioning/ownership, or a native path
mapping mismatch.

## Relationship

The failures are related by the virtual external-storage surface, but they are
not the same failure:

1. Debug fails while querying the external-volume list (`getExternalDirs()[0]`).
2. Release reaches native media initialization and fails creating a directory.

The current evidence is insufficient to select a safe general implementation
change. Level 8D remains PARTIAL.
