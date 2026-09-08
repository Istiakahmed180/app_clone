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
    this.abis = const <String>[],
    this.apkCount = 1,
    this.installedAt,
    this.updatedAt,
    this.icon,
  });

  factory InstalledAppModel.fromMap(Map<String, dynamic> map) {
    final String? encodedIcon = map['icon'] as String?;
    return InstalledAppModel(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      versionName: map['versionName'] as String?,
      isSystem: map['system'] as bool? ?? false,
      abis: List<String>.unmodifiable(
        (map['abis'] as List<Object?>? ?? const <Object?>[])
            .whereType<String>(),
      ),
      apkCount: map['apkCount'] as int? ?? 1,
      installedAt: _time(map['firstInstallTime']),
      updatedAt: _time(map['lastUpdateTime']),
      icon: encodedIcon == null ? null : base64Decode(encodedIcon),
    );
  }

  static DateTime? _time(Object? millis) => millis is int && millis > 0
      ? DateTime.fromMillisecondsSinceEpoch(millis)
      : null;

  final String packageName;
  final String appName;
  final String? versionName;
  final bool isSystem;

  /// The ABI directories the package ships native code for, e.g. `arm64-v8a`.
  ///
  /// Empty means pure bytecode, which runs anywhere — not "unknown".
  final List<String> abis;

  /// Base APK plus splits. 1 is a plain single-APK install.
  final int apkCount;

  final DateTime? installedAt;
  final DateTime? updatedAt;
  final Uint8List? icon;

  bool get hasNativeCode => abis.isNotEmpty;
  bool get isSplit => apkCount > 1;

  bool get supports64Bit =>
      abis.contains('arm64-v8a') || abis.contains('x86_64');
  bool get supports32Bit =>
      abis.contains('armeabi-v7a') || abis.contains('x86');

  /// The ABIs in the order a reader expects them, under their common names.
  ///
  /// `arm64-v8a` is the name in the archive; nobody calls it that out loud.
  List<String> get abiNames => <String>[
    for (final String abi in const <String>[
      'arm64-v8a',
      'armeabi-v7a',
      'x86_64',
      'x86',
    ])
      if (abis.contains(abi)) _abiLabels[abi]!,
  ];

  static const Map<String, String> _abiLabels = <String, String>{
    'arm64-v8a': 'ARM64',
    'armeabi-v7a': 'ARMv7',
    'x86_64': 'x86_64',
    'x86': 'x86',
  };

  /// What the picker's first chip says, e.g. `ARM64 + ARMv7 · 32 + 64`.
  String get architectureLabel {
    if (abis.isEmpty) {
      return 'No native code';
    }
    final String bits = switch ((supports32Bit, supports64Bit)) {
      (true, true) => '32 + 64',
      (false, true) => '64-bit',
      (true, false) => '32-bit',
      (false, false) => '',
    };
    final String names = abiNames.join(' + ');
    return bits.isEmpty ? names : '$names · $bits';
  }

  /// What the picker's second chip says.
  String get packageTypeLabel =>
      isSplit ? 'Split APK · $apkCount files' : 'Single APK';
}

/// Identity read from a standalone APK the user picked, before it is installed.
@immutable
class ApkCandidate {
  const ApkCandidate({
    required this.apkPaths,
    required this.packageName,
    required this.appName,
    required this.installedOnHost,
    this.versionName,
    this.versionCode,
  });

  factory ApkCandidate.fromMap(
    List<String> apkPaths,
    Map<String, dynamic> map,
  ) {
    return ApkCandidate(
      apkPaths: List<String>.unmodifiable(apkPaths),
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      installedOnHost: map['installedOnHost'] as bool? ?? false,
      versionName: map['versionName'] as String?,
      versionCode: map['versionCode'] as String?,
    );
  }

  final List<String> apkPaths;
  String get apkPath => apkPaths.first;
  final String packageName;
  final String appName;
  final bool installedOnHost;
  final String? versionName;
  final String? versionCode;
}
