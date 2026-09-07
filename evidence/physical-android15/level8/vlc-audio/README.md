# Level 8D — VLC Android media compatibility

Device: OnePlus CPH2605 / Android 15 / API 35 / arm64  
ADB serial: `KNOJORMFV4GERKHM`

## Selected application

- Application: VLC for Android
- Version: 3.7.1
- Package: `org.videolan.vlc`
- Artifact: `VLC-Android-3.7.1-arm64-v8a.apk`
- APK type: single APK, arm64-v8a native libraries
- SHA-256: `bea9ea0cdecfd8f461ef305d2afe5d1ac1459cfb9156acce2f615788a486de74`
- Source: official VideoLAN download mirror

## Why selected

VLC introduces a new media compatibility surface not covered by the existing
Fossify Notes, AntennaPod, or Markor tests:

- native media libraries (`libvlc.so`, `libvlcjni.so`)
- local audio/video playback
- media playback foreground service
- media notification and playback controls
- media-storage access on Android 15
- activity/service lifecycle during playback and relaunch

The test does not involve GMS, authentication, Play Integrity, DRM bypass, or
security bypasses.

## Status

Selection and artifact validation: PASS.  
Debug/Release launch and native loading: PASS.  
Media-library playback compatibility: FAIL/PARTIAL because of the confirmed
Android 15 virtual-storage permission boundary. See `failure-analysis.md`.
