import 'dart:async';

import 'package:flutter/foundation.dart';

import 'diagnostic_event.dart';
import 'diagnostic_filter.dart';
import 'diagnostic_logger.dart';
import 'native_diagnostics.dart';
import 'system_info.dart';

/// One operation's events, in order, with its outcome already worked out.
@immutable
class OperationTimeline {
  const OperationTimeline({
    required this.operationId,
    required this.name,
    required this.events,
  });

  final String operationId;
  final String name;

  /// Oldest first. A timeline read newest-first is a timeline nobody can follow.
  final List<DiagnosticEvent> events;

  DateTime? get startedAt => events.isEmpty ? null : events.first.timestamp;

  DateTime? get endedAt => events.isEmpty ? null : events.last.timestamp;

  Duration? get duration => events.isEmpty
      ? null
      : events.last.timestamp.difference(events.first.timestamp);

  /// The worst thing that happened, which is what the operation is judged on.
  DiagLevel get outcome => events.fold(
        DiagLevel.debug,
        (DiagLevel worst, DiagnosticEvent event) =>
            event.level.severity > worst.severity ? event.level : worst,
      );

  bool get failed => outcome.severity >= DiagLevel.error.severity;

  List<DiagnosticEvent> get failures =>
      events.where((DiagnosticEvent event) => event.isFailure).toList(growable: false);
}

/// The console's read model.
///
/// Merges three sources that all have a reason to exist:
///
/// * the logger's in-memory ring, which is what makes the console open instantly and
///   is the only place `DEBUG` events live;
/// * the Dart persistent store, which survives a restart;
/// * the native store, which survives a restart *and* covers the guest processes,
///   where no Flutter engine exists to log from.
///
/// Deduplication is by event id, so an event that appears in more than one source is
/// shown once.
class DiagnosticsRepository {
  DiagnosticsRepository({
    DiagnosticLogger? logger,
    NativeDiagnostics? native,
  })  : _logger = logger ?? DiagnosticLogger.instance,
        _native = native ?? NativeDiagnostics();

  final DiagnosticLogger _logger;
  final NativeDiagnostics _native;

  /// Hard ceiling on how many events the console will hold at once.
  ///
  /// Without it, a long session's merged history would grow until the list view — and
  /// then the filter pass over it — became the app's slowest screen. The newest events
  /// are the ones kept.
  static const int maxLoadedEvents = 3000;

  final List<DiagnosticEvent> _events = <DiagnosticEvent>[];
  final Set<String> _seenIds = <String>{};

  /// Everything currently loaded, oldest first.
  List<DiagnosticEvent> get events => List<DiagnosticEvent>.unmodifiable(_events);

  Stream<DiagnosticEvent> get liveEvents => _logger.stream;

  bool get nativeAvailable => _native.isAvailable;

  /// Reloads the whole merged history from every source.
  Future<void> load() async {
    final List<DiagnosticEvent> merged = <DiagnosticEvent>[
      ...await _logger.history(limit: maxLoadedEvents),
      ...await _native.readHistory(limit: maxLoadedEvents),
      ..._logger.recentEvents(),
    ];

    _events.clear();
    _seenIds.clear();
    _ingest(merged);
  }

  /// Adds a single live event, keeping the loaded window ordered and bounded.
  ///
  /// Returns false when the event was already known, so a caller does not repaint for
  /// nothing.
  bool add(DiagnosticEvent event) {
    if (_seenIds.contains(event.id)) {
      return false;
    }
    _seenIds.add(event.id);

    // Live events almost always belong at the end, so check that before sorting.
    if (_events.isEmpty || _compare(_events.last, event) <= 0) {
      _events.add(event);
    } else {
      _events.add(event);
      _events.sort(_compare);
    }
    _trim();
    return true;
  }

  Future<void> clear() async {
    await _logger.clear();
    await _native.clearHistory();
    _events.clear();
    _seenIds.clear();
  }

  Future<SystemInfoSnapshot> systemInfo() => _native.systemInfo();

  NativeDiagnostics get native => _native;

  List<DiagnosticEvent> filter(DiagnosticFilter filter) {
    if (!filter.isActive) {
      return events;
    }
    return _events.where(filter.matches).toList(growable: false);
  }

  /// The most recent failures, newest first.
  List<DiagnosticEvent> recentFailures({int limit = 200}) {
    final List<DiagnosticEvent> failures = _events
        .where((DiagnosticEvent event) => event.isFailure)
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    return failures.length <= limit ? failures : failures.sublist(0, limit);
  }

  /// Distinct package names seen in the loaded window, for the package filter.
  List<String> knownPackages() => _distinct((DiagnosticEvent e) => e.packageName);

  List<String> knownProfiles() => _distinct((DiagnosticEvent e) => e.profileId);

  /// Operations seen in the loaded window, newest first.
  List<OperationTimeline> operations({int limit = 100}) {
    final Map<String, List<DiagnosticEvent>> grouped = <String, List<DiagnosticEvent>>{};
    for (final DiagnosticEvent event in _events) {
      final String? id = event.operation;
      if (id == null) {
        continue;
      }
      grouped.putIfAbsent(id, () => <DiagnosticEvent>[]).add(event);
    }

    final List<OperationTimeline> timelines = grouped.entries
        .map(
          (MapEntry<String, List<DiagnosticEvent>> entry) => OperationTimeline(
            operationId: entry.key,
            name: entry.value
                    .map((DiagnosticEvent e) => e.operationName)
                    .firstWhere((String? name) => name != null, orElse: () => null) ??
                entry.key,
            events: entry.value,
          ),
        )
        .toList()
      ..sort(
        (OperationTimeline a, OperationTimeline b) =>
            b.events.last.timestamp.compareTo(a.events.last.timestamp),
      );

    return timelines.length <= limit ? timelines : timelines.sublist(0, limit);
  }

  /// One operation's events. Empty when the operation has aged out of the window.
  OperationTimeline timelineFor(String operationId) {
    final List<DiagnosticEvent> events = _events
        .where((DiagnosticEvent event) => event.operation == operationId)
        .toList(growable: false);
    return OperationTimeline(
      operationId: operationId,
      name: events
              .map((DiagnosticEvent e) => e.operationName)
              .firstWhere((String? name) => name != null, orElse: () => null) ??
          operationId,
      events: events,
    );
  }

  /// The events immediately around [event], for the "what led to this" panel.
  ///
  /// Neighbours by position, not by operation: an error whose cause was never given an
  /// operation id — a plugin blowing up, a native crash — still has a story before it,
  /// and this is the only way to see it.
  List<DiagnosticEvent> neighboursOf(DiagnosticEvent event, {int span = 10}) {
    final int index = _events.indexWhere((DiagnosticEvent other) => other.id == event.id);
    if (index < 0) {
      return const <DiagnosticEvent>[];
    }
    final int start = (index - span).clamp(0, _events.length);
    final int end = (index + span + 1).clamp(0, _events.length);
    return _events.sublist(start, end);
  }

  /// Other events sharing this event's operation id.
  List<DiagnosticEvent> relatedTo(DiagnosticEvent event) {
    final String? operation = event.operation;
    if (operation == null) {
      return const <DiagnosticEvent>[];
    }
    return _events
        .where((DiagnosticEvent other) =>
            other.operation == operation && other.id != event.id)
        .toList(growable: false);
  }

  void _ingest(List<DiagnosticEvent> incoming) {
    for (final DiagnosticEvent event in incoming) {
      if (event.id.isEmpty || _seenIds.add(event.id)) {
        _events.add(event);
      }
    }
    _events.sort(_compare);
    _trim();
  }

  void _trim() {
    if (_events.length <= maxLoadedEvents) {
      return;
    }
    final List<DiagnosticEvent> dropped =
        _events.sublist(0, _events.length - maxLoadedEvents);
    _events.removeRange(0, dropped.length);
    for (final DiagnosticEvent event in dropped) {
      _seenIds.remove(event.id);
    }
  }

  List<String> _distinct(String? Function(DiagnosticEvent event) selector) {
    final Set<String> values = <String>{};
    for (final DiagnosticEvent event in _events) {
      final String? value = selector(event);
      if (value != null && value.isNotEmpty) {
        values.add(value);
      }
    }
    final List<String> sorted = values.toList()..sort();
    return sorted;
  }

  /// Timestamp first, then sequence.
  ///
  /// Sequence alone would interleave wrongly, because Dart and each native process
  /// keep their own counters; timestamp alone would reorder events that share a
  /// millisecond, which on a fast install path is most of them.
  static int _compare(DiagnosticEvent a, DiagnosticEvent b) {
    final int byTime = a.timestamp.compareTo(b.timestamp);
    if (byTime != 0) {
      return byTime;
    }
    return a.sequence.compareTo(b.sequence);
  }
}
