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

  /// No description provided for @settingsSectionDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get settingsSectionDelivery;

  /// No description provided for @settingsBackgroundActivity.
  ///
  /// In en, this message translates to:
  /// **'Background activity'**
  String get settingsBackgroundActivity;

  /// No description provided for @settingsBackgroundActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lets cloned apps receive notifications while they are closed'**
  String get settingsBackgroundActivitySubtitle;

  /// No description provided for @settingsBackgroundActivityAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get settingsBackgroundActivityAllowed;

  /// No description provided for @settingsBackgroundActivityRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get settingsBackgroundActivityRestricted;

  /// No description provided for @settingsBackgroundActivityNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get settingsBackgroundActivityNotAllowed;

  /// No description provided for @backgroundGuideAllowedStatus.
  ///
  /// In en, this message translates to:
  /// **'Background activity is allowed, so clones keep receiving notifications while they are closed.'**
  String get backgroundGuideAllowedStatus;

  /// No description provided for @backgroundGuideDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get backgroundGuideDone;

  /// No description provided for @backgroundGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Background activity'**
  String get backgroundGuideTitle;

  /// No description provided for @backgroundGuideWhy.
  ///
  /// In en, this message translates to:
  /// **'Android can pause Duplika while it is in the background, and cloned apps then miss notifications until you open Duplika again.'**
  String get backgroundGuideWhy;

  /// No description provided for @backgroundGuideStepsOem.
  ///
  /// In en, this message translates to:
  /// **'In App info, tap Battery usage and turn on Allow background activity.'**
  String get backgroundGuideStepsOem;

  /// No description provided for @backgroundGuideStepsStock.
  ///
  /// In en, this message translates to:
  /// **'Tap Allow on the system question that opens, so it may run in the background.'**
  String get backgroundGuideStepsStock;

  /// No description provided for @backgroundGuideStepsUnknown.
  ///
  /// In en, this message translates to:
  /// **'In App info, allow background activity.'**
  String get backgroundGuideStepsUnknown;

  /// No description provided for @backgroundGuideOpenAppInfo.
  ///
  /// In en, this message translates to:
  /// **'Open App info'**
  String get backgroundGuideOpenAppInfo;

  /// No description provided for @backgroundGuideAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get backgroundGuideAllow;

  /// No description provided for @backgroundGuideLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get backgroundGuideLater;

  /// No description provided for @settingsBackgroundActivityFix.
  ///
  /// In en, this message translates to:
  /// **'Tap here and allow background activity'**
  String get settingsBackgroundActivityFix;

  /// No description provided for @settingsBackgroundActivityFixBatteryUsage.
  ///
  /// In en, this message translates to:
  /// **'Tap here, then Battery usage, then Allow background activity'**
  String get settingsBackgroundActivityFixBatteryUsage;

  /// No description provided for @settingsBackgroundActivityFailed.
  ///
  /// In en, this message translates to:
  /// **'The background activity settings could not be opened.'**
  String get settingsBackgroundActivityFailed;

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

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get commonNotNow;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @commonFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t do that'**
  String get commonFailureTitle;

  /// No description provided for @homePrivateSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Private space'**
  String get homePrivateSpaceTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your private space'**
  String get homeSubtitle;

  /// Header subtitle while the Private space is open.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No hidden apps} =1{1 hidden app} other{{count} hidden apps}}'**
  String homeHiddenApps(int count);

  /// No description provided for @homeLockAndClose.
  ///
  /// In en, this message translates to:
  /// **'Lock and close'**
  String get homeLockAndClose;

  /// No description provided for @homeMenuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeMenuSettings;

  /// No description provided for @homeMenuDeveloperTools.
  ///
  /// In en, this message translates to:
  /// **'Developer Tools'**
  String get homeMenuDeveloperTools;

  /// No description provided for @homeAddApp.
  ///
  /// In en, this message translates to:
  /// **'Add app'**
  String get homeAddApp;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your space is empty'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add an app to create your first private instance.'**
  String get homeEmptyMessage;

  /// No description provided for @homeEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Add your first app'**
  String get homeEmptyAction;

  /// No description provided for @homePrivateEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing hidden yet'**
  String get homePrivateEmptyTitle;

  /// No description provided for @homePrivateEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Hold any app on the main grid and choose Hide to move it in here.'**
  String get homePrivateEmptyMessage;

  /// No description provided for @homeSetUpPrivateSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up Private space?'**
  String get homeSetUpPrivateSpaceTitle;

  /// No description provided for @homeSetUpPrivateSpaceMessage.
  ///
  /// In en, this message translates to:
  /// **'Hiding a clone needs a Private space. Create one with a PIN first.'**
  String get homeSetUpPrivateSpaceMessage;

  /// No description provided for @homeSetUpPrivateSpaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get homeSetUpPrivateSpaceConfirm;

  /// No description provided for @homeEngineInactive.
  ///
  /// In en, this message translates to:
  /// **'The virtualization engine is not active on this device, so clones cannot run in isolated containers.'**
  String get homeEngineInactive;

  /// No description provided for @homeEngineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The virtualization engine is unavailable on this device.'**
  String get homeEngineUnavailable;

  /// No description provided for @homeBackgroundNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Clones may miss notifications while they are closed.'**
  String get homeBackgroundNudgeTitle;

  /// No description provided for @homeBackgroundNudgeMessage.
  ///
  /// In en, this message translates to:
  /// **'Make sure background activity is allowed so they keep receiving them.'**
  String get homeBackgroundNudgeMessage;

  /// No description provided for @homeBackgroundNudgeAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get homeBackgroundNudgeAllow;

  /// No description provided for @homeBackgroundNudgeDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get homeBackgroundNudgeDismiss;

  /// Which of an app's clones this one is, e.g. Space 2.
  ///
  /// In en, this message translates to:
  /// **'Space {index}'**
  String cloneSpaceLabel(int index);

  /// No description provided for @cloneActionsCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Compatibility'**
  String get cloneActionsCompatibility;

  /// No description provided for @cloneActionsManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get cloneActionsManage;

  /// No description provided for @cloneActionUninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get cloneActionUninstall;

  /// No description provided for @cloneActionClone.
  ///
  /// In en, this message translates to:
  /// **'Clone'**
  String get cloneActionClone;

  /// No description provided for @cloneActionShortcut.
  ///
  /// In en, this message translates to:
  /// **'Shortcut'**
  String get cloneActionShortcut;

  /// No description provided for @cloneActionSpaceInfo.
  ///
  /// In en, this message translates to:
  /// **'Space info'**
  String get cloneActionSpaceInfo;

  /// No description provided for @cloneActionEditName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get cloneActionEditName;

  /// No description provided for @cloneActionForceStop.
  ///
  /// In en, this message translates to:
  /// **'Force stop'**
  String get cloneActionForceStop;

  /// No description provided for @cloneActionClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get cloneActionClearCache;

  /// No description provided for @cloneActionClearStorage.
  ///
  /// In en, this message translates to:
  /// **'Clear storage'**
  String get cloneActionClearStorage;

  /// No description provided for @cloneActionHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get cloneActionHide;

  /// No description provided for @cloneActionUnhide.
  ///
  /// In en, this message translates to:
  /// **'Unhide'**
  String get cloneActionUnhide;

  /// No description provided for @cloneActionShareApp.
  ///
  /// In en, this message translates to:
  /// **'Share app'**
  String get cloneActionShareApp;

  /// No description provided for @cloneActionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get cloneActionNotifications;

  /// No description provided for @cloneActionPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get cloneActionPermissions;

  /// No description provided for @cloneActionGoogleServicesInstalled.
  ///
  /// In en, this message translates to:
  /// **'Google services (microG) installed'**
  String get cloneActionGoogleServicesInstalled;

  /// No description provided for @cloneActionInstallGoogleServices.
  ///
  /// In en, this message translates to:
  /// **'Install Google services (microG)'**
  String get cloneActionInstallGoogleServices;

  /// Screen-reader suffix naming which clone of an app a tile is.
  ///
  /// In en, this message translates to:
  /// **', clone {index} of {count}'**
  String cloneTileSibling(int index, int count);

  /// No description provided for @cloneTileOpening.
  ///
  /// In en, this message translates to:
  /// **', opening'**
  String get cloneTileOpening;

  /// No description provided for @cloneTileRunning.
  ///
  /// In en, this message translates to:
  /// **', running'**
  String get cloneTileRunning;

  /// No description provided for @cloneTileCannotLaunch.
  ///
  /// In en, this message translates to:
  /// **', cannot be launched on this device'**
  String get cloneTileCannotLaunch;

  /// No description provided for @cloneForceStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Force stop this app?'**
  String get cloneForceStopTitle;

  /// No description provided for @cloneForceStopMessage.
  ///
  /// In en, this message translates to:
  /// **'The app will stop running until you open it again.'**
  String get cloneForceStopMessage;

  /// No description provided for @cloneForceStopConfirm.
  ///
  /// In en, this message translates to:
  /// **'Force stop'**
  String get cloneForceStopConfirm;

  /// No description provided for @cloneClearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear app cache?'**
  String get cloneClearCacheTitle;

  /// No description provided for @cloneClearCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove temporary files for this clone.'**
  String get cloneClearCacheMessage;

  /// No description provided for @cloneClearCacheConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get cloneClearCacheConfirm;

  /// No description provided for @cloneClearStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear app storage?'**
  String get cloneClearStorageTitle;

  /// No description provided for @cloneClearStorageMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this clone\'s accounts, settings, and local data.'**
  String get cloneClearStorageMessage;

  /// No description provided for @cloneClearStorageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear Storage'**
  String get cloneClearStorageConfirm;

  /// No description provided for @cloneInstallGoogleServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Install Google services?'**
  String get cloneInstallGoogleServicesTitle;

  /// No description provided for @cloneInstallGoogleServicesMessage.
  ///
  /// In en, this message translates to:
  /// **'{appName} will install its bundled microG into this clone as Google Play services. The clone keeps its data. This can take a few seconds.'**
  String cloneInstallGoogleServicesMessage(String appName);

  /// No description provided for @cloneInstallGoogleServicesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get cloneInstallGoogleServicesConfirm;

  /// No description provided for @cloneStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped {name}.'**
  String cloneStopped(String name);

  /// No description provided for @cloneCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared for {name}.'**
  String cloneCacheCleared(String name);

  /// No description provided for @cloneStorageCleared.
  ///
  /// In en, this message translates to:
  /// **'{name} was reset. Its next launch is a first launch.'**
  String cloneStorageCleared(String name);

  /// No description provided for @cloneHidden.
  ///
  /// In en, this message translates to:
  /// **'{name} hidden in Private space.'**
  String cloneHidden(String name);

  /// No description provided for @cloneUnhidden.
  ///
  /// In en, this message translates to:
  /// **'{name} is back on the main grid.'**
  String cloneUnhidden(String name);

  /// No description provided for @cloneShortcutAdded.
  ///
  /// In en, this message translates to:
  /// **'Confirm the shortcut on your home screen to finish adding it.'**
  String get cloneShortcutAdded;

  /// No description provided for @cloneGoogleServicesInstalling.
  ///
  /// In en, this message translates to:
  /// **'Installing Google services…'**
  String get cloneGoogleServicesInstalling;

  /// No description provided for @cloneGoogleServicesInstalled.
  ///
  /// In en, this message translates to:
  /// **'Google services installed in {name}.'**
  String cloneGoogleServicesInstalled(String name);

  /// No description provided for @cloneCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Clone app'**
  String get cloneCountTitle;

  /// No description provided for @cloneCountMessage.
  ///
  /// In en, this message translates to:
  /// **'Create additional copies of {appName}.'**
  String cloneCountMessage(String appName);

  /// No description provided for @cloneCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of clones'**
  String get cloneCountLabel;

  /// No description provided for @cloneCountDecrease.
  ///
  /// In en, this message translates to:
  /// **'One fewer'**
  String get cloneCountDecrease;

  /// No description provided for @cloneCountIncrease.
  ///
  /// In en, this message translates to:
  /// **'One more'**
  String get cloneCountIncrease;

  /// No description provided for @cloneCountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clone'**
  String get cloneCountConfirm;

  /// No description provided for @cloneCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating {created} of {total}…'**
  String cloneCreating(int created, int total);

  /// No description provided for @cloneCreatingFinishing.
  ///
  /// In en, this message translates to:
  /// **'Finishing…'**
  String get cloneCreatingFinishing;

  /// No description provided for @cloneAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added another {appName}.} other{Added {count} more copies of {appName}.}}'**
  String cloneAdded(int count, String appName);

  /// A batch that only partly succeeded, followed by the engine's own message.
  ///
  /// In en, this message translates to:
  /// **'Created {created} of {total}. {failure}'**
  String cloneCreatedPartly(int created, int total, String failure);

  /// No description provided for @cloneBudgetRange.
  ///
  /// In en, this message translates to:
  /// **'Choose from 1 to {maximum}'**
  String cloneBudgetRange(int maximum);

  /// Free space is already formatted by the platform, e.g. 240 MB.
  ///
  /// In en, this message translates to:
  /// **'Only {free} is free, and the device keeps half a gigabyte spare.'**
  String cloneBudgetNoStorage(String free);

  /// No description provided for @cloneBudgetStorage.
  ///
  /// In en, this message translates to:
  /// **'Up to {maximum} — {free} of space left'**
  String cloneBudgetStorage(int maximum, String free);

  /// No description provided for @cloneBudgetMemory.
  ///
  /// In en, this message translates to:
  /// **'Up to {maximum} at a time on a device with {memory} of memory'**
  String cloneBudgetMemory(int maximum, String memory);

  /// No description provided for @cloneBudgetNoRoom.
  ///
  /// In en, this message translates to:
  /// **'There is no room for another {appName} clone. {reason}'**
  String cloneBudgetNoRoom(String appName, String reason);

  /// No description provided for @cloneBudgetNotEnoughRoom.
  ///
  /// In en, this message translates to:
  /// **'Not enough room for {count} more {appName} clones. {reason}.'**
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason);

  /// No description provided for @clonePermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions · {appName}'**
  String clonePermissionsTitle(String appName);

  /// No description provided for @clonePermissionsErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not read permissions'**
  String get clonePermissionsErrorTitle;

  /// No description provided for @clonePermissionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to scope'**
  String get clonePermissionsEmptyTitle;

  /// No description provided for @clonePermissionsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'This app declares no dangerous permissions, so there is nothing to allow or deny for this clone.'**
  String get clonePermissionsEmptyMessage;

  /// No description provided for @clonePermissionsNote.
  ///
  /// In en, this message translates to:
  /// **'These apply to this clone only. A cloned app usually asks before it uses a permission, and this is where that answer is scoped — an app that skips the ask may still reach hardware through {appName}\'s own grant.'**
  String clonePermissionsNote(String appName);

  /// No description provided for @spaceInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Space Info'**
  String get spaceInfoTitle;

  /// No description provided for @spaceInfoIdentifiers.
  ///
  /// In en, this message translates to:
  /// **'Device identifiers'**
  String get spaceInfoIdentifiers;

  /// No description provided for @spaceInfoIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ID {index}'**
  String spaceInfoIdLabel(int index);

  /// No description provided for @spaceInfoStateEngineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Engine unavailable'**
  String get spaceInfoStateEngineUnavailable;

  /// No description provided for @spaceInfoStateRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get spaceInfoStateRunning;

  /// No description provided for @spaceInfoStateActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get spaceInfoStateActive;

  /// No description provided for @spaceInfoStateRebuilds.
  ///
  /// In en, this message translates to:
  /// **'Rebuilds on launch'**
  String get spaceInfoStateRebuilds;

  /// No description provided for @spaceInfoNoContainer.
  ///
  /// In en, this message translates to:
  /// **'This space has no container yet, so it has no identifiers. Launch it once and they will appear here.'**
  String get spaceInfoNoContainer;

  /// No description provided for @spaceInfoDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get spaceInfoDeviceId;

  /// No description provided for @spaceInfoAndroidId.
  ///
  /// In en, this message translates to:
  /// **'Android ID'**
  String get spaceInfoAndroidId;

  /// No description provided for @spaceInfoSerialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial number'**
  String get spaceInfoSerialNumber;

  /// No description provided for @spaceInfoWifiMac.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi MAC'**
  String get spaceInfoWifiMac;

  /// No description provided for @spaceInfoBluetoothMac.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth MAC'**
  String get spaceInfoBluetoothMac;

  /// No description provided for @spaceInfoCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy {label}'**
  String spaceInfoCopy(String label);

  /// No description provided for @spaceInfoCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied.'**
  String spaceInfoCopied(String label);

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @pickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add app'**
  String get pickerTitle;

  /// No description provided for @pickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get pickerSearchHint;

  /// No description provided for @pickerFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter and sort'**
  String get pickerFilterTooltip;

  /// No description provided for @pickerErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not list apps'**
  String get pickerErrorTitle;

  /// No description provided for @pickerNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching apps'**
  String get pickerNoMatchesTitle;

  /// No description provided for @pickerNoMatchesMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different search, or import an APK instead.'**
  String get pickerNoMatchesMessage;

  /// No description provided for @pickerPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get pickerPopular;

  /// No description provided for @pickerQuickPicks.
  ///
  /// In en, this message translates to:
  /// **'Quick picks'**
  String get pickerQuickPicks;

  /// No description provided for @pickerInstalledApps.
  ///
  /// In en, this message translates to:
  /// **'Installed apps'**
  String get pickerInstalledApps;

  /// No description provided for @pickerAppCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 app} other{{count} apps}}'**
  String pickerAppCount(int count);

  /// No description provided for @pickerSystemChip.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get pickerSystemChip;

  /// No description provided for @pickerCannotClone.
  ///
  /// In en, this message translates to:
  /// **'This app cannot be cloned on this device.'**
  String get pickerCannotClone;

  /// No description provided for @pickerApkUnreadable.
  ///
  /// In en, this message translates to:
  /// **'The selected APK could not be read.'**
  String get pickerApkUnreadable;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter and sort'**
  String get filterTitle;

  /// No description provided for @filterSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get filterSort;

  /// No description provided for @filterSortName.
  ///
  /// In en, this message translates to:
  /// **'App name'**
  String get filterSortName;

  /// No description provided for @filterSortRecentlyInstalled.
  ///
  /// In en, this message translates to:
  /// **'Recently installed'**
  String get filterSortRecentlyInstalled;

  /// No description provided for @filterSortRecentlyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get filterSortRecentlyUpdated;

  /// No description provided for @filterFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterFilter;

  /// No description provided for @filterAllApps.
  ///
  /// In en, this message translates to:
  /// **'All apps'**
  String get filterAllApps;

  /// No description provided for @filterUserApps.
  ///
  /// In en, this message translates to:
  /// **'User apps'**
  String get filterUserApps;

  /// No description provided for @filterSystemApps.
  ///
  /// In en, this message translates to:
  /// **'System apps'**
  String get filterSystemApps;

  /// No description provided for @filterNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get filterNotAdded;

  /// No description provided for @filterAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Already added'**
  String get filterAlreadyAdded;

  /// No description provided for @filterArchitecture.
  ///
  /// In en, this message translates to:
  /// **'Architecture'**
  String get filterArchitecture;

  /// No description provided for @filterArch64.
  ///
  /// In en, this message translates to:
  /// **'64-bit'**
  String get filterArch64;

  /// No description provided for @filterArch32.
  ///
  /// In en, this message translates to:
  /// **'32-bit'**
  String get filterArch32;

  /// No description provided for @filterArchNoNativeCode.
  ///
  /// In en, this message translates to:
  /// **'No native code'**
  String get filterArchNoNativeCode;

  /// No description provided for @filterPackageType.
  ///
  /// In en, this message translates to:
  /// **'Package type'**
  String get filterPackageType;

  /// No description provided for @filterPackageSingle.
  ///
  /// In en, this message translates to:
  /// **'Single APK'**
  String get filterPackageSingle;

  /// No description provided for @filterPackageSplit.
  ///
  /// In en, this message translates to:
  /// **'Split APK'**
  String get filterPackageSplit;

  /// Opens the system file picker to import an APK.
  ///
  /// In en, this message translates to:
  /// **'Open {appName} App Package'**
  String filterImportApk(String appName);

  /// No description provided for @appSheetAddClone.
  ///
  /// In en, this message translates to:
  /// **'Add clone'**
  String get appSheetAddClone;

  /// No description provided for @appSheetAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Add another'**
  String get appSheetAddAnother;

  /// No description provided for @appSheetShareApp.
  ///
  /// In en, this message translates to:
  /// **'Share app'**
  String get appSheetShareApp;

  /// No description provided for @appSheetAppDetails.
  ///
  /// In en, this message translates to:
  /// **'App details'**
  String get appSheetAppDetails;

  /// No description provided for @appDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'App details'**
  String get appDetailsTitle;

  /// No description provided for @appDetailsAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced details'**
  String get appDetailsAdvanced;

  /// No description provided for @appDetailsPackageName.
  ///
  /// In en, this message translates to:
  /// **'Package name'**
  String get appDetailsPackageName;

  /// No description provided for @appDetailsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appDetailsVersion;

  /// No description provided for @appDetailsArchitecture.
  ///
  /// In en, this message translates to:
  /// **'Architecture'**
  String get appDetailsArchitecture;

  /// No description provided for @appDetailsBitness.
  ///
  /// In en, this message translates to:
  /// **'Bitness'**
  String get appDetailsBitness;

  /// No description provided for @appDetailsPackageType.
  ///
  /// In en, this message translates to:
  /// **'Package type'**
  String get appDetailsPackageType;

  /// No description provided for @appDetailsApkComponents.
  ///
  /// In en, this message translates to:
  /// **'APK components'**
  String get appDetailsApkComponents;

  /// No description provided for @appDetailsTotalApkSize.
  ///
  /// In en, this message translates to:
  /// **'Total APK size'**
  String get appDetailsTotalApkSize;

  /// No description provided for @appDetailsSigningSha256.
  ///
  /// In en, this message translates to:
  /// **'Signing certificate SHA-256'**
  String get appDetailsSigningSha256;

  /// No description provided for @appDetailsSigningUnreadable.
  ///
  /// In en, this message translates to:
  /// **'could not be read'**
  String get appDetailsSigningUnreadable;

  /// No description provided for @appDetailsNoApkFiles.
  ///
  /// In en, this message translates to:
  /// **'The package manager reported no APK files for this app.'**
  String get appDetailsNoApkFiles;

  /// No description provided for @compatibilityNotAnalysed.
  ///
  /// In en, this message translates to:
  /// **'Not analysed'**
  String get compatibilityNotAnalysed;

  /// No description provided for @compatibilitySupported.
  ///
  /// In en, this message translates to:
  /// **'Supported'**
  String get compatibilitySupported;

  /// No description provided for @compatibilityLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get compatibilityLimited;

  /// No description provided for @compatibilityUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported'**
  String get compatibilityUnsupported;

  /// No description provided for @compatibilityUnexaminedMessage.
  ///
  /// In en, this message translates to:
  /// **'This app could not be examined, so nothing is known about how well it will run. It may still be refused when the clone is created.'**
  String get compatibilityUnexaminedMessage;

  /// No description provided for @compatibilityNoProblems.
  ///
  /// In en, this message translates to:
  /// **'No known compatibility problems.'**
  String get compatibilityNoProblems;

  /// No description provided for @compatibilityExistingClones.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You already have 1 clone of this app. The new one starts empty with its own data.} other{You already have {count} clones of this app. The new one starts empty with its own data.}}'**
  String compatibilityExistingClones(int count);

  /// No description provided for @compatibilityAddClone.
  ///
  /// In en, this message translates to:
  /// **'Add clone'**
  String get compatibilityAddClone;

  /// No description provided for @compatibilityCannotClone.
  ///
  /// In en, this message translates to:
  /// **'Cannot clone'**
  String get compatibilityCannotClone;

  /// No description provided for @findingAppNotFound.
  ///
  /// In en, this message translates to:
  /// **'This application is not installed on the device.'**
  String get findingAppNotFound;

  /// No description provided for @findingSecureEnvRequired.
  ///
  /// In en, this message translates to:
  /// **'This application requires a secure environment and cannot be virtualized.'**
  String get findingSecureEnvRequired;

  /// No description provided for @findingSelfClone.
  ///
  /// In en, this message translates to:
  /// **'{appName} cannot clone itself.'**
  String findingSelfClone(String appName);

  /// No description provided for @findingSystemComponent.
  ///
  /// In en, this message translates to:
  /// **'System components cannot be cloned.'**
  String get findingSystemComponent;

  /// No description provided for @findingAbiNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This app\'s native libraries are not built for an architecture the engine supports.'**
  String get findingAbiNotSupported;

  /// No description provided for @findingRequiresGms.
  ///
  /// In en, this message translates to:
  /// **'Google Play services is available inside a clone, but Google features that must verify this app\'s own identity are not supported — including sign-in and identity-bound APIs such as location and SMS verification.'**
  String get findingRequiresGms;

  /// No description provided for @findingPushUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Push notifications will not work in a clone. Google Play services will not register this app for push while it runs under {appName}\'s identity, so messages sent to the clone never arrive. The app is otherwise usable, but expect a pause on first launch while it waits for a push registration that cannot succeed.'**
  String findingPushUnsupported(String appName);

  /// No description provided for @findingStorageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This app uses shared storage, and this build of {appName} does not declare All files access. A clone of it cannot reach your files and will not work.'**
  String findingStorageUnavailable(String appName);

  /// No description provided for @findingStorageNotGranted.
  ///
  /// In en, this message translates to:
  /// **'This app uses shared storage. Grant {appName} \"All files access\" in Settings → Special app access before launching the clone, or it may be refused at launch.'**
  String findingStorageNotGranted(String appName);

  /// No description provided for @factsNoNativeCode.
  ///
  /// In en, this message translates to:
  /// **'No native code'**
  String get factsNoNativeCode;

  /// No description provided for @factsAnyNoNativeCode.
  ///
  /// In en, this message translates to:
  /// **'Any — no native code'**
  String get factsAnyNoNativeCode;

  /// No description provided for @factsBits32And64.
  ///
  /// In en, this message translates to:
  /// **'32 + 64'**
  String get factsBits32And64;

  /// No description provided for @factsSingleApk.
  ///
  /// In en, this message translates to:
  /// **'Single APK'**
  String get factsSingleApk;

  /// No description provided for @factsSplitApk.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Split APK · {count} files}}'**
  String factsSplitApk(int count);

  /// No description provided for @factsVersionUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get factsVersionUnknown;

  /// No description provided for @filterArchBoth.
  ///
  /// In en, this message translates to:
  /// **'32 + 64'**
  String get filterArchBoth;

  /// No description provided for @filterImportFiles.
  ///
  /// In en, this message translates to:
  /// **'Import by the file manager'**
  String get filterImportFiles;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @renameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename profile'**
  String get renameTitle;

  /// No description provided for @renameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get renameFieldLabel;

  /// No description provided for @uninstallTitle.
  ///
  /// In en, this message translates to:
  /// **'Uninstall this clone?'**
  String get uninstallTitle;

  /// No description provided for @uninstallSpaceOf.
  ///
  /// In en, this message translates to:
  /// **'Space {index} of {count}'**
  String uninstallSpaceOf(int index, int count);

  /// No description provided for @uninstallMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove the selected app instance and its local data.'**
  String get uninstallMessage;

  /// No description provided for @uninstallConfirm.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstallConfirm;

  /// No description provided for @calculatorError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get calculatorError;

  /// No description provided for @disclosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get disclosureTitle;

  /// No description provided for @disclosureIntro.
  ///
  /// In en, this message translates to:
  /// **'{appName} runs a second copy of apps you choose. Here is exactly what it reads and what it will ask you for.'**
  String disclosureIntro(String appName);

  /// No description provided for @disclosureAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your installed apps'**
  String get disclosureAppsTitle;

  /// No description provided for @disclosureAppsBody.
  ///
  /// In en, this message translates to:
  /// **'To show the clone picker, {appName} reads the list of apps installed on this device — their names, icons and versions. This list stays on your device. It is never uploaded, sold or shared, and the app contains no ads, no analytics and no tracker.'**
  String disclosureAppsBody(String appName);

  /// No description provided for @disclosurePermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions on behalf of clones'**
  String get disclosurePermissionsTitle;

  /// No description provided for @disclosurePermissionsBody.
  ///
  /// In en, this message translates to:
  /// **'Cloned apps run inside {appName}, so some Android permissions apply to it on their behalf. You may be asked once to exempt it from battery optimisation so cloned messengers keep delivering. Only when you clone a file or media app, you may need to grant All files access in Settings.'**
  String disclosurePermissionsBody(String appName);

  /// No description provided for @disclosureControlTitle.
  ///
  /// In en, this message translates to:
  /// **'You stay in control'**
  String get disclosureControlTitle;

  /// No description provided for @disclosureControlBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing is requested silently. You can refuse any of these requests and still use the app, and you can change your mind in Android Settings at any time.'**
  String get disclosureControlBody;

  /// No description provided for @disclosureAccept.
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get disclosureAccept;

  /// No description provided for @privateSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Private space'**
  String get privateSpaceTitle;

  /// No description provided for @privateSpaceOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Private space is off'**
  String get privateSpaceOffTitle;

  /// No description provided for @privateSpaceOffMessage.
  ///
  /// In en, this message translates to:
  /// **'Turn it on to hide clones behind a PIN. Hidden apps disappear from the main grid and open only here.'**
  String get privateSpaceOffMessage;

  /// No description provided for @privateSpaceSetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up Private space'**
  String get privateSpaceSetUp;

  /// No description provided for @privateSpaceChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get privateSpaceChangePin;

  /// No description provided for @privateSpaceUnlockSection.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get privateSpaceUnlockSection;

  /// No description provided for @privateSpaceFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint'**
  String get privateSpaceFingerprint;

  /// No description provided for @privateSpaceFingerprintAvailable.
  ///
  /// In en, this message translates to:
  /// **'You can still use your PIN at any time.'**
  String get privateSpaceFingerprintAvailable;

  /// No description provided for @privateSpaceFingerprintUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No fingerprint or face is set up on this device.'**
  String get privateSpaceFingerprintUnavailable;

  /// No description provided for @privateSpaceDisguiseSection.
  ///
  /// In en, this message translates to:
  /// **'Disguise'**
  String get privateSpaceDisguiseSection;

  /// No description provided for @privateSpaceDisguiseAsCalculator.
  ///
  /// In en, this message translates to:
  /// **'Disguise as Calculator'**
  String get privateSpaceDisguiseAsCalculator;

  /// No description provided for @privateSpaceDisguiseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replaces {appName}\'s icon with a calculator. Type your Private space PIN and press = to open the app.'**
  String privateSpaceDisguiseSubtitle(String appName);

  /// No description provided for @privateSpaceTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off Private space'**
  String get privateSpaceTurnOff;

  /// No description provided for @privateSpaceTurnOffNote.
  ///
  /// In en, this message translates to:
  /// **'Turning it off brings every hidden app back to the main grid. The clones themselves are not deleted.'**
  String get privateSpaceTurnOffNote;

  /// No description provided for @privateSpaceDisguiseOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Disguise as Calculator?'**
  String get privateSpaceDisguiseOnTitle;

  /// No description provided for @privateSpaceDisguiseOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Show {appName} again?'**
  String privateSpaceDisguiseOffTitle(String appName);

  /// No description provided for @privateSpaceDisguiseOnMessage.
  ///
  /// In en, this message translates to:
  /// **'{appName}\'s icon is replaced by a calculator named \"Calculator\". To open {appName}, type your Private space PIN and press =. If you forget the PIN you will not be able to open the app.'**
  String privateSpaceDisguiseOnMessage(String appName);

  /// No description provided for @privateSpaceDisguiseOffMessage.
  ///
  /// In en, this message translates to:
  /// **'{appName} will show its own icon and name on the home screen again.'**
  String privateSpaceDisguiseOffMessage(String appName);

  /// No description provided for @privateSpaceDisguiseConfirmOn.
  ///
  /// In en, this message translates to:
  /// **'Disguise'**
  String get privateSpaceDisguiseConfirmOn;

  /// No description provided for @privateSpaceDisguiseConfirmOff.
  ///
  /// In en, this message translates to:
  /// **'Show app'**
  String get privateSpaceDisguiseConfirmOff;

  /// No description provided for @privateSpaceDisguiseFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change how the app appears.'**
  String get privateSpaceDisguiseFailed;

  /// No description provided for @privateSpaceDisguiseNowCalculator.
  ///
  /// In en, this message translates to:
  /// **'{appName} now looks like Calculator on your home screen.'**
  String privateSpaceDisguiseNowCalculator(String appName);

  /// No description provided for @privateSpaceDisguiseRestored.
  ///
  /// In en, this message translates to:
  /// **'{appName} is back on your home screen.'**
  String privateSpaceDisguiseRestored(String appName);

  /// No description provided for @privateSpaceTurnOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off Private space?'**
  String get privateSpaceTurnOffTitle;

  /// No description provided for @privateSpaceTurnOffMessage.
  ///
  /// In en, this message translates to:
  /// **'Every hidden app will return to the main grid, and the PIN will be forgotten. The clones themselves are kept.'**
  String get privateSpaceTurnOffMessage;

  /// No description provided for @privateSpaceTurnOffConfirm.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get privateSpaceTurnOffConfirm;

  /// No description provided for @privateSpaceTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'Private space turned off.'**
  String get privateSpaceTurnedOff;

  /// No description provided for @pinCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create PIN'**
  String get pinCreateTitle;

  /// No description provided for @pinChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get pinChangeTitle;

  /// No description provided for @pinCreateMessage.
  ///
  /// In en, this message translates to:
  /// **'This PIN locks the Private space. Keep it somewhere you will not forget: there is no way to recover a hidden clone without it.'**
  String get pinCreateMessage;

  /// No description provided for @pinChangeMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your current PIN, then choose a new one.'**
  String get pinChangeMessage;

  /// No description provided for @pinCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get pinCurrentLabel;

  /// No description provided for @pinNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get pinNewLabel;

  /// No description provided for @pinConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get pinConfirmLabel;

  /// No description provided for @pinCreateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create Private space'**
  String get pinCreateConfirm;

  /// No description provided for @pinSaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Save PIN'**
  String get pinSaveConfirm;

  /// No description provided for @pinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Use {minimum} to {maximum} digits.'**
  String pinLengthError(int minimum, int maximum);

  /// No description provided for @pinMismatchError.
  ///
  /// In en, this message translates to:
  /// **'The two PINs do not match.'**
  String get pinMismatchError;

  /// No description provided for @pinCurrentIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current PIN is incorrect.'**
  String get pinCurrentIncorrect;

  /// No description provided for @unlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Private space'**
  String get unlockTitle;

  /// No description provided for @unlockPinLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get unlockPinLabel;

  /// No description provided for @unlockUseFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint'**
  String get unlockUseFingerprint;

  /// No description provided for @unlockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockConfirm;

  /// No description provided for @unlockIncorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get unlockIncorrectPin;

  /// No description provided for @unlockFingerprintUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint unlock is not available right now.'**
  String get unlockFingerprintUnavailable;

  /// No description provided for @unlockFingerprintNotRecognised.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint not recognised.'**
  String get unlockFingerprintNotRecognised;

  /// No description provided for @unlockBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock your private space'**
  String get unlockBiometricReason;

  /// No description provided for @privateTileEmpty.
  ///
  /// In en, this message translates to:
  /// **'Private space, empty'**
  String get privateTileEmpty;

  /// No description provided for @privateTileHidden.
  ///
  /// In en, this message translates to:
  /// **'Private space, {count} hidden'**
  String privateTileHidden(int count);

  /// No description provided for @settingsSectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsSectionPrivacy;

  /// No description provided for @settingsPrivateSpaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide apps behind a PIN'**
  String get settingsPrivateSpaceSubtitle;

  /// No description provided for @settingsOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsOn;

  /// No description provided for @settingsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsOff;

  /// No description provided for @componentBaseApk.
  ///
  /// In en, this message translates to:
  /// **'Base APK'**
  String get componentBaseApk;

  /// No description provided for @componentSplitApk.
  ///
  /// In en, this message translates to:
  /// **'Split APK'**
  String get componentSplitApk;

  /// No description provided for @componentNoNativeLibraries.
  ///
  /// In en, this message translates to:
  /// **'No native libraries'**
  String get componentNoNativeLibraries;
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
