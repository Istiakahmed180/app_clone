import 'dart:convert';
import 'dart:io';

import 'package:duplika/core/diagnostics/diagnostic_buffer.dart';
import 'package:duplika/core/diagnostics/diagnostic_event.dart';
import 'package:duplika/core/diagnostics/diagnostic_filter.dart';
import 'package:duplika/core/diagnostics/diagnostic_logger.dart';
import 'package:duplika/core/diagnostics/diagnostics_exporter.dart';
import 'package:duplika/core/diagnostics/diagnostics_repository.dart';
import 'package:duplika/core/diagnostics/native_diagnostics.dart';
import 'package:duplika/core/diagnostics/system_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// A native side that answers from a list instead of a platform channel.
class _FakeNative extends NativeDiagnostics {
  _FakeNative({this.history = const <DiagnosticEvent>[]});

  List<DiagnosticEvent> history;
  int clearCount = 0;

  @override
  Future<List<DiagnosticEvent>> readHistory({int limit = 2000}) async => history;

  @override
  Future<void> clearHistory() async {
    clearCount++;
    history = const <DiagnosticEvent>[];
  }

  @override
  Future<SystemInfoSnapshot> systemInfo() async =>
      SystemInfoSnapshot.from(<String, dynamic>{
        'model': 'CPH2605',
        'androidVersion': '15',
        'sdkInt': 35,
        'appVersion': '1.0.0',
        'engineStatus': 'READY',
        'engineBackend': 'NewBlackbox/Bcore',
        'processName': 'co.tdevs.duplika',
      });
}

DiagnosticEvent _event({
  required String id,
  required int sequence,
  DiagLevel level = DiagLevel.info,
  DiagnosticSource source = DiagnosticSource.dart,
  String message = 'event',
  String? operation,
  String? operationName,
  String? packageName,
  String? profileId,
  int secondsPastNine = 0,
}) =>
    DiagnosticEvent(
      id: id,
      sequence: sequence,
      timestamp: DateTime(2026, 9, 8, 9, 10, secondsPastNine),
      level: level,
      source: source,
      category: DiagnosticCategory.launch,
      message: message,
      operation: operation,
      operationName: operationName,
      packageName: packageName,
      profileId: profileId,
    );

void main() {
  late DiagnosticLogger logger;

  setUp(() {
    logger = DiagnosticLogger(buffer: DiagnosticBuffer(capacity: 64));
    DiagnosticLogger.instance = logger;
  });

  group('DiagnosticsRepository', () {
    test('merges Dart and native history into one ordered timeline', () async {
      final _FakeNative native = _FakeNative(
        history: <DiagnosticEvent>[
          _event(
            id: 'n1',
            sequence: 0,
            source: DiagnosticSource.bcore,
            message: 'engine attached',
            secondsPastNine: 1,
          ),
          _event(
            id: 'n2',
            sequence: 1,
            source: DiagnosticSource.guestProcess,
            message: 'guest process started',
            secondsPastNine: 5,
          ),
        ],
      );

      logger.recordExternal(
        _event(
          id: 'd1',
          sequence: 0,
          source: DiagnosticSource.flutter,
          message: 'app started',
          secondsPastNine: 3,
        ),
      );

      final DiagnosticsRepository repository =
          DiagnosticsRepository(logger: logger, native: native);
      await repository.load();

      expect(
        repository.events.map((DiagnosticEvent e) => e.id),
        <String>['n1', 'd1', 'n2'],
        reason: 'ordered by timestamp regardless of which side produced them',
      );
    });

    test('an event present in two sources is shown once', () async {
      final DiagnosticEvent shared = _event(id: 'shared', sequence: 0);
      final _FakeNative native = _FakeNative(history: <DiagnosticEvent>[shared]);
      logger.recordExternal(shared);

      final DiagnosticsRepository repository =
          DiagnosticsRepository(logger: logger, native: native);
      await repository.load();

      expect(repository.events.length, 1);
    });

    test('add() rejects an event it already holds', () async {
      final DiagnosticsRepository repository =
          DiagnosticsRepository(logger: logger, native: _FakeNative());
      await repository.load();

      final DiagnosticEvent event = _event(id: 'live', sequence: 0);
      expect(repository.add(event), isTrue);
      expect(repository.add(event), isFalse);
      expect(repository.events.length, 1);
    });

    test('groups an operation into a timeline with its worst outcome', () async {
      final _FakeNative native = _FakeNative(
        history: <DiagnosticEvent>[
          _event(
            id: 'o1',
            sequence: 0,
            operation: 'launch_20260908_001',
            operationName: 'launch VLC',
            message: 'launch started',
            secondsPastNine: 1,
          ),
          _event(
            id: 'o2',
            sequence: 1,
            level: DiagLevel.success,
            operation: 'launch_20260908_001',
            message: 'guest process created',
            secondsPastNine: 3,
          ),
          _event(
            id: 'o3',
            sequence: 2,
            level: DiagLevel.error,
            operation: 'launch_20260908_001',
            message: 'storage initialization failed',
            secondsPastNine: 7,
          ),
          _event(id: 'other', sequence: 3, message: 'unrelated', secondsPastNine: 8),
        ],
      );

      final DiagnosticsRepository repository =
          DiagnosticsRepository(logger: logger, native: native);
      await repository.load();

      final OperationTimeline timeline =
          repository.timelineFor('launch_20260908_001');

      expect(timeline.events.length, 3);
      expect(timeline.name, 'launch VLC');
      expect(timeline.outcome, DiagLevel.error);
      expect(timeline.failed, isTrue);
      expect(timeline.duration, const Duration(seconds: 6));
      expect(timeline.failures.single.message, 'storage initialization failed');
      expect(
        timeline.events.map((DiagnosticEvent e) => e.id),
        <String>['o1', 'o2', 'o3'],
        reason: 'a timeline is read oldest first',
      );
    });

    test('operations() lists newest first', () async {
      final _FakeNative native = _FakeNative(
        history: <DiagnosticEvent>[
          _event(id: 'a', sequence: 0, operation: 'import_1', secondsPastNine: 1),
          _event(id: 'b', sequence: 1, operation: 'launch_1', secondsPastNine: 9),
        ],
      );
      final DiagnosticsRepository repository =
          DiagnosticsRepository(logger: logger, native: native);
      await repository.load();

      expect(
        repository.operations().map((OperationTimeline t) => t.operationId),
        <String>['launch_1', 'import_1'],
      );
    });

    test('neighbours span both sides of an event with no operation id', () async {
      final _FakeNative native = _FakeNative(
        history: <DiagnosticEvent>[
          for (int index = 0; index < 9; index++)
            _event(id: 'e$index', sequence: index, secondsPastNine: index),
        ],
      );
      final DiagnosticsRepository repository =
          DiagnosticsRepository(logger: logger, native: native);
      await repository.load();

      final List<DiagnosticEvent> neighbours = repository.neighboursOf(
        repository.events[4],
        span: 2,
      );

      expect(
        neighbours.map((DiagnosticEvent e) => e.id),
        <String>['e2', 'e3', 'e4', 'e5', 'e6'],
      );
    });

    test('recentFailures returns errors and fatals, newest first', () async {
      final _FakeNative native = _FakeNative(
        history: <DiagnosticEvent>[
          _event(id: 'ok', sequence: 0, secondsPastNine: 1),
          _event(id: 'warn', sequence: 1, level: DiagLevel.warning, secondsPastNine: 2),
          _event(id: 'err', sequence: 2, level: DiagLevel.error, secondsPastNine: 3),
          _event(id: 'fatal', sequence: 3, level: DiagLevel.fatal, secondsPastNine: 4),
        ],
      );
      final DiagnosticsRepository repository =
          DiagnosticsRepository(logger: logger, native: native);
      await repository.load();

      expect(
        repository.recentFailures().map((DiagnosticEvent e) => e.id),
        <String>['fatal', 'err'],
        reason: 'a warning is not a failure',
      );
    });

    test('known packages and profiles come from the loaded window', () async {
      final _FakeNative native = _FakeNative(
        history: <DiagnosticEvent>[
          _event(
            id: 'a',
            sequence: 0,
            packageName: 'org.videolan.vlc',
            profileId: 'p-1',
          ),
          _event(id: 'b', sequence: 1, packageName: 'net.gsantner.markor'),
          _event(id: 'c', sequence: 2),
        ],
      );
      final DiagnosticsRepository repository =
          DiagnosticsRepository(logger: logger, native: native);
      await repository.load();

      expect(
        repository.knownPackages(),
        <String>['net.gsantner.markor', 'org.videolan.vlc'],
      );
      expect(repository.knownProfiles(), <String>['p-1']);
    });

    test('clear empties both sides', () async {
      final _FakeNative native = _FakeNative(
        history: <DiagnosticEvent>[_event(id: 'n', sequence: 0)],
      );
      final DiagnosticsRepository repository =
          DiagnosticsRepository(logger: logger, native: native);
      await repository.load();
      expect(repository.events, isNotEmpty);

      await repository.clear();

      expect(repository.events, isEmpty);
      expect(native.clearCount, 1);
      expect(logger.recentEvents(), isEmpty);
    });

    test('the loaded window is bounded', () async {
      final _FakeNative native = _FakeNative(
        history: <DiagnosticEvent>[
          for (int index = 0; index < DiagnosticsRepository.maxLoadedEvents + 50; index++)
            _event(id: 'e$index', sequence: index),
        ],
      );
      final DiagnosticsRepository repository =
          DiagnosticsRepository(logger: logger, native: native);
      await repository.load();

      expect(repository.events.length, DiagnosticsRepository.maxLoadedEvents);
      expect(
        repository.events.last.id,
        'e${DiagnosticsRepository.maxLoadedEvents + 49}',
        reason: 'the newest events are the ones kept',
      );
    });
  });

  group('DiagnosticsExporter', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('duplika-export-test');
    });

    tearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    Future<DiagnosticsRepository> repositoryWith(
      List<DiagnosticEvent> events,
    ) async {
      final DiagnosticsRepository repository = DiagnosticsRepository(
        logger: logger,
        native: _FakeNative(history: events),
      );
      await repository.load();
      return repository;
    }

    test('writes the documented bundle', () async {
      final DiagnosticsRepository repository = await repositoryWith(<DiagnosticEvent>[
        _event(
          id: 'a',
          sequence: 0,
          operation: 'launch_20260908_001',
          operationName: 'launch VLC',
          message: 'launch started',
          secondsPastNine: 1,
        ),
        _event(
          id: 'b',
          sequence: 1,
          level: DiagLevel.error,
          operation: 'launch_20260908_001',
          message: 'Failed to initialize external storage',
          packageName: 'org.videolan.vlc',
          secondsPastNine: 7,
        ),
      ]);

      final DiagnosticsExport export = await DiagnosticsExporter(
        repository: repository,
        directoryProvider: () async => root,
      ).write();

      expect(
        export.files.map((String path) => path.split('/').last),
        containsAll(<String>[
          'diagnostic-events.json',
          'diagnostic-events.txt',
          'system-info.json',
          'recent-errors.txt',
          'DUPLIKA-DIAGNOSTICS-REPORT.txt',
        ]),
      );
      expect(export.eventCount, 2);
      expect(export.totalBytes, greaterThan(0));

      final Map<String, dynamic> json = jsonDecode(
        File('${export.directory}/diagnostic-events.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(json['count'], 2);
      expect((json['events'] as List<dynamic>).length, 2);

      final String report =
          File('${export.directory}/DUPLIKA-DIAGNOSTICS-REPORT.txt').readAsStringSync();
      expect(report, contains('DUPLIKA DIAGNOSTICS REPORT'));
      expect(report, contains('CPH2605'));
      expect(report, contains('Failed to initialize external storage'));
      expect(report, contains('launch_20260908_001'));
      expect(report, contains('EVENT TIMELINE'));

      final String errors =
          File('${export.directory}/recent-errors.txt').readAsStringSync();
      expect(errors, contains('Failed to initialize external storage'));
    });

    test('a filtered export says so in its header', () async {
      final DiagnosticsRepository repository = await repositoryWith(<DiagnosticEvent>[
        _event(id: 'a', sequence: 0, secondsPastNine: 1),
        _event(id: 'b', sequence: 1, level: DiagLevel.error, secondsPastNine: 2),
      ]);

      final DiagnosticsExport export = await DiagnosticsExporter(
        repository: repository,
        directoryProvider: () async => root,
      ).write(filter: const DiagnosticFilter(minimumLevel: DiagLevel.error));

      expect(export.eventCount, 1);
      final String report =
          File('${export.directory}/DUPLIKA-DIAGNOSTICS-REPORT.txt').readAsStringSync();
      expect(report, contains('Filter:         >= ERROR'));
    });

    test('says plainly when there were no failures', () async {
      final DiagnosticsRepository repository = await repositoryWith(<DiagnosticEvent>[
        _event(id: 'a', sequence: 0),
      ]);

      final DiagnosticsExport export = await DiagnosticsExporter(
        repository: repository,
        directoryProvider: () async => root,
      ).write();

      expect(
        File('${export.directory}/recent-errors.txt').readAsStringSync(),
        contains('No errors or fatal events'),
      );
    });

    test('clearPrevious removes earlier bundles', () async {
      final DiagnosticsRepository repository = await repositoryWith(<DiagnosticEvent>[
        _event(id: 'a', sequence: 0),
      ]);
      final DiagnosticsExporter exporter = DiagnosticsExporter(
        repository: repository,
        directoryProvider: () async => root,
      );

      await exporter.write();
      expect(Directory('${root.path}/diagnostics_export').existsSync(), isTrue);

      await exporter.clearPrevious();
      expect(Directory('${root.path}/diagnostics_export').existsSync(), isFalse);
    });
  });
}
