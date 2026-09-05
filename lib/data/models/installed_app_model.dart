import 'dart:convert';

import 'package:flutter/foundation.dart';

/// A launchable application on the device, as offered in the clone picker.
@immutable
class InstalledAppModel {
  const InstalledAppModel({
    required this.packageName,
    required this.appName,
    this.versionName,
    this.isSystem = false,
    this.icon,
  });

  factory InstalledAppModel.fromMap(Map<String, dynamic> map) {
    final String? encodedIcon = map['icon'] as String?;
    return InstalledAppModel(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      versionName: map['versionName'] as String?,
      isSystem: map['system'] as bool? ?? false,
      icon: encodedIcon == null ? null : base64Decode(encodedIcon),
    );
  }

  final String packageName;
  final String appName;
  final String? versionName;
  final bool isSystem;
  final Uint8List? icon;
}

/// Identity read from a standalone APK the user picked, before it is installed.
@immutable
class ApkCandidate {
  const ApkCandidate({
    required this.apkPath,
    required this.packageName,
    required this.appName,
    required this.installedOnHost,
    this.versionName,
    this.versionCode,
  });

  factory ApkCandidate.fromMap(String apkPath, Map<String, dynamic> map) {
    return ApkCandidate(
      apkPath: apkPath,
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      installedOnHost: map['installedOnHost'] as bool? ?? false,
      versionName: map['versionName'] as String?,
      versionCode: map['versionCode'] as String?,
    );
  }

  final String apkPath;
  final String packageName;
  final String appName;
  final bool installedOnHost;
  final String? versionName;
  final String? versionCode;
}
