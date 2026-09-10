import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_no.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('ms'),
    Locale('no'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('uk'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale.fromSubtags(
      languageCode: 'zh',
      countryCode: 'HK',
      scriptCode: 'Hant',
    ),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSectionSupport;

  /// No description provided for @settingsSectionLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsSectionLegal;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsContact.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get settingsContact;

  /// No description provided for @settingsContactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Questions or feedback'**
  String get settingsContactSubtitle;

  /// No description provided for @settingsRate.
  ///
  /// In en, this message translates to:
  /// **'Rate us'**
  String get settingsRate;

  /// No description provided for @settingsRateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enjoying {appName}? Leave a review'**
  String settingsRateSubtitle(String appName);

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsArchitecture.
  ///
  /// In en, this message translates to:
  /// **'Device architecture'**
  String get settingsArchitecture;

  /// No description provided for @settingsArchitectureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App compatibility'**
  String get settingsArchitectureSubtitle;

  /// No description provided for @settingsBits64.
  ///
  /// In en, this message translates to:
  /// **'64-bit'**
  String get settingsBits64;

  /// No description provided for @settingsBits32.
  ///
  /// In en, this message translates to:
  /// **'32-bit'**
  String get settingsBits32;

  /// Word size and primary ABI, e.g. 64-bit · arm64-v8a.
  ///
  /// In en, this message translates to:
  /// **'{width} · {abi}'**
  String settingsArchitectureValue(String width, String abi);

  /// No description provided for @settingsSupportedAbis.
  ///
  /// In en, this message translates to:
  /// **'Supported ABIs'**
  String get settingsSupportedAbis;

  /// No description provided for @settingsCopyright.
  ///
  /// In en, this message translates to:
  /// **'© {year} {appName}'**
  String settingsCopyright(int year, String appName);

  /// No description provided for @settingsNotPublishedYet.
  ///
  /// In en, this message translates to:
  /// **'Not published yet'**
  String get settingsNotPublishedYet;

  /// No description provided for @settingsNotListedYet.
  ///
  /// In en, this message translates to:
  /// **'Not listed yet'**
  String get settingsNotListedYet;

  /// No description provided for @settingsNotSetUpYet.
  ///
  /// In en, this message translates to:
  /// **'Not set up yet'**
  String get settingsNotSetUpYet;

  /// No description provided for @commonUnavailable.
  ///
  /// In en, this message translates to:
  /// **'unavailable'**
  String get commonUnavailable;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearancePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get appearancePreview;

  /// No description provided for @appearanceChooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose a theme'**
  String get appearanceChooseTheme;

  /// No description provided for @appearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get appearanceSystem;

  /// No description provided for @appearanceSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Match your device settings'**
  String get appearanceSystemSubtitle;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// No description provided for @appearanceLightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always use light theme'**
  String get appearanceLightSubtitle;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// No description provided for @appearanceDarkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always use dark theme'**
  String get appearanceDarkSubtitle;

  /// No description provided for @appearanceInstantNote.
  ///
  /// In en, this message translates to:
  /// **'Theme changes apply instantly across {appName}.'**
  String appearanceInstantNote(String appName);

  /// Screen-reader label for one of the two palette mockups.
  ///
  /// In en, this message translates to:
  /// **'{theme} theme preview'**
  String appearancePreviewLabel(String theme);

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get languageSearchHint;

  /// No description provided for @languageClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get languageClearSearch;

  /// No description provided for @languageNote.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used in {appName}.'**
  String languageNote(String appName);

  /// No description provided for @languageSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionHeader;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your device language'**
  String get languageSystemSubtitle;

  /// No description provided for @languageInstantNote.
  ///
  /// In en, this message translates to:
  /// **'Language changes apply immediately.'**
  String get languageInstantNote;

  /// No description provided for @languageNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No language matches \"{query}\".'**
  String languageNoMatches(String query);

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactTitle;

  /// No description provided for @contactHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get contactHeroTitle;

  /// No description provided for @contactHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred way to contact the {appName} team.'**
  String contactHeroSubtitle(String appName);

  /// No description provided for @contactSectionOptions.
  ///
  /// In en, this message translates to:
  /// **'Contact options'**
  String get contactSectionOptions;

  /// No description provided for @contactWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get contactWhatsApp;

  /// No description provided for @contactWhatsAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with our support team'**
  String get contactWhatsAppSubtitle;

  /// No description provided for @contactTelegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get contactTelegram;

  /// No description provided for @contactTelegramSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Message us on Telegram'**
  String get contactTelegramSubtitle;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactEmail;

  /// No description provided for @contactEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send us an email'**
  String get contactEmailSubtitle;

  /// No description provided for @contactResponseTime.
  ///
  /// In en, this message translates to:
  /// **'Response time'**
  String get contactResponseTime;

  /// No description provided for @contactResponseTimeValue.
  ///
  /// In en, this message translates to:
  /// **'We usually reply within 1–2 business days.'**
  String get contactResponseTimeValue;

  /// No description provided for @contactPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'We\'ll only use your message to provide support.'**
  String get contactPrivacyNote;

  /// No description provided for @contactNoMailApp.
  ///
  /// In en, this message translates to:
  /// **'No mail app could be opened. Write to {email} instead.'**
  String contactNoMailApp(String email);

  /// No description provided for @contactWhatsAppFailed.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp could not be opened.'**
  String get contactWhatsAppFailed;

  /// No description provided for @contactTelegramFailed.
  ///
  /// In en, this message translates to:
  /// **'Telegram could not be opened.'**
  String get contactTelegramFailed;

  /// No description provided for @contactPlayStoreFailed.
  ///
  /// In en, this message translates to:
  /// **'The Play Store could not be opened.'**
  String get contactPlayStoreFailed;

  /// No description provided for @contactLegalOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The {document} could not be opened.'**
  String contactLegalOpenFailed(String document);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'hi',
    'id',
    'it',
    'ja',
    'ko',
    'ms',
    'no',
    'pt',
    'ru',
    'uk',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script+country codes are specified.
  switch (locale.toString()) {
    case 'zh_Hant_HK':
      return AppLocalizationsZhHantHk();
  }

  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ms':
      return AppLocalizationsMs();
    case 'no':
      return AppLocalizationsNo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'uk':
      return AppLocalizationsUk();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
