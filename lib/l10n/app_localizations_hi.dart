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
  String get settingsSectionDelivery => 'डिलीवरी';

  @override
  String get settingsBackgroundActivity => 'पृष्ठभूमि गतिविधि';

  @override
  String get settingsBackgroundActivitySubtitle =>
      'क्लोन किए गए ऐप बंद रहने पर भी सूचनाएँ पाने देता है';

  @override
  String get settingsBackgroundActivityAllowed => 'अनुमत';

  @override
  String get settingsBackgroundActivityRestricted => 'प्रतिबंधित';

  @override
  String get settingsBackgroundActivityNotAllowed => 'अनुमति नहीं';

  @override
  String get backgroundGuideAllowedStatus =>
      'पृष्ठभूमि गतिविधि की अनुमति है, इसलिए क्लोन किए गए ऐप बंद रहने पर भी सूचनाएँ पाते रहते हैं।';

  @override
  String get backgroundGuideDone => 'ठीक है';

  @override
  String get backgroundGuideTitle => 'पृष्ठभूमि गतिविधि';

  @override
  String get backgroundGuideWhy =>
      'Android Duplika को पृष्ठभूमि में रोक सकता है; तब तक क्लोन किए गए ऐप सूचनाएँ नहीं पाएँगे जब तक आप Duplika दोबारा नहीं खोलते।';

  @override
  String get backgroundGuideStepsOem =>
      'ऐप जानकारी में ‘बैटरी उपयोग’ पर टैप करें और ‘पृष्ठभूमि गतिविधि की अनुमति दें’ चालू करें।';

  @override
  String get backgroundGuideStepsStock =>
      'खुलने वाले सिस्टम सवाल में ‘अनुमति दें’ टैप करें, ताकि यह पृष्ठभूमि में चल सके।';

  @override
  String get backgroundGuideStepsUnknown =>
      'ऐप जानकारी में पृष्ठभूमि गतिविधि की अनुमति दें।';

  @override
  String get backgroundGuideOpenAppInfo => 'ऐप जानकारी खोलें';

  @override
  String get backgroundGuideAllow => 'अनुमति दें';

  @override
  String get backgroundGuideLater => 'अभी नहीं';

  @override
  String get settingsBackgroundActivityFix =>
      'यहाँ टैप करें और पृष्ठभूमि गतिविधि की अनुमति दें';

  @override
  String get settingsBackgroundActivityFixBatteryUsage =>
      'यहाँ टैप करें, फिर बैटरी उपयोग, फिर पृष्ठभूमि गतिविधि की अनुमति दें';

  @override
  String get settingsBackgroundActivityFailed =>
      'पृष्ठभूमि गतिविधि सेटिंग्स खोली नहीं जा सकीं।';

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
}
