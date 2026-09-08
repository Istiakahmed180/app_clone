import 'dart:convert';

import 'package:flutter/foundation.dart';

/// How bad it is.
///
/// [success] sits between [info] and [warning] deliberately: a completed operation is
/// worth finding quickly in a wall of `INFO`, but it is not a problem, so severity
/// filters ("warning and above") must not pick it up.
enum DiagLevel {
  debug('DEBUG', 0),
  info('INFO', 1),
  success('SUCCESS', 2),
  warning('WARNING', 3),
  error('ERROR', 4),
  fatal('FATAL', 5);

  const DiagLevel(this.wire, this.severity);

  /// The on-the-wire name. Shared with the Kotlin logger, so it must not be derived
  /// from the Dart enum name — renaming a constant would silently break stored events.
  final String wire;

  /// Ordering for "this level and above" filters. Not the enum index: [success] is
  /// louder than [info] in the UI but quieter than [warning] in a severity filter.
  final int severity;

  static DiagLevel parse(String? value) => _byWire[value] ?? DiagLevel.info;

  static final Map<String, DiagLevel> _byWire = <String, DiagLevel>{
    for (final DiagLevel level in DiagLevel.values) level.wire: level,
  };
}

/// Which subsystem produced the event.
///
/// This answers "who is talking", not "what were they doing" — that is
/// [DiagnosticCategory]. A storage failure raised by the engine is
/// `source: virtualEngine, category: storage`.
enum DiagnosticSource {
  flutter('FLUTTER'),
  dart('DART'),
  android('ANDROID'),
  kotlin('KOTLIN'),
  methodChannel('METHOD_CHANNEL'),
  virtualEngine('VIRTUAL_ENGINE'),
  bcore('BCORE'),
  apkImporter('APK_IMPORTER'),
  packageInstaller('PACKAGE_INSTALLER'),
  guestProcess('GUEST_PROCESS'),
  activity('ACTIVITY'),
  permission('PERMISSION'),
  storage('STORAGE'),
  webview('WEBVIEW'),
  notification('NOTIFICATION'),
  jobScheduler('JOBSCHEDULER'),
  network('NETWORK'),
  native('NATIVE'),
  system('SYSTEM');

  const DiagnosticSource(this.wire);

  final String wire;

  static DiagnosticSource parse(String? value) =>
      _byWire[value] ?? DiagnosticSource.system;

  static final Map<String, DiagnosticSource> _byWire = <String, DiagnosticSource>{
    for (final DiagnosticSource source in DiagnosticSource.values) source.wire: source,
  };
}

/// What was going on when the event was produced.
enum DiagnosticCategory {
  appLifecycle('APP_LIFECYCLE'),
  import('IMPORT'),
  install('INSTALL'),
  profile('PROFILE'),
  launch('LAUNCH'),
  process('PROCESS'),
  activity('ACTIVITY'),
  storage('STORAGE'),
  permission('PERMISSION'),
  webview('WEBVIEW'),
  notification('NOTIFICATION'),
  job('JOB'),
  network('NETWORK'),
  nativeLibrary('NATIVE_LIBRARY'),
  crash('CRASH'),
  unknown('UNKNOWN');

  const DiagnosticCategory(this.wire);

  final String wire;

  static DiagnosticCategory parse(String? value) =>
      _byWire[value] ?? DiagnosticCategory.unknown;

  static final Map<String, DiagnosticCategory> _byWire = <String, DiagnosticCategory>{
    for (final DiagnosticCategory category in DiagnosticCategory.values)
      category.wire: category,
  };
}

/// One recorded fact about what the application did.
///
/// The same shape is produced by the Kotlin logger (`diagnostics/DiagnosticEvent.kt`)
/// and by every Dart caller, so the console renders host and native events in a single
/// ordered timeline. Every field except [id], [timestamp], [level], [source],
/// [category] and [message] is optional: forcing a caller to invent a `profileId` for
/// an event that has nothing to do with a profile is how log fields become lies.
@immutable
class DiagnosticEvent {
  const DiagnosticEvent({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.source,
    required this.category,
    required this.message,
    this.sequence = 0,
    this.operation,
    this.operationName,
    this.details,
    this.stackTrace,
    this.exceptionType,
    this.packageName,
    this.profileId,
    this.processName,
    this.virtualUserId,
    this.thread,
    this.buildType,
    this.appVersion,
    this.deviceInfo,
    this.metadata = const <String, String>{},
  });

  factory DiagnosticEvent.fromJson(Map<String, dynamic> json) {
    final Object? rawMetadata = json['metadata'];
    return DiagnosticEvent(
      id: json['id'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '')?.toLocal() ??
              DateTime.fromMillisecondsSinceEpoch(0),
      sequence: _asInt(json['sequence']) ?? 0,
      level: DiagLevel.parse(json['level'] as String?),
      source: DiagnosticSource.parse(json['source'] as String?),
      category: DiagnosticCategory.parse(json['category'] as String?),
      operation: json['operation'] as String?,
      operationName: json['operationName'] as String?,
      message: json['message'] as String? ?? '',
      details: json['details'] as String?,
      stackTrace: json['stackTrace'] as String?,
      exceptionType: json['exceptionType'] as String?,
      packageName: json['packageName'] as String?,
      profileId: json['profileId'] as String?,
      processName: json['processName'] as String?,
      virtualUserId: _asInt(json['virtualUserId']),
      thread: json['thread'] as String?,
      buildType: json['buildType'] as String?,
      appVersion: json['appVersion'] as String?,
      deviceInfo: json['deviceInfo'] as String?,
      metadata: rawMetadata is Map
          ? rawMetadata.map(
              (Object? key, Object? value) => MapEntry<String, String>('$key', '$value'),
            )
          : const <String, String>{},
    );
  }

  /// Unique within a run and stable once written, so the UI can key list items and
  /// "related events" lookups on it.
  final String id;
  final DateTime timestamp;

  /// Monotonic within one process. Two events can share a millisecond; the console
  /// still has to show them in the order they happened.
  final int sequence;

  final DiagLevel level;
  final DiagnosticSource source;
  final DiagnosticCategory category;

  /// Correlation id. Every event emitted while one user-visible operation is running
  /// carries the same value, which is what makes the timeline view possible.
  final String? operation;

  /// Human-readable name of that operation, e.g. `launch org.videolan.vlc`.
  final String? operationName;

  final String message;
  final String? details;
  final String? stackTrace;
  final String? exceptionType;
  final String? packageName;
  final String? profileId;
  final String? processName;
  final int? virtualUserId;
  final String? thread;
  final String? buildType;
  final String? appVersion;
  final String? deviceInfo;
  final Map<String, String> metadata;

  bool get isProblem => level.severity >= DiagLevel.warning.severity;

  bool get isFailure => level.severity >= DiagLevel.error.severity;

  /// Null entries are dropped rather than written as `null`, which keeps the stored
  /// line small — the persistent log is size-bounded, so every absent field is
  /// budget for another event.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'sequence': sequence,
        'level': level.wire,
        'source': source.wire,
        'category': category.wire,
        'message': message,
        if (operation != null) 'operation': operation,
        if (operationName != null) 'operationName': operationName,
        if (details != null) 'details': details,
        if (stackTrace != null) 'stackTrace': stackTrace,
        if (exceptionType != null) 'exceptionType': exceptionType,
        if (packageName != null) 'packageName': packageName,
        if (profileId != null) 'profileId': profileId,
        if (processName != null) 'processName': processName,
        if (virtualUserId != null) 'virtualUserId': virtualUserId,
        if (thread != null) 'thread': thread,
        if (buildType != null) 'buildType': buildType,
        if (appVersion != null) 'appVersion': appVersion,
        if (deviceInfo != null) 'deviceInfo': deviceInfo,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  String toJsonLine() => jsonEncode(toJson());

  /// One line per event, for the human-readable export and for `logcat`-style reading.
  String toLogLine() {
    final StringBuffer buffer = StringBuffer()
      ..write(formatTimestamp(timestamp))
      ..write(' [')
      ..write(level.wire.padRight(7))
      ..write('] ')
      ..write(source.wire)
      ..write('/')
      ..write(category.wire);
    if (operation != null) {
      buffer.write(' op=$operation');
    }
    if (packageName != null) {
      buffer.write(' pkg=$packageName');
    }
    if (profileId != null) {
      buffer.write(' profile=$profileId');
    }
    if (virtualUserId != null) {
      buffer.write(' vuser=$virtualUserId');
    }
    buffer.write(' — $message');
    if (details != null && details!.isNotEmpty) {
      buffer.write('\n    details: ${details!.replaceAll('\n', '\n    ')}');
    }
    if (exceptionType != null) {
      buffer.write('\n    exception: $exceptionType');
    }
    if (stackTrace != null && stackTrace!.isNotEmpty) {
      buffer.write('\n    stack:\n      ${stackTrace!.trim().replaceAll('\n', '\n      ')}');
    }
    return buffer.toString();
  }

  /// `HH:mm:ss.mmm`, which is what the console shows. Dates are deliberately absent
  /// from the list rows: every row would carry the same date and the useful digits
  /// would be pushed off a phone screen.
  static String formatTimestamp(DateTime value) =>
      '${_two(value.hour)}:${_two(value.minute)}:${_two(value.second)}'
      '.${value.millisecond.toString().padLeft(3, '0')}';

  static String formatFullTimestamp(DateTime value) =>
      '${value.year}-${_two(value.month)}-${_two(value.day)} '
      '${formatTimestamp(value)}';

  static String _two(int value) => value.toString().padLeft(2, '0');

  static int? _asInt(Object? value) => switch (value) {
        final int value => value,
        final String value => int.tryParse(value),
        final num value => value.toInt(),
        _ => null,
      };

  @override
  bool operator ==(Object other) =>
      other is DiagnosticEvent && other.id == id && other.sequence == sequence;

  @override
  int get hashCode => Object.hash(id, sequence);
}
