import 'package:flutter/widgets.dart';

/// One language the app can be asked to run in.
///
/// Both names are carried because the list has to be usable by someone who cannot read
/// the language they are looking for as much as by someone who can: the native name is
/// how a speaker finds their own language, the English name is how everyone else does.
@immutable
class AppLanguage {
  const AppLanguage({
    required this.locale,
    required this.nativeName,
    required this.englishName,
    required this.badge,
  });

  final Locale locale;

  /// The language's name in itself — 日本語, not Japanese.
  final String nativeName;

  final String englishName;

  /// One or two characters for the medallion, in the language's own script. A flag
  /// would be wrong here: a language is not a country, and several of these are spoken
  /// in many.
  final String badge;

  /// What [locale] is stored and read back as. `Locale.toString` already uses this
  /// form, but naming it makes the storage format deliberate rather than incidental.
  String get tag => locale.toLanguageTag();

  /// Whether this entry is what [query] is looking for. Matches either name and the
  /// tag, so 'chinese', '中文' and 'zh' all find the same rows.
  bool matches(String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    return nativeName.toLowerCase().contains(needle) ||
        englishName.toLowerCase().contains(needle) ||
        tag.toLowerCase().contains(needle);
  }
}

/// The languages offered, in the order the screen lists them.
///
/// Every locale here must be one `flutter_localizations` can actually supply, so that
/// choosing it changes the framework's own strings and its date and number formats.
/// `language_catalogue_test.dart` asserts that for each entry rather than trusting this
/// comment.
abstract final class AppLanguages {
  static const List<AppLanguage> all = <AppLanguage>[
    AppLanguage(
      locale: Locale('en'),
      nativeName: 'English',
      englishName: 'English',
      badge: 'A',
    ),
    AppLanguage(
      locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      nativeName: '简体中文',
      englishName: 'Chinese (Simplified)',
      badge: '简',
    ),
    AppLanguage(
      locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      nativeName: '繁體中文',
      englishName: 'Chinese (Traditional)',
      badge: '繁',
    ),
    AppLanguage(
      locale: Locale('hi'),
      nativeName: 'हिन्दी',
      englishName: 'Hindi',
      badge: 'हि',
    ),
    AppLanguage(
      locale: Locale('id'),
      nativeName: 'Bahasa Indonesia',
      englishName: 'Indonesian',
      badge: 'ID',
    ),
    AppLanguage(
      locale: Locale('vi'),
      nativeName: 'Tiếng Việt',
      englishName: 'Vietnamese',
      badge: 'Vi',
    ),
    AppLanguage(
      locale: Locale('ja'),
      nativeName: '日本語',
      englishName: 'Japanese',
      badge: '日',
    ),
    AppLanguage(
      locale: Locale('ko'),
      nativeName: '한국어',
      englishName: 'Korean',
      badge: '한',
    ),
    AppLanguage(
      locale: Locale('de'),
      nativeName: 'Deutsch',
      englishName: 'German',
      badge: 'De',
    ),
    AppLanguage(
      locale: Locale('es'),
      nativeName: 'Español',
      englishName: 'Spanish',
      badge: 'Es',
    ),
    AppLanguage(
      locale: Locale('pt', 'BR'),
      nativeName: 'Português (Brasil)',
      englishName: 'Portuguese (Brazil)',
      badge: 'Pt',
    ),
    AppLanguage(
      locale: Locale('it'),
      nativeName: 'Italiano',
      englishName: 'Italian',
      badge: 'It',
    ),
    AppLanguage(
      locale: Locale('ms'),
      nativeName: 'Bahasa Melayu',
      englishName: 'Malay',
      badge: 'Ms',
    ),
    AppLanguage(
      locale: Locale('no'),
      nativeName: 'Norsk',
      englishName: 'Norwegian',
      badge: 'No',
    ),
    AppLanguage(
      locale: Locale('ru'),
      nativeName: 'Русский',
      englishName: 'Russian',
      badge: 'Ру',
    ),
    AppLanguage(
      locale: Locale('uk'),
      nativeName: 'Українська',
      englishName: 'Ukrainian',
      badge: 'Ук',
    ),
    AppLanguage(
      locale: Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'HK',
      ),
      nativeName: '繁體中文（香港）',
      englishName: 'Chinese (Traditional, Hong Kong)',
      badge: '港',
    ),
  ];

  /// The locales handed to `MaterialApp.supportedLocales`.
  static List<Locale> get locales =>
      all.map((AppLanguage language) => language.locale).toList(growable: false);

  /// The entry for a stored tag, or null when the tag is unknown — which is what a
  /// preference written by a build that offered a language this one does not looks
  /// like, and must mean "follow the device" rather than a crash.
  static AppLanguage? byTag(String? tag) {
    if (tag == null || tag.isEmpty) {
      return null;
    }
    for (final AppLanguage language in all) {
      if (language.tag == tag) {
        return language;
      }
    }
    return null;
  }
}
