import 'dart:convert';
import 'dart:io';

import 'package:duplika/data/models/app_language.dart';
import 'package:duplika/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the translation files against drift.
///
/// Adding a string to the English template without translating it makes that screen
/// fall back to English in sixteen other languages, which nothing at runtime reports.
/// These tests are the report.
void main() {
  final Directory l10nDir = Directory('lib/l10n');

  Map<String, String> readArb(String file) {
    final Map<String, Object?> raw =
        jsonDecode(File('${l10nDir.path}/$file').readAsStringSync())
            as Map<String, Object?>;
    return <String, String>{
      for (final MapEntry<String, Object?> e in raw.entries)
        if (!e.key.startsWith('@')) e.key: '${e.value}',
    };
  }

  List<String> arbFiles() => l10nDir
      .listSync()
      .whereType<File>()
      .map((File f) => f.uri.pathSegments.last)
      .where((String name) => name.endsWith('.arb'))
      .toList()
    ..sort();

  final Map<String, String> template = readArb('app_en.arb');

  test('the template has strings to translate', () {
    expect(template, isNotEmpty);
  });

  test('every language in the picker has a translation file', () {
    final Set<String> files = arbFiles().toSet();

    for (final AppLanguage language in AppLanguages.all) {
      // Flutter resolves a variant to its base file, so either satisfies the offer.
      final String exact = 'app_${language.tag.replaceAll('-', '_')}.arb';
      final String base = 'app_${language.locale.languageCode}.arb';
      expect(
        files.contains(exact) || files.contains(base),
        isTrue,
        reason: 'no ARB for ${language.tag} (${language.englishName})',
      );
    }
  });

  test('every translation file carries every key, and no extras', () {
    for (final String file in arbFiles()) {
      if (file == 'app_en.arb') {
        continue;
      }
      final Map<String, String> table = readArb(file);
      expect(
        table.keys.toSet(),
        template.keys.toSet(),
        reason: '$file does not match the English template',
      );
    }
  });

  test('no translation is left as the English string', () {
    // Names that are the same word in every language are exempt: a brand is not
    // translated, and 'Telegram' is 'Telegram'.
    const Set<String> sameEverywhere = <String>{
      'contactWhatsApp',
      'contactTelegram',
      'settingsCopyright',
    };

    for (final String file in arbFiles()) {
      if (file == 'app_en.arb') {
        continue;
      }
      final Map<String, String> table = readArb(file);
      final List<String> untranslated = <String>[
        for (final String key in template.keys)
          if (!sameEverywhere.contains(key) && table[key] == template[key]) key,
      ];
      // Some overlap is legitimate ('Email' in several Latin-script languages), so this
      // asserts a file is not wholesale English rather than demanding every string differ.
      expect(
        untranslated.length,
        lessThan(template.length ~/ 4),
        reason: '$file looks largely untranslated: $untranslated',
      );
    }
  });

  test('every placeholder survives translation', () {
    final RegExp placeholder = RegExp(r'\{(\w+)\}');
    Set<String> namesIn(String value) =>
        placeholder.allMatches(value).map((RegExpMatch m) => m.group(1)!).toSet();

    for (final String file in arbFiles()) {
      if (file == 'app_en.arb') {
        continue;
      }
      final Map<String, String> table = readArb(file);
      for (final MapEntry<String, String> entry in template.entries) {
        final String? translated = table[entry.key];
        if (translated == null) {
          continue;
        }
        expect(
          namesIn(translated),
          namesIn(entry.value),
          reason: '$file: ${entry.key} lost or renamed a placeholder',
        );
      }
    }
  });

  test('the generated delegate supports every language offered', () {
    for (final AppLanguage language in AppLanguages.all) {
      expect(
        AppLocalizations.delegate.isSupported(language.locale),
        isTrue,
        reason: 'AppLocalizations cannot supply ${language.tag}',
      );
    }
    // And English, which is the fallback rather than an offered row.
    expect(AppLocalizations.delegate.isSupported(const Locale('en')), isTrue);
  });
}
