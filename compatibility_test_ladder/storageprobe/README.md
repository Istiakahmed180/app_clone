# VLC Storage Probe 2.0

This is a test-only APK. It does not modify Duplika, Bcore, the Flutter host,
or the virtualization engine.

The probe mirrors the Android-side part of VLC MediaLibrary initialization:

1. `Environment.isExternalStorageManager()`
2. `Context.getExternalFilesDirs(null)` and the first directory
3. `Context.getExternalFilesDir(null)`
4. `Context.getDir("db", MODE_PRIVATE)` and `canWrite()`
5. `<externalFilesDir>/medialib/thumbnails`
6. Java `mkdirs()` and file write/read
7. Native `mkdir(2)`, `realpath(3)`, `open(2)`, `write(2)`, and `close(2)`
8. runtime permission and AppOps state

The native probe reports `errno`, canonical paths, and directory/file uid/gid
when a native operation fails. Manifest permissions are declared for
diagnostic reporting; the APK does not request or bypass permissions.

## Build

From this directory:

```sh
JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home \
  ./gradlew :storageprobe:assembleDebug :storageprobe:assembleRelease
```

Outputs:

```text
storageprobe/build/outputs/apk/debug/storageprobe-debug.apk
storageprobe/build/outputs/apk/release/storageprobe-release.apk
```

## Six physical test scenarios

Use only the physical OnePlus CPH2605, serial `KNOJORMFV4GERKHM`:

1. Host Debug: install `storageprobe-debug.apk`, launch, capture the report.
2. Host Release: install `storageprobe-release.apk`, launch, capture the report.
3. Guest Debug: import the Debug APK through Duplika's user-facing picker,
   launch the imported profile, capture the report.
4. Guest Release: import the Release APK through the same picker, launch the
   imported profile, capture the report.
5. Guest Debug relaunch: close and relaunch the same Debug profile, confirm
   the persistence counter increases and paths remain unchanged.
6. Guest Release relaunch: close and relaunch the same Release profile,
   confirm the persistence counter increases and paths remain unchanged.

For every report record:

- `context.getExternalFilesDirs.count` and entries;
- `environment.isExternalStorageManager`;
- all `permission.*` and `appops.*` lines;
- `vlc.externalFilesDir`, `vlc.dbDir`, and `vlc.thumbnailPath`;
- Java thumbnail mkdir/write/read result;
- native mkdir/open/write/close result and errno on failure; and
- `internalPersistence.launches`.

Do not classify a guest result from an older APK build as a 2.0 native-probe
result. The APK version and imported guest profile must be recorded.
