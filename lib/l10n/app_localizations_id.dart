// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsSectionSupport => 'Dukungan';

  @override
  String get settingsSectionLegal => 'Legal';

  @override
  String get settingsSectionAbout => 'Tentang';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsAppearance => 'Tampilan';

  @override
  String get settingsContact => 'Hubungi kami';

  @override
  String get settingsContactSubtitle => 'Pertanyaan atau masukan';

  @override
  String get settingsRate => 'Beri nilai';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Menikmati $appName? Tinggalkan ulasan';
  }

  @override
  String get settingsPrivacyPolicy => 'Kebijakan Privasi';

  @override
  String get settingsTermsOfService => 'Ketentuan Layanan';

  @override
  String get settingsVersion => 'Versi';

  @override
  String get settingsArchitecture => 'Arsitektur perangkat';

  @override
  String get settingsArchitectureSubtitle => 'Kompatibilitas aplikasi';

  @override
  String get settingsBits64 => '64-bit';

  @override
  String get settingsBits32 => '32-bit';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'ABI yang didukung';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Belum dipublikasikan';

  @override
  String get settingsNotListedYet => 'Belum ada di toko';

  @override
  String get settingsNotSetUpYet => 'Belum disiapkan';

  @override
  String get settingsSectionDelivery => 'Pengiriman';

  @override
  String get settingsBackgroundActivity => 'Aktivitas latar belakang';

  @override
  String get settingsBackgroundActivitySubtitle =>
      'Membuat aplikasi klon tetap menerima notifikasi saat ditutup';

  @override
  String get settingsBackgroundActivityAllowed => 'Diizinkan';

  @override
  String get settingsBackgroundActivityRestricted => 'Dibatasi';

  @override
  String get settingsBackgroundActivityCheck => 'Periksa';

  @override
  String get backgroundGuideTitle => 'Aktivitas latar belakang';

  @override
  String get backgroundGuideWhy =>
      'Android dapat menghentikan sementara Duplika di latar belakang; aplikasi klon lalu tidak menerima notifikasi sampai Anda membuka Duplika lagi.';

  @override
  String get backgroundGuideStepsOem =>
      'Di Info aplikasi, ketuk Penggunaan baterai lalu aktifkan Izinkan aktivitas latar belakang.';

  @override
  String get backgroundGuideStepsStock =>
      'Ketuk Izinkan pada pertanyaan sistem yang muncul, agar dapat berjalan di latar belakang.';

  @override
  String get backgroundGuideStepsUnknown =>
      'Di Info aplikasi, izinkan aktivitas latar belakang.';

  @override
  String get backgroundGuideOpenAppInfo => 'Buka info aplikasi';

  @override
  String get backgroundGuideAllow => 'Izinkan';

  @override
  String get backgroundGuideLater => 'Nanti saja';

  @override
  String get settingsBackgroundActivityFix =>
      'Ketuk di sini dan izinkan aktivitas latar belakang';

  @override
  String get settingsBackgroundActivityFixBatteryUsage =>
      'Ketuk di sini, lalu Penggunaan baterai, lalu Izinkan aktivitas latar belakang';

  @override
  String get settingsBackgroundActivityFailed =>
      'Setelan aktivitas latar belakang tidak dapat dibuka.';

  @override
  String get commonUnavailable => 'tidak tersedia';

  @override
  String get appearanceTitle => 'Tampilan';

  @override
  String get appearancePreview => 'Pratinjau';

  @override
  String get appearanceChooseTheme => 'Pilih tema';

  @override
  String get appearanceSystem => 'Bawaan sistem';

  @override
  String get appearanceSystemSubtitle => 'Ikuti pengaturan perangkat';

  @override
  String get appearanceLight => 'Terang';

  @override
  String get appearanceLightSubtitle => 'Selalu gunakan tema terang';

  @override
  String get appearanceDark => 'Gelap';

  @override
  String get appearanceDarkSubtitle => 'Selalu gunakan tema gelap';

  @override
  String appearanceInstantNote(String appName) {
    return 'Perubahan tema langsung berlaku di seluruh $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Pratinjau tema $theme';
  }

  @override
  String get languageTitle => 'Bahasa';

  @override
  String get languageSearchHint => 'Cari bahasa';

  @override
  String get languageClearSearch => 'Hapus pencarian';

  @override
  String languageNote(String appName) {
    return 'Pilih bahasa yang digunakan di $appName.';
  }

  @override
  String get languageSectionHeader => 'Bahasa';

  @override
  String get languageSystem => 'Bawaan sistem';

  @override
  String get languageSystemSubtitle => 'Gunakan bahasa perangkat';

  @override
  String get languageInstantNote => 'Perubahan bahasa langsung berlaku.';

  @override
  String languageNoMatches(String query) {
    return 'Tidak ada bahasa yang cocok dengan \"$query\".';
  }

  @override
  String get contactTitle => 'Hubungi kami';

  @override
  String get contactHeroTitle => 'Ada yang bisa kami bantu?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Pilih cara yang Anda sukai untuk menghubungi tim $appName.';
  }

  @override
  String get contactSectionOptions => 'Opsi kontak';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Chat dengan tim dukungan kami';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Kirim pesan lewat Telegram';

  @override
  String get contactEmail => 'Email';

  @override
  String get contactEmailSubtitle => 'Kirim email kepada kami';

  @override
  String get contactResponseTime => 'Waktu respons';

  @override
  String get contactResponseTimeValue =>
      'Kami biasanya membalas dalam 1–2 hari kerja.';

  @override
  String get contactPrivacyNote =>
      'Kami hanya menggunakan pesan Anda untuk memberikan dukungan.';

  @override
  String contactNoMailApp(String email) {
    return 'Tidak ada aplikasi email yang bisa dibuka. Kirim ke $email saja.';
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
