import 'dart:async';

import 'diagnostic_event.dart';
import 'diagnostic_logger.dart';
import 'diagnostic_operation.dart';
import 'diagnostic_redactor.dart';

/// Instrumentation for Flutter → Kotlin calls.
///
/// Wrapped once, around the single place that invokes the platform channel, rather
/// than added to each of the thirty-odd call sites. A method that is added later is
/// then instrumented by construction instead of by remembering.
class ChannelDiagnostics {
  const ChannelDiagnostics._();

  /// Methods whose start and success are worth an `INFO` line.
  ///
  /// Everything else is recorded at `DEBUG`: it stays in the in-memory buffer, so it
  /// is there when a developer needs the full sequence, but it does not fill the
  /// persistent log or bury the interesting lines. Reading the installed-app list
  /// eleven times is not a story; installing a package is.
  static const Set<String> _significantMethods = <String>{
    'initializeVirtualization',
    'installAppToProfile',
    'installApkToProfile',
    'uninstallAppFromProfile',
    'launchProfile',
    'stopProfile',
    'deleteProfile',
    'inspectApk',
    'pinCloneShortcut',
    'requestIgnoreBatteryOptimizations',
  };

  /// Argument keys never worth writing down: large binary payloads and anything whose
  /// only content is an image.
  static const Set<String> _skippedArguments = <String>{'includeIcons', 'icons'};

  /// Runs [call], recording the start, the outcome and how long it took.
  ///
  /// The result and any exception pass through untouched. This is an observer.
  static Future<T> trace<T>({
    required String channel,
    required String method,
    required Future<T> Function() call,
    Map<String, dynamic>? arguments,
    String Function(T result)? describeResult,
    DiagnosticLogger? logger,
  }) async {
    final DiagnosticLogger sink = logger ?? DiagnosticLogger.instance;
    final DiagLevel routineLevel = _significantMethods.contains(method)
        ? DiagLevel.info
        : DiagLevel.debug;
    final String argumentSummary = summariseArguments(arguments);
    final Stopwatch stopwatch = Stopwatch()..start();

    sink.record(
      level: routineLevel,
      source: DiagnosticSource.methodChannel,
      category: DiagnosticCategory.unknown,
      message: 'Call started: $method',
      packageName: arguments?['packageName'] as String?,
      profileId: arguments?['profileId'] as String?,
      metadata: <String, String>{
        'channel': channel,
        'method': method,
        'phase': 'start',
        if (argumentSummary.isNotEmpty) 'arguments': argumentSummary,
      },
    );

    try {
      final T result = await call();
      stopwatch.stop();
      sink.record(
        level: routineLevel,
        source: DiagnosticSource.methodChannel,
        category: DiagnosticCategory.unknown,
        message: 'Call succeeded: $method (${stopwatch.elapsedMilliseconds} ms)',
        packageName: arguments?['packageName'] as String?,
        profileId: arguments?['profileId'] as String?,
        metadata: <String, String>{
          'channel': channel,
          'method': method,
          'phase': 'success',
          'durationMs': '${stopwatch.elapsedMilliseconds}',
          if (describeResult != null)
            'result': DiagnosticRedactor.redactText(describeResult(result)),
        },
      );
      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();
      sink.record(
        level: DiagLevel.error,
        source: DiagnosticSource.methodChannel,
        category: DiagnosticCategory.unknown,
        message: 'Call failed: $method (${stopwatch.elapsedMilliseconds} ms)',
        details: error.toString(),
        error: error,
        stackTrace: stackTrace,
        packageName: arguments?['packageName'] as String?,
        profileId: arguments?['profileId'] as String?,
        metadata: <String, String>{
          'channel': channel,
          'method': method,
          'phase': 'failure',
          'durationMs': '${stopwatch.elapsedMilliseconds}',
          if (argumentSummary.isNotEmpty) 'arguments': argumentSummary,
        },
      );
      rethrow;
    }
  }

  /// The correlation id to send with a platform call, so the Kotlin side can tag its
  /// own events with the operation that caused them.
  static String? currentOperationId() => DiagnosticOperation.current?.id;

  /// A short, safe rendering of a call's arguments.
  ///
  /// Values are summarised rather than dumped: a list becomes its length, a path
  /// becomes its filename under a root label, a long string is truncated, and anything
  /// under a sensitive key is dropped. An argument summary exists to answer "which
  /// package, how many APKs" — not to reproduce the payload.
  static String summariseArguments(Map<String, dynamic>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return '';
    }
    final List<String> parts = <String>[];
    arguments.forEach((String key, Object? value) {
      if (_skippedArguments.contains(key) || key.startsWith('__')) {
        return;
      }
      if (DiagnosticRedactor.isSensitiveKey(key)) {
        parts.add('$key=${DiagnosticRedactor.placeholder}');
        return;
      }
      parts.add('$key=${_summariseValue(key, value)}');
    });
    return parts.join(', ');
  }

  static String _summariseValue(String key, Object? value) {
    if (value == null) {
      return 'null';
    }
    if (value is bool || value is num) {
      return '$value';
    }
    if (value is List) {
      if (value.isEmpty) {
        return '[]';
      }
      if (_looksLikePathKey(key)) {
        return '[${value.length}: ${DiagnosticRedactor.sanitizePaths(value.map((Object? e) => '$e')).join(', ')}]';
      }
      return '[${value.length} items]';
    }
    if (value is Map) {
      return '{${value.length} entries}';
    }
    final String text = '$value';
    if (_looksLikePathKey(key) || text.startsWith('/')) {
      return DiagnosticRedactor.sanitizePath(text);
    }
    return text.length <= 120
        ? DiagnosticRedactor.redactText(text)
        : '${DiagnosticRedactor.redactText(text.substring(0, 120))}…';
  }

  static bool _looksLikePathKey(String key) {
    final String lower = key.toLowerCase();
    return lower.contains('path') || lower.contains('paths') || lower.contains('dir');
  }
}
