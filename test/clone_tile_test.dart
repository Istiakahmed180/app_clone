import 'package:duplika/app/theme/app_theme.dart';
import 'package:duplika/data/models/compatibility_report.dart';
import 'package:duplika/data/models/engine_result.dart';
import 'package:duplika/data/models/virtual_profile_model.dart';
import 'package:duplika/features/home/widgets/clone_action_sheet.dart';
import 'package:duplika/features/home/widgets/clone_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

VirtualProfileModel _profile({String profileName = 'Example'}) => VirtualProfileModel(
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
  List<CompatibilityFinding> warnings = const <CompatibilityFinding>[],
  int siblingCount = 1,
  int instanceIndex = 1,
  bool needsPermissions = false,
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
                warnings: warnings,
                siblingCount: siblingCount,
                instanceIndex: instanceIndex,
                needsPermissions: needsPermissions,
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
Future<CloneAction?> _openSheet(
  WidgetTester tester, {
  VirtualProfileState state = _ready,
  List<CompatibilityFinding> warnings = const <CompatibilityFinding>[],
  int siblingCount = 1,
  int instanceIndex = 1,
  bool needsPermissions = false,
  bool canLaunch = true,
}) async {
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
                chosen = await showCloneActionSheet(
                  context,
                  profile: _profile(),
                  state: state,
                  warnings: warnings,
                  siblingCount: siblingCount,
                  instanceIndex: instanceIndex,
                  needsPermissions: needsPermissions,
                  canLaunch: canLaunch,
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
    testWidgets('shows the clone name and no marker when healthy',
        (WidgetTester tester) async {
      await _pumpTile(tester);

      expect(find.text('Example'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(find.byIcon(Icons.block), findsNothing);
    });

    testWidgets('numbers a clone only when it has siblings', (WidgetTester tester) async {
      await _pumpTile(tester);
      expect(find.text('1'), findsNothing,
          reason: 'a lone clone needs no instance number');

      await _pumpTile(tester, siblingCount: 3, instanceIndex: 2);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('marks a non-blocking problem with a warning',
        (WidgetTester tester) async {
      await _pumpTile(
        tester,
        warnings: const <CompatibilityFinding>[_permissionsWarning],
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.block), findsNothing);
    });

    testWidgets('a blocking problem wins over a lesser one', (WidgetTester tester) async {
      await _pumpTile(
        tester,
        warnings: const <CompatibilityFinding>[_permissionsWarning, _blockingFinding],
      );

      // The serious one decides the marker: it is the difference between "works, with a
      // caveat" and "will not run".
      expect(find.byIcon(Icons.block), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('a clone needing permissions is marked even with no findings',
        (WidgetTester tester) async {
      await _pumpTile(tester, needsPermissions: true);

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('tapping launches, holding opens the actions',
        (WidgetTester tester) async {
      int taps = 0;
      int holds = 0;
      await _pumpTile(
        tester,
        onTap: () => taps++,
        onLongPress: () => holds++,
      );

      await tester.tap(find.byType(CloneTile));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(holds, 0);

      await tester.longPress(find.byType(CloneTile));
      await tester.pumpAndSettle();
      expect(holds, 1);
      expect(taps, 1);
    });

    testWidgets('stays interactive when the engine cannot launch it',
        (WidgetTester tester) async {
      // Dimmed, not disabled: the sheet is the only way to rename or delete a clone,
      // and losing that because the engine is down would be worse than a dim tile.
      int holds = 0;
      await _pumpTile(tester, canLaunch: false, onLongPress: () => holds++);

      await tester.longPress(find.byType(CloneTile));
      await tester.pumpAndSettle();
      expect(holds, 1);
    });

    testWidgets('describes everything it encodes visually, for screen readers',
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
        warnings: const <CompatibilityFinding>[_blockingFinding],
      );

      expect(
        find.bySemanticsLabel('Example, clone 2 of 2, running, will not run'),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  group('showCloneActionSheet', () {
    testWidgets('reports the engine status and the virtual user',
        (WidgetTester tester) async {
      await _openSheet(tester);

      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('user 0'), findsOneWidget);
    });

    testWidgets('a container the engine has lost says it rebuilds, not that it failed',
        (WidgetTester tester) async {
      await _openSheet(
        tester,
        state: const VirtualProfileState(installed: false, running: false),
      );

      expect(find.text('Rebuilds on launch'), findsOneWidget);
    });

    testWidgets('shows every finding, blocking first', (WidgetTester tester) async {
      await _openSheet(
        tester,
        warnings: const <CompatibilityFinding>[_permissionsWarning, _blockingFinding],
      );

      final double blockingY =
          tester.getTopLeft(find.text(_blockingFinding.message)).dy;
      final double lesserY =
          tester.getTopLeft(find.text(_permissionsWarning.message)).dy;
      expect(blockingY, lessThan(lesserY));
    });

    testWidgets('offers adding the clone to the home screen',
        (WidgetTester tester) async {
      expect(await _openSheet(tester), isNull);

      await tester.tap(find.text('Add to home screen'));
      await tester.pumpAndSettle();
      // The sheet closes with its answer; the caller acts on it.
      expect(find.text('Add to home screen'), findsNothing);
    });

    testWidgets('a clone missing permissions offers a way to grant them',
        (WidgetTester tester) async {
      // Warning text alone is a dead end: the guest silently gets nothing (VLC sits on
      // "Loading." with no media) and the tile alone offers no way to fix it.
      await _openSheet(tester, needsPermissions: true);

      expect(find.text('Grant permissions'), findsOneWidget);
    });

    testWidgets('a clone that needs nothing does not offer the grant action',
        (WidgetTester tester) async {
      await _openSheet(tester);

      expect(find.text('Grant permissions'), findsNothing);
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('labels a multi-instance clone by position',
        (WidgetTester tester) async {
      await _openSheet(tester, siblingCount: 3, instanceIndex: 2);

      expect(find.text('Example · clone 2 of 3'), findsOneWidget);
    });

    testWidgets('says why launch is unavailable rather than just greying it out',
        (WidgetTester tester) async {
      await _openSheet(tester, canLaunch: false);

      expect(
        find.text('The virtualization engine is not active on this device.'),
        findsOneWidget,
      );
    });
  });
}
