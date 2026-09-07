# Level 8C Release startup investigation

Device: OnePlus CPH2605, Android 15/API 35
Guest: Markor 2.15.2 (`net.gsantner.markor`)

## Finding

The initial observed Release-only failure appeared to be in the guest
application bind path. That earlier run is retained as historical evidence in
`release-file-open-failure.log`.

The clean physical re-test below did not reproduce that bind failure.

1. Bcore cannot obtain its PackageManager service.
2. Fallback `ApplicationInfo`/`PackageInfo` objects are created with null APK
   paths for both host and guest packages.
3. `LoadedApk.makeApplication()` and the fallback path fail.
4. `BActivityThread.handleBindApplication()` throws
   `ClassCastException: android.app.ContextImpl cannot be cast to
   android.app.Application`.

The relevant evidence is in `release-file-open-failure.log`.

## Controlled diagnostic

The same Release flow was built with minification and resource shrinking
disabled temporarily. On the physical device, the imported Markor profile then
opened `DocumentActivity` successfully and displayed the document editor. The
diagnostic log is `release-file-open-nominify.log`; it contains no fatal
exception, null-APK-path failure, or PackageManager-null failure for that file
open.

At that stage this appeared to establish R8/minification as the causal
boundary, but the clean minified re-test below did not reproduce it. No R8
rule should be added from this earlier run alone.

A second temporary broad keep diagnostic for `co.tdevs.duplika.**` was built,
but could not be physically tested because the local ADB daemon failed again
with `could not install *smartsocket* listener: Operation not permitted`. The
temporary rule was removed; no unverified workaround remains in project code.

## Current status

The R8 hypothesis remains unconfirmed and no R8 keep rule was added. The
general WebView process-isolation fix is implemented in
`WebViewProcessIsolation.kt` and has passed physical Debug and minified Release
verification, including local preview and same-profile relaunch.

## ADB recovery state

Read-only diagnostics found the stale listener at `127.0.0.1:5037`:

- PID: `63023`
- owner: `tdevs`
- executable: `/Users/tdevs/Library/Android/sdk/platform-tools/adb`
- working directory: `/Users/tdevs/Library/Android/sdk/platform-tools`
- observed active device transport before the failure: `KNOJORMFV4GERKHM`

The current shell cannot query the parent process because macOS denied the
process-list request, and new ADB clients cannot connect to the listener:
`Operation not permitted`. No project-code or engine changes were made for
this infrastructure failure. Full diagnostics are in `adb-recovery.log`.

## Clean minified Release re-test

After ADB was restored from the normal macOS Terminal, a clean minified
Release APK was built and installed on the physical device. Through the
user-facing Duplika flow, Markor reached `MainActivity` and `IntroActivity`.
The startup log contains no `FATAL EXCEPTION`, `Unable to makeApplication`, or
`ContextImpl`→`Application` failure.

Opening a document then produced the explicit first fatal error:

`Using WebView from more than one process at once with the same data directory`

The lock owner and current process were both `net.gsantner.markor` with
different PIDs. The stack enters `DraggableScrollbarWebView` inflation and
Markor's `ApplicationObject.onCreate`, then Bcore's activity binding delegate.
This is a WebView multi-process data-directory failure, not evidence of an R8
retention failure. The PackageManager-null messages in this run were warnings;
the guest reached its UI.

No broad keep rule or minimal R8 rule was added. The confirmed WebView fix and
its final physical evidence are documented in `webview-root-cause-analysis.md`.
