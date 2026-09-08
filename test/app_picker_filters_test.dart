import 'package:duplika/core/virtualization/real_virtualization_engine.dart';
import 'package:duplika/data/models/installed_app_model.dart';
import 'package:duplika/data/repositories/virtual_profile_repository.dart';
import 'package:duplika/app/theme/app_theme.dart';
import 'package:duplika/features/apps/controllers/app_picker_controller.dart';
import 'package:duplika/features/apps/views/app_picker_view.dart';
import 'package:duplika/features/apps/widgets/installed_app_sheet.dart';
import 'package:duplika/native/native_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
// `assignAll` is a GetX extension on List, so this import is what makes it visible.
import 'package:get/get.dart';

import 'fakes/in_memory_profile_storage.dart';

InstalledAppModel _app({
  required String name,
  required String package,
  bool isSystem = false,
  List<String> abis = const <String>['arm64-v8a'],
  int apkCount = 1,
  DateTime? installedAt,
  DateTime? updatedAt,
}) => InstalledAppModel(
  packageName: package,
  appName: name,
  isSystem: isSystem,
  abis: abis,
  apkCount: apkCount,
  installedAt: installedAt,
  updatedAt: updatedAt,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InstalledAppModel labels', () {
    test('names the ABIs the archive actually ships, with the bitness', () {
      expect(
        _app(
          name: 'A',
          package: 'a',
          abis: const <String>['arm64-v8a'],
        ).architectureLabel,
        'ARM64 · 64-bit',
      );
      expect(
        _app(
          name: 'A',
          package: 'a',
          abis: const <String>['armeabi-v7a', 'arm64-v8a', 'x86_64'],
        ).architectureLabel,
        // Listed widest-first regardless of the order the archive returned them, so
        // two apps with the same ABIs always read the same.
        'ARM64 + ARMv7 + x86_64 · 32 + 64',
      );
      expect(
        _app(
          name: 'A',
          package: 'a',
          abis: const <String>['armeabi-v7a'],
        ).architectureLabel,
        'ARMv7 · 32-bit',
      );
    });

    test('pure bytecode is stated, not left blank', () {
      // An app with no native code runs on any device. That is an answer, and the
      // picker has a filter for it.
      final InstalledAppModel app = _app(
        name: 'A',
        package: 'a',
        abis: const <String>[],
      );
      expect(app.hasNativeCode, isFalse);
      expect(app.architectureLabel, 'No native code');
    });

    test('a split set says how many files it is', () {
      expect(_app(name: 'A', package: 'a').packageTypeLabel, 'Single APK');
      expect(
        _app(name: 'A', package: 'a', apkCount: 4).packageTypeLabel,
        'Split APK · 4 files',
      );
    });
  });

  group('AppPickerController', () {
    late AppPickerController controller;

    setUp(() {
      // Real collaborators, none of them exercised: everything under test here is a
      // pure list operation over `apps` and the filter state.
      final VirtualProfileRepository repository = VirtualProfileRepository(
        storage: InMemoryProfileStorage(),
      );
      final NativeBridge bridge = NativeBridge(
        channel: const MethodChannel(NativeBridge.channelName),
      );
      controller = AppPickerController(
        bridge: bridge,
        engine: RealVirtualizationEngine(
          repository: repository,
          nativeBridge: bridge,
        ),
        repository: repository,
      );
      controller.apps.assignAll(<InstalledAppModel>[
        _app(
          name: 'Zebra',
          package: 'com.zebra',
          installedAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 6, 1),
        ),
        _app(
          name: 'Apple',
          package: 'com.apple',
          apkCount: 3,
          abis: const <String>['armeabi-v7a', 'arm64-v8a'],
          installedAt: DateTime(2026, 3, 1),
          updatedAt: DateTime(2026, 4, 1),
        ),
        _app(
          name: 'System Thing',
          package: 'com.system',
          isSystem: true,
          abis: const <String>[],
          installedAt: DateTime(2026, 2, 1),
        ),
      ]);
      controller.clonedPackages.assignAll(<String>{'com.apple'});
    });

    List<String> names() =>
        controller.visibleApps.map((InstalledAppModel a) => a.appName).toList();

    test('sorts by name and shows everything by default', () {
      // Both defaults asserted here: a picker that silently hid system apps sent the
      // user looking for an app that was on the device all along.
      expect(controller.sort.value, AppSort.name);
      expect(controller.filter.value, AppFilter.all);
      expect(names(), <String>['Apple', 'System Thing', 'Zebra']);
    });

    test('sorts by install and update time, newest first', () {
      controller.sort.value = AppSort.recentlyInstalled;
      expect(names(), <String>['Apple', 'System Thing', 'Zebra']);

      controller.sort.value = AppSort.recentlyUpdated;
      // System Thing has no update time; unknown is not newest, so it goes last.
      expect(names(), <String>['Zebra', 'Apple', 'System Thing']);
    });

    test('separates user apps from system apps', () {
      controller.filter.value = AppFilter.userApps;
      expect(names(), <String>['Apple', 'Zebra']);

      controller.filter.value = AppFilter.systemApps;
      expect(names(), <String>['System Thing']);
    });

    test('filters on whether the app already has a clone', () {
      controller.filter.value = AppFilter.alreadyAdded;
      expect(names(), <String>['Apple']);

      controller.filter.value = AppFilter.notAdded;
      expect(names(), <String>['System Thing', 'Zebra']);
    });

    test('architecture filters are exclusive, not "contains"', () {
      // A 32+64 app is not an answer to "show me 32-bit apps": the point of the filter
      // is to find the ones that only run one way.
      controller.architecture.value = ArchitectureFilter.only64Bit;
      expect(names(), <String>['Zebra']);

      controller.architecture.value = ArchitectureFilter.both;
      expect(names(), <String>['Apple']);

      controller.architecture.value = ArchitectureFilter.only32Bit;
      expect(names(), isEmpty);

      controller.architecture.value = ArchitectureFilter.noNativeCode;
      expect(names(), <String>['System Thing']);
    });

    test('filters on package layout', () {
      controller.packageType.value = PackageTypeFilter.split;
      expect(names(), <String>['Apple']);

      controller.packageType.value = PackageTypeFilter.single;
      expect(names(), <String>['System Thing', 'Zebra']);
    });

    test('filters combine with the search rather than replacing it', () {
      controller.query.value = 'e';
      controller.filter.value = AppFilter.notAdded;
      expect(names(), <String>['System Thing', 'Zebra']);

      controller.packageType.value = PackageTypeFilter.split;
      expect(names(), isEmpty);
    });

    test('only a name sort is grouped by letter', () {
      expect(controller.isAlphabetical, isTrue);
      expect(controller.sections.map((AppSection s) => s.letter), <String>[
        'A',
        'S',
        'Z',
      ]);

      controller.sort.value = AppSort.recentlyInstalled;
      expect(controller.isAlphabetical, isFalse);
      // One unlabelled group, so the time order survives.
      expect(controller.sections, hasLength(1));
      expect(controller.sections.single.letter, isEmpty);
      expect(controller.sections.single.apps, hasLength(3));
    });

    test('quick picks show installed well-known apps, in a fixed order', () {
      controller.apps.assignAll(<InstalledAppModel>[
        _app(name: 'Telegram', package: 'org.telegram.messenger'),
        _app(name: 'Facebook', package: 'com.facebook.katana'),
        _app(name: 'Something Else', package: 'com.example.other'),
      ]);

      expect(
        controller.quickPicks.map((InstalledAppModel a) => a.appName),
        <String>['Facebook', 'Telegram'],
        reason: 'the order is the curated one, not the device list order',
      );
    });

    test('a quick pick that is not installed is simply absent', () {
      controller.apps.assignAll(<InstalledAppModel>[
        _app(name: 'Something Else', package: 'com.example.other'),
      ]);

      expect(controller.quickPicks, isEmpty);
    });

    test('a clone in flight is announced per package, not globally', () {
      // Per package because the picker draws the spinner on the row it belongs to, so
      // a single "busy" flag could not say which app is being cloned.
      expect(controller.cloning, isEmpty);
      controller.cloning.add('com.apple');
      expect(controller.cloning.contains('com.apple'), isTrue);
      expect(controller.cloning.contains('com.zebra'), isFalse);
    });
  });

  group('showInstalledAppSheet', () {
    InstalledAppAction? chosen;

    setUp(() => chosen = null);

    Future<void> open(WidgetTester tester, {int existingClones = 0}) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (BuildContext context, Widget? child) => MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) => TextButton(
                  onPressed: () async {
                    chosen = await showInstalledAppSheet(
                      context,
                      app: _app(
                        name: 'Skill Track',
                        package: 'com.tdevs.skilltrack',
                      ),
                      existingClones: existingClones,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('identifies the app it is about, not just its name', (
      WidgetTester tester,
    ) async {
      // The sheet covers the row it came from, so the two facts the row showed have to
      // be here too or there is nothing left to check against.
      await open(tester);

      expect(find.text('Skill Track'), findsOneWidget);
      expect(find.text('com.tdevs.skilltrack'), findsOneWidget);
      expect(find.text('ARM64 · 64-bit'), findsOneWidget);
      expect(find.text('Single APK'), findsOneWidget);
    });

    testWidgets('offers exactly the three actions', (
      WidgetTester tester,
    ) async {
      await open(tester);

      expect(find.text('Add clone'), findsOneWidget);
      expect(find.text('Share app'), findsOneWidget);
      expect(find.text('App details'), findsOneWidget);
      // Nothing else: the row used to be a one-way trip into cloning, and the point of
      // the sheet is that those three are the whole set.
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          // The bordered container each action row draws; the close button has none.
          matching: find.byType(Ink),
        ),
        findsNWidgets(3),
      );
    });

    testWidgets('says "another" only when there is already one', (
      WidgetTester tester,
    ) async {
      await open(tester, existingClones: 2);
      expect(find.text('Add another'), findsOneWidget);
      expect(find.text('Add clone'), findsNothing);
    });

    testWidgets('each row answers with its own action', (
      WidgetTester tester,
    ) async {
      // One per row, so a mis-wired row cannot pass by borrowing its neighbour.
      for (final (String label, InstalledAppAction expected)
          in <(String, InstalledAppAction)>[
            ('Add clone', InstalledAppAction.addClone),
            ('Share app', InstalledAppAction.shareApp),
            ('App details', InstalledAppAction.appDetails),
          ]) {
        chosen = null;
        await open(tester);
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(chosen, expected, reason: label);
      }
    });

    testWidgets('closing answers nothing', (WidgetTester tester) async {
      await open(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(chosen, isNull);
      expect(find.text('Add clone'), findsNothing);
    });
  });

  group('AppPickerView rows', () {
    const MethodChannel channel = MethodChannel(NativeBridge.channelName);

    Map<Object?, Object?> ok(Map<String, Object?> data) => <Object?, Object?>{
      'success': true,
      'code': 'OK',
      'message': 'ok',
      'data': data,
    };

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            switch (call.method) {
              case 'listInstalledApps':
                return ok(<String, Object?>{
                  'apps': <Object?>[
                    <Object?, Object?>{
                      'packageName': 'com.example.one',
                      'appName': 'Alpha',
                      'system': false,
                      'abis': <Object?>['arm64-v8a'],
                      'apkCount': 1,
                    },
                    <Object?, Object?>{
                      'packageName': 'com.example.two',
                      'appName': 'Beta',
                      'system': false,
                      'abis': <Object?>['arm64-v8a'],
                      'apkCount': 1,
                    },
                    // A curated quick pick, so the Popular row has a card in it.
                    <Object?, Object?>{
                      'packageName': 'org.telegram.messenger',
                      'appName': 'Telegram',
                      'system': false,
                      'abis': <Object?>['arm64-v8a'],
                      'apkCount': 1,
                    },
                  ],
                });
              default:
                return ok(<String, Object?>{});
            }
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      Get.reset();
    });

    Future<AppPickerController> pumpPicker(WidgetTester tester) async {
      final VirtualProfileRepository repository = VirtualProfileRepository(
        storage: InMemoryProfileStorage(),
      );
      final NativeBridge bridge = NativeBridge(channel: channel);
      final AppPickerController controller = AppPickerController(
        bridge: bridge,
        engine: RealVirtualizationEngine(
          repository: repository,
          nativeBridge: bridge,
        ),
        repository: repository,
      );
      Get.put<AppPickerController>(controller);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (BuildContext context, Widget? child) =>
              const GetMaterialApp(home: AppPickerView()),
        ),
      );
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('every row carries the add mark', (WidgetTester tester) async {
      await pumpPicker(tester);

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      // One per row, and no compatibility glyph in their place: the mark says what the
      // row does, which is the same for every row.
      // Three rows plus one Popular card, each with its own mark.
      expect(find.byIcon(Icons.add), findsNWidgets(4));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a quick pick being cloned shows a spinner on its card', (
      WidgetTester tester,
    ) async {
      final AppPickerController controller = await pumpPicker(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);

      controller.cloning.add('org.telegram.messenger');
      await tester.pump();

      // Two: the card in the Popular row and the app's own row in the list below. Both
      // are the same app being cloned, and both said `+` a moment ago.
      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    });

    testWidgets('the row being cloned shows a spinner, and only that row', (
      WidgetTester tester,
    ) async {
      final AppPickerController controller = await pumpPicker(tester);

      controller.cloning.add('com.example.one');
      await tester.pump();

      // On the row the user tapped: which app is being cloned is the part they need to
      // see, and a bar across the bottom of the screen does not say it.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.byIcon(Icons.add),
        findsNWidgets(3),
        reason: 'the other rows and the Popular card keep their plus',
      );
    });
  });
}
