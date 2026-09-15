// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsSectionLegal => 'Rechtliches';

  @override
  String get settingsSectionAbout => 'Über';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsAppearance => 'Erscheinungsbild';

  @override
  String get settingsContact => 'Kontakt';

  @override
  String get settingsContactSubtitle => 'Fragen oder Feedback';

  @override
  String get settingsRate => 'Bewerten';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Gefällt dir $appName? Schreibe eine Bewertung';
  }

  @override
  String get settingsPrivacyPolicy => 'Datenschutzerklärung';

  @override
  String get settingsTermsOfService => 'Nutzungsbedingungen';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsArchitecture => 'Gerätearchitektur';

  @override
  String get settingsArchitectureSubtitle => 'App-Kompatibilität';

  @override
  String get settingsBits64 => '64-Bit';

  @override
  String get settingsBits32 => '32-Bit';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'Unterstützte ABIs';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Noch nicht veröffentlicht';

  @override
  String get settingsNotListedYet => 'Noch nicht im Store';

  @override
  String get settingsNotSetUpYet => 'Noch nicht eingerichtet';

  @override
  String get settingsSectionDelivery => 'Zustellung';

  @override
  String get settingsBackgroundActivity => 'Hintergrundaktivität';

  @override
  String get settingsBackgroundActivitySubtitle =>
      'Lässt geklonte Apps Benachrichtigungen erhalten, während sie geschlossen sind';

  @override
  String get settingsBackgroundActivityAllowed => 'Erlaubt';

  @override
  String get settingsBackgroundActivityRestricted => 'Eingeschränkt';

  @override
  String get settingsBackgroundActivityNotAllowed => 'Nicht erlaubt';

  @override
  String get backgroundGuideAllowedStatus =>
      'Hintergrundaktivität ist erlaubt, deshalb erhalten geklonte Apps Benachrichtigungen, während sie geschlossen sind.';

  @override
  String get backgroundGuideDone => 'Fertig';

  @override
  String get backgroundGuideTitle => 'Hintergrundaktivität';

  @override
  String get backgroundGuideWhy =>
      'Android kann Duplika im Hintergrund pausieren; geklonte Apps verpassen dann Benachrichtigungen, bis du Duplika wieder öffnest.';

  @override
  String get backgroundGuideStepsOem =>
      'Tippe in den App-Infos auf Akkuverbrauch und aktiviere Hintergrundaktivität.';

  @override
  String get backgroundGuideStepsStock =>
      'Tippe in der Systemfrage auf Zulassen, damit die App im Hintergrund laufen darf.';

  @override
  String get backgroundGuideStepsUnknown =>
      'Erlaube in den App-Infos die Hintergrundaktivität.';

  @override
  String get backgroundGuideOpenAppInfo => 'App-Infos öffnen';

  @override
  String get backgroundGuideAllow => 'Zulassen';

  @override
  String get backgroundGuideLater => 'Später';

  @override
  String get settingsBackgroundActivityFix =>
      'Hier tippen und Hintergrundaktivität erlauben';

  @override
  String get settingsBackgroundActivityFixBatteryUsage =>
      'Hier tippen, dann Akkuverbrauch, dann Hintergrundaktivität erlauben';

  @override
  String get settingsBackgroundActivityFailed =>
      'Die Einstellungen für die Hintergrundaktivität konnten nicht geöffnet werden.';

  @override
  String get commonUnavailable => 'nicht verfügbar';

  @override
  String get appearanceTitle => 'Erscheinungsbild';

  @override
  String get appearancePreview => 'Vorschau';

  @override
  String get appearanceChooseTheme => 'Design wählen';

  @override
  String get appearanceSystem => 'Systemstandard';

  @override
  String get appearanceSystemSubtitle => 'Geräteeinstellungen folgen';

  @override
  String get appearanceLight => 'Hell';

  @override
  String get appearanceLightSubtitle => 'Immer helles Design';

  @override
  String get appearanceDark => 'Dunkel';

  @override
  String get appearanceDarkSubtitle => 'Immer dunkles Design';

  @override
  String appearanceInstantNote(String appName) {
    return 'Designänderungen gelten sofort in ganz $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Vorschau des Designs $theme';
  }

  @override
  String get languageTitle => 'Sprache';

  @override
  String get languageSearchHint => 'Sprachen suchen';

  @override
  String get languageClearSearch => 'Suche löschen';

  @override
  String languageNote(String appName) {
    return 'Wähle die Sprache, die in $appName verwendet wird.';
  }

  @override
  String get languageSectionHeader => 'Sprache';

  @override
  String get languageSystem => 'Systemstandard';

  @override
  String get languageSystemSubtitle => 'Gerätesprache verwenden';

  @override
  String get languageInstantNote => 'Sprachänderungen gelten sofort.';

  @override
  String languageNoMatches(String query) {
    return 'Keine Sprache passt zu „$query“.';
  }

  @override
  String get contactTitle => 'Kontakt';

  @override
  String get contactHeroTitle => 'Wie können wir helfen?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Wähle, wie du das $appName-Team erreichen möchtest.';
  }

  @override
  String get contactSectionOptions => 'Kontaktmöglichkeiten';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Chatte mit unserem Support-Team';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Schreibe uns auf Telegram';

  @override
  String get contactEmail => 'E-Mail';

  @override
  String get contactEmailSubtitle => 'Schreibe uns eine E-Mail';

  @override
  String get contactResponseTime => 'Antwortzeit';

  @override
  String get contactResponseTimeValue =>
      'Wir antworten meist innerhalb von 1–2 Werktagen.';

  @override
  String get contactPrivacyNote =>
      'Wir verwenden deine Nachricht nur für den Support.';

  @override
  String contactNoMailApp(String email) {
    return 'Es konnte keine Mail-App geöffnet werden. Schreibe stattdessen an $email.';
  }

  @override
  String get contactWhatsAppFailed => 'WhatsApp konnte nicht geöffnet werden.';

  @override
  String get contactTelegramFailed => 'Telegram konnte nicht geöffnet werden.';

  @override
  String get contactPlayStoreFailed =>
      'Der Play Store konnte nicht geöffnet werden.';

  @override
  String contactLegalOpenFailed(String document) {
    return '$document konnte nicht geöffnet werden.';
  }

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNotNow => 'Jetzt nicht';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonMore => 'Mehr';

  @override
  String get commonFailureTitle => 'Das hat nicht geklappt';

  @override
  String get homePrivateSpaceTitle => 'Privater Bereich';

  @override
  String get homeSubtitle => 'Dein privater Bereich';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgeblendete Apps',
      one: '1 ausgeblendete App',
      zero: 'Keine ausgeblendeten Apps',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => 'Sperren und schließen';

  @override
  String get homeMenuSettings => 'Einstellungen';

  @override
  String get homeMenuDeveloperTools => 'Entwicklertools';

  @override
  String get homeAddApp => 'App hinzufügen';

  @override
  String get homeEmptyTitle => 'Dein Bereich ist leer';

  @override
  String get homeEmptyMessage =>
      'Füge eine App hinzu, um deine erste private Instanz zu erstellen.';

  @override
  String get homeEmptyAction => 'Erste App hinzufügen';

  @override
  String get homePrivateEmptyTitle => 'Noch nichts ausgeblendet';

  @override
  String get homePrivateEmptyMessage =>
      'Halte eine beliebige App im Hauptraster gedrückt und wähle Ausblenden, um sie hierher zu verschieben.';

  @override
  String get homeSetUpPrivateSpaceTitle => 'Privaten Bereich einrichten?';

  @override
  String get homeSetUpPrivateSpaceMessage =>
      'Zum Ausblenden eines Klons braucht es einen privaten Bereich. Richte ihn zuerst mit einer PIN ein.';

  @override
  String get homeSetUpPrivateSpaceConfirm => 'Einrichten';

  @override
  String get homeEngineInactive =>
      'Die Virtualisierungs-Engine ist auf diesem Gerät nicht aktiv, deshalb können Klone nicht in isolierten Containern laufen.';

  @override
  String get homeEngineUnavailable =>
      'Die Virtualisierungs-Engine ist auf diesem Gerät nicht verfügbar.';

  @override
  String get homeBackgroundNudgeTitle =>
      'Klone verpassen möglicherweise Benachrichtigungen, solange sie geschlossen sind.';

  @override
  String get homeBackgroundNudgeMessage =>
      'Stelle sicher, dass Hintergrundaktivität erlaubt ist, damit sie weiter ankommen.';

  @override
  String get homeBackgroundNudgeAllow => 'Erlauben';

  @override
  String get homeBackgroundNudgeDismiss => 'Ausblenden';

  @override
  String cloneSpaceLabel(int index) {
    return 'Bereich $index';
  }

  @override
  String get cloneActionsCompatibility => 'Kompatibilität';

  @override
  String get cloneActionsManage => 'Verwalten';

  @override
  String get cloneActionUninstall => 'Deinstallieren';

  @override
  String get cloneActionClone => 'Klonen';

  @override
  String get cloneActionShortcut => 'Verknüpfung';

  @override
  String get cloneActionSpaceInfo => 'Bereichsinfo';

  @override
  String get cloneActionEditName => 'Namen ändern';

  @override
  String get cloneActionForceStop => 'Beenden erzwingen';

  @override
  String get cloneActionClearCache => 'Cache leeren';

  @override
  String get cloneActionClearStorage => 'Daten löschen';

  @override
  String get cloneActionHide => 'Ausblenden';

  @override
  String get cloneActionUnhide => 'Einblenden';

  @override
  String get cloneActionShareApp => 'App teilen';

  @override
  String get cloneActionNotifications => 'Benachrichtigungen';

  @override
  String get cloneActionPermissions => 'Berechtigungen';

  @override
  String get cloneActionGoogleServicesInstalled =>
      'Google-Dienste (microG) installiert';

  @override
  String get cloneActionInstallGoogleServices =>
      'Google-Dienste (microG) installieren';

  @override
  String cloneTileSibling(int index, int count) {
    return ', Klon $index von $count';
  }

  @override
  String get cloneTileOpening => ', wird geöffnet';

  @override
  String get cloneTileRunning => ', läuft';

  @override
  String get cloneTileCannotLaunch =>
      ', kann auf diesem Gerät nicht gestartet werden';

  @override
  String get cloneForceStopTitle => 'Beenden dieser App erzwingen?';

  @override
  String get cloneForceStopMessage =>
      'Die App läuft nicht weiter, bis du sie wieder öffnest.';

  @override
  String get cloneForceStopConfirm => 'Beenden erzwingen';

  @override
  String get cloneClearCacheTitle => 'Cache der App leeren?';

  @override
  String get cloneClearCacheMessage =>
      'Dadurch werden die temporären Dateien dieses Klons entfernt.';

  @override
  String get cloneClearCacheConfirm => 'Cache leeren';

  @override
  String get cloneClearStorageTitle => 'Daten der App löschen?';

  @override
  String get cloneClearStorageMessage =>
      'Dadurch werden Konten, Einstellungen und lokale Daten dieses Klons dauerhaft gelöscht.';

  @override
  String get cloneClearStorageConfirm => 'Daten löschen';

  @override
  String get cloneInstallGoogleServicesTitle => 'Google-Dienste installieren?';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName installiert das mitgelieferte microG als Google Play-Dienste in diesen Klon. Der Klon behält seine Daten. Das kann einige Sekunden dauern.';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => 'Installieren';

  @override
  String cloneStopped(String name) {
    return '$name beendet.';
  }

  @override
  String cloneCacheCleared(String name) {
    return 'Cache für $name geleert.';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name wurde zurückgesetzt. Der nächste Start ist ein Erststart.';
  }

  @override
  String cloneHidden(String name) {
    return '$name im privaten Bereich ausgeblendet.';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name ist zurück im Hauptraster.';
  }

  @override
  String get cloneShortcutAdded =>
      'Bestätige die Verknüpfung auf deinem Startbildschirm, um sie fertig hinzuzufügen.';

  @override
  String get cloneGoogleServicesInstalling =>
      'Google-Dienste werden installiert…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return 'Google-Dienste in $name installiert.';
  }

  @override
  String get cloneCountTitle => 'App klonen';

  @override
  String cloneCountMessage(String appName) {
    return 'Weitere Kopien von $appName erstellen.';
  }

  @override
  String get cloneCountLabel => 'Anzahl der Klone';

  @override
  String get cloneCountDecrease => 'Einer weniger';

  @override
  String get cloneCountIncrease => 'Einer mehr';

  @override
  String get cloneCountConfirm => 'Klonen';

  @override
  String cloneCreating(int created, int total) {
    return '$created von $total wird erstellt…';
  }

  @override
  String get cloneCreatingFinishing => 'Wird abgeschlossen…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere Kopien von $appName hinzugefügt.',
      one: 'Eine weitere Kopie von $appName hinzugefügt.',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return '$created von $total erstellt. $failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return 'Wähle 1 bis $maximum';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return 'Es sind nur $free frei, und das Gerät hält ein halbes Gigabyte zurück.';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return 'Bis zu $maximum — $free Speicher übrig';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return 'Bis zu $maximum gleichzeitig auf einem Gerät mit $memory Arbeitsspeicher';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return 'Für einen weiteren Klon von $appName ist kein Platz. $reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return 'Nicht genug Platz für $count weitere Klone von $appName. $reason.';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return 'Berechtigungen · $appName';
  }

  @override
  String get clonePermissionsErrorTitle =>
      'Berechtigungen konnten nicht gelesen werden';

  @override
  String get clonePermissionsEmptyTitle => 'Nichts einzuschränken';

  @override
  String get clonePermissionsEmptyMessage =>
      'Diese App deklariert keine gefährlichen Berechtigungen, es gibt für diesen Klon also nichts zu erlauben oder zu verweigern.';

  @override
  String clonePermissionsNote(String appName) {
    return 'Das gilt nur für diesen Klon. Eine geklonte App fragt normalerweise, bevor sie eine Berechtigung nutzt, und hier wird diese Antwort eingeschränkt — eine App, die die Frage überspringt, kann über die Berechtigung von $appName selbst trotzdem an die Hardware kommen.';
  }

  @override
  String get spaceInfoTitle => 'Bereichsinfo';

  @override
  String get spaceInfoIdentifiers => 'Gerätekennungen';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => 'Engine nicht verfügbar';

  @override
  String get spaceInfoStateRunning => 'Läuft';

  @override
  String get spaceInfoStateActive => 'Aktiv';

  @override
  String get spaceInfoStateRebuilds => 'Wird beim Start neu aufgebaut';

  @override
  String get spaceInfoNoContainer =>
      'Dieser Bereich hat noch keinen Container und damit keine Kennungen. Öffne ihn einmal, dann erscheinen sie hier.';

  @override
  String get spaceInfoDeviceId => 'Geräte-ID';

  @override
  String get spaceInfoAndroidId => 'Android-ID';

  @override
  String get spaceInfoSerialNumber => 'Seriennummer';

  @override
  String get spaceInfoWifiMac => 'WLAN-MAC';

  @override
  String get spaceInfoBluetoothMac => 'Bluetooth-MAC';

  @override
  String spaceInfoCopy(String label) {
    return '$label kopieren';
  }

  @override
  String spaceInfoCopied(String label) {
    return '$label kopiert.';
  }

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonApply => 'Anwenden';

  @override
  String get pickerTitle => 'App hinzufügen';

  @override
  String get pickerSearchHint => 'Apps suchen';

  @override
  String get pickerFilterTooltip => 'Filtern und sortieren';

  @override
  String get pickerErrorTitle => 'Apps konnten nicht aufgelistet werden';

  @override
  String get pickerNoMatchesTitle => 'Keine passenden Apps';

  @override
  String get pickerNoMatchesMessage =>
      'Versuche eine andere Suche oder importiere stattdessen eine APK.';

  @override
  String get pickerPopular => 'Beliebt';

  @override
  String get pickerQuickPicks => 'Schnellauswahl';

  @override
  String get pickerInstalledApps => 'Installierte Apps';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Apps',
      one: '1 App',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => 'System';

  @override
  String get pickerCannotClone =>
      'Diese App kann auf diesem Gerät nicht geklont werden.';

  @override
  String get pickerApkUnreadable =>
      'Die ausgewählte APK konnte nicht gelesen werden.';

  @override
  String get filterTitle => 'Filtern und sortieren';

  @override
  String get filterSort => 'Sortieren';

  @override
  String get filterSortName => 'App-Name';

  @override
  String get filterSortRecentlyInstalled => 'Zuletzt installiert';

  @override
  String get filterSortRecentlyUpdated => 'Zuletzt aktualisiert';

  @override
  String get filterFilter => 'Filtern';

  @override
  String get filterAllApps => 'Alle Apps';

  @override
  String get filterUserApps => 'Nutzer-Apps';

  @override
  String get filterSystemApps => 'System-Apps';

  @override
  String get filterNotAdded => 'Nicht hinzugefügt';

  @override
  String get filterAlreadyAdded => 'Bereits hinzugefügt';

  @override
  String get filterArchitecture => 'Architektur';

  @override
  String get filterArch64 => '64-Bit';

  @override
  String get filterArch32 => '32-Bit';

  @override
  String get filterArchNoNativeCode => 'Kein nativer Code';

  @override
  String get filterPackageType => 'Pakettyp';

  @override
  String get filterPackageSingle => 'Einzelne APK';

  @override
  String get filterPackageSplit => 'Split-APK';

  @override
  String filterImportApk(String appName) {
    return '$appName-App-Paket öffnen';
  }

  @override
  String get appSheetAddClone => 'Klon hinzufügen';

  @override
  String get appSheetAddAnother => 'Weiteren hinzufügen';

  @override
  String get appSheetShareApp => 'App teilen';

  @override
  String get appSheetAppDetails => 'App-Details';

  @override
  String get appDetailsTitle => 'App-Details';

  @override
  String get appDetailsAdvanced => 'Erweiterte Details';

  @override
  String get appDetailsPackageName => 'Paketname';

  @override
  String get appDetailsVersion => 'Version';

  @override
  String get appDetailsArchitecture => 'Architektur';

  @override
  String get appDetailsBitness => 'Bit-Breite';

  @override
  String get appDetailsPackageType => 'Pakettyp';

  @override
  String get appDetailsApkComponents => 'APK-Komponenten';

  @override
  String get appDetailsTotalApkSize => 'Gesamtgröße der APK';

  @override
  String get appDetailsSigningSha256 => 'SHA-256 des Signaturzertifikats';

  @override
  String get appDetailsSigningUnreadable => 'nicht lesbar';

  @override
  String get appDetailsNoApkFiles =>
      'Der Paketmanager hat für diese App keine APK-Dateien gemeldet.';

  @override
  String get compatibilityNotAnalysed => 'Nicht analysiert';

  @override
  String get compatibilitySupported => 'Unterstützt';

  @override
  String get compatibilityLimited => 'Eingeschränkt';

  @override
  String get compatibilityUnsupported => 'Nicht unterstützt';

  @override
  String get compatibilityUnexaminedMessage =>
      'Diese App konnte nicht geprüft werden, daher ist nicht bekannt, wie gut sie laufen wird. Sie kann beim Erstellen des Klons trotzdem abgelehnt werden.';

  @override
  String get compatibilityNoProblems =>
      'Keine bekannten Kompatibilitätsprobleme.';

  @override
  String compatibilityExistingClones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Du hast bereits $count Klone dieser App. Der neue startet leer mit eigenen Daten.',
      one:
          'Du hast bereits 1 Klon dieser App. Der neue startet leer mit eigenen Daten.',
    );
    return '$_temp0';
  }

  @override
  String get compatibilityAddClone => 'Klon hinzufügen';

  @override
  String get compatibilityCannotClone => 'Nicht klonbar';

  @override
  String get findingAppNotFound =>
      'Diese Anwendung ist auf dem Gerät nicht installiert.';

  @override
  String get findingSecureEnvRequired =>
      'Diese Anwendung erfordert eine sichere Umgebung und kann nicht virtualisiert werden.';

  @override
  String findingSelfClone(String appName) {
    return '$appName kann sich nicht selbst klonen.';
  }

  @override
  String get findingSystemComponent =>
      'Systemkomponenten können nicht geklont werden.';

  @override
  String get findingAbiNotSupported =>
      'Die nativen Bibliotheken dieser App sind nicht für eine von der Engine unterstützte Architektur gebaut.';

  @override
  String get findingRequiresGms =>
      'Google Play-Dienste sind innerhalb eines Klons verfügbar, aber Google-Funktionen, die die eigene Identität dieser App prüfen müssen, werden nicht unterstützt — darunter die Anmeldung und identitätsgebundene APIs wie Standort- und SMS-Verifizierung.';

  @override
  String findingPushUnsupported(String appName) {
    return 'Push-Benachrichtigungen funktionieren in einem Klon nicht. Die Google Play-Dienste registrieren diese App nicht für Push, solange sie unter der Identität von $appName läuft, deshalb kommen an den Klon gesendete Nachrichten nie an. Ansonsten ist die App nutzbar, aber rechne beim ersten Start mit einer Pause, während sie auf eine Push-Registrierung wartet, die nicht gelingen kann.';
  }

  @override
  String findingStorageUnavailable(String appName) {
    return 'Diese App nutzt den gemeinsamen Speicher, und dieser Build von $appName deklariert keinen Zugriff auf alle Dateien. Ein Klon davon kommt nicht an deine Dateien und wird nicht funktionieren.';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return 'Diese App nutzt den gemeinsamen Speicher. Gib $appName in Einstellungen → Spezieller App-Zugriff den „Zugriff auf alle Dateien“, bevor du den Klon startest, sonst wird er beim Start möglicherweise abgelehnt.';
  }

  @override
  String get factsNoNativeCode => 'Kein nativer Code';

  @override
  String get factsAnyNoNativeCode => 'Beliebig — kein nativer Code';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => 'Einzelne APK';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Split-APK · $count Dateien',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => 'unbekannt';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => 'Über die Dateiverwaltung importieren';

  @override
  String get commonSave => 'Speichern';

  @override
  String get renameTitle => 'Profil umbenennen';

  @override
  String get renameFieldLabel => 'Profilname';

  @override
  String get uninstallTitle => 'Diesen Klon deinstallieren?';

  @override
  String uninstallSpaceOf(int index, int count) {
    return 'Bereich $index von $count';
  }

  @override
  String get uninstallMessage =>
      'Dadurch werden die ausgewählte App-Instanz und ihre lokalen Daten entfernt.';

  @override
  String get uninstallConfirm => 'Deinstallieren';

  @override
  String get calculatorError => 'Fehler';

  @override
  String get disclosureTitle => 'Bevor du loslegst';

  @override
  String disclosureIntro(String appName) {
    return '$appName führt eine zweite Kopie der Apps aus, die du wählst. Hier steht genau, was gelesen wird und wonach gefragt wird.';
  }

  @override
  String get disclosureAppsTitle => 'Deine installierten Apps';

  @override
  String disclosureAppsBody(String appName) {
    return 'Um die Klon-Auswahl zu zeigen, liest $appName die Liste der auf diesem Gerät installierten Apps — ihre Namen, Symbole und Versionen. Diese Liste bleibt auf deinem Gerät. Sie wird nie hochgeladen, verkauft oder weitergegeben, und die App enthält keine Werbung, keine Analyse und keinen Tracker.';
  }

  @override
  String get disclosurePermissionsTitle => 'Berechtigungen im Namen der Klone';

  @override
  String disclosurePermissionsBody(String appName) {
    return 'Geklonte Apps laufen innerhalb von $appName, deshalb gelten manche Android-Berechtigungen stellvertretend für sie. Du wirst eventuell einmal gebeten, die App von der Akku-Optimierung auszunehmen, damit geklonte Messenger weiter zustellen. Nur wenn du eine Datei- oder Medien-App klonst, musst du in den Einstellungen möglicherweise den Zugriff auf alle Dateien erteilen.';
  }

  @override
  String get disclosureControlTitle => 'Du behältst die Kontrolle';

  @override
  String get disclosureControlBody =>
      'Nichts wird still angefordert. Du kannst jede dieser Anfragen ablehnen und die App trotzdem nutzen, und du kannst es jederzeit in den Android-Einstellungen ändern.';

  @override
  String get disclosureAccept => 'Zustimmen und fortfahren';

  @override
  String get privateSpaceTitle => 'Privater Bereich';

  @override
  String get privateSpaceOffTitle => 'Der private Bereich ist aus';

  @override
  String get privateSpaceOffMessage =>
      'Schalte ihn ein, um Klone hinter einer PIN zu verbergen. Ausgeblendete Apps verschwinden aus dem Hauptraster und öffnen sich nur hier.';

  @override
  String get privateSpaceSetUp => 'Privaten Bereich einrichten';

  @override
  String get privateSpaceChangePin => 'PIN ändern';

  @override
  String get privateSpaceUnlockSection => 'Entsperren';

  @override
  String get privateSpaceFingerprint => 'Mit Fingerabdruck entsperren';

  @override
  String get privateSpaceFingerprintAvailable =>
      'Du kannst jederzeit weiterhin deine PIN nutzen.';

  @override
  String get privateSpaceFingerprintUnavailable =>
      'Auf diesem Gerät ist kein Fingerabdruck und kein Gesicht eingerichtet.';

  @override
  String get privateSpaceDisguiseSection => 'Tarnung';

  @override
  String get privateSpaceDisguiseAsCalculator => 'Als Rechner tarnen';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return 'Ersetzt das Symbol von $appName durch einen Rechner. Gib die PIN deines privaten Bereichs ein und drücke =, um die App zu öffnen.';
  }

  @override
  String get privateSpaceTurnOff => 'Privaten Bereich ausschalten';

  @override
  String get privateSpaceTurnOffNote =>
      'Beim Ausschalten kehrt jede ausgeblendete App ins Hauptraster zurück. Die Klone selbst werden nicht gelöscht.';

  @override
  String get privateSpaceDisguiseOnTitle => 'Als Rechner tarnen?';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return '$appName wieder anzeigen?';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return 'Das Symbol von $appName wird durch einen Rechner namens „Calculator“ ersetzt. Um $appName zu öffnen, gib die PIN deines privaten Bereichs ein und drücke =. Wenn du die PIN vergisst, kannst du die App nicht mehr öffnen.';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName zeigt wieder das eigene Symbol und den eigenen Namen auf dem Startbildschirm.';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => 'Tarnen';

  @override
  String get privateSpaceDisguiseConfirmOff => 'App anzeigen';

  @override
  String get privateSpaceDisguiseFailed =>
      'Das Erscheinungsbild der App konnte nicht geändert werden.';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '$appName sieht auf deinem Startbildschirm jetzt wie ein Rechner aus.';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName ist wieder auf deinem Startbildschirm.';
  }

  @override
  String get privateSpaceTurnOffTitle => 'Privaten Bereich ausschalten?';

  @override
  String get privateSpaceTurnOffMessage =>
      'Jede ausgeblendete App kehrt ins Hauptraster zurück und die PIN wird vergessen. Die Klone bleiben erhalten.';

  @override
  String get privateSpaceTurnOffConfirm => 'Ausschalten';

  @override
  String get privateSpaceTurnedOff => 'Privater Bereich ausgeschaltet.';

  @override
  String get pinCreateTitle => 'PIN erstellen';

  @override
  String get pinChangeTitle => 'PIN ändern';

  @override
  String get pinCreateMessage =>
      'Diese PIN sperrt den privaten Bereich. Bewahre sie so auf, dass du sie nicht vergisst: ohne sie lässt sich ein ausgeblendeter Klon nicht wiederherstellen.';

  @override
  String get pinChangeMessage =>
      'Gib deine aktuelle PIN ein und wähle dann eine neue.';

  @override
  String get pinCurrentLabel => 'Aktuelle PIN';

  @override
  String get pinNewLabel => 'Neue PIN';

  @override
  String get pinConfirmLabel => 'PIN bestätigen';

  @override
  String get pinCreateConfirm => 'Privaten Bereich erstellen';

  @override
  String get pinSaveConfirm => 'PIN speichern';

  @override
  String pinLengthError(int minimum, int maximum) {
    return 'Verwende $minimum bis $maximum Ziffern.';
  }

  @override
  String get pinMismatchError => 'Die beiden PINs stimmen nicht überein.';

  @override
  String get pinCurrentIncorrect => 'Die aktuelle PIN ist falsch.';

  @override
  String get unlockTitle => 'Privaten Bereich entsperren';

  @override
  String get unlockPinLabel => 'PIN';

  @override
  String get unlockUseFingerprint => 'Fingerabdruck verwenden';

  @override
  String get unlockConfirm => 'Entsperren';

  @override
  String get unlockIncorrectPin => 'Falsche PIN';

  @override
  String get unlockFingerprintUnavailable =>
      'Das Entsperren per Fingerabdruck ist gerade nicht verfügbar.';

  @override
  String get unlockFingerprintNotRecognised => 'Fingerabdruck nicht erkannt.';

  @override
  String get unlockBiometricReason => 'Entsperre deinen privaten Bereich';

  @override
  String get privateTileEmpty => 'Privater Bereich, leer';

  @override
  String privateTileHidden(int count) {
    return 'Privater Bereich, $count ausgeblendet';
  }

  @override
  String get settingsSectionPrivacy => 'Datenschutz';

  @override
  String get settingsPrivateSpaceSubtitle => 'Apps hinter einer PIN verbergen';

  @override
  String get settingsOn => 'An';

  @override
  String get settingsOff => 'Aus';

  @override
  String get componentBaseApk => 'Basis-APK';

  @override
  String get componentSplitApk => 'Split-APK';

  @override
  String get componentNoNativeLibraries => 'Keine nativen Bibliotheken';
}
