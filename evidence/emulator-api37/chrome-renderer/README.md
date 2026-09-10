# Chrome renderers — instance-aware slot allocation (patch 0010)

Emulator `sdk_gphone64_arm64`, Android 15 / API 35. Chrome 152.0.7977.82.

## Before

With patch 0009 the fatal locale crash was gone, but web content never rendered:

```
BProcessManager: initProcess: com.android.chrome:sandboxed_process0
BProcessManager: App Died:    com.android.chrome:sandboxed_process0
cr_ChildProcessConn: onServiceDisconnected (crash or killed by oom): pid=12429
```

Every renderer instance collapsed into one `ProxyService$P1` slot and evicted the previous
process. `docs/multiapp-vs-duplika-chrome-comparison.md` §10 named this gap and deferred it.

## After

| Signal | Before | After |
| --- | --- | --- |
| Distinct proxy slots | `P1` only | **`P1 P3 P4 P5 P6 P8 P9`** |
| bpid allocations | 1 | **0–9** |
| `:privileged_process0` (GPU) | never created | **created** |
| `:sandboxed_process0` (renderer) | died on loop | **alive** |
| `onServiceDisconnected` | every bind | **0** |
| `FATAL EXCEPTION` | — | **0** |
| New Tab page | never reached | **renders, with live Discover content and images** |

`newtab-rendered.png` is the New Tab page inside the clone: Google logo, omnibox, shortcut
tiles, and Discover articles with fetched thumbnails. Thumbnails are renderer output, so
this is proof of rendering rather than of native UI.

12 `App Died: …:sandboxed_process0` lines remain, but with **zero** `onServiceDisconnected`
— Chrome recycling its own renderers, not the container evicting them. That is the
difference from the before-state, where the two always appeared together.

## Errors still in the log, and what they are

462 `GoogleApiManager` + the `GenericAppFlowLogger`, `Finsky`, `Auth`, `cr_AccountManager`,
`PhenotypeFlagCommitter` and `DatabaseUtils` lines downstream of them are the documented
caller-identity boundary (`docs/level10-gms-caller-identity-boundary.md`) and its knock-on
effects: analytics, flag sync, font fetch, account lookup. None is fatal; Chrome renders
through all of them.

Ours in that list, and small: `NativeCore: Didn't find setHiddenApiExemptions` (17) and
`GmsProxy: Failed to get gms service binder` (16) are pre-existing and unrelated to
rendering. `ActivityManagerStub: Unexpected error in updateServiceGroup` (7) is new to look
at but did not stop anything.

## Not covered here

Chrome's first-run sign-in step ("Make Chrome your own") still appears. Getting past it
requires accepting Chrome's Terms of Service, which is the device owner's decision, so the
flow beyond that point is unverified.
