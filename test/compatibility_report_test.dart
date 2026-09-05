import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_space_demo/data/models/compatibility_report.dart';

void main() {
  Map<String, dynamic> report({
    String verdict = 'SUPPORTED',
    List<Map<String, Object?>> findings = const <Map<String, Object?>>[],
    List<String> bridgeable = const <String>[],
    List<String> missing = const <String>[],
    bool gms = false,
  }) =>
      <String, dynamic>{
        'packageName': 'org.example.app',
        'verdict': verdict,
        'findings': findings,
        'bridgeablePermissions': bridgeable,
        'missingPermissions': missing,
        'requiresGms': gms,
        'abi': 'arm64-v8a',
      };

  group('verdict parsing', () {
    test('reads the three known verdicts', () {
      expect(CompatibilityVerdict.parse('SUPPORTED'), CompatibilityVerdict.supported);
      expect(CompatibilityVerdict.parse('LIMITED'), CompatibilityVerdict.limited);
      expect(CompatibilityVerdict.parse('UNSUPPORTED'), CompatibilityVerdict.unsupported);
    });

    test('treats anything unrecognised as unsupported rather than assuming success', () {
      expect(CompatibilityVerdict.parse(null), CompatibilityVerdict.unsupported);
      expect(CompatibilityVerdict.parse('WHATEVER'), CompatibilityVerdict.unsupported);
    });
  });

  group('report', () {
    test('a supported app can be cloned and needs nothing', () {
      final CompatibilityReport parsed = CompatibilityReport.fromMap(report());

      expect(parsed.canClone, isTrue);
      expect(parsed.needsPermissions, isFalse);
      expect(parsed.blocker, isNull);
      expect(parsed.abi, 'arm64-v8a');
    });

    test('a limited app can still be cloned', () {
      final CompatibilityReport parsed = CompatibilityReport.fromMap(report(
        verdict: 'LIMITED',
        gms: true,
        findings: <Map<String, Object?>>[
          <String, Object?>{
            'code': 'REQUIRES_GMS',
            'message': 'Needs Play Services.',
            'blocking': false,
          },
        ],
      ));

      expect(parsed.canClone, isTrue);
      expect(parsed.requiresGms, isTrue);
      expect(parsed.blocker, isNull);
    });

    test('an unsupported app cannot be cloned and exposes the blocking reason', () {
      final CompatibilityReport parsed = CompatibilityReport.fromMap(report(
        verdict: 'UNSUPPORTED',
        findings: <Map<String, Object?>>[
          <String, Object?>{
            'code': 'ABI_NOT_SUPPORTED',
            'message': 'Wrong architecture.',
            'blocking': true,
          },
        ],
      ));

      expect(parsed.canClone, isFalse);
      expect(parsed.blocker?.code, 'ABI_NOT_SUPPORTED');
    });

    test('reports outstanding permissions', () {
      final CompatibilityReport parsed = CompatibilityReport.fromMap(report(
        verdict: 'LIMITED',
        bridgeable: <String>['android.permission.CAMERA', 'android.permission.RECORD_AUDIO'],
        missing: <String>['android.permission.CAMERA'],
      ));

      expect(parsed.needsPermissions, isTrue);
      expect(parsed.missingPermissions, <String>['android.permission.CAMERA']);
    });

    test('survives a malformed payload without throwing', () {
      final CompatibilityReport parsed =
          CompatibilityReport.fromMap(<String, dynamic>{'findings': 'not-a-list'});

      expect(parsed.verdict, CompatibilityVerdict.unsupported);
      expect(parsed.findings, isEmpty);
      expect(parsed.bridgeablePermissions, isEmpty);
    });
  });

  group('permission request result', () {
    test('is complete only when nothing is still missing', () {
      expect(
        PermissionRequestResult.fromMap(<String, dynamic>{
          'granted': <String>['android.permission.CAMERA'],
          'stillMissing': <String>[],
        }).allGranted,
        isTrue,
      );

      final PermissionRequestResult partial =
          PermissionRequestResult.fromMap(<String, dynamic>{
        'granted': <String>['android.permission.CAMERA'],
        'stillMissing': <String>['android.permission.RECORD_AUDIO'],
      });
      expect(partial.allGranted, isFalse);
      expect(partial.granted, hasLength(1));
    });
  });
}
