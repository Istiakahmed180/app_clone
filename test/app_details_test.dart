import 'package:duplika/data/models/app_details.dart';
import 'package:flutter_test/flutter_test.dart';

AppDetails _details({
  List<String> abis = const <String>['arm64-v8a'],
  int apkCount = 1,
  int totalSizeBytes = 0,
  String? versionName,
  int? versionCode,
  List<ApkComponent> components = const <ApkComponent>[],
}) => AppDetails(
  packageName: 'com.example',
  appName: 'Example',
  versionName: versionName,
  versionCode: versionCode,
  abis: abis,
  apkCount: apkCount,
  totalSizeBytes: totalSizeBytes,
  components: components,
);

void main() {
  group('AppDetails', () {
    test('states the version as name and code together', () {
      expect(
        _details(versionName: '1.0.7', versionCode: 8).versionLabel,
        '1.0.7 (8)',
      );
      // Half an answer is still an answer; a blank line is not.
      expect(_details(versionName: '1.0.7').versionLabel, '1.0.7');
      expect(_details(versionCode: 8).versionLabel, '(8)');
      expect(_details().versionLabel, 'unknown');
    });

    test('separates architecture from bitness', () {
      // Two different questions: which ABIs are shipped, and whether the app can run
      // 32-bit, 64-bit or both. The picker filters on the second.
      final AppDetails both = _details(
        abis: const <String>['arm64-v8a', 'armeabi-v7a'],
      );
      // The same string the picker chip shows, bitness included, so the two screens
      // never disagree about the app the user just tapped.
      expect(both.architectureLabel, 'ARM64 + ARMv7 · 32 + 64');
      expect(both.bitnessLabel, '32 + 64');

      final AppDetails none = _details(abis: const <String>[]);
      expect(none.architectureLabel, 'No native code');
      expect(
        none.bitnessLabel,
        'Any — no native code',
        reason: 'pure bytecode is not "32-bit" and not unknown',
      );
    });

    test('sizes read in whole units', () {
      expect(AppDetails.formatBytes(0), 'unknown');
      expect(AppDetails.formatBytes(512), '512 B');
      expect(AppDetails.formatBytes(97_000), '95 kB');
      expect(AppDetails.formatBytes(26_214_400), '25 MB');
      expect(AppDetails.formatBytes(2_147_483_648), '2.0 GB');
    });

    test('counts APK components as the package type', () {
      expect(_details().packageTypeLabel, 'Single APK');
      expect(_details(apkCount: 4).packageTypeLabel, 'Split APK · 4 files');
    });
  });

  group('ApkComponent', () {
    test('the base APK says so, and says it carries no libraries', () {
      const ApkComponent base = ApkComponent(
        name: 'base.apk',
        path: '/data/app/~~x/base.apk',
        isBase: true,
        abis: <String>[],
        sizeBytes: 26_214_400,
      );

      expect(base.summary, 'Base APK · No native libraries · 25 MB');
    });

    test('a split names itself and its ABIs', () {
      const ApkComponent split = ApkComponent(
        name: 'split_config.arm64_v8a.apk',
        path: '/data/app/~~x/split_config.arm64_v8a.apk',
        isBase: false,
        splitName: 'config.arm64_v8a',
        abis: <String>['arm64-v8a'],
        sizeBytes: 33_554_432,
      );

      expect(split.summary, 'Split APK · config.arm64_v8a · arm64-v8a · 32 MB');
    });
  });

  group('AppDetails.fromMap', () {
    test('reads the platform payload, components and all', () {
      final AppDetails details = AppDetails.fromMap(<String, dynamic>{
        'packageName': 'com.moneyin.cabex.fx',
        'appName': 'CABEX-FX',
        'versionName': '1.0.7',
        'versionCode': 8,
        'abis': <Object?>['arm64-v8a'],
        'apkCount': 2,
        'totalSizeBytes': 59_768_832,
        'signingSha256': 'AA:0E:88',
        'components': <Object?>[
          <Object?, Object?>{
            'name': 'base.apk',
            'path': '/data/app/base.apk',
            'isBase': true,
            'abis': <Object?>[],
            'sizeBytes': 26_214_400,
          },
          <Object?, Object?>{
            'name': 'split_config.arm64_v8a.apk',
            'path': '/data/app/split.apk',
            'isBase': false,
            'splitName': 'config.arm64_v8a',
            'abis': <Object?>['arm64-v8a'],
            'sizeBytes': 33_554_432,
          },
        ],
      });

      expect(details.appName, 'CABEX-FX');
      expect(details.versionLabel, '1.0.7 (8)');
      expect(details.packageTypeLabel, 'Split APK · 2 files');
      expect(details.totalSizeLabel, '57 MB');
      expect(details.signingSha256, 'AA:0E:88');
      expect(details.components, hasLength(2));
      expect(details.components.first.isBase, isTrue);
      expect(details.components.last.splitName, 'config.arm64_v8a');
    });

    test('a payload missing everything optional still builds', () {
      // The platform can fail to read a certificate or a version; a details screen that
      // threw on that would be worse than one that says it could not read it.
      final AppDetails details = AppDetails.fromMap(<String, dynamic>{});

      expect(details.packageName, isEmpty);
      expect(details.signingSha256, isNull);
      expect(details.versionLabel, 'unknown');
      expect(details.components, isEmpty);
    });
  });
}
