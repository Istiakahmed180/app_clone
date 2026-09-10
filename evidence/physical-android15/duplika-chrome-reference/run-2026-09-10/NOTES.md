# Duplika — 2026-09-10 live re-confirmation

Release build (R8 minified) of `70b6431`, engine `bcore.aar` sha256 f38fa7d3…be4af
(unchanged since 9387659). Fresh install, fresh Chrome clone.
Chrome 152.0.7977.82 (797708204), 6 splits.

Two attempts, both fatal, both identical to the 2026-09-09 run:

| | attempt 1 | attempt 2 |
|---|---|---|
| launch | 09:29:55 | 09:32:13 |
| first-run UI | 09:30:28 | 09:32:23 |
| "Stay signed out" tap | not tapped | 09:32:41 (`signin_fre_dismiss_button`) |
| fatal `IllegalArgumentException` | 09:30:36.728 | 09:32:53.904 |
| SIGTRAP / process gone | 09:30:38.915 | 09:32:57.631 |
| browser lifetime | 43.9 s | 44.6 s |
| renderer / GPU / New Tab | none | none |

The renderer bind is attempted ~41 s after launch regardless of the tap, so the
"Stay signed out" click is not the trigger.

Fatal, every attempt:

    IllegalArgumentException: Can't use instance name '0' with non-isolated
    non-sdk sandbox service 'top.niunaijun.blackbox.proxy.ProxyService$P1'
      at ActivityManagerService.bindServiceInstance(ASM.java:15388)
    → cr_JniAndroid uncaught → SIGTRAP

Files:
- `dup-timestamps.txt` — full step-by-step timestamps
- `dup-focused-excerpt.txt` — filtered log lines (raw `dup-logcat.log` is gitignored)
- `dup-process-timeline.log` — per-second process table deltas
- `chrome-base-manifest-xmltree.txt` — Chrome's own service declarations
  (`SandboxedProcessService0`: isolatedProcess=true, useAppZygote=true)
- `dup_1*.png`, `dup_2*.png` — screenshots

No account, credential, cookie, token, or private app data was read or recorded.
