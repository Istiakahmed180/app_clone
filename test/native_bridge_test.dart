import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_space_demo/core/errors/app_exception.dart';
import 'package:virtual_space_demo/data/models/compatibility_report.dart';
import 'package:virtual_space_demo/data/models/installed_app_model.dart';
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

  group('installed app list', () {
    test('a successful listing is parsed', () async {
      responses['listInstalledApps'] = <Object?, Object?>{
        'success': true,
        'code': 'APPS_LISTED',
        'message': 'ok',
        'data': <Object?, Object?>{
          'apps': <Object?>[
            <Object?, Object?>{'packageName': 'org.example', 'appName': 'Example'},
          ],
        },
      };

      final List<InstalledAppModel> apps = await bridge.listInstalledApps();

      expect(apps, hasLength(1));
      expect(apps.single.packageName, 'org.example');
    });

    test('a failed listing raises rather than looking like an empty device', () async {
      // Returning [] would render as "No matching apps", telling the user they have no
      // apps when the truth is that the call failed.
      responses['listInstalledApps'] = <Object?, Object?>{
        'success': false,
        'code': 'BRIDGE_ERROR',
        'message': 'Native call failed.',
        'data': <Object?, Object?>{},
      };

      expect(bridge.listInstalledApps(), throwsA(isA<VirtualizationException>()));
    });

    test('a malformed entry is skipped rather than crashing the listing', () async {
      responses['listInstalledApps'] = <Object?, Object?>{
        'success': true,
        'code': 'APPS_LISTED',
        'message': 'ok',
        'data': <Object?, Object?>{
          'apps': <Object?>[
            'not-a-map',
            <Object?, Object?>{'packageName': 'org.example', 'appName': 'Example'},
          ],
        },
      };

      final List<InstalledAppModel> apps = await bridge.listInstalledApps();

      expect(apps, hasLength(1));
    });
  });

  group('guest permission requests', () {
    test('an answered request reports what was granted and what is still missing', () async {
      responses['requestGuestPermissions'] = <Object?, Object?>{
        'success': true,
        'code': 'PERMISSIONS_REQUESTED',
        'message': 'ok',
        'data': <Object?, Object?>{
          'granted': <Object?>['android.permission.CAMERA'],
          'denied': <Object?>['android.permission.RECORD_AUDIO'],
          'stillMissing': <Object?>['android.permission.RECORD_AUDIO'],
        },
      };

      final PermissionRequestResult result =
          await bridge.requestGuestPermissions('org.example');

      expect(result.granted, <String>['android.permission.CAMERA']);
      expect(result.stillMissing, <String>['android.permission.RECORD_AUDIO']);
      expect(result.allGranted, isFalse);
    });

    test('a fully granted request reports nothing still missing', () async {
      responses['requestGuestPermissions'] = <Object?, Object?>{
        'success': true,
        'code': 'PERMISSIONS_REQUESTED',
        'message': 'ok',
        'data': <Object?, Object?>{
          'granted': <Object?>['android.permission.CAMERA'],
          'denied': <Object?>[],
          'stillMissing': <Object?>[],
        },
      };

      expect((await bridge.requestGuestPermissions('org.example')).allGranted, isTrue);
    });

    test('a request that was never shown raises rather than looking answered', () async {
      // The user decided nothing here; reporting success would claim otherwise.
      responses['requestGuestPermissions'] = <Object?, Object?>{
        'success': false,
        'code': 'PERMISSION_REQUEST_IN_PROGRESS',
        'message': 'Another permission request is already open.',
        'data': <Object?, Object?>{},
      };

      expect(
        bridge.requestGuestPermissions('org.example'),
        throwsA(isA<VirtualizationException>().having(
          (VirtualizationException e) => e.code,
          'code',
          'PERMISSION_REQUEST_IN_PROGRESS',
        )),
      );
    });

    test('an interrupted request raises with its own code', () async {
      responses['requestGuestPermissions'] = <Object?, Object?>{
        'success': false,
        'code': 'PERMISSION_REQUEST_CANCELLED',
        'message': 'The permission request was interrupted.',
        'data': <Object?, Object?>{},
      };

      expect(
        bridge.requestGuestPermissions('org.example'),
        throwsA(isA<VirtualizationException>().having(
          (VirtualizationException e) => e.code,
          'code',
          'PERMISSION_REQUEST_CANCELLED',
        )),
      );
    });
  });

  test('a platform failure becomes a NativeBridgeException', () {
    expect(bridge.getPlatformInfo(), throwsA(isA<NativeBridgeException>()));
  });
}
