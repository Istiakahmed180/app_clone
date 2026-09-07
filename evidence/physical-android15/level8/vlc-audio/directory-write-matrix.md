# Directory-write matrix

All rows were physically tested on OnePlus CPH2605 / Android 15.

| Location | Normal Debug | Normal Release | Guest Debug | Guest Release | Relaunch persistence |
|---|---:|---:|---:|---:|---:|
| `Context.getFilesDir()` | PASS | PASS | PASS | PASS | PASS |
| `Context.getCacheDir()` | PASS | PASS | PASS | PASS | PASS |
| `Context.getExternalFilesDir(null)` | PASS | PASS | PASS | PASS | PASS |
| `Context.getExternalCacheDir()` | PASS | PASS | PASS | PASS | PASS |
| `Context.getExternalMediaDirs()[0]` | PASS | PASS | PASS | PASS | PASS |
| `<externalFiles>/medialib/thumbnails` | PASS | PASS | PASS | PASS | PASS |

The guest tests used the virtual path supplied by Duplika and did not chmod,
grant all-files access, or alter shared-storage permissions.
