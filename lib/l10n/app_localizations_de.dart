// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsSectionLegal => 'Rechtliches';

  @override
  String get settingsSectionAbout => 'Über';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsAppearance => 'Erscheinungsbild';

  @override
  String get settingsContact => 'Kontakt';

  @override
  String get settingsContactSubtitle => 'Fragen oder Feedback';

  @override
  String get settingsRate => 'Bewerten';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Gefällt dir $appName? Schreibe eine Bewertung';
  }

  @override
  String get settingsPrivacyPolicy => 'Datenschutzerklärung';

  @override
  String get settingsTermsOfService => 'Nutzungsbedingungen';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsArchitecture => 'Gerätearchitektur';

  @override
  String get settingsArchitectureSubtitle => 'App-Kompatibilität';

  @override
  String get settingsBits64 => '64-Bit';

  @override
  String get settingsBits32 => '32-Bit';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'Unterstützte ABIs';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Noch nicht veröffentlicht';

  @override
  String get settingsNotListedYet => 'Noch nicht im Store';

  @override
  String get settingsNotSetUpYet => 'Noch nicht eingerichtet';

  @override
  String get settingsSectionDelivery => 'Zustellung';

  @override
  String get settingsBackgroundActivity => 'Hintergrundaktivität';

  @override
  String get settingsBackgroundActivitySubtitle =>
      'Lässt geklonte Apps Benachrichtigungen erhalten, während sie geschlossen sind';

  @override
  String get settingsBackgroundActivityAllowed => 'Erlaubt';

  @override
  String get settingsBackgroundActivityRestricted => 'Eingeschränkt';

  @override
  String get settingsBackgroundActivityCheck => 'Prüfen';

  @override
  String get backgroundGuideTitle => 'Hintergrundaktivität';

  @override
  String get backgroundGuideWhy =>
      'Android kann Duplika im Hintergrund pausieren; geklonte Apps verpassen dann Benachrichtigungen, bis du Duplika wieder öffnest.';

  @override
  String get backgroundGuideStepsOem =>
      'Tippe in den App-Infos auf Akkuverbrauch und aktiviere Hintergrundaktivität.';

  @override
  String get backgroundGuideStepsStock =>
      'Tippe in der Systemfrage auf Zulassen, damit die App im Hintergrund laufen darf.';

  @override
  String get backgroundGuideStepsUnknown =>
      'Erlaube in den App-Infos die Hintergrundaktivität.';

  @override
  String get backgroundGuideOpenAppInfo => 'App-Infos öffnen';

  @override
  String get backgroundGuideAllow => 'Zulassen';

  @override
  String get backgroundGuideLater => 'Später';

  @override
  String get settingsBackgroundActivityFix =>
      'Hier tippen und Hintergrundaktivität erlauben';

  @override
  String get settingsBackgroundActivityFixBatteryUsage =>
      'Hier tippen, dann Akkuverbrauch, dann Hintergrundaktivität erlauben';

  @override
  String get settingsBackgroundActivityFailed =>
      'Die Einstellungen für die Hintergrundaktivität konnten nicht geöffnet werden.';

  @override
  String get commonUnavailable => 'nicht verfügbar';

  @override
  String get appearanceTitle => 'Erscheinungsbild';

  @override
  String get appearancePreview => 'Vorschau';

  @override
  String get appearanceChooseTheme => 'Design wählen';

  @override
  String get appearanceSystem => 'Systemstandard';

  @override
  String get appearanceSystemSubtitle => 'Geräteeinstellungen folgen';

  @override
  String get appearanceLight => 'Hell';

  @override
  String get appearanceLightSubtitle => 'Immer helles Design';

  @override
  String get appearanceDark => 'Dunkel';

  @override
  String get appearanceDarkSubtitle => 'Immer dunkles Design';

  @override
  String appearanceInstantNote(String appName) {
    return 'Designänderungen gelten sofort in ganz $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Vorschau des Designs $theme';
  }

  @override
  String get languageTitle => 'Sprache';

  @override
  String get languageSearchHint => 'Sprachen suchen';

  @override
  String get languageClearSearch => 'Suche löschen';

  @override
  String languageNote(String appName) {
    return 'Wähle die Sprache, die in $appName verwendet wird.';
  }

  @override
  String get languageSectionHeader => 'Sprache';

  @override
  String get languageSystem => 'Systemstandard';

  @override
  String get languageSystemSubtitle => 'Gerätesprache verwenden';

  @override
  String get languageInstantNote => 'Sprachänderungen gelten sofort.';

  @override
  String languageNoMatches(String query) {
    return 'Keine Sprache passt zu „$query“.';
  }

  @override
  String get contactTitle => 'Kontakt';

  @override
  String get contactHeroTitle => 'Wie können wir helfen?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Wähle, wie du das $appName-Team erreichen möchtest.';
  }

  @override
  String get contactSectionOptions => 'Kontaktmöglichkeiten';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Chatte mit unserem Support-Team';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Schreibe uns auf Telegram';

  @override
  String get contactEmail => 'E-Mail';

  @override
  String get contactEmailSubtitle => 'Schreibe uns eine E-Mail';

  @override
  String get contactResponseTime => 'Antwortzeit';

  @override
  String get contactResponseTimeValue =>
      'Wir antworten meist innerhalb von 1–2 Werktagen.';

  @override
  String get contactPrivacyNote =>
      'Wir verwenden deine Nachricht nur für den Support.';

  @override
  String contactNoMailApp(String email) {
    return 'Es konnte keine Mail-App geöffnet werden. Schreibe stattdessen an $email.';
  }

  @override
  String get contactWhatsAppFailed => 'WhatsApp konnte nicht geöffnet werden.';

  @override
  String get contactTelegramFailed => 'Telegram konnte nicht geöffnet werden.';

  @override
  String get contactPlayStoreFailed =>
      'Der Play Store konnte nicht geöffnet werden.';

  @override
  String contactLegalOpenFailed(String document) {
    return '$document konnte nicht geöffnet werden.';
  }
}
