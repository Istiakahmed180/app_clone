import 'package:flutter/foundation.dart';

/// How well an application is expected to work inside a container.
enum CompatibilityVerdict {
  /// Nothing known to stand in the way.
  supported,

  /// Runnable, but something will not work fully — see the findings.
  limited,

  /// Cannot be cloned at all.
  unsupported;

  static CompatibilityVerdict parse(String? raw) => switch (raw) {
        'SUPPORTED' => CompatibilityVerdict.supported,
        'LIMITED' => CompatibilityVerdict.limited,
        _ => CompatibilityVerdict.unsupported,
      };
}

/// One concrete reason an app is not fully supported.
@immutable
class CompatibilityFinding {
  const CompatibilityFinding({
    required this.code,
    required this.message,
    required this.blocking,
  });

  factory CompatibilityFinding.fromMap(Map<String, dynamic> map) {
    return CompatibilityFinding(
      code: map['code'] as String? ?? 'UNKNOWN',
      message: map['message'] as String? ?? '',
      blocking: map['blocking'] as bool? ?? false,
    );
  }

  final String code;
  final String message;

  /// A blocking finding makes the app [CompatibilityVerdict.unsupported].
  final bool blocking;
}

/// The compatibility layer's verdict for one application.
@immutable
class CompatibilityReport {
  const CompatibilityReport({
    required this.packageName,
    required this.verdict,
    required this.findings,
    required this.bridgeablePermissions,
    required this.missingPermissions,
    required this.requiresGms,
    this.abi,
  });

  factory CompatibilityReport.fromMap(Map<String, dynamic> map) {
    // The payload crosses a platform channel, so every field is treated as untrusted
    // shape rather than cast directly.
    final Object? rawFindings = map['findings'];
    return CompatibilityReport(
      packageName: map['packageName'] as String? ?? '',
      verdict: CompatibilityVerdict.parse(map['verdict'] as String?),
      findings: rawFindings is! List
          ? const <CompatibilityFinding>[]
          : rawFindings
              .whereType<Map<Object?, Object?>>()
              .map((Map<Object?, Object?> f) => CompatibilityFinding.fromMap(
                    f.map((Object? k, Object? v) => MapEntry<String, dynamic>('$k', v)),
                  ))
              .toList(growable: false),
      bridgeablePermissions: _strings(map['bridgeablePermissions']),
      missingPermissions: _strings(map['missingPermissions']),
      requiresGms: map['requiresGms'] as bool? ?? false,
      abi: map['abi'] as String?,
    );
  }

  static const CompatibilityReport unknown = CompatibilityReport(
    packageName: '',
    verdict: CompatibilityVerdict.supported,
    findings: <CompatibilityFinding>[],
    bridgeablePermissions: <String>[],
    missingPermissions: <String>[],
    requiresGms: false,
  );

  static List<String> _strings(Object? raw) => raw is List
      ? raw.map((Object? e) => '$e').toList(growable: false)
      : const <String>[];

  final String packageName;
  final CompatibilityVerdict verdict;
  final List<CompatibilityFinding> findings;

  /// Dangerous permissions the guest declares that the host is able to hold.
  final List<String> bridgeablePermissions;

  /// Of those, the ones the host has not been granted yet.
  final List<String> missingPermissions;

  final bool requiresGms;
  final String? abi;

  bool get canClone => verdict != CompatibilityVerdict.unsupported;

  bool get needsPermissions => missingPermissions.isNotEmpty;

  /// The first blocking reason, which is what stops the app being cloned.
  CompatibilityFinding? get blocker =>
      findings.where((CompatibilityFinding f) => f.blocking).firstOrNull;
}

/// Outcome of asking the user for the permissions a guest needs.
@immutable
class PermissionRequestResult {
  const PermissionRequestResult({required this.granted, required this.stillMissing});

  factory PermissionRequestResult.fromMap(Map<String, dynamic> map) {
    return PermissionRequestResult(
      granted: CompatibilityReport._strings(map['granted']),
      stillMissing: CompatibilityReport._strings(map['stillMissing']),
    );
  }

  final List<String> granted;
  final List<String> stillMissing;

  bool get allGranted => stillMissing.isEmpty;
}
