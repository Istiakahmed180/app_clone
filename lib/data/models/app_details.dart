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

  /// `1.0.7 (8)`, or just one half when the other is missing.
  String get versionLabel {
    if (versionName == null && versionCode == null) {
      return 'unknown';
    }
    if (versionCode == null) {
      return versionName!;
    }
    if (versionName == null) {
      return '($versionCode)';
    }
    return '$versionName ($versionCode)';
  }

  /// `ARM64 · 64-bit`, the same string the picker's chip shows.
  ///
  /// Repeats the bitness that has its own row below. Deliberate: the chip in the list
  /// reads this way, and a details screen that named the ABIs differently from the row
  /// the user tapped would look like a different app's numbers.
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
    final String names = abiLabel(abis);
    return bits.isEmpty ? names : '$names · $bits';
  }

  /// `64-bit`, `32-bit`, `32 + 64`, or the honest answer for pure bytecode.
  String get bitnessLabel => switch ((supports32Bit, supports64Bit)) {
    (true, true) => '32 + 64',
    (false, true) => '64-bit',
    (true, false) => '32-bit',
    (false, false) => 'Any — no native code',
  };

  String get packageTypeLabel =>
      isSplit ? 'Split APK · $apkCount files' : 'Single APK';

  String get totalSizeLabel => formatBytes(totalSizeBytes);

  /// The ABIs under the names people use for them, widest first.
  static String abiLabel(List<String> abis) {
    if (abis.isEmpty) {
      return 'No native code';
    }
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
  static String formatBytes(int bytes) {
    if (bytes <= 0) {
      return 'unknown';
    }
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

  /// `Base APK · No native libraries · 25 MB`, or
  /// `Split APK · config.arm64_v8a · arm64-v8a · 32 MB`.
  String get summary => <String>[
    isBase ? 'Base APK' : 'Split APK',
    if (splitName != null && splitName!.isNotEmpty) splitName!,
    if (abis.isEmpty) 'No native libraries' else abis.join(', '),
    AppDetails.formatBytes(sizeBytes),
  ].join(' · ');
}
