import 'package:duplika/app/theme/app_theme.dart';
import 'package:duplika/data/models/engine_result.dart';
import 'package:duplika/core/virtualization/real_virtualization_engine.dart';
import 'package:duplika/data/models/space_identity.dart';
import 'package:duplika/data/models/virtual_profile_model.dart';
import 'package:duplika/data/repositories/virtual_profile_repository.dart';
import 'package:duplika/features/home/controllers/home_controller.dart';
import 'package:duplika/native/native_bridge.dart';
import 'package:duplika/features/home/widgets/clone_action_sheet.dart';
import 'package:duplika/features/home/widgets/clone_count_dialog.dart';
import 'package:duplika/features/home/widgets/clone_tile.dart';
import 'package:duplika/features/home/views/space_info_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/in_memory_profile_storage.dart';

VirtualProfileModel _profile({String profileName = 'Example'}) =>
    VirtualProfileModel(
      id: 'p1',
      packageName: 'org.example',
      appName: 'Example',
      profileName: profileName,
      createdAt: DateTime(2026),
    );

const VirtualProfileState _ready = VirtualProfileState(
  installed: true,
  running: false,
  virtualUserId: 0,
);

Future<void> _pumpTile(
  WidgetTester tester, {
  String profileName = 'Example',
  VirtualProfileState state = _ready,
  int siblingCount = 1,
  int instanceIndex = 1,
  bool canLaunch = true,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (BuildContext context, Widget? child) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            // Sized like a grid cell, which is the only place this widget is used.
            child: SizedBox(
              width: 110,
              height: 110,
              child: CloneTile(
                profile: _profile(profileName: profileName),
                state: state,
                siblingCount: siblingCount,
                instanceIndex: instanceIndex,
                canLaunch: canLaunch,
                onTap: onTap ?? () {},
                onLongPress: onLongPress ?? () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps a screen whose only job is to open the sheet, so the sheet is tested through
/// the same route the app uses rather than by constructing it directly.
CloneAction? _lastChoice;

Future<CloneAction?> _openSheet(
  WidgetTester tester, {
  VirtualProfileState state = _ready,
  int siblingCount = 1,
  int instanceIndex = 1,
}) async {
  _lastChoice = null;
  CloneAction? chosen;
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (BuildContext context, Widget? child) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () async {
                chosen = _lastChoice = await showCloneActionSheet(
                  context,
                  profile: _profile(),
                  state: state,
                  siblingCount: siblingCount,
                  instanceIndex: instanceIndex,
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
  return chosen;
}

void main() {
  group('CloneTile', () {
    testWidgets('shows the clone name', (WidgetTester tester) async {
      await _pumpTile(tester);

      expect(find.text('Example'), findsOneWidget);
    });

    testWidgets('a long name wraps to a second line instead of being cut', (
      WidgetTester tester,
    ) async {
      // A third of a phone's width is not enough for a real app name on one line, and
      // 'CABEX-FXsa…' identifies nothing. The tile is pumped at its actual grid size,
      // so this also catches the wrap overflowing the cell.
      //
      // Kept short because the test font is monospaced at the full font size, so a name
      // that wraps to two lines on a device needs three here.
      const String name = 'CABEX-FX';
      await _pumpTile(tester, profileName: name);

      expect(tester.takeException(), isNull);
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.text(name),
      );
      expect(
        paragraph.size.height,
        greaterThan(paragraph.preferredLineHeight * 1.5),
        reason: 'the name should occupy two lines',
      );
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: 'two lines should be enough for a name of this length',
      );
    });

    testWidgets('carries no compatibility marker, healthy or not', (
      WidgetTester tester,
    ) async {
      // The grid is meant to read as a home screen. A warning badge on every tile made
      // it read as a list of faults, so problems live in the long-press sheet only —
      // see the showCloneActionSheet group below.
      await _pumpTile(tester);

      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(find.byIcon(Icons.warning_amber_outlined), findsNothing);
      expect(find.byIcon(Icons.block), findsNothing);
    });

    testWidgets('numbers a clone only when it has siblings', (
      WidgetTester tester,
    ) async {
      await _pumpTile(tester);
      expect(
        find.text('1'),
        findsNothing,
        reason: 'a lone clone needs no instance number',
      );

      await _pumpTile(tester, siblingCount: 3, instanceIndex: 2);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('tapping launches, holding opens the actions', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      int holds = 0;
      await _pumpTile(tester, onTap: () => taps++, onLongPress: () => holds++);

      await tester.tap(find.byType(CloneTile));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(holds, 0);

      await tester.longPress(find.byType(CloneTile));
      await tester.pumpAndSettle();
      expect(holds, 1);
      expect(taps, 1);
    });

    testWidgets('stays interactive when the engine cannot launch it', (
      WidgetTester tester,
    ) async {
      // Dimmed, not disabled: the sheet is the only way to rename or delete a clone,
      // and losing that because the engine is down would be worse than a dim tile.
      int holds = 0;
      await _pumpTile(tester, canLaunch: false, onLongPress: () => holds++);

      await tester.longPress(find.byType(CloneTile));
      await tester.pumpAndSettle();
      expect(holds, 1);
    });

    testWidgets(
      'describes everything it encodes visually, for screen readers',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await _pumpTile(
          tester,
          state: const VirtualProfileState(
            installed: true,
            running: true,
            virtualUserId: 1,
          ),
          siblingCount: 2,
          instanceIndex: 2,
        );

        expect(
          find.bySemanticsLabel('Example, clone 2 of 2, running'),
          findsOneWidget,
        );
        semantics.dispose();
      },
    );
  });

  group('showCloneActionSheet', () {
    testWidgets('offers every action, grouped by what it costs', (
      WidgetTester tester,
    ) async {
      await _openSheet(tester);

      // The three things done *with* a clone.
      expect(find.text('Clone'), findsOneWidget);
      expect(find.text('Shortcut'), findsOneWidget);
      expect(find.text('Space info'), findsOneWidget);

      // The things done *to* it.
      expect(find.text('Manage'), findsOneWidget);
      expect(find.text('Edit name'), findsOneWidget);
      expect(find.text('Force stop'), findsOneWidget);
      expect(find.text('Clear cache'), findsOneWidget);
      expect(find.text('Clear storage'), findsOneWidget);
      expect(find.text('Share app'), findsOneWidget);

      // And the one that destroys it.
      expect(find.text('Uninstall'), findsOneWidget);
    });

    testWidgets('does not offer launch, which tapping the tile already does', (
      WidgetTester tester,
    ) async {
      await _openSheet(tester);

      expect(find.text('Launch'), findsNothing);
    });

    testWidgets('names the space rather than repeating the app name', (
      WidgetTester tester,
    ) async {
      await _openSheet(tester, instanceIndex: 2, siblingCount: 3);

      expect(find.text('Example'), findsOneWidget, reason: 'the title');
      expect(find.text('Space 2'), findsOneWidget);
    });

    testWidgets('each action closes the sheet with its own answer', (
      WidgetTester tester,
    ) async {
      // One per band, so a mis-wired tile cannot pass by borrowing its neighbour.
      for (final (String label, CloneAction expected)
          in <(String, CloneAction)>[
            ('Clone', CloneAction.clone),
            ('Space info', CloneAction.spaceInfo),
            ('Force stop', CloneAction.forceStop),
            ('Clear storage', CloneAction.clearStorage),
            ('Uninstall', CloneAction.delete),
          ]) {
        await _openSheet(tester);
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(_lastChoice, expected, reason: label);
      }
    });

    testWidgets('the close button answers nothing at all', (
      WidgetTester tester,
    ) async {
      await _openSheet(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(_lastChoice, isNull);
      expect(find.text('Manage'), findsNothing);
    });
  });

  group('SpaceInfoView', () {
    const MethodChannel channel = MethodChannel(NativeBridge.channelName);
    late Map<String, Object?> identityData;
    late List<String> identityActions;
    late bool identityFails;

    setUp(() {
      identityActions = <String>[];
      identityFails = false;
      identityData = <String, Object?>{
        'virtualUserId': 0,
        'revision': 0,
        'deviceId': '358240051111110',
        'androidId': '9774d56d682e549c',
        'serialNumber': '1234567890123456',
        'wifiMac': '02:1a:2b:3c:4d:5e',
        'bluetoothMac': '02:aa:bb:cc:dd:ee',
      };

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            if (call.method == 'spaceIdentity') {
              final Map<Object?, Object?> args =
                  call.arguments as Map<Object?, Object?>;
              final String action = args['action']! as String;
              identityActions.add(action);
              if (identityFails) {
                return <Object?, Object?>{
                  'success': false,
                  'code': 'NO_CONTAINER',
                  'message': 'This space has no container yet.',
                  'data': <Object?, Object?>{},
                };
              }
              if (action == 'regenerate') {
                identityData = <String, Object?>{
                  ...identityData,
                  'revision': (identityData['revision']! as int) + 1,
                  'deviceId': '358240059999998',
                };
              } else if (action == 'reset') {
                identityData = <String, Object?>{
                  ...identityData,
                  'revision': 0,
                  'deviceId': '358240051111110',
                };
              }
              return <Object?, Object?>{
                'success': true,
                'code': 'SPACE_IDENTITY',
                'message': 'ok',
                'data': identityData,
              };
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    Future<void> open(
      WidgetTester tester, {
      VirtualProfileState state = _ready,
      bool engineActive = true,
    }) async {
      // The page is taller than a phone, so on a phone-sized test surface a ListView
      // never builds its lower half and nothing down there can be found or tapped.
      tester.view.physicalSize = const Size(390 * 3, 2200 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final VirtualProfileRepository repository = VirtualProfileRepository(
        storage: InMemoryProfileStorage(),
      );
      final NativeBridge bridge = NativeBridge(channel: channel);
      final HomeController controller = HomeController(
        engine: RealVirtualizationEngine(
          repository: repository,
          nativeBridge: bridge,
        ),
        nativeBridge: bridge,
        repository: repository,
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (BuildContext context, Widget? child) => MaterialApp(
            theme: AppTheme.light(),
            home: SpaceInfoView(
              controller: controller,
              profile: _profile(),
              state: state,
              engineActive: engineActive,
              instanceIndex: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('reports the engine status and the container', (
      WidgetTester tester,
    ) async {
      await open(tester);

      expect(find.text('Space 1'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('ID 1'), findsOneWidget);
    });

    testWidgets('shows every identifier the space presents as its own', (
      WidgetTester tester,
    ) async {
      await open(tester);

      for (final String label in <String>[
        'Device ID',
        'Android ID',
        'Serial number',
        'Wi-Fi MAC',
        'Bluetooth MAC',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('358240051111110'), findsOneWidget);
      expect(find.text('02:1a:2b:3c:4d:5e'), findsOneWidget);
      expect(identityActions, <String>['read']);
    });

    testWidgets('makes no claim that the identifiers reach guest apps', (
      WidgetTester tester,
    ) async {
      // A guest still reads the device's own values, so the screen shows the set and
      // says nothing about it. Asserted rather than assumed: a reassurance the engine
      // cannot back would be worse than none.
      await open(tester);

      expect(SpaceIdentity.isolatedFromGuests, isFalse);
      expect(find.textContaining('isolated'), findsNothing);
      expect(find.textContaining('private to this space'), findsNothing);
    });

    testWidgets('Modify asks for a new identity and shows it', (
      WidgetTester tester,
    ) async {
      await open(tester);

      await tester.tap(find.text('Modify'));
      await tester.pumpAndSettle();

      expect(identityActions, <String>['read', 'regenerate']);
      expect(find.text('358240059999998'), findsOneWidget);
      expect(find.text('358240051111110'), findsNothing);
    });

    testWidgets('Reset waits until there is something to reset', (
      WidgetTester tester,
    ) async {
      await open(tester);

      // Revision 0 is the identity the space was born with; resetting to it is a no-op
      // dressed up as an action.
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );

      await tester.tap(find.text('Modify'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNotNull,
      );

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(identityActions, <String>['read', 'regenerate', 'reset']);
      expect(find.text('358240051111110'), findsOneWidget);
    });

    testWidgets(
      'a space with no container explains itself instead of failing',
      (WidgetTester tester) async {
        identityFails = true;
        await open(tester);

        expect(find.text('This space has no container yet.'), findsOneWidget);
        // Nothing to modify, so nothing offers to.
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
      },
    );

    testWidgets(
      'a container the engine has lost says it rebuilds, not that it failed',
      (WidgetTester tester) async {
        await open(
          tester,
          state: const VirtualProfileState(installed: false, running: false),
        );

        expect(find.text('Rebuilds on launch'), findsOneWidget);
        // The pill counts spaces, so it stays put; the status line is what changes.
        expect(find.text('ID 1'), findsOneWidget);
      },
    );

    testWidgets('a dead engine is reported as such, not as a ready clone', (
      WidgetTester tester,
    ) async {
      await open(tester, engineActive: false);

      expect(find.text('Engine unavailable'), findsOneWidget);
      expect(find.text('Active'), findsNothing);
    });
  });

  group('showCloneCountDialog', () {
    Future<int?> open(WidgetTester tester) async {
      int? chosen;
      bool answered = false;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (BuildContext context, Widget? child) => MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) => TextButton(
                  onPressed: () async {
                    chosen = await showCloneCountDialog(
                      context,
                      appName: 'Example',
                    );
                    answered = true;
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
      expect(answered, isFalse, reason: 'still open until answered');
      return chosen;
    }

    testWidgets('names the app it is about to copy', (
      WidgetTester tester,
    ) async {
      await open(tester);

      expect(find.text('Clone app'), findsOneWidget);
      expect(find.text('Create additional copies of Example.'), findsOneWidget);
      expect(find.text('Choose from 1 to 20'), findsOneWidget);
    });

    testWidgets('starts at one and steps up', (WidgetTester tester) async {
      await open(tester);
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('will not step below the minimum', (WidgetTester tester) async {
      await open(tester);

      // Disabled rather than hidden, so the control keeps its shape at the bound.
      final IconButton minus = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.remove),
          matching: find.byType(IconButton),
        ),
      );
      expect(minus.onPressed, isNull);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('will not step past the maximum', (WidgetTester tester) async {
      await open(tester);

      for (int i = 0; i < 25; i++) {
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text('20'), findsOneWidget);
      final IconButton plus = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.add),
          matching: find.byType(IconButton),
        ),
      );
      expect(plus.onPressed, isNull);
    });

    testWidgets('Cancel answers nothing, Clone answers the count', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Clone app'), findsNothing);

      await open(tester);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clone'));
      await tester.pumpAndSettle();
      expect(find.text('Clone app'), findsNothing);
    });
  });
}
