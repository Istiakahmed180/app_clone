import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'diagnostic_buffer.dart';
import 'diagnostic_event.dart';
import 'diagnostic_operation.dart';
import 'diagnostic_redactor.dart';
import 'diagnostic_store.dart';

/// The single sink every Dart-side diagnostic goes through.
///
/// Recording is synchronous and cheap by design — build the event, redact it, push it
/// into the ring buffer, hand it to the broadcast stream — and everything expensive
/// (disk) is batched behind a timer. Nothing on a caller's path awaits I/O, because the
/// paths worth instrumenting are exactly the ones that must not get slower: APK import,
/// container install, guest launch.
///
/// Failure of the logger is never allowed to become the failure under investigation:
/// persistence errors are swallowed, and the buffer is bounded.
class DiagnosticLogger {
  DiagnosticLogger({
    DiagnosticBuffer? buffer,
    DiagnosticEventStore? store,
    this.flushInterval = const Duration(seconds: 2),
    this.flushThreshold = 25,
  })  : buffer = buffer ?? DiagnosticBuffer(),
        _store = store ?? const NoopDiagnosticEventStore();

  /// The app-wide logger. Replaceable so tests can install one with a fake store.
  static DiagnosticLogger get instance => _instance ??= DiagnosticLogger();

  static DiagnosticLogger? _instance;

  @visibleForTesting
  static set instance(DiagnosticLogger logger) => _instance = logger;

  /// Installs the production logger: bounded buffer plus the on-disk store.
  ///
  /// Safe to call more than once; the first call wins, so a test that installed its
  /// own logger is not overwritten by app start-up.
  static DiagnosticLogger bootstrap() =>
      _instance ??= DiagnosticLogger(store: FileDiagnosticEventStore());

  final DiagnosticBuffer buffer;
  final DiagnosticEventStore _store;

  /// How long a batch may sit in memory before being written. Long enough that a burst
  /// of events costs one write, short enough that a crash loses at most this much.
  final Duration flushInterval;

  /// A batch this large is written immediately rather than waiting out the timer.
  final int flushThreshold;

  final StreamController<DiagnosticEvent> _events =
      StreamController<DiagnosticEvent>.broadcast();

  final List<DiagnosticEvent> _unwritten = <DiagnosticEvent>[];
  Timer? _flushTimer;

  int _sequence = 0;
  late final String _idPrefix = _makeIdPrefix();

  String? _appVersion;
  String? _deviceInfo;
  String? _processName;

  /// Live events, newest as they happen. Broadcast, so the console can attach and
  /// detach without affecting recording.
  Stream<DiagnosticEvent> get stream => _events.stream;

  /// `debug`, `profile` or `release`. Stamped on every event so a report from a release
  /// build cannot be mistaken for a debug one.
  static String get buildType {
    if (kDebugMode) {
      return 'debug';
    }
    if (kProfileMode) {
      return 'profile';
    }
    return 'release';
  }

  /// Fills in the fields that need the platform to answer first.
  ///
  /// Called once system information has been read from native. Events recorded before
  /// that simply have no version or device — an absent field is honest, a guessed one
  /// is not.
  void describeEnvironment({
    String? appVersion,
    String? deviceInfo,
    String? processName,
  }) {
    _appVersion = appVersion ?? _appVersion;
    _deviceInfo = deviceInfo ?? _deviceInfo;
    _processName = processName ?? _processName;
  }

  DiagnosticEvent record({
    required DiagLevel level,
    required DiagnosticSource source,
    required DiagnosticCategory category,
    required String message,
    String? details,
    Object? error,
    StackTrace? stackTrace,
    String? operation,
    String? operationName,
    String? packageName,
    String? profileId,
    int? virtualUserId,
    Map<String, String>? metadata,
  }) {
    final DiagnosticOperation? ambient = DiagnosticOperation.current;

    final DiagnosticEvent event = DiagnosticEvent(
      id: '$_idPrefix-${_sequence.toRadixString(36)}',
      sequence: _sequence++,
      timestamp: DateTime.now(),
      level: level,
      source: source,
      category: category,
      message: DiagnosticRedactor.redactText(message),
      details: details == null ? null : DiagnosticRedactor.redactText(details),
      exceptionType: error?.runtimeType.toString(),
      // The exception's own text is part of the failure, so it is preserved rather than
      // summarised — redaction is the only thing applied to it.
      stackTrace: stackTrace == null ? null : _trimStack(stackTrace),
      operation: operation ?? ambient?.id,
      operationName: operationName ?? ambient?.name,
      packageName: packageName ?? ambient?.packageName,
      profileId: profileId ?? ambient?.profileId,
      virtualUserId: virtualUserId,
      processName: _processName,
      thread: 'dart:main',
      buildType: buildType,
      appVersion: _appVersion,
      deviceInfo: _deviceInfo,
      metadata: _buildMetadata(error, metadata),
    );

    _publish(event);
    _mirrorToConsole(event, error, stackTrace);
    return event;
  }

  /// Takes an event that was built elsewhere — the Kotlin logger, or a stored history
  /// being replayed — without re-stamping its identity.
  ///
  /// Not persisted by default. Native events already have a durable copy written by
  /// the Kotlin store, and writing them again here would spend the Dart log's byte
  /// budget on a second copy of events the export already reads from native.
  void recordExternal(DiagnosticEvent event, {bool persist = false}) {
    _publish(event, persist: persist);
  }

  void debug(
    DiagnosticSource source,
    DiagnosticCategory category,
    String message, {
    Map<String, String>? metadata,
  }) =>
      record(
        level: DiagLevel.debug,
        source: source,
        category: category,
        message: message,
        metadata: metadata,
      );

  void info(
    DiagnosticSource source,
    DiagnosticCategory category,
    String message, {
    String? packageName,
    String? profileId,
    Map<String, String>? metadata,
  }) =>
      record(
        level: DiagLevel.info,
        source: source,
        category: category,
        message: message,
        packageName: packageName,
        profileId: profileId,
        metadata: metadata,
      );

  void success(
    DiagnosticSource source,
    DiagnosticCategory category,
    String message, {
    String? packageName,
    String? profileId,
    Map<String, String>? metadata,
  }) =>
      record(
        level: DiagLevel.success,
        source: source,
        category: category,
        message: message,
        packageName: packageName,
        profileId: profileId,
        metadata: metadata,
      );

  void warning(
    DiagnosticSource source,
    DiagnosticCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? packageName,
    String? profileId,
    Map<String, String>? metadata,
  }) =>
      record(
        level: DiagLevel.warning,
        source: source,
        category: category,
        message: message,
        error: error,
        stackTrace: stackTrace,
        packageName: packageName,
        profileId: profileId,
        metadata: metadata,
      );

  void error(
    DiagnosticSource source,
    DiagnosticCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? packageName,
    String? profileId,
    Map<String, String>? metadata,
  }) =>
      record(
        level: DiagLevel.error,
        source: source,
        category: category,
        message: message,
        error: error,
        stackTrace: stackTrace,
        packageName: packageName,
        profileId: profileId,
        metadata: metadata,
      );

  void fatal(
    DiagnosticSource source,
    DiagnosticCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, String>? metadata,
  }) =>
      record(
        level: DiagLevel.fatal,
        source: source,
        category: category,
        message: message,
        error: error,
        stackTrace: stackTrace,
        metadata: metadata,
      );

  /// Everything the ring buffer still holds, oldest first.
  List<DiagnosticEvent> recentEvents() => buffer.toList();

  /// The persisted history, oldest first, newest-biased when truncated.
  Future<List<DiagnosticEvent>> history({int limit = 0}) async {
    await flush();
    return _store.read(limit: limit);
  }

  Future<int> persistedBytes() => _store.occupiedBytes();

  /// Writes anything still queued. Called before reading history or exporting, so a
  /// report can never be missing the event that prompted it.
  ///
  /// A store failure is absorbed here rather than left to the caller. Most flushes are
  /// fire-and-forget from [_publish], so a store that threw would surface as an
  /// unhandled async error — the logging system becoming the incident, which is the one
  /// thing it must never do.
  Future<void> flush() {
    _flushTimer?.cancel();
    _flushTimer = null;

    final List<DiagnosticEvent> batch = List<DiagnosticEvent>.of(_unwritten);
    _unwritten.clear();
    return _store.append(batch).catchError((Object _) {});
  }

  /// Drops both the recent buffer and the persisted history.
  Future<void> clear() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    _unwritten.clear();
    buffer.clear();
    await _store.clear();
  }

  void _publish(DiagnosticEvent event, {bool persist = true}) {
    buffer.add(event);
    if (_events.hasListener) {
      _events.add(event);
    }

    // Debug-level events are the noisiest and the least useful after the fact, so they
    // stay in memory only. Everything a bug report would want is persisted.
    if (persist && _store.isPersistent && event.level != DiagLevel.debug) {
      _unwritten.add(event);
      if (_unwritten.length >= flushThreshold) {
        flush();
      } else {
        _flushTimer ??= Timer(flushInterval, flush);
      }
    }
  }

  Map<String, String> _buildMetadata(Object? error, Map<String, String>? extra) {
    final Map<String, String> metadata = <String, String>{
      ...?extra,
      'error': ?error?.toString(),
    };
    return DiagnosticRedactor.redactMetadata(metadata);
  }

  /// Keeps the frames that identify the failure and drops the rest.
  ///
  /// A full Flutter stack is ~100 frames of framework internals; storing all of them
  /// would let a handful of errors consume the whole size-bounded log.
  static String _trimStack(StackTrace stackTrace) {
    const int maxFrames = 40;
    final List<String> frames = stackTrace.toString().split('\n');
    if (frames.length <= maxFrames) {
      return stackTrace.toString().trimRight();
    }
    return <String>[
      ...frames.take(maxFrames),
      '... ${frames.length - maxFrames} more frames',
    ].join('\n');
  }

  /// Keeps `dart:developer` output working exactly as it did before diagnostics
  /// existed, so nothing that used to appear in the IDE console stops appearing.
  ///
  /// In release only problems are mirrored: the console call is not free, and there is
  /// no attached observatory to read the rest.
  void _mirrorToConsole(DiagnosticEvent event, Object? error, StackTrace? stackTrace) {
    if (!kDebugMode && !event.isProblem) {
      return;
    }
    developer.log(
      event.message,
      name: 'Duplika.${event.source.wire}',
      level: _developerLevel(event.level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static int _developerLevel(DiagLevel level) => switch (level) {
        DiagLevel.debug => 500,
        DiagLevel.info => 800,
        DiagLevel.success => 800,
        DiagLevel.warning => 900,
        DiagLevel.error => 1000,
        DiagLevel.fatal => 1200,
      };

  /// A short per-run token, so event ids from two runs (or from a native process) can
  /// never collide even though the counter restarts at zero.
  static String _makeIdPrefix() {
    final int micros = DateTime.now().microsecondsSinceEpoch;
    return 'd${micros.toRadixString(36)}';
  }
}
