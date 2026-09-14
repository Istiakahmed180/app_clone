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

  void build() {
    controller = OnboardingController(store: store);
  }

  setUp(() {
    storage = InMemoryProfileStorage();
    store = OnboardingStore(storage: storage);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async => null);
    build();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('a first launch is usable straight away', () async {
    await controller.start();

    expect(controller.step.value, OnboardingStep.ready);
  });

  test('the disclosure starts unaccepted, and stays accepted once agreed to', () async {
    await controller.start();
    expect(controller.accepted.value, isFalse);

    await controller.acceptDisclosure();
    expect(controller.accepted.value, isTrue);

    // A new controller over the same store — i.e. the next launch — sees it accepted.
    build();
    await controller.start();
    expect(controller.accepted.value, isTrue);
  });

  test('a native bridge with no handler at all still reaches ready', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    build();

    await controller.start();

    expect(controller.step.value, OnboardingStep.ready);
  });

  test('the background-activity ask is not part of onboarding', () async {
    // It lives in Settings, where its state is on show, rather than arriving here as a
    // banner that duplicated it.
    await controller.start();
    await controller.acceptDisclosure();

    expect(controller.accepted.value, isTrue);
    expect(storage.values.keys, isNot(contains('duplika.onboarding.background_prompt_dismissed')));
  });
}
