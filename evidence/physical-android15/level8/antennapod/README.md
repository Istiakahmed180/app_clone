# Level 8B — AntennaPod 3.11.2 networking test

Device: OnePlus CPH2605, Android 15 / API 35, arm64  
Package: `de.danoeh.antennapod`  
Version: 3.11.2 (`versionCode 3110295`)  
Artifact: `de.danoeh.antennapod_3110295.apk`, single APK  
Host package: `co.tdevs.duplika`

## Observable operation

Using the user-facing Duplika import flow, the guest was launched and the
AntennaPod public search flow was used. Query `science` followed by
`Search online` returned visible public podcast results, including
“Science Magazine Podcast” and “Science for Sport Podcast”. No account,
GMS dependency, security bypass, or protected service was used.

## Results

| Build | Import | Launch/UI | HTTPS operation | Close/relaunch | Result |
|---|---|---|---|---|---|
| Debug | PASS | PASS | PASS: public search results visible | PASS: same guest profile relaunched | PASS |
| Release | PASS | PASS | PASS: public search results visible | PASS: same guest profile relaunched | PASS |

The release test used a clean host install and a fresh import. Relaunch was
performed after closing the guest and reopening the same imported profile.

## Evidence

- `metadata.txt`
- `debug-import.log`, `debug-launch.log`, `debug-network-online.log`, `debug-relaunch.log`
- `debug-launch.png`, `debug-network-online.png`, `debug-relaunch.png`
- `release-import-selection.log`, `release-import.log`, `release-launch.log`, `release-network.log`, `release-relaunch.log`
- `release-launch.png`, `release-network.png`, `release-relaunch.png`

The logs contain normal device/network diagnostics. A single remote artwork
URL produced a Glide warning while search results still loaded; this did not
prevent the tested HTTPS search operation or guest UI.

No Flutter, Kotlin, Bcore, or virtualization-engine source was modified for
this test.
