import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duplika/core/services/onboarding_store.dart';
import 'package:duplika/data/models/consent_state.dart';
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
  late List<String> calls;

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
    calls = <String>[];
    responses = <String, Map<Object?, Object?>>{
      'requestConsent': ok(<String, Object?>{'status': 'obtained', 'shown': true}),
      'isIgnoringBatteryOptimizations': ok(<String, Object?>{'ignoring': false}),
      'requestIgnoreBatteryOptimizations': ok(<String, Object?>{'screen': 'dialog'}),
    };

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call.method);
      return responses[call.method];
    });
    build();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('a first launch asks for consent, then stops on the terms', () async {
    await controller.start();

    expect(calls, contains('requestConsent'));
    expect(controller.step.value, OnboardingStep.terms);
    expect(controller.consent.value.status, ConsentStatus.obtained);
    // The Doze offer must wait until the terms are settled.
    expect(controller.showBackgroundPrompt.value, isFalse);
  });

  test('accepting the terms records the version and offers the Doze exemption', () async {
    await controller.start();
    await controller.acceptTerms();

    expect(controller.step.value, OnboardingStep.ready);
    expect(await store.hasAcceptedCurrentTerms(), isTrue);
    expect(controller.showBackgroundPrompt.value, isTrue);
  });

  test('a returning user is not asked for the terms again', () async {
    await store.acceptTerms();

    await controller.start();

    expect(controller.step.value, OnboardingStep.ready);
  });

  test('declining raises the flag the view exits on', () async {
    await controller.start();
    controller.declineTerms();

    expect(controller.declined.value, isTrue);
    // Declining must not be recorded as acceptance.
    expect(await store.hasAcceptedCurrentTerms(), isFalse);
  });

  test('a consent failure is recorded but does not stop onboarding', () async {
    responses['requestConsent'] = ok(<String, Object?>{
      'status': 'required',
      'shown': false,
      'errorCode': 3,
      'errorMessage': 'No form configured',
    });

    await controller.start();

    expect(controller.consent.value.failed, isTrue);
    expect(controller.step.value, OnboardingStep.terms);
  });

  test('a native bridge with no handler at all still reaches the terms', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    build();

    await controller.start();

    expect(controller.consent.value.status, ConsentStatus.unknown);
    expect(controller.step.value, OnboardingStep.terms);
  });

  test('an already-exempt device is never offered the prompt', () async {
    responses['isIgnoringBatteryOptimizations'] = ok(<String, Object?>{'ignoring': true});

    await controller.start();
    await controller.acceptTerms();

    expect(controller.showBackgroundPrompt.value, isFalse);
  });

  test('a dismissed prompt stays dismissed on the next launch', () async {
    await controller.start();
    await controller.acceptTerms();
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
    await controller.acceptTerms();

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
