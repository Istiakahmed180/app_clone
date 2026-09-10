// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian (`no`).
class AppLocalizationsNo extends AppLocalizations {
  AppLocalizationsNo([String locale = 'no']) : super(locale);

  @override
  String get settingsTitle => 'Innstillinger';

  @override
  String get settingsSectionSupport => 'Kundestøtte';

  @override
  String get settingsSectionLegal => 'Juridisk';

  @override
  String get settingsSectionAbout => 'Om';

  @override
  String get settingsLanguage => 'Språk';

  @override
  String get settingsAppearance => 'Utseende';

  @override
  String get settingsContact => 'Kontakt oss';

  @override
  String get settingsContactSubtitle => 'Spørsmål eller tilbakemelding';

  @override
  String get settingsRate => 'Vurder oss';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Liker du $appName? Legg igjen en vurdering';
  }

  @override
  String get settingsPrivacyPolicy => 'Personvernerklæring';

  @override
  String get settingsTermsOfService => 'Vilkår for bruk';

  @override
  String get settingsVersion => 'Versjon';

  @override
  String get settingsArchitecture => 'Enhetsarkitektur';

  @override
  String get settingsArchitectureSubtitle => 'Appkompatibilitet';

  @override
  String get settingsBits64 => '64-bit';

  @override
  String get settingsBits32 => '32-bit';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'Støttede ABI-er';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Ikke publisert ennå';

  @override
  String get settingsNotListedYet => 'Ikke i butikken ennå';

  @override
  String get settingsNotSetUpYet => 'Ikke satt opp ennå';

  @override
  String get commonUnavailable => 'utilgjengelig';

  @override
  String get appearanceTitle => 'Utseende';

  @override
  String get appearancePreview => 'Forhåndsvisning';

  @override
  String get appearanceChooseTheme => 'Velg et tema';

  @override
  String get appearanceSystem => 'Systemstandard';

  @override
  String get appearanceSystemSubtitle => 'Følg enhetens innstillinger';

  @override
  String get appearanceLight => 'Lyst';

  @override
  String get appearanceLightSubtitle => 'Bruk alltid lyst tema';

  @override
  String get appearanceDark => 'Mørkt';

  @override
  String get appearanceDarkSubtitle => 'Bruk alltid mørkt tema';

  @override
  String appearanceInstantNote(String appName) {
    return 'Temaendringer gjelder umiddelbart i hele $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Forhåndsvisning av $theme tema';
  }

  @override
  String get languageTitle => 'Språk';

  @override
  String get languageSearchHint => 'Søk i språk';

  @override
  String get languageClearSearch => 'Tøm søket';

  @override
  String languageNote(String appName) {
    return 'Velg språket som brukes i $appName.';
  }

  @override
  String get languageSectionHeader => 'Språk';

  @override
  String get languageSystem => 'Systemstandard';

  @override
  String get languageSystemSubtitle => 'Bruk enhetens språk';

  @override
  String get languageInstantNote => 'Språkendringer gjelder umiddelbart.';

  @override
  String languageNoMatches(String query) {
    return 'Ingen språk samsvarer med «$query».';
  }

  @override
  String get contactTitle => 'Kontakt oss';

  @override
  String get contactHeroTitle => 'Hvordan kan vi hjelpe?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Velg hvordan du vil kontakte $appName-teamet.';
  }

  @override
  String get contactSectionOptions => 'Kontaktalternativer';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Chat med kundestøtten vår';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Send oss melding på Telegram';

  @override
  String get contactEmail => 'E-post';

  @override
  String get contactEmailSubtitle => 'Send oss en e-post';

  @override
  String get contactResponseTime => 'Svartid';

  @override
  String get contactResponseTimeValue =>
      'Vi svarer vanligvis innen 1–2 virkedager.';

  @override
  String get contactPrivacyNote =>
      'Vi bruker meldingen din bare til å gi kundestøtte.';

  @override
  String contactNoMailApp(String email) {
    return 'Ingen e-postapp kunne åpnes. Skriv til $email i stedet.';
  }

  @override
  String get contactWhatsAppFailed => 'WhatsApp kunne ikke åpnes.';

  @override
  String get contactTelegramFailed => 'Telegram kunne ikke åpnes.';

  @override
  String get contactPlayStoreFailed => 'Play Store kunne ikke åpnes.';

  @override
  String contactLegalOpenFailed(String document) {
    return '$document kunne ikke åpnes.';
  }
}
