import 'dart:async';

import 'diagnostic_event.dart';
import 'diagnostic_logger.dart';

/// One user-visible piece of work, and the correlation id that ties its events together.
///
/// This is the feature that makes the console more than a log viewer. "Launch VLC"
/// touches Dart, the method channel, the Kotlin engine, Bcore, the installer and the
/// guest process; without a shared id those arrive as unrelated lines interleaved with
/// whatever else the app was doing, and the failure at the end has no visible cause.
///
/// The id is ambient. [run] installs it as a zone value, so every `await` inside the
/// body — and every native call made from it — inherits it without being passed it.
class DiagnosticOperation {
  DiagnosticOperation({
    required this.id,
    required this.name,
    this.packageName,
    this.profileId,
  }) : startedAt = DateTime.now();

  /// Mints an id of the form `launch_20260908_mts_001`: kind, date, run, ordinal.
  ///
  /// Readable on purpose. A developer reads these out of a bug report and searches for
  /// them, so an opaque UUID would be a worse answer.
  ///
  /// The run token is not decoration. The counter restarts at 1 with the process, so
  /// without it two runs on the same day both produce `engine_init_20260908_001` — and
  /// because the persistent log outlives a restart, the console then merges those two
  /// runs into a single operation minutes long. That was observed on a device, and it
  /// makes the timeline lie about what happened.
  factory DiagnosticOperation.start(
    String kind, {
    String? name,
    String? packageName,
    String? profileId,
  }) {
    final DateTime now = DateTime.now();
    final String slug = _slugify(kind);
    final int ordinal = _counters.update(slug, (int value) => value + 1, ifAbsent: () => 1);
    final String date = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';

    return DiagnosticOperation(
      id: '${slug}_${date}_${_runToken}_${ordinal.toString().padLeft(3, '0')}',
      name: name ?? kind,
      packageName: packageName,
      profileId: profileId,
    );
  }

  static const Object _zoneKey = #duplikaDiagnosticOperation;
  static final Map<String, int> _counters = <String, int>{};

  /// Three base-36 characters identifying this run of the process.
  ///
  /// Short enough to keep an id readable and to type into a search box; taken from the
  /// clock so two consecutive runs cannot collide.
  static final String _runToken = () {
    final String seconds =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toRadixString(36);
    return seconds.substring(seconds.length - 3);
  }();

  final String id;
  final String name;
  final String? packageName;
  final String? profileId;
  final DateTime startedAt;

  /// The operation in scope on this call path, if any.
  static DiagnosticOperation? get current {
    final Object? value = Zone.current[_zoneKey];
    return value is DiagnosticOperation ? value : null;
  }

  Duration get elapsed => DateTime.now().difference(startedAt);

  /// Runs [body] with this operation ambient, recording a start event and either a
  /// success or a failure event around it.
  ///
  /// The original exception is rethrown unchanged. Diagnostics observe; they do not
  /// decide what a caller sees, and an operation wrapper that swallowed errors would
  /// be worse than no wrapper at all.
  static Future<T> run<T>(
    String kind,
    Future<T> Function(DiagnosticOperation operation) body, {
    String? name,
    String? packageName,
    String? profileId,
    DiagnosticSource source = DiagnosticSource.dart,
    DiagnosticCategory category = DiagnosticCategory.unknown,
    DiagnosticLogger? logger,
  }) {
    final DiagnosticOperation operation = DiagnosticOperation.start(
      kind,
      name: name,
      packageName: packageName,
      profileId: profileId,
    );
    final DiagnosticLogger sink = logger ?? DiagnosticLogger.instance;

    return runZoned<Future<T>>(
      () async {
        sink.record(
          level: DiagLevel.info,
          source: source,
          category: category,
          message: '${operation.name} started',
        );
        try {
          final T result = await body(operation);
          sink.record(
            level: DiagLevel.success,
            source: source,
            category: category,
            message: '${operation.name} finished',
            metadata: <String, String>{'durationMs': '${operation.elapsed.inMilliseconds}'},
          );
          return result;
        } catch (error, stackTrace) {
          sink.record(
            level: DiagLevel.error,
            source: source,
            category: category,
            message: '${operation.name} failed',
            error: error,
            stackTrace: stackTrace,
            details: error.toString(),
            metadata: <String, String>{'durationMs': '${operation.elapsed.inMilliseconds}'},
          );
          rethrow;
        }
      },
      zoneValues: <Object, Object?>{_zoneKey: operation},
    );
  }

  /// Records an intermediate step of this operation.
  ///
  /// Useful when the interesting boundary is inside the body rather than at its edges —
  /// "package resolved", "profile found", "guest process created".
  void step(
    String message, {
    DiagnosticSource source = DiagnosticSource.dart,
    DiagnosticCategory category = DiagnosticCategory.unknown,
    DiagLevel level = DiagLevel.info,
    Map<String, String>? metadata,
    DiagnosticLogger? logger,
  }) {
    (logger ?? DiagnosticLogger.instance).record(
      level: level,
      source: source,
      category: category,
      message: message,
      operation: id,
      operationName: name,
      packageName: packageName,
      profileId: profileId,
      metadata: metadata,
    );
  }

  static String _slugify(String value) {
    final String lowered = value.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_');
    final String trimmed = lowered.replaceAll(RegExp('^_+|_+\$'), '');
    return trimmed.isEmpty ? 'operation' : trimmed;
  }
}
