// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian (`no`).
class AppLocalizationsNo extends AppLocalizations {
  AppLocalizationsNo([String locale = 'no']) : super(locale);

  @override
  String get settingsTitle => 'Innstillinger';

  @override
  String get settingsSectionSupport => 'Kundestøtte';

  @override
  String get settingsSectionLegal => 'Juridisk';

  @override
  String get settingsSectionAbout => 'Om';

  @override
  String get settingsLanguage => 'Språk';

  @override
  String get settingsAppearance => 'Utseende';

  @override
  String get settingsContact => 'Kontakt oss';

  @override
  String get settingsContactSubtitle => 'Spørsmål eller tilbakemelding';

  @override
  String get settingsRate => 'Vurder oss';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Liker du $appName? Legg igjen en vurdering';
  }

  @override
  String get settingsPrivacyPolicy => 'Personvernerklæring';

  @override
  String get settingsTermsOfService => 'Vilkår for bruk';

  @override
  String get settingsVersion => 'Versjon';

  @override
  String get settingsArchitecture => 'Enhetsarkitektur';

  @override
  String get settingsArchitectureSubtitle => 'Appkompatibilitet';

  @override
  String get settingsBits64 => '64-bit';

  @override
  String get settingsBits32 => '32-bit';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'Støttede ABI-er';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Ikke publisert ennå';

  @override
  String get settingsNotListedYet => 'Ikke i butikken ennå';

  @override
  String get settingsNotSetUpYet => 'Ikke satt opp ennå';

  @override
  String get commonUnavailable => 'utilgjengelig';

  @override
  String get appearanceTitle => 'Utseende';

  @override
  String get appearancePreview => 'Forhåndsvisning';

  @override
  String get appearanceChooseTheme => 'Velg et tema';

  @override
  String get appearanceSystem => 'Systemstandard';

  @override
  String get appearanceSystemSubtitle => 'Følg enhetens innstillinger';

  @override
  String get appearanceLight => 'Lyst';

  @override
  String get appearanceLightSubtitle => 'Bruk alltid lyst tema';

  @override
  String get appearanceDark => 'Mørkt';

  @override
  String get appearanceDarkSubtitle => 'Bruk alltid mørkt tema';

  @override
  String appearanceInstantNote(String appName) {
    return 'Temaendringer gjelder umiddelbart i hele $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Forhåndsvisning av $theme tema';
  }

  @override
  String get languageTitle => 'Språk';

  @override
  String get languageSearchHint => 'Søk i språk';

  @override
  String get languageClearSearch => 'Tøm søket';

  @override
  String languageNote(String appName) {
    return 'Velg språket som brukes i $appName.';
  }

  @override
  String get languageSectionHeader => 'Språk';

  @override
  String get languageSystem => 'Systemstandard';

  @override
  String get languageSystemSubtitle => 'Bruk enhetens språk';

  @override
  String get languageInstantNote => 'Språkendringer gjelder umiddelbart.';

  @override
  String languageNoMatches(String query) {
    return 'Ingen språk samsvarer med «$query».';
  }

  @override
  String get contactTitle => 'Kontakt oss';

  @override
  String get contactHeroTitle => 'Hvordan kan vi hjelpe?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Velg hvordan du vil kontakte $appName-teamet.';
  }

  @override
  String get contactSectionOptions => 'Kontaktalternativer';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Chat med kundestøtten vår';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Send oss melding på Telegram';

  @override
  String get contactEmail => 'E-post';

  @override
  String get contactEmailSubtitle => 'Send oss en e-post';

  @override
  String get contactResponseTime => 'Svartid';

  @override
  String get contactResponseTimeValue =>
      'Vi svarer vanligvis innen 1–2 virkedager.';

  @override
  String get contactPrivacyNote =>
      'Vi bruker meldingen din bare til å gi kundestøtte.';

  @override
  String contactNoMailApp(String email) {
    return 'Ingen e-postapp kunne åpnes. Skriv til $email i stedet.';
  }

  @override
  String get contactWhatsAppFailed => 'WhatsApp kunne ikke åpnes.';

  @override
  String get contactTelegramFailed => 'Telegram kunne ikke åpnes.';

  @override
  String get contactPlayStoreFailed => 'Play Store kunne ikke åpnes.';

  @override
  String contactLegalOpenFailed(String document) {
    return '$document kunne ikke åpnes.';
  }

  @override
  String get commonCancel => 'Avbryt';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNotNow => 'Ikke nå';

  @override
  String get commonClose => 'Lukk';

  @override
  String get commonMore => 'Mer';

  @override
  String get commonFailureTitle => 'Det gikk ikke';

  @override
  String get homePrivateSpaceTitle => 'Privat rom';

  @override
  String get homeSubtitle => 'Ditt private rom';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skjulte apper',
      one: '1 skjult app',
      zero: 'Ingen skjulte apper',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => 'Lås og lukk';

  @override
  String get homeMenuSettings => 'Innstillinger';

  @override
  String get homeMenuDeveloperTools => 'Utviklerverktøy';

  @override
  String get homeAddApp => 'Legg til app';

  @override
  String get homeEmptyTitle => 'Rommet ditt er tomt';

  @override
  String get homeEmptyMessage =>
      'Legg til en app for å lage din første private instans.';

  @override
  String get homeEmptyAction => 'Legg til din første app';

  @override
  String get homePrivateEmptyTitle => 'Ingenting skjult ennå';

  @override
  String get homePrivateEmptyMessage =>
      'Hold inne en app i hovedrutenettet og velg Skjul for å flytte den hit.';

  @override
  String get homeSetUpPrivateSpaceTitle => 'Sette opp privat rom?';

  @override
  String get homeSetUpPrivateSpaceMessage =>
      'Å skjule en klone krever et privat rom. Lag ett med en PIN-kode først.';

  @override
  String get homeSetUpPrivateSpaceConfirm => 'Sett opp';

  @override
  String get homeEngineInactive =>
      'Virtualiseringsmotoren er ikke aktiv på denne enheten, så kloner kan ikke kjøre i isolerte containere.';

  @override
  String get homeEngineUnavailable =>
      'Virtualiseringsmotoren er ikke tilgjengelig på denne enheten.';

  @override
  String cloneSpaceLabel(int index) {
    return 'Rom $index';
  }

  @override
  String get cloneActionsManage => 'Administrer';

  @override
  String get cloneActionUninstall => 'Avinstaller';

  @override
  String get cloneActionClone => 'Klon';

  @override
  String get cloneActionShortcut => 'Snarvei';

  @override
  String get cloneActionSpaceInfo => 'Rominfo';

  @override
  String get cloneActionEditName => 'Endre navn';

  @override
  String get cloneActionChangeIcon => 'Endre ikon';

  @override
  String get cloneIconPickerChoose => 'Velg et bilde';

  @override
  String get cloneIconPickerUseAppIcon => 'Bruk appens ikon';

  @override
  String get errorCloneIconFailed =>
      'Det bildet kunne ikke brukes som ikon. Prøv et annet.';

  @override
  String get cloneIconPickerTitle => 'Ikonet til denne klonen';

  @override
  String get cloneIconPickerMessage =>
      'Gi den et bilde du velger selv, eller behold appens ikon og merk det med en farge — uansett kjenner du den igjen med én gang blant de andre klonene av samme app.';

  @override
  String get cloneActionForceStop => 'Tving stopp';

  @override
  String get cloneActionClearCache => 'Tøm buffer';

  @override
  String get cloneActionClearStorage => 'Slett data';

  @override
  String get cloneActionHide => 'Skjul';

  @override
  String get cloneActionUnhide => 'Vis';

  @override
  String get cloneActionShareApp => 'Del app';

  @override
  String get cloneActionPermissions => 'Tillatelser';

  @override
  String get cloneActionInstallGoogleServices => 'Installer Google-tjenester';

  @override
  String cloneTileSibling(int index, int count) {
    return ', klone $index av $count';
  }

  @override
  String get cloneTileOpening => ', åpner';

  @override
  String get cloneTileRunning => ', kjører';

  @override
  String get cloneTileCannotLaunch => ', kan ikke startes på denne enheten';

  @override
  String get cloneForceStopTitle => 'Tvinge stopp av denne appen?';

  @override
  String get cloneForceStopMessage =>
      'Appen slutter å kjøre til du åpner den igjen.';

  @override
  String get cloneForceStopConfirm => 'Tving stopp';

  @override
  String get cloneClearCacheTitle => 'Tømme appbufferen?';

  @override
  String get cloneClearCacheMessage =>
      'Dette fjerner midlertidige filer for denne klonen.';

  @override
  String get cloneClearCacheConfirm => 'Tøm buffer';

  @override
  String get cloneClearStorageTitle => 'Slette appdataene?';

  @override
  String get cloneClearStorageMessage =>
      'Dette sletter permanent kontoene, innstillingene og de lokale dataene til denne klonen.';

  @override
  String get cloneClearStorageConfirm => 'Slett data';

  @override
  String get cloneInstallGoogleServicesTitle => 'Installere Google-tjenester?';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName installerer Google Play-tjenester i denne klonen. Klonen beholder dataene sine. Det kan ta noen sekunder.';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => 'Installer';

  @override
  String cloneStopped(String name) {
    return '$name stoppet.';
  }

  @override
  String cloneCacheCleared(String name) {
    return 'Buffer tømt for $name.';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name ble tilbakestilt. Neste oppstart blir en førstegangs oppstart.';
  }

  @override
  String cloneHidden(String name) {
    return '$name er skjult i det private rommet.';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name er tilbake i hovedrutenettet.';
  }

  @override
  String get cloneShortcutAdded =>
      'Bekreft snarveien på startskjermen for å fullføre.';

  @override
  String get cloneGoogleServicesInstalling => 'Installerer Google-tjenester…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return 'Google-tjenester installert i $name.';
  }

  @override
  String get cloneCountTitle => 'Klon app';

  @override
  String cloneCountMessage(String appName) {
    return 'Lag flere kopier av $appName.';
  }

  @override
  String get cloneCountLabel => 'Antall kloner';

  @override
  String get cloneCountDecrease => 'Én mindre';

  @override
  String get cloneCountIncrease => 'Én til';

  @override
  String get cloneCountConfirm => 'Klon';

  @override
  String cloneCreating(int created, int total) {
    return 'Lager $created av $total…';
  }

  @override
  String get cloneCreatingFinishing => 'Fullfører…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'La til $count kopier til av $appName.',
      one: 'La til enda en kopi av $appName.',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return 'Laget $created av $total. $failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return 'Velg fra 1 til $maximum';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return 'Bare $free er ledig, og enheten holder av en halv gigabyte.';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return 'Opptil $maximum — $free plass igjen';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return 'Opptil $maximum om gangen på en enhet med $memory minne';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return 'Det er ikke plass til enda en klone av $appName. $reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return 'Ikke nok plass til $count kloner til av $appName. $reason.';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return 'Tillatelser · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => 'Kunne ikke lese tillatelsene';

  @override
  String get clonePermissionsEmptyTitle => 'Ingenting å begrense';

  @override
  String get clonePermissionsEmptyMessage =>
      'Denne appen oppgir ingen farlige tillatelser, så det er ingenting å tillate eller nekte for denne klonen.';

  @override
  String clonePermissionsNote(String appName) {
    return 'Dette gjelder bare denne klonen. En klonet app spør vanligvis før den bruker en tillatelse, og det er her det svaret begrenses — en app som hopper over spørsmålet kan fortsatt nå maskinvaren via $appName sin egen tillatelse.';
  }

  @override
  String get spaceInfoTitle => 'Rominfo';

  @override
  String get spaceInfoIdentifiers => 'Enhetsidentifikatorer';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => 'Motor utilgjengelig';

  @override
  String get spaceInfoStateRunning => 'Kjører';

  @override
  String get spaceInfoStateActive => 'Aktiv';

  @override
  String get spaceInfoStateRebuilds => 'Bygges opp ved oppstart';

  @override
  String get spaceInfoNoContainer =>
      'Dette rommet har ingen container ennå, så det har ingen identifikatorer. Åpne det én gang, så dukker de opp her.';

  @override
  String get spaceInfoDeviceId => 'Enhets-ID';

  @override
  String get spaceInfoAndroidId => 'Android-ID';

  @override
  String get spaceInfoSerialNumber => 'Serienummer';

  @override
  String get spaceInfoWifiMac => 'Wi-Fi-MAC';

  @override
  String get spaceInfoBluetoothMac => 'Bluetooth-MAC';

  @override
  String spaceInfoCopy(String label) {
    return 'Kopier $label';
  }

  @override
  String spaceInfoCopied(String label) {
    return '$label kopiert.';
  }

  @override
  String get commonBack => 'Tilbake';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonApply => 'Bruk';

  @override
  String get pickerTitle => 'Legg til app';

  @override
  String get pickerSearchHint => 'Søk i apper';

  @override
  String get pickerFilterTooltip => 'Filtrer og sorter';

  @override
  String get pickerErrorTitle => 'Kunne ikke liste appene';

  @override
  String get pickerNoMatchesTitle => 'Ingen apper samsvarer';

  @override
  String get pickerNoMatchesMessage =>
      'Prøv et annet søk, eller importer en APK i stedet.';

  @override
  String get pickerPopular => 'Populære';

  @override
  String get pickerQuickPicks => 'Hurtigvalg';

  @override
  String get pickerInstalledApps => 'Installerte apper';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apper',
      one: '1 app',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => 'System';

  @override
  String get pickerCannotClone =>
      'Denne appen kan ikke klones på denne enheten.';

  @override
  String get pickerApkUnreadable => 'Den valgte APK-filen kunne ikke leses.';

  @override
  String pickerHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count apper på denne enheten kan ikke klones og vises ikke i listen',
      one: '1 app på denne enheten kan ikke klones og vises ikke i listen',
    );
    return '$_temp0';
  }

  @override
  String get filterTitle => 'Filtrer og sorter';

  @override
  String get filterSort => 'Sorter';

  @override
  String get filterSortName => 'Appnavn';

  @override
  String get filterSortRecentlyInstalled => 'Nylig installert';

  @override
  String get filterSortRecentlyUpdated => 'Nylig oppdatert';

  @override
  String get filterFilter => 'Filtrer';

  @override
  String get filterAllApps => 'Alle apper';

  @override
  String get filterUserApps => 'Brukerapper';

  @override
  String get filterSystemApps => 'Systemapper';

  @override
  String get filterNotAdded => 'Ikke lagt til';

  @override
  String get filterAlreadyAdded => 'Allerede lagt til';

  @override
  String get filterArchitecture => 'Arkitektur';

  @override
  String get filterArch64 => '64-bit';

  @override
  String get filterArch32 => '32-bit';

  @override
  String get filterArchNoNativeCode => 'Ingen nativ kode';

  @override
  String get filterPackageType => 'Pakketype';

  @override
  String get filterPackageSingle => 'Enkelt APK';

  @override
  String get filterPackageSplit => 'Delt APK';

  @override
  String filterImportApk(String appName) {
    return 'Åpne $appName-apppakke';
  }

  @override
  String get appSheetAddClone => 'Legg til klone';

  @override
  String get appSheetAddAnother => 'Legg til enda en';

  @override
  String get appSheetShareApp => 'Del app';

  @override
  String get appSheetAppDetails => 'Appdetaljer';

  @override
  String get appDetailsTitle => 'Appdetaljer';

  @override
  String get appDetailsAdvanced => 'Avanserte detaljer';

  @override
  String get appDetailsPackageName => 'Pakkenavn';

  @override
  String get appDetailsVersion => 'Versjon';

  @override
  String get appDetailsArchitecture => 'Arkitektur';

  @override
  String get appDetailsBitness => 'Bitbredde';

  @override
  String get appDetailsPackageType => 'Pakketype';

  @override
  String get appDetailsApkComponents => 'APK-komponenter';

  @override
  String get appDetailsTotalApkSize => 'Total APK-størrelse';

  @override
  String get appDetailsSigningSha256 => 'SHA-256 for signeringssertifikatet';

  @override
  String get appDetailsSigningUnreadable => 'kunne ikke leses';

  @override
  String get appDetailsNoApkFiles =>
      'Pakkebehandleren rapporterte ingen APK-filer for denne appen.';

  @override
  String get findingAppNotFound =>
      'Denne applikasjonen er ikke installert på enheten.';

  @override
  String get findingSecureEnvRequired =>
      'Denne applikasjonen krever et sikkert miljø og kan ikke virtualiseres.';

  @override
  String findingSelfClone(String appName) {
    return '$appName kan ikke klone seg selv.';
  }

  @override
  String get findingSystemComponent => 'Systemkomponenter kan ikke klones.';

  @override
  String get findingAbiNotSupported =>
      'De native bibliotekene i denne appen er ikke bygget for en arkitektur motoren støtter.';

  @override
  String get findingAppArchiveUnavailable =>
      'This app\'s installation files are not on the device. It has been archived, or its installation is incomplete.';

  @override
  String findingStorageUnavailable(String appName) {
    return 'Denne appen bruker delt lagring, og denne versjonen av $appName oppgir ikke tilgang til alle filer. En klone av den når ikke filene dine og vil ikke virke.';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return 'Denne appen bruker delt lagring. Gi $appName «tilgang til alle filer» i Innstillinger → Spesiell apptilgang før du starter klonen, ellers kan den bli avvist ved oppstart.';
  }

  @override
  String get factsNoNativeCode => 'Ingen nativ kode';

  @override
  String get factsAnyNoNativeCode => 'Alle — ingen nativ kode';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => 'Enkelt APK';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delt APK · $count filer',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => 'ukjent';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => 'Importer via filbehandleren';

  @override
  String get commonSave => 'Lagre';

  @override
  String get renameTitle => 'Gi profilen nytt navn';

  @override
  String get renameFieldLabel => 'Profilnavn';

  @override
  String get uninstallTitle => 'Avinstallere denne klonen?';

  @override
  String uninstallSpaceOf(int index, int count) {
    return 'Rom $index av $count';
  }

  @override
  String get uninstallMessage =>
      'Dette fjerner den valgte appinstansen og dens lokale data.';

  @override
  String get uninstallConfirm => 'Avinstaller';

  @override
  String get calculatorError => 'Feil';

  @override
  String get disclosureTitle => 'Før du begynner';

  @override
  String disclosureIntro(String appName) {
    return '$appName kjører en ekstra kopi av appene du velger. Her står nøyaktig hva den leser og hva den vil be deg om.';
  }

  @override
  String get disclosureAppsTitle => 'De installerte appene dine';

  @override
  String disclosureAppsBody(String appName) {
    return 'For å vise klonevelgeren leser $appName listen over apper som er installert på denne enheten — navn, ikoner og versjoner. Denne listen blir på enheten din. Den lastes aldri opp, selges eller deles, og appen inneholder ingen annonser, ingen analyse og ingen sporing.';
  }

  @override
  String get disclosurePermissionsTitle => 'Tillatelser på vegne av kloner';

  @override
  String disclosurePermissionsBody(String appName) {
    return 'Klonede apper kjører inne i $appName, så noen Android-tillatelser gjelder den på deres vegne. Du kan bli bedt én gang om å unnta den fra batterioptimalisering, slik at klonede meldingsapper fortsetter å levere. Bare når du kloner en fil- eller medieapp kan du måtte gi tilgang til alle filer i Innstillinger.';
  }

  @override
  String get disclosureControlTitle => 'Du har kontrollen';

  @override
  String get disclosureControlBody =>
      'Ingenting blir bedt om i det stille. Du kan avslå alle disse forespørslene og fortsatt bruke appen, og du kan ombestemme deg i Android-innstillingene når som helst.';

  @override
  String get disclosureAccept => 'Godta og fortsett';

  @override
  String get privateSpaceTitle => 'Privat rom';

  @override
  String get privateSpaceOffTitle => 'Privat rom er av';

  @override
  String get privateSpaceOffMessage =>
      'Slå det på for å skjule kloner bak en PIN-kode. Skjulte apper forsvinner fra hovedrutenettet og åpnes bare her.';

  @override
  String get privateSpaceSetUp => 'Sett opp privat rom';

  @override
  String get privateSpaceChangePin => 'Endre PIN-kode';

  @override
  String get privateSpaceUnlockSection => 'Opplåsing';

  @override
  String get privateSpaceFingerprint => 'Lås opp med fingeravtrykk';

  @override
  String get privateSpaceFingerprintAvailable =>
      'Du kan fortsatt bruke PIN-koden din når som helst.';

  @override
  String get privateSpaceFingerprintUnavailable =>
      'Det er ikke satt opp fingeravtrykk eller ansikt på denne enheten.';

  @override
  String get privateSpaceDisguiseSection => 'Forkledning';

  @override
  String get privateSpaceDisguiseAsCalculator => 'Forkle som kalkulator';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return 'Erstatter ikonet til $appName med en kalkulator. Skriv PIN-koden til det private rommet og trykk = for å åpne appen.';
  }

  @override
  String get privateSpaceTurnOff => 'Slå av privat rom';

  @override
  String get privateSpaceTurnOffNote =>
      'Slår du det av, kommer alle skjulte apper tilbake til hovedrutenettet. Klonene slettes ikke.';

  @override
  String get privateSpaceDisguiseOnTitle => 'Forkle som kalkulator?';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return 'Vise $appName igjen?';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return 'Ikonet til $appName erstattes av en kalkulator som heter «Calculator». For å åpne $appName, skriv PIN-koden til det private rommet og trykk =. Glemmer du PIN-koden, får du ikke åpnet appen.';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName viser igjen sitt eget ikon og navn på startskjermen.';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => 'Forkle';

  @override
  String get privateSpaceDisguiseConfirmOff => 'Vis app';

  @override
  String get privateSpaceDisguiseFailed =>
      'Kunne ikke endre hvordan appen ser ut.';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '$appName ser nå ut som en kalkulator på startskjermen din.';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName er tilbake på startskjermen din.';
  }

  @override
  String get privateSpaceTurnOffTitle => 'Slå av privat rom?';

  @override
  String get privateSpaceTurnOffMessage =>
      'Alle skjulte apper kommer tilbake til hovedrutenettet, og PIN-koden glemmes. Klonene beholdes.';

  @override
  String get privateSpaceTurnOffConfirm => 'Slå av';

  @override
  String get privateSpaceTurnedOff => 'Privat rom slått av.';

  @override
  String get pinCreateTitle => 'Lag PIN-kode';

  @override
  String get pinChangeTitle => 'Endre PIN-kode';

  @override
  String get pinCreateMessage =>
      'Denne PIN-koden låser det private rommet. Ta vare på den et sted du ikke glemmer: uten den finnes ingen måte å hente tilbake en skjult klone.';

  @override
  String get pinChangeMessage =>
      'Skriv inn nåværende PIN-kode, og velg så en ny.';

  @override
  String get pinCurrentLabel => 'Nåværende PIN-kode';

  @override
  String get pinNewLabel => 'Ny PIN-kode';

  @override
  String get pinConfirmLabel => 'Bekreft PIN-kode';

  @override
  String get pinCreateConfirm => 'Lag privat rom';

  @override
  String get pinSaveConfirm => 'Lagre PIN-kode';

  @override
  String pinLengthError(int minimum, int maximum) {
    return 'Bruk $minimum til $maximum sifre.';
  }

  @override
  String get pinMismatchError => 'De to PIN-kodene er ikke like.';

  @override
  String get pinCurrentIncorrect => 'Nåværende PIN-kode er feil.';

  @override
  String get unlockTitle => 'Lås opp privat rom';

  @override
  String get unlockPinLabel => 'PIN-kode';

  @override
  String get unlockUseFingerprint => 'Bruk fingeravtrykk';

  @override
  String get unlockConfirm => 'Lås opp';

  @override
  String get unlockIncorrectPin => 'Feil PIN-kode';

  @override
  String get unlockFingerprintUnavailable =>
      'Opplåsing med fingeravtrykk er ikke tilgjengelig akkurat nå.';

  @override
  String get unlockFingerprintNotRecognised => 'Fingeravtrykk ikke gjenkjent.';

  @override
  String get unlockBiometricReason => 'Lås opp det private rommet ditt';

  @override
  String get privateTileEmpty => 'Privat rom, tomt';

  @override
  String privateTileHidden(int count) {
    return 'Privat rom, $count skjult';
  }

  @override
  String get settingsSectionPrivacy => 'Personvern';

  @override
  String get settingsPrivateSpaceSubtitle => 'Skjul apper bak en PIN-kode';

  @override
  String get settingsOn => 'På';

  @override
  String get settingsOff => 'Av';

  @override
  String get componentBaseApk => 'Base-APK';

  @override
  String get componentSplitApk => 'Delt APK';

  @override
  String get componentNoNativeLibraries => 'Ingen native biblioteker';

  @override
  String get errorProfileNameEmpty => 'En klone trenger et navn.';

  @override
  String errorProfileNameTooLong(int maximum) {
    return 'Navnet på en klone kan være på høyst $maximum tegn.';
  }

  @override
  String get errorProfileStorageUnreadable =>
      'De lagrede klonene dine kunne ikke leses.';

  @override
  String get errorProfileNotFound => 'Den klonen finnes ikke lenger.';

  @override
  String get errorBridgeFailed =>
      'Noe gikk galt i kommunikasjonen med den delen av appen som styrer klonene.';

  @override
  String get errorBridgeUnsupportedPlatform =>
      'Denne funksjonen finnes bare på Android.';

  @override
  String get errorTestAppCheckFailed =>
      'Om testappen er installert, kunne ikke sjekkes.';

  @override
  String get errorEngineInitFailed =>
      'Virtualiseringsmotoren klarte ikke å starte på denne enheten.';

  @override
  String get errorEngineAndroidTooOld =>
      'Virtualiseringsmotoren krever en nyere versjon av Android.';

  @override
  String get errorEngineNoResponse =>
      'Virtualiseringsmotoren svarte ikke. Prøv igjen.';

  @override
  String get errorNoContainer =>
      'Denne klonen har ingen container ennå. Åpne den én gang og prøv igjen.';

  @override
  String get errorLaunchRefused => 'Motoren nektet å åpne denne klonen.';

  @override
  String get errorAlreadyCloned => 'Denne appen er allerede klonet.';

  @override
  String get errorClearCacheFailed =>
      'Deler av bufferen til denne klonen kunne ikke slettes.';

  @override
  String get errorClearDataFailed =>
      'Dataene til denne klonen kunne ikke slettes.';

  @override
  String get errorShortcutsUnsupported =>
      'Denne launcheren støtter ikke snarveier.';

  @override
  String get errorShortcutRefused => 'Launcheren avviste snarveien.';

  @override
  String get errorApkGone =>
      'APK-en til denne klonen er ikke på enheten lenger, så det er ingenting å dele.';

  @override
  String get errorShareFailed => 'Appen kunne ikke deles.';

  @override
  String get errorApkUnreadable => 'En av de valgte APK-ene kunne ikke leses.';

  @override
  String get errorApkPackageMismatch =>
      'Alle valgte APK-er må tilhøre samme app.';

  @override
  String get errorApkVersionMismatch =>
      'Alle valgte APK-er må ha samme versjon.';

  @override
  String get errorApkBaseRequired =>
      'Velg nøyaktig én base-APK og én eller flere konfigurasjonssplitter.';

  @override
  String get errorApkDuplicateSplit =>
      'Den samme APK-splitten ble valgt mer enn én gang.';
}
