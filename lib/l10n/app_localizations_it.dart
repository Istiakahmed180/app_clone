// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsSectionSupport => 'Assistenza';

  @override
  String get settingsSectionLegal => 'Note legali';

  @override
  String get settingsSectionAbout => 'Informazioni';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get settingsContact => 'Contattaci';

  @override
  String get settingsContactSubtitle => 'Domande o feedback';

  @override
  String get settingsRate => 'Valutaci';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Ti piace $appName? Lascia una recensione';
  }

  @override
  String get settingsPrivacyPolicy => 'Informativa sulla privacy';

  @override
  String get settingsTermsOfService => 'Termini di servizio';

  @override
  String get settingsVersion => 'Versione';

  @override
  String get settingsArchitecture => 'Architettura del dispositivo';

  @override
  String get settingsArchitectureSubtitle => 'Compatibilità delle app';

  @override
  String get settingsBits64 => '64 bit';

  @override
  String get settingsBits32 => '32 bit';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'ABI supportate';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Non ancora pubblicato';

  @override
  String get settingsNotListedYet => 'Non ancora sullo store';

  @override
  String get settingsNotSetUpYet => 'Non ancora configurato';

  @override
  String get commonUnavailable => 'non disponibile';

  @override
  String get appearanceTitle => 'Aspetto';

  @override
  String get appearancePreview => 'Anteprima';

  @override
  String get appearanceChooseTheme => 'Scegli un tema';

  @override
  String get appearanceSystem => 'Predefinito di sistema';

  @override
  String get appearanceSystemSubtitle =>
      'Segui le impostazioni del dispositivo';

  @override
  String get appearanceLight => 'Chiaro';

  @override
  String get appearanceLightSubtitle => 'Usa sempre il tema chiaro';

  @override
  String get appearanceDark => 'Scuro';

  @override
  String get appearanceDarkSubtitle => 'Usa sempre il tema scuro';

  @override
  String appearanceInstantNote(String appName) {
    return 'Le modifiche al tema si applicano subito in tutto $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Anteprima del tema $theme';
  }

  @override
  String get languageTitle => 'Lingua';

  @override
  String get languageSearchHint => 'Cerca lingue';

  @override
  String get languageClearSearch => 'Cancella la ricerca';

  @override
  String languageNote(String appName) {
    return 'Scegli la lingua usata in $appName.';
  }

  @override
  String get languageSectionHeader => 'Lingua';

  @override
  String get languageSystem => 'Predefinito di sistema';

  @override
  String get languageSystemSubtitle => 'Usa la lingua del dispositivo';

  @override
  String get languageInstantNote =>
      'Le modifiche alla lingua si applicano subito.';

  @override
  String languageNoMatches(String query) {
    return 'Nessuna lingua corrisponde a «$query».';
  }

  @override
  String get contactTitle => 'Contattaci';

  @override
  String get contactHeroTitle => 'Come possiamo aiutarti?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Scegli come preferisci contattare il team di $appName.';
  }

  @override
  String get contactSectionOptions => 'Opzioni di contatto';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle =>
      'Chatta con il nostro team di assistenza';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Scrivici su Telegram';

  @override
  String get contactEmail => 'Email';

  @override
  String get contactEmailSubtitle => 'Inviaci un\'email';

  @override
  String get contactResponseTime => 'Tempo di risposta';

  @override
  String get contactResponseTimeValue =>
      'Di solito rispondiamo entro 1–2 giorni lavorativi.';

  @override
  String get contactPrivacyNote =>
      'Useremo il tuo messaggio solo per fornirti assistenza.';

  @override
  String contactNoMailApp(String email) {
    return 'Non è stato possibile aprire un\'app di posta. Scrivi invece a $email.';
  }

  @override
  String get contactWhatsAppFailed => 'Non è stato possibile aprire WhatsApp.';

  @override
  String get contactTelegramFailed => 'Non è stato possibile aprire Telegram.';

  @override
  String get contactPlayStoreFailed =>
      'Non è stato possibile aprire il Play Store.';

  @override
  String contactLegalOpenFailed(String document) {
    return 'Non è stato possibile aprire $document.';
  }

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNotNow => 'Non ora';

  @override
  String get commonClose => 'Chiudi';

  @override
  String get commonMore => 'Altro';

  @override
  String get commonFailureTitle => 'Operazione non riuscita';

  @override
  String get homePrivateSpaceTitle => 'Spazio privato';

  @override
  String get homeSubtitle => 'Il tuo spazio privato';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count app nascoste',
      one: '1 app nascosta',
      zero: 'Nessuna app nascosta',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => 'Blocca e chiudi';

  @override
  String get homeMenuSettings => 'Impostazioni';

  @override
  String get homeMenuDeveloperTools => 'Strumenti per sviluppatori';

  @override
  String get homeAddApp => 'Aggiungi app';

  @override
  String get homeEmptyTitle => 'Il tuo spazio è vuoto';

  @override
  String get homeEmptyMessage =>
      'Aggiungi un\'app per creare la tua prima istanza privata.';

  @override
  String get homeEmptyAction => 'Aggiungi la tua prima app';

  @override
  String get homePrivateEmptyTitle => 'Ancora niente di nascosto';

  @override
  String get homePrivateEmptyMessage =>
      'Tieni premuta una qualsiasi app della griglia principale e scegli Nascondi per spostarla qui.';

  @override
  String get homeSetUpPrivateSpaceTitle => 'Configurare lo spazio privato?';

  @override
  String get homeSetUpPrivateSpaceMessage =>
      'Per nascondere un clone serve uno spazio privato. Creane uno con un PIN.';

  @override
  String get homeSetUpPrivateSpaceConfirm => 'Configura';

  @override
  String get homeEngineInactive =>
      'Il motore di virtualizzazione non è attivo su questo dispositivo, quindi i cloni non possono girare in container isolati.';

  @override
  String get homeEngineUnavailable =>
      'Il motore di virtualizzazione non è disponibile su questo dispositivo.';

  @override
  String cloneSpaceLabel(int index) {
    return 'Spazio $index';
  }

  @override
  String get cloneActionsCompatibility => 'Compatibilità';

  @override
  String get cloneActionsManage => 'Gestisci';

  @override
  String get cloneActionUninstall => 'Disinstalla';

  @override
  String get cloneActionClone => 'Clona';

  @override
  String get cloneActionShortcut => 'Scorciatoia';

  @override
  String get cloneActionSpaceInfo => 'Info spazio';

  @override
  String get cloneActionEditName => 'Modifica nome';

  @override
  String get cloneActionForceStop => 'Arresto forzato';

  @override
  String get cloneActionClearCache => 'Svuota cache';

  @override
  String get cloneActionClearStorage => 'Cancella dati';

  @override
  String get cloneActionHide => 'Nascondi';

  @override
  String get cloneActionUnhide => 'Mostra';

  @override
  String get cloneActionShareApp => 'Condividi app';

  @override
  String get cloneActionNotifications => 'Notifiche';

  @override
  String get cloneActionPermissions => 'Autorizzazioni';

  @override
  String get cloneActionGoogleServicesInstalled =>
      'Servizi Google (microG) installati';

  @override
  String get cloneActionInstallGoogleServices =>
      'Installa i servizi Google (microG)';

  @override
  String cloneTileSibling(int index, int count) {
    return ', clone $index di $count';
  }

  @override
  String get cloneTileOpening => ', in apertura';

  @override
  String get cloneTileRunning => ', in esecuzione';

  @override
  String get cloneTileCannotLaunch =>
      ', non può essere avviata su questo dispositivo';

  @override
  String get cloneForceStopTitle => 'Forzare l\'arresto di questa app?';

  @override
  String get cloneForceStopMessage =>
      'L\'app smetterà di funzionare finché non la riaprirai.';

  @override
  String get cloneForceStopConfirm => 'Arresto forzato';

  @override
  String get cloneClearCacheTitle => 'Svuotare la cache dell\'app?';

  @override
  String get cloneClearCacheMessage =>
      'Verranno rimossi i file temporanei di questo clone.';

  @override
  String get cloneClearCacheConfirm => 'Svuota cache';

  @override
  String get cloneClearStorageTitle => 'Cancellare i dati dell\'app?';

  @override
  String get cloneClearStorageMessage =>
      'Verranno eliminati definitivamente account, impostazioni e dati locali di questo clone.';

  @override
  String get cloneClearStorageConfirm => 'Cancella dati';

  @override
  String get cloneInstallGoogleServicesTitle => 'Installare i servizi Google?';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName installerà il microG incluso in questo clone come servizi Google Play. Il clone conserva i suoi dati. Può richiedere qualche secondo.';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => 'Installa';

  @override
  String cloneStopped(String name) {
    return '$name arrestata.';
  }

  @override
  String cloneCacheCleared(String name) {
    return 'Cache svuotata per $name.';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name è stata ripristinata. Il prossimo avvio sarà un primo avvio.';
  }

  @override
  String cloneHidden(String name) {
    return '$name nascosta nello spazio privato.';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name è di nuovo nella griglia principale.';
  }

  @override
  String get cloneShortcutAdded =>
      'Conferma la scorciatoia nella schermata Home per completare l\'aggiunta.';

  @override
  String get cloneGoogleServicesInstalling =>
      'Installazione dei servizi Google…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return 'Servizi Google installati in $name.';
  }

  @override
  String get cloneCountTitle => 'Clona app';

  @override
  String cloneCountMessage(String appName) {
    return 'Crea copie aggiuntive di $appName.';
  }

  @override
  String get cloneCountLabel => 'Numero di cloni';

  @override
  String get cloneCountDecrease => 'Uno in meno';

  @override
  String get cloneCountIncrease => 'Uno in più';

  @override
  String get cloneCountConfirm => 'Clona';

  @override
  String cloneCreating(int created, int total) {
    return 'Creazione di $created su $total…';
  }

  @override
  String get cloneCreatingFinishing => 'Completamento…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aggiunte altre $count copie di $appName.',
      one: 'Aggiunta un\'altra copia di $appName.',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return 'Creati $created su $total. $failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return 'Scegli da 1 a $maximum';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return 'Sono liberi solo $free e il dispositivo ne tiene mezzo gigabyte di riserva.';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return 'Fino a $maximum — restano $free di spazio';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return 'Fino a $maximum alla volta su un dispositivo con $memory di memoria';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return 'Non c\'è spazio per un altro clone di $appName. $reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return 'Spazio insufficiente per altri $count cloni di $appName. $reason.';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return 'Autorizzazioni · $appName';
  }

  @override
  String get clonePermissionsErrorTitle =>
      'Impossibile leggere le autorizzazioni';

  @override
  String get clonePermissionsEmptyTitle => 'Niente da limitare';

  @override
  String get clonePermissionsEmptyMessage =>
      'Questa app non dichiara autorizzazioni pericolose, quindi non c\'è nulla da consentire o negare per questo clone.';

  @override
  String clonePermissionsNote(String appName) {
    return 'Valgono solo per questo clone. Un\'app clonata di solito chiede prima di usare un\'autorizzazione, ed è qui che quella risposta viene limitata: un\'app che salta la richiesta può comunque raggiungere l\'hardware tramite l\'autorizzazione di $appName.';
  }

  @override
  String get spaceInfoTitle => 'Info spazio';

  @override
  String get spaceInfoIdentifiers => 'Identificatori del dispositivo';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => 'Motore non disponibile';

  @override
  String get spaceInfoStateRunning => 'In esecuzione';

  @override
  String get spaceInfoStateActive => 'Attivo';

  @override
  String get spaceInfoStateRebuilds => 'Ricostruito all\'avvio';

  @override
  String get spaceInfoNoContainer =>
      'Questo spazio non ha ancora un container, quindi non ha identificatori. Aprilo una volta e compariranno qui.';

  @override
  String get spaceInfoDeviceId => 'ID dispositivo';

  @override
  String get spaceInfoAndroidId => 'ID Android';

  @override
  String get spaceInfoSerialNumber => 'Numero di serie';

  @override
  String get spaceInfoWifiMac => 'MAC Wi-Fi';

  @override
  String get spaceInfoBluetoothMac => 'MAC Bluetooth';

  @override
  String spaceInfoCopy(String label) {
    return 'Copia $label';
  }

  @override
  String spaceInfoCopied(String label) {
    return '$label copiato.';
  }

  @override
  String get commonBack => 'Indietro';

  @override
  String get commonApply => 'Applica';

  @override
  String get pickerTitle => 'Aggiungi app';

  @override
  String get pickerSearchHint => 'Cerca app';

  @override
  String get pickerFilterTooltip => 'Filtra e ordina';

  @override
  String get pickerErrorTitle => 'Impossibile elencare le app';

  @override
  String get pickerNoMatchesTitle => 'Nessuna app corrispondente';

  @override
  String get pickerNoMatchesMessage =>
      'Prova un\'altra ricerca oppure importa un APK.';

  @override
  String get pickerPopular => 'Popolari';

  @override
  String get pickerQuickPicks => 'Scelte rapide';

  @override
  String get pickerInstalledApps => 'App installate';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count app',
      one: '1 app',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => 'Sistema';

  @override
  String get pickerCannotClone =>
      'Questa app non può essere clonata su questo dispositivo.';

  @override
  String get pickerApkUnreadable => 'Impossibile leggere l\'APK selezionato.';

  @override
  String get filterTitle => 'Filtra e ordina';

  @override
  String get filterSort => 'Ordina';

  @override
  String get filterSortName => 'Nome dell\'app';

  @override
  String get filterSortRecentlyInstalled => 'Installate di recente';

  @override
  String get filterSortRecentlyUpdated => 'Aggiornate di recente';

  @override
  String get filterFilter => 'Filtra';

  @override
  String get filterAllApps => 'Tutte le app';

  @override
  String get filterUserApps => 'App dell\'utente';

  @override
  String get filterSystemApps => 'App di sistema';

  @override
  String get filterNotAdded => 'Non aggiunte';

  @override
  String get filterAlreadyAdded => 'Già aggiunte';

  @override
  String get filterArchitecture => 'Architettura';

  @override
  String get filterArch64 => '64 bit';

  @override
  String get filterArch32 => '32 bit';

  @override
  String get filterArchNoNativeCode => 'Nessun codice nativo';

  @override
  String get filterPackageType => 'Tipo di pacchetto';

  @override
  String get filterPackageSingle => 'APK singolo';

  @override
  String get filterPackageSplit => 'APK suddiviso';

  @override
  String filterImportApk(String appName) {
    return 'Apri pacchetto app di $appName';
  }

  @override
  String get appSheetAddClone => 'Aggiungi clone';

  @override
  String get appSheetAddAnother => 'Aggiungine un altro';

  @override
  String get appSheetShareApp => 'Condividi app';

  @override
  String get appSheetAppDetails => 'Dettagli app';

  @override
  String get appDetailsTitle => 'Dettagli app';

  @override
  String get appDetailsAdvanced => 'Dettagli avanzati';

  @override
  String get appDetailsPackageName => 'Nome del pacchetto';

  @override
  String get appDetailsVersion => 'Versione';

  @override
  String get appDetailsArchitecture => 'Architettura';

  @override
  String get appDetailsBitness => 'Bit';

  @override
  String get appDetailsPackageType => 'Tipo di pacchetto';

  @override
  String get appDetailsApkComponents => 'Componenti APK';

  @override
  String get appDetailsTotalApkSize => 'Dimensione totale APK';

  @override
  String get appDetailsSigningSha256 => 'SHA-256 del certificato di firma';

  @override
  String get appDetailsSigningUnreadable => 'non leggibile';

  @override
  String get appDetailsNoApkFiles =>
      'Il gestore pacchetti non ha segnalato file APK per questa app.';

  @override
  String get compatibilityNotAnalysed => 'Non analizzata';

  @override
  String get compatibilitySupported => 'Supportata';

  @override
  String get compatibilityLimited => 'Limitata';

  @override
  String get compatibilityUnsupported => 'Non supportata';

  @override
  String get compatibilityUnexaminedMessage =>
      'Non è stato possibile esaminare questa app, quindi non si sa come funzionerà. Potrebbe comunque essere rifiutata alla creazione del clone.';

  @override
  String get compatibilityNoProblems =>
      'Nessun problema di compatibilità noto.';

  @override
  String compatibilityExistingClones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Hai già $count cloni di questa app. Quello nuovo parte vuoto con i propri dati.',
      one:
          'Hai già 1 clone di questa app. Quello nuovo parte vuoto con i propri dati.',
    );
    return '$_temp0';
  }

  @override
  String get compatibilityAddClone => 'Aggiungi clone';

  @override
  String get compatibilityCannotClone => 'Non clonabile';

  @override
  String get findingAppNotFound =>
      'Questa applicazione non è installata sul dispositivo.';

  @override
  String get findingSecureEnvRequired =>
      'Questa applicazione richiede un ambiente sicuro e non può essere virtualizzata.';

  @override
  String findingSelfClone(String appName) {
    return '$appName non può clonare se stessa.';
  }

  @override
  String get findingSystemComponent =>
      'I componenti di sistema non possono essere clonati.';

  @override
  String get findingAbiNotSupported =>
      'Le librerie native di questa app non sono compilate per un\'architettura supportata dal motore.';

  @override
  String get findingRequiresGms =>
      'I servizi Google Play sono disponibili dentro un clone, ma le funzioni Google che devono verificare l\'identità propria di questa app non sono supportate, incluso l\'accesso e le API legate all\'identità come la verifica per posizione e via SMS.';

  @override
  String findingPushUnsupported(String appName) {
    return 'Le notifiche push non funzioneranno in un clone. I servizi Google Play non registreranno questa app per il push mentre gira sotto l\'identità di $appName, quindi i messaggi inviati al clone non arrivano mai. Per il resto l\'app è utilizzabile, ma aspettati una pausa al primo avvio mentre attende una registrazione push che non può riuscire.';
  }

  @override
  String findingStorageUnavailable(String appName) {
    return 'Questa app usa l\'archiviazione condivisa e questa build di $appName non dichiara l\'accesso a tutti i file. Un suo clone non può raggiungere i tuoi file e non funzionerà.';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return 'Questa app usa l\'archiviazione condivisa. Concedi a $appName l\'“accesso a tutti i file” in Impostazioni → Accesso speciale alle app prima di avviare il clone, altrimenti potrebbe essere rifiutato all\'avvio.';
  }

  @override
  String get factsNoNativeCode => 'Nessun codice nativo';

  @override
  String get factsAnyNoNativeCode => 'Qualsiasi — nessun codice nativo';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => 'APK singolo';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'APK suddiviso · $count file',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => 'sconosciuta';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => 'Importa dal gestore file';

  @override
  String get commonSave => 'Salva';

  @override
  String get renameTitle => 'Rinomina profilo';

  @override
  String get renameFieldLabel => 'Nome del profilo';

  @override
  String get uninstallTitle => 'Disinstallare questo clone?';

  @override
  String uninstallSpaceOf(int index, int count) {
    return 'Spazio $index di $count';
  }

  @override
  String get uninstallMessage =>
      'Verranno rimossi l\'istanza dell\'app selezionata e i suoi dati locali.';

  @override
  String get uninstallConfirm => 'Disinstalla';

  @override
  String get calculatorError => 'Errore';

  @override
  String get disclosureTitle => 'Prima di iniziare';

  @override
  String disclosureIntro(String appName) {
    return '$appName esegue una seconda copia delle app che scegli. Ecco esattamente cosa legge e cosa ti chiederà.';
  }

  @override
  String get disclosureAppsTitle => 'Le tue app installate';

  @override
  String disclosureAppsBody(String appName) {
    return 'Per mostrare il selettore dei cloni, $appName legge l\'elenco delle app installate su questo dispositivo: nomi, icone e versioni. Questo elenco resta sul tuo dispositivo. Non viene mai caricato, venduto o condiviso, e l\'app non contiene pubblicità, analytics né tracker.';
  }

  @override
  String get disclosurePermissionsTitle => 'Autorizzazioni per conto dei cloni';

  @override
  String disclosurePermissionsBody(String appName) {
    return 'Le app clonate girano dentro $appName, quindi alcune autorizzazioni Android si applicano a essa per loro conto. Potrebbe esserti chiesto una volta di esentarla dall\'ottimizzazione della batteria, così le app di messaggistica clonate continuano a consegnare. Solo quando cloni un\'app di file o multimediale potresti dover concedere l\'accesso a tutti i file nelle Impostazioni.';
  }

  @override
  String get disclosureControlTitle => 'Il controllo resta tuo';

  @override
  String get disclosureControlBody =>
      'Nulla viene richiesto in silenzio. Puoi rifiutare qualsiasi di queste richieste e continuare a usare l\'app, e puoi cambiare idea nelle Impostazioni di Android in qualsiasi momento.';

  @override
  String get disclosureAccept => 'Accetta e continua';

  @override
  String get privateSpaceTitle => 'Spazio privato';

  @override
  String get privateSpaceOffTitle => 'Lo spazio privato è disattivato';

  @override
  String get privateSpaceOffMessage =>
      'Attivalo per nascondere i cloni dietro un PIN. Le app nascoste spariscono dalla griglia principale e si aprono solo qui.';

  @override
  String get privateSpaceSetUp => 'Configura lo spazio privato';

  @override
  String get privateSpaceChangePin => 'Cambia PIN';

  @override
  String get privateSpaceUnlockSection => 'Sblocco';

  @override
  String get privateSpaceFingerprint => 'Sblocca con l\'impronta';

  @override
  String get privateSpaceFingerprintAvailable =>
      'Puoi comunque usare il tuo PIN in qualsiasi momento.';

  @override
  String get privateSpaceFingerprintUnavailable =>
      'Su questo dispositivo non è configurata nessuna impronta né riconoscimento del volto.';

  @override
  String get privateSpaceDisguiseSection => 'Travestimento';

  @override
  String get privateSpaceDisguiseAsCalculator => 'Travesti da calcolatrice';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return 'Sostituisce l\'icona di $appName con una calcolatrice. Digita il PIN del tuo spazio privato e premi = per aprire l\'app.';
  }

  @override
  String get privateSpaceTurnOff => 'Disattiva lo spazio privato';

  @override
  String get privateSpaceTurnOffNote =>
      'Disattivandolo, ogni app nascosta torna nella griglia principale. I cloni stessi non vengono eliminati.';

  @override
  String get privateSpaceDisguiseOnTitle => 'Travestire da calcolatrice?';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return 'Mostrare di nuovo $appName?';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return 'L\'icona di $appName viene sostituita da una calcolatrice chiamata “Calculator”. Per aprire $appName, digita il PIN del tuo spazio privato e premi =. Se dimentichi il PIN non potrai aprire l\'app.';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName tornerà a mostrare la propria icona e il proprio nome nella schermata Home.';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => 'Travesti';

  @override
  String get privateSpaceDisguiseConfirmOff => 'Mostra app';

  @override
  String get privateSpaceDisguiseFailed =>
      'Impossibile cambiare l\'aspetto dell\'app.';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '$appName ora appare come una calcolatrice nella tua schermata Home.';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName è tornata nella tua schermata Home.';
  }

  @override
  String get privateSpaceTurnOffTitle => 'Disattivare lo spazio privato?';

  @override
  String get privateSpaceTurnOffMessage =>
      'Ogni app nascosta tornerà nella griglia principale e il PIN verrà dimenticato. I cloni vengono conservati.';

  @override
  String get privateSpaceTurnOffConfirm => 'Disattiva';

  @override
  String get privateSpaceTurnedOff => 'Spazio privato disattivato.';

  @override
  String get pinCreateTitle => 'Crea PIN';

  @override
  String get pinChangeTitle => 'Cambia PIN';

  @override
  String get pinCreateMessage =>
      'Questo PIN blocca lo spazio privato. Conservalo dove non lo dimenticherai: senza non c\'è modo di recuperare un clone nascosto.';

  @override
  String get pinChangeMessage =>
      'Inserisci il PIN attuale, poi scegline uno nuovo.';

  @override
  String get pinCurrentLabel => 'PIN attuale';

  @override
  String get pinNewLabel => 'Nuovo PIN';

  @override
  String get pinConfirmLabel => 'Conferma PIN';

  @override
  String get pinCreateConfirm => 'Crea spazio privato';

  @override
  String get pinSaveConfirm => 'Salva PIN';

  @override
  String pinLengthError(int minimum, int maximum) {
    return 'Usa da $minimum a $maximum cifre.';
  }

  @override
  String get pinMismatchError => 'I due PIN non coincidono.';

  @override
  String get pinCurrentIncorrect => 'Il PIN attuale non è corretto.';

  @override
  String get unlockTitle => 'Sblocca lo spazio privato';

  @override
  String get unlockPinLabel => 'PIN';

  @override
  String get unlockUseFingerprint => 'Usa l\'impronta';

  @override
  String get unlockConfirm => 'Sblocca';

  @override
  String get unlockIncorrectPin => 'PIN errato';

  @override
  String get unlockFingerprintUnavailable =>
      'Lo sblocco con impronta non è disponibile al momento.';

  @override
  String get unlockFingerprintNotRecognised => 'Impronta non riconosciuta.';

  @override
  String get unlockBiometricReason => 'Sblocca il tuo spazio privato';

  @override
  String get privateTileEmpty => 'Spazio privato, vuoto';

  @override
  String privateTileHidden(int count) {
    return 'Spazio privato, $count nascoste';
  }

  @override
  String get settingsSectionPrivacy => 'Privacy';

  @override
  String get settingsPrivateSpaceSubtitle => 'Nascondi le app dietro un PIN';

  @override
  String get settingsOn => 'Attivo';

  @override
  String get settingsOff => 'Non attivo';

  @override
  String get componentBaseApk => 'APK base';

  @override
  String get componentSplitApk => 'APK suddiviso';

  @override
  String get componentNoNativeLibraries => 'Nessuna libreria nativa';

  @override
  String get errorProfileNameEmpty => 'Un clone ha bisogno di un nome.';

  @override
  String errorProfileNameTooLong(int maximum) {
    return 'Il nome di un clone può avere al massimo $maximum caratteri.';
  }

  @override
  String get errorProfileStorageUnreadable =>
      'Non è stato possibile leggere i tuoi cloni salvati.';

  @override
  String get errorProfileNotFound => 'Quel clone non esiste più.';

  @override
  String get errorBridgeFailed =>
      'Qualcosa è andato storto nel dialogo con la parte dell\'app che gestisce i cloni.';

  @override
  String get errorBridgeUnsupportedPlatform =>
      'Questa funzione è disponibile solo su Android.';

  @override
  String get errorTestAppCheckFailed =>
      'Non è stato possibile verificare se l\'app di prova è installata.';

  @override
  String get errorEngineInitFailed =>
      'Il motore di virtualizzazione non è riuscito ad avviarsi su questo dispositivo.';

  @override
  String get errorEngineAndroidTooOld =>
      'Il motore di virtualizzazione richiede una versione più recente di Android.';

  @override
  String get errorEngineNoResponse =>
      'Il motore di virtualizzazione non ha risposto. Riprova.';

  @override
  String get errorNoContainer =>
      'Questo clone non ha ancora un container. Aprilo una volta e riprova.';

  @override
  String get errorLaunchRefused =>
      'Il motore ha rifiutato di aprire questo clone.';

  @override
  String get errorAlreadyCloned => 'Questa app è già stata clonata.';

  @override
  String get errorClearCacheFailed =>
      'Parte della cache di questo clone non è stata eliminata.';

  @override
  String get errorClearDataFailed =>
      'Non è stato possibile cancellare i dati di questo clone.';

  @override
  String get errorShortcutsUnsupported =>
      'Questo launcher non supporta l\'aggiunta di scorciatoie.';

  @override
  String get errorShortcutRefused => 'Il launcher ha rifiutato la scorciatoia.';

  @override
  String get errorApkGone =>
      'L\'APK di questo clone non è più sul dispositivo, quindi non c\'è nulla da condividere.';

  @override
  String get errorShareFailed => 'Non è stato possibile condividere l\'app.';

  @override
  String get errorApkUnreadable =>
      'Non è stato possibile leggere uno degli APK selezionati.';

  @override
  String get errorApkPackageMismatch =>
      'Tutti gli APK selezionati devono appartenere alla stessa app.';

  @override
  String get errorApkVersionMismatch =>
      'Tutti gli APK selezionati devono avere la stessa versione.';

  @override
  String get errorApkBaseRequired =>
      'Seleziona esattamente un APK base e uno o più split di configurazione.';

  @override
  String get errorApkDuplicateSplit =>
      'Lo stesso split APK è stato selezionato più di una volta.';
}
