# Storage-volume diagnostic

Device: OnePlus CPH2605 / Android 15 / API 35  
Serial: `KNOJORMFV4GERKHM`

Diagnostic APK: `com.example.duplikaladder.storageprobe`, version 1.1,
target SDK 35. It requests no storage permissions and only uses ordinary
storage APIs.

## Results

### Normally installed APK

- UID: `10950`
- `externalStorageState=mounted`
- `externalStorageDirectory=/storage/emulated/0`
- `isExternalStorageManager=false`
- `externalMediaDirs.count=1`
- `storageVolumes.count=1`
- Primary volume: `/storage/emulated/0`, mounted
- Internal, external-files, external-cache, and external-media mkdir/write/read: PASS
- Nested `externalFiles/medialib/thumbnails` mkdir/write/read: PASS

### Debug guest, virtual user 0

- Guest UID reported by the probe: `10001`
- External storage is mapped below Duplika's virtual root
- `isExternalStorageManager=true` under the current virtual hooks
- `externalMediaDirs.count=1`
- `storageVolumes.count=1`
- Primary virtual volume is present and mounted
- Internal, external-files, external-cache, and external-media mkdir/write/read: PASS
- Nested `medialib/thumbnails` mkdir/write/read: PASS
- Same profile relaunch counter: `launches=2`

### Release guest, virtual users 1 and 3

- `storageVolumes.count=1` for both tested Release profiles
- Primary virtual volume is present and mounted
- Nested `externalFiles/medialib/thumbnails` mkdir/write/read: PASS
- User 1 relaunch counter: `launches=2`
- User 3 relaunch counter: `launches=2`

## Decision

The empty-volume result does not reproduce in a minimal guest APK. The
general virtual storage volume path is present for both Debug and Release,
and app-specific external storage is writable through ordinary Java APIs.

This does not erase the VLC evidence. It means the VLC Debug exception is
not explained by a universal missing-volume defect, and the VLC Release
native mkdir denial is not explained by a universal inability to write the
same nested Java path.
