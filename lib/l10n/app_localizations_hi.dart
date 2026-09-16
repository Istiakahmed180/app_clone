// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get settingsTitle => 'सेटिंग';

  @override
  String get settingsSectionSupport => 'सहायता';

  @override
  String get settingsSectionLegal => 'कानूनी';

  @override
  String get settingsSectionAbout => 'ऐप के बारे में';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get settingsAppearance => 'रूप';

  @override
  String get settingsContact => 'संपर्क करें';

  @override
  String get settingsContactSubtitle => 'सवाल या सुझाव';

  @override
  String get settingsRate => 'रेटिंग दें';

  @override
  String settingsRateSubtitle(String appName) {
    return '$appName पसंद आया? समीक्षा लिखें';
  }

  @override
  String get settingsPrivacyPolicy => 'गोपनीयता नीति';

  @override
  String get settingsTermsOfService => 'सेवा की शर्तें';

  @override
  String get settingsVersion => 'वर्शन';

  @override
  String get settingsArchitecture => 'डिवाइस आर्किटेक्चर';

  @override
  String get settingsArchitectureSubtitle => 'ऐप अनुकूलता';

  @override
  String get settingsBits64 => '64-बिट';

  @override
  String get settingsBits32 => '32-बिट';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'समर्थित ABI';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'अभी प्रकाशित नहीं';

  @override
  String get settingsNotListedYet => 'अभी स्टोर पर नहीं';

  @override
  String get settingsNotSetUpYet => 'अभी सेट अप नहीं';

  @override
  String get commonUnavailable => 'उपलब्ध नहीं';

  @override
  String get appearanceTitle => 'रूप';

  @override
  String get appearancePreview => 'पूर्वावलोकन';

  @override
  String get appearanceChooseTheme => 'थीम चुनें';

  @override
  String get appearanceSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get appearanceSystemSubtitle => 'अपने डिवाइस की सेटिंग के अनुसार';

  @override
  String get appearanceLight => 'लाइट';

  @override
  String get appearanceLightSubtitle => 'हमेशा लाइट थीम';

  @override
  String get appearanceDark => 'डार्क';

  @override
  String get appearanceDarkSubtitle => 'हमेशा डार्क थीम';

  @override
  String appearanceInstantNote(String appName) {
    return 'थीम में बदलाव पूरे $appName में तुरंत लागू होते हैं।';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return '$theme थीम का पूर्वावलोकन';
  }

  @override
  String get languageTitle => 'भाषा';

  @override
  String get languageSearchHint => 'भाषाएँ खोजें';

  @override
  String get languageClearSearch => 'खोज साफ़ करें';

  @override
  String languageNote(String appName) {
    return '$appName में इस्तेमाल होने वाली भाषा चुनें।';
  }

  @override
  String get languageSectionHeader => 'भाषा';

  @override
  String get languageSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get languageSystemSubtitle => 'अपने डिवाइस की भाषा इस्तेमाल करें';

  @override
  String get languageInstantNote => 'भाषा में बदलाव तुरंत लागू होते हैं।';

  @override
  String languageNoMatches(String query) {
    return '“$query” से कोई भाषा मेल नहीं खाती।';
  }

  @override
  String get contactTitle => 'संपर्क करें';

  @override
  String get contactHeroTitle => 'हम कैसे मदद कर सकते हैं?';

  @override
  String contactHeroSubtitle(String appName) {
    return '$appName टीम से संपर्क करने का अपना पसंदीदा तरीका चुनें।';
  }

  @override
  String get contactSectionOptions => 'संपर्क के विकल्प';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'हमारी सहायता टीम से चैट करें';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Telegram पर हमें संदेश भेजें';

  @override
  String get contactEmail => 'ईमेल';

  @override
  String get contactEmailSubtitle => 'हमें ईमेल भेजें';

  @override
  String get contactResponseTime => 'जवाब देने का समय';

  @override
  String get contactResponseTimeValue =>
      'हम आमतौर पर 1–2 कार्यदिवसों में जवाब देते हैं।';

  @override
  String get contactPrivacyNote =>
      'हम आपके संदेश का इस्तेमाल केवल सहायता देने के लिए करेंगे।';

  @override
  String contactNoMailApp(String email) {
    return 'कोई मेल ऐप नहीं खुल सका। इसके बजाय $email पर लिखें।';
  }

  @override
  String get contactWhatsAppFailed => 'WhatsApp नहीं खुल सका।';

  @override
  String get contactTelegramFailed => 'Telegram नहीं खुल सका।';

  @override
  String get contactPlayStoreFailed => 'Play Store नहीं खुल सका।';

  @override
  String contactLegalOpenFailed(String document) {
    return '$document नहीं खुल सका।';
  }

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonOk => 'ठीक है';

  @override
  String get commonNotNow => 'अभी नहीं';

  @override
  String get commonClose => 'बंद करें';

  @override
  String get commonMore => 'और';

  @override
  String get commonFailureTitle => 'यह नहीं हो सका';

  @override
  String get homePrivateSpaceTitle => 'निजी स्पेस';

  @override
  String get homeSubtitle => 'आपका निजी स्पेस';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count छिपे ऐप',
      one: '1 छिपा ऐप',
      zero: 'कोई छिपा ऐप नहीं',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => 'लॉक करके बंद करें';

  @override
  String get homeMenuSettings => 'सेटिंग';

  @override
  String get homeMenuDeveloperTools => 'डेवलपर टूल';

  @override
  String get homeAddApp => 'ऐप जोड़ें';

  @override
  String get homeEmptyTitle => 'आपका स्पेस खाली है';

  @override
  String get homeEmptyMessage =>
      'अपनी पहली निजी कॉपी बनाने के लिए कोई ऐप जोड़ें।';

  @override
  String get homeEmptyAction => 'अपना पहला ऐप जोड़ें';

  @override
  String get homePrivateEmptyTitle => 'अभी कुछ छिपा नहीं है';

  @override
  String get homePrivateEmptyMessage =>
      'मुख्य ग्रिड में किसी भी ऐप को दबाए रखें और उसे यहाँ लाने के लिए \'छिपाएँ\' चुनें।';

  @override
  String get homeSetUpPrivateSpaceTitle => 'निजी स्पेस सेट करें?';

  @override
  String get homeSetUpPrivateSpaceMessage =>
      'क्लोन छिपाने के लिए निजी स्पेस चाहिए। पहले पिन के साथ एक बनाएँ।';

  @override
  String get homeSetUpPrivateSpaceConfirm => 'सेट करें';

  @override
  String get homeEngineInactive =>
      'इस डिवाइस पर वर्चुअलाइज़ेशन इंजन सक्रिय नहीं है, इसलिए क्लोन अलग कंटेनरों में नहीं चल सकते।';

  @override
  String get homeEngineUnavailable =>
      'इस डिवाइस पर वर्चुअलाइज़ेशन इंजन उपलब्ध नहीं है।';

  @override
  String cloneSpaceLabel(int index) {
    return 'स्पेस $index';
  }

  @override
  String get cloneActionsManage => 'प्रबंधन';

  @override
  String get cloneActionUninstall => 'अनइंस्टॉल करें';

  @override
  String get cloneActionClone => 'क्लोन करें';

  @override
  String get cloneActionShortcut => 'शॉर्टकट';

  @override
  String get cloneActionSpaceInfo => 'स्पेस जानकारी';

  @override
  String get cloneActionEditName => 'नाम बदलें';

  @override
  String get cloneActionChangeIcon => 'आइकन बदलें';

  @override
  String get cloneIconPickerChoose => 'तस्वीर चुनें';

  @override
  String get cloneIconPickerUseAppIcon => 'ऐप का आइकन इस्तेमाल करें';

  @override
  String get errorCloneIconFailed =>
      'उस तस्वीर को आइकन के रूप में इस्तेमाल नहीं किया जा सका। कोई दूसरी आज़माएँ।';

  @override
  String get cloneIconPickerTitle => 'इस क्लोन का आइकन';

  @override
  String get cloneIconPickerMessage =>
      'इसे अपनी कोई तस्वीर दें, या ऐप का आइकन रखकर उस पर रंग का निशान लगाएँ — दोनों ही तरह आप इसे उसी ऐप के अपने दूसरे क्लोन से एक नज़र में पहचान लेंगे।';

  @override
  String get cloneActionForceStop => 'ज़बरदस्ती रोकें';

  @override
  String get cloneActionClearCache => 'कैश साफ़ करें';

  @override
  String get cloneActionClearStorage => 'डेटा साफ़ करें';

  @override
  String get cloneActionHide => 'छिपाएँ';

  @override
  String get cloneActionUnhide => 'दिखाएँ';

  @override
  String get cloneActionShareApp => 'ऐप शेयर करें';

  @override
  String get cloneActionPermissions => 'अनुमतियाँ';

  @override
  String get cloneActionInstallGoogleServices => 'Google सेवाएँ इंस्टॉल करें';

  @override
  String cloneTileSibling(int index, int count) {
    return ', $count में से क्लोन $index';
  }

  @override
  String get cloneTileOpening => ', खुल रहा है';

  @override
  String get cloneTileRunning => ', चल रहा है';

  @override
  String get cloneTileCannotLaunch => ', इस डिवाइस पर शुरू नहीं हो सकता';

  @override
  String get cloneForceStopTitle => 'इस ऐप को ज़बरदस्ती रोकें?';

  @override
  String get cloneForceStopMessage =>
      'जब तक आप इसे दोबारा नहीं खोलते, ऐप चलना बंद कर देगा।';

  @override
  String get cloneForceStopConfirm => 'ज़बरदस्ती रोकें';

  @override
  String get cloneClearCacheTitle => 'ऐप का कैश साफ़ करें?';

  @override
  String get cloneClearCacheMessage =>
      'इससे इस क्लोन की अस्थायी फ़ाइलें हट जाएँगी।';

  @override
  String get cloneClearCacheConfirm => 'कैश साफ़ करें';

  @override
  String get cloneClearStorageTitle => 'ऐप का डेटा साफ़ करें?';

  @override
  String get cloneClearStorageMessage =>
      'इससे इस क्लोन के खाते, सेटिंग और स्थानीय डेटा हमेशा के लिए मिट जाएँगे।';

  @override
  String get cloneClearStorageConfirm => 'डेटा साफ़ करें';

  @override
  String get cloneInstallGoogleServicesTitle => 'Google सेवाएँ इंस्टॉल करें?';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName इस क्लोन में Google Play सेवाएँ इंस्टॉल करेगा। क्लोन का डेटा बना रहेगा। इसमें कुछ सेकंड लग सकते हैं।';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => 'इंस्टॉल करें';

  @override
  String cloneStopped(String name) {
    return '$name रोक दिया गया।';
  }

  @override
  String cloneCacheCleared(String name) {
    return '$name का कैश साफ़ कर दिया गया।';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name रीसेट हो गया। अगली बार खोलना पहली बार खोलने जैसा होगा।';
  }

  @override
  String cloneHidden(String name) {
    return '$name निजी स्पेस में छिपा दिया गया।';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name फिर से मुख्य ग्रिड में है।';
  }

  @override
  String get cloneShortcutAdded =>
      'जोड़ना पूरा करने के लिए अपनी होम स्क्रीन पर शॉर्टकट की पुष्टि करें।';

  @override
  String get cloneGoogleServicesInstalling =>
      'Google सेवाएँ इंस्टॉल हो रही हैं…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return '$name में Google सेवाएँ इंस्टॉल हो गईं।';
  }

  @override
  String get cloneCountTitle => 'ऐप क्लोन करें';

  @override
  String cloneCountMessage(String appName) {
    return '$appName की और कॉपियाँ बनाएँ।';
  }

  @override
  String get cloneCountLabel => 'क्लोन की संख्या';

  @override
  String get cloneCountDecrease => 'एक कम';

  @override
  String get cloneCountIncrease => 'एक और';

  @override
  String get cloneCountConfirm => 'क्लोन करें';

  @override
  String cloneCreating(int created, int total) {
    return '$total में से $created बन रहा है…';
  }

  @override
  String get cloneCreatingFinishing => 'पूरा हो रहा है…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$appName की $count और कॉपियाँ जोड़ी गईं।',
      one: '$appName की एक और कॉपी जोड़ी गई।',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return '$total में से $created बने। $failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return '1 से $maximum तक चुनें';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return 'सिर्फ़ $free खाली है, और डिवाइस आधा गीगाबाइट सुरक्षित रखता है।';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return '$maximum तक — $free जगह बची है';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return '$memory मेमोरी वाले डिवाइस पर एक बार में $maximum तक';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return '$appName के एक और क्लोन के लिए जगह नहीं है। $reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return '$appName के $count और क्लोन के लिए पर्याप्त जगह नहीं है। $reason.';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return 'अनुमतियाँ · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => 'अनुमतियाँ पढ़ी नहीं जा सकीं';

  @override
  String get clonePermissionsEmptyTitle => 'सीमित करने को कुछ नहीं';

  @override
  String get clonePermissionsEmptyMessage =>
      'यह ऐप कोई ख़तरनाक अनुमति घोषित नहीं करता, इसलिए इस क्लोन के लिए कुछ भी अनुमत या अस्वीकृत करने को नहीं है।';

  @override
  String clonePermissionsNote(String appName) {
    return 'ये सिर्फ़ इसी क्लोन पर लागू होती हैं। क्लोन किया गया ऐप आम तौर पर अनुमति इस्तेमाल करने से पहले पूछता है, और वही जवाब यहाँ सीमित होता है — जो ऐप पूछना छोड़ देता है, वह $appName की अपनी अनुमति के ज़रिए फिर भी हार्डवेयर तक पहुँच सकता है।';
  }

  @override
  String get spaceInfoTitle => 'स्पेस जानकारी';

  @override
  String get spaceInfoIdentifiers => 'डिवाइस पहचानकर्ता';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => 'इंजन उपलब्ध नहीं';

  @override
  String get spaceInfoStateRunning => 'चल रहा है';

  @override
  String get spaceInfoStateActive => 'सक्रिय';

  @override
  String get spaceInfoStateRebuilds => 'खुलने पर फिर बनता है';

  @override
  String get spaceInfoNoContainer =>
      'इस स्पेस का अभी कोई कंटेनर नहीं है, इसलिए इसके पहचानकर्ता भी नहीं हैं। इसे एक बार खोलें, वे यहाँ दिखने लगेंगे।';

  @override
  String get spaceInfoDeviceId => 'डिवाइस ID';

  @override
  String get spaceInfoAndroidId => 'Android ID';

  @override
  String get spaceInfoSerialNumber => 'सीरियल नंबर';

  @override
  String get spaceInfoWifiMac => 'Wi-Fi MAC';

  @override
  String get spaceInfoBluetoothMac => 'Bluetooth MAC';

  @override
  String spaceInfoCopy(String label) {
    return '$label कॉपी करें';
  }

  @override
  String spaceInfoCopied(String label) {
    return '$label कॉपी हो गया।';
  }

  @override
  String get commonBack => 'वापस';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonApply => 'लागू करें';

  @override
  String get pickerTitle => 'ऐप जोड़ें';

  @override
  String get pickerSearchHint => 'ऐप खोजें';

  @override
  String get pickerFilterTooltip => 'फ़िल्टर और क्रम';

  @override
  String get pickerErrorTitle => 'ऐप की सूची नहीं मिल सकी';

  @override
  String get pickerNoMatchesTitle => 'कोई मेल खाता ऐप नहीं';

  @override
  String get pickerNoMatchesMessage =>
      'कोई और खोज आज़माएँ, या इसके बजाय APK इम्पोर्ट करें।';

  @override
  String get pickerPopular => 'लोकप्रिय';

  @override
  String get pickerQuickPicks => 'त्वरित चयन';

  @override
  String get pickerInstalledApps => 'इंस्टॉल किए ऐप';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ऐप',
      one: '1 ऐप',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => 'सिस्टम';

  @override
  String get pickerCannotClone => 'इस डिवाइस पर यह ऐप क्लोन नहीं किया जा सकता।';

  @override
  String get pickerApkUnreadable => 'चुनी गई APK पढ़ी नहीं जा सकी।';

  @override
  String pickerHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'इस डिवाइस के $count ऐप क्लोन नहीं किए जा सकते, इसलिए वे सूची में नहीं हैं',
      one:
          'इस डिवाइस का 1 ऐप क्लोन नहीं किया जा सकता, इसलिए वह सूची में नहीं है',
    );
    return '$_temp0';
  }

  @override
  String get filterTitle => 'फ़िल्टर और क्रम';

  @override
  String get filterSort => 'क्रम';

  @override
  String get filterSortName => 'ऐप का नाम';

  @override
  String get filterSortRecentlyInstalled => 'हाल में इंस्टॉल किए';

  @override
  String get filterSortRecentlyUpdated => 'हाल में अपडेट हुए';

  @override
  String get filterFilter => 'फ़िल्टर';

  @override
  String get filterAllApps => 'सभी ऐप';

  @override
  String get filterUserApps => 'उपयोगकर्ता ऐप';

  @override
  String get filterSystemApps => 'सिस्टम ऐप';

  @override
  String get filterNotAdded => 'नहीं जोड़े गए';

  @override
  String get filterAlreadyAdded => 'पहले से जोड़े गए';

  @override
  String get filterArchitecture => 'आर्किटेक्चर';

  @override
  String get filterArch64 => '64-बिट';

  @override
  String get filterArch32 => '32-बिट';

  @override
  String get filterArchNoNativeCode => 'कोई नेटिव कोड नहीं';

  @override
  String get filterPackageType => 'पैकेज प्रकार';

  @override
  String get filterPackageSingle => 'एकल APK';

  @override
  String get filterPackageSplit => 'स्प्लिट APK';

  @override
  String filterImportApk(String appName) {
    return '$appName ऐप पैकेज खोलें';
  }

  @override
  String get appSheetAddClone => 'क्लोन जोड़ें';

  @override
  String get appSheetAddAnother => 'एक और जोड़ें';

  @override
  String get appSheetShareApp => 'ऐप शेयर करें';

  @override
  String get appSheetAppDetails => 'ऐप विवरण';

  @override
  String get appDetailsTitle => 'ऐप विवरण';

  @override
  String get appDetailsAdvanced => 'उन्नत विवरण';

  @override
  String get appDetailsPackageName => 'पैकेज नाम';

  @override
  String get appDetailsVersion => 'संस्करण';

  @override
  String get appDetailsArchitecture => 'आर्किटेक्चर';

  @override
  String get appDetailsBitness => 'बिट चौड़ाई';

  @override
  String get appDetailsPackageType => 'पैकेज प्रकार';

  @override
  String get appDetailsApkComponents => 'APK घटक';

  @override
  String get appDetailsTotalApkSize => 'कुल APK आकार';

  @override
  String get appDetailsSigningSha256 => 'साइनिंग प्रमाणपत्र का SHA-256';

  @override
  String get appDetailsSigningUnreadable => 'पढ़ा नहीं जा सका';

  @override
  String get appDetailsNoApkFiles =>
      'पैकेज मैनेजर ने इस ऐप के लिए कोई APK फ़ाइल नहीं बताई।';

  @override
  String get findingAppNotFound => 'यह ऐप्लिकेशन इस डिवाइस पर इंस्टॉल नहीं है।';

  @override
  String get findingSecureEnvRequired =>
      'इस ऐप्लिकेशन को सुरक्षित परिवेश चाहिए और इसे वर्चुअलाइज़ नहीं किया जा सकता।';

  @override
  String findingSelfClone(String appName) {
    return '$appName अपना ही क्लोन नहीं बना सकता।';
  }

  @override
  String get findingSystemComponent =>
      'सिस्टम घटकों का क्लोन नहीं बनाया जा सकता।';

  @override
  String get findingAbiNotSupported =>
      'इस ऐप की नेटिव लाइब्रेरी इंजन द्वारा समर्थित किसी आर्किटेक्चर के लिए नहीं बनी हैं।';

  @override
  String get findingAppArchiveUnavailable =>
      'This app\'s installation files are not on the device. It has been archived, or its installation is incomplete.';

  @override
  String findingStorageUnavailable(String appName) {
    return 'यह ऐप साझा स्टोरेज इस्तेमाल करता है, और $appName का यह बिल्ड \'सभी फ़ाइलों तक पहुँच\' घोषित नहीं करता। इसका क्लोन आपकी फ़ाइलों तक नहीं पहुँच पाएगा और काम नहीं करेगा।';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return 'यह ऐप साझा स्टोरेज इस्तेमाल करता है। क्लोन शुरू करने से पहले सेटिंग → विशेष ऐप पहुँच में $appName को \'सभी फ़ाइलों तक पहुँच\' दें, वरना शुरू होते समय उसे अस्वीकार किया जा सकता है।';
  }

  @override
  String get factsNoNativeCode => 'कोई नेटिव कोड नहीं';

  @override
  String get factsAnyNoNativeCode => 'कोई भी — नेटिव कोड नहीं';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => 'एकल APK';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'स्प्लिट APK · $count फ़ाइलें',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => 'अज्ञात';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => 'फ़ाइल मैनेजर से इम्पोर्ट करें';

  @override
  String get commonSave => 'सहेजें';

  @override
  String get renameTitle => 'प्रोफ़ाइल का नाम बदलें';

  @override
  String get renameFieldLabel => 'प्रोफ़ाइल नाम';

  @override
  String get uninstallTitle => 'यह क्लोन अनइंस्टॉल करें?';

  @override
  String uninstallSpaceOf(int index, int count) {
    return '$count में से स्पेस $index';
  }

  @override
  String get uninstallMessage =>
      'इससे चुनी गई ऐप कॉपी और उसका स्थानीय डेटा हट जाएगा।';

  @override
  String get uninstallConfirm => 'अनइंस्टॉल करें';

  @override
  String get calculatorError => 'त्रुटि';

  @override
  String get disclosureTitle => 'शुरू करने से पहले';

  @override
  String disclosureIntro(String appName) {
    return '$appName आपके चुने ऐप की दूसरी कॉपी चलाता है। यह ठीक-ठीक बताता है कि वह क्या पढ़ता है और आपसे क्या माँगेगा।';
  }

  @override
  String get disclosureAppsTitle => 'आपके इंस्टॉल किए ऐप';

  @override
  String disclosureAppsBody(String appName) {
    return 'क्लोन चुनने की सूची दिखाने के लिए $appName इस डिवाइस पर इंस्टॉल ऐप की सूची पढ़ता है — उनके नाम, आइकन और संस्करण। यह सूची आपके डिवाइस पर ही रहती है। इसे कभी अपलोड, बेचा या साझा नहीं किया जाता, और ऐप में कोई विज्ञापन, एनालिटिक्स या ट्रैकर नहीं है।';
  }

  @override
  String get disclosurePermissionsTitle => 'क्लोन की ओर से अनुमतियाँ';

  @override
  String disclosurePermissionsBody(String appName) {
    return 'क्लोन किए ऐप $appName के अंदर चलते हैं, इसलिए कुछ Android अनुमतियाँ उनकी ओर से उस पर लागू होती हैं। हो सकता है आपसे एक बार कहा जाए कि इसे बैटरी ऑप्टिमाइज़ेशन से छूट दें, ताकि क्लोन किए मैसेंजर संदेश पहुँचाते रहें। सिर्फ़ फ़ाइल या मीडिया ऐप क्लोन करते समय आपको सेटिंग में \'सभी फ़ाइलों तक पहुँच\' देनी पड़ सकती है।';
  }

  @override
  String get disclosureControlTitle => 'नियंत्रण आपके पास है';

  @override
  String get disclosureControlBody =>
      'कुछ भी चुपचाप नहीं माँगा जाता। आप इनमें से कोई भी अनुरोध अस्वीकार करके भी ऐप इस्तेमाल कर सकते हैं, और Android सेटिंग में कभी भी अपना मन बदल सकते हैं।';

  @override
  String get disclosureAccept => 'सहमत होकर आगे बढ़ें';

  @override
  String get privateSpaceTitle => 'निजी स्पेस';

  @override
  String get privateSpaceOffTitle => 'निजी स्पेस बंद है';

  @override
  String get privateSpaceOffMessage =>
      'क्लोन को पिन के पीछे छिपाने के लिए इसे चालू करें। छिपे ऐप मुख्य ग्रिड से हट जाते हैं और सिर्फ़ यहीं खुलते हैं।';

  @override
  String get privateSpaceSetUp => 'निजी स्पेस सेट करें';

  @override
  String get privateSpaceChangePin => 'पिन बदलें';

  @override
  String get privateSpaceUnlockSection => 'अनलॉक';

  @override
  String get privateSpaceFingerprint => 'फ़िंगरप्रिंट से अनलॉक करें';

  @override
  String get privateSpaceFingerprintAvailable =>
      'आप कभी भी अपना पिन इस्तेमाल कर सकते हैं।';

  @override
  String get privateSpaceFingerprintUnavailable =>
      'इस डिवाइस पर कोई फ़िंगरप्रिंट या चेहरा सेट नहीं है।';

  @override
  String get privateSpaceDisguiseSection => 'छद्मवेश';

  @override
  String get privateSpaceDisguiseAsCalculator => 'कैलकुलेटर का रूप दें';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return '$appName के आइकन की जगह कैलकुलेटर लगा देता है। ऐप खोलने के लिए अपना निजी स्पेस पिन टाइप करें और = दबाएँ।';
  }

  @override
  String get privateSpaceTurnOff => 'निजी स्पेस बंद करें';

  @override
  String get privateSpaceTurnOffNote =>
      'इसे बंद करने पर हर छिपा ऐप मुख्य ग्रिड में लौट आता है। क्लोन खुद नहीं मिटते।';

  @override
  String get privateSpaceDisguiseOnTitle => 'कैलकुलेटर का रूप दें?';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return '$appName फिर से दिखाएँ?';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return '$appName का आइकन \'Calculator\' नाम के कैलकुलेटर से बदल दिया जाता है। $appName खोलने के लिए अपना निजी स्पेस पिन टाइप करें और = दबाएँ। पिन भूल गए तो आप ऐप नहीं खोल पाएँगे।';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName फिर से होम स्क्रीन पर अपना आइकन और नाम दिखाएगा।';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => 'रूप बदलें';

  @override
  String get privateSpaceDisguiseConfirmOff => 'ऐप दिखाएँ';

  @override
  String get privateSpaceDisguiseFailed => 'ऐप का रूप नहीं बदला जा सका।';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '$appName अब आपकी होम स्क्रीन पर कैलकुलेटर जैसा दिखता है।';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName फिर से आपकी होम स्क्रीन पर है।';
  }

  @override
  String get privateSpaceTurnOffTitle => 'निजी स्पेस बंद करें?';

  @override
  String get privateSpaceTurnOffMessage =>
      'हर छिपा ऐप मुख्य ग्रिड में लौट आएगा और पिन भुला दिया जाएगा। क्लोन बने रहते हैं।';

  @override
  String get privateSpaceTurnOffConfirm => 'बंद करें';

  @override
  String get privateSpaceTurnedOff => 'निजी स्पेस बंद कर दिया गया।';

  @override
  String get pinCreateTitle => 'पिन बनाएँ';

  @override
  String get pinChangeTitle => 'पिन बदलें';

  @override
  String get pinCreateMessage =>
      'यह पिन निजी स्पेस को लॉक करता है। इसे ऐसी जगह रखें जहाँ भूलें नहीं: इसके बिना छिपे क्लोन को वापस पाने का कोई तरीका नहीं है।';

  @override
  String get pinChangeMessage => 'अपना मौजूदा पिन डालें, फिर नया चुनें।';

  @override
  String get pinCurrentLabel => 'मौजूदा पिन';

  @override
  String get pinNewLabel => 'नया पिन';

  @override
  String get pinConfirmLabel => 'पिन की पुष्टि करें';

  @override
  String get pinCreateConfirm => 'निजी स्पेस बनाएँ';

  @override
  String get pinSaveConfirm => 'पिन सहेजें';

  @override
  String pinLengthError(int minimum, int maximum) {
    return '$minimum से $maximum अंक इस्तेमाल करें।';
  }

  @override
  String get pinMismatchError => 'दोनों पिन मेल नहीं खाते।';

  @override
  String get pinCurrentIncorrect => 'मौजूदा पिन ग़लत है।';

  @override
  String get unlockTitle => 'निजी स्पेस अनलॉक करें';

  @override
  String get unlockPinLabel => 'पिन';

  @override
  String get unlockUseFingerprint => 'फ़िंगरप्रिंट इस्तेमाल करें';

  @override
  String get unlockConfirm => 'अनलॉक करें';

  @override
  String get unlockIncorrectPin => 'ग़लत पिन';

  @override
  String get unlockFingerprintUnavailable =>
      'फ़िंगरप्रिंट से अनलॉक अभी उपलब्ध नहीं है।';

  @override
  String get unlockFingerprintNotRecognised => 'फ़िंगरप्रिंट पहचाना नहीं गया।';

  @override
  String get unlockBiometricReason => 'अपना निजी स्पेस अनलॉक करें';

  @override
  String get privateTileEmpty => 'निजी स्पेस, खाली';

  @override
  String privateTileHidden(int count) {
    return 'निजी स्पेस, $count छिपे';
  }

  @override
  String get settingsSectionPrivacy => 'गोपनीयता';

  @override
  String get settingsPrivateSpaceSubtitle => 'ऐप को पिन के पीछे छिपाएँ';

  @override
  String get settingsOn => 'चालू';

  @override
  String get settingsOff => 'बंद';

  @override
  String get componentBaseApk => 'बेस APK';

  @override
  String get componentSplitApk => 'स्प्लिट APK';

  @override
  String get componentNoNativeLibraries => 'कोई नेटिव लाइब्रेरी नहीं';

  @override
  String get errorProfileNameEmpty => 'क्लोन के लिए एक नाम चाहिए।';

  @override
  String errorProfileNameTooLong(int maximum) {
    return 'क्लोन का नाम ज़्यादा से ज़्यादा $maximum अक्षरों का हो सकता है।';
  }

  @override
  String get errorProfileStorageUnreadable =>
      'आपके सहेजे गए क्लोन पढ़े नहीं जा सके।';

  @override
  String get errorProfileNotFound => 'वह क्लोन अब मौजूद नहीं है।';

  @override
  String get errorBridgeFailed =>
      'ऐप के जिस हिस्से पर क्लोन चलते हैं, उससे बात करने में कुछ गड़बड़ हुई।';

  @override
  String get errorBridgeUnsupportedPlatform =>
      'यह सुविधा सिर्फ़ Android पर उपलब्ध है।';

  @override
  String get errorTestAppCheckFailed =>
      'टेस्ट ऐप इंस्टॉल है या नहीं, यह जाँचा नहीं जा सका।';

  @override
  String get errorEngineInitFailed =>
      'इस डिवाइस पर वर्चुअलाइज़ेशन इंजन शुरू नहीं हो सका।';

  @override
  String get errorEngineAndroidTooOld =>
      'वर्चुअलाइज़ेशन इंजन को Android के नए संस्करण की ज़रूरत है।';

  @override
  String get errorEngineNoResponse =>
      'वर्चुअलाइज़ेशन इंजन ने जवाब नहीं दिया। फिर कोशिश करें।';

  @override
  String get errorNoContainer =>
      'इस क्लोन का अभी कोई कंटेनर नहीं है। इसे एक बार खोलें और फिर कोशिश करें।';

  @override
  String get errorLaunchRefused => 'इंजन ने यह क्लोन खोलने से मना कर दिया।';

  @override
  String get errorAlreadyCloned => 'इस ऐप का क्लोन पहले ही बन चुका है।';

  @override
  String get errorClearCacheFailed => 'इस क्लोन का कुछ कैश नहीं हटाया जा सका।';

  @override
  String get errorClearDataFailed => 'इस क्लोन का डेटा साफ़ नहीं किया जा सका।';

  @override
  String get errorShortcutsUnsupported =>
      'यह लॉन्चर शॉर्टकट जोड़ना समर्थित नहीं करता।';

  @override
  String get errorShortcutRefused => 'लॉन्चर ने शॉर्टकट अस्वीकार कर दिया।';

  @override
  String get errorApkGone =>
      'इस क्लोन की APK अब डिवाइस पर नहीं है, इसलिए शेयर करने को कुछ नहीं है।';

  @override
  String get errorShareFailed => 'ऐप शेयर नहीं किया जा सका।';

  @override
  String get errorApkUnreadable => 'चुनी गई APK में से एक पढ़ी नहीं जा सकी।';

  @override
  String get errorApkPackageMismatch =>
      'चुनी गई सभी APK एक ही ऐप की होनी चाहिए।';

  @override
  String get errorApkVersionMismatch =>
      'चुनी गई सभी APK का संस्करण एक ही होना चाहिए।';

  @override
  String get errorApkBaseRequired =>
      'ठीक एक बेस APK और एक या अधिक कॉन्फ़िगरेशन स्प्लिट चुनें।';

  @override
  String get errorApkDuplicateSplit =>
      'एक ही APK स्प्लिट एक से ज़्यादा बार चुना गया।';
}
