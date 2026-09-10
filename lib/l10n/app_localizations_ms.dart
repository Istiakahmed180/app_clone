// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get settingsTitle => 'Tetapan';

  @override
  String get settingsSectionSupport => 'Sokongan';

  @override
  String get settingsSectionLegal => 'Perundangan';

  @override
  String get settingsSectionAbout => 'Perihal';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsAppearance => 'Penampilan';

  @override
  String get settingsContact => 'Hubungi kami';

  @override
  String get settingsContactSubtitle => 'Pertanyaan atau maklum balas';

  @override
  String get settingsRate => 'Nilai kami';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Suka $appName? Tinggalkan ulasan';
  }

  @override
  String get settingsPrivacyPolicy => 'Dasar Privasi';

  @override
  String get settingsTermsOfService => 'Terma Perkhidmatan';

  @override
  String get settingsVersion => 'Versi';

  @override
  String get settingsArchitecture => 'Seni bina peranti';

  @override
  String get settingsArchitectureSubtitle => 'Keserasian apl';

  @override
  String get settingsBits64 => '64-bit';

  @override
  String get settingsBits32 => '32-bit';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'ABI yang disokong';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Belum diterbitkan';

  @override
  String get settingsNotListedYet => 'Belum ada di gedung';

  @override
  String get settingsNotSetUpYet => 'Belum disediakan';

  @override
  String get commonUnavailable => 'tidak tersedia';

  @override
  String get appearanceTitle => 'Penampilan';

  @override
  String get appearancePreview => 'Pratonton';

  @override
  String get appearanceChooseTheme => 'Pilih tema';

  @override
  String get appearanceSystem => 'Lalai sistem';

  @override
  String get appearanceSystemSubtitle => 'Ikut tetapan peranti';

  @override
  String get appearanceLight => 'Cerah';

  @override
  String get appearanceLightSubtitle => 'Sentiasa guna tema cerah';

  @override
  String get appearanceDark => 'Gelap';

  @override
  String get appearanceDarkSubtitle => 'Sentiasa guna tema gelap';

  @override
  String appearanceInstantNote(String appName) {
    return 'Perubahan tema berkuat kuasa serta-merta di seluruh $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Pratonton tema $theme';
  }

  @override
  String get languageTitle => 'Bahasa';

  @override
  String get languageSearchHint => 'Cari bahasa';

  @override
  String get languageClearSearch => 'Kosongkan carian';

  @override
  String languageNote(String appName) {
    return 'Pilih bahasa yang digunakan dalam $appName.';
  }

  @override
  String get languageSectionHeader => 'Bahasa';

  @override
  String get languageSystem => 'Lalai sistem';

  @override
  String get languageSystemSubtitle => 'Guna bahasa peranti';

  @override
  String get languageInstantNote =>
      'Perubahan bahasa berkuat kuasa serta-merta.';

  @override
  String languageNoMatches(String query) {
    return 'Tiada bahasa sepadan dengan \"$query\".';
  }

  @override
  String get contactTitle => 'Hubungi kami';

  @override
  String get contactHeroTitle => 'Bagaimana kami boleh membantu?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Pilih cara yang anda mahu untuk menghubungi pasukan $appName.';
  }

  @override
  String get contactSectionOptions => 'Pilihan hubungan';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle =>
      'Bersembang dengan pasukan sokongan kami';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Hantar mesej kepada kami di Telegram';

  @override
  String get contactEmail => 'E-mel';

  @override
  String get contactEmailSubtitle => 'Hantar e-mel kepada kami';

  @override
  String get contactResponseTime => 'Masa tindak balas';

  @override
  String get contactResponseTimeValue =>
      'Kami biasanya menjawab dalam 1–2 hari bekerja.';

  @override
  String get contactPrivacyNote =>
      'Kami hanya menggunakan mesej anda untuk memberikan sokongan.';

  @override
  String contactNoMailApp(String email) {
    return 'Tiada apl e-mel dapat dibuka. Tulis kepada $email sebagai ganti.';
  }

  @override
  String get contactWhatsAppFailed => 'WhatsApp tidak dapat dibuka.';

  @override
  String get contactTelegramFailed => 'Telegram tidak dapat dibuka.';

  @override
  String get contactPlayStoreFailed => 'Play Store tidak dapat dibuka.';

  @override
  String contactLegalOpenFailed(String document) {
    return '$document tidak dapat dibuka.';
  }
}
