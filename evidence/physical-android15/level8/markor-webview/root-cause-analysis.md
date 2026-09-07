# Level 8C Release startup investigation

Device: OnePlus CPH2605, Android 15/API 35
Guest: Markor 2.15.2 (`net.gsantner.markor`)

## Finding

The first observed Release-only failure is in the guest application bind path,
not in WebView. The minified Release log records the following order:

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

This establishes R8/minification as the current causal boundary for the
Release-only startup failure. It does not yet identify the minimal keep rule.

A second temporary broad keep diagnostic for `co.tdevs.duplika.**` was built,
but could not be physically tested because the local ADB daemon failed again
with `could not install *smartsocket* listener: Operation not permitted`. The
temporary rule was removed; no unverified workaround remains in project code.

## Current status

No WebView fix was attempted. No Bcore or virtualization-engine source was
modified. A physical post-fix Debug/Release verification remains pending until
ADB connectivity is restored and a minimal general R8 rule is confirmed.

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
