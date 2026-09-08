import 'dart:async';
import 'dart:ui' show ErrorCallback, PlatformDispatcher;

import 'package:flutter/foundation.dart';

import 'diagnostic_event.dart';
import 'diagnostic_logger.dart';

/// Records framework and uncaught asynchronous Dart errors.
///
/// Deliberately additive. Every hook here chains to whatever was installed before it
/// and then lets the platform do exactly what it would have done anyway: framework
/// errors still reach `FlutterError.presentError`, uncaught async errors still get
/// dumped to the console, and a release build still fails the same way. The console
/// gains a record; nothing gains a swallowed exception.
class FlutterErrorCapture {
  const FlutterErrorCapture._();

  static bool _installed = false;

  /// Installs the framework hooks. Idempotent, so a hot restart does not chain the
  /// same handler onto itself and report every error twice.
  static void install({DiagnosticLogger? logger}) {
    if (_installed) {
      return;
    }
    _installed = true;

    final DiagnosticLogger sink = logger ?? DiagnosticLogger.instance;
    final FlutterExceptionHandler? previousOnError = FlutterError.onError;

    FlutterError.onError = (FlutterErrorDetails details) {
      recordFlutterError(details, logger: sink);
      // Chained, not replaced: the default handler is what prints the error banner and
      // the console dump that developers rely on.
      if (previousOnError != null) {
        previousOnError(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    // Errors raised outside the guarded zone — most often inside a platform message
    // handler — arrive here instead of at the zone handler.
    final ErrorCallback? previousPlatformOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
      recordUncaughtError(error, stackTrace, logger: sink);
      // `false` means "not handled", which keeps the engine's own reporting intact.
      return previousPlatformOnError?.call(error, stackTrace) ?? false;
    };
  }

  /// Restores the pre-install state. Tests only; the app installs once and keeps it.
  @visibleForTesting
  static void resetForTesting() => _installed = false;

  static void recordFlutterError(
    FlutterErrorDetails details, {
    DiagnosticLogger? logger,
  }) {
    final Object exception = details.exception;
    (logger ?? DiagnosticLogger.instance).record(
      // A framework error the app never caught is a defect, not a warning, but it is
      // not fatal either: Flutter keeps running and shows an error widget.
      level: DiagLevel.error,
      source: DiagnosticSource.flutter,
      category: DiagnosticCategory.crash,
      message: _summarise(exception),
      details: _describe(details),
      error: exception,
      stackTrace: details.stack,
      metadata: <String, String>{
        'kind': 'flutterError',
        if (details.library != null) 'library': details.library!,
        if (details.context != null) 'context': details.context!.toStringDeep().trim(),
        'silent': '${details.silent}',
      },
    );
  }

  /// An uncaught asynchronous error: the zone handler's payload.
  static void recordUncaughtError(
    Object error,
    StackTrace stackTrace, {
    DiagnosticLogger? logger,
  }) {
    (logger ?? DiagnosticLogger.instance).record(
      level: DiagLevel.fatal,
      source: DiagnosticSource.dart,
      category: DiagnosticCategory.crash,
      message: 'Uncaught asynchronous error: ${_summarise(error)}',
      details: error.toString(),
      error: error,
      stackTrace: stackTrace,
      metadata: const <String, String>{'kind': 'uncaughtAsync'},
    );
  }

  /// Runs [body] inside a guarded zone whose uncaught errors are recorded.
  ///
  /// `WidgetsFlutterBinding.ensureInitialized()` must be called by [body], inside this
  /// zone: initialising the binding in one zone and calling `runApp` in another is the
  /// mistake that makes a guarded `main` misbehave.
  static R? runGuarded<R>(R Function() body, {DiagnosticLogger? logger}) {
    return runZonedGuarded<R>(body, (Object error, StackTrace stackTrace) {
      recordUncaughtError(error, stackTrace, logger: logger);
      // Present it the way an unguarded app would, so nothing disappears from the
      // console just because diagnostics are watching.
      FlutterError.presentError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'duplika',
          context: ErrorDescription('in an uncaught asynchronous callback'),
        ),
      );
    });
  }

  static String _summarise(Object exception) {
    final String text = exception.toString();
    final int newline = text.indexOf('\n');
    final String firstLine = newline < 0 ? text : text.substring(0, newline);
    return firstLine.length <= 200 ? firstLine : '${firstLine.substring(0, 200)}…';
  }

  static String _describe(FlutterErrorDetails details) {
    final StringBuffer buffer = StringBuffer(details.exception.toString());
    final DiagnosticsNode? context = details.context;
    if (context != null) {
      buffer.write('\nContext: ${context.toStringDeep().trim()}');
    }
    if (details.library != null) {
      buffer.write('\nLibrary: ${details.library}');
    }
    return buffer.toString();
  }
}
