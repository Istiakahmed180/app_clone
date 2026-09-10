// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get settingsTitle => 'Налаштування';

  @override
  String get settingsSectionSupport => 'Підтримка';

  @override
  String get settingsSectionLegal => 'Правова інформація';

  @override
  String get settingsSectionAbout => 'Про додаток';

  @override
  String get settingsLanguage => 'Мова';

  @override
  String get settingsAppearance => 'Вигляд';

  @override
  String get settingsContact => 'Звʼязатися з нами';

  @override
  String get settingsContactSubtitle => 'Запитання чи відгуки';

  @override
  String get settingsRate => 'Оцінити';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Вам подобається $appName? Залиште відгук';
  }

  @override
  String get settingsPrivacyPolicy => 'Політика конфіденційності';

  @override
  String get settingsTermsOfService => 'Умови використання';

  @override
  String get settingsVersion => 'Версія';

  @override
  String get settingsArchitecture => 'Архітектура пристрою';

  @override
  String get settingsArchitectureSubtitle => 'Сумісність додатків';

  @override
  String get settingsBits64 => '64-біт';

  @override
  String get settingsBits32 => '32-біт';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'Підтримувані ABI';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Ще не опубліковано';

  @override
  String get settingsNotListedYet => 'Ще немає в магазині';

  @override
  String get settingsNotSetUpYet => 'Ще не налаштовано';

  @override
  String get commonUnavailable => 'недоступно';

  @override
  String get appearanceTitle => 'Вигляд';

  @override
  String get appearancePreview => 'Перегляд';

  @override
  String get appearanceChooseTheme => 'Виберіть тему';

  @override
  String get appearanceSystem => 'Як у системі';

  @override
  String get appearanceSystemSubtitle =>
      'Використовувати налаштування пристрою';

  @override
  String get appearanceLight => 'Світла';

  @override
  String get appearanceLightSubtitle => 'Завжди світла тема';

  @override
  String get appearanceDark => 'Темна';

  @override
  String get appearanceDarkSubtitle => 'Завжди темна тема';

  @override
  String appearanceInstantNote(String appName) {
    return 'Зміни теми застосовуються одразу в усьому $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Перегляд теми: $theme';
  }

  @override
  String get languageTitle => 'Мова';

  @override
  String get languageSearchHint => 'Пошук мов';

  @override
  String get languageClearSearch => 'Очистити пошук';

  @override
  String languageNote(String appName) {
    return 'Виберіть мову, яка використовується в $appName.';
  }

  @override
  String get languageSectionHeader => 'Мова';

  @override
  String get languageSystem => 'Як у системі';

  @override
  String get languageSystemSubtitle => 'Використовувати мову пристрою';

  @override
  String get languageInstantNote => 'Зміни мови застосовуються одразу.';

  @override
  String languageNoMatches(String query) {
    return 'Немає мов за запитом «$query».';
  }

  @override
  String get contactTitle => 'Звʼязатися з нами';

  @override
  String get contactHeroTitle => 'Чим можемо допомогти?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Виберіть, як вам зручніше звернутися до команди $appName.';
  }

  @override
  String get contactSectionOptions => 'Способи звʼязку';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Напишіть нашій службі підтримки';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Напишіть нам у Telegram';

  @override
  String get contactEmail => 'Ел. пошта';

  @override
  String get contactEmailSubtitle => 'Надішліть нам листа';

  @override
  String get contactResponseTime => 'Час відповіді';

  @override
  String get contactResponseTimeValue =>
      'Зазвичай відповідаємо протягом 1–2 робочих днів.';

  @override
  String get contactPrivacyNote =>
      'Ми використаємо ваше повідомлення лише для підтримки.';

  @override
  String contactNoMailApp(String email) {
    return 'Не вдалося відкрити поштовий додаток. Напишіть на $email.';
  }

  @override
  String get contactWhatsAppFailed => 'Не вдалося відкрити WhatsApp.';

  @override
  String get contactTelegramFailed => 'Не вдалося відкрити Telegram.';

  @override
  String get contactPlayStoreFailed => 'Не вдалося відкрити Play Store.';

  @override
  String contactLegalOpenFailed(String document) {
    return 'Не вдалося відкрити «$document».';
  }
}
