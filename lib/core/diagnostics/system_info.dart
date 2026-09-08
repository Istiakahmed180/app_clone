import 'dart:io';

import 'package:flutter/foundation.dart';

import 'diagnostic_logger.dart';

/// One entry in the System Information screen.
@immutable
class SystemInfoField {
  const SystemInfoField(this.label, this.value);

  final String label;

  /// Never null. A value the platform could not answer reads as `unavailable` rather
  /// than being omitted: an absent row and a row the system refused to fill in mean
  /// very different things when reading a report.
  final String value;
}

/// One labelled block of the System Information screen.
@immutable
class SystemInfoSection {
  const SystemInfoSection(this.title, this.fields);

  final String title;
  final List<SystemInfoField> fields;
}

/// Everything worth knowing about the environment a report was captured in.
///
/// Deliberately limited to device and build facts. No account identifiers, no
/// advertising id, no hardware serial: a diagnostics report gets shared, and none of
/// that would help read it.
@immutable
class SystemInfoSnapshot {
  const SystemInfoSnapshot({
    required this.capturedAt,
    required this.native,
    required this.buildType,
    required this.dartVersion,
    required this.operatingSystem,
  });

  /// Builds a snapshot from the native payload, filling in what only Dart knows.
  factory SystemInfoSnapshot.from(Map<String, dynamic> native) => SystemInfoSnapshot(
        capturedAt: DateTime.now(),
        native: native,
        buildType: DiagnosticLogger.buildType,
        dartVersion: Platform.version,
        operatingSystem: '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      );

  /// A snapshot with nothing from the platform, used when the channel is unavailable.
  factory SystemInfoSnapshot.unavailable(String reason) => SystemInfoSnapshot(
        capturedAt: DateTime.now(),
        native: <String, dynamic>{'unavailableReason': reason},
        buildType: DiagnosticLogger.buildType,
        dartVersion: Platform.version,
        operatingSystem: Platform.operatingSystem,
      );

  final DateTime capturedAt;

  /// The raw map from the Kotlin side, kept verbatim so the export carries fields this
  /// Dart code does not yet know how to display.
  final Map<String, dynamic> native;

  final String buildType;
  final String dartVersion;
  final String operatingSystem;

  String? get appVersion => _string('appVersion');

  String get engineStatus => _string('engineStatus') ?? 'unknown';

  String get deviceSummary {
    final String? model = _string('model');
    final String? release = _string('androidVersion');
    final Object? sdk = native['sdkInt'];
    if (model == null) {
      return operatingSystem;
    }
    return '$model · Android ${release ?? '?'} (API ${sdk ?? '?'})';
  }

  /// Rendered by the System Information screen and by the text export, so the two can
  /// never drift apart.
  List<SystemInfoSection> sections() => <SystemInfoSection>[
        SystemInfoSection('Application', <SystemInfoField>[
          SystemInfoField('Package', _text('applicationId')),
          SystemInfoField('Version', _text('appVersion')),
          SystemInfoField('Version code', _text('appVersionCode')),
          SystemInfoField('Flutter build type', buildType),
          SystemInfoField('Native build type', _text('nativeBuildType')),
          SystemInfoField('Process', _text('processName')),
          SystemInfoField('Process id', _text('pid')),
          SystemInfoField('UID', _text('uid')),
        ]),
        SystemInfoSection('Device', <SystemInfoField>[
          SystemInfoField('Manufacturer', _text('manufacturer')),
          SystemInfoField('Model', _text('model')),
          SystemInfoField('Device', _text('device')),
          SystemInfoField('Android', _text('androidVersion')),
          SystemInfoField('API level', _text('sdkInt')),
          SystemInfoField('Supported ABIs', _text('supportedAbis')),
          SystemInfoField('Primary ABI', _text('primaryAbi')),
        ]),
        SystemInfoSection('Runtime', <SystemInfoField>[
          SystemInfoField('Dart', dartVersion),
          // The Flutter SDK version is not exposed to a running app. Saying so is more
          // useful than printing the framework's channel name and calling it a version.
          SystemInfoField(
            'Flutter framework',
            'not reported at runtime (see build metadata)',
          ),
          SystemInfoField('Host OS', operatingSystem),
        ]),
        SystemInfoSection('Virtualization engine', <SystemInfoField>[
          SystemInfoField('Status', _text('engineStatus')),
          SystemInfoField('Backend', _text('engineBackend')),
          SystemInfoField('Detail', _text('engineDetail')),
          SystemInfoField('Bcore attached', _text('bcoreAttached')),
          SystemInfoField('Virtual users', _text('virtualUserIds')),
        ]),
        SystemInfoSection('Storage', <SystemInfoField>[
          SystemInfoField('Internal free', _text('internalFreeBytes')),
          SystemInfoField('Internal total', _text('internalTotalBytes')),
          SystemInfoField('External storage state', _text('externalStorageState')),
          SystemInfoField('All-files access', _text('isExternalStorageManager')),
        ]),
        SystemInfoSection('Diagnostics', <SystemInfoField>[
          SystemInfoField('Captured at', capturedAt.toIso8601String()),
          SystemInfoField('Native events retained', _text('nativeEventCount')),
          SystemInfoField('Native log bytes', _text('nativeLogBytes')),
          SystemInfoField('Native processes seen', _text('nativeProcesses')),
        ]),
      ];

  Map<String, dynamic> toJson() => <String, dynamic>{
        'capturedAt': capturedAt.toUtc().toIso8601String(),
        'flutterBuildType': buildType,
        'dartVersion': dartVersion,
        'hostOs': operatingSystem,
        'native': native,
      };

  String toReportText() {
    final StringBuffer buffer = StringBuffer();
    for (final SystemInfoSection section in sections()) {
      buffer
        ..writeln(section.title.toUpperCase())
        ..writeln('-' * section.title.length);
      for (final SystemInfoField field in section.fields) {
        buffer.writeln('  ${field.label.padRight(26)}${field.value}');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  String? _string(String key) {
    final Object? value = native[key];
    return value == null ? null : '$value';
  }

  String _text(String key) {
    final Object? value = native[key];
    if (value == null) {
      return 'unavailable';
    }
    if (value is List) {
      return value.join(', ');
    }
    return '$value';
  }
}
