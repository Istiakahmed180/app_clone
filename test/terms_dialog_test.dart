import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duplika/features/onboarding/widgets/terms_dialog.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    required void Function(bool accepted) onAnswer,
    bool policiesArePlaceholders = false,
  }) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (BuildContext context, Widget? child) => MaterialApp(
          home: Scaffold(
            body: TermsDialog(
              policiesArePlaceholders: policiesArePlaceholders,
              onAccept: () => onAnswer(true),
              onDecline: () => onAnswer(false),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the disclosure names what is actually collected', (WidgetTester tester) async {
    await pumpDialog(tester, onAnswer: (_) {});

    expect(find.text('Installed applications'), findsOneWidget);
    expect(find.text('Crash logs'), findsOneWidget);
    expect(find.text('What is not collected'), findsOneWidget);
  });

  testWidgets('both answers are offered, and neither is preselected',
      (WidgetTester tester) async {
    await pumpDialog(tester, onAnswer: (_) {});

    expect(find.widgetWithText(TextButton, 'Decline'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Accept'), findsOneWidget);
  });

  testWidgets('accepting reports acceptance', (WidgetTester tester) async {
    bool? answer;
    await pumpDialog(tester, onAnswer: (bool value) => answer = value);

    await tester.tap(find.text('Accept'));
    await tester.pump();

    expect(answer, isTrue);
  });

  testWidgets('declining reports a decline, not a dismissal',
      (WidgetTester tester) async {
    bool? answer;
    await pumpDialog(tester, onAnswer: (bool value) => answer = value);

    await tester.tap(find.text('Decline'));
    await tester.pump();

    expect(answer, isFalse);
  });

  testWidgets('real policies are presented as links', (WidgetTester tester) async {
    await pumpDialog(tester, onAnswer: (_) {});

    expect(find.textContaining('Privacy Policy'), findsOneWidget);
    expect(find.textContaining('Terms of Service'), findsOneWidget);
  });

  testWidgets('unpublished policies are never presented as if they were real',
      (WidgetTester tester) async {
    await pumpDialog(tester, onAnswer: (_) {}, policiesArePlaceholders: true);

    expect(find.textContaining('not published'), findsOneWidget);
    // The whole point: no link text claiming to be the policy.
    expect(find.textContaining('Read our'), findsNothing);
  });

  testWidgets('the dialog cannot be dismissed with the back gesture',
      (WidgetTester tester) async {
    bool answered = false;
    await pumpDialog(tester, onAnswer: (_) => answered = true);

    final PopScope<Object?> scope =
        tester.widget<PopScope<Object?>>(find.byType(PopScope<Object?>));

    expect(scope.canPop, isFalse);
    expect(answered, isFalse);
  });
}
