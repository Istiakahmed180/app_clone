import 'dart:developer' as developer;

/// Thin wrapper over `dart:developer` so the codebase never calls `print`.
class AppLogger {
  const AppLogger(this._name);

  final String _name;

  void info(String message) => developer.log(message, name: _name);

  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      developer.log(message, name: _name, error: error, stackTrace: stackTrace);
}
