# Level 8D VLC failure analysis

Device: OnePlus CPH2605 / Android 15 / API 35  
Serial: `KNOJORMFV4GERKHM`  
Guest: VLC 3.7.1 / `org.videolan.vlc`

## Confirmed successes

- User-facing APK picker selected the official single APK.
- Package metadata identified VLC and the profile was created.
- Debug and Release guest launch reached VLC `MainActivity`.
- Release loaded `libvlc.so`, `libvlcjni.so`, and `libmla.so`.
- Debug and Release relaunch reached the same VLC profile/MainActivity.

## First Debug failure

The first captured Debug fatal was:

`java.lang.ArrayIndexOutOfBoundsException: length=0; index=0`

The stack is:

`android.os.Environment.isExternalStorageManager()`  
`org.videolan.resources.util.HelpersKt.isExternalStorageManager()`  
`org.videolan.vlc.util.Permissions.canReadStorage()`  
`org.videolan.vlc.gui.MainActivity.onPrepareOptionsMenu()`

This is a reproducible Android 15 storage-permission failure path. It is not
classified as an R8 or native-library failure. It occurred before successful
media playback and was recorded in `debug-function.log`.

## Release failure

After legitimate user-facing permission grants for audio, photos/video, and
record audio, Release reached VLC MainActivity and loaded the native media
libraries. The media library then reported:

`Failed to create thumbnail directory (.../medialib/thumbnails/): Permission denied`

The VLC UI remained in its Loading state. No local audio playback, media
notification, or foreground playback service could be verified. The same
thumbnail-directory permission error recurred on Release relaunch.

## Classification

The current evidence identifies a general virtual-storage/permission boundary:

1. Guest code can launch and load native media libraries.
2. Android 15 storage-manager permission inspection is unsafe in the current
   virtual identity/path arrangement.
3. The guest media-library path is redirected under Duplika storage, but VLC
   cannot create its thumbnail directory there.

The exact responsible engine hook has not yet been isolated. No source code was
modified and no permission was artificially granted. This is therefore a
confirmed Level 8D compatibility failure, not a basis for a speculative fix.

## Evidence

- `debug-import.log`
- `debug-launch.log`
- `debug-function.log`
- `debug-relaunch.log`
- `release-launch.log`
- `release-relaunch.log`
- `debug-function.png`
- `release-launch.png`
