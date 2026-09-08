import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'diagnostic_event.dart';
import 'diagnostic_filter.dart';
import 'diagnostics_repository.dart';
import 'native_diagnostics.dart';
import 'system_info.dart';

/// What an export produced.
@immutable
class DiagnosticsExport {
  const DiagnosticsExport({
    required this.directory,
    required this.files,
    required this.eventCount,
    required this.totalBytes,
  });

  final String directory;

  /// Absolute paths, in the order they should be attached.
  final List<String> files;
  final int eventCount;
  final int totalBytes;
}

/// Writes a shareable diagnostics bundle.
///
/// Everything lands in the app's own cache directory, which needs no permission at all
/// and is reclaimable by the system. Nothing is written to shared storage: an export is
/// something you send to a developer, not something that should quietly accumulate in
/// the user's Downloads folder.
class DiagnosticsExporter {
  DiagnosticsExporter({
    required this._repository,
    Future<Directory> Function()? directoryProvider,
  })  : _directoryProvider = directoryProvider ?? getTemporaryDirectory;

  static const String _exportDirectoryName = 'diagnostics_export';

  final DiagnosticsRepository _repository;
  final Future<Directory> Function() _directoryProvider;

  /// Builds the bundle described in `docs/diagnostics-system.md`.
  ///
  /// [filter] is applied to the event files and recorded in the report header, so a
  /// filtered export cannot be mistaken for the full history.
  Future<DiagnosticsExport> write({
    DiagnosticFilter filter = DiagnosticFilter.none,
    SystemInfoSnapshot? systemInfo,
    Map<String, NativeProbeResult> subsystemReports = const <String, NativeProbeResult>{},
  }) async {
    final Directory base = await _directoryProvider();
    final Directory target = Directory(
      '${base.path}/$_exportDirectoryName/${_stamp(DateTime.now())}',
    );

    // A previous export of the same second would otherwise be merged into.
    if (target.existsSync()) {
      await target.delete(recursive: true);
    }
    await target.create(recursive: true);

    final SystemInfoSnapshot info = systemInfo ?? await _repository.systemInfo();
    final List<DiagnosticEvent> events = _repository.filter(filter);
    final List<DiagnosticEvent> failures = events
        .where((DiagnosticEvent event) => event.isFailure)
        .toList(growable: false);

    final List<String> written = <String>[];

    written.add(
      await _writeFile(target, 'diagnostic-events.json', _encodeEvents(events, filter)),
    );
    written.add(
      await _writeFile(
        target,
        'diagnostic-events.txt',
        events.map((DiagnosticEvent event) => event.toLogLine()).join('\n'),
      ),
    );
    written.add(
      await _writeFile(
        target,
        'system-info.json',
        const JsonEncoder.withIndent('  ').convert(info.toJson()),
      ),
    );
    written.add(
      await _writeFile(
        target,
        'recent-errors.txt',
        failures.isEmpty
            ? 'No errors or fatal events in the exported window.\n'
            : failures.reversed
                .map((DiagnosticEvent event) => event.toLogLine())
                .join('\n\n'),
      ),
    );
    written.add(
      await _writeFile(
        target,
        'DUPLIKA-DIAGNOSTICS-REPORT.txt',
        buildTextReport(events: events, info: info, filter: filter),
      ),
    );

    for (final MapEntry<String, NativeProbeResult> entry in subsystemReports.entries) {
      if (entry.value.text.trim().isEmpty) {
        continue;
      }
      written.add(
        await _writeFile(target, '${entry.key}-report.txt', entry.value.text),
      );
    }

    int totalBytes = 0;
    for (final String path in written) {
      totalBytes += await File(path).length();
    }

    return DiagnosticsExport(
      directory: target.path,
      files: written,
      eventCount: events.length,
      totalBytes: totalBytes,
    );
  }

  /// Deletes previously written bundles.
  ///
  /// Exports are copies of a size-bounded log, but the bundles themselves are not
  /// bounded, so they are cleared before each new one rather than left to accumulate
  /// in the cache.
  Future<void> clearPrevious() async {
    try {
      final Directory base = await _directoryProvider();
      final Directory root = Directory('${base.path}/$_exportDirectoryName');
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    } on FileSystemException {
      // A cache directory the system reclaimed underneath us. Nothing to clean.
    }
  }

  /// The human-readable report.
  ///
  /// Ordered the way a report is actually read: what device, what state the engine was
  /// in, what went wrong, and only then the full sequence.
  String buildTextReport({
    required List<DiagnosticEvent> events,
    required SystemInfoSnapshot info,
    DiagnosticFilter filter = DiagnosticFilter.none,
  }) {
    final StringBuffer out = StringBuffer();
    void rule() => out.writeln('=' * 72);

    rule();
    out
      ..writeln('DUPLIKA DIAGNOSTICS REPORT')
      ..writeln()
      ..writeln('Generated:      ${DiagnosticEvent.formatFullTimestamp(DateTime.now())}')
      ..writeln('Events:         ${events.length}')
      ..writeln('Filter:         ${filter.describe()}')
      ..writeln('Build:          ${info.buildType}')
      ..writeln('App version:    ${info.appVersion ?? 'unavailable'}')
      ..writeln('Device:         ${info.deviceSummary}')
      ..writeln('Engine status:  ${info.engineStatus}');
    rule();
    out.writeln();

    out.write(info.toReportText());

    final List<DiagnosticEvent> failures = events
        .where((DiagnosticEvent event) => event.isFailure)
        .toList(growable: false);

    rule();
    out
      ..writeln('FAILURES (${failures.length})')
      ..writeln();
    if (failures.isEmpty) {
      out.writeln('  None recorded in this window.');
    } else {
      // Newest first: the failure that prompted the report is the one at the top.
      for (final DiagnosticEvent failure in failures.reversed.take(25)) {
        out
          ..writeln('  ${DiagnosticEvent.formatFullTimestamp(failure.timestamp)}'
              '  ${failure.level.wire}')
          ..writeln('  Source:       ${failure.source.wire} / ${failure.category.wire}')
          ..writeln('  Package:      ${failure.packageName ?? '-'}')
          ..writeln('  Profile:      ${failure.profileId ?? '-'}')
          ..writeln('  Process:      ${failure.processName ?? '-'}')
          ..writeln('  Operation:    ${failure.operation ?? '-'}')
          ..writeln('  Message:      ${failure.message}');
        if (failure.exceptionType != null) {
          out.writeln('  Exception:    ${failure.exceptionType}');
        }
        if (failure.details != null && failure.details!.isNotEmpty) {
          out.writeln('  Details:      ${failure.details!.replaceAll('\n', '\n                ')}');
        }
        if (failure.stackTrace != null && failure.stackTrace!.isNotEmpty) {
          out
            ..writeln('  Stack trace:')
            ..writeln('    ${failure.stackTrace!.trim().replaceAll('\n', '\n    ')}');
        }
        out.writeln();
      }
      if (failures.length > 25) {
        out.writeln('  ... ${failures.length - 25} older failures in recent-errors.txt');
      }
    }
    out.writeln();

    final List<OperationTimeline> operations = _timelines(events);
    rule();
    out
      ..writeln('OPERATIONS (${operations.length})')
      ..writeln();
    for (final OperationTimeline timeline in operations.take(20)) {
      out.writeln('  ${timeline.operationId}  ${timeline.name}  '
          '[${timeline.outcome.wire}, ${timeline.duration?.inMilliseconds ?? 0} ms, '
          '${timeline.events.length} events]');
    }
    out.writeln();

    rule();
    out
      ..writeln('EVENT TIMELINE')
      ..writeln();
    for (final DiagnosticEvent event in events) {
      out.writeln(event.toLogLine());
    }
    out.writeln();
    rule();
    out.writeln('END OF REPORT');
    return out.toString();
  }

  List<OperationTimeline> _timelines(List<DiagnosticEvent> events) {
    final Map<String, List<DiagnosticEvent>> grouped = <String, List<DiagnosticEvent>>{};
    for (final DiagnosticEvent event in events) {
      final String? id = event.operation;
      if (id != null) {
        grouped.putIfAbsent(id, () => <DiagnosticEvent>[]).add(event);
      }
    }
    return grouped.entries
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
  }

  String _encodeEvents(List<DiagnosticEvent> events, DiagnosticFilter filter) =>
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'filter': filter.describe(),
        'count': events.length,
        'events': events.map((DiagnosticEvent event) => event.toJson()).toList(),
      });

  Future<String> _writeFile(Directory directory, String name, String contents) async {
    final File file = File('${directory.path}/$name');
    await file.writeAsString(contents, flush: true);
    return file.path;
  }

  static String _stamp(DateTime value) => '${value.year}'
      '${value.month.toString().padLeft(2, '0')}'
      '${value.day.toString().padLeft(2, '0')}-'
      '${value.hour.toString().padLeft(2, '0')}'
      '${value.minute.toString().padLeft(2, '0')}'
      '${value.second.toString().padLeft(2, '0')}';
}
