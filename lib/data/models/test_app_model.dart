import 'package:flutter/foundation.dart';

/// Public package metadata for the controlled test application.
@immutable
class TestAppModel {
  const TestAppModel({
    required this.installed,
    required this.packageName,
    this.appName,
    this.versionName,
    this.versionCode,
  });

  /// Builds a model from the raw platform-channel map, tolerating missing keys
  /// rather than throwing on a partially populated native response.
  factory TestAppModel.fromMap(Map<String, dynamic> map) {
    return TestAppModel(
      installed: map['installed'] as bool? ?? false,
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String?,
      versionName: map['versionName'] as String?,
      versionCode: map['versionCode'] as String?,
    );
  }

  const TestAppModel.notInstalled(this.packageName)
      : installed = false,
        appName = null,
        versionName = null,
        versionCode = null;

  final bool installed;
  final String packageName;
  final String? appName;
  final String? versionName;
  final String? versionCode;

  String get displayName => appName ?? packageName;
}
