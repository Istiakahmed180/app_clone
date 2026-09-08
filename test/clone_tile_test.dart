import 'package:duplika/app/theme/app_theme.dart';
import 'package:duplika/data/models/compatibility_report.dart';
import 'package:duplika/data/models/engine_result.dart';
import 'package:duplika/data/models/virtual_profile_model.dart';
import 'package:duplika/features/home/widgets/clone_action_sheet.dart';
import 'package:duplika/features/home/widgets/clone_count_dialog.dart';
import 'package:duplika/features/home/widgets/clone_tile.dart';
import 'package:duplika/features/home/widgets/space_info_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

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

const CompatibilityFinding _permissionsWarning = CompatibilityFinding(
  code: 'PERMISSIONS_REQUIRED',
  message: 'The clone needs 2 permission(s).',
  blocking: false,
);

const CompatibilityFinding _blockingFinding = CompatibilityFinding(
  code: 'SECURE_ENV_REQUIRED',
  message: 'This application requires a secure environment.',
  blocking: true,
);

Future<void> _pumpTile(
  WidgetTester tester, {
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
                profile: _profile(),
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

  group('showSpaceInfoSheet', () {
    Future<bool> open(
      WidgetTester tester, {
      VirtualProfileState state = _ready,
      List<CompatibilityFinding> warnings = const <CompatibilityFinding>[],
      bool needsPermissions = false,
      bool engineActive = true,
    }) async {
      bool granted = false;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (BuildContext context, Widget? child) => MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) => TextButton(
                  onPressed: () async {
                    granted = await showSpaceInfoSheet(
                      context,
                      profile: _profile(),
                      state: state,
                      warnings: warnings,
                      needsPermissions: needsPermissions,
                      engineActive: engineActive,
                      siblingCount: 2,
                      instanceIndex: 1,
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
      return granted;
    }

    testWidgets('reports the engine status and the container', (
      WidgetTester tester,
    ) async {
      await open(tester);

      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('virtual user 0'), findsOneWidget);
      expect(find.text('org.example'), findsOneWidget);
      expect(find.text('1 of 2'), findsOneWidget);
    });

    testWidgets(
      'a container the engine has lost says it rebuilds, not that it failed',
      (WidgetTester tester) async {
        await open(
          tester,
          state: const VirtualProfileState(installed: false, running: false),
        );

        expect(find.text('Rebuilds on launch'), findsOneWidget);
        expect(find.text('not allocated yet'), findsOneWidget);
      },
    );

    testWidgets('a dead engine is reported as such, not as a ready clone', (
      WidgetTester tester,
    ) async {
      await open(tester, engineActive: false);

      expect(find.text('Engine unavailable'), findsOneWidget);
      expect(find.text('Ready'), findsNothing);
    });

    testWidgets('shows every finding, blocking first', (
      WidgetTester tester,
    ) async {
      await open(
        tester,
        warnings: const <CompatibilityFinding>[
          _permissionsWarning,
          _blockingFinding,
        ],
      );

      final double blockingY = tester
          .getTopLeft(find.text(_blockingFinding.message))
          .dy;
      final double lesserY = tester
          .getTopLeft(find.text(_permissionsWarning.message))
          .dy;
      expect(blockingY, lessThan(lesserY));
    });

    testWidgets('a clone missing permissions offers a way to grant them', (
      WidgetTester tester,
    ) async {
      // The tile carries no marker and the action sheet no status line, so this is the
      // only place the fix is reachable. Losing it would leave the warning a dead end.
      await open(tester, needsPermissions: true);

      expect(find.text('Grant permissions'), findsOneWidget);
      await tester.tap(find.text('Grant permissions'));
      await tester.pumpAndSettle();
      expect(
        find.text('Grant permissions'),
        findsNothing,
        reason: 'the sheet closes',
      );
    });

    testWidgets('a clone that needs nothing does not offer the grant action', (
      WidgetTester tester,
    ) async {
      await open(tester);

      expect(find.text('Grant permissions'), findsNothing);
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
