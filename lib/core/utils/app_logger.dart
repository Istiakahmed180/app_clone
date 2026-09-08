import '../diagnostics/diagnostic_event.dart';
import '../diagnostics/diagnostic_logger.dart';

/// Named logger used throughout the Dart codebase.
///
/// This used to be a thin wrapper over `dart:developer`. It now feeds the central
/// diagnostics logger instead, which still mirrors to `dart:developer`, so existing
/// call sites keep behaving as they did while their output becomes visible in the
/// in-app Developer Console.
///
/// Keeping this type is the migration strategy: the existing `_logger.info` /
/// `_logger.error` calls did not have to be rewritten to gain structured logging, and
/// the paths worth correlating were then instrumented explicitly on top. New code that
/// has a real subsystem and category to name should call [DiagnosticLogger] directly
/// rather than relying on the attribution table below.
class AppLogger {
  const AppLogger(this._name);

  final String _name;

  /// Attribution for a logger that did not name its own subsystem.
  ///
  /// A guessed-but-close source beats `SYSTEM` for every event in the app: without this
  /// the console's source filter would be useless for anything logged before
  /// diagnostics existed.
  static const Map<String, (DiagnosticSource, DiagnosticCategory)> _attribution =
      <String, (DiagnosticSource, DiagnosticCategory)>{
    'NativeBridge': (DiagnosticSource.methodChannel, DiagnosticCategory.unknown),
    'RealVirtualizationEngine': (DiagnosticSource.virtualEngine, DiagnosticCategory.profile),
    'HomeController': (DiagnosticSource.flutter, DiagnosticCategory.appLifecycle),
    'AppPickerController': (DiagnosticSource.flutter, DiagnosticCategory.import),
    'OnboardingController': (DiagnosticSource.flutter, DiagnosticCategory.appLifecycle),
    'TermsDialog': (DiagnosticSource.flutter, DiagnosticCategory.appLifecycle),
    'VirtualProfileRepository': (DiagnosticSource.dart, DiagnosticCategory.profile),
  };

  DiagnosticSource get _resolvedSource =>
      _attribution[_name]?.$1 ?? DiagnosticSource.dart;

  DiagnosticCategory get _resolvedCategory =>
      _attribution[_name]?.$2 ?? DiagnosticCategory.unknown;

  void info(String message) => DiagnosticLogger.instance.record(
        level: DiagLevel.info,
        source: _resolvedSource,
        category: _resolvedCategory,
        message: message,
        metadata: <String, String>{'logger': _name},
      );

  void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      DiagnosticLogger.instance.record(
        level: DiagLevel.warning,
        source: _resolvedSource,
        category: _resolvedCategory,
        message: message,
        error: error,
        stackTrace: stackTrace,
        metadata: <String, String>{'logger': _name},
      );

  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      DiagnosticLogger.instance.record(
        level: DiagLevel.error,
        source: _resolvedSource,
        category: _resolvedCategory,
        message: message,
        error: error,
        stackTrace: stackTrace,
        details: error?.toString(),
        metadata: <String, String>{'logger': _name},
      );
}
