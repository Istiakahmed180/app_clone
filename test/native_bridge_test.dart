import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_space_demo/core/errors/app_exception.dart';
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

  test('a platform failure becomes a NativeBridgeException', () {
    expect(bridge.getPlatformInfo(), throwsA(isA<NativeBridgeException>()));
  });
}
