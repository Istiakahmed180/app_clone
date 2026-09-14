import 'package:duplika/core/diagnostics/diagnostics_repository.dart';
import 'package:duplika/core/services/settings_store.dart';
import 'package:duplika/data/models/app_language.dart';
import 'package:duplika/data/models/background_activity_state.dart';
import 'package:duplika/data/repositories/virtual_profile_repository.dart';
import 'package:duplika/features/private_space/controllers/private_space_controller.dart';
import 'package:duplika/l10n/app_localizations.dart';
import 'package:duplika/features/settings/views/language_view.dart';
import 'package:duplika/features/settings/controllers/settings_controller.dart';
import 'package:duplika/features/settings/views/appearance_view.dart';
import 'package:duplika/features/settings/views/contact_view.dart';
import 'package:duplika/features/settings/views/settings_view.dart';
import 'package:duplika/features/settings/widgets/theme_preview.dart';
import 'package:duplika/app/routes/app_routes.dart';
import 'package:duplika/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'fakes/fake_background_activity_bridge.dart';
import 'fakes/fake_native_diagnostics.dart';
import 'fakes/in_memory_profile_storage.dart';

/// An exempt, unrestricted Duplika: the state the row reads as `Allowed`.
const BackgroundActivityState _allowedState = BackgroundActivityState(
  exempt: true,
  restricted: false,
  standbyBucket: 'active',
);

const Map<String, dynamic> _payload = <String, dynamic>{
  'appVersion': '1.0.0',
  'appVersionCode': 1,
  'model': 'CPH2605',
  'androidVersion': '15',
  'sdkInt': 35,
  'supportedAbis': <String>['arm64-v8a', 'armeabi-v7a'],
  'primaryAbi': 'arm64-v8a',
};

void main() {
  group('SettingsStore', () {
    test('follows the system until the user chooses otherwise', () async {
      final SettingsStore store =
          SettingsStore(storage: InMemoryProfileStorage());

      expect(await store.themeMode(), ThemeMode.system);
    });

    test('round-trips every mode', () async {
      final InMemoryProfileStorage storage = InMemoryProfileStorage();
      final SettingsStore store = SettingsStore(storage: storage);

      for (final ThemeMode mode in ThemeMode.values) {
        await store.setThemeMode(mode);
        expect(await store.themeMode(), mode, reason: mode.name);
      }
    });

    test('a stored value it does not recognise means the default', () async {
      // A preference written by a build that named the modes differently must land the
      // user on the system default, not on whichever mode a parse failure produces.
      final InMemoryProfileStorage storage = InMemoryProfileStorage()
        ..values[SettingsStore.themeModeKey] = 'midnight';

      expect(await SettingsStore(storage: storage).themeMode(), ThemeMode.system);
    });

    test('the background nudge remembers being waved away', () async {
      final InMemoryProfileStorage storage = InMemoryProfileStorage();
      final SettingsStore store = SettingsStore(storage: storage);

      expect(await store.backgroundNudgeDismissed(), isFalse);

      await store.dismissBackgroundNudge();

      expect(await store.backgroundNudgeDismissed(), isTrue);
    });
  });

  group('SettingsController', () {
    late InMemoryProfileStorage storage;
    late FakeNativeDiagnostics native;
    late FakeBackgroundActivityBridge bridge;
    late List<Uri> opened;
    late bool openSucceeds;

    SettingsController build() {
      return SettingsController(
        diagnostics: DiagnosticsRepository(native: native),
        bridge: bridge,
        store: SettingsStore(storage: storage),
        openUrl: (Uri url) async {
          opened.add(url);
          return openSucceeds;
        },
      );
    }

    setUp(() {
      storage = InMemoryProfileStorage();
      native = FakeNativeDiagnostics(payload: _payload);
      bridge = FakeBackgroundActivityBridge();
      opened = <Uri>[];
      openSucceeds = true;
    });

    test('restores the stored appearance and applies it', () async {
      await SettingsStore(storage: storage).setThemeMode(ThemeMode.dark);
      final SettingsController controller = build();

      await controller.restoreThemeMode();

      expect(controller.themeMode.value, ThemeMode.dark);
    });

    test('choosing an appearance applies it and stores it', () async {
      final SettingsController controller = build();

      await controller.setThemeMode(ThemeMode.light);

      expect(controller.themeMode.value, ThemeMode.light);
      expect(storage.values[SettingsStore.themeModeKey], 'light');
    });

    test('choosing the mode already in force does nothing', () async {
      final SettingsController controller = build();

      await controller.setThemeMode(ThemeMode.system);

      expect(controller.themeMode.value, ThemeMode.system);
      expect(storage.values, isEmpty, reason: 'nothing to store');
    });

    test('follows the device until a language is chosen', () async {
      final SettingsController controller = build();

      await controller.restoreLanguage();

      // Null is what the app root reads as 'follow the device'.
      expect(controller.language.value, isNull);
    });

    test('restores a stored language and applies it', () async {
      final AppLanguage japanese = AppLanguages.byTag('ja')!;
      await SettingsStore(storage: storage).setLanguage(japanese);
      final SettingsController controller = build();

      await controller.restoreLanguage();

      expect(controller.language.value?.tag, 'ja');
      expect(controller.language.value?.locale, japanese.locale);
      expect(controller.language.value?.nativeName, '日本語');
    });

    test('choosing a language applies it and stores its tag', () async {
      final SettingsController controller = build();

      await controller.setLanguage(AppLanguages.byTag('zh-Hant-HK'));

      expect(controller.language.value?.englishName,
          'Chinese (Traditional, Hong Kong)');
      expect(storage.values[SettingsStore.languageKey], 'zh-Hant-HK');
      expect(controller.language.value?.locale.toLanguageTag(), 'zh-Hant-HK');
    });

    test('going back to System default forgets the stored tag', () async {
      final SettingsController controller = build();
      await controller.setLanguage(AppLanguages.byTag('de'));

      await controller.setLanguage(null);

      expect(controller.language.value, isNull);
      expect(storage.values.containsKey(SettingsStore.languageKey), isFalse);
    });

    test('choosing the language already in force does nothing', () async {
      final SettingsController controller = build();
      await controller.setLanguage(AppLanguages.byTag('it'));
      storage.values.clear();

      await controller.setLanguage(AppLanguages.byTag('it'));

      expect(controller.language.value?.tag, 'it');
      expect(storage.values, isEmpty, reason: 'it did not write again');
    });

    test('a stored language this build dropped falls back to the device', () async {
      // Removing a language must not strand its users on a locale the app can no
      // longer supply.
      storage.values[SettingsStore.languageKey] = 'kl';
      final SettingsController controller = build();

      await controller.restoreLanguage();

      expect(controller.language.value, isNull);
    });

    test('reports the build and the architecture it is running as', () async {
      final SettingsController controller = build();

      await controller.loadSystemInfo();

      expect(controller.versionLabel, '1.0.0 (1)');
      expect(controller.architecture?.abi, 'arm64-v8a');
      expect(controller.architecture?.is64Bit, isTrue);
      expect(controller.supportedAbisLabel, 'arm64-v8a, armeabi-v7a');
    });

    test('a 32-bit device is described as one', () async {
      native.payload = <String, dynamic>{
        ..._payload,
        'supportedAbis': <String>['armeabi-v7a'],
        'primaryAbi': 'armeabi-v7a',
      };
      final SettingsController controller = build();

      await controller.loadSystemInfo();

      expect(controller.architecture?.abi, 'armeabi-v7a');
      expect(controller.architecture?.is64Bit, isFalse);
    });

    test('a failed lookup leaves the About rows empty rather than wrong', () async {
      native.fails = true;
      final SettingsController controller = build();

      await controller.loadSystemInfo();

      expect(controller.versionLabel, isNull);
      expect(controller.architecture, isNull);
      expect(controller.supportedAbisLabel, isNull);
      expect(controller.status.value, isNull, reason: 'logged, not shouted');
    });

    test('reads the background standing Android reports', () async {
      bridge.state = const BackgroundActivityState(
        exempt: true,
        restricted: false,
        standbyBucket: 'active',
      );
      final SettingsController controller = build();

      await controller.refreshBackgroundActivity();

      expect(controller.backgroundActivity.value?.allowed, isTrue);
      expect(controller.backgroundActivity.value?.standbyBucket, 'active');
    });

    test('a build that cannot answer says nothing rather than "restricted"', () async {
      // Null is the honest answer here. Reporting it as restricted would send every user
      // of a device without the API to a system screen that cannot help them.
      bridge.state = null;
      final SettingsController controller = build();

      await controller.refreshBackgroundActivity();

      expect(controller.backgroundActivity.value, isNull);
    });

    test('a screen that never opened is reported, not swallowed', () async {
      bridge.state = _allowedState;
      bridge.openFails = true;
      final SettingsController controller = build();

      await controller.openBackgroundActivitySettings();

      expect(controller.status.value, SettingsStatus.backgroundActivityFailed);
    });

    test('the nudge offers itself only while Android actually restricts us', () async {
      final SettingsController controller = build();

      bridge.state = _allowedState;
      await controller.refreshBackgroundActivity();
      expect(controller.backgroundNudgeVisible, isFalse);

      bridge.state = const BackgroundActivityState(
        exempt: false,
        restricted: true,
        standbyBucket: 'rare',
      );
      await controller.refreshBackgroundActivity();
      expect(controller.backgroundNudgeVisible, isTrue);
    });

    test('an unreadable OEM switch still asks the user to look', () async {
      // The switch decides more than the two readable controls, so an OEM build is never
      // "allowed" from here -- and the reminder is the only place that says so before the
      // user notices the notifications missing.
      bridge.state = const BackgroundActivityState(
        exempt: true,
        restricted: false,
        standbyBucket: 'unknown(5)',
        nextStep: 'batteryUsage',
      );
      final SettingsController controller = build();

      await controller.refreshBackgroundActivity();

      expect(controller.backgroundActivity.value?.allowed, isFalse);
      expect(controller.backgroundNudgeVisible, isTrue);
    });

    test('acting on the nudge keeps it away, readable or not', () async {
      bridge.state = const BackgroundActivityState(
        exempt: true,
        restricted: false,
        standbyBucket: 'unknown(5)',
        nextStep: 'batteryUsage',
      );
      final SettingsController controller = build();
      await controller.refreshBackgroundActivity();

      await controller.acceptBackgroundNudge();

      expect(controller.backgroundNudgeVisible, isFalse);
      expect(
        bridge.opened,
        0,
        reason: 'the guide the view opens next is the answer, not a silent jump',
      );
    });

    test('a state the platform cannot report is not treated as a problem', () async {
      // Null means "the platform could not say". Nudging on it would send every user of
      // an old release to a screen that cannot help them.
      final SettingsController controller = build();

      bridge.state = null;
      await controller.refreshBackgroundActivity();

      expect(controller.backgroundNudgeVisible, isFalse);
    });

    test('dismissing the nudge hides the reminder and keeps it hidden', () async {
      bridge.state = const BackgroundActivityState(
        exempt: false,
        restricted: true,
        standbyBucket: 'rare',
      );
      final SettingsController controller = build();
      await controller.refreshBackgroundActivity();

      await controller.dismissBackgroundNudge();

      expect(controller.backgroundNudgeVisible, isFalse);
      expect(storage.values[SettingsStore.backgroundNudgeKey], 'true');
      expect(
        controller.backgroundActivity.value?.allowed,
        isFalse,
        reason: 'the Settings row still reports the state',
      );
    });

    test('an unmet exemption is asked for where the system can grant it', () async {
      // On the builds whose switch is not under Battery usage, the system's own one-tap
      // exemption prompt is the control that matters, and a dialog no OEM page can offer
      // goes unused if it is skipped.
      bridge.state = const BackgroundActivityState(
        exempt: false,
        restricted: true,
        standbyBucket: 'rare',
      );
      final SettingsController controller = build();
      await controller.refreshBackgroundActivity();


      await controller.openBackgroundActivitySettings();

      expect(bridge.prompts, 1);
      expect(bridge.opened, 0, reason: 'the prompt is the whole answer there');
    });

    test('an OEM switch under Battery usage goes straight to its page', () async {
      // No dialog grants that switch, so the info page -- which carries both it and the
      // battery control -- is the only destination worth opening.
      bridge.state = const BackgroundActivityState(
        exempt: false,
        restricted: true,
        standbyBucket: 'rare',
        nextStep: 'batteryUsage',
      );
      final SettingsController controller = build();
      await controller.refreshBackgroundActivity();


      await controller.openBackgroundActivitySettings();

      expect(bridge.opened, 1);
      expect(bridge.prompts, 0);
    });

    test('an exemption already granted means the page, not a dead tap', () async {
      // The prompt has nothing to ask once the exemption is in place, so tapping the row
      // must still land the user somewhere.
      bridge.state = _allowedState;
      final SettingsController controller = build();
      await controller.refreshBackgroundActivity();


      await controller.openBackgroundActivitySettings();

      expect(bridge.opened, 1);
      expect(bridge.prompts, 0);
    });

    test('Contact us opens a mail composer naming the build', () async {
      final SettingsController controller = build();
      await controller.loadSystemInfo();

      await controller.emailSupport();

      expect(opened, hasLength(1));
      expect(opened.single.scheme, 'mailto');
      expect(opened.single.path, 'support@tdevs.co');
      expect(opened.single.queryParameters['subject'], 'Duplika 1.0.0 (1)');
    });

    test('a device with no mail app reports that it could not open one', () async {
      openSucceeds = false;
      final SettingsController controller = build();

      await controller.emailSupport();

      expect(controller.status.value, SettingsStatus.mailAppMissing);
    });

    test('an unpublished policy is not opened', () async {
      // The URLs are still example.com placeholders, so there is nothing to open. The
      // same rule the terms dialog follows.
      final SettingsController controller = build();

      await controller.openPrivacyPolicy();
      await controller.openTermsOfService();

      expect(controller.legalLinksArePublished, isFalse);
      expect(opened, isEmpty);
    });

    test('an unlisted app does not send anyone to the Play Store', () async {
      final SettingsController controller = build();

      await controller.openReview();

      expect(controller.reviewLinkIsPublished, isFalse);
      expect(opened, isEmpty);
    });
  });

  group('SettingsView', () {
    late FakeNativeDiagnostics native;

    late FakeBackgroundActivityBridge bridge;

    /// Settings reads the Private space controller for its one privacy row, so the
    /// graph has to hold one before the screen is built.
    void registerPrivateSpace() {
      Get.put<PrivateSpaceController>(
        PrivateSpaceController(
          repository: VirtualProfileRepository(storage: InMemoryProfileStorage()),
        ),
      );
    }

    Future<void> open(WidgetTester tester) async {
      // The page is taller than a phone, so on a phone-sized surface a ListView never
      // builds its lower half and nothing down there can be found.
      tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      registerPrivateSpace();
      Get.put<SettingsController>(
        SettingsController(
          diagnostics: DiagnosticsRepository(native: native),
          bridge: bridge,
          store: SettingsStore(storage: InMemoryProfileStorage()),
          openUrl: (Uri _) async => true,
        ),
      );
      addTearDown(Get.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (BuildContext context, Widget? child) => MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Settings inside a real GetMaterialApp, so the route table itself is asserted: a
    /// row names a route, and a route that is not registered fails here rather than on
    /// a device.
    Future<void> openRouted(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      registerPrivateSpace();
      Get.put<SettingsController>(
        SettingsController(
          diagnostics: DiagnosticsRepository(native: native),
          bridge: bridge,
          store: SettingsStore(storage: InMemoryProfileStorage()),
          openUrl: (Uri _) async => true,
        ),
      );
      addTearDown(Get.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (BuildContext context, Widget? child) => GetMaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            initialRoute: AppRoutes.settings,
            getPages: AppRoutes.pages(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      native = FakeNativeDiagnostics(payload: _payload);
      // Allowed by default, so the rows that read 'unavailable' stay the ones about the
      // build facts rather than picking up the background row as well.
      bridge = FakeBackgroundActivityBridge()..state = _allowedState;
    });

    testWidgets('groups every row under the heading it belongs to', (
      WidgetTester tester,
    ) async {
      await open(tester);

      for (final String label in <String>[
        'Language',
        'Appearance',
        'DELIVERY',
        'Background activity',
        'SUPPORT',
        'Contact us',
        'Rate us',
        'LEGAL',
        'Privacy Policy',
        'Terms of Service',
        'ABOUT',
        'Version',
        'Device architecture',
        'Supported ABIs',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('reports the build it is actually running', (
      WidgetTester tester,
    ) async {
      await open(tester);

      expect(find.text('1.0.0 (1)'), findsOneWidget);
      expect(find.text('64-bit · arm64-v8a'), findsOneWidget);
      expect(find.text('arm64-v8a, armeabi-v7a'), findsOneWidget);
    });

    testWidgets('says which rows the build cannot honour yet', (
      WidgetTester tester,
    ) async {
      // Rendered inert with the reason, not hidden: a row that vanishes tells the user
      // nothing about why it is not there.
      await open(tester);

      expect(find.text('Not published yet'), findsNWidgets(2));
      expect(find.text('Not listed yet'), findsOneWidget);
    });

    testWidgets('Language and Appearance both show what is in force', (
      WidgetTester tester,
    ) async {
      await open(tester);

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      // Both default to following the device, so both read the same until changed.
      expect(find.text('System default'), findsNWidgets(2));
    });

    testWidgets('the Background activity row reports what Android decided', (
      WidgetTester tester,
    ) async {
      bridge.state = const BackgroundActivityState(
        exempt: true,
        restricted: false,
        standbyBucket: 'active',
      );
      await open(tester);

      expect(find.text('Background activity'), findsOneWidget);
      expect(find.text('Allowed'), findsOneWidget);
      expect(
        find.text('Lets cloned apps receive notifications while they are closed'),
        findsOneWidget,
      );
    });

    testWidgets('a restricted row says which taps turn it back on', (
      WidgetTester tester,
    ) async {
      bridge.state = const BackgroundActivityState(
        exempt: false,
        restricted: true,
        standbyBucket: 'restricted',
      );
      await open(tester);

      expect(find.text('Restricted'), findsOneWidget);
      expect(find.text('Tap here and allow background activity'), findsOneWidget);
    });

    testWidgets('an unreadable OEM switch is a Check, not a claim', (
      WidgetTester tester,
    ) async {
      // Measured on a OnePlus with its switch off: none of Android's readable controls
      // move. A green `Allowed` over a switch the app never read is worse than saying so.
      bridge.state = const BackgroundActivityState(
        exempt: true,
        restricted: false,
        standbyBucket: 'unknown(5)',
        nextStep: 'batteryUsage',
      );
      await open(tester);

      expect(find.text('Check'), findsOneWidget);
      expect(find.text('Allowed'), findsNothing);
      expect(
        find.text('Tap here, then Battery usage, then Allow background activity'),
        findsOneWidget,
      );
    });

    testWidgets('a problem it can see is Restricted even beside that switch', (
      WidgetTester tester,
    ) async {
      // The exemption is readable, and it is missing: that is a fact worth stating, not
      // something to soften into a check.
      bridge.state = const BackgroundActivityState(
        exempt: false,
        restricted: false,
        standbyBucket: 'unknown(5)',
        nextStep: 'batteryUsage',
      );
      await open(tester);

      expect(find.text('Restricted'), findsOneWidget);
      expect(find.text('Check'), findsNothing);
      expect(
        find.text('Tap here, then Battery usage, then Allow background activity'),
        findsOneWidget,
      );
    });

    testWidgets('the row explains before it sends anyone to a system screen', (
      WidgetTester tester,
    ) async {
      // The word "background" means five different things in Android settings, so the row
      // has to say which one it means before it points at a screen that uses none of them.
      bridge.state = const BackgroundActivityState(
        exempt: false,
        restricted: true,
        standbyBucket: 'rare',
      );
      await open(tester);

      await tester.tap(find.text('Background activity'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Android can pause Duplika'),
        findsOneWidget,
        reason: 'the guide says what the setting is for',
      );
      expect(bridge.prompts, 0, reason: 'nothing opens until the user asks');

      await tester.tap(find.widgetWithText(FilledButton, 'Allow'));
      await tester.pumpAndSettle();

      expect(bridge.prompts, 1);
    });

    testWidgets('an OEM guide names the sub-page and opens app info', (
      WidgetTester tester,
    ) async {
      bridge.state = const BackgroundActivityState(
        exempt: false,
        restricted: true,
        standbyBucket: 'unknown(5)',
        nextStep: 'batteryUsage',
      );
      await open(tester);

      await tester.tap(find.text('Background activity'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Battery usage'), findsWidgets);

      await tester.tap(find.widgetWithText(FilledButton, 'Open App info'));
      await tester.pumpAndSettle();

      expect(bridge.opened, 1);
    });

    testWidgets('the Language row opens the language page', (
      WidgetTester tester,
    ) async {
      await openRouted(tester);

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      expect(find.byType(LanguageView), findsOneWidget);
      expect(find.text('Search languages'), findsOneWidget);
    });

    testWidgets('the Contact us row opens the contact page', (
      WidgetTester tester,
    ) async {
      await openRouted(tester);

      await tester.tap(find.text('Contact us'));
      await tester.pumpAndSettle();

      expect(find.byType(ContactView), findsOneWidget);
      expect(find.text('How can we help?'), findsOneWidget);
    });

    testWidgets('the Appearance row opens the appearance page', (
      WidgetTester tester,
    ) async {
      await openRouted(tester);

      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();

      expect(find.byType(AppearanceView), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
    });

    testWidgets('an unreachable build reads as unavailable, not as blank', (
      WidgetTester tester,
    ) async {
      native.fails = true;
      await open(tester);

      expect(find.text('unavailable'), findsNWidgets(3));
    });

    testWidgets('carries a copyright line for the current year', (
      WidgetTester tester,
    ) async {
      await open(tester);

      expect(find.text('© ${DateTime.now().year} Duplika'), findsOneWidget);
    });

    testWidgets('rows survive a real phone width and a large text scale', (
      WidgetTester tester,
    ) async {
      // The trailing value is bounded rather than free, so that a four-entry ABI list
      // wraps inside its own column instead of squeezing the title to nothing. At a
      // large font scale that is the row that breaks first, so it is the one asserted:
      // an overflow here fails the pump.
      native.payload = <String, dynamic>{
        ..._payload,
        'appVersion': '1.0.59.20',
        'appVersionCode': 73,
        'supportedAbis': <String>['arm64-v8a', 'armeabi-v7a', 'x86_64', 'x86'],
      };

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      registerPrivateSpace();
      Get.put<SettingsController>(
        SettingsController(
          diagnostics: DiagnosticsRepository(native: native),
          store: SettingsStore(storage: InMemoryProfileStorage()),
          openUrl: (Uri _) async => true,
        ),
      );
      addTearDown(Get.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: MaterialApp(
              theme: AppTheme.light(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const SettingsView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Far enough to reach the About rows at this text scale, one section further down
      // than it used to be: Delivery sits between the preferences and Privacy.
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();

      expect(find.text('arm64-v8a, armeabi-v7a, x86_64, x86'), findsOneWidget);
    });
  });

  group('AppearanceView', () {
    late InMemoryProfileStorage storage;
    late SettingsController controller;

    Future<void> open(
      WidgetTester tester, {
      Brightness platform = Brightness.light,
    }) async {
      tester.view.physicalSize = const Size(390 * 3, 1200 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      controller = SettingsController(
        diagnostics: DiagnosticsRepository(native: FakeNativeDiagnostics()),
        store: SettingsStore(storage: storage),
        openUrl: (Uri _) async => true,
      );
      Get.put<SettingsController>(controller);
      addTearDown(Get.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQueryData(platformBrightness: platform),
            child: MaterialApp(
              theme: AppTheme.light(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const AppearanceView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      storage = InMemoryProfileStorage();
    });

    testWidgets('offers all three modes, each with what it does', (
      WidgetTester tester,
    ) async {
      await open(tester);

      for (final (String name, String description) in <(String, String)>[
        ('System default', 'Match your device settings'),
        ('Light', 'Always use light theme'),
        ('Dark', 'Always use dark theme'),
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
        expect(find.text(description), findsOneWidget, reason: description);
      }
    });

    testWidgets('previews both palettes side by side', (
      WidgetTester tester,
    ) async {
      await open(tester);

      expect(find.text('Preview'), findsOneWidget);
      expect(find.byType(ThemePreview), findsNWidgets(2));
    });

    testWidgets('the ring marks the palette actually in effect', (
      WidgetTester tester,
    ) async {
      // 'System default' on a light device means the light mockup is the live one. The
      // selected mode alone cannot answer this, which is the reason for the preview.
      await open(tester);

      ThemePreview preview(Brightness brightness) => tester
          .widgetList<ThemePreview>(find.byType(ThemePreview))
          .firstWhere((ThemePreview p) => p.brightness == brightness);

      expect(preview(Brightness.light).selected, isTrue);
      expect(preview(Brightness.dark).selected, isFalse);
    });

    testWidgets('System default on a dark device rings the dark mockup', (
      WidgetTester tester,
    ) async {
      await open(tester, platform: Brightness.dark);

      final ThemePreview dark = tester
          .widgetList<ThemePreview>(find.byType(ThemePreview))
          .firstWhere((ThemePreview p) => p.brightness == Brightness.dark);
      expect(dark.selected, isTrue);
    });

    testWidgets('choosing Dark applies it, stores it and moves the ring', (
      WidgetTester tester,
    ) async {
      await open(tester);

      await tester.tap(find.text('Always use dark theme'));
      await tester.pumpAndSettle();

      expect(controller.themeMode.value, ThemeMode.dark);
      expect(storage.values[SettingsStore.themeModeKey], 'dark');

      final ThemePreview dark = tester
          .widgetList<ThemePreview>(find.byType(ThemePreview))
          .firstWhere((ThemePreview p) => p.brightness == Brightness.dark);
      expect(dark.selected, isTrue, reason: 'the ring follows the choice');
    });

    testWidgets('the radio and the row select the same thing', (
      WidgetTester tester,
    ) async {
      await open(tester);

      await tester.tap(find.byType(Radio<ThemeMode>).last);
      await tester.pumpAndSettle();

      expect(controller.themeMode.value, ThemeMode.dark);
    });

    testWidgets('says that the change takes effect at once', (
      WidgetTester tester,
    ) async {
      await open(tester);

      expect(
        find.text('Theme changes apply instantly across Duplika.'),
        findsOneWidget,
      );
    });
  });

  group('ContactView', () {
    late List<Uri> opened;
    late bool openSucceeds;
    late SettingsController controller;

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1200 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      controller = SettingsController(
        diagnostics: DiagnosticsRepository(native: FakeNativeDiagnostics()),
        store: SettingsStore(storage: InMemoryProfileStorage()),
        openUrl: (Uri url) async {
          opened.add(url);
          return openSucceeds;
        },
      );
      Get.put<SettingsController>(controller);
      addTearDown(Get.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (BuildContext context, Widget? child) => MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ContactView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      opened = <Uri>[];
      openSucceeds = true;
    });

    testWidgets('leads with what the screen is for', (
      WidgetTester tester,
    ) async {
      await open(tester);

      expect(find.text('How can we help?'), findsOneWidget);
      expect(
        find.text('Choose your preferred way to contact the Duplika team.'),
        findsOneWidget,
      );
    });

    testWidgets('lists every channel, each saying what it is', (
      WidgetTester tester,
    ) async {
      await open(tester);

      for (final (String name, String description) in <(String, String)>[
        ('WhatsApp', 'Chat with our support team'),
        ('Telegram', 'Message us on Telegram'),
        ('Email', 'Send us an email'),
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
        expect(find.text(description), findsOneWidget, reason: description);
      }
    });

    testWidgets('sets the expectation for a reply, and for the message', (
      WidgetTester tester,
    ) async {
      await open(tester);

      expect(find.text('Response time'), findsOneWidget);
      expect(find.textContaining('within 1\u20132 business days'), findsOneWidget);
      expect(
        find.text("We'll only use your message to provide support."),
        findsOneWidget,
      );
    });

    testWidgets('a usable channel is marked as leaving the app', (
      WidgetTester tester,
    ) async {
      // A chevron would promise another screen inside Duplika; these hand off to
      // something else, and the glyph says so before the tap. An inert row carries no
      // glyph at all, because it has no destination to advertise — with only Email
      // configured, that is one glyph and not three.
      await open(tester);

      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('Email opens a composer for the support address', (
      WidgetTester tester,
    ) async {
      await open(tester);

      await tester.tap(find.text('Send us an email'));
      await tester.pumpAndSettle();

      expect(opened, hasLength(1));
      expect(opened.single.scheme, 'mailto');
      expect(opened.single.path, 'support@tdevs.co');
    });

    testWidgets('an unconfigured channel says so and opens nothing', (
      WidgetTester tester,
    ) async {
      // No WhatsApp number and no Telegram handle are set yet. Both rows stay visible
      // and inert rather than vanishing, so the gap is legible.
      await open(tester);

      expect(controller.hasWhatsApp, isFalse);
      expect(controller.hasTelegram, isFalse);
      expect(find.text('Not set up yet'), findsNWidgets(2));

      await tester.tap(find.text('Chat with our support team'));
      await tester.tap(find.text('Message us on Telegram'));
      await tester.pumpAndSettle();

      expect(opened, isEmpty);
    });

    testWidgets('a channel that will not open is reported, not swallowed', (
      WidgetTester tester,
    ) async {
      openSucceeds = false;
      await open(tester);

      await tester.tap(find.text('Send us an email'));
      await tester.pumpAndSettle();

      expect(find.textContaining('support@tdevs.co'), findsWidgets);
    });
  });

  group('LanguageView', () {
    late InMemoryProfileStorage storage;
    late SettingsController controller;

    Future<void> open(WidgetTester tester) async {
      // Taller than a phone so the whole list builds and any row can be found.
      tester.view.physicalSize = const Size(390 * 3, 3000 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      controller = SettingsController(
        diagnostics: DiagnosticsRepository(native: FakeNativeDiagnostics()),
        store: SettingsStore(storage: storage),
        openUrl: (Uri _) async => true,
      );
      Get.put<SettingsController>(controller);
      addTearDown(Get.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (BuildContext context, Widget? child) => MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LanguageView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      storage = InMemoryProfileStorage();
    });

    testWidgets('lists System default first, then every language', (
      WidgetTester tester,
    ) async {
      await open(tester);

      expect(find.text('System default'), findsOneWidget);
      expect(find.text('Use your device language'), findsOneWidget);
      for (final AppLanguage language in AppLanguages.all) {
        // findsWidgets, not findsOneWidget: English names itself 'English' in both
        // rows of its own entry, so its name legitimately appears twice.
        expect(
          find.text(language.nativeName),
          findsWidgets,
          reason: language.tag,
        );
      }
      expect(find.byType(Radio<bool>), findsNWidgets(AppLanguages.all.length + 1));
    });

    testWidgets('names each language in itself and in English', (
      WidgetTester tester,
    ) async {
      await open(tester);

      expect(find.text('日本語'), findsOneWidget);
      expect(find.text('Japanese'), findsOneWidget);
      expect(find.text('繁體中文（香港）'), findsOneWidget);
      expect(find.text('Chinese (Traditional, Hong Kong)'), findsOneWidget);
    });

    testWidgets('says what the choice governs', (WidgetTester tester) async {
      await open(tester);

      expect(find.text('Choose the language used in Duplika.'), findsOneWidget);
      expect(find.text('Language changes apply immediately.'), findsOneWidget);
    });

    testWidgets('search narrows by English name', (WidgetTester tester) async {
      await open(tester);

      await tester.enterText(find.byType(TextField), 'japan');
      await tester.pumpAndSettle();

      expect(find.text('日本語'), findsOneWidget);
      expect(find.text('Deutsch'), findsNothing);
      expect(find.text('System default'), findsNothing);
      expect(find.byType(Radio<bool>), findsOneWidget, reason: 'one row left');
    });

    testWidgets('search narrows by native name and by tag', (
      WidgetTester tester,
    ) async {
      await open(tester);

      await tester.enterText(find.byType(TextField), 'Русский');
      await tester.pumpAndSettle();
      expect(find.text('Russian'), findsOneWidget);
      expect(find.text('Deutsch'), findsNothing);

      await tester.enterText(find.byType(TextField), 'uk');
      await tester.pumpAndSettle();
      expect(find.text('Українська'), findsOneWidget);
    });

    testWidgets('System default answers the search too', (
      WidgetTester tester,
    ) async {
      // It is a row in the same list, so a query that describes it must not empty the
      // screen.
      await open(tester);

      await tester.enterText(find.byType(TextField), 'device');
      await tester.pumpAndSettle();

      expect(find.text('System default'), findsOneWidget);
    });

    testWidgets('a search that matches nothing says so', (
      WidgetTester tester,
    ) async {
      await open(tester);

      await tester.enterText(find.byType(TextField), 'klingon');
      await tester.pumpAndSettle();

      expect(find.textContaining('No language matches'), findsOneWidget);
      expect(find.text('English'), findsNothing);
    });

    testWidgets('clearing the search brings the whole list back', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.enterText(find.byType(TextField), 'japan');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      expect(find.text('System default'), findsOneWidget);
      expect(find.text('Deutsch'), findsOneWidget);
      expect(find.byType(Radio<bool>), findsNWidgets(AppLanguages.all.length + 1));
    });

    testWidgets('tapping a language applies it and stores it', (
      WidgetTester tester,
    ) async {
      await open(tester);

      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();

      expect(controller.language.value?.tag, 'de');
      expect(controller.language.value?.locale, const Locale('de'));
      expect(storage.values[SettingsStore.languageKey], 'de');
    });

    testWidgets('the selected row is the only one selected', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();

      final Iterable<Radio<bool>> radios =
          tester.widgetList<Radio<bool>>(find.byType(Radio<bool>));
      // Each row carries its own single-value group, so exactly one group is on.
      final int selected = tester
          .widgetList<RadioGroup<bool>>(find.byType(RadioGroup<bool>))
          .where((RadioGroup<bool> group) => group.groupValue == true)
          .length;
      expect(radios, hasLength(AppLanguages.all.length + 1));
      expect(selected, 1);
    });

    testWidgets('choosing System default again clears the stored language', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('System default'));
      await tester.pumpAndSettle();

      expect(controller.language.value, isNull);
      expect(storage.values.containsKey(SettingsStore.languageKey), isFalse);
    });
  });
}
