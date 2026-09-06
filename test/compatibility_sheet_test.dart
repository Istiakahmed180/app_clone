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

  testWidgets(
    'the GMS opt-in appears when the app needs Google Play services',
    (WidgetTester tester) async {
      await _pump(tester, _gmsReport);
      expect(find.text('Install Google Play services in this clone'), findsOneWidget);
    },
  );

  testWidgets(
    'the GMS opt-in is hidden for an app that does not need it',
    (WidgetTester tester) async {
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
      expect(find.text('Install Google Play services in this clone'), findsNothing);
    },
  );

  testWidgets(
    'GMS provisioning is off unless the user ticks the box',
    (WidgetTester tester) async {
      late CloneDecision decision;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (BuildContext context, Widget? child) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) => ElevatedButton(
                  onPressed: () async {
                    decision = await CompatibilitySheet.show(
                      context,
                      appName: 'Example',
                      report: _gmsReport,
                      existingClones: 0,
                      onGrantPermissions: () async => _gmsReport,
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
      // Add clone without touching the checkbox.
      await tester.tap(find.widgetWithText(FilledButton, 'Add clone'));
      await tester.pumpAndSettle();

      expect(decision.proceed, isTrue);
      expect(decision.installGms, isFalse,
          reason: 'provisioning must default off even for a GMS app');
    },
  );

  testWidgets(
    'ticking the box opts this clone into GMS provisioning',
    (WidgetTester tester) async {
      late CloneDecision decision;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (BuildContext context, Widget? child) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) => ElevatedButton(
                  onPressed: () async {
                    decision = await CompatibilitySheet.show(
                      context,
                      appName: 'Example',
                      report: _gmsReport,
                      existingClones: 0,
                      onGrantPermissions: () async => _gmsReport,
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
      await tester.tap(find.text('Install Google Play services in this clone'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add clone'));
      await tester.pumpAndSettle();

      expect(decision.proceed, isTrue);
      expect(decision.installGms, isTrue);
    },
  );
}

  const CompatibilityReport _gmsReport = CompatibilityReport(
    packageName: 'org.example.gms',
    verdict: CompatibilityVerdict.limited,
    findings: <CompatibilityFinding>[
      CompatibilityFinding(
        code: 'REQUIRES_GMS',
        message: 'This app relies on Google Play Services.',
        blocking: false,
      ),
    ],
    bridgeablePermissions: <String>[],
    missingPermissions: <String>[],
    requiresGms: true,
  );

