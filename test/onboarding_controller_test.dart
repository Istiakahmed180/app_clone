import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duplika/core/services/onboarding_store.dart';
import 'package:duplika/features/onboarding/controllers/onboarding_controller.dart';
import 'package:duplika/native/native_bridge.dart';

import 'fakes/in_memory_profile_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(NativeBridge.channelName);
  late InMemoryProfileStorage storage;
  late OnboardingStore store;
  late OnboardingController controller;
  late Map<String, Map<Object?, Object?>> responses;

  Map<Object?, Object?> ok(Map<String, Object?> data) => <Object?, Object?>{
        'success': true,
        'code': 'OK',
        'message': 'ok',
        'data': data,
      };

  void build() {
    final NativeBridge bridge = NativeBridge(channel: channel);
    controller = OnboardingController(nativeBridge: bridge, store: store);
  }

  setUp(() {
    storage = InMemoryProfileStorage();
    store = OnboardingStore(storage: storage);
    responses = <String, Map<Object?, Object?>>{
      'isIgnoringBatteryOptimizations': ok(<String, Object?>{'ignoring': false}),
      'requestIgnoreBatteryOptimizations': ok(<String, Object?>{'screen': 'dialog'}),
    };

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      return responses[call.method];
    });
    build();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('a first launch is usable straight away, and offers the Doze exemption', () async {
    await controller.start();

    expect(controller.step.value, OnboardingStep.ready);
    expect(controller.showBackgroundPrompt.value, isTrue);
  });

  test('a native bridge with no handler at all still reaches ready', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    build();

    await controller.start();

    expect(controller.step.value, OnboardingStep.ready);
  });

  test('an already-exempt device is never offered the prompt', () async {
    responses['isIgnoringBatteryOptimizations'] = ok(<String, Object?>{'ignoring': true});

    await controller.start();

    expect(controller.showBackgroundPrompt.value, isFalse);
  });

  test('a dismissed prompt stays dismissed on the next launch', () async {
    await controller.start();
    await controller.dismissBackgroundPrompt();

    build();
    await controller.start();

    expect(controller.showBackgroundPrompt.value, isFalse);
  });

  test('the settings fallback tells the user what they have to do themselves', () async {
    responses['requestIgnoreBatteryOptimizations'] =
        ok(<String, Object?>{'screen': 'settings'});

    final String? message = await controller.requestBackgroundPermission();

    expect(message, contains("Don't optimise"));
  });

  test('the one-tap dialog needs no explanation, and the offer stays up', () async {
    await controller.start();

    final String? message = await controller.requestBackgroundPermission();

    expect(message, isNull);
    // Opening the dialog is not the same as being granted the exemption.
    expect(controller.showBackgroundPrompt.value, isTrue);
  });

  test('a device with no battery screen surfaces the reason', () async {
    responses['requestIgnoreBatteryOptimizations'] = <Object?, Object?>{
      'success': false,
      'code': 'BATTERY_PROMPT_UNAVAILABLE',
      'message': 'This device has no battery optimisation screen to open.',
      'data': <Object?, Object?>{},
    };

    final String? message = await controller.requestBackgroundPermission();

    expect(message, contains('no battery optimisation screen'));
  });
}
