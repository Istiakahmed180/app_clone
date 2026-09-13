import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duplika/data/models/compatibility_report.dart';
import 'package:duplika/features/apps/widgets/compatibility_sheet.dart';

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
    'the retired GMS provisioning opt-in is gone, even for a GMS-dependent app',
    (WidgetTester tester) async {
      // Regression guard for Level 10 Phase 7. The checkbox provisioned a container-local
      // copy of Play services, which shadowed the host passthrough that actually works and
      // could not bootstrap its own Chimera modules. If it ever reappears, this fails.
      await _pump(tester, _gmsReport);

      expect(find.text('Install Google Play services in this clone'), findsNothing);
      expect(find.byType(CheckboxListTile), findsNothing);
    },
  );

  testWidgets(
    'a GMS-dependent app still gets its compatibility warning',
    (WidgetTester tester) async {
      // The opt-in went; the warning must not. Removing the checkbox must not quietly
      // remove the user's only signal that the app depends on Google Play services.
      await _pump(tester, _gmsReport);

      expect(find.text('This app relies on Google Play Services.'), findsOneWidget);
    },
  );

  testWidgets(
    'a GMS-dependent app can still be cloned',
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
      await tester.tap(find.widgetWithText(FilledButton, 'Add clone'));
      await tester.pumpAndSettle();

      expect(decision.proceed, isTrue);
    },
  );

  testWidgets(
    'a push-dependent app is warned about before it is cloned, and can still be cloned',
    (WidgetTester tester) async {
      // The failure this warns about is measured, not predicted:
      // evidence/physical-android15/fcm-cabexfx/. Play services refuses to register a
      // clone for push, and the app then stalls for about thirty seconds before giving
      // up. Without this warning that stall is all the user sees.
      await _pump(
        tester,
        const CompatibilityReport(
          packageName: 'org.example.push',
          verdict: CompatibilityVerdict.limited,
          findings: <CompatibilityFinding>[
            CompatibilityFinding(
              code: 'PUSH_UNSUPPORTED',
              message: 'Push notifications will not work in a clone. Google Play services '
                  'will not register this app for push while it runs under Duplika\'s '
                  'identity, so messages sent to the clone never arrive.',
              blocking: false,
            ),
          ],
          bridgeablePermissions: <String>[],
          missingPermissions: <String>[],
          requiresGms: true,
        ),
      );

      expect(find.textContaining('Push notifications will not work'), findsOneWidget);
      // Not blocking: the app is usable, it just never receives messages. Refusing to
      // clone it would be a bigger lie than the missing warning was.
      final Finder button = find.widgetWithText(FilledButton, 'Add clone');
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
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

