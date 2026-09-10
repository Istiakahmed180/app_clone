import 'package:duplika/app/app.dart';
import 'package:duplika/app/routes/app_routes.dart';
import 'package:duplika/core/diagnostics/diagnostic_event.dart';
import 'package:duplika/core/diagnostics/diagnostics_repository.dart';
import 'package:duplika/core/diagnostics/native_diagnostics.dart';
import 'package:duplika/core/diagnostics/system_info.dart';
import 'package:duplika/core/services/settings_store.dart';
import 'package:duplika/data/models/app_language.dart';
import 'package:duplika/features/settings/views/language_view.dart';
import 'package:duplika/l10n/app_localizations.dart';
import 'package:duplika/features/settings/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'fakes/in_memory_profile_storage.dart';

class _FakeNative extends NativeDiagnostics {
  @override
  Future<List<DiagnosticEvent>> readHistory({int limit = 2000}) async =>
      const <DiagnosticEvent>[];

  @override
  Future<SystemInfoSnapshot> systemInfo() async =>
      SystemInfoSnapshot.from(const <String, dynamic>{});
}

void main() {
  group('choosing a language', () {
    late SettingsController controller;

    /// The app's own root, so what is asserted is Duplika's localization setup rather
    /// than one rebuilt by the test.
    Future<void> pumpApp(WidgetTester tester) async {
      // Tall enough that the whole language list is laid out: a tap on a row below the
      // fold of the default test surface lands on nothing.
      tester.view.physicalSize = const Size(390 * 3, 3000 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      controller = SettingsController(
        diagnostics: DiagnosticsRepository(native: _FakeNative()),
        store: SettingsStore(storage: InMemoryProfileStorage()),
      );
      Get.put<SettingsController>(controller);
      addTearDown(Get.reset);

      await tester.pumpWidget(
        DuplikaAppRoot(settings: controller, initialRoute: AppRoutes.language),
      );
      await tester.pumpAndSettle();
    }

    /// Anchored on the screen rather than on any of its text: every string on it is
    /// translated now, so a text finder would stop resolving the moment the feature
    /// started working.
    BuildContext screen(WidgetTester tester) =>
        tester.element(find.byType(LanguageView));

    String cancelLabel(WidgetTester tester) =>
        MaterialLocalizations.of(screen(tester)).cancelButtonLabel;

    AppLocalizations l10n(WidgetTester tester) =>
        AppLocalizations.of(screen(tester));

    testWidgets('really changes the language, in Duplika and in the framework', (
      WidgetTester tester,
    ) async {
      // Both halves matter: Duplika's own strings come from its ARB files, the
      // framework's from flutter_localizations, and a locale that only moved one of
      // them is half-applied.
      await pumpApp(tester);
      expect(l10n(tester).languageTitle, 'Language');
      expect(cancelLabel(tester), 'Cancel');
      expect(find.text('Search languages'), findsOneWidget);

      // Tapped by native name, which is deliberately never translated -- it is how a
      // speaker finds their own language whatever the interface is currently in.
      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();
      expect(l10n(tester).languageTitle, 'Sprache');
      expect(cancelLabel(tester), 'Abbrechen');
      expect(find.text('Sprachen suchen'), findsOneWidget);
      expect(find.text('Systemstandard'), findsOneWidget);

      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();
      expect(l10n(tester).languageTitle, 'Язык');
      expect(cancelLabel(tester), 'Отмена');
      expect(find.text('Поиск языков'), findsOneWidget);

      await tester.tap(find.text('日本語'));
      await tester.pumpAndSettle();
      expect(l10n(tester).languageTitle, '言語');
      expect(find.text('言語を検索'), findsOneWidget);
    });

    testWidgets('every offered language resolves to a real translation', (
      WidgetTester tester,
    ) async {
      // Catches a locale that is listed but silently falls back to English -- the one
      // failure mode a picker cannot show the user.
      await pumpApp(tester);

      for (final AppLanguage language in AppLanguages.all) {
        await controller.setLanguage(language);
        await tester.pumpAndSettle();

        final BuildContext context = screen(tester);
        expect(
          Localizations.localeOf(context).languageCode,
          language.locale.languageCode,
          reason: 'the app did not switch to ${language.tag}',
        );
        if (language.locale.languageCode != 'en') {
          expect(
            MaterialLocalizations.of(context).cancelButtonLabel,
            isNot('Cancel'),
            reason: '${language.tag} has no framework translation',
          );
          expect(
            AppLocalizations.of(context).languageTitle,
            isNot('Language'),
            reason: '${language.tag} has no Duplika translation',
          );
        }
      }
    });

    testWidgets('going back to System default leaves a usable locale', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      await controller.setLanguage(AppLanguages.byTag('ja'));
      await tester.pumpAndSettle();

      await controller.setLanguage(null);
      await tester.pumpAndSettle();

      expect(controller.language.value, isNull);
      expect(cancelLabel(tester), isNotEmpty);
      expect(l10n(tester).languageTitle, isNotEmpty);
    });
  });
}
