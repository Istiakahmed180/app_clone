import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/diagnostics/diagnostic_event.dart';
import 'core/diagnostics/diagnostic_logger.dart';
import 'core/diagnostics/flutter_error_capture.dart';

void main() {
  // Everything runs inside one guarded zone, and the binding is initialised inside it.
  // Initialising the binding in the root zone and calling runApp in a guarded one is
  // the mistake that makes a guarded `main` misbehave, so both happen here together.
  FlutterErrorCapture.runGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    // Before anything else can fail. The logger owns the bounded buffer and the
    // persistent store; the capture hooks chain onto Flutter's own handlers rather
    // than replacing them, so error behaviour is unchanged.
    final DiagnosticLogger logger = DiagnosticLogger.bootstrap();
    FlutterErrorCapture.install(logger: logger);

    logger.info(
      DiagnosticSource.flutter,
      DiagnosticCategory.appLifecycle,
      'Duplika starting (${DiagnosticLogger.buildType} build)',
    );

    runApp(const DuplikaApp());
  });
}
