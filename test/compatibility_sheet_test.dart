import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_space_demo/data/models/compatibility_report.dart';
import 'package:virtual_space_demo/features/apps/widgets/compatibility_sheet.dart';

Future<void> _pump(WidgetTester tester, CompatibilityReport report) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (BuildContext context, Widget? child) => MaterialApp(
        home: Scaffold(
          body: CompatibilitySheet(
            appName: 'Example',
            report: report,
            existingClones: 0,
            onGrantPermissions: () async => report,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an unsupported app cannot be cloned', (WidgetTester tester) async {
    await _pump(
      tester,
      const CompatibilityReport(
        packageName: 'org.example',
        verdict: CompatibilityVerdict.unsupported,
        findings: <CompatibilityFinding>[
          CompatibilityFinding(
            code: 'SECURE_ENV_REQUIRED',
            message: 'This application requires a secure environment.',
            blocking: true,
          ),
        ],
        bridgeablePermissions: <String>[],
        missingPermissions: <String>[],
        requiresGms: false,
      ),
    );

    expect(find.text('Unsupported'), findsOneWidget);
    expect(find.text('Cannot clone'), findsOneWidget);

    final Finder button = find.widgetWithText(FilledButton, 'Cannot clone');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
  });

  testWidgets('an analysed clean app reports no known problems', (WidgetTester tester) async {
    await _pump(
      tester,
      const CompatibilityReport(
        packageName: 'org.example',
        verdict: CompatibilityVerdict.supported,
        findings: <CompatibilityFinding>[],
        bridgeablePermissions: <String>[],
        missingPermissions: <String>[],
        requiresGms: false,
      ),
    );

    expect(find.text('Supported'), findsOneWidget);
    expect(find.text('No known compatibility problems.'), findsOneWidget);
  });

  testWidgets(
    'an APK that was never analysed must not be presented as problem-free',
    (WidgetTester tester) async {
      // This is what the import flow hands the sheet for an APK that is not installed
      // on this device, so there was nothing for the analyzer to inspect.
      await _pump(tester, CompatibilityReport.unknown);

      expect(
        find.text('No known compatibility problems.'),
        findsNothing,
        reason: 'claiming an unanalysed APK is clean overstates what is known',
      );
      expect(find.text('Supported'), findsNothing);
    },
  );
}
