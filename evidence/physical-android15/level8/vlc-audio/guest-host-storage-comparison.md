# Guest/host storage comparison

| Property | Normal APK | Duplika guest |
|---|---|---|
| Host package UID | `10950` for probe | Duplika host UID `10951`; guest probe reported virtual UID `10001` |
| Virtual user | platform user 0 | tested users 0, 1, 2, and 3 |
| Volume count | 1 | 1 |
| Volume state | mounted | mounted |
| Volume path | `/storage/emulated/0` | Duplika virtual path ending in `/storage/emulated/<virtualUser>` |
| External media count | 1 | 1 |
| App-specific external write | PASS | PASS |
| Nested media-library directory write | PASS | PASS |
| `isExternalStorageManager()` | false | true under the current virtual permission hooks |

The virtual user-to-path mapping is consistent: users 0, 1, 2, and 3 were
observed under corresponding `storage/emulated/0`, `/1`, `/2`, and `/3`
directories. This is evidence of working volume/path initialization for the
controlled guest, not evidence that VLC media playback works.
