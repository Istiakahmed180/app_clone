import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'diagnostic_event.dart';

/// Where recorded events go so they survive a restart.
abstract class DiagnosticEventStore {
  /// Whether writing to this store is worth doing at all.
  ///
  /// False lets the logger skip its batching machinery entirely — no queue, no flush
  /// timer — which is what makes a unit or widget test free of a pending timer it never
  /// asked for.
  bool get isPersistent;

  /// Appends a batch. Implementations must never throw: a logging failure has to stay
  /// a logging failure, not become the crash under investigation.
  Future<void> append(List<DiagnosticEvent> events);

  /// Oldest first, newest-biased when truncating: if the history exceeds [limit], the
  /// most recent [limit] events are returned. Older events are the ones you can afford
  /// to lose.
  Future<List<DiagnosticEvent>> read({int limit});

  Future<void> clear();

  /// Bytes currently held, for the console's storage line.
  Future<int> occupiedBytes();
}

/// A store that keeps nothing.
///
/// Used on platforms with no writable app directory and in unit tests, so callers do
/// not have to branch on whether persistence exists.
class NoopDiagnosticEventStore implements DiagnosticEventStore {
  const NoopDiagnosticEventStore();

  @override
  bool get isPersistent => false;

  @override
  Future<void> append(List<DiagnosticEvent> events) async {}

  @override
  Future<List<DiagnosticEvent>> read({int limit = 0}) async => const <DiagnosticEvent>[];

  @override
  Future<void> clear() async {}

  @override
  Future<int> occupiedBytes() async => 0;
}

/// JSON-lines on disk, in two rotating segments.
///
/// One line per event means a corrupt tail (a write interrupted by a kill) costs one
/// event rather than the whole history, and appending never has to read what is already
/// there.
///
/// Retention is bounded twice over, because either bound alone fails: a byte cap alone
/// lets a flood of tiny events fill the console, and an event cap alone lets a handful
/// of huge stack traces fill the disk.
///
/// * Two segments of [maxSegmentBytes] each — so at most `2 x maxSegmentBytes` on disk.
/// * At most [maxEvents] returned by [read].
///
/// Pruning is rotation, not rewriting: when the live segment is full it becomes the
/// previous segment and the previous one is deleted. Rewriting a log to drop its head
/// would mean reading and re-serialising the entire history on the very code path that
/// must stay cheap.
class FileDiagnosticEventStore implements DiagnosticEventStore {
  FileDiagnosticEventStore({
    this.maxSegmentBytes = 512 * 1024,
    this.maxEvents = 5000,
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const String _directoryName = 'diagnostics';
  static const String _currentSegment = 'events.jsonl';
  static const String _previousSegment = 'events.1.jsonl';

  final int maxSegmentBytes;
  final int maxEvents;
  final Future<Directory> Function() _directoryProvider;

  @override
  bool get isPersistent => true;

  Future<Directory?>? _directory;

  /// Serialises every file operation. Two concurrent appends could otherwise interleave
  /// halfway through a line and produce JSON that parses as neither event.
  Future<void> _pending = Future<void>.value();

  @override
  Future<void> append(List<DiagnosticEvent> events) {
    if (events.isEmpty) {
      return _pending;
    }
    return _serialise(() async {
      final Directory? directory = await _resolveDirectory();
      if (directory == null) {
        return;
      }

      final File current = File('${directory.path}/$_currentSegment');
      final String payload =
          '${events.map((DiagnosticEvent event) => event.toJsonLine()).join('\n')}\n';

      await current.writeAsString(payload, mode: FileMode.append, flush: false);

      if (await current.length() >= maxSegmentBytes) {
        await _rotate(directory, current);
      }
    });
  }

  @override
  Future<List<DiagnosticEvent>> read({int limit = 0}) async {
    final int effectiveLimit = limit <= 0 ? maxEvents : limit;
    // Reads queue behind pending appends so the console never shows a history that is
    // missing the event the user just triggered.
    await _pending;

    final Directory? directory = await _resolveDirectory();
    if (directory == null) {
      return const <DiagnosticEvent>[];
    }

    final List<DiagnosticEvent> events = <DiagnosticEvent>[];
    for (final String name in <String>[_previousSegment, _currentSegment]) {
      events.addAll(await _readSegment(File('${directory.path}/$name')));
    }

    events.sort(_byTime);
    if (events.length > effectiveLimit) {
      return events.sublist(events.length - effectiveLimit);
    }
    return events;
  }

  @override
  Future<void> clear() => _serialise(() async {
        final Directory? directory = await _resolveDirectory();
        if (directory == null) {
          return;
        }
        for (final String name in <String>[_currentSegment, _previousSegment]) {
          final File file = File('${directory.path}/$name');
          if (file.existsSync()) {
            await file.delete();
          }
        }
      });

  @override
  Future<int> occupiedBytes() async {
    await _pending;
    final Directory? directory = await _resolveDirectory();
    if (directory == null) {
      return 0;
    }
    int total = 0;
    for (final String name in <String>[_currentSegment, _previousSegment]) {
      final File file = File('${directory.path}/$name');
      if (file.existsSync()) {
        total += await file.length();
      }
    }
    return total;
  }

  Future<void> _rotate(Directory directory, File current) async {
    final File previous = File('${directory.path}/$_previousSegment');
    if (previous.existsSync()) {
      await previous.delete();
    }
    await current.rename(previous.path);
  }

  Future<List<DiagnosticEvent>> _readSegment(File file) async {
    if (!file.existsSync()) {
      return const <DiagnosticEvent>[];
    }
    final List<DiagnosticEvent> events = <DiagnosticEvent>[];
    try {
      for (final String line in await file.readAsLines()) {
        if (line.isEmpty) {
          continue;
        }
        try {
          final Object? decoded = jsonDecode(line);
          if (decoded is Map<String, dynamic>) {
            events.add(DiagnosticEvent.fromJson(decoded));
          }
        } on FormatException {
          // A half-written last line from a process that was killed mid-append. Skip
          // that event rather than losing the segment it lives in.
          continue;
        }
      }
    } on FileSystemException {
      return events;
    }
    return events;
  }

  Future<Directory?> _resolveDirectory() {
    return _directory ??= () async {
      try {
        final Directory base = await _directoryProvider();
        final Directory target = Directory('${base.path}/$_directoryName');
        if (!target.existsSync()) {
          await target.create(recursive: true);
        }
        return target;
      } on MissingPluginException {
        // No platform channel (unit tests, unsupported host). Persistence is optional;
        // the in-memory buffer still works.
        return null;
      } on FileSystemException {
        return null;
      }
    }();
  }

  /// Runs [action] after everything already queued, and swallows its failures.
  Future<void> _serialise(Future<void> Function() action) {
    _pending = _pending.then((_) => action()).catchError((Object _) {});
    return _pending;
  }

  static int _byTime(DiagnosticEvent a, DiagnosticEvent b) {
    final int byTimestamp = a.timestamp.compareTo(b.timestamp);
    return byTimestamp != 0 ? byTimestamp : a.sequence.compareTo(b.sequence);
  }
}
