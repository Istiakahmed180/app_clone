import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:duplika/core/services/onboarding_store.dart';
import 'package:duplika/core/virtualization/real_virtualization_engine.dart';
import 'package:duplika/core/virtualization/virtualization_engine.dart';
import 'package:duplika/data/repositories/virtual_profile_repository.dart';
import 'package:duplika/features/home/controllers/home_controller.dart';
import 'package:duplika/features/home/views/home_view.dart';
import 'package:duplika/features/home/widgets/virtualization_warning.dart';
import 'package:duplika/features/onboarding/controllers/onboarding_controller.dart';
import 'package:duplika/features/onboarding/widgets/background_permission_banner.dart';
import 'package:duplika/native/native_bridge.dart';

import 'fakes/in_memory_profile_storage.dart';

/// Covers the wiring the analyzer cannot: that the home screen still builds with the
/// onboarding host and banner in it, and that the banner is driven by the controller
/// rather than always being on screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(NativeBridge.channelName);
  late OnboardingController onboarding;
  late VirtualProfileRepository repository;
  late bool ignoringBattery;
  late bool virtualizationAvailable;
  late List<String> calls;

  Map<Object?, Object?> ok(Map<String, Object?> data) => <Object?, Object?>{
    'success': true,
    'code': 'OK',
    'message': 'ok',
    'data': data,
  };

  setUp(() async {
    ignoringBattery = false;
    virtualizationAvailable = true;
    calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'isVirtualizationAvailable':
              return <Object?, Object?>{
                'available': virtualizationAvailable,
                'backend': 'test',
                'message': 'This device cannot host containers.',
              };
            case 'getTestAppInfo':
              return <Object?, Object?>{'installed': false, 'packageName': 'x'};
            case 'getPlatformInfo':
              return <Object?, Object?>{};
            case 'isIgnoringBatteryOptimizations':
              return ok(<String, Object?>{'ignoring': ignoringBattery});
            case 'isAppInstalledInProfile':
              return ok(<String, Object?>{
                'installed': true,
                'running': true,
                'virtualUserId': 0,
              });
            default:
              return ok(<String, Object?>{});
          }
        });

    final NativeBridge bridge = NativeBridge(channel: channel);
    repository = VirtualProfileRepository(storage: InMemoryProfileStorage());

    // The terms are already settled here. This test is about the banner, and an
    // unanswered terms dialog would sit over the whole screen absorbing taps.
    final OnboardingStore store = OnboardingStore(
      storage: InMemoryProfileStorage(),
    );
    await store.acceptTerms();
    onboarding = OnboardingController(nativeBridge: bridge, store: store);

    Get.put<NativeBridge>(bridge);
    Get.put<VirtualProfileRepository>(repository);
    Get.put<VirtualizationEngine>(
      RealVirtualizationEngine(repository: repository, nativeBridge: bridge),
    );
    Get.put<HomeController>(
      HomeController(
        engine: Get.find<VirtualizationEngine>(),
        nativeBridge: bridge,
        repository: repository,
      ),
    );
    Get.put<OnboardingController>(onboarding);
  });

  tearDown(() {
    Get.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (BuildContext context, Widget? child) =>
            const GetMaterialApp(home: HomeView()),
      ),
    );
    await tester.pump();
  }

  testWidgets('the home screen builds with the onboarding host in place', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    expect(find.byType(HomeView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a working device is given no banner above the clone list', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);
    await tester.pumpAndSettle();

    // The warning is in the tree but takes no space: the healthy path is the list, not
    // a standing notice about the app working.
    // In the tree, painting nothing: the healthy path is the clone list, not a standing
    // notice that the app works.
    final Finder warning = find.byType(
      VirtualizationWarning,
      skipOffstage: false,
    );
    expect(warning, findsOneWidget);
    // Width is whatever the list gives it; the height is the assertion.
    expect(tester.getSize(warning).height, 0);
    // What the user gets instead: the identity block and a way to add a clone.
    expect(find.text('Duplika'), findsOneWidget);
    expect(find.text('Add app'), findsOneWidget);
  });

  testWidgets(
    'a device the engine cannot run on says so, in the backend\'s words',
    (WidgetTester tester) async {
      virtualizationAvailable = false;
      // The controller loaded once already, on Get.put in setUp.
      await Get.find<HomeController>().refreshAll();

      await pumpHome(tester);
      await tester.pumpAndSettle();

      expect(find.text('This device cannot host containers.'), findsOneWidget);
    },
  );

  testWidgets('a device that is not exempt is offered the Doze banner', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    expect(find.byType(BackgroundPermissionBanner), findsOneWidget);
    expect(find.text('Allow'), findsOneWidget);
  });

  testWidgets('an already-exempt device is never shown the banner', (
    WidgetTester tester,
  ) async {
    ignoringBattery = true;
    await onboarding.refreshBackgroundPrompt();
    await pumpHome(tester);

    expect(find.byType(BackgroundPermissionBanner), findsNothing);
  });

  testWidgets('dismissing the banner takes it off screen', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);
    expect(find.byType(BackgroundPermissionBanner), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pump();

    expect(find.byType(BackgroundPermissionBanner), findsNothing);
  });

  /// Puts one running clone on the grid and opens its action sheet.
  Future<void> openSheet(WidgetTester tester) async {
    await repository.createProfile(
      packageName: 'com.example.app',
      appName: 'Example',
      profileName: 'Example',
    );
    await Get.find<HomeController>().refreshAll();
    await pumpHome(tester);
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Example'));
    await tester.pumpAndSettle();
  }

  group('force stop', () {
    testWidgets('is confirmed before the guest is stopped', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.text('Force stop'));
      await tester.pumpAndSettle();

      expect(find.text('Force stop this app?'), findsOneWidget);
      expect(
        find.text('The app will stop running until you open it again.'),
        findsOneWidget,
      );
      expect(
        calls,
        isNot(contains('stopProfile')),
        reason:
            'nothing should be stopped while the question is still on screen',
      );
    });

    testWidgets('Cancel leaves the guest running', (WidgetTester tester) async {
      await openSheet(tester);
      await tester.tap(find.text('Force stop'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Force stop this app?'), findsNothing);
      expect(calls, isNot(contains('stopProfile')));
    });

    testWidgets('confirming stops it', (WidgetTester tester) async {
      await openSheet(tester);
      await tester.tap(find.text('Force stop'));
      await tester.pumpAndSettle();

      // The dialog's own button, not the sheet's tile of the same name.
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Force stop'),
        ),
      );
      await tester.pumpAndSettle();

      expect(calls, contains('stopProfile'));
    });
  });

  group('clear cache', () {
    testWidgets('is confirmed before anything is deleted', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.text('Clear cache'));
      await tester.pumpAndSettle();

      expect(find.text('Clear app cache?'), findsOneWidget);
      expect(
        find.text('This will remove temporary files for this clone.'),
        findsOneWidget,
      );
      expect(calls, isNot(contains('clearProfileCache')));
    });

    testWidgets('Cancel keeps the cache', (WidgetTester tester) async {
      await openSheet(tester);
      await tester.tap(find.text('Clear cache'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Clear app cache?'), findsNothing);
      expect(calls, isNot(contains('clearProfileCache')));
    });

    testWidgets('confirming clears it', (WidgetTester tester) async {
      await openSheet(tester);
      await tester.tap(find.text('Clear cache'));
      await tester.pumpAndSettle();

      // The dialog's own button, not the sheet's tile of the same name.
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Clear cache'),
        ),
      );
      await tester.pumpAndSettle();

      expect(calls, contains('clearProfileCache'));
    });
  });
}
