# Level 8C — Markor WebView compatibility investigation

Device: OnePlus CPH2605, Android 15 / API 35, arm64  
Application: Markor 2.15.2  
Package: `net.gsantner.markor`  
Artifact: `net.gsantner.markor_161.apk`, single APK  
Host: `co.tdevs.duplika`

## Selection rationale

Markor is an ordinary single-APK open-source productivity application. Its
Markdown preview declares and instantiates `android.webkit.WebView`; this
provided a real-world WebView screen without account, GMS, banking, or
security-bypass requirements.

## Physical results

| Build | Import | Guest launch/UI | WebView initialization | Public URL action | Result |
|---|---|---|---|---|---|
| Debug | PASS | PASS | PASS: Markor preview created an `android.webkit.WebView` and rendered the document | Link opened `https://www.example.com` in Chrome Custom Tab; not embedded WebView | PARTIAL |
| Release | PASS | PASS initially | NOT REACHED for the final WebView step | FAIL before WebView test when opening the document | FAIL |

Debug evidence showed the preview surface and rendered Markdown content. The
public link action was deliberately not counted as embedded-WebView navigation
because ActivityManager showed Chrome's `CustomTabActivity`.

## Confirmed Release failure

When opening the imported document, the guest process failed during
application binding, before the requested WebView operation:

- `PackageManager service is null, attempting reinitialization`
- `No existing APK found for net.gsantner.markor, using null path`
- `Unable to makeApplication - all fallback attempts failed`
- `ClassCastException: android.app.ContextImpl cannot be cast to android.app.Application`
- failure location: `top.niunaijun.blackbox.app.BActivityThread.handleBindApplication`

This is classified as a general guest process/application initialization
failure, not as a TLS, DNS, WebView-provider, or certificate failure. The
log also records the WebView sandbox process later dying after the host-side
guest failure, so that is secondary evidence rather than the first failure.

## Evidence files

- `metadata.txt`
- `release-import-selection.log`, `release-import.log`, `release-launch.log`
- `release-file-open-failure.log`, `release-file-open-failure.png`
- `debug-import.log`, `debug-launch.log`, `debug-file-open.log`
- `debug-webview.log`, `debug-webview.png`
- `debug-webview-navigation.log`, `debug-webview-navigation.png`
- `debug-webview-remote.log`, `debug-webview-remote.png`

No Flutter, Kotlin, Bcore, or virtualization-engine source was modified.
No WebView security behavior, TLS validation, or application APK was changed.

## Follow-up Release diagnostic

Disabling Release minification/resource shrinking temporarily allowed the same
imported Markor profile to open `DocumentActivity` on the physical device;
see `release-file-open-nominify.log`. This confirms the Release-only boundary
is R8/minification-related, while the exact minimal general keep rule remains
unverified. A broad host-package keep diagnostic could not be tested because
ADB subsequently failed with `could not install *smartsocket* listener:
Operation not permitted`; that temporary rule was removed.
