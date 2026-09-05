import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_space_demo/core/errors/app_exception.dart';
import 'package:virtual_space_demo/data/models/compatibility_report.dart';
import 'package:virtual_space_demo/data/models/test_app_model.dart';
import 'package:virtual_space_demo/native/native_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(NativeBridge.channelName);
  final NativeBridge bridge = NativeBridge(channel: channel);
  late Map<String, Object?> responses;

  setUp(() {
    responses = <String, Object?>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      if (!responses.containsKey(call.method)) {
        throw PlatformException(code: 'UNAVAILABLE');
      }
      return responses[call.method];
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getTestAppInfo returns a model when installed', () async {
    responses['getTestAppInfo'] = <Object?, Object?>{
      'installed': true,
      'packageName': 'com.example.virtualtestapp',
      'appName': 'Virtual Test App',
      'versionName': '1.0.0',
      'versionCode': '1',
    };

    final TestAppModel? model = await bridge.getTestAppInfo();

    expect(model?.appName, 'Virtual Test App');
  });

  test('getTestAppInfo returns null when not installed', () async {
    responses['getTestAppInfo'] = <Object?, Object?>{
      'installed': false,
      'packageName': 'com.example.virtualtestapp',
    };

    expect(await bridge.getTestAppInfo(), isNull);
  });

  test('launchTestApp reports success', () async {
    responses['launchTestApp'] = <Object?, Object?>{'success': true};

    expect(await bridge.launchTestApp(), isTrue);
  });

  test('launchTestApp throws a typed error when the app is missing', () async {
    responses['launchTestApp'] = <Object?, Object?>{
      'success': false,
      'error': 'TEST_APP_NOT_INSTALLED',
    };

    expect(
      bridge.launchTestApp(),
      throwsA(isA<LaunchException>()
          .having((LaunchException e) => e.code, 'code', 'TEST_APP_NOT_INSTALLED')),
    );
  });

  group('compatibility analysis', () {
    test('a successful analysis is parsed', () async {
      responses['analyzeApp'] = <Object?, Object?>{
        'success': true,
        'code': 'APP_ANALYZED',
        'message': 'ok',
        'data': <Object?, Object?>{
          'packageName': 'org.example',
          'verdict': 'LIMITED',
          'findings': <Object?>[],
          'bridgeablePermissions': <Object?>[],
          'missingPermissions': <Object?>[],
          'requiresGms': true,
        },
      };

      final CompatibilityReport report = await bridge.analyzeApp('org.example');

      expect(report.verdict, CompatibilityVerdict.limited);
      expect(report.requiresGms, isTrue);
      expect(report.analysed, isTrue);
    });

    test('a failed analysis is reported as not analysed, not as unsupported', () async {
      // A bridge failure means nothing is known. Turning that into "unsupported" would
      // block the user with no reason shown, since there are no findings to explain it.
      responses['analyzeApp'] = <Object?, Object?>{
        'success': false,
        'code': 'BRIDGE_ERROR',
        'message': 'Native call failed.',
        'data': <Object?, Object?>{},
      };

      final CompatibilityReport report = await bridge.analyzeApp('org.example');

      expect(report.analysed, isFalse);
      expect(report.findings, isEmpty);
    });

    test('a failed APK analysis is reported as not analysed', () async {
      responses['analyzeApk'] = <Object?, Object?>{
        'success': false,
        'code': 'BRIDGE_ERROR',
        'message': 'Native call failed.',
        'data': <Object?, Object?>{},
      };

      final CompatibilityReport report =
          await bridge.analyzeApk('/tmp/x.apk', 'org.example');

      expect(report.analysed, isFalse);
    });
  });

  test('a platform failure becomes a NativeBridgeException', () {
    expect(bridge.getPlatformInfo(), throwsA(isA<NativeBridgeException>()));
  });
}
