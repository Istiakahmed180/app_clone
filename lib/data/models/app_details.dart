import 'package:flutter/foundation.dart';

/// Everything Duplika can say about one installed package's archive.
///
/// Read from the package manager and the archives' own zip directories, on request for
/// one app — not for every row in the picker, where hashing a certificate and opening
/// four APKs per app would be indefensible.
@immutable
class AppDetails {
  const AppDetails({
    required this.packageName,
    required this.appName,
    required this.abis,
    required this.apkCount,
    required this.totalSizeBytes,
    required this.components,
    this.versionName,
    this.versionCode,
    this.signingSha256,
  });

  factory AppDetails.fromMap(Map<String, dynamic> map) => AppDetails(
    packageName: map['packageName'] as String? ?? '',
    appName: map['appName'] as String? ?? '',
    versionName: map['versionName'] as String?,
    versionCode: (map['versionCode'] as num?)?.toInt(),
    abis: List<String>.unmodifiable(
      (map['abis'] as List<Object?>? ?? const <Object?>[]).whereType<String>(),
    ),
    apkCount: map['apkCount'] as int? ?? 0,
    totalSizeBytes: (map['totalSizeBytes'] as num?)?.toInt() ?? 0,
    signingSha256: map['signingSha256'] as String?,
    components: List<ApkComponent>.unmodifiable(
      (map['components'] as List<Object?>? ?? const <Object?>[])
          .whereType<Map<Object?, Object?>>()
          .map(
            (Map<Object?, Object?> raw) =>
                ApkComponent.fromMap(raw.cast<String, dynamic>()),
          ),
    ),
  );

  final String packageName;
  final String appName;
  final String? versionName;
  final int? versionCode;
  final List<String> abis;
  final int apkCount;
  final int totalSizeBytes;

  /// Colon-grouped SHA-256 of the signing certificate, or null when it could not be
  /// read. Several signers are separated by newlines.
  final String? signingSha256;

  final List<ApkComponent> components;

  bool get supports64Bit =>
      abis.contains('arm64-v8a') || abis.contains('x86_64');
  bool get supports32Bit =>
      abis.contains('armeabi-v7a') || abis.contains('x86');
  bool get hasNativeCode => abis.isNotEmpty;
  bool get isSplit => apkCount > 1;

  /// The ABIs under the names people use for them, widest first.
  ///
  /// Empty in, empty out: an app with no native code is a sentence rather than a list,
  /// and only a widget can say that sentence in the user's language.
  static String abiLabel(List<String> abis) {
    final List<String> names = <String>[
      for (final String abi in _abiOrder)
        if (abis.contains(abi)) _abiLabels[abi]!,
    ];
    return names.isEmpty ? abis.join(' + ') : names.join(' + ');
  }

  static const List<String> _abiOrder = <String>[
    'arm64-v8a',
    'armeabi-v7a',
    'x86_64',
    'x86',
  ];

  static const Map<String, String> _abiLabels = <String, String>{
    'arm64-v8a': 'ARM64',
    'armeabi-v7a': 'ARMv7',
    'x86_64': 'x86_64',
    'x86': 'x86',
  };

  /// Rounded to whole units above a kilobyte: nobody reading an APK size needs the
  /// third significant figure, and `25 MB` is easier to compare than `25.31 MB`.
  ///
  /// Callers word the zero case themselves; see `totalSizeLabel`.
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).round()} kB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).round()} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// One APK file in a package: the base, or one split.
@immutable
class ApkComponent {
  const ApkComponent({
    required this.name,
    required this.path,
    required this.isBase,
    required this.abis,
    required this.sizeBytes,
    this.splitName,
  });

  factory ApkComponent.fromMap(Map<String, dynamic> map) => ApkComponent(
    name: map['name'] as String? ?? '',
    path: map['path'] as String? ?? '',
    isBase: map['isBase'] as bool? ?? false,
    splitName: map['splitName'] as String?,
    abis: List<String>.unmodifiable(
      (map['abis'] as List<Object?>? ?? const <Object?>[]).whereType<String>(),
    ),
    sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
  );

  final String name;
  final String path;
  final bool isBase;

  /// The installer's name for this split, e.g. `config.arm64_v8a`. Null for the base.
  final String? splitName;

  final List<String> abis;
  final int sizeBytes;
}
