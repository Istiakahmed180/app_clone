// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsSectionLegal => 'Legal';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsContact => 'Contact us';

  @override
  String get settingsContactSubtitle => 'Questions or feedback';

  @override
  String get settingsRate => 'Rate us';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Enjoying $appName? Leave a review';
  }

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsArchitecture => 'Device architecture';

  @override
  String get settingsArchitectureSubtitle => 'App compatibility';

  @override
  String get settingsBits64 => '64-bit';

  @override
  String get settingsBits32 => '32-bit';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'Supported ABIs';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Not published yet';

  @override
  String get settingsNotListedYet => 'Not listed yet';

  @override
  String get settingsNotSetUpYet => 'Not set up yet';

  @override
  String get commonUnavailable => 'unavailable';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearancePreview => 'Preview';

  @override
  String get appearanceChooseTheme => 'Choose a theme';

  @override
  String get appearanceSystem => 'System default';

  @override
  String get appearanceSystemSubtitle => 'Match your device settings';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceLightSubtitle => 'Always use light theme';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceDarkSubtitle => 'Always use dark theme';

  @override
  String appearanceInstantNote(String appName) {
    return 'Theme changes apply instantly across $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return '$theme theme preview';
  }

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSearchHint => 'Search languages';

  @override
  String get languageClearSearch => 'Clear search';

  @override
  String languageNote(String appName) {
    return 'Choose the language used in $appName.';
  }

  @override
  String get languageSectionHeader => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageSystemSubtitle => 'Use your device language';

  @override
  String get languageInstantNote => 'Language changes apply immediately.';

  @override
  String languageNoMatches(String query) {
    return 'No language matches \"$query\".';
  }

  @override
  String get contactTitle => 'Contact us';

  @override
  String get contactHeroTitle => 'How can we help?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Choose your preferred way to contact the $appName team.';
  }

  @override
  String get contactSectionOptions => 'Contact options';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Chat with our support team';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Message us on Telegram';

  @override
  String get contactEmail => 'Email';

  @override
  String get contactEmailSubtitle => 'Send us an email';

  @override
  String get contactResponseTime => 'Response time';

  @override
  String get contactResponseTimeValue =>
      'We usually reply within 1–2 business days.';

  @override
  String get contactPrivacyNote =>
      'We\'ll only use your message to provide support.';

  @override
  String contactNoMailApp(String email) {
    return 'No mail app could be opened. Write to $email instead.';
  }

  @override
  String get contactWhatsAppFailed => 'WhatsApp could not be opened.';

  @override
  String get contactTelegramFailed => 'Telegram could not be opened.';

  @override
  String get contactPlayStoreFailed => 'The Play Store could not be opened.';

  @override
  String contactLegalOpenFailed(String document) {
    return 'The $document could not be opened.';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNotNow => 'Not now';

  @override
  String get commonClose => 'Close';

  @override
  String get commonMore => 'More';

  @override
  String get commonFailureTitle => 'Couldn\'t do that';

  @override
  String get homePrivateSpaceTitle => 'Private space';

  @override
  String get homeSubtitle => 'Your private space';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hidden apps',
      one: '1 hidden app',
      zero: 'No hidden apps',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => 'Lock and close';

  @override
  String get homeMenuSettings => 'Settings';

  @override
  String get homeMenuDeveloperTools => 'Developer Tools';

  @override
  String get homeAddApp => 'Add app';

  @override
  String get homeEmptyTitle => 'Your space is empty';

  @override
  String get homeEmptyMessage =>
      'Add an app to create your first private instance.';

  @override
  String get homeEmptyAction => 'Add your first app';

  @override
  String get homePrivateEmptyTitle => 'Nothing hidden yet';

  @override
  String get homePrivateEmptyMessage =>
      'Hold any app on the main grid and choose Hide to move it in here.';

  @override
  String get homeSetUpPrivateSpaceTitle => 'Set up Private space?';

  @override
  String get homeSetUpPrivateSpaceMessage =>
      'Hiding a clone needs a Private space. Create one with a PIN first.';

  @override
  String get homeSetUpPrivateSpaceConfirm => 'Set up';

  @override
  String get homeEngineInactive =>
      'The virtualization engine is not active on this device, so clones cannot run in isolated containers.';

  @override
  String get homeEngineUnavailable =>
      'The virtualization engine is unavailable on this device.';

  @override
  String cloneSpaceLabel(int index) {
    return 'Space $index';
  }

  @override
  String get cloneActionsManage => 'Manage';

  @override
  String get cloneActionUninstall => 'Uninstall';

  @override
  String get cloneActionClone => 'Clone';

  @override
  String get cloneActionShortcut => 'Shortcut';

  @override
  String get cloneActionSpaceInfo => 'Space info';

  @override
  String get cloneActionEditName => 'Edit name';

  @override
  String get cloneActionChangeIcon => 'Change icon';

  @override
  String get cloneIconPickerChoose => 'Choose a picture';

  @override
  String get cloneIconPickerUseAppIcon => 'Use the app\'s icon';

  @override
  String get errorCloneIconFailed =>
      'That picture could not be used as an icon. Try a different one.';

  @override
  String get cloneIconPickerTitle => 'This clone\'s icon';

  @override
  String get cloneIconPickerMessage =>
      'Give it a picture of your own, or keep the app\'s icon and mark it with a colour — either way you can tell it from your other clones of the same app at a glance.';

  @override
  String get cloneActionForceStop => 'Force stop';

  @override
  String get cloneActionClearCache => 'Clear cache';

  @override
  String get cloneActionClearStorage => 'Clear storage';

  @override
  String get cloneActionHide => 'Hide';

  @override
  String get cloneActionUnhide => 'Unhide';

  @override
  String get cloneActionShareApp => 'Share app';

  @override
  String get cloneActionPermissions => 'Permissions';

  @override
  String get cloneActionInstallGoogleServices => 'Install Google services';

  @override
  String cloneTileSibling(int index, int count) {
    return ', clone $index of $count';
  }

  @override
  String get cloneTileOpening => ', opening';

  @override
  String get cloneTileRunning => ', running';

  @override
  String get cloneTileCannotLaunch => ', cannot be launched on this device';

  @override
  String get cloneForceStopTitle => 'Force stop this app?';

  @override
  String get cloneForceStopMessage =>
      'The app will stop running until you open it again.';

  @override
  String get cloneForceStopConfirm => 'Force stop';

  @override
  String get cloneClearCacheTitle => 'Clear app cache?';

  @override
  String get cloneClearCacheMessage =>
      'This will remove temporary files for this clone.';

  @override
  String get cloneClearCacheConfirm => 'Clear cache';

  @override
  String get cloneClearStorageTitle => 'Clear app storage?';

  @override
  String get cloneClearStorageMessage =>
      'This will permanently delete this clone\'s accounts, settings, and local data.';

  @override
  String get cloneClearStorageConfirm => 'Clear Storage';

  @override
  String get cloneInstallGoogleServicesTitle => 'Install Google services?';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName will install Google Play services into this clone. The clone keeps its data. This can take a few seconds.';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => 'Install';

  @override
  String cloneStopped(String name) {
    return 'Stopped $name.';
  }

  @override
  String cloneCacheCleared(String name) {
    return 'Cache cleared for $name.';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name was reset. Its next launch is a first launch.';
  }

  @override
  String cloneHidden(String name) {
    return '$name hidden in Private space.';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name is back on the main grid.';
  }

  @override
  String get cloneShortcutAdded =>
      'Confirm the shortcut on your home screen to finish adding it.';

  @override
  String get cloneGoogleServicesInstalling => 'Installing Google services…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return 'Google services installed in $name.';
  }

  @override
  String get cloneCountTitle => 'Clone app';

  @override
  String cloneCountMessage(String appName) {
    return 'Create additional copies of $appName.';
  }

  @override
  String get cloneCountLabel => 'Number of clones';

  @override
  String get cloneCountDecrease => 'One fewer';

  @override
  String get cloneCountIncrease => 'One more';

  @override
  String get cloneCountConfirm => 'Clone';

  @override
  String cloneCreating(int created, int total) {
    return 'Creating $created of $total…';
  }

  @override
  String get cloneCreatingFinishing => 'Finishing…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count more copies of $appName.',
      one: 'Added another $appName.',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return 'Created $created of $total. $failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return 'Choose from 1 to $maximum';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return 'Only $free is free, and the device keeps half a gigabyte spare.';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return 'Up to $maximum — $free of space left';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return 'Up to $maximum at a time on a device with $memory of memory';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return 'There is no room for another $appName clone. $reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return 'Not enough room for $count more $appName clones. $reason.';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return 'Permissions · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => 'Could not read permissions';

  @override
  String get clonePermissionsEmptyTitle => 'Nothing to scope';

  @override
  String get clonePermissionsEmptyMessage =>
      'This app declares no dangerous permissions, so there is nothing to allow or deny for this clone.';

  @override
  String clonePermissionsNote(String appName) {
    return 'These apply to this clone only. A cloned app usually asks before it uses a permission, and this is where that answer is scoped — an app that skips the ask may still reach hardware through $appName\'s own grant.';
  }

  @override
  String get spaceInfoTitle => 'Space Info';

  @override
  String get spaceInfoIdentifiers => 'Device identifiers';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => 'Engine unavailable';

  @override
  String get spaceInfoStateRunning => 'Running';

  @override
  String get spaceInfoStateActive => 'Active';

  @override
  String get spaceInfoStateRebuilds => 'Rebuilds on launch';

  @override
  String get spaceInfoNoContainer =>
      'This space has no container yet, so it has no identifiers. Launch it once and they will appear here.';

  @override
  String get spaceInfoDeviceId => 'Device ID';

  @override
  String get spaceInfoAndroidId => 'Android ID';

  @override
  String get spaceInfoSerialNumber => 'Serial number';

  @override
  String get spaceInfoWifiMac => 'Wi-Fi MAC';

  @override
  String get spaceInfoBluetoothMac => 'Bluetooth MAC';

  @override
  String spaceInfoCopy(String label) {
    return 'Copy $label';
  }

  @override
  String spaceInfoCopied(String label) {
    return '$label copied.';
  }

  @override
  String get commonBack => 'Back';

  @override
  String get commonApply => 'Apply';

  @override
  String get pickerTitle => 'Add app';

  @override
  String get pickerSearchHint => 'Search apps';

  @override
  String get pickerFilterTooltip => 'Filter and sort';

  @override
  String get pickerErrorTitle => 'Could not list apps';

  @override
  String get pickerNoMatchesTitle => 'No matching apps';

  @override
  String get pickerNoMatchesMessage =>
      'Try a different search, or import an APK instead.';

  @override
  String get pickerPopular => 'Popular';

  @override
  String get pickerQuickPicks => 'Quick picks';

  @override
  String get pickerInstalledApps => 'Installed apps';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => 'System';

  @override
  String get pickerCannotClone => 'This app cannot be cloned on this device.';

  @override
  String get pickerApkUnreadable => 'The selected APK could not be read.';

  @override
  String pickerHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps on this device cannot be cloned and are not listed',
      one: '1 app on this device cannot be cloned and is not listed',
    );
    return '$_temp0';
  }

  @override
  String get filterTitle => 'Filter and sort';

  @override
  String get filterSort => 'Sort';

  @override
  String get filterSortName => 'App name';

  @override
  String get filterSortRecentlyInstalled => 'Recently installed';

  @override
  String get filterSortRecentlyUpdated => 'Recently updated';

  @override
  String get filterFilter => 'Filter';

  @override
  String get filterAllApps => 'All apps';

  @override
  String get filterUserApps => 'User apps';

  @override
  String get filterSystemApps => 'System apps';

  @override
  String get filterNotAdded => 'Not added';

  @override
  String get filterAlreadyAdded => 'Already added';

  @override
  String get filterArchitecture => 'Architecture';

  @override
  String get filterArch64 => '64-bit';

  @override
  String get filterArch32 => '32-bit';

  @override
  String get filterArchNoNativeCode => 'No native code';

  @override
  String get filterPackageType => 'Package type';

  @override
  String get filterPackageSingle => 'Single APK';

  @override
  String get filterPackageSplit => 'Split APK';

  @override
  String filterImportApk(String appName) {
    return 'Open $appName App Package';
  }

  @override
  String get appSheetAddClone => 'Add clone';

  @override
  String get appSheetAddAnother => 'Add another';

  @override
  String get appSheetShareApp => 'Share app';

  @override
  String get appSheetAppDetails => 'App details';

  @override
  String get appDetailsTitle => 'App details';

  @override
  String get appDetailsAdvanced => 'Advanced details';

  @override
  String get appDetailsPackageName => 'Package name';

  @override
  String get appDetailsVersion => 'Version';

  @override
  String get appDetailsArchitecture => 'Architecture';

  @override
  String get appDetailsBitness => 'Bitness';

  @override
  String get appDetailsPackageType => 'Package type';

  @override
  String get appDetailsApkComponents => 'APK components';

  @override
  String get appDetailsTotalApkSize => 'Total APK size';

  @override
  String get appDetailsSigningSha256 => 'Signing certificate SHA-256';

  @override
  String get appDetailsSigningUnreadable => 'could not be read';

  @override
  String get appDetailsNoApkFiles =>
      'The package manager reported no APK files for this app.';

  @override
  String get findingAppNotFound =>
      'This application is not installed on the device.';

  @override
  String get findingSecureEnvRequired =>
      'This application requires a secure environment and cannot be virtualized.';

  @override
  String findingSelfClone(String appName) {
    return '$appName cannot clone itself.';
  }

  @override
  String get findingSystemComponent => 'System components cannot be cloned.';

  @override
  String get findingAbiNotSupported =>
      'This app\'s native libraries are not built for an architecture the engine supports.';

  @override
  String findingStorageUnavailable(String appName) {
    return 'This app uses shared storage, and this build of $appName does not declare All files access. A clone of it cannot reach your files and will not work.';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return 'This app uses shared storage. Grant $appName \"All files access\" in Settings → Special app access before launching the clone, or it may be refused at launch.';
  }

  @override
  String get factsNoNativeCode => 'No native code';

  @override
  String get factsAnyNoNativeCode => 'Any — no native code';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => 'Single APK';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Split APK · $count files',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => 'unknown';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => 'Import by the file manager';

  @override
  String get commonSave => 'Save';

  @override
  String get renameTitle => 'Rename profile';

  @override
  String get renameFieldLabel => 'Profile name';

  @override
  String get uninstallTitle => 'Uninstall this clone?';

  @override
  String uninstallSpaceOf(int index, int count) {
    return 'Space $index of $count';
  }

  @override
  String get uninstallMessage =>
      'This will remove the selected app instance and its local data.';

  @override
  String get uninstallConfirm => 'Uninstall';

  @override
  String get calculatorError => 'Error';

  @override
  String get disclosureTitle => 'Before you start';

  @override
  String disclosureIntro(String appName) {
    return '$appName runs a second copy of apps you choose. Here is exactly what it reads and what it will ask you for.';
  }

  @override
  String get disclosureAppsTitle => 'Your installed apps';

  @override
  String disclosureAppsBody(String appName) {
    return 'To show the clone picker, $appName reads the list of apps installed on this device — their names, icons and versions. This list stays on your device. It is never uploaded, sold or shared, and the app contains no ads, no analytics and no tracker.';
  }

  @override
  String get disclosurePermissionsTitle => 'Permissions on behalf of clones';

  @override
  String disclosurePermissionsBody(String appName) {
    return 'Cloned apps run inside $appName, so some Android permissions apply to it on their behalf. You may be asked once to exempt it from battery optimisation so cloned messengers keep delivering. Only when you clone a file or media app, you may need to grant All files access in Settings.';
  }

  @override
  String get disclosureControlTitle => 'You stay in control';

  @override
  String get disclosureControlBody =>
      'Nothing is requested silently. You can refuse any of these requests and still use the app, and you can change your mind in Android Settings at any time.';

  @override
  String get disclosureAccept => 'Agree and continue';

  @override
  String get privateSpaceTitle => 'Private space';

  @override
  String get privateSpaceOffTitle => 'Private space is off';

  @override
  String get privateSpaceOffMessage =>
      'Turn it on to hide clones behind a PIN. Hidden apps disappear from the main grid and open only here.';

  @override
  String get privateSpaceSetUp => 'Set up Private space';

  @override
  String get privateSpaceChangePin => 'Change PIN';

  @override
  String get privateSpaceUnlockSection => 'Unlock';

  @override
  String get privateSpaceFingerprint => 'Unlock with fingerprint';

  @override
  String get privateSpaceFingerprintAvailable =>
      'You can still use your PIN at any time.';

  @override
  String get privateSpaceFingerprintUnavailable =>
      'No fingerprint or face is set up on this device.';

  @override
  String get privateSpaceDisguiseSection => 'Disguise';

  @override
  String get privateSpaceDisguiseAsCalculator => 'Disguise as Calculator';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return 'Replaces $appName\'s icon with a calculator. Type your Private space PIN and press = to open the app.';
  }

  @override
  String get privateSpaceTurnOff => 'Turn off Private space';

  @override
  String get privateSpaceTurnOffNote =>
      'Turning it off brings every hidden app back to the main grid. The clones themselves are not deleted.';

  @override
  String get privateSpaceDisguiseOnTitle => 'Disguise as Calculator?';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return 'Show $appName again?';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return '$appName\'s icon is replaced by a calculator named \"Calculator\". To open $appName, type your Private space PIN and press =. If you forget the PIN you will not be able to open the app.';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName will show its own icon and name on the home screen again.';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => 'Disguise';

  @override
  String get privateSpaceDisguiseConfirmOff => 'Show app';

  @override
  String get privateSpaceDisguiseFailed =>
      'Could not change how the app appears.';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '$appName now looks like Calculator on your home screen.';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName is back on your home screen.';
  }

  @override
  String get privateSpaceTurnOffTitle => 'Turn off Private space?';

  @override
  String get privateSpaceTurnOffMessage =>
      'Every hidden app will return to the main grid, and the PIN will be forgotten. The clones themselves are kept.';

  @override
  String get privateSpaceTurnOffConfirm => 'Turn off';

  @override
  String get privateSpaceTurnedOff => 'Private space turned off.';

  @override
  String get pinCreateTitle => 'Create PIN';

  @override
  String get pinChangeTitle => 'Change PIN';

  @override
  String get pinCreateMessage =>
      'This PIN locks the Private space. Keep it somewhere you will not forget: there is no way to recover a hidden clone without it.';

  @override
  String get pinChangeMessage =>
      'Enter your current PIN, then choose a new one.';

  @override
  String get pinCurrentLabel => 'Current PIN';

  @override
  String get pinNewLabel => 'New PIN';

  @override
  String get pinConfirmLabel => 'Confirm PIN';

  @override
  String get pinCreateConfirm => 'Create Private space';

  @override
  String get pinSaveConfirm => 'Save PIN';

  @override
  String pinLengthError(int minimum, int maximum) {
    return 'Use $minimum to $maximum digits.';
  }

  @override
  String get pinMismatchError => 'The two PINs do not match.';

  @override
  String get pinCurrentIncorrect => 'Current PIN is incorrect.';

  @override
  String get unlockTitle => 'Unlock Private space';

  @override
  String get unlockPinLabel => 'PIN';

  @override
  String get unlockUseFingerprint => 'Use fingerprint';

  @override
  String get unlockConfirm => 'Unlock';

  @override
  String get unlockIncorrectPin => 'Incorrect PIN';

  @override
  String get unlockFingerprintUnavailable =>
      'Fingerprint unlock is not available right now.';

  @override
  String get unlockFingerprintNotRecognised => 'Fingerprint not recognised.';

  @override
  String get unlockBiometricReason => 'Unlock your private space';

  @override
  String get privateTileEmpty => 'Private space, empty';

  @override
  String privateTileHidden(int count) {
    return 'Private space, $count hidden';
  }

  @override
  String get settingsSectionPrivacy => 'Privacy';

  @override
  String get settingsPrivateSpaceSubtitle => 'Hide apps behind a PIN';

  @override
  String get settingsOn => 'On';

  @override
  String get settingsOff => 'Off';

  @override
  String get componentBaseApk => 'Base APK';

  @override
  String get componentSplitApk => 'Split APK';

  @override
  String get componentNoNativeLibraries => 'No native libraries';

  @override
  String get errorProfileNameEmpty => 'A clone needs a name.';

  @override
  String errorProfileNameTooLong(int maximum) {
    return 'A clone\'s name can be at most $maximum characters.';
  }

  @override
  String get errorProfileStorageUnreadable =>
      'Your saved clones could not be read.';

  @override
  String get errorProfileNotFound => 'That clone no longer exists.';

  @override
  String get errorBridgeFailed =>
      'Something went wrong talking to the part of the app that manages clones.';

  @override
  String get errorBridgeUnsupportedPlatform =>
      'This feature is only available on Android.';

  @override
  String get errorTestAppCheckFailed =>
      'Whether the test app is installed could not be checked.';

  @override
  String get errorEngineInitFailed =>
      'The virtualization engine failed to start on this device.';

  @override
  String get errorEngineAndroidTooOld =>
      'The virtualization engine requires a newer version of Android.';

  @override
  String get errorEngineNoResponse =>
      'The virtualization engine did not answer. Try again.';

  @override
  String get errorNoContainer =>
      'This clone has no container yet. Open it once and try again.';

  @override
  String get errorLaunchRefused => 'The engine refused to open this clone.';

  @override
  String get errorAlreadyCloned => 'This app has already been cloned.';

  @override
  String get errorClearCacheFailed =>
      'Part of this clone\'s cache could not be deleted.';

  @override
  String get errorClearDataFailed => 'This clone\'s data could not be cleared.';

  @override
  String get errorShortcutsUnsupported =>
      'This launcher does not support adding shortcuts.';

  @override
  String get errorShortcutRefused => 'The launcher refused the shortcut.';

  @override
  String get errorApkGone =>
      'This clone\'s APK is no longer on the device, so there is nothing to share.';

  @override
  String get errorShareFailed => 'The app could not be shared.';

  @override
  String get errorApkUnreadable =>
      'One of the selected APKs could not be read.';

  @override
  String get errorApkPackageMismatch =>
      'All selected APKs must belong to the same app.';

  @override
  String get errorApkVersionMismatch =>
      'All selected APKs must have the same version.';

  @override
  String get errorApkBaseRequired =>
      'Select exactly one base APK and one or more configuration splits.';

  @override
  String get errorApkDuplicateSplit =>
      'The same APK split was selected more than once.';
}
