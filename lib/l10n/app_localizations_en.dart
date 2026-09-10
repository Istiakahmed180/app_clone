// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsSectionLegal => 'Legal';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsContact => 'Contact us';

  @override
  String get settingsContactSubtitle => 'Questions or feedback';

  @override
  String get settingsRate => 'Rate us';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Enjoying $appName? Leave a review';
  }

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsArchitecture => 'Device architecture';

  @override
  String get settingsArchitectureSubtitle => 'App compatibility';

  @override
  String get settingsBits64 => '64-bit';

  @override
  String get settingsBits32 => '32-bit';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'Supported ABIs';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Not published yet';

  @override
  String get settingsNotListedYet => 'Not listed yet';

  @override
  String get settingsNotSetUpYet => 'Not set up yet';

  @override
  String get commonUnavailable => 'unavailable';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearancePreview => 'Preview';

  @override
  String get appearanceChooseTheme => 'Choose a theme';

  @override
  String get appearanceSystem => 'System default';

  @override
  String get appearanceSystemSubtitle => 'Match your device settings';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceLightSubtitle => 'Always use light theme';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceDarkSubtitle => 'Always use dark theme';

  @override
  String appearanceInstantNote(String appName) {
    return 'Theme changes apply instantly across $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return '$theme theme preview';
  }

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSearchHint => 'Search languages';

  @override
  String get languageClearSearch => 'Clear search';

  @override
  String languageNote(String appName) {
    return 'Choose the language used in $appName.';
  }

  @override
  String get languageSectionHeader => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageSystemSubtitle => 'Use your device language';

  @override
  String get languageInstantNote => 'Language changes apply immediately.';

  @override
  String languageNoMatches(String query) {
    return 'No language matches \"$query\".';
  }

  @override
  String get contactTitle => 'Contact us';

  @override
  String get contactHeroTitle => 'How can we help?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Choose your preferred way to contact the $appName team.';
  }

  @override
  String get contactSectionOptions => 'Contact options';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Chat with our support team';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Message us on Telegram';

  @override
  String get contactEmail => 'Email';

  @override
  String get contactEmailSubtitle => 'Send us an email';

  @override
  String get contactResponseTime => 'Response time';

  @override
  String get contactResponseTimeValue =>
      'We usually reply within 1–2 business days.';

  @override
  String get contactPrivacyNote =>
      'We\'ll only use your message to provide support.';

  @override
  String contactNoMailApp(String email) {
    return 'No mail app could be opened. Write to $email instead.';
  }

  @override
  String get contactWhatsAppFailed => 'WhatsApp could not be opened.';

  @override
  String get contactTelegramFailed => 'Telegram could not be opened.';

  @override
  String get contactPlayStoreFailed => 'The Play Store could not be opened.';

  @override
  String contactLegalOpenFailed(String document) {
    return 'The $document could not be opened.';
  }
}
