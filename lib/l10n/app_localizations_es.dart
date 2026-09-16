// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionSupport => 'Soporte';

  @override
  String get settingsSectionLegal => 'Legal';

  @override
  String get settingsSectionAbout => 'Acerca de';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsContact => 'Contáctanos';

  @override
  String get settingsContactSubtitle => 'Preguntas o comentarios';

  @override
  String get settingsRate => 'Valóranos';

  @override
  String settingsRateSubtitle(String appName) {
    return '¿Te gusta $appName? Déjanos una reseña';
  }

  @override
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsTermsOfService => 'Términos del servicio';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get settingsArchitecture => 'Arquitectura del dispositivo';

  @override
  String get settingsArchitectureSubtitle => 'Compatibilidad de apps';

  @override
  String get settingsBits64 => '64 bits';

  @override
  String get settingsBits32 => '32 bits';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'ABIs compatibles';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Aún no publicado';

  @override
  String get settingsNotListedYet => 'Aún no está en la tienda';

  @override
  String get settingsNotSetUpYet => 'Aún no configurado';

  @override
  String get commonUnavailable => 'no disponible';

  @override
  String get appearanceTitle => 'Apariencia';

  @override
  String get appearancePreview => 'Vista previa';

  @override
  String get appearanceChooseTheme => 'Elige un tema';

  @override
  String get appearanceSystem => 'Predeterminado del sistema';

  @override
  String get appearanceSystemSubtitle => 'Seguir los ajustes del dispositivo';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceLightSubtitle => 'Usar siempre el tema claro';

  @override
  String get appearanceDark => 'Oscuro';

  @override
  String get appearanceDarkSubtitle => 'Usar siempre el tema oscuro';

  @override
  String appearanceInstantNote(String appName) {
    return 'Los cambios de tema se aplican al instante en todo $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Vista previa del tema $theme';
  }

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSearchHint => 'Buscar idiomas';

  @override
  String get languageClearSearch => 'Borrar búsqueda';

  @override
  String languageNote(String appName) {
    return 'Elige el idioma que se usa en $appName.';
  }

  @override
  String get languageSectionHeader => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get languageSystemSubtitle => 'Usar el idioma del dispositivo';

  @override
  String get languageInstantNote =>
      'Los cambios de idioma se aplican de inmediato.';

  @override
  String languageNoMatches(String query) {
    return 'Ningún idioma coincide con «$query».';
  }

  @override
  String get contactTitle => 'Contáctanos';

  @override
  String get contactHeroTitle => '¿Cómo podemos ayudarte?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Elige cómo prefieres contactar con el equipo de $appName.';
  }

  @override
  String get contactSectionOptions => 'Opciones de contacto';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Chatea con nuestro equipo de soporte';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Escríbenos por Telegram';

  @override
  String get contactEmail => 'Correo electrónico';

  @override
  String get contactEmailSubtitle => 'Envíanos un correo';

  @override
  String get contactResponseTime => 'Tiempo de respuesta';

  @override
  String get contactResponseTimeValue =>
      'Normalmente respondemos en 1–2 días laborables.';

  @override
  String get contactPrivacyNote =>
      'Solo usaremos tu mensaje para brindarte soporte.';

  @override
  String contactNoMailApp(String email) {
    return 'No se pudo abrir ninguna app de correo. Escribe a $email en su lugar.';
  }

  @override
  String get contactWhatsAppFailed => 'No se pudo abrir WhatsApp.';

  @override
  String get contactTelegramFailed => 'No se pudo abrir Telegram.';

  @override
  String get contactPlayStoreFailed => 'No se pudo abrir Play Store.';

  @override
  String contactLegalOpenFailed(String document) {
    return 'No se pudo abrir $document.';
  }

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonNotNow => 'Ahora no';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonMore => 'Más';

  @override
  String get commonFailureTitle => 'No se pudo hacer';

  @override
  String get homePrivateSpaceTitle => 'Espacio privado';

  @override
  String get homeSubtitle => 'Tu espacio privado';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps ocultas',
      one: '1 app oculta',
      zero: 'Ninguna app oculta',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => 'Bloquear y cerrar';

  @override
  String get homeMenuSettings => 'Ajustes';

  @override
  String get homeMenuDeveloperTools => 'Herramientas de desarrollo';

  @override
  String get homeAddApp => 'Añadir app';

  @override
  String get homeEmptyTitle => 'Tu espacio está vacío';

  @override
  String get homeEmptyMessage =>
      'Añade una app para crear tu primera instancia privada.';

  @override
  String get homeEmptyAction => 'Añade tu primera app';

  @override
  String get homePrivateEmptyTitle => 'Aún no hay nada oculto';

  @override
  String get homePrivateEmptyMessage =>
      'Mantén pulsada cualquier app de la cuadrícula principal y elige Ocultar para moverla aquí.';

  @override
  String get homeSetUpPrivateSpaceTitle => '¿Configurar el espacio privado?';

  @override
  String get homeSetUpPrivateSpaceMessage =>
      'Ocultar un clon requiere un espacio privado. Crea uno con un PIN primero.';

  @override
  String get homeSetUpPrivateSpaceConfirm => 'Configurar';

  @override
  String get homeEngineInactive =>
      'El motor de virtualización no está activo en este dispositivo, así que los clones no pueden ejecutarse en contenedores aislados.';

  @override
  String get homeEngineUnavailable =>
      'El motor de virtualización no está disponible en este dispositivo.';

  @override
  String cloneSpaceLabel(int index) {
    return 'Espacio $index';
  }

  @override
  String get cloneActionsManage => 'Gestionar';

  @override
  String get cloneActionUninstall => 'Desinstalar';

  @override
  String get cloneActionClone => 'Clonar';

  @override
  String get cloneActionShortcut => 'Acceso directo';

  @override
  String get cloneActionSpaceInfo => 'Info del espacio';

  @override
  String get cloneActionEditName => 'Editar nombre';

  @override
  String get cloneActionChangeIcon => 'Cambiar icono';

  @override
  String get cloneIconPickerChoose => 'Elegir una imagen';

  @override
  String get cloneIconPickerUseAppIcon => 'Usar el icono de la app';

  @override
  String get errorCloneIconFailed =>
      'Esa imagen no se pudo usar como icono. Prueba con otra.';

  @override
  String get cloneIconPickerTitle => 'Icono de este clon';

  @override
  String get cloneIconPickerMessage =>
      'Ponle una imagen propia, o conserva el icono de la app y márcalo con un color: así lo distinguirás de tus otros clones de la misma app de un vistazo.';

  @override
  String get cloneActionForceStop => 'Forzar detención';

  @override
  String get cloneActionClearCache => 'Borrar caché';

  @override
  String get cloneActionClearStorage => 'Borrar datos';

  @override
  String get cloneActionHide => 'Ocultar';

  @override
  String get cloneActionUnhide => 'Mostrar';

  @override
  String get cloneActionShareApp => 'Compartir app';

  @override
  String get cloneActionPermissions => 'Permisos';

  @override
  String get cloneActionInstallGoogleServices => 'Instalar servicios de Google';

  @override
  String cloneTileSibling(int index, int count) {
    return ', clon $index de $count';
  }

  @override
  String get cloneTileOpening => ', abriendo';

  @override
  String get cloneTileRunning => ', en ejecución';

  @override
  String get cloneTileCannotLaunch => ', no se puede abrir en este dispositivo';

  @override
  String get cloneForceStopTitle => '¿Forzar la detención de esta app?';

  @override
  String get cloneForceStopMessage =>
      'La app dejará de ejecutarse hasta que vuelvas a abrirla.';

  @override
  String get cloneForceStopConfirm => 'Forzar detención';

  @override
  String get cloneClearCacheTitle => '¿Borrar la caché de la app?';

  @override
  String get cloneClearCacheMessage =>
      'Se eliminarán los archivos temporales de este clon.';

  @override
  String get cloneClearCacheConfirm => 'Borrar caché';

  @override
  String get cloneClearStorageTitle => '¿Borrar los datos de la app?';

  @override
  String get cloneClearStorageMessage =>
      'Se eliminarán de forma permanente las cuentas, los ajustes y los datos locales de este clon.';

  @override
  String get cloneClearStorageConfirm => 'Borrar datos';

  @override
  String get cloneInstallGoogleServicesTitle =>
      '¿Instalar los servicios de Google?';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName instalará los servicios de Google Play en este clon. El clon conserva sus datos. Puede tardar unos segundos.';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => 'Instalar';

  @override
  String cloneStopped(String name) {
    return 'Se detuvo $name.';
  }

  @override
  String cloneCacheCleared(String name) {
    return 'Caché borrada para $name.';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name se restableció. Su próximo inicio será un primer inicio.';
  }

  @override
  String cloneHidden(String name) {
    return '$name está oculta en el espacio privado.';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name vuelve a estar en la cuadrícula principal.';
  }

  @override
  String get cloneShortcutAdded =>
      'Confirma el acceso directo en tu pantalla de inicio para terminar de añadirlo.';

  @override
  String get cloneGoogleServicesInstalling =>
      'Instalando los servicios de Google…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return 'Servicios de Google instalados en $name.';
  }

  @override
  String get cloneCountTitle => 'Clonar app';

  @override
  String cloneCountMessage(String appName) {
    return 'Crea copias adicionales de $appName.';
  }

  @override
  String get cloneCountLabel => 'Número de clones';

  @override
  String get cloneCountDecrease => 'Uno menos';

  @override
  String get cloneCountIncrease => 'Uno más';

  @override
  String get cloneCountConfirm => 'Clonar';

  @override
  String cloneCreating(int created, int total) {
    return 'Creando $created de $total…';
  }

  @override
  String get cloneCreatingFinishing => 'Finalizando…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se añadieron $count copias más de $appName.',
      one: 'Se añadió otra copia de $appName.',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return 'Se crearon $created de $total. $failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return 'Elige entre 1 y $maximum';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return 'Solo hay $free libres y el dispositivo reserva medio gigabyte.';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return 'Hasta $maximum — quedan $free de espacio';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return 'Hasta $maximum a la vez en un dispositivo con $memory de memoria';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return 'No hay espacio para otro clon de $appName. $reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return 'No hay espacio suficiente para $count clones más de $appName. $reason.';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return 'Permisos · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => 'No se pudieron leer los permisos';

  @override
  String get clonePermissionsEmptyTitle => 'Nada que limitar';

  @override
  String get clonePermissionsEmptyMessage =>
      'Esta app no declara permisos peligrosos, así que no hay nada que permitir o denegar para este clon.';

  @override
  String clonePermissionsNote(String appName) {
    return 'Solo se aplican a este clon. Una app clonada suele preguntar antes de usar un permiso, y aquí es donde se limita esa respuesta; una app que se salte la pregunta todavía puede llegar al hardware a través del permiso del propio $appName.';
  }

  @override
  String get spaceInfoTitle => 'Info del espacio';

  @override
  String get spaceInfoIdentifiers => 'Identificadores del dispositivo';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => 'Motor no disponible';

  @override
  String get spaceInfoStateRunning => 'En ejecución';

  @override
  String get spaceInfoStateActive => 'Activo';

  @override
  String get spaceInfoStateRebuilds => 'Se reconstruye al abrir';

  @override
  String get spaceInfoNoContainer =>
      'Este espacio todavía no tiene contenedor, así que no tiene identificadores. Ábrelo una vez y aparecerán aquí.';

  @override
  String get spaceInfoDeviceId => 'ID del dispositivo';

  @override
  String get spaceInfoAndroidId => 'ID de Android';

  @override
  String get spaceInfoSerialNumber => 'Número de serie';

  @override
  String get spaceInfoWifiMac => 'MAC de Wi-Fi';

  @override
  String get spaceInfoBluetoothMac => 'MAC de Bluetooth';

  @override
  String spaceInfoCopy(String label) {
    return 'Copiar $label';
  }

  @override
  String spaceInfoCopied(String label) {
    return '$label copiado.';
  }

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonApply => 'Aplicar';

  @override
  String get pickerTitle => 'Añadir app';

  @override
  String get pickerSearchHint => 'Buscar apps';

  @override
  String get pickerFilterTooltip => 'Filtrar y ordenar';

  @override
  String get pickerErrorTitle => 'No se pudieron listar las apps';

  @override
  String get pickerNoMatchesTitle => 'No hay apps coincidentes';

  @override
  String get pickerNoMatchesMessage => 'Prueba otra búsqueda o importa un APK.';

  @override
  String get pickerPopular => 'Populares';

  @override
  String get pickerQuickPicks => 'Selección rápida';

  @override
  String get pickerInstalledApps => 'Apps instaladas';

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
  String get pickerSystemChip => 'Sistema';

  @override
  String get pickerCannotClone =>
      'Esta app no se puede clonar en este dispositivo.';

  @override
  String get pickerApkUnreadable => 'No se pudo leer el APK seleccionado.';

  @override
  String pickerHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count apps de este dispositivo no se pueden clonar y no aparecen en la lista',
      one:
          '1 app de este dispositivo no se puede clonar y no aparece en la lista',
    );
    return '$_temp0';
  }

  @override
  String get filterTitle => 'Filtrar y ordenar';

  @override
  String get filterSort => 'Ordenar';

  @override
  String get filterSortName => 'Nombre de la app';

  @override
  String get filterSortRecentlyInstalled => 'Instaladas recientemente';

  @override
  String get filterSortRecentlyUpdated => 'Actualizadas recientemente';

  @override
  String get filterFilter => 'Filtrar';

  @override
  String get filterAllApps => 'Todas las apps';

  @override
  String get filterUserApps => 'Apps del usuario';

  @override
  String get filterSystemApps => 'Apps del sistema';

  @override
  String get filterNotAdded => 'No añadidas';

  @override
  String get filterAlreadyAdded => 'Ya añadidas';

  @override
  String get filterArchitecture => 'Arquitectura';

  @override
  String get filterArch64 => '64 bits';

  @override
  String get filterArch32 => '32 bits';

  @override
  String get filterArchNoNativeCode => 'Sin código nativo';

  @override
  String get filterPackageType => 'Tipo de paquete';

  @override
  String get filterPackageSingle => 'APK único';

  @override
  String get filterPackageSplit => 'APK dividido';

  @override
  String filterImportApk(String appName) {
    return 'Abrir paquete de app de $appName';
  }

  @override
  String get appSheetAddClone => 'Añadir clon';

  @override
  String get appSheetAddAnother => 'Añadir otro';

  @override
  String get appSheetShareApp => 'Compartir app';

  @override
  String get appSheetAppDetails => 'Detalles de la app';

  @override
  String get appDetailsTitle => 'Detalles de la app';

  @override
  String get appDetailsAdvanced => 'Detalles avanzados';

  @override
  String get appDetailsPackageName => 'Nombre del paquete';

  @override
  String get appDetailsVersion => 'Versión';

  @override
  String get appDetailsArchitecture => 'Arquitectura';

  @override
  String get appDetailsBitness => 'Bits';

  @override
  String get appDetailsPackageType => 'Tipo de paquete';

  @override
  String get appDetailsApkComponents => 'Componentes del APK';

  @override
  String get appDetailsTotalApkSize => 'Tamaño total del APK';

  @override
  String get appDetailsSigningSha256 => 'SHA-256 del certificado de firma';

  @override
  String get appDetailsSigningUnreadable => 'no se pudo leer';

  @override
  String get appDetailsNoApkFiles =>
      'El gestor de paquetes no informó de ningún archivo APK para esta app.';

  @override
  String get findingAppNotFound =>
      'Esta aplicación no está instalada en el dispositivo.';

  @override
  String get findingSecureEnvRequired =>
      'Esta aplicación requiere un entorno seguro y no se puede virtualizar.';

  @override
  String findingSelfClone(String appName) {
    return '$appName no puede clonarse a sí misma.';
  }

  @override
  String get findingSystemComponent =>
      'Los componentes del sistema no se pueden clonar.';

  @override
  String get findingAbiNotSupported =>
      'Las bibliotecas nativas de esta app no están compiladas para una arquitectura compatible con el motor.';

  @override
  String get findingAppArchiveUnavailable =>
      'This app\'s installation files are not on the device. It has been archived, or its installation is incomplete.';

  @override
  String findingStorageUnavailable(String appName) {
    return 'Esta app usa el almacenamiento compartido y esta versión de $appName no declara el acceso a todos los archivos. Un clon suyo no puede acceder a tus archivos y no funcionará.';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return 'Esta app usa el almacenamiento compartido. Concede a $appName el «acceso a todos los archivos» en Ajustes → Acceso especial de apps antes de abrir el clon, o podría rechazarse al iniciarse.';
  }

  @override
  String get factsNoNativeCode => 'Sin código nativo';

  @override
  String get factsAnyNoNativeCode => 'Cualquiera — sin código nativo';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => 'APK único';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'APK dividido · $count archivos',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => 'desconocida';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => 'Importar desde el gestor de archivos';

  @override
  String get commonSave => 'Guardar';

  @override
  String get renameTitle => 'Renombrar perfil';

  @override
  String get renameFieldLabel => 'Nombre del perfil';

  @override
  String get uninstallTitle => '¿Desinstalar este clon?';

  @override
  String uninstallSpaceOf(int index, int count) {
    return 'Espacio $index de $count';
  }

  @override
  String get uninstallMessage =>
      'Se eliminará la instancia de app seleccionada y sus datos locales.';

  @override
  String get uninstallConfirm => 'Desinstalar';

  @override
  String get calculatorError => 'Error';

  @override
  String get disclosureTitle => 'Antes de empezar';

  @override
  String disclosureIntro(String appName) {
    return '$appName ejecuta una segunda copia de las apps que elijas. Esto es exactamente lo que lee y lo que te pedirá.';
  }

  @override
  String get disclosureAppsTitle => 'Tus apps instaladas';

  @override
  String disclosureAppsBody(String appName) {
    return 'Para mostrar el selector de clones, $appName lee la lista de apps instaladas en este dispositivo: sus nombres, iconos y versiones. Esta lista permanece en tu dispositivo. Nunca se sube, se vende ni se comparte, y la app no contiene anuncios, analíticas ni rastreadores.';
  }

  @override
  String get disclosurePermissionsTitle => 'Permisos en nombre de los clones';

  @override
  String disclosurePermissionsBody(String appName) {
    return 'Las apps clonadas se ejecutan dentro de $appName, así que algunos permisos de Android se le aplican en su nombre. Puede que se te pida una vez que la eximas de la optimización de batería para que los mensajeros clonados sigan entregando. Solo al clonar una app de archivos o multimedia puede que necesites conceder el acceso a todos los archivos en Ajustes.';
  }

  @override
  String get disclosureControlTitle => 'Tú mantienes el control';

  @override
  String get disclosureControlBody =>
      'Nada se solicita en silencio. Puedes rechazar cualquiera de estas peticiones y seguir usando la app, y puedes cambiar de opinión en los Ajustes de Android cuando quieras.';

  @override
  String get disclosureAccept => 'Aceptar y continuar';

  @override
  String get privateSpaceTitle => 'Espacio privado';

  @override
  String get privateSpaceOffTitle => 'El espacio privado está desactivado';

  @override
  String get privateSpaceOffMessage =>
      'Actívalo para ocultar clones tras un PIN. Las apps ocultas desaparecen de la cuadrícula principal y solo se abren aquí.';

  @override
  String get privateSpaceSetUp => 'Configurar el espacio privado';

  @override
  String get privateSpaceChangePin => 'Cambiar el PIN';

  @override
  String get privateSpaceUnlockSection => 'Desbloqueo';

  @override
  String get privateSpaceFingerprint => 'Desbloquear con huella';

  @override
  String get privateSpaceFingerprintAvailable =>
      'Puedes seguir usando tu PIN en cualquier momento.';

  @override
  String get privateSpaceFingerprintUnavailable =>
      'No hay ninguna huella ni rostro configurado en este dispositivo.';

  @override
  String get privateSpaceDisguiseSection => 'Disfraz';

  @override
  String get privateSpaceDisguiseAsCalculator => 'Disfrazar de calculadora';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return 'Sustituye el icono de $appName por una calculadora. Escribe el PIN de tu espacio privado y pulsa = para abrir la app.';
  }

  @override
  String get privateSpaceTurnOff => 'Desactivar el espacio privado';

  @override
  String get privateSpaceTurnOffNote =>
      'Al desactivarlo, todas las apps ocultas vuelven a la cuadrícula principal. Los clones no se eliminan.';

  @override
  String get privateSpaceDisguiseOnTitle => '¿Disfrazar de calculadora?';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return '¿Mostrar $appName de nuevo?';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return 'El icono de $appName se sustituye por una calculadora llamada «Calculator». Para abrir $appName, escribe el PIN de tu espacio privado y pulsa =. Si olvidas el PIN no podrás abrir la app.';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName volverá a mostrar su propio icono y nombre en la pantalla de inicio.';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => 'Disfrazar';

  @override
  String get privateSpaceDisguiseConfirmOff => 'Mostrar app';

  @override
  String get privateSpaceDisguiseFailed =>
      'No se pudo cambiar el aspecto de la app.';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '$appName ahora parece una calculadora en tu pantalla de inicio.';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName vuelve a estar en tu pantalla de inicio.';
  }

  @override
  String get privateSpaceTurnOffTitle => '¿Desactivar el espacio privado?';

  @override
  String get privateSpaceTurnOffMessage =>
      'Todas las apps ocultas volverán a la cuadrícula principal y se olvidará el PIN. Los clones se conservan.';

  @override
  String get privateSpaceTurnOffConfirm => 'Desactivar';

  @override
  String get privateSpaceTurnedOff => 'Espacio privado desactivado.';

  @override
  String get pinCreateTitle => 'Crear PIN';

  @override
  String get pinChangeTitle => 'Cambiar el PIN';

  @override
  String get pinCreateMessage =>
      'Este PIN bloquea el espacio privado. Guárdalo donde no lo olvides: no hay forma de recuperar un clon oculto sin él.';

  @override
  String get pinChangeMessage =>
      'Introduce tu PIN actual y luego elige uno nuevo.';

  @override
  String get pinCurrentLabel => 'PIN actual';

  @override
  String get pinNewLabel => 'PIN nuevo';

  @override
  String get pinConfirmLabel => 'Confirmar PIN';

  @override
  String get pinCreateConfirm => 'Crear espacio privado';

  @override
  String get pinSaveConfirm => 'Guardar PIN';

  @override
  String pinLengthError(int minimum, int maximum) {
    return 'Usa de $minimum a $maximum dígitos.';
  }

  @override
  String get pinMismatchError => 'Los dos PIN no coinciden.';

  @override
  String get pinCurrentIncorrect => 'El PIN actual es incorrecto.';

  @override
  String get unlockTitle => 'Desbloquear el espacio privado';

  @override
  String get unlockPinLabel => 'PIN';

  @override
  String get unlockUseFingerprint => 'Usar huella';

  @override
  String get unlockConfirm => 'Desbloquear';

  @override
  String get unlockIncorrectPin => 'PIN incorrecto';

  @override
  String get unlockFingerprintUnavailable =>
      'El desbloqueo por huella no está disponible ahora mismo.';

  @override
  String get unlockFingerprintNotRecognised => 'Huella no reconocida.';

  @override
  String get unlockBiometricReason => 'Desbloquea tu espacio privado';

  @override
  String get privateTileEmpty => 'Espacio privado, vacío';

  @override
  String privateTileHidden(int count) {
    return 'Espacio privado, $count ocultas';
  }

  @override
  String get settingsSectionPrivacy => 'Privacidad';

  @override
  String get settingsPrivateSpaceSubtitle => 'Oculta apps tras un PIN';

  @override
  String get settingsOn => 'Activado';

  @override
  String get settingsOff => 'Desactivado';

  @override
  String get componentBaseApk => 'APK base';

  @override
  String get componentSplitApk => 'APK dividido';

  @override
  String get componentNoNativeLibraries => 'Sin bibliotecas nativas';

  @override
  String get errorProfileNameEmpty => 'Un clon necesita un nombre.';

  @override
  String errorProfileNameTooLong(int maximum) {
    return 'El nombre de un clon puede tener $maximum caracteres como máximo.';
  }

  @override
  String get errorProfileStorageUnreadable =>
      'No se pudieron leer tus clones guardados.';

  @override
  String get errorProfileNotFound => 'Ese clon ya no existe.';

  @override
  String get errorBridgeFailed =>
      'Algo falló al comunicarse con la parte de la app que gestiona los clones.';

  @override
  String get errorBridgeUnsupportedPlatform =>
      'Esta función solo está disponible en Android.';

  @override
  String get errorTestAppCheckFailed =>
      'No se pudo comprobar si la app de prueba está instalada.';

  @override
  String get errorEngineInitFailed =>
      'El motor de virtualización no pudo iniciarse en este dispositivo.';

  @override
  String get errorEngineAndroidTooOld =>
      'El motor de virtualización requiere una versión más reciente de Android.';

  @override
  String get errorEngineNoResponse =>
      'El motor de virtualización no respondió. Inténtalo de nuevo.';

  @override
  String get errorNoContainer =>
      'Este clon aún no tiene contenedor. Ábrelo una vez e inténtalo de nuevo.';

  @override
  String get errorLaunchRefused => 'El motor se negó a abrir este clon.';

  @override
  String get errorAlreadyCloned => 'Esta app ya se ha clonado.';

  @override
  String get errorClearCacheFailed =>
      'Parte de la caché de este clon no se pudo eliminar.';

  @override
  String get errorClearDataFailed =>
      'No se pudieron borrar los datos de este clon.';

  @override
  String get errorShortcutsUnsupported =>
      'Este launcher no admite añadir accesos directos.';

  @override
  String get errorShortcutRefused => 'El launcher rechazó el acceso directo.';

  @override
  String get errorApkGone =>
      'El APK de este clon ya no está en el dispositivo, así que no hay nada que compartir.';

  @override
  String get errorShareFailed => 'No se pudo compartir la app.';

  @override
  String get errorApkUnreadable =>
      'No se pudo leer uno de los APK seleccionados.';

  @override
  String get errorApkPackageMismatch =>
      'Todos los APK seleccionados deben pertenecer a la misma app.';

  @override
  String get errorApkVersionMismatch =>
      'Todos los APK seleccionados deben tener la misma versión.';

  @override
  String get errorApkBaseRequired =>
      'Selecciona exactamente un APK base y uno o más splits de configuración.';

  @override
  String get errorApkDuplicateSplit =>
      'El mismo split de APK se seleccionó más de una vez.';
}
