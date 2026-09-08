import 'package:duplika/app/theme/app_theme.dart';
import 'package:duplika/core/diagnostics/diagnostic_buffer.dart';
import 'package:duplika/core/diagnostics/diagnostic_event.dart';
import 'package:duplika/core/diagnostics/diagnostic_logger.dart';
import 'package:duplika/core/diagnostics/diagnostics_repository.dart';
import 'package:duplika/core/diagnostics/native_diagnostics.dart';
import 'package:duplika/core/diagnostics/system_info.dart';
import 'package:duplika/features/diagnostics/controllers/diagnostics_controller.dart';
import 'package:duplika/features/diagnostics/views/error_center_tab.dart';
import 'package:duplika/features/diagnostics/views/live_log_tab.dart';
import 'package:duplika/features/diagnostics/views/operation_timeline_view.dart';
import 'package:duplika/features/diagnostics/views/operations_tab.dart';
import 'package:duplika/features/diagnostics/views/subsystems_tab.dart';
import 'package:duplika/features/diagnostics/views/system_info_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A native side with no platform channel behind it.
class _FakeNative extends NativeDiagnostics {
  _FakeNative({this.history = const <DiagnosticEvent>[]});

  final List<DiagnosticEvent> history;

  @override
  Future<List<DiagnosticEvent>> readHistory({int limit = 2000}) async => history;

  @override
  Future<void> clearHistory() async {}

  @override
  Future<SystemInfoSnapshot> systemInfo() async =>
      SystemInfoSnapshot.from(<String, dynamic>{
        'model': 'CPH2605',
        'androidVersion': '15',
        'sdkInt': 35,
        'engineStatus': 'READY',
      });
}

DiagnosticEvent _event({
  required String id,
  required int sequence,
  DiagLevel level = DiagLevel.info,
  DiagnosticSource source = DiagnosticSource.virtualEngine,
  String message = 'event',
  String? operation,
  String? operationName,
  String? packageName,
}) =>
    DiagnosticEvent(
      id: id,
      sequence: sequence,
      timestamp: DateTime(2026, 9, 8, 9, 10, sequence),
      level: level,
      source: source,
      category: DiagnosticCategory.launch,
      message: message,
      operation: operation,
      operationName: operationName,
      packageName: packageName,
    );

void main() {
  late DiagnosticsController controller;

  final List<DiagnosticEvent> events = <DiagnosticEvent>[
    _event(
      id: 'a',
      sequence: 1,
      message: 'Launch operation started',
      operation: 'launch_20260908_001',
      operationName: 'launch VLC',
      packageName: 'org.videolan.vlc',
    ),
    _event(
      id: 'b',
      sequence: 3,
      level: DiagLevel.success,
      source: DiagnosticSource.guestProcess,
      message: 'Guest process created',
      operation: 'launch_20260908_001',
    ),
    _event(
      id: 'c',
      sequence: 7,
      level: DiagLevel.error,
      source: DiagnosticSource.storage,
      message: 'Failed to initialize external storage',
      operation: 'launch_20260908_001',
      packageName: 'org.videolan.vlc',
    ),
  ];

  setUp(() async {
    DiagnosticLogger.instance =
        DiagnosticLogger(buffer: DiagnosticBuffer(capacity: 32));
    controller = DiagnosticsController(
      repository: DiagnosticsRepository(
        logger: DiagnosticLogger.instance,
        native: _FakeNative(history: events),
      ),
    );
    controller.onInit();
    // onInit kicks off an async reload; let it settle before asserting on the UI.
    await controller.reload();
  });

  tearDown(() => controller.onClose());

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the live log lists events newest first', (WidgetTester tester) async {
    await pump(tester, LiveLogTab(controller: controller));

    expect(find.text('Failed to initialize external storage'), findsOneWidget);
    expect(find.text('Launch operation started'), findsOneWidget);
    expect(find.textContaining('3 of 3 events'), findsOneWidget);

    final double errorY = tester.getTopLeft(
      find.text('Failed to initialize external storage'),
    ).dy;
    final double startY =
        tester.getTopLeft(find.text('Launch operation started')).dy;
    expect(errorY, lessThan(startY), reason: 'newest first is the default order');
  });

  testWidgets('search narrows the live log', (WidgetTester tester) async {
    await pump(tester, LiveLogTab(controller: controller));

    await tester.enterText(find.byType(TextField), 'storage');
    await tester.pumpAndSettle();

    expect(find.text('Failed to initialize external storage'), findsOneWidget);
    expect(find.text('Launch operation started'), findsNothing);
    expect(find.textContaining('1 of 3 events'), findsOneWidget);
  });

  testWidgets('the error centre shows only failures, grouped', (WidgetTester tester) async {
    await pump(tester, ErrorCenterTab(controller: controller));

    expect(find.text('Failed to initialize external storage'), findsOneWidget);
    expect(find.text('Guest process created'), findsNothing);
    expect(find.textContaining('Storage'), findsWidgets);
  });

  testWidgets('the operations tab lists the correlated operation',
      (WidgetTester tester) async {
    await pump(tester, OperationsTab(controller: controller));

    expect(find.text('launch VLC'), findsOneWidget);
    expect(find.text('launch_20260908_001'), findsOneWidget);
    expect(find.text('FAILED'), findsOneWidget);
    expect(find.text('3 events'), findsOneWidget);
  });

  testWidgets('the timeline shows one operation oldest first',
      (WidgetTester tester) async {
    await pump(
      tester,
      OperationTimelineView(
        operationId: 'launch_20260908_001',
        controller: controller,
      ),
    );

    final double startY =
        tester.getTopLeft(find.text('Launch operation started')).dy;
    final double errorY = tester
        .getTopLeft(find.text('Failed to initialize external storage'))
        .dy;
    expect(startY, lessThan(errorY), reason: 'a timeline reads forwards');
  });

  testWidgets('the subsystems tab builds and offers every probe',
      (WidgetTester tester) async {
    // A regression guard for a real defect: this screen once wrapped its whole list in
    // an Obx whose builder read no observable, which GetX raises as an error the moment
    // the tab is opened.
    await pump(tester, SubsystemsTab(controller: controller));

    expect(tester.takeException(), isNull);
    for (final DiagnosticProbe probe in DiagnosticProbe.values) {
      expect(find.text(probe.label), findsOneWidget);
    }

    // The limitations card sits below the fold in the test viewport.
    await tester.scrollUntilVisible(
      find.text('What cannot be captured'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('What cannot be captured'), findsOneWidget);
  });

  testWidgets('the system tab reports the device and the buffer state',
      (WidgetTester tester) async {
    await pump(tester, SystemInfoTab(controller: controller));

    expect(find.text('CPH2605'), findsOneWidget);

    // The engine and Flutter-side blocks sit below the fold in the test viewport, and
    // the sections are ordered, so they are reached in turn.
    final Finder scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('READY'), 400, scrollable: scrollable);
    expect(find.text('READY'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Diagnostics (Flutter side)'),
      400,
      scrollable: scrollable,
    );
    expect(find.text('Diagnostics (Flutter side)'), findsOneWidget);
  });

  testWidgets('an empty console explains itself rather than showing a blank list',
      (WidgetTester tester) async {
    final DiagnosticsController empty = DiagnosticsController(
      repository: DiagnosticsRepository(
        logger: DiagnosticLogger.instance,
        native: _FakeNative(),
      ),
    );
    empty.onInit();
    await empty.reload();

    await pump(tester, LiveLogTab(controller: empty));

    expect(find.text('No events recorded yet'), findsOneWidget);
    empty.onClose();
  });
}
