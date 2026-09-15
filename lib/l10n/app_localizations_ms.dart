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

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNotNow => 'Bukan sekarang';

  @override
  String get commonClose => 'Tutup';

  @override
  String get commonMore => 'Lagi';

  @override
  String get commonFailureTitle => 'Tidak dapat berbuat demikian';

  @override
  String get homePrivateSpaceTitle => 'Ruang peribadi';

  @override
  String get homeSubtitle => 'Ruang peribadi anda';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apl tersembunyi',
      zero: 'Tiada apl tersembunyi',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => 'Kunci dan tutup';

  @override
  String get homeMenuSettings => 'Tetapan';

  @override
  String get homeMenuDeveloperTools => 'Alat pembangun';

  @override
  String get homeAddApp => 'Tambah apl';

  @override
  String get homeEmptyTitle => 'Ruang anda kosong';

  @override
  String get homeEmptyMessage =>
      'Tambah apl untuk mencipta salinan peribadi pertama anda.';

  @override
  String get homeEmptyAction => 'Tambah apl pertama anda';

  @override
  String get homePrivateEmptyTitle => 'Belum ada yang disembunyikan';

  @override
  String get homePrivateEmptyMessage =>
      'Tekan lama mana-mana apl pada grid utama dan pilih Sembunyikan untuk memindahkannya ke sini.';

  @override
  String get homeSetUpPrivateSpaceTitle => 'Sediakan ruang peribadi?';

  @override
  String get homeSetUpPrivateSpaceMessage =>
      'Menyembunyikan klon memerlukan ruang peribadi. Cipta satu dengan PIN dahulu.';

  @override
  String get homeSetUpPrivateSpaceConfirm => 'Sediakan';

  @override
  String get homeEngineInactive =>
      'Enjin virtualisasi tidak aktif pada peranti ini, jadi klon tidak boleh berjalan dalam bekas terasing.';

  @override
  String get homeEngineUnavailable =>
      'Enjin virtualisasi tidak tersedia pada peranti ini.';

  @override
  String cloneSpaceLabel(int index) {
    return 'Ruang $index';
  }

  @override
  String get cloneActionsCompatibility => 'Keserasian';

  @override
  String get cloneActionsManage => 'Urus';

  @override
  String get cloneActionUninstall => 'Nyahpasang';

  @override
  String get cloneActionClone => 'Klon';

  @override
  String get cloneActionShortcut => 'Pintasan';

  @override
  String get cloneActionSpaceInfo => 'Maklumat ruang';

  @override
  String get cloneActionEditName => 'Ubah nama';

  @override
  String get cloneActionForceStop => 'Paksa henti';

  @override
  String get cloneActionClearCache => 'Kosongkan cache';

  @override
  String get cloneActionClearStorage => 'Padam data';

  @override
  String get cloneActionHide => 'Sembunyikan';

  @override
  String get cloneActionUnhide => 'Tunjukkan';

  @override
  String get cloneActionShareApp => 'Kongsi apl';

  @override
  String get cloneActionNotifications => 'Pemberitahuan';

  @override
  String get cloneActionPermissions => 'Kebenaran';

  @override
  String get cloneActionGoogleServicesInstalled =>
      'Perkhidmatan Google (microG) dipasang';

  @override
  String get cloneActionInstallGoogleServices =>
      'Pasang perkhidmatan Google (microG)';

  @override
  String cloneTileSibling(int index, int count) {
    return ', klon $index daripada $count';
  }

  @override
  String get cloneTileOpening => ', sedang dibuka';

  @override
  String get cloneTileRunning => ', sedang berjalan';

  @override
  String get cloneTileCannotLaunch =>
      ', tidak boleh dilancarkan pada peranti ini';

  @override
  String get cloneForceStopTitle => 'Paksa henti apl ini?';

  @override
  String get cloneForceStopMessage =>
      'Apl akan berhenti berjalan sehingga anda membukanya semula.';

  @override
  String get cloneForceStopConfirm => 'Paksa henti';

  @override
  String get cloneClearCacheTitle => 'Kosongkan cache apl?';

  @override
  String get cloneClearCacheMessage =>
      'Ini akan membuang fail sementara klon ini.';

  @override
  String get cloneClearCacheConfirm => 'Kosongkan cache';

  @override
  String get cloneClearStorageTitle => 'Padam data apl?';

  @override
  String get cloneClearStorageMessage =>
      'Ini akan memadam kekal akaun, tetapan dan data setempat klon ini.';

  @override
  String get cloneClearStorageConfirm => 'Padam data';

  @override
  String get cloneInstallGoogleServicesTitle => 'Pasang perkhidmatan Google?';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName akan memasang microG terbinanya ke dalam klon ini sebagai perkhidmatan Google Play. Klon mengekalkan datanya. Ini boleh mengambil beberapa saat.';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => 'Pasang';

  @override
  String cloneStopped(String name) {
    return '$name dihentikan.';
  }

  @override
  String cloneCacheCleared(String name) {
    return 'Cache $name dikosongkan.';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name telah ditetapkan semula. Pembukaan seterusnya akan jadi pembukaan pertama.';
  }

  @override
  String cloneHidden(String name) {
    return '$name disembunyikan dalam ruang peribadi.';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name kembali ke grid utama.';
  }

  @override
  String get cloneShortcutAdded =>
      'Sahkan pintasan pada skrin utama anda untuk selesai menambahnya.';

  @override
  String get cloneGoogleServicesInstalling => 'Memasang perkhidmatan Google…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return 'Perkhidmatan Google dipasang dalam $name.';
  }

  @override
  String get cloneCountTitle => 'Klon apl';

  @override
  String cloneCountMessage(String appName) {
    return 'Cipta salinan tambahan $appName.';
  }

  @override
  String get cloneCountLabel => 'Bilangan klon';

  @override
  String get cloneCountDecrease => 'Kurang satu';

  @override
  String get cloneCountIncrease => 'Tambah satu';

  @override
  String get cloneCountConfirm => 'Klon';

  @override
  String cloneCreating(int created, int total) {
    return 'Mencipta $created daripada $total…';
  }

  @override
  String get cloneCreatingFinishing => 'Menyelesaikan…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Menambah $count lagi salinan $appName.',
      one: 'Menambah satu lagi salinan $appName.',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return 'Dicipta $created daripada $total. $failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return 'Pilih dari 1 hingga $maximum';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return 'Hanya $free yang kosong, dan peranti menyimpan setengah gigabait sebagai simpanan.';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return 'Sehingga $maximum — tinggal $free ruang';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return 'Sehingga $maximum pada satu masa pada peranti dengan memori $memory';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return 'Tiada ruang untuk satu lagi klon $appName. $reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return 'Ruang tidak cukup untuk $count lagi klon $appName. $reason.';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return 'Kebenaran · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => 'Tidak dapat membaca kebenaran';

  @override
  String get clonePermissionsEmptyTitle => 'Tiada apa untuk dihadkan';

  @override
  String get clonePermissionsEmptyMessage =>
      'Apl ini tidak mengisytiharkan kebenaran berbahaya, jadi tiada apa untuk dibenarkan atau ditolak bagi klon ini.';

  @override
  String clonePermissionsNote(String appName) {
    return 'Ini terpakai hanya pada klon ini. Apl yang diklon biasanya bertanya sebelum menggunakan kebenaran, dan di sinilah jawapan itu dihadkan — apl yang melangkau soalan itu masih boleh mencapai perkakasan melalui kebenaran $appName sendiri.';
  }

  @override
  String get spaceInfoTitle => 'Maklumat ruang';

  @override
  String get spaceInfoIdentifiers => 'Pengecam peranti';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => 'Enjin tidak tersedia';

  @override
  String get spaceInfoStateRunning => 'Berjalan';

  @override
  String get spaceInfoStateActive => 'Aktif';

  @override
  String get spaceInfoStateRebuilds => 'Dibina semula semasa dibuka';

  @override
  String get spaceInfoNoContainer =>
      'Ruang ini belum mempunyai bekas, jadi ia tiada pengecam. Buka sekali dan ia akan muncul di sini.';

  @override
  String get spaceInfoDeviceId => 'ID peranti';

  @override
  String get spaceInfoAndroidId => 'ID Android';

  @override
  String get spaceInfoSerialNumber => 'Nombor siri';

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
  String get commonApply => 'Guna';

  @override
  String get pickerTitle => 'Tambah apl';

  @override
  String get pickerSearchHint => 'Cari apl';

  @override
  String get pickerFilterTooltip => 'Tapis dan isih';

  @override
  String get pickerErrorTitle => 'Tidak dapat menyenaraikan apl';

  @override
  String get pickerNoMatchesTitle => 'Tiada apl yang sepadan';

  @override
  String get pickerNoMatchesMessage =>
      'Cuba carian lain, atau import APK sebaliknya.';

  @override
  String get pickerPopular => 'Popular';

  @override
  String get pickerQuickPicks => 'Pilihan pantas';

  @override
  String get pickerInstalledApps => 'Apl dipasang';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apl',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => 'Sistem';

  @override
  String get pickerCannotClone =>
      'Apl ini tidak boleh diklon pada peranti ini.';

  @override
  String get pickerApkUnreadable => 'APK yang dipilih tidak dapat dibaca.';

  @override
  String get filterTitle => 'Tapis dan isih';

  @override
  String get filterSort => 'Isih';

  @override
  String get filterSortName => 'Nama apl';

  @override
  String get filterSortRecentlyInstalled => 'Baru dipasang';

  @override
  String get filterSortRecentlyUpdated => 'Baru dikemas kini';

  @override
  String get filterFilter => 'Tapis';

  @override
  String get filterAllApps => 'Semua apl';

  @override
  String get filterUserApps => 'Apl pengguna';

  @override
  String get filterSystemApps => 'Apl sistem';

  @override
  String get filterNotAdded => 'Belum ditambah';

  @override
  String get filterAlreadyAdded => 'Sudah ditambah';

  @override
  String get filterArchitecture => 'Seni bina';

  @override
  String get filterArch64 => '64-bit';

  @override
  String get filterArch32 => '32-bit';

  @override
  String get filterArchNoNativeCode => 'Tiada kod natif';

  @override
  String get filterPackageType => 'Jenis pakej';

  @override
  String get filterPackageSingle => 'APK tunggal';

  @override
  String get filterPackageSplit => 'APK terpisah';

  @override
  String filterImportApk(String appName) {
    return 'Buka pakej apl $appName';
  }

  @override
  String get appSheetAddClone => 'Tambah klon';

  @override
  String get appSheetAddAnother => 'Tambah satu lagi';

  @override
  String get appSheetShareApp => 'Kongsi apl';

  @override
  String get appSheetAppDetails => 'Butiran apl';

  @override
  String get appDetailsTitle => 'Butiran apl';

  @override
  String get appDetailsAdvanced => 'Butiran lanjutan';

  @override
  String get appDetailsPackageName => 'Nama pakej';

  @override
  String get appDetailsVersion => 'Versi';

  @override
  String get appDetailsArchitecture => 'Seni bina';

  @override
  String get appDetailsBitness => 'Lebar bit';

  @override
  String get appDetailsPackageType => 'Jenis pakej';

  @override
  String get appDetailsApkComponents => 'Komponen APK';

  @override
  String get appDetailsTotalApkSize => 'Jumlah saiz APK';

  @override
  String get appDetailsSigningSha256 => 'SHA-256 sijil penandatanganan';

  @override
  String get appDetailsSigningUnreadable => 'tidak dapat dibaca';

  @override
  String get appDetailsNoApkFiles =>
      'Pengurus pakej tidak melaporkan sebarang fail APK untuk apl ini.';

  @override
  String get compatibilityNotAnalysed => 'Belum dianalisis';

  @override
  String get compatibilitySupported => 'Disokong';

  @override
  String get compatibilityLimited => 'Terhad';

  @override
  String get compatibilityUnsupported => 'Tidak disokong';

  @override
  String get compatibilityUnexaminedMessage =>
      'Apl ini tidak dapat diperiksa, jadi tiada apa yang diketahui tentang sebaik mana ia akan berjalan. Ia masih boleh ditolak semasa klon dicipta.';

  @override
  String get compatibilityNoProblems =>
      'Tiada masalah keserasian yang diketahui.';

  @override
  String compatibilityExistingClones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Anda sudah mempunyai $count klon apl ini. Yang baharu bermula kosong dengan datanya sendiri.',
    );
    return '$_temp0';
  }

  @override
  String get compatibilityAddClone => 'Tambah klon';

  @override
  String get compatibilityCannotClone => 'Tidak boleh diklon';

  @override
  String get findingAppNotFound => 'Aplikasi ini tidak dipasang pada peranti.';

  @override
  String get findingSecureEnvRequired =>
      'Aplikasi ini memerlukan persekitaran selamat dan tidak boleh divirtualisasikan.';

  @override
  String findingSelfClone(String appName) {
    return '$appName tidak boleh mengklon dirinya sendiri.';
  }

  @override
  String get findingSystemComponent => 'Komponen sistem tidak boleh diklon.';

  @override
  String get findingAbiNotSupported =>
      'Pustaka natif apl ini tidak dibina untuk seni bina yang disokong oleh enjin.';

  @override
  String get findingRequiresGms =>
      'Perkhidmatan Google Play tersedia di dalam klon, tetapi ciri Google yang perlu mengesahkan identiti apl ini sendiri tidak disokong — termasuk log masuk dan API terikat identiti seperti pengesahan lokasi dan SMS.';

  @override
  String findingPushUnsupported(String appName) {
    return 'Pemberitahuan tolak tidak akan berfungsi dalam klon. Perkhidmatan Google Play tidak akan mendaftarkan apl ini untuk tolak selagi ia berjalan di bawah identiti $appName, jadi mesej yang dihantar kepada klon tidak pernah sampai. Selain itu apl masih boleh digunakan, tetapi jangkakan jeda pada pembukaan pertama sementara ia menunggu pendaftaran tolak yang tidak mungkin berjaya.';
  }

  @override
  String findingStorageUnavailable(String appName) {
    return 'Apl ini menggunakan storan kongsi, dan binaan $appName ini tidak mengisytiharkan akses kepada semua fail. Klonnya tidak dapat mencapai fail anda dan tidak akan berfungsi.';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return 'Apl ini menggunakan storan kongsi. Berikan $appName “akses kepada semua fail” dalam Tetapan → Akses apl khas sebelum melancarkan klon, jika tidak ia mungkin ditolak semasa dilancarkan.';
  }

  @override
  String get factsNoNativeCode => 'Tiada kod natif';

  @override
  String get factsAnyNoNativeCode => 'Mana-mana — tiada kod natif';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => 'APK tunggal';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'APK terpisah · $count fail',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => 'tidak diketahui';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => 'Import melalui pengurus fail';

  @override
  String get commonSave => 'Simpan';

  @override
  String get renameTitle => 'Namakan semula profil';

  @override
  String get renameFieldLabel => 'Nama profil';

  @override
  String get uninstallTitle => 'Nyahpasang klon ini?';

  @override
  String uninstallSpaceOf(int index, int count) {
    return 'Ruang $index daripada $count';
  }

  @override
  String get uninstallMessage =>
      'Ini akan membuang salinan apl yang dipilih dan data setempatnya.';

  @override
  String get uninstallConfirm => 'Nyahpasang';

  @override
  String get calculatorError => 'Ralat';

  @override
  String get disclosureTitle => 'Sebelum anda bermula';

  @override
  String disclosureIntro(String appName) {
    return '$appName menjalankan salinan kedua bagi apl yang anda pilih. Inilah apa yang ia baca dan apa yang ia akan minta daripada anda.';
  }

  @override
  String get disclosureAppsTitle => 'Apl dipasang anda';

  @override
  String disclosureAppsBody(String appName) {
    return 'Untuk memaparkan pemilih klon, $appName membaca senarai apl yang dipasang pada peranti ini — nama, ikon dan versinya. Senarai ini kekal pada peranti anda. Ia tidak pernah dimuat naik, dijual atau dikongsi, dan apl ini tiada iklan, analitik mahupun penjejak.';
  }

  @override
  String get disclosurePermissionsTitle => 'Kebenaran bagi pihak klon';

  @override
  String disclosurePermissionsBody(String appName) {
    return 'Apl yang diklon berjalan di dalam $appName, jadi sesetengah kebenaran Android terpakai padanya bagi pihak mereka. Anda mungkin diminta sekali untuk mengecualikannya daripada pengoptimuman bateri supaya apl pemesejan yang diklon terus menyampaikan mesej. Hanya apabila anda mengklon apl fail atau media, anda mungkin perlu memberikan akses kepada semua fail dalam Tetapan.';
  }

  @override
  String get disclosureControlTitle => 'Kawalan kekal pada anda';

  @override
  String get disclosureControlBody =>
      'Tiada apa yang diminta secara senyap. Anda boleh menolak mana-mana permintaan ini dan masih menggunakan apl, dan anda boleh berubah fikiran dalam Tetapan Android pada bila-bila masa.';

  @override
  String get disclosureAccept => 'Setuju dan teruskan';

  @override
  String get privateSpaceTitle => 'Ruang peribadi';

  @override
  String get privateSpaceOffTitle => 'Ruang peribadi dimatikan';

  @override
  String get privateSpaceOffMessage =>
      'Hidupkannya untuk menyembunyikan klon di sebalik PIN. Apl tersembunyi hilang daripada grid utama dan hanya dibuka di sini.';

  @override
  String get privateSpaceSetUp => 'Sediakan ruang peribadi';

  @override
  String get privateSpaceChangePin => 'Tukar PIN';

  @override
  String get privateSpaceUnlockSection => 'Buka kunci';

  @override
  String get privateSpaceFingerprint => 'Buka kunci dengan cap jari';

  @override
  String get privateSpaceFingerprintAvailable =>
      'Anda masih boleh menggunakan PIN anda pada bila-bila masa.';

  @override
  String get privateSpaceFingerprintUnavailable =>
      'Tiada cap jari atau wajah disediakan pada peranti ini.';

  @override
  String get privateSpaceDisguiseSection => 'Penyamaran';

  @override
  String get privateSpaceDisguiseAsCalculator => 'Samarkan sebagai kalkulator';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return 'Menggantikan ikon $appName dengan kalkulator. Taip PIN ruang peribadi anda dan tekan = untuk membuka apl.';
  }

  @override
  String get privateSpaceTurnOff => 'Matikan ruang peribadi';

  @override
  String get privateSpaceTurnOffNote =>
      'Mematikannya mengembalikan setiap apl tersembunyi ke grid utama. Klon itu sendiri tidak dipadam.';

  @override
  String get privateSpaceDisguiseOnTitle => 'Samarkan sebagai kalkulator?';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return 'Tunjukkan $appName semula?';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return 'Ikon $appName digantikan dengan kalkulator bernama “Calculator”. Untuk membuka $appName, taip PIN ruang peribadi anda dan tekan =. Jika anda terlupa PIN, anda tidak akan dapat membuka apl.';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName akan menunjukkan semula ikon dan namanya sendiri pada skrin utama.';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => 'Samarkan';

  @override
  String get privateSpaceDisguiseConfirmOff => 'Tunjukkan apl';

  @override
  String get privateSpaceDisguiseFailed => 'Tidak dapat menukar rupa apl.';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '$appName kini kelihatan seperti kalkulator pada skrin utama anda.';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName kembali pada skrin utama anda.';
  }

  @override
  String get privateSpaceTurnOffTitle => 'Matikan ruang peribadi?';

  @override
  String get privateSpaceTurnOffMessage =>
      'Setiap apl tersembunyi akan kembali ke grid utama, dan PIN akan dilupakan. Klon dikekalkan.';

  @override
  String get privateSpaceTurnOffConfirm => 'Matikan';

  @override
  String get privateSpaceTurnedOff => 'Ruang peribadi dimatikan.';

  @override
  String get pinCreateTitle => 'Cipta PIN';

  @override
  String get pinChangeTitle => 'Tukar PIN';

  @override
  String get pinCreateMessage =>
      'PIN ini mengunci ruang peribadi. Simpan di tempat yang anda tidak akan lupa: tiada cara untuk memulihkan klon tersembunyi tanpanya.';

  @override
  String get pinChangeMessage =>
      'Masukkan PIN semasa anda, kemudian pilih yang baharu.';

  @override
  String get pinCurrentLabel => 'PIN semasa';

  @override
  String get pinNewLabel => 'PIN baharu';

  @override
  String get pinConfirmLabel => 'Sahkan PIN';

  @override
  String get pinCreateConfirm => 'Cipta ruang peribadi';

  @override
  String get pinSaveConfirm => 'Simpan PIN';

  @override
  String pinLengthError(int minimum, int maximum) {
    return 'Gunakan $minimum hingga $maximum digit.';
  }

  @override
  String get pinMismatchError => 'Kedua-dua PIN tidak sepadan.';

  @override
  String get pinCurrentIncorrect => 'PIN semasa tidak betul.';

  @override
  String get unlockTitle => 'Buka kunci ruang peribadi';

  @override
  String get unlockPinLabel => 'PIN';

  @override
  String get unlockUseFingerprint => 'Guna cap jari';

  @override
  String get unlockConfirm => 'Buka kunci';

  @override
  String get unlockIncorrectPin => 'PIN salah';

  @override
  String get unlockFingerprintUnavailable =>
      'Buka kunci dengan cap jari tidak tersedia buat masa ini.';

  @override
  String get unlockFingerprintNotRecognised => 'Cap jari tidak dikenali.';

  @override
  String get unlockBiometricReason => 'Buka kunci ruang peribadi anda';

  @override
  String get privateTileEmpty => 'Ruang peribadi, kosong';

  @override
  String privateTileHidden(int count) {
    return 'Ruang peribadi, $count tersembunyi';
  }

  @override
  String get settingsSectionPrivacy => 'Privasi';

  @override
  String get settingsPrivateSpaceSubtitle => 'Sembunyikan apl di sebalik PIN';

  @override
  String get settingsOn => 'Hidup';

  @override
  String get settingsOff => 'Mati';

  @override
  String get componentBaseApk => 'APK asas';

  @override
  String get componentSplitApk => 'APK terpisah';

  @override
  String get componentNoNativeLibraries => 'Tiada pustaka natif';

  @override
  String get errorProfileNameEmpty => 'Klon perlukan satu nama.';

  @override
  String errorProfileNameTooLong(int maximum) {
    return 'Nama klon boleh sepanjang $maximum aksara sahaja.';
  }

  @override
  String get errorProfileStorageUnreadable =>
      'Klon anda yang disimpan tidak dapat dibaca.';

  @override
  String get errorProfileNotFound => 'Klon itu sudah tiada.';

  @override
  String get errorBridgeFailed =>
      'Ada masalah semasa berhubung dengan bahagian apl yang menguruskan klon.';

  @override
  String get errorBridgeUnsupportedPlatform =>
      'Ciri ini hanya tersedia pada Android.';

  @override
  String get errorTestAppCheckFailed =>
      'Sama ada apl ujian dipasang tidak dapat disemak.';

  @override
  String get errorEngineInitFailed =>
      'Enjin virtualisasi gagal dimulakan pada peranti ini.';

  @override
  String get errorEngineAndroidTooOld =>
      'Enjin virtualisasi memerlukan versi Android yang lebih baharu.';

  @override
  String get errorEngineNoResponse =>
      'Enjin virtualisasi tidak menjawab. Cuba lagi.';

  @override
  String get errorNoContainer =>
      'Klon ini belum mempunyai bekas. Buka sekali dan cuba lagi.';

  @override
  String get errorLaunchRefused => 'Enjin enggan membuka klon ini.';

  @override
  String get errorAlreadyCloned => 'Apl ini sudah diklon.';

  @override
  String get errorClearCacheFailed =>
      'Sebahagian cache klon ini tidak dapat dipadam.';

  @override
  String get errorClearDataFailed => 'Data klon ini tidak dapat dipadam.';

  @override
  String get errorShortcutsUnsupported =>
      'Pelancar ini tidak menyokong penambahan pintasan.';

  @override
  String get errorShortcutRefused => 'Pelancar menolak pintasan.';

  @override
  String get errorApkGone =>
      'APK klon ini tiada lagi pada peranti, jadi tiada apa untuk dikongsi.';

  @override
  String get errorShareFailed => 'Apl tidak dapat dikongsi.';

  @override
  String get errorApkUnreadable =>
      'Salah satu APK yang dipilih tidak dapat dibaca.';

  @override
  String get errorApkPackageMismatch =>
      'Semua APK yang dipilih mesti milik apl yang sama.';

  @override
  String get errorApkVersionMismatch =>
      'Semua APK yang dipilih mesti mempunyai versi yang sama.';

  @override
  String get errorApkBaseRequired =>
      'Pilih tepat satu APK asas dan satu atau lebih split konfigurasi.';

  @override
  String get errorApkDuplicateSplit =>
      'Split APK yang sama dipilih lebih daripada sekali.';
}
