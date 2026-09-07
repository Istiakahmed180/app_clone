# Level 8C WebView compatibility verification

Device: OnePlus CPH2605 / Android 15 / API 35  
ADB serial: `KNOJORMFV4GERKHM`  
Guest: Markor 2.15.2 (`net.gsantner.markor`)

## Root cause

The first reproducible fatal was Android WebView's per-process data-directory
lock. Bcore hosts guest components in real Duplika processes such as
`co.tdevs.duplika:p0` and `co.tdevs.duplika:p1`, while Markor's application
initializes WebView from its application lifecycle. Two real processes could
therefore initialize WebView against the same default directory.

The original failure evidence is in `webview-data-directory-conflict.log` and
`release-minified-host-crash.log`. It records:

`Using WebView from more than one process at once with the same data directory`

The crashing process was guest-visible as `net.gsantner.markor`, while the
actual host process was a Duplika process. This is a host-process isolation
problem, not a package-specific Markor workaround and not a confirmed R8
retention problem. The clean minified Release startup reached Markor UI before
the WebView failure, and the historical PackageManager/ClassCastException did
not recur.

## General fix

`WebViewProcessIsolation` calls `WebView.setDataDirectorySuffix()` from
`DuplikaApplication.attachBaseContext()` before the virtualization engine is
attached. The suffix is derived from the actual Android process name, so each
Duplika process gets a deterministic, distinct WebView directory. No guest
package name, Bcore code, R8 rule, or GMS behavior is hardcoded.

Modified source:

- `android/app/src/main/kotlin/co/tdevs/duplika/DuplikaApplication.kt`
- `android/app/src/main/kotlin/co/tdevs/duplika/WebViewProcessIsolation.kt`

## Physical verification

### Debug

- `flutter build apk --debug`: PASS
- Host install: PASS
- Existing Markor profile launched through the user-facing Duplika UI: PASS
- Markor file browser and persisted `webview_test.md`: PASS
- Local Markdown preview: PASS
- UI hierarchy contained `android.webkit.WebView`: PASS
- No `FATAL EXCEPTION` or WebView data-directory conflict: PASS
- Host stopped and the same profile relaunched through the user-facing UI: PASS
- `webview-fix-debug.log`, `webview-relaunch-debug.log`, and
  `webview-fix-debug.png` contain the evidence.

### Release

- `flutter build apk --release` with minification enabled: PASS
- Host install: PASS
- Existing Markor profile launched through the user-facing Duplika UI: PASS
- Markor file browser and persisted `webview_test.md`: PASS
- Local Markdown preview: PASS
- UI hierarchy contained `android.webkit.WebView`: PASS
- No `FATAL EXCEPTION` or WebView data-directory conflict: PASS
- Host stopped and the same profile relaunched through the user-facing UI: PASS
- `webview-fix-release.log`, `webview-relaunch-release.log`, and
  `webview-fix-release.png` contain the evidence.

## Remaining limitation

Markor's public URL action opens a Chrome Custom Tab. That is a separate
external-browser flow and is not evidence of embedded WebView failure. This
Level 8C result verifies local embedded WebView startup/rendering and same-
profile relaunch only.
