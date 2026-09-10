import 'package:duplika/data/models/app_language.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLanguages', () {
    test('every language offered is one the framework can actually supply', () {
      // The point of the picker is that choosing a language changes something. A locale
      // flutter_localizations cannot supply would silently fall back to English, so the
      // catalogue is checked against the delegates rather than against a comment.
      for (final AppLanguage language in AppLanguages.all) {
        expect(
          GlobalMaterialLocalizations.delegate.isSupported(language.locale),
          isTrue,
          reason: 'material: ${language.tag} (${language.englishName})',
        );
        expect(
          GlobalWidgetsLocalizations.delegate.isSupported(language.locale),
          isTrue,
          reason: 'widgets: ${language.tag}',
        );
        expect(
          GlobalCupertinoLocalizations.delegate.isSupported(language.locale),
          isTrue,
          reason: 'cupertino: ${language.tag}',
        );
      }
    });

    test('no language is listed twice', () {
      final Set<String> tags =
          AppLanguages.all.map((AppLanguage l) => l.tag).toSet();

      expect(tags, hasLength(AppLanguages.all.length));
    });

    test('every language names itself and says so in English', () {
      for (final AppLanguage language in AppLanguages.all) {
        expect(language.nativeName, isNotEmpty, reason: language.tag);
        expect(language.englishName, isNotEmpty, reason: language.tag);
        expect(language.badge, isNotEmpty, reason: language.tag);
        expect(language.badge.characters.length, lessThanOrEqualTo(2),
            reason: 'the medallion holds two characters: ${language.tag}');
      }
    });

    test('a stored tag round-trips, and an unknown one means the device', () {
      for (final AppLanguage language in AppLanguages.all) {
        expect(AppLanguages.byTag(language.tag), same(language));
      }
      expect(AppLanguages.byTag('kl'), isNull);
      expect(AppLanguages.byTag(''), isNull);
      expect(AppLanguages.byTag(null), isNull);
    });

    test('search finds a row by either name and by its tag', () {
      AppLanguage find(String tag) => AppLanguages.byTag(tag)!;

      expect(find('ja').matches('japanese'), isTrue);
      expect(find('ja').matches('日本'), isTrue);
      expect(find('ja').matches('ja'), isTrue);
      expect(find('ja').matches('JAPAN'), isTrue, reason: 'case-insensitive');
      expect(find('ja').matches('korean'), isFalse);
      // An empty query is not a filter; it is the unfiltered list.
      expect(find('ja').matches('   '), isTrue);
    });

    test('both Chinese scripts are offered and are distinct', () {
      expect(AppLanguages.byTag('zh-Hans'), isNotNull);
      expect(AppLanguages.byTag('zh-Hant'), isNotNull);
      expect(AppLanguages.byTag('zh-Hant-HK'), isNotNull);
    });
  });
}
