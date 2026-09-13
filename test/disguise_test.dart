import 'package:duplika/core/services/biometric_authenticator.dart';
import 'package:duplika/core/services/pin_hasher.dart';
import 'package:duplika/core/services/private_space_store.dart';
import 'package:duplika/data/models/app_disguise_mode.dart';
import 'package:duplika/data/repositories/virtual_profile_repository.dart';
import 'package:duplika/features/disguise/controllers/disguise_controller.dart';
import 'package:duplika/features/disguise/views/calculator_view.dart';
import 'package:duplika/features/private_space/controllers/private_space_controller.dart';
import 'package:duplika/native/native_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/in_memory_profile_storage.dart';

class _NoBiometric extends BiometricAuthenticator {
  @override
  Future<bool> isAvailable() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(NativeBridge.channelName);
  late String platformMode;
  late bool rejectDisguise;

  Map<Object?, Object?> envelope(String mode) => <Object?, Object?>{
        'success': true,
        'code': 'APP_DISGUISE',
        'message': 'ok',
        'data': <Object?, Object?>{'mode': mode},
      };

  setUp(() {
    platformMode = 'NORMAL';
    rejectDisguise = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      switch (call.method) {
        case 'getAppDisguise':
          return envelope(platformMode);
        case 'setAppDisguise':
          if (!rejectDisguise) {
            platformMode = (call.arguments as Map<Object?, Object?>)['mode'] as String;
          }
          return envelope(platformMode);
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<PrivateSpaceController> privateSpaceWithPin(String pin) async {
    final InMemoryProfileStorage storage = InMemoryProfileStorage();
    final PrivateSpaceController controller = PrivateSpaceController(
      repository: VirtualProfileRepository(storage: storage),
      store: PrivateSpaceStore(
        storage: storage,
        hasher: const PinHasher(iterations: 1000),
      ),
      biometric: _NoBiometric(),
    );
    await controller.create(pin);
    return controller;
  }

  DisguiseController controllerFor(PrivateSpaceController privateSpace) =>
      DisguiseController(bridge: NativeBridge(channel: channel), privateSpace: privateSpace);

  test('a calculator disguise starts locked and the PIN is the way back in', () async {
    platformMode = 'CALCULATOR';
    final PrivateSpaceController privateSpace = await privateSpaceWithPin('1234');
    final DisguiseController controller = controllerFor(privateSpace);

    await controller.reload();

    expect(controller.mode.value, AppDisguiseMode.calculator);
    expect(controller.locked.value, isTrue);
    expect(controller.shouldHideApp, isTrue);

    expect(await controller.unlock('0000'), isFalse);
    expect(controller.shouldHideApp, isTrue);

    expect(await controller.unlock('1234'), isTrue);
    expect(controller.shouldHideApp, isFalse);
  });

  test('setMode applies and reports what the platform says', () async {
    final PrivateSpaceController privateSpace = await privateSpaceWithPin('1234');
    final DisguiseController controller = controllerFor(privateSpace);
    await controller.reload();

    expect(controller.mode.value, AppDisguiseMode.normal);
    expect(controller.shouldHideApp, isFalse);

    final AppDisguiseMode? applied =
        await controller.setMode(AppDisguiseMode.calculator);

    expect(applied, AppDisguiseMode.calculator);
    expect(controller.mode.value, AppDisguiseMode.calculator);
    // Turning it on from an authenticated session does not immediately lock the user out.
    expect(controller.shouldHideApp, isFalse);
  });

  test('the reported platform state wins over the requested one', () async {
    final PrivateSpaceController privateSpace = await privateSpaceWithPin('1234');
    final DisguiseController controller = controllerFor(privateSpace);
    await controller.reload();

    // The platform refuses the change and reports NORMAL back: the requested value is not
    // what is trusted.
    rejectDisguise = true;
    platformMode = 'NORMAL';
    final AppDisguiseMode? applied =
        await controller.setMode(AppDisguiseMode.calculator);

    expect(applied, AppDisguiseMode.normal);
    expect(controller.mode.value, AppDisguiseMode.normal);
  });

  testWidgets('the calculator computes like a calculator', (WidgetTester tester) async {
    // No PIN is set, and none is needed: `2 + 3 =` carries an operator, so the unlock path
    // is not entered. Avoids the store's isolate, which a widget test cannot await.
    final PrivateSpaceController privateSpace = PrivateSpaceController(
      repository: VirtualProfileRepository(storage: InMemoryProfileStorage()),
      store: PrivateSpaceStore(
        storage: InMemoryProfileStorage(),
        hasher: const PinHasher(iterations: 1000),
      ),
      biometric: _NoBiometric(),
    );
    final DisguiseController controller = controllerFor(privateSpace);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (BuildContext context, Widget? child) =>
            CalculatorView(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    String display() => tester
        .widget<Text>(find.byKey(const Key('calculator-display')))
        .data!;

    // 2 + 3 = 5
    await tester.tap(find.text('2'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    expect(display(), '5');

    // C clears it back to a single zero.
    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();
    expect(display(), '0');
  });
}
