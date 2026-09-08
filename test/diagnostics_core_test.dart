import 'dart:io';

import 'package:duplika/core/diagnostics/diagnostic_buffer.dart';
import 'package:duplika/core/diagnostics/diagnostic_event.dart';
import 'package:duplika/core/diagnostics/diagnostic_filter.dart';
import 'package:duplika/core/diagnostics/diagnostic_logger.dart';
import 'package:duplika/core/diagnostics/diagnostic_operation.dart';
import 'package:duplika/core/diagnostics/diagnostic_redactor.dart';
import 'package:duplika/core/diagnostics/diagnostic_store.dart';
import 'package:flutter_test/flutter_test.dart';

DiagnosticEvent _event({
  String id = 'e1',
  int sequence = 0,
  DiagLevel level = DiagLevel.info,
  DiagnosticSource source = DiagnosticSource.dart,
  DiagnosticCategory category = DiagnosticCategory.unknown,
  String message = 'something happened',
  String? operation,
  String? packageName,
  DateTime? timestamp,
}) =>
    DiagnosticEvent(
      id: id,
      sequence: sequence,
      timestamp: timestamp ?? DateTime(2026, 9, 8, 9, 10, 7, 42),
      level: level,
      source: source,
      category: category,
      message: message,
      operation: operation,
      packageName: packageName,
    );

void main() {
  group('DiagnosticBuffer', () {
    test('drops the oldest event once capacity is reached', () {
      final DiagnosticBuffer buffer = DiagnosticBuffer(capacity: 3);
      for (int index = 0; index < 5; index++) {
        buffer.add(_event(id: 'e$index', sequence: index));
      }

      expect(buffer.length, 3);
      expect(
        buffer.toList().map((DiagnosticEvent e) => e.id),
        <String>['e2', 'e3', 'e4'],
        reason: 'the ring must keep the newest events, oldest first',
      );
    });

    test('reports how many events were recorded, not just retained', () {
      final DiagnosticBuffer buffer = DiagnosticBuffer(capacity: 2);
      for (int index = 0; index < 7; index++) {
        buffer.add(_event(id: 'e$index', sequence: index));
      }

      expect(buffer.totalRecorded, 7);
      expect(buffer.hasOverflowed, isTrue);
    });
  });

  group('DiagnosticEvent', () {
    test('survives a JSON round trip', () {
      final DiagnosticEvent original = DiagnosticEvent(
        id: 'abc',
        sequence: 12,
        timestamp: DateTime(2026, 9, 8, 9, 10, 7, 42),
        level: DiagLevel.error,
        source: DiagnosticSource.virtualEngine,
        category: DiagnosticCategory.launch,
        message: 'Launch failed',
        operation: 'launch_20260908_001',
        operationName: 'launch VLC',
        packageName: 'org.videolan.vlc',
        profileId: 'profile-1',
        virtualUserId: 3,
        exceptionType: 'StateError',
        stackTrace: '#0 main',
        metadata: const <String, String>{'code': 'VIRTUAL_APP_LAUNCH_FAILED'},
      );

      final DiagnosticEvent restored =
          DiagnosticEvent.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.level, DiagLevel.error);
      expect(restored.source, DiagnosticSource.virtualEngine);
      expect(restored.category, DiagnosticCategory.launch);
      expect(restored.operation, 'launch_20260908_001');
      expect(restored.virtualUserId, 3);
      expect(restored.metadata['code'], 'VIRTUAL_APP_LAUNCH_FAILED');
      expect(restored.timestamp.toUtc(), original.timestamp.toUtc());
    });

    test('an unknown wire value falls back instead of throwing', () {
      // A stored event written by a newer build must not make the whole segment
      // unreadable.
      final DiagnosticEvent restored = DiagnosticEvent.fromJson(<String, dynamic>{
        'id': 'x',
        'timestamp': '2026-09-08T09:10:07.000Z',
        'level': 'SHOUTING',
        'source': 'QUANTUM',
        'category': 'TELEPATHY',
        'message': 'hello',
      });

      expect(restored.level, DiagLevel.info);
      expect(restored.source, DiagnosticSource.system);
      expect(restored.category, DiagnosticCategory.unknown);
    });

    test('success is louder than info but quieter than warning', () {
      expect(DiagLevel.success.severity, greaterThan(DiagLevel.info.severity));
      expect(DiagLevel.success.severity, lessThan(DiagLevel.warning.severity));
    });
  });

  group('DiagnosticRedactor', () {
    test('removes bearer tokens and JWTs from free text', () {
      const String text =
          'GET /v1/me failed, Authorization: Bearer abcdefghijklmnop1234';
      expect(DiagnosticRedactor.redactText(text), contains('[REDACTED]'));
      expect(DiagnosticRedactor.redactText(text), isNot(contains('abcdefghijklmnop')));

      const String jwt =
          'token eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.abcd';
      expect(DiagnosticRedactor.redactText(jwt), isNot(contains('eyJhbGciOi')));
    });

    test('redacts a sensitive value written inline', () {
      expect(
        DiagnosticRedactor.redactText('password=hunter2xyz and more'),
        'password=[REDACTED] and more',
      );
    });

    test('drops values under a sensitive metadata key', () {
      final Map<String, String> redacted =
          DiagnosticRedactor.redactMetadata(<String, String>{
        'packageName': 'org.videolan.vlc',
        'authToken': 'abc123def456',
      });

      expect(redacted['packageName'], 'org.videolan.vlc');
      expect(redacted['authToken'], '[REDACTED]');
    });

    test('leaves a long digit run that is not a card number alone', () {
      // Version codes, byte counts and epoch millis are all long digit runs. Redacting
      // those would make an install log unreadable, so only a Luhn-valid run is treated
      // as a card.
      const String line = 'installed 3110295 bytes at 1757321407000';
      expect(DiagnosticRedactor.redactText(line), line);
    });

    test('redacts a Luhn-valid card number', () {
      expect(
        DiagnosticRedactor.redactText('card 4111 1111 1111 1111 declined'),
        contains('[REDACTED]'),
      );
    });

    test('sanitises a path down to a root label and a filename', () {
      expect(
        DiagnosticRedactor.sanitizePath('/storage/emulated/0/Download/vlc.apk'),
        '<shared>/…/vlc.apk',
      );
      expect(
        DiagnosticRedactor.sanitizePath('/data/user/0/co.tdevs.duplika/files/a.apk'),
        '<app-data>/…/a.apk',
      );
    });
  });

  group('DiagnosticFilter', () {
    final DiagnosticEvent engineError = _event(
      id: 'a',
      level: DiagLevel.error,
      source: DiagnosticSource.virtualEngine,
      category: DiagnosticCategory.launch,
      message: 'Failed to initialize external storage',
      operation: 'launch_20260908_001',
      packageName: 'org.videolan.vlc',
    );
    final DiagnosticEvent channelDebug = _event(
      id: 'b',
      level: DiagLevel.debug,
      source: DiagnosticSource.methodChannel,
      message: 'Call started: listInstalledApps',
    );

    test('an empty filter matches everything', () {
      expect(DiagnosticFilter.none.isActive, isFalse);
      expect(DiagnosticFilter.none.matches(engineError), isTrue);
      expect(DiagnosticFilter.none.matches(channelDebug), isTrue);
    });

    test('a minimum level excludes quieter events', () {
      const DiagnosticFilter filter =
          DiagnosticFilter(minimumLevel: DiagLevel.warning);
      expect(filter.matches(engineError), isTrue);
      expect(filter.matches(channelDebug), isFalse);
    });

    test('a source filter is exclusive', () {
      const DiagnosticFilter filter = DiagnosticFilter(
        sources: <DiagnosticSource>{DiagnosticSource.virtualEngine},
      );
      expect(filter.matches(engineError), isTrue);
      expect(filter.matches(channelDebug), isFalse);
    });

    test('search covers the message, package and operation', () {
      expect(
        const DiagnosticFilter(query: 'external storage').matches(engineError),
        isTrue,
      );
      expect(const DiagnosticFilter(query: 'videolan').matches(engineError), isTrue);
      expect(
        const DiagnosticFilter(query: 'launch_20260908').matches(engineError),
        isTrue,
      );
      expect(const DiagnosticFilter(query: 'videolan').matches(channelDebug), isFalse);
    });

    test('an operation filter narrows to one timeline', () {
      const DiagnosticFilter filter =
          DiagnosticFilter(operationId: 'launch_20260908_001');
      expect(filter.matches(engineError), isTrue);
      expect(filter.matches(channelDebug), isFalse);
    });

    test('describe() names every active axis, for the export header', () {
      const DiagnosticFilter filter = DiagnosticFilter(
        minimumLevel: DiagLevel.error,
        query: 'storage',
      );
      expect(filter.activeCount, 2);
      expect(filter.describe(), contains('>= ERROR'));
      expect(filter.describe(), contains('storage'));
    });
  });

  group('DiagnosticOperation', () {
    late DiagnosticLogger logger;

    setUp(() {
      logger = DiagnosticLogger(buffer: DiagnosticBuffer(capacity: 64));
      DiagnosticLogger.instance = logger;
    });

    test('every event recorded inside run() carries the same operation id', () async {
      await DiagnosticOperation.run<void>(
        'launch',
        (DiagnosticOperation operation) async {
          logger.info(
            DiagnosticSource.virtualEngine,
            DiagnosticCategory.launch,
            'package resolved',
          );
          // The id has to survive an await, which is the whole reason it is a zone
          // value rather than a field.
          await Future<void>.delayed(Duration.zero);
          logger.success(
            DiagnosticSource.guestProcess,
            DiagnosticCategory.process,
            'guest process created',
          );
        },
        name: 'launch VLC',
        packageName: 'org.videolan.vlc',
      );

      final List<DiagnosticEvent> events = logger.recentEvents();
      final Set<String?> ids =
          events.map((DiagnosticEvent event) => event.operation).toSet();

      expect(ids.length, 1, reason: 'all events belong to one operation');
      expect(ids.single, startsWith('launch_'));
      expect(
        events.map((DiagnosticEvent event) => event.message),
        containsAllInOrder(<String>[
          'launch VLC started',
          'package resolved',
          'guest process created',
          'launch VLC finished',
        ]),
      );
      expect(
        events.every((DiagnosticEvent event) => event.packageName == 'org.videolan.vlc'),
        isTrue,
        reason: 'the operation supplies the package to events that omit it',
      );
    });

    test('a failing operation records the error and rethrows unchanged', () async {
      await expectLater(
        DiagnosticOperation.run<void>(
          'launch',
          (DiagnosticOperation operation) async =>
              throw StateError('engine refused'),
        ),
        throwsA(isA<StateError>()),
      );

      final DiagnosticEvent failure = logger
          .recentEvents()
          .lastWhere((DiagnosticEvent event) => event.isFailure);
      expect(failure.level, DiagLevel.error);
      expect(failure.exceptionType, 'StateError');
      expect(failure.stackTrace, isNotNull);
    });

    test('there is no ambient operation outside run()', () {
      expect(DiagnosticOperation.current, isNull);
    });

    test('ids are readable, and carry a run token so two runs cannot collide', () {
      final DiagnosticOperation first = DiagnosticOperation.start('launch');
      final DiagnosticOperation second = DiagnosticOperation.start('launch');
      expect(first.id, matches(RegExp(r'^launch_\d{8}_[a-z0-9]{3}_\d{3}$')));
      expect(first.id, isNot(second.id));
    });
  });

  group('FileDiagnosticEventStore', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('duplika-diagnostics-test');
    });

    tearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    test('writes and reads events back', () async {
      final FileDiagnosticEventStore store = FileDiagnosticEventStore(
        directoryProvider: () async => root,
      );

      await store.append(<DiagnosticEvent>[
        _event(id: 'a', sequence: 0),
        _event(id: 'b', sequence: 1, level: DiagLevel.error),
      ]);

      final List<DiagnosticEvent> read = await store.read();
      expect(read.map((DiagnosticEvent e) => e.id), <String>['a', 'b']);
      expect(read.last.level, DiagLevel.error);
      expect(await store.occupiedBytes(), greaterThan(0));
    });

    test('rotation bounds the store to two segments', () async {
      final FileDiagnosticEventStore store = FileDiagnosticEventStore(
        // Small enough that a handful of events forces several rotations.
        maxSegmentBytes: 512,
        directoryProvider: () async => root,
      );

      for (int index = 0; index < 200; index++) {
        await store.append(<DiagnosticEvent>[
          _event(id: 'e$index', sequence: index, message: 'event number $index'),
        ]);
      }

      final List<File> files = Directory('${root.path}/diagnostics')
          .listSync()
          .whereType<File>()
          .toList();
      expect(files.length, lessThanOrEqualTo(2),
          reason: 'retention is rotation between two segments, not unbounded files');

      final int totalBytes = await store.occupiedBytes();
      expect(totalBytes, lessThanOrEqualTo(512 * 2 + 4096),
          reason: 'a rotated store stays within roughly two segments');

      // The newest events are the ones kept.
      final List<DiagnosticEvent> read = await store.read();
      expect(read.last.id, 'e199');
    });

    test('a corrupt line costs one event, not the segment', () async {
      final Directory diagnostics = Directory('${root.path}/diagnostics')
        ..createSync(recursive: true);
      final DiagnosticEvent good = _event(id: 'good', sequence: 1);
      File('${diagnostics.path}/events.jsonl').writeAsStringSync(
        '{"id":"broken","level":\n${good.toJsonLine()}\n',
      );

      final FileDiagnosticEventStore store = FileDiagnosticEventStore(
        directoryProvider: () async => root,
      );

      final List<DiagnosticEvent> read = await store.read();
      expect(read.map((DiagnosticEvent e) => e.id), <String>['good']);
    });

    test('read is newest-biased when the limit is exceeded', () async {
      final FileDiagnosticEventStore store = FileDiagnosticEventStore(
        directoryProvider: () async => root,
      );
      await store.append(<DiagnosticEvent>[
        for (int index = 0; index < 10; index++)
          _event(
            id: 'e$index',
            sequence: index,
            timestamp: DateTime(2026, 9, 8, 9, 0, index),
          ),
      ]);

      final List<DiagnosticEvent> read = await store.read(limit: 3);
      expect(read.map((DiagnosticEvent e) => e.id), <String>['e7', 'e8', 'e9']);
    });

    test('clear empties the store', () async {
      final FileDiagnosticEventStore store = FileDiagnosticEventStore(
        directoryProvider: () async => root,
      );
      await store.append(<DiagnosticEvent>[_event()]);
      await store.clear();
      expect(await store.read(), isEmpty);
      expect(await store.occupiedBytes(), 0);
    });
  });

  group('DiagnosticLogger', () {
    test('redacts as it records, not as it renders', () {
      final DiagnosticLogger logger =
          DiagnosticLogger(buffer: DiagnosticBuffer(capacity: 8));

      logger.record(
        level: DiagLevel.error,
        source: DiagnosticSource.network,
        category: DiagnosticCategory.network,
        message: 'request failed with Authorization: Bearer abcdefgh12345678',
        metadata: <String, String>{'sessionToken': 'zzz999zzz'},
      );

      final DiagnosticEvent event = logger.recentEvents().single;
      expect(event.message, isNot(contains('abcdefgh12345678')));
      expect(event.metadata['sessionToken'], '[REDACTED]');
    });

    test('keeps debug events in memory and out of persistence', () async {
      final _RecordingStore store = _RecordingStore();
      final DiagnosticLogger logger = DiagnosticLogger(
        buffer: DiagnosticBuffer(capacity: 8),
        store: store,
        flushThreshold: 1,
      );

      logger.debug(DiagnosticSource.dart, DiagnosticCategory.unknown, 'noisy');
      logger.info(DiagnosticSource.dart, DiagnosticCategory.unknown, 'worth keeping');
      await logger.flush();

      expect(logger.recentEvents().length, 2);
      expect(
        store.written.map((DiagnosticEvent e) => e.message),
        <String>['worth keeping'],
      );
    });

    test('external events are buffered but not written twice', () async {
      final _RecordingStore store = _RecordingStore();
      final DiagnosticLogger logger = DiagnosticLogger(
        buffer: DiagnosticBuffer(capacity: 8),
        store: store,
        flushThreshold: 1,
      );

      // Native events already have a durable copy written by the Kotlin store.
      logger.recordExternal(_event(id: 'native-1', level: DiagLevel.error));
      await logger.flush();

      expect(logger.recentEvents().single.id, 'native-1');
      expect(store.written, isEmpty);
    });

    test('recording never throws when the store fails', () async {
      final DiagnosticLogger logger = DiagnosticLogger(
        buffer: DiagnosticBuffer(capacity: 4),
        store: _ThrowingStore(),
        flushThreshold: 1,
      );

      expect(
        () => logger.error(
          DiagnosticSource.storage,
          DiagnosticCategory.storage,
          'disk on fire',
        ),
        returnsNormally,
      );
      await logger.flush();
      expect(logger.recentEvents().single.message, 'disk on fire');
    });
  });
}

class _RecordingStore implements DiagnosticEventStore {
  final List<DiagnosticEvent> written = <DiagnosticEvent>[];

  @override
  bool get isPersistent => true;

  @override
  Future<void> append(List<DiagnosticEvent> events) async => written.addAll(events);

  @override
  Future<List<DiagnosticEvent>> read({int limit = 0}) async => written;

  @override
  Future<void> clear() async => written.clear();

  @override
  Future<int> occupiedBytes() async => written.length;
}

class _ThrowingStore implements DiagnosticEventStore {
  @override
  bool get isPersistent => true;

  @override
  Future<void> append(List<DiagnosticEvent> events) async =>
      throw const FileSystemException('no space left on device');

  @override
  Future<List<DiagnosticEvent>> read({int limit = 0}) async =>
      throw const FileSystemException('unreadable');

  @override
  Future<void> clear() async {}

  @override
  Future<int> occupiedBytes() async => 0;
}
