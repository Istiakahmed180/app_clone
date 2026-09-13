import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../data/models/app_details.dart';
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

  String? get appVersionCode => _string('appVersionCode');

  /// Every ABI this device can run, most preferred first. Empty when the platform did
  /// not answer, which is not the same as a device that supports nothing.
  List<String> get supportedAbis {
    final Object? value = native['supportedAbis'];
    return value is List
        ? value.map((Object? abi) => '$abi').toList(growable: false)
        : const <String>[];
  }

  /// The ABI the device actually runs code as. Drives what a guest app can be, so it is
  /// reported to the user and not only to a diagnostics export.
  String? get primaryAbi => _string('primaryAbi') ?? supportedAbis.firstOrNull;

  /// Whether [primaryAbi] is a 64-bit one. `null` when there is no ABI to judge.
  bool? get is64Bit {
    final String? abi = primaryAbi;
    if (abi == null) {
      return null;
    }
    return abi.contains('64');
  }

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
        SystemInfoSection('Memory', <SystemInfoField>[
          SystemInfoField('Total RAM', _bytes('totalMemBytes')),
          SystemInfoField('Available RAM', _bytes('availMemBytes')),
          // Android's own line for "start killing things", not one Duplika picked.
          SystemInfoField('Low-memory threshold', _bytes('memoryThresholdBytes')),
          SystemInfoField('Under memory pressure', _text('underMemoryPressure')),
          SystemInfoField('Low-RAM device', _text('isLowRamDevice')),
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
          // Labelled 'Host' because they are Android's numbers, not the engine's: the
          // containers above are not Android users and this cap does not bound them.
          SystemInfoField(
            'Host multi-user support',
            _text('hostSupportsMultipleUsers'),
          ),
          SystemInfoField('Host max Android users', _text('hostMaxAndroidUsers')),
        ]),
        SystemInfoSection('Storage', <SystemInfoField>[
          SystemInfoField('Internal free', _bytes('internalFreeBytes')),
          SystemInfoField('Internal total', _bytes('internalTotalBytes')),
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

  /// `7.6 GB (8127352832 bytes)`, or plain `0 bytes` when there is nothing to round.
  ///
  /// Both halves earn their place above a kilobyte: the round number is the one a person
  /// reads, and the exact one is what makes two reports comparable. Below that they would
  /// be the same number printed twice, so only one is given.
  ///
  /// Zero is a measurement, not a gap — a full volume really does read zero, and that is
  /// the reading a storage report exists to show. Only a negative is treated as no answer.
  String _bytes(String key) {
    final Object? value = native[key];
    if (value is! num || value < 0) {
      return 'unavailable';
    }
    final int bytes = value.toInt();
    if (bytes < 1024) {
      return '$bytes bytes';
    }
    return '${AppDetails.formatBytes(bytes)} ($bytes bytes)';
  }

  String _text(String key) {
    final Object? value = native[key];
    if (value == null) {
      return 'unavailable';
    }
    if (value is List) {
      // An empty row reads as a field that failed to render. 'none' is the finding:
      // the engine holds no virtual users, the device declares no ABIs.
      return value.isEmpty ? 'none' : value.join(', ');
    }
    return '$value';
  }
}
