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
  String get settingsBackgroundActivityNotAllowed => 'Tidak diizinkan';

  @override
  String get backgroundGuideAllowedStatus =>
      'Aktivitas latar belakang diizinkan, sehingga aplikasi klon tetap menerima notifikasi saat ditutup.';

  @override
  String get backgroundGuideDone => 'Selesai';

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

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNotNow => 'Nanti saja';

  @override
  String get commonClose => 'Tutup';

  @override
  String get commonMore => 'Lainnya';

  @override
  String get commonFailureTitle => 'Tidak bisa melakukannya';

  @override
  String get homePrivateSpaceTitle => 'Ruang pribadi';

  @override
  String get homeSubtitle => 'Ruang pribadi Anda';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aplikasi tersembunyi',
      zero: 'Tidak ada aplikasi tersembunyi',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => 'Kunci dan tutup';

  @override
  String get homeMenuSettings => 'Setelan';

  @override
  String get homeMenuDeveloperTools => 'Alat pengembang';

  @override
  String get homeAddApp => 'Tambah aplikasi';

  @override
  String get homeEmptyTitle => 'Ruang Anda masih kosong';

  @override
  String get homeEmptyMessage =>
      'Tambahkan aplikasi untuk membuat salinan pribadi pertama Anda.';

  @override
  String get homeEmptyAction => 'Tambahkan aplikasi pertama Anda';

  @override
  String get homePrivateEmptyTitle => 'Belum ada yang disembunyikan';

  @override
  String get homePrivateEmptyMessage =>
      'Tahan aplikasi mana pun di kisi utama lalu pilih Sembunyikan untuk memindahkannya ke sini.';

  @override
  String get homeSetUpPrivateSpaceTitle => 'Siapkan ruang pribadi?';

  @override
  String get homeSetUpPrivateSpaceMessage =>
      'Menyembunyikan klon memerlukan ruang pribadi. Buat dulu satu dengan PIN.';

  @override
  String get homeSetUpPrivateSpaceConfirm => 'Siapkan';

  @override
  String get homeEngineInactive =>
      'Mesin virtualisasi tidak aktif di perangkat ini, jadi klon tidak dapat berjalan di kontainer terpisah.';

  @override
  String get homeEngineUnavailable =>
      'Mesin virtualisasi tidak tersedia di perangkat ini.';

  @override
  String get homeBackgroundNudgeTitle =>
      'Klon bisa melewatkan notifikasi selagi tertutup.';

  @override
  String get homeBackgroundNudgeMessage =>
      'Pastikan aktivitas latar belakang diizinkan agar mereka tetap menerimanya.';

  @override
  String get homeBackgroundNudgeAllow => 'Izinkan';

  @override
  String get homeBackgroundNudgeDismiss => 'Tutup';

  @override
  String cloneSpaceLabel(int index) {
    return 'Ruang $index';
  }

  @override
  String get cloneActionsCompatibility => 'Kompatibilitas';

  @override
  String get cloneActionsManage => 'Kelola';

  @override
  String get cloneActionUninstall => 'Copot pemasangan';

  @override
  String get cloneActionClone => 'Klon';

  @override
  String get cloneActionShortcut => 'Pintasan';

  @override
  String get cloneActionSpaceInfo => 'Info ruang';

  @override
  String get cloneActionEditName => 'Ubah nama';

  @override
  String get cloneActionForceStop => 'Paksa berhenti';

  @override
  String get cloneActionClearCache => 'Hapus cache';

  @override
  String get cloneActionClearStorage => 'Hapus data';

  @override
  String get cloneActionHide => 'Sembunyikan';

  @override
  String get cloneActionUnhide => 'Tampilkan';

  @override
  String get cloneActionShareApp => 'Bagikan aplikasi';

  @override
  String get cloneActionNotifications => 'Notifikasi';

  @override
  String get cloneActionPermissions => 'Izin';

  @override
  String get cloneActionGoogleServicesInstalled =>
      'Layanan Google (microG) terpasang';

  @override
  String get cloneActionInstallGoogleServices =>
      'Pasang layanan Google (microG)';

  @override
  String cloneTileSibling(int index, int count) {
    return ', klon $index dari $count';
  }

  @override
  String get cloneTileOpening => ', sedang dibuka';

  @override
  String get cloneTileRunning => ', sedang berjalan';

  @override
  String get cloneTileCannotLaunch =>
      ', tidak dapat dijalankan di perangkat ini';

  @override
  String get cloneForceStopTitle => 'Paksa berhenti aplikasi ini?';

  @override
  String get cloneForceStopMessage =>
      'Aplikasi berhenti berjalan sampai Anda membukanya lagi.';

  @override
  String get cloneForceStopConfirm => 'Paksa berhenti';

  @override
  String get cloneClearCacheTitle => 'Hapus cache aplikasi?';

  @override
  String get cloneClearCacheMessage =>
      'Ini akan menghapus berkas sementara klon ini.';

  @override
  String get cloneClearCacheConfirm => 'Hapus cache';

  @override
  String get cloneClearStorageTitle => 'Hapus data aplikasi?';

  @override
  String get cloneClearStorageMessage =>
      'Ini akan menghapus permanen akun, setelan, dan data lokal klon ini.';

  @override
  String get cloneClearStorageConfirm => 'Hapus data';

  @override
  String get cloneInstallGoogleServicesTitle => 'Pasang layanan Google?';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName akan memasang microG bawaannya ke klon ini sebagai layanan Google Play. Data klon tetap ada. Ini bisa memakan beberapa detik.';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => 'Pasang';

  @override
  String cloneStopped(String name) {
    return '$name dihentikan.';
  }

  @override
  String cloneCacheCleared(String name) {
    return 'Cache $name dihapus.';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name telah direset. Pembukaan berikutnya akan seperti pembukaan pertama.';
  }

  @override
  String cloneHidden(String name) {
    return '$name disembunyikan di ruang pribadi.';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name kembali ke kisi utama.';
  }

  @override
  String get cloneShortcutAdded =>
      'Konfirmasi pintasan di layar utama Anda untuk menyelesaikan penambahan.';

  @override
  String get cloneGoogleServicesInstalling => 'Memasang layanan Google…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return 'Layanan Google terpasang di $name.';
  }

  @override
  String get cloneCountTitle => 'Klon aplikasi';

  @override
  String cloneCountMessage(String appName) {
    return 'Buat salinan tambahan $appName.';
  }

  @override
  String get cloneCountLabel => 'Jumlah klon';

  @override
  String get cloneCountDecrease => 'Kurangi satu';

  @override
  String get cloneCountIncrease => 'Tambah satu';

  @override
  String get cloneCountConfirm => 'Klon';

  @override
  String cloneCreating(int created, int total) {
    return 'Membuat $created dari $total…';
  }

  @override
  String get cloneCreatingFinishing => 'Menyelesaikan…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Menambahkan $count salinan $appName lagi.',
      one: 'Menambahkan satu salinan $appName lagi.',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return 'Dibuat $created dari $total. $failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return 'Pilih dari 1 sampai $maximum';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return 'Hanya $free yang kosong, dan perangkat menyisakan setengah gigabyte.';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return 'Hingga $maximum — tersisa $free ruang';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return 'Hingga $maximum sekaligus di perangkat dengan memori $memory';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return 'Tidak ada ruang untuk klon $appName lagi. $reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return 'Ruang tidak cukup untuk $count klon $appName lagi. $reason.';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return 'Izin · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => 'Tidak dapat membaca izin';

  @override
  String get clonePermissionsEmptyTitle => 'Tidak ada yang dibatasi';

  @override
  String get clonePermissionsEmptyMessage =>
      'Aplikasi ini tidak menyatakan izin berbahaya, jadi tidak ada yang perlu diizinkan atau ditolak untuk klon ini.';

  @override
  String clonePermissionsNote(String appName) {
    return 'Ini hanya berlaku untuk klon ini. Aplikasi yang diklon biasanya bertanya sebelum memakai izin, dan di sinilah jawaban itu dibatasi — aplikasi yang melewati pertanyaan itu tetap bisa menjangkau perangkat keras lewat izin $appName sendiri.';
  }

  @override
  String get spaceInfoTitle => 'Info ruang';

  @override
  String get spaceInfoIdentifiers => 'Pengidentifikasi perangkat';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => 'Mesin tidak tersedia';

  @override
  String get spaceInfoStateRunning => 'Berjalan';

  @override
  String get spaceInfoStateActive => 'Aktif';

  @override
  String get spaceInfoStateRebuilds => 'Dibangun ulang saat dibuka';

  @override
  String get spaceInfoNoContainer =>
      'Ruang ini belum punya kontainer, jadi belum punya pengidentifikasi. Buka sekali dan mereka akan muncul di sini.';

  @override
  String get spaceInfoDeviceId => 'ID perangkat';

  @override
  String get spaceInfoAndroidId => 'ID Android';

  @override
  String get spaceInfoSerialNumber => 'Nomor seri';

  @override
  String get spaceInfoWifiMac => 'MAC Wi-Fi';

  @override
  String get spaceInfoBluetoothMac => 'MAC Bluetooth';

  @override
  String spaceInfoCopy(String label) {
    return 'Salin $label';
  }

  @override
  String spaceInfoCopied(String label) {
    return '$label disalin.';
  }

  @override
  String get commonBack => 'Kembali';

  @override
  String get commonApply => 'Terapkan';

  @override
  String get pickerTitle => 'Tambah aplikasi';

  @override
  String get pickerSearchHint => 'Cari aplikasi';

  @override
  String get pickerFilterTooltip => 'Filter dan urutkan';

  @override
  String get pickerErrorTitle => 'Tidak dapat menampilkan daftar aplikasi';

  @override
  String get pickerNoMatchesTitle => 'Tidak ada aplikasi yang cocok';

  @override
  String get pickerNoMatchesMessage =>
      'Coba pencarian lain, atau impor APK saja.';

  @override
  String get pickerPopular => 'Populer';

  @override
  String get pickerQuickPicks => 'Pilihan cepat';

  @override
  String get pickerInstalledApps => 'Aplikasi terpasang';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aplikasi',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => 'Sistem';

  @override
  String get pickerCannotClone =>
      'Aplikasi ini tidak dapat diklon di perangkat ini.';

  @override
  String get pickerApkUnreadable => 'APK yang dipilih tidak dapat dibaca.';

  @override
  String get filterTitle => 'Filter dan urutkan';

  @override
  String get filterSort => 'Urutkan';

  @override
  String get filterSortName => 'Nama aplikasi';

  @override
  String get filterSortRecentlyInstalled => 'Baru dipasang';

  @override
  String get filterSortRecentlyUpdated => 'Baru diperbarui';

  @override
  String get filterFilter => 'Filter';

  @override
  String get filterAllApps => 'Semua aplikasi';

  @override
  String get filterUserApps => 'Aplikasi pengguna';

  @override
  String get filterSystemApps => 'Aplikasi sistem';

  @override
  String get filterNotAdded => 'Belum ditambahkan';

  @override
  String get filterAlreadyAdded => 'Sudah ditambahkan';

  @override
  String get filterArchitecture => 'Arsitektur';

  @override
  String get filterArch64 => '64-bit';

  @override
  String get filterArch32 => '32-bit';

  @override
  String get filterArchNoNativeCode => 'Tanpa kode native';

  @override
  String get filterPackageType => 'Jenis paket';

  @override
  String get filterPackageSingle => 'APK tunggal';

  @override
  String get filterPackageSplit => 'APK terpisah';

  @override
  String filterImportApk(String appName) {
    return 'Buka paket aplikasi $appName';
  }

  @override
  String get appSheetAddClone => 'Tambah klon';

  @override
  String get appSheetAddAnother => 'Tambah lagi';

  @override
  String get appSheetShareApp => 'Bagikan aplikasi';

  @override
  String get appSheetAppDetails => 'Detail aplikasi';

  @override
  String get appDetailsTitle => 'Detail aplikasi';

  @override
  String get appDetailsAdvanced => 'Detail lanjutan';

  @override
  String get appDetailsPackageName => 'Nama paket';

  @override
  String get appDetailsVersion => 'Versi';

  @override
  String get appDetailsArchitecture => 'Arsitektur';

  @override
  String get appDetailsBitness => 'Lebar bit';

  @override
  String get appDetailsPackageType => 'Jenis paket';

  @override
  String get appDetailsApkComponents => 'Komponen APK';

  @override
  String get appDetailsTotalApkSize => 'Total ukuran APK';

  @override
  String get appDetailsSigningSha256 => 'SHA-256 sertifikat penandatanganan';

  @override
  String get appDetailsSigningUnreadable => 'tidak dapat dibaca';

  @override
  String get appDetailsNoApkFiles =>
      'Pengelola paket tidak melaporkan berkas APK apa pun untuk aplikasi ini.';

  @override
  String get compatibilityNotAnalysed => 'Belum dianalisis';

  @override
  String get compatibilitySupported => 'Didukung';

  @override
  String get compatibilityLimited => 'Terbatas';

  @override
  String get compatibilityUnsupported => 'Tidak didukung';

  @override
  String get compatibilityUnexaminedMessage =>
      'Aplikasi ini tidak dapat diperiksa, jadi belum diketahui seberapa baik ia akan berjalan. Ia masih bisa ditolak saat klon dibuat.';

  @override
  String get compatibilityNoProblems =>
      'Tidak ada masalah kompatibilitas yang diketahui.';

  @override
  String compatibilityExistingClones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Anda sudah punya $count klon aplikasi ini. Yang baru mulai kosong dengan datanya sendiri.',
    );
    return '$_temp0';
  }

  @override
  String get compatibilityAddClone => 'Tambah klon';

  @override
  String get compatibilityCannotClone => 'Tidak bisa diklon';

  @override
  String get findingAppNotFound => 'Aplikasi ini tidak terpasang di perangkat.';

  @override
  String get findingSecureEnvRequired =>
      'Aplikasi ini memerlukan lingkungan aman dan tidak dapat divirtualisasi.';

  @override
  String findingSelfClone(String appName) {
    return '$appName tidak dapat mengklon dirinya sendiri.';
  }

  @override
  String get findingSystemComponent => 'Komponen sistem tidak dapat diklon.';

  @override
  String get findingAbiNotSupported =>
      'Pustaka native aplikasi ini tidak dibangun untuk arsitektur yang didukung mesin.';

  @override
  String get findingRequiresGms =>
      'Layanan Google Play tersedia di dalam klon, tetapi fitur Google yang harus memverifikasi identitas aplikasi ini sendiri tidak didukung — termasuk masuk dan API yang terikat identitas seperti verifikasi lokasi dan SMS.';

  @override
  String findingPushUnsupported(String appName) {
    return 'Notifikasi push tidak akan berfungsi di klon. Layanan Google Play tidak akan mendaftarkan aplikasi ini untuk push selagi ia berjalan di bawah identitas $appName, jadi pesan yang dikirim ke klon tidak pernah sampai. Selebihnya aplikasi tetap bisa dipakai, tetapi harap maklum ada jeda saat pembukaan pertama sementara ia menunggu pendaftaran push yang tidak mungkin berhasil.';
  }

  @override
  String findingStorageUnavailable(String appName) {
    return 'Aplikasi ini memakai penyimpanan bersama, dan build $appName ini tidak menyatakan akses ke semua berkas. Klonnya tidak dapat menjangkau berkas Anda dan tidak akan berfungsi.';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return 'Aplikasi ini memakai penyimpanan bersama. Berikan $appName “akses ke semua berkas” di Setelan → Akses aplikasi khusus sebelum membuka klon, atau ia bisa ditolak saat dijalankan.';
  }

  @override
  String get factsNoNativeCode => 'Tanpa kode native';

  @override
  String get factsAnyNoNativeCode => 'Apa pun — tanpa kode native';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => 'APK tunggal';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'APK terpisah · $count berkas',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => 'tidak diketahui';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => 'Impor lewat pengelola berkas';

  @override
  String get commonSave => 'Simpan';

  @override
  String get renameTitle => 'Ganti nama profil';

  @override
  String get renameFieldLabel => 'Nama profil';

  @override
  String get uninstallTitle => 'Copot pemasangan klon ini?';

  @override
  String uninstallSpaceOf(int index, int count) {
    return 'Ruang $index dari $count';
  }

  @override
  String get uninstallMessage =>
      'Ini akan menghapus salinan aplikasi yang dipilih beserta data lokalnya.';

  @override
  String get uninstallConfirm => 'Copot pemasangan';

  @override
  String get calculatorError => 'Galat';

  @override
  String get disclosureTitle => 'Sebelum Anda mulai';

  @override
  String disclosureIntro(String appName) {
    return '$appName menjalankan salinan kedua dari aplikasi yang Anda pilih. Berikut persisnya apa yang dibaca dan apa yang akan diminta dari Anda.';
  }

  @override
  String get disclosureAppsTitle => 'Aplikasi terpasang Anda';

  @override
  String disclosureAppsBody(String appName) {
    return 'Untuk menampilkan pemilih klon, $appName membaca daftar aplikasi yang terpasang di perangkat ini — nama, ikon, dan versinya. Daftar ini tetap di perangkat Anda. Ia tidak pernah diunggah, dijual, atau dibagikan, dan aplikasi ini tidak memuat iklan, analitik, maupun pelacak.';
  }

  @override
  String get disclosurePermissionsTitle => 'Izin atas nama klon';

  @override
  String disclosurePermissionsBody(String appName) {
    return 'Aplikasi yang diklon berjalan di dalam $appName, jadi sebagian izin Android berlaku padanya atas nama mereka. Anda mungkin diminta sekali untuk mengecualikannya dari pengoptimalan baterai agar pesan dari messenger yang diklon tetap sampai. Hanya ketika Anda mengklon aplikasi berkas atau media, Anda mungkin perlu memberikan akses ke semua berkas di Setelan.';
  }

  @override
  String get disclosureControlTitle => 'Kendali tetap di tangan Anda';

  @override
  String get disclosureControlBody =>
      'Tidak ada yang diminta diam-diam. Anda dapat menolak permintaan mana pun dan tetap memakai aplikasi ini, dan Anda dapat berubah pikiran di Setelan Android kapan saja.';

  @override
  String get disclosureAccept => 'Setuju dan lanjutkan';

  @override
  String get privateSpaceTitle => 'Ruang pribadi';

  @override
  String get privateSpaceOffTitle => 'Ruang pribadi nonaktif';

  @override
  String get privateSpaceOffMessage =>
      'Aktifkan untuk menyembunyikan klon di balik PIN. Aplikasi tersembunyi hilang dari kisi utama dan hanya terbuka di sini.';

  @override
  String get privateSpaceSetUp => 'Siapkan ruang pribadi';

  @override
  String get privateSpaceChangePin => 'Ubah PIN';

  @override
  String get privateSpaceUnlockSection => 'Buka kunci';

  @override
  String get privateSpaceFingerprint => 'Buka dengan sidik jari';

  @override
  String get privateSpaceFingerprintAvailable =>
      'Anda tetap dapat memakai PIN kapan saja.';

  @override
  String get privateSpaceFingerprintUnavailable =>
      'Tidak ada sidik jari atau wajah yang disiapkan di perangkat ini.';

  @override
  String get privateSpaceDisguiseSection => 'Penyamaran';

  @override
  String get privateSpaceDisguiseAsCalculator => 'Samarkan sebagai kalkulator';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return 'Mengganti ikon $appName dengan kalkulator. Ketik PIN ruang pribadi Anda lalu tekan = untuk membuka aplikasi.';
  }

  @override
  String get privateSpaceTurnOff => 'Nonaktifkan ruang pribadi';

  @override
  String get privateSpaceTurnOffNote =>
      'Menonaktifkannya mengembalikan setiap aplikasi tersembunyi ke kisi utama. Klonnya sendiri tidak dihapus.';

  @override
  String get privateSpaceDisguiseOnTitle => 'Samarkan sebagai kalkulator?';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return 'Tampilkan $appName lagi?';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return 'Ikon $appName diganti dengan kalkulator bernama “Calculator”. Untuk membuka $appName, ketik PIN ruang pribadi Anda lalu tekan =. Jika Anda lupa PIN-nya, Anda tidak akan bisa membuka aplikasi ini.';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName akan kembali menampilkan ikon dan namanya sendiri di layar utama.';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => 'Samarkan';

  @override
  String get privateSpaceDisguiseConfirmOff => 'Tampilkan aplikasi';

  @override
  String get privateSpaceDisguiseFailed =>
      'Tidak dapat mengubah tampilan aplikasi.';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '$appName kini tampak seperti kalkulator di layar utama Anda.';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName kembali ke layar utama Anda.';
  }

  @override
  String get privateSpaceTurnOffTitle => 'Nonaktifkan ruang pribadi?';

  @override
  String get privateSpaceTurnOffMessage =>
      'Setiap aplikasi tersembunyi akan kembali ke kisi utama, dan PIN akan dilupakan. Klonnya tetap disimpan.';

  @override
  String get privateSpaceTurnOffConfirm => 'Nonaktifkan';

  @override
  String get privateSpaceTurnedOff => 'Ruang pribadi dinonaktifkan.';

  @override
  String get pinCreateTitle => 'Buat PIN';

  @override
  String get pinChangeTitle => 'Ubah PIN';

  @override
  String get pinCreateMessage =>
      'PIN ini mengunci ruang pribadi. Simpan di tempat yang tidak akan Anda lupakan: tanpa PIN, klon tersembunyi tidak bisa dipulihkan.';

  @override
  String get pinChangeMessage =>
      'Masukkan PIN Anda saat ini, lalu pilih yang baru.';

  @override
  String get pinCurrentLabel => 'PIN saat ini';

  @override
  String get pinNewLabel => 'PIN baru';

  @override
  String get pinConfirmLabel => 'Konfirmasi PIN';

  @override
  String get pinCreateConfirm => 'Buat ruang pribadi';

  @override
  String get pinSaveConfirm => 'Simpan PIN';

  @override
  String pinLengthError(int minimum, int maximum) {
    return 'Gunakan $minimum sampai $maximum digit.';
  }

  @override
  String get pinMismatchError => 'Kedua PIN tidak cocok.';

  @override
  String get pinCurrentIncorrect => 'PIN saat ini salah.';

  @override
  String get unlockTitle => 'Buka kunci ruang pribadi';

  @override
  String get unlockPinLabel => 'PIN';

  @override
  String get unlockUseFingerprint => 'Gunakan sidik jari';

  @override
  String get unlockConfirm => 'Buka kunci';

  @override
  String get unlockIncorrectPin => 'PIN salah';

  @override
  String get unlockFingerprintUnavailable =>
      'Buka kunci dengan sidik jari sedang tidak tersedia.';

  @override
  String get unlockFingerprintNotRecognised => 'Sidik jari tidak dikenali.';

  @override
  String get unlockBiometricReason => 'Buka kunci ruang pribadi Anda';

  @override
  String get privateTileEmpty => 'Ruang pribadi, kosong';

  @override
  String privateTileHidden(int count) {
    return 'Ruang pribadi, $count tersembunyi';
  }

  @override
  String get settingsSectionPrivacy => 'Privasi';

  @override
  String get settingsPrivateSpaceSubtitle =>
      'Sembunyikan aplikasi di balik PIN';

  @override
  String get settingsOn => 'Aktif';

  @override
  String get settingsOff => 'Nonaktif';

  @override
  String get componentBaseApk => 'APK dasar';

  @override
  String get componentSplitApk => 'APK terpisah';

  @override
  String get componentNoNativeLibraries => 'Tanpa pustaka native';
}
