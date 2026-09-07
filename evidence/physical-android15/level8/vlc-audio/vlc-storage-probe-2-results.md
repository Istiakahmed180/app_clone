# VLC Storage Probe 2.0 physical results

Device: OnePlus CPH2605, Android 15 / API 35
Serial: `KNOJORMFV4GERKHM`
Probe package: `com.example.duplikaladder.storageprobe`

## Build

Debug and Release APKs both built successfully with the native C++ probe.

## Host results

| Scenario | Result | Evidence |
|---|---|---|
| Host Debug | PASS | One mounted primary volume; one `getExternalFilesDirs()` entry; VLC-style Java thumbnail mkdir/write/read PASS; native mkdir/open/write/close PASS |
| Host Release | PASS | Same results as Host Debug; native file uid/gid and canonical path reported |

Observed on both host variants:

```text
externalStorageState=mounted
environment.isExternalStorageManager=false
context.getExternalFilesDirs.count=1
vlc.dbDir.canWrite=true
vlc.thumbnailPath ... exists=true readable=true writable=true
vlc.thumbnailPath.mkdir=true,write=true,read=true
native.mkdir=true
native.open=true
native.write=true
native.close=true
```

The diagnostic APK declared the VLC-related storage/media permissions, but no
permission bypass or artificial grant was performed. The physical host report
showed the declared permissions as denied/default/ignored while app-specific
external storage and native file I/O still succeeded.

## Guest matrix

The current source and APK are ready for guest import. Guest Debug, Guest
Release, and both guest relaunch rows must be run by importing this exact 2.0
APK through the user-facing Duplika picker. Results from earlier StorageProbe
1.x/2.x imports do not contain the native probe and are not substituted here.

| Scenario | Status | Required evidence |
|---|---|---|
| Guest Debug | PENDING | Exact 2.0 APK imported, virtual paths, permissions/AppOps, native errno result |
| Guest Release | PENDING | Exact 2.0 APK imported, virtual paths, permissions/AppOps, native errno result |
| Guest Debug relaunch | PENDING | Same profile, counter increment, same native/path result |
| Guest Release relaunch | PENDING | Same profile, counter increment, same native/path result |

No production fix is justified by the host results alone. Level 8D remains
PARTIAL until VLC itself and this guest diagnostic are correlated on the
physical device.
