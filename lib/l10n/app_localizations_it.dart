// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsSectionSupport => 'Assistenza';

  @override
  String get settingsSectionLegal => 'Note legali';

  @override
  String get settingsSectionAbout => 'Informazioni';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get settingsContact => 'Contattaci';

  @override
  String get settingsContactSubtitle => 'Domande o feedback';

  @override
  String get settingsRate => 'Valutaci';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Ti piace $appName? Lascia una recensione';
  }

  @override
  String get settingsPrivacyPolicy => 'Informativa sulla privacy';

  @override
  String get settingsTermsOfService => 'Termini di servizio';

  @override
  String get settingsVersion => 'Versione';

  @override
  String get settingsArchitecture => 'Architettura del dispositivo';

  @override
  String get settingsArchitectureSubtitle => 'Compatibilità delle app';

  @override
  String get settingsBits64 => '64 bit';

  @override
  String get settingsBits32 => '32 bit';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'ABI supportate';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Non ancora pubblicato';

  @override
  String get settingsNotListedYet => 'Non ancora sullo store';

  @override
  String get settingsNotSetUpYet => 'Non ancora configurato';

  @override
  String get commonUnavailable => 'non disponibile';

  @override
  String get appearanceTitle => 'Aspetto';

  @override
  String get appearancePreview => 'Anteprima';

  @override
  String get appearanceChooseTheme => 'Scegli un tema';

  @override
  String get appearanceSystem => 'Predefinito di sistema';

  @override
  String get appearanceSystemSubtitle =>
      'Segui le impostazioni del dispositivo';

  @override
  String get appearanceLight => 'Chiaro';

  @override
  String get appearanceLightSubtitle => 'Usa sempre il tema chiaro';

  @override
  String get appearanceDark => 'Scuro';

  @override
  String get appearanceDarkSubtitle => 'Usa sempre il tema scuro';

  @override
  String appearanceInstantNote(String appName) {
    return 'Le modifiche al tema si applicano subito in tutto $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Anteprima del tema $theme';
  }

  @override
  String get languageTitle => 'Lingua';

  @override
  String get languageSearchHint => 'Cerca lingue';

  @override
  String get languageClearSearch => 'Cancella la ricerca';

  @override
  String languageNote(String appName) {
    return 'Scegli la lingua usata in $appName.';
  }

  @override
  String get languageSectionHeader => 'Lingua';

  @override
  String get languageSystem => 'Predefinito di sistema';

  @override
  String get languageSystemSubtitle => 'Usa la lingua del dispositivo';

  @override
  String get languageInstantNote =>
      'Le modifiche alla lingua si applicano subito.';

  @override
  String languageNoMatches(String query) {
    return 'Nessuna lingua corrisponde a «$query».';
  }

  @override
  String get contactTitle => 'Contattaci';

  @override
  String get contactHeroTitle => 'Come possiamo aiutarti?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Scegli come preferisci contattare il team di $appName.';
  }

  @override
  String get contactSectionOptions => 'Opzioni di contatto';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle =>
      'Chatta con il nostro team di assistenza';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Scrivici su Telegram';

  @override
  String get contactEmail => 'Email';

  @override
  String get contactEmailSubtitle => 'Inviaci un\'email';

  @override
  String get contactResponseTime => 'Tempo di risposta';

  @override
  String get contactResponseTimeValue =>
      'Di solito rispondiamo entro 1–2 giorni lavorativi.';

  @override
  String get contactPrivacyNote =>
      'Useremo il tuo messaggio solo per fornirti assistenza.';

  @override
  String contactNoMailApp(String email) {
    return 'Non è stato possibile aprire un\'app di posta. Scrivi invece a $email.';
  }

  @override
  String get contactWhatsAppFailed => 'Non è stato possibile aprire WhatsApp.';

  @override
  String get contactTelegramFailed => 'Non è stato possibile aprire Telegram.';

  @override
  String get contactPlayStoreFailed =>
      'Non è stato possibile aprire il Play Store.';

  @override
  String contactLegalOpenFailed(String document) {
    return 'Non è stato possibile aprire $document.';
  }
}
