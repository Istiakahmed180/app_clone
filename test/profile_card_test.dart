import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_space_demo/data/models/compatibility_report.dart';
import 'package:virtual_space_demo/data/models/engine_result.dart';
import 'package:virtual_space_demo/data/models/virtual_profile_model.dart';
import 'package:virtual_space_demo/widgets/profile_card.dart';

VirtualProfileModel _profile() => VirtualProfileModel(
      id: 'p1',
      packageName: 'org.example',
      appName: 'Example',
      profileName: 'Example',
      createdAt: DateTime(2026),
    );

Future<void> _pump(
  WidgetTester tester, {
  List<CompatibilityFinding> warnings = const <CompatibilityFinding>[],
  int siblingCount = 1,
  int instanceIndex = 1,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (BuildContext context, Widget? child) => MaterialApp(
        home: Scaffold(
          body: ProfileCard(
            profile: _profile(),
            state: const VirtualProfileState(installed: true, running: false, virtualUserId: 0),
            canLaunch: true,
            onLaunch: () {},
            onAction: (_) {},
            siblingCount: siblingCount,
            instanceIndex: instanceIndex,
            warnings: warnings,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a healthy clone shows no warning', (WidgetTester tester) async {
    await _pump(tester);

    expect(find.text('Ready'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsNothing);
    expect(find.byIcon(Icons.block), findsNothing);
  });

  testWidgets('a non-blocking problem is surfaced as a warning', (WidgetTester tester) async {
    await _pump(
      tester,
      warnings: const <CompatibilityFinding>[
        CompatibilityFinding(
          code: 'PERMISSIONS_REQUIRED',
          message: 'The clone needs 2 permission(s).',
          blocking: false,
        ),
      ],
    );

    expect(find.text('The clone needs 2 permission(s).'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
  });

  testWidgets('a blocking problem wins over a lesser one', (WidgetTester tester) async {
    await _pump(
      tester,
      warnings: const <CompatibilityFinding>[
        CompatibilityFinding(
          code: 'PERMISSIONS_REQUIRED',
          message: 'Needs permissions.',
          blocking: false,
        ),
        CompatibilityFinding(
          code: 'SECURE_ENV_REQUIRED',
          message: 'This application requires a secure environment.',
          blocking: true,
        ),
      ],
    );

    // The serious one is the one the user must see.
    expect(find.text('This application requires a secure environment.'), findsOneWidget);
    expect(find.text('Needs permissions.'), findsNothing);
    expect(find.byIcon(Icons.block), findsOneWidget);
  });

  testWidgets('multi-instance clones are labelled by position', (WidgetTester tester) async {
    await _pump(tester, siblingCount: 3, instanceIndex: 2);

    expect(find.text('Example · clone 2 of 3'), findsOneWidget);
  });
}
