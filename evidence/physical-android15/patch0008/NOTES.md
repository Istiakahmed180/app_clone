# Patch 0008 — evidence, 2026-09-10

Engine `f38fa7d3…be4af` → `7769e0d4cfa09ee1d9b42d76d74b6c7761602546734c49715cb6228329df160d`.
Release build, R8 minified. Chrome 152.0.7977.82, 6 splits. OnePlus CPH2605, Android 15/API 35.

Verdict: **PARTIAL** — the instanceName rejection is eliminated and Chrome reaches a working
New Tab with a real renderer + GPU process, but pre-existing Defect B
(`Unable to makeApplication`) fails ~50% of guest launches.

## Marker counts (vs the pre-0008 run in ../duplika-chrome-reference/run-2026-09-10/)

|                                      | pre-0008 | post-0008 |
|--------------------------------------|----------|-----------|
| `Can't use instance name`            | 8        | **0**     |
| `cr_JniAndroid: Handling uncaught`   | 2        | **0**     |
| SIGTRAP browser aborts               | 4/4      | **0**     |
| `Unable to makeApplication`          | 0        | 41        |
| `ContextImpl cannot be cast to App`  | 0        | 28        |

## Chrome runs

| Run | Launch | Outcome |
|-----|--------|---------|
| 1 | 10:03:44 | bind accepted, proxy proc started, makeApplication failed; Chrome alive 278 s, FRE stuck |
| 2 | 10:08:48 | guest never started (makeApplication) |
| 3 | 10:10:17 | **browser + privileged_process0 + sandboxed_process0 all at u0_a977; FRE completed; New Tab reached with live content** |
| 4 | 10:15:20 | guest never started (ProxyActivity$P1 makeApplication) |
| 5 | 10:17:40 | browser + GPU + renderer up; session restored; page did not render |

## Regressions

- 0006 `usermanagerprobe`: **PASS** (P1/P2/P3 SUCCESS, virtualUserId=2)
- 0007 `level11_isosplit`: **PASS** ("split-manifest component registration works")
- Level 6: **PASS** (SQLite value=1, notification posted, job result=0 = modal historical)
- Level 7/8 VLC: **PASS** (libvlc 3.0.23, native libs from split_config.arm64_v8a.apk)
- `flutter analyze` 0 errors · `flutter test` 276/276

Not run: Level 8 Markor/Fossify/AntennaPod, WebView-isolation tests, debug-build runs,
and the 0007-vs-0008 A/B that would settle Defect B attribution on the activity path.

## Files

- `chrome-timestamps-0008.txt` — step timestamps
- `chrome-focused-excerpt-0008.txt` — filtered log (raw `*.log` is gitignored)
- `chrome-process-timeline-0008.log` — per-second process deltas
- `probe-HOST.txt`, `probe-GUEST-release-0008*.txt` — level12 fixture, host + guest
- `crash-buffer.txt` — Defect B fatal chain
- `regress-*.txt` — regression captures
- `p0008_*.png` — screenshots

No account, credential, cookie, token, or private app data was read or recorded.
