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
    required this.requiresGms,
    this.abi,
    this.analysed = true,
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
      requiresGms: map['requiresGms'] as bool? ?? false,
      abi: map['abi'] as String?,
    );
  }

  /// Used when analysis could not run at all.
  ///
  /// Deliberately not [CompatibilityVerdict.supported]: an app nobody examined must never
  /// be presented as problem-free.
  static const CompatibilityReport unknown = CompatibilityReport(
    packageName: '',
    verdict: CompatibilityVerdict.limited,
    findings: <CompatibilityFinding>[],
    requiresGms: false,
    analysed: false,
  );

  final String packageName;
  final CompatibilityVerdict verdict;
  final List<CompatibilityFinding> findings;

  final bool requiresGms;
  final String? abi;

  /// False when the compatibility layer could not inspect this app at all.
  final bool analysed;

  bool get canClone => verdict != CompatibilityVerdict.unsupported;

  /// The first blocking reason, which is what stops the app being cloned.
  CompatibilityFinding? get blocker =>
      findings.where((CompatibilityFinding f) => f.blocking).firstOrNull;
}
