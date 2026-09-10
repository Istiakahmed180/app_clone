// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSectionSupport => 'Поддержка';

  @override
  String get settingsSectionLegal => 'Правовая информация';

  @override
  String get settingsSectionAbout => 'О приложении';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsAppearance => 'Оформление';

  @override
  String get settingsContact => 'Связаться с нами';

  @override
  String get settingsContactSubtitle => 'Вопросы или отзывы';

  @override
  String get settingsRate => 'Оценить';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Нравится $appName? Оставьте отзыв';
  }

  @override
  String get settingsPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get settingsTermsOfService => 'Условия использования';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsArchitecture => 'Архитектура устройства';

  @override
  String get settingsArchitectureSubtitle => 'Совместимость приложений';

  @override
  String get settingsBits64 => '64-бит';

  @override
  String get settingsBits32 => '32-бит';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'Поддерживаемые ABI';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Ещё не опубликовано';

  @override
  String get settingsNotListedYet => 'Ещё нет в магазине';

  @override
  String get settingsNotSetUpYet => 'Ещё не настроено';

  @override
  String get commonUnavailable => 'недоступно';

  @override
  String get appearanceTitle => 'Оформление';

  @override
  String get appearancePreview => 'Предпросмотр';

  @override
  String get appearanceChooseTheme => 'Выберите тему';

  @override
  String get appearanceSystem => 'Как в системе';

  @override
  String get appearanceSystemSubtitle => 'Следовать настройкам устройства';

  @override
  String get appearanceLight => 'Светлая';

  @override
  String get appearanceLightSubtitle => 'Всегда светлая тема';

  @override
  String get appearanceDark => 'Тёмная';

  @override
  String get appearanceDarkSubtitle => 'Всегда тёмная тема';

  @override
  String appearanceInstantNote(String appName) {
    return 'Изменения темы применяются сразу во всём приложении $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Предпросмотр темы: $theme';
  }

  @override
  String get languageTitle => 'Язык';

  @override
  String get languageSearchHint => 'Поиск языков';

  @override
  String get languageClearSearch => 'Очистить поиск';

  @override
  String languageNote(String appName) {
    return 'Выберите язык, используемый в $appName.';
  }

  @override
  String get languageSectionHeader => 'Язык';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get languageSystemSubtitle => 'Использовать язык устройства';

  @override
  String get languageInstantNote => 'Изменения языка применяются сразу.';

  @override
  String languageNoMatches(String query) {
    return 'Нет языков по запросу «$query».';
  }

  @override
  String get contactTitle => 'Связаться с нами';

  @override
  String get contactHeroTitle => 'Чем можем помочь?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Выберите удобный способ связаться с командой $appName.';
  }

  @override
  String get contactSectionOptions => 'Способы связи';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Написать в службу поддержки';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Напишите нам в Telegram';

  @override
  String get contactEmail => 'Эл. почта';

  @override
  String get contactEmailSubtitle => 'Отправить нам письмо';

  @override
  String get contactResponseTime => 'Время ответа';

  @override
  String get contactResponseTimeValue =>
      'Обычно отвечаем в течение 1–2 рабочих дней.';

  @override
  String get contactPrivacyNote =>
      'Мы используем ваше сообщение только для поддержки.';

  @override
  String contactNoMailApp(String email) {
    return 'Не удалось открыть почтовое приложение. Напишите на $email.';
  }

  @override
  String get contactWhatsAppFailed => 'Не удалось открыть WhatsApp.';

  @override
  String get contactTelegramFailed => 'Не удалось открыть Telegram.';

  @override
  String get contactPlayStoreFailed => 'Не удалось открыть Play Store.';

  @override
  String contactLegalOpenFailed(String document) {
    return 'Не удалось открыть «$document».';
  }
}
