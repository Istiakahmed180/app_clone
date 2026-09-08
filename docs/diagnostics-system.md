# Diagnostics and logging

A centralized, structured logging system and an in-app Developer Console, so that when
something fails anywhere in Duplika — Flutter, Dart, the method channel, the Kotlin
engine, Bcore, a guest process — a developer can open one screen and read what happened,
when, in which subsystem, to which clone, and in what order.

Everything here is **additive**. No existing engine, installer, launcher or profile code
changed behaviour; the diagnostics layer observes, and the one place it touches control
flow (`Slog`) still writes to Logcat exactly as it did.

---

## 1. Architecture

```
Flutter / Dart
      │
      ├─ FlutterError.onError ─────┐
      ├─ PlatformDispatcher.onError┤   (chained, never replaced)
      ├─ runZonedGuarded ──────────┤
      ├─ AppLogger (existing sites)┤
      ├─ DiagnosticOperation.run() ┤   ← mints the correlation id
      └─ ChannelDiagnostics.trace()┘   ← wraps every platform call
                     │
                     ▼
            DiagnosticLogger  (lib/core/diagnostics/diagnostic_logger.dart)
             │                     │
             ▼                     ▼
      DiagnosticBuffer     FileDiagnosticEventStore
      (ring, 1000)         (2 × 512 KB JSONL segments)
             │                     │
             └──────────┬──────────┘
                        ▼
              DiagnosticsRepository ──────────► Developer Console (GetX)
                        ▲
                        │  live events + history
                        │
              NativeDiagnostics
              (MethodChannel + EventChannel)
                        ▲
════════════════════════╪══════════════════════════════════ platform boundary
                        │
              DiagnosticsBridge  (android/.../diagnostics/DiagnosticsBridge.kt)
                        ▲
                        │
            DiagnosticLogger (Kotlin object, one per process)
             │                     │
             ▼                     ▼
        ring (500)          DiagnosticStore
                            files/diagnostics/native-<process>.jsonl
                        ▲
      ┌─────────────────┼──────────────────┬───────────────┬──────────────┐
   Slog (55 sites)  RealVirtualization  PermissionBridge  CrashCapture  Probes
                    Engine phases                          (uncaught)   (on demand)
```

### Why native events are persisted natively

Bcore runs guest activities in **separate host processes** (`:p0`, `:p1`, … and
`:black`), where `DuplikaApplication` is instantiated again and where **no Flutter engine
exists**. A launch failure, a WebView data-directory clash or a storage error inside one
of those processes cannot be sent over a method channel, because there is no channel
there.

So each process appends to its own file under the host's real `filesDir`, and the main
process reads them all back and merges them. This also means no cross-process locking is
needed: a process only ever appends to its own file.

Verified on device — `native-co.tdevs.duplika_black.jsonl` contains the `:black`
process's own `attachBaseContext` / WebView / engine-attach events.

### Why `DiagnosticLogger.initialize()` runs first in `attachBaseContext`

Attaching Bcore rewrites the process's data directory for guest apps. Resolving the log
directory **before** that keeps every process — host and stub alike — writing into the
host's real `filesDir`, and it is also what makes the WebView-isolation and engine-attach
steps (the two most common start-up failures) instrumentable at all.

---

## 2. Log model

One shape on both sides: `lib/core/diagnostics/diagnostic_event.dart` and
`android/.../diagnostics/DiagnosticEvent.kt`. Wire names are written out explicitly
rather than derived from enum names, so renaming a constant cannot silently invalidate
events already on disk.

| Field | Notes |
| --- | --- |
| `id` | Unique within a run. Prefixed per run/process, so ids never collide. |
| `timestamp` | ISO-8601 UTC with milliseconds. |
| `sequence` | Monotonic per process. Two events can share a millisecond. |
| `level` | See below. |
| `source` | *Who* is talking. |
| `category` | *What* they were doing. |
| `operation` | Correlation id. The reason the timeline view exists. |
| `operationName` | e.g. `launch Notes`. |
| `message` | Redacted at record time. |
| `details` | Longer form, usually the exception's own text. |
| `stackTrace` | Trimmed: 40 Dart frames / 60 JVM lines. |
| `exceptionType` | Fully-qualified class name. |
| `packageName`, `profileId`, `virtualUserId` | Which clone. |
| `processName`, `thread` | Which process and thread. |
| `buildType`, `appVersion`, `deviceInfo` | So a release report is never read as a debug one. |
| `metadata` | Free-form string map, redacted. Carries the phase name under `event`. |

Every field except `id`, `timestamp`, `level`, `source`, `category` and `message` is
optional. Forcing a caller to invent a `profileId` for an event that has nothing to do
with a profile is how log fields become lies.

### Levels

`DEBUG` · `INFO` · `SUCCESS` · `WARNING` · `ERROR` · `FATAL`

`SUCCESS` sits between `INFO` and `WARNING` on purpose: a completed operation is worth
finding quickly in a wall of `INFO`, but it is not a problem, so a "warning and above"
severity filter must not pick it up.

`DEBUG` is **memory-only**. It is the noisiest level and the least useful after the fact,
so the size-bounded file budget is spent on everything else. Routine method-channel
traffic is recorded at `DEBUG`; the operations that change state are `INFO`.

### Sources

`FLUTTER` `DART` `ANDROID` `KOTLIN` `METHOD_CHANNEL` `VIRTUAL_ENGINE` `BCORE`
`APK_IMPORTER` `PACKAGE_INSTALLER` `GUEST_PROCESS` `ACTIVITY` `PERMISSION` `STORAGE`
`WEBVIEW` `NOTIFICATION` `JOBSCHEDULER` `NETWORK` `NATIVE` `SYSTEM`

`VIRTUAL_ENGINE` is Duplika's engine layer; `BCORE` is the backend itself. They are
separate because "which of the two is talking" is usually the first thing worth knowing.

### Categories

`APP_LIFECYCLE` `IMPORT` `INSTALL` `PROFILE` `LAUNCH` `PROCESS` `ACTIVITY` `STORAGE`
`PERMISSION` `WEBVIEW` `NOTIFICATION` `JOB` `NETWORK` `NATIVE_LIBRARY` `CRASH` `UNKNOWN`

An unknown wire value parses to a fallback (`INFO` / `SYSTEM` / `UNKNOWN`) rather than
throwing, so a stored event written by a newer build cannot make its segment unreadable.

---

## 3. Correlation IDs

Format: `<kind>_<yyyyMMdd>_<run>_<NNN>` — e.g. `launch_20260908_2cn_001`.

Readable on purpose: a developer reads these out of a bug report and searches for them,
so an opaque UUID would be a worse answer.

The `<run>` token (three base-36 characters from the clock) is **not decoration**. The
ordinal counter restarts with the process, and the persistent log outlives a restart, so
without it two runs on the same day both produce `engine_init_20260908_001` and the
console merges them into one operation minutes long. That was observed on the device
during verification.

### How the id travels

1. `DiagnosticOperation.run()` in `RealVirtualizationEngine` (Dart) mints it and installs
   it as a **zone value**, so every `await` inside the body inherits it.
2. `NativeBridge._withCorrelation()` adds `__opId` / `__opName` to the arguments of the
   platform call. The keys are `__`-prefixed so they can never collide with a real
   parameter, and native code that does not look for them ignores them.
3. Kotlin `NativeBridge.onMethodCall` installs it as a **thread-local** for the dispatch,
   and `submit()` captures it and re-applies it on the engine executor thread.
4. Everything below — the installer, the launcher, `Slog`, the Bcore adapter — emits
   events tagged with it without taking a diagnostics parameter.

`CloneLauncherActivity` mints its own (`shortcut_<millis36>`), because a shortcut launch
never passes through Flutter.

Operations that mint an id: `engine_init`, `clone`, `import`, `apk_import`, `launch`,
`delete`, `shortcut`.

---

## 4. What is captured

### Flutter / Dart

| Hook | Records |
| --- | --- |
| `FlutterError.onError` | Framework errors, as `FLUTTER` / `CRASH`, level `ERROR`. |
| `PlatformDispatcher.instance.onError` | Errors raised outside the guarded zone. |
| `runZonedGuarded` | Uncaught async errors, as `DART` / `CRASH`, level `FATAL`. |
| `AppLogger` | The pre-existing `_logger.info` / `_logger.error` sites. |

Every hook **chains** to whatever was installed before it and then lets the platform do
what it would have done anyway: framework errors still reach `FlutterError.presentError`,
uncaught async errors still get dumped to the console, and a release build still fails the
same way. `PlatformDispatcher.onError` returns `false` ("not handled") so the engine's own
reporting stays intact. `install()` is idempotent, so a hot restart does not chain the
same handler onto itself.

`main()` initialises the binding **inside** the guarded zone. Initialising it in one zone
and calling `runApp` in another is the mistake that makes a guarded `main` misbehave.

### Method channel

`ChannelDiagnostics.trace()` wraps the single place that invokes the channel
(`NativeBridge._invokeMap`), so a method added later is instrumented by construction.
Each call records **start**, then **success** or **failure**, with channel, method,
argument summary, duration in ms, and a result summary (`success=` / `code=` from the
envelope — never the payload, which would put installed-app lists and icon maps in the
log). The result and any exception pass through untouched.

Argument summaries are values, not payloads: a list becomes its length, a path becomes
its filename under a root label, a long string is truncated, anything under a sensitive
key is dropped, and `includeIcons` / `icons` are skipped outright.

### Virtualization engine (named phases)

Emitted from the Kotlin `RealVirtualizationEngine`, carried in `metadata["event"]` so
they survive message edits and can be searched for:

`ENGINE_INITIALIZATION_STARTED` · `_SUCCESS` · `_FAILED`
`PROFILE_CREATION_STARTED` · `_SUCCESS` · `_FAILED`
`APK_IMPORT_STARTED` · `APK_METADATA_PARSED` · `APK_VALIDATION_SUCCESS` · `_FAILED`
`PACKAGE_INSTALL_STARTED` · `BASE_APK_INSTALL` · `SPLIT_APK_INSTALL` · `PACKAGE_INSTALL_SUCCESS` · `_FAILED`
`GUEST_PROCESS_STARTING` · `_STARTED` · `_FAILED`
`ACTIVITY_LAUNCH_STARTED` · `_SUCCESS` · `_FAILED`
`GUEST_CLOSE` · `GUEST_RELAUNCH`
`PROFILE_DELETE_SUCCESS` · `_FAILED`
`SHORTCUT_LAUNCH_STARTED`

The phase events sit at the **caller** level; the inner cause (Bcore's own verdict) is
still logged by the existing `Slog` line inside the adapter. Outer phase plus inner
reason, not two copies of the same fact.

### Bcore

Not redesigned, and not modified to make logging easier. The adapter's existing log lines
were re-tagged from `Duplika.Engine` to `Duplika.Bcore` (source `BCORE`) so the backend's
own behaviour — its service backoff, its null-binder window, its install verdicts — can be
filtered apart from Duplika's decisions. No fake success events: an install that Bcore
refused is recorded as refused, with its code and reason.

### Permissions

`PermissionBridge` records `PERMISSION_CHECK`, `PERMISSION_ALREADY_GRANTED`,
`PERMISSION_REQUEST_SHOWN`, `PERMISSION_REQUEST_BUSY`, `PERMISSION_REQUEST_CANCELLED`,
`PERMISSION_RESULT` (with granted/denied lists). A denial is the user's decision and is
respected, so it is a `WARNING`, not an `ERROR` — but it is visible, because it is the
reason a feature inside the clone will not work.

Nothing here requests anything. No permission is ever requested for logging.

### Crashes

`CrashCapture` chains `Thread.setDefaultUncaughtExceptionHandler`, records a `FATAL`
event, **flushes synchronously** (the process is about to die, so the batching that keeps
logging cheap has to be defeated), and then lets the previous handler run. The process
dies exactly as it would have.

---

## 5. Subsystem probes (on demand)

Run from **Developer Tools → Subsystems**. On demand rather than continuously, and that
is a design decision: instrumenting every filesystem call or permission check would
produce thousands of events a second during a media scan and bury everything else.

| Probe | Reads | Never does |
| --- | --- | --- |
| **Storage** | external storage state / emulated / removable, `getExternalStorageDirectory`, `isExternalStorageManager`, `filesDir`, `cacheDir`, `noBackupFilesDir`, `getExternalFilesDir(s)`, `externalCacheDir`, `externalMediaDirs`, `StorageManager` volumes (description only), free/total bytes, storage permission grants. Existence, read, write. | Request `MANAGE_EXTERNAL_STORAGE` or any permission; write outside Duplika's own directories; touch shared storage, MediaStore or another app's data. |
| **WebView** | process name, the data-directory suffix actually in force and its outcome, `getCurrentWebViewPackage`, which providers are visible. | Read any browsing data. |
| **Permissions** | the host's declared permissions, which are dangerous, which are granted, All-files access, `POST_NOTIFICATIONS`. | Request anything. |
| **Notifications** | `areNotificationsEnabled`, importance, interruption filter, channel ids + importance + blocked state. | Read notification content. |
| **Jobs** | `JobScheduler.getAllPendingJobs` for this UID (guest jobs included), service, periodic, persisted, charging, network. | — |

The write test creates and deletes one file (`.duplika-diagnostics-write-test`) inside
app-scoped directories only. `canWrite()` lies often enough on scoped-storage paths to be
worth confirming with a real create-and-delete.

**Native self-test** (overflow menu) raises a real `IllegalStateException` through the
real Kotlin logger, so "does native capture work on this build, on this device" can be
answered rather than assumed. In a release build it asks for confirmation first.

It is recorded at `ERROR` with a full stack trace, because that record *is* the proof —
so it is kept out of the failure counts by identity, not by severity. Its metadata
carries `selfTest: true`; its category is `APP_LIFECYCLE`, not `CRASH`, since nothing
crashed; the Error Center files it under its own *Diagnostics self-test (not a failure)*
group, last; and neither the Errors badge nor the summary's failure total counts it. It is
never hidden: seeing it arrive is the whole point.

---

## 6. Persistence and retention

| | Dart | Kotlin |
| --- | --- | --- |
| Memory | ring buffer, 1000 events | ring buffer, 500 events **per process** |
| Disk | `files/diagnostics/events.jsonl` + `events.1.jsonl` | `files/diagnostics/native-<process>.jsonl` + `.1.jsonl` |
| Segment cap | 512 KB | 384 KB |
| Total on disk | ≤ 1 MB | ≤ 768 KB per process, ≤ 12 process files |
| Read cap | 5000 events | 20 000 events |
| Console window | 3000 merged events | — |

Retention is bounded **twice over**, because either bound alone fails: a byte cap alone
lets a flood of tiny events fill the console, and an event cap alone lets a handful of
huge stack traces fill the disk.

Pruning is **rotation, not rewriting**. When the live segment is full it becomes the
previous segment and the previous one is deleted. Rewriting a log to drop its head would
mean reading and re-serialising the entire history on the code path that has to stay
cheap.

One JSON object per line means a torn write (a process killed mid-append) costs one event
rather than the whole segment; an unparseable line is skipped.

Native events reaching Dart live are **not** written to the Dart store — they already
have a durable copy natively, and writing them again would spend the Dart budget on a
second copy. Merging deduplicates by event id, so an event present in more than one
source is shown once.

---

## 7. Performance

- Recording is synchronous and cheap: build the event, redact it, push into the ring,
  hand to the broadcast stream. Nothing on a caller's path awaits I/O.
- Disk writes are **batched** (25 events / 2 s on Dart, 20 events / 1.5 s on Kotlin) and
  run on a background single-thread executor. The delayed flush uses a *scheduled*
  executor so it does not occupy the writer thread while it waits.
- Redaction has a cheap pre-scan: almost every log line is prose plus a package name and
  cannot contain any of the patterns, so it skips the regex work entirely.
- The console inserts a live event with one predicate call and one list insert; it
  re-filters the whole window only when the filter or the ordering changes.
- Persistence failures are absorbed inside `flush()`. Most flushes are fire-and-forget,
  so a store that threw would surface as an unhandled async error — the logging system
  becoming the incident, which is the one thing it must never do.

Measured on the device: engine init ~220–490 ms, clone create 2621 ms, guest launch
755–1631 ms — all in line with the pre-diagnostics figures in
`docs/PHASE_4_COMPATIBILITY.md`.

---

## 8. Privacy and redaction

Redaction happens **at the point of recording**, not at render time: an event persisted
with a token in it is already leaked, and no amount of careful UI can un-leak it.

Never recorded:

- passwords, tokens, secrets, credentials, cookies, `Authorization` / `Bearer` values
- JWTs (matched on shape — the interesting ones never announce themselves)
- PEM private-key blocks
- payment card numbers (a digit run is only redacted when it passes the Luhn check, so
  version codes, byte counts and epoch millis stay readable)
- notification content, browsing data, any other app's data

Metadata values under a sensitive key are replaced with `[REDACTED]` outright.

Filesystem paths are **sanitised**: the filename survives (because "which APK failed" is
what an import diagnostic exists to answer) and the directories above it collapse to a
root label — `/storage/emulated/0/Download/vlc.apk` → `<shared>/…/vlc.apk`.

System information is limited to build facts and device capabilities. No serial, no
`ANDROID_ID`, no advertising id, no accounts.

This is a safety net, not a licence: callers must still not hand credentials to the
logger.

---

## 9. Known Android limitations

Stated in the Developer Console itself (Subsystems → *What cannot be captured*), not only
here, because a developer reading an empty section needs to know whether nothing happened
or nothing is observable.

- **Native (SIGSEGV/SIGABRT) crashes are not captured.** They never reach a Java handler.
  Android writes a tombstone under `/data/tombstones`, readable only by the system and by
  `adb bugreport`; an app cannot read its own. Installing a signal handler to fake it
  would mean interfering with the ART runtime's crash handling inside a process that also
  hosts guest code — not a trade worth making for a log line.
- **Another application's logs and private data are outside the sandbox.** Only Duplika's
  own processes are covered. A *clone* runs inside one of those, so a clone is covered; an
  app running normally on the device is not.
- **`READ_LOGS` is not held**, and is deliberately stripped from the merged manifest. The
  app reads no system-wide Logcat. `Duplika.*` tags are written to Logcat for `adb`, but
  are not read back.
- **A guest WebView's renderer-crash callbacks** (`onRenderProcessGone`) are delivered to
  the guest's own `WebViewClient` inside a stub process and are not reachable from the
  host.
- **Process kills without unwinding** — low-memory kill, ANR watchdog kill,
  `Process.killProcess` — record nothing.
- **JobScheduler start and finish** are only observable for jobs whose service Duplika
  hosts. The schedule request and the pending list always are.
- **Network errors** are recorded only where Duplika's own code sees them. A guest's
  sockets are not intercepted and no VPN capture is used.
- **`run-as` is unavailable in a release build**, so the on-disk files cannot be inspected
  with `adb` there. Use *Export diagnostics*.

The console distinguishes three things rather than blurring them: a **captured crash**
(unhandled JVM/Dart exception, with a stack trace), an **observed error** (an engine or
platform verdict returned as data — a code and a message, no trace, and the details
screen says so), and **unavailable system crash details** (the list above).

---

## 10. Export

**Developer Tools → ⋮ → Export diagnostics.** Writes into the app's own cache directory,
which needs no permission and is reclaimable by the system, then offers the files to the
Android share sheet through a `FileProvider` content URI with a temporary read grant.
Nothing is copied into shared storage.

```
<cache>/diagnostics_export/<yyyyMMdd-HHmmss>/
  DUPLIKA-DIAGNOSTICS-REPORT.txt   human-readable: header, system info, failures,
                                   operations, full timeline
  diagnostic-events.json           { generatedAt, filter, count, events[] }
  diagnostic-events.txt            one line per event
  recent-errors.txt                failures only, newest first
  system-info.json                 native payload verbatim + Dart-side facts
  <probe>-report.txt               one per subsystem probe run this session
```

The active filter is applied to the event files **and printed in the report header**, so
a filtered export cannot be mistaken for the full history. Previous bundles are deleted
before each new one: they are unbounded copies of a bounded log.

The provider is scoped by `res/xml/diagnostics_paths.xml` to the one cache subdirectory
the exporter writes into — a provider rooted at the whole cache would also expose the
staged APK copies that APK import leaves there.

---

## 11. Using the Developer Console

Reached from the terminal icon in the home-screen header. Available in **release as well
as debug** — release behaviour is what this project most needs to be able to diagnose —
with the destructive and exception-raising actions gated instead of removed.

| Tab | What it is for |
| --- | --- |
| **Live** | What is happening now. Search (message, exception, package, operation, source, category), filters, newest/oldest first, auto-scroll, pause. Pause means "stop moving", not "stop recording" — arriving events are counted on the badge and ingested in order on resume. |
| **Errors** | What is broken. Errors and fatals only, newest first, grouped by what you would do about it: crashes, engine, Bcore, install/import, guest lifecycle, platform channel, storage. |
| **Operations** | The index into the timelines. One row per correlated operation with its outcome, duration, event count and first failure. |
| **Subsystems** | The manual probes, one-tap filters into the log per subsystem, and the limitations list. |
| **System** | Build, device, engine, storage, and what the diagnostics system itself is holding (so a short log can be told from a wrapped buffer). |

**Filters** (bottom sheet): minimum level, exact levels, sources, categories, packages,
profiles, operation. The sheet edits a working copy and applies on confirm, so the list
underneath does not thrash while you tap and there is a way back.

**A log row** shows time, level, source, message, and then package / operation /
exception type. Tapping it opens **Event details**: every recorded field, details,
metadata, stack trace (or an explicit note when there is none and why), the operation it
belongs to, and the events immediately around it — neighbours by position, not only by
operation, because an error that was never given an operation id still has a story before
it.

**Operation timeline** is always oldest-first, with a connector between rows and a
`+N ms` label where a step actually took time. This is the view that turns "launch
failed" into a sequence: Dart → method channel → Kotlin engine → Bcore → guest process.

**Clear logs** is always confirmed, and the wording says what it really does: it drops
the native log files for every Duplika process too, including the ones written while
guest apps were running.

---

## 12. Files

### Added — Dart

```
lib/core/diagnostics/diagnostic_event.dart        model, levels, sources, categories
lib/core/diagnostics/diagnostic_buffer.dart       bounded ring
lib/core/diagnostics/diagnostic_store.dart        JSONL store + rotation, noop store
lib/core/diagnostics/diagnostic_logger.dart       the central sink
lib/core/diagnostics/diagnostic_operation.dart    correlation ids, zone scoping
lib/core/diagnostics/diagnostic_redactor.dart     redaction policy
lib/core/diagnostics/diagnostic_filter.dart       console filter value object
lib/core/diagnostics/diagnostics_repository.dart  merged read model, timelines
lib/core/diagnostics/diagnostics_exporter.dart    export bundle + text report
lib/core/diagnostics/native_diagnostics.dart      channel client
lib/core/diagnostics/channel_diagnostics.dart     method-channel instrumentation
lib/core/diagnostics/flutter_error_capture.dart   framework + zone hooks
lib/core/diagnostics/system_info.dart             system information model
lib/features/diagnostics/**                       controller, 5 tabs, 2 detail screens,
                                                  4 widgets
```

### Added — Kotlin

```
android/app/src/main/kotlin/co/tdevs/duplika/diagnostics/
  DiagnosticEvent.kt        model, mirrors the Dart one
  DiagnosticLogger.kt       per-process central sink
  DiagnosticStore.kt        per-process JSONL store + rotation
  DiagRedactor.kt           redaction policy
  DiagnosticsBridge.kt      MethodChannel + EventChannel
  SystemDiagnostics.kt      system information payload
  StorageDiagnostics.kt     storage probe
  SubsystemDiagnostics.kt   WebView / permission / notification / job probes
  ProbeReport.kt            shared probe result shape
  CrashCapture.kt           chained uncaught-exception handler
android/app/src/main/res/xml/diagnostics_paths.xml
```

### Modified

```
lib/main.dart                                   guarded zone, logger bootstrap
lib/app/routes/app_routes.dart                  /developer/tools
lib/app/routes/app_bindings.dart                AppBinding + DiagnosticsBinding
lib/core/utils/app_logger.dart                  now feeds DiagnosticLogger
lib/native/native_bridge.dart                   trace + correlation on every call
lib/core/virtualization/real_virtualization_engine.dart  operations
lib/features/apps/controllers/app_picker_controller.dart apk_import operation
lib/features/home/views/home_view.dart          Developer Tools entry
lib/features/home/widgets/home_header.dart      optional trailing action

android/.../DuplikaApplication.kt               logger + crash capture, first
android/.../MainActivity.kt                     DiagnosticsBridge attach
android/.../WebViewProcessIsolation.kt          records outcome + suffix
android/.../CloneLauncherActivity.kt            shortcut operation
android/.../native/Slog.kt                      forwards to DiagnosticLogger; BCORE tag
android/.../native/NativeBridge.kt              operation scope across threads
android/.../native/RealVirtualizationEngine.kt  named lifecycle phases
android/.../native/PermissionBridge.kt          permission lifecycle events
android/.../native/blackbox/BlackBoxEngineAdapter.kt  re-tagged to BCORE (tags only)
android/app/src/main/AndroidManifest.xml        FileProvider
android/app/build.gradle.kts                    buildConfig = true, androidx.core
```

### Tests

```
test/diagnostics_core_test.dart        buffer, model, redaction, filter, operations,
                                       store rotation/retention, logger
test/diagnostics_repository_test.dart  merge, dedup, timelines, neighbours, export
test/developer_console_test.dart       all five tabs, timeline, search, empty state
```
