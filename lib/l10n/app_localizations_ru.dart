// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSectionSupport => 'Поддержка';

  @override
  String get settingsSectionLegal => 'Правовая информация';

  @override
  String get settingsSectionAbout => 'О приложении';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsAppearance => 'Оформление';

  @override
  String get settingsContact => 'Связаться с нами';

  @override
  String get settingsContactSubtitle => 'Вопросы или отзывы';

  @override
  String get settingsRate => 'Оценить';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Нравится $appName? Оставьте отзыв';
  }

  @override
  String get settingsPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get settingsTermsOfService => 'Условия использования';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsArchitecture => 'Архитектура устройства';

  @override
  String get settingsArchitectureSubtitle => 'Совместимость приложений';

  @override
  String get settingsBits64 => '64-бит';

  @override
  String get settingsBits32 => '32-бит';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'Поддерживаемые ABI';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Ещё не опубликовано';

  @override
  String get settingsNotListedYet => 'Ещё нет в магазине';

  @override
  String get settingsNotSetUpYet => 'Ещё не настроено';

  @override
  String get settingsSectionDelivery => 'Доставка';

  @override
  String get settingsBackgroundActivity => 'Фоновая активность';

  @override
  String get settingsBackgroundActivitySubtitle =>
      'Позволяет клонированным приложениям получать уведомления, когда они закрыты';

  @override
  String get settingsBackgroundActivityAllowed => 'Разрешена';

  @override
  String get settingsBackgroundActivityRestricted => 'Ограничена';

  @override
  String get settingsBackgroundActivityNotAllowed => 'Не разрешена';

  @override
  String get backgroundGuideAllowedStatus =>
      'Фоновая активность разрешена, поэтому клонированные приложения получают уведомления, даже когда закрыты.';

  @override
  String get backgroundGuideDone => 'Готово';

  @override
  String get backgroundGuideTitle => 'Фоновая активность';

  @override
  String get backgroundGuideWhy =>
      'Android может приостановить Duplika в фоне; тогда клонированные приложения перестанут получать уведомления, пока вы снова не откроете Duplika.';

  @override
  String get backgroundGuideStepsOem =>
      'В разделе «О приложении» нажмите «Расход батареи» и включите «Разрешить фоновую активность».';

  @override
  String get backgroundGuideStepsStock =>
      'Нажмите «Разрешить» в системном запросе, чтобы приложение могло работать в фоне.';

  @override
  String get backgroundGuideStepsUnknown =>
      'В разделе «О приложении» разрешите фоновую активность.';

  @override
  String get backgroundGuideOpenAppInfo => 'Открыть «О приложении»';

  @override
  String get backgroundGuideAllow => 'Разрешить';

  @override
  String get backgroundGuideLater => 'Не сейчас';

  @override
  String get settingsBackgroundActivityFix =>
      'Нажмите здесь и разрешите фоновую активность';

  @override
  String get settingsBackgroundActivityFixBatteryUsage =>
      'Нажмите здесь, затем «Расход батареи», затем «Разрешить фоновую активность»';

  @override
  String get settingsBackgroundActivityFailed =>
      'Не удалось открыть настройки фоновой активности.';

  @override
  String get commonUnavailable => 'недоступно';

  @override
  String get appearanceTitle => 'Оформление';

  @override
  String get appearancePreview => 'Предпросмотр';

  @override
  String get appearanceChooseTheme => 'Выберите тему';

  @override
  String get appearanceSystem => 'Как в системе';

  @override
  String get appearanceSystemSubtitle => 'Следовать настройкам устройства';

  @override
  String get appearanceLight => 'Светлая';

  @override
  String get appearanceLightSubtitle => 'Всегда светлая тема';

  @override
  String get appearanceDark => 'Тёмная';

  @override
  String get appearanceDarkSubtitle => 'Всегда тёмная тема';

  @override
  String appearanceInstantNote(String appName) {
    return 'Изменения темы применяются сразу во всём приложении $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Предпросмотр темы: $theme';
  }

  @override
  String get languageTitle => 'Язык';

  @override
  String get languageSearchHint => 'Поиск языков';

  @override
  String get languageClearSearch => 'Очистить поиск';

  @override
  String languageNote(String appName) {
    return 'Выберите язык, используемый в $appName.';
  }

  @override
  String get languageSectionHeader => 'Язык';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get languageSystemSubtitle => 'Использовать язык устройства';

  @override
  String get languageInstantNote => 'Изменения языка применяются сразу.';

  @override
  String languageNoMatches(String query) {
    return 'Нет языков по запросу «$query».';
  }

  @override
  String get contactTitle => 'Связаться с нами';

  @override
  String get contactHeroTitle => 'Чем можем помочь?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Выберите удобный способ связаться с командой $appName.';
  }

  @override
  String get contactSectionOptions => 'Способы связи';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Написать в службу поддержки';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Напишите нам в Telegram';

  @override
  String get contactEmail => 'Эл. почта';

  @override
  String get contactEmailSubtitle => 'Отправить нам письмо';

  @override
  String get contactResponseTime => 'Время ответа';

  @override
  String get contactResponseTimeValue =>
      'Обычно отвечаем в течение 1–2 рабочих дней.';

  @override
  String get contactPrivacyNote =>
      'Мы используем ваше сообщение только для поддержки.';

  @override
  String contactNoMailApp(String email) {
    return 'Не удалось открыть почтовое приложение. Напишите на $email.';
  }

  @override
  String get contactWhatsAppFailed => 'Не удалось открыть WhatsApp.';

  @override
  String get contactTelegramFailed => 'Не удалось открыть Telegram.';

  @override
  String get contactPlayStoreFailed => 'Не удалось открыть Play Store.';

  @override
  String contactLegalOpenFailed(String document) {
    return 'Не удалось открыть «$document».';
  }

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonOk => 'ОК';

  @override
  String get commonNotNow => 'Не сейчас';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonMore => 'Ещё';

  @override
  String get commonFailureTitle => 'Не удалось';

  @override
  String get homePrivateSpaceTitle => 'Личное пространство';

  @override
  String get homeSubtitle => 'Ваше личное пространство';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count скрытых приложений',
      few: '$count скрытых приложения',
      one: '$count скрытое приложение',
      zero: 'Нет скрытых приложений',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => 'Заблокировать и закрыть';

  @override
  String get homeMenuSettings => 'Настройки';

  @override
  String get homeMenuDeveloperTools => 'Инструменты разработчика';

  @override
  String get homeAddApp => 'Добавить приложение';

  @override
  String get homeEmptyTitle => 'Ваше пространство пусто';

  @override
  String get homeEmptyMessage =>
      'Добавьте приложение, чтобы создать первую личную копию.';

  @override
  String get homeEmptyAction => 'Добавить первое приложение';

  @override
  String get homePrivateEmptyTitle => 'Пока ничего не скрыто';

  @override
  String get homePrivateEmptyMessage =>
      'Удерживайте любое приложение на главной сетке и выберите «Скрыть», чтобы перенести его сюда.';

  @override
  String get homeSetUpPrivateSpaceTitle => 'Настроить личное пространство?';

  @override
  String get homeSetUpPrivateSpaceMessage =>
      'Чтобы скрыть клон, нужно личное пространство. Сначала создайте его с PIN-кодом.';

  @override
  String get homeSetUpPrivateSpaceConfirm => 'Настроить';

  @override
  String get homeEngineInactive =>
      'Движок виртуализации не активен на этом устройстве, поэтому клоны не могут работать в изолированных контейнерах.';

  @override
  String get homeEngineUnavailable =>
      'Движок виртуализации недоступен на этом устройстве.';

  @override
  String get homeBackgroundNudgeTitle =>
      'Пока клоны закрыты, они могут пропускать уведомления.';

  @override
  String get homeBackgroundNudgeMessage =>
      'Убедитесь, что фоновая активность разрешена, чтобы они продолжали их получать.';

  @override
  String get homeBackgroundNudgeAllow => 'Разрешить';

  @override
  String get homeBackgroundNudgeDismiss => 'Скрыть';

  @override
  String cloneSpaceLabel(int index) {
    return 'Пространство $index';
  }

  @override
  String get cloneActionsCompatibility => 'Совместимость';

  @override
  String get cloneActionsManage => 'Управление';

  @override
  String get cloneActionUninstall => 'Удалить';

  @override
  String get cloneActionClone => 'Клонировать';

  @override
  String get cloneActionShortcut => 'Ярлык';

  @override
  String get cloneActionSpaceInfo => 'О пространстве';

  @override
  String get cloneActionEditName => 'Изменить имя';

  @override
  String get cloneActionForceStop => 'Остановить';

  @override
  String get cloneActionClearCache => 'Очистить кэш';

  @override
  String get cloneActionClearStorage => 'Очистить данные';

  @override
  String get cloneActionHide => 'Скрыть';

  @override
  String get cloneActionUnhide => 'Показать';

  @override
  String get cloneActionShareApp => 'Поделиться';

  @override
  String get cloneActionNotifications => 'Уведомления';

  @override
  String get cloneActionPermissions => 'Разрешения';

  @override
  String get cloneActionGoogleServicesInstalled =>
      'Сервисы Google (microG) установлены';

  @override
  String get cloneActionInstallGoogleServices =>
      'Установить сервисы Google (microG)';

  @override
  String cloneTileSibling(int index, int count) {
    return ', клон $index из $count';
  }

  @override
  String get cloneTileOpening => ', открывается';

  @override
  String get cloneTileRunning => ', работает';

  @override
  String get cloneTileCannotLaunch =>
      ', не может быть запущено на этом устройстве';

  @override
  String get cloneForceStopTitle => 'Принудительно остановить приложение?';

  @override
  String get cloneForceStopMessage =>
      'Приложение перестанет работать, пока вы не откроете его снова.';

  @override
  String get cloneForceStopConfirm => 'Остановить';

  @override
  String get cloneClearCacheTitle => 'Очистить кэш приложения?';

  @override
  String get cloneClearCacheMessage =>
      'Это удалит временные файлы этого клона.';

  @override
  String get cloneClearCacheConfirm => 'Очистить кэш';

  @override
  String get cloneClearStorageTitle => 'Очистить данные приложения?';

  @override
  String get cloneClearStorageMessage =>
      'Это навсегда удалит аккаунты, настройки и локальные данные этого клона.';

  @override
  String get cloneClearStorageConfirm => 'Очистить данные';

  @override
  String get cloneInstallGoogleServicesTitle => 'Установить сервисы Google?';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName установит встроенный microG в этот клон как сервисы Google Play. Данные клона сохранятся. Это может занять несколько секунд.';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => 'Установить';

  @override
  String cloneStopped(String name) {
    return '$name остановлено.';
  }

  @override
  String cloneCacheCleared(String name) {
    return 'Кэш $name очищен.';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name сброшено. Следующий запуск будет как первый.';
  }

  @override
  String cloneHidden(String name) {
    return '$name скрыто в личном пространстве.';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name снова на главной сетке.';
  }

  @override
  String get cloneShortcutAdded =>
      'Подтвердите ярлык на главном экране, чтобы завершить добавление.';

  @override
  String get cloneGoogleServicesInstalling => 'Установка сервисов Google…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return 'Сервисы Google установлены в $name.';
  }

  @override
  String get cloneCountTitle => 'Клонировать приложение';

  @override
  String cloneCountMessage(String appName) {
    return 'Создать дополнительные копии $appName.';
  }

  @override
  String get cloneCountLabel => 'Количество клонов';

  @override
  String get cloneCountDecrease => 'На один меньше';

  @override
  String get cloneCountIncrease => 'На один больше';

  @override
  String get cloneCountConfirm => 'Клонировать';

  @override
  String cloneCreating(int created, int total) {
    return 'Создание $created из $total…';
  }

  @override
  String get cloneCreatingFinishing => 'Завершение…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Добавлено ещё $count копий $appName.',
      few: 'Добавлено ещё $count копии $appName.',
      one: 'Добавлена ещё $count копия $appName.',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return 'Создано $created из $total. $failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return 'Выберите от 1 до $maximum';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return 'Свободно только $free, а устройство оставляет полгигабайта в запасе.';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return 'До $maximum — осталось $free места';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return 'До $maximum одновременно на устройстве с $memory памяти';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return 'Нет места для ещё одного клона $appName. $reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return 'Недостаточно места для ещё $count клонов $appName. $reason.';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return 'Разрешения · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => 'Не удалось прочитать разрешения';

  @override
  String get clonePermissionsEmptyTitle => 'Нечего ограничивать';

  @override
  String get clonePermissionsEmptyMessage =>
      'Это приложение не объявляет опасных разрешений, поэтому для этого клона нечего разрешать или запрещать.';

  @override
  String clonePermissionsNote(String appName) {
    return 'Действует только для этого клона. Клонированное приложение обычно спрашивает перед использованием разрешения, и именно здесь этот ответ ограничивается — приложение, которое пропускает запрос, всё равно может добраться до оборудования через собственное разрешение $appName.';
  }

  @override
  String get spaceInfoTitle => 'О пространстве';

  @override
  String get spaceInfoIdentifiers => 'Идентификаторы устройства';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => 'Движок недоступен';

  @override
  String get spaceInfoStateRunning => 'Работает';

  @override
  String get spaceInfoStateActive => 'Активно';

  @override
  String get spaceInfoStateRebuilds => 'Пересоздаётся при запуске';

  @override
  String get spaceInfoNoContainer =>
      'У этого пространства пока нет контейнера, поэтому нет и идентификаторов. Откройте его один раз, и они появятся здесь.';

  @override
  String get spaceInfoDeviceId => 'ID устройства';

  @override
  String get spaceInfoAndroidId => 'Android ID';

  @override
  String get spaceInfoSerialNumber => 'Серийный номер';

  @override
  String get spaceInfoWifiMac => 'MAC Wi-Fi';

  @override
  String get spaceInfoBluetoothMac => 'MAC Bluetooth';

  @override
  String spaceInfoCopy(String label) {
    return 'Копировать $label';
  }

  @override
  String spaceInfoCopied(String label) {
    return '$label скопирован.';
  }

  @override
  String get commonBack => 'Назад';

  @override
  String get commonApply => 'Применить';

  @override
  String get pickerTitle => 'Добавить приложение';

  @override
  String get pickerSearchHint => 'Поиск приложений';

  @override
  String get pickerFilterTooltip => 'Фильтр и сортировка';

  @override
  String get pickerErrorTitle => 'Не удалось получить список приложений';

  @override
  String get pickerNoMatchesTitle => 'Нет подходящих приложений';

  @override
  String get pickerNoMatchesMessage =>
      'Попробуйте другой запрос или импортируйте APK.';

  @override
  String get pickerPopular => 'Популярные';

  @override
  String get pickerQuickPicks => 'Быстрый выбор';

  @override
  String get pickerInstalledApps => 'Установленные приложения';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count приложений',
      few: '$count приложения',
      one: '$count приложение',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => 'Системное';

  @override
  String get pickerCannotClone =>
      'Это приложение нельзя клонировать на этом устройстве.';

  @override
  String get pickerApkUnreadable => 'Не удалось прочитать выбранный APK.';

  @override
  String get filterTitle => 'Фильтр и сортировка';

  @override
  String get filterSort => 'Сортировка';

  @override
  String get filterSortName => 'Название приложения';

  @override
  String get filterSortRecentlyInstalled => 'Недавно установленные';

  @override
  String get filterSortRecentlyUpdated => 'Недавно обновлённые';

  @override
  String get filterFilter => 'Фильтр';

  @override
  String get filterAllApps => 'Все приложения';

  @override
  String get filterUserApps => 'Пользовательские';

  @override
  String get filterSystemApps => 'Системные';

  @override
  String get filterNotAdded => 'Не добавленные';

  @override
  String get filterAlreadyAdded => 'Уже добавленные';

  @override
  String get filterArchitecture => 'Архитектура';

  @override
  String get filterArch64 => '64 бита';

  @override
  String get filterArch32 => '32 бита';

  @override
  String get filterArchNoNativeCode => 'Без нативного кода';

  @override
  String get filterPackageType => 'Тип пакета';

  @override
  String get filterPackageSingle => 'Одиночный APK';

  @override
  String get filterPackageSplit => 'Split APK';

  @override
  String filterImportApk(String appName) {
    return 'Открыть пакет приложения $appName';
  }

  @override
  String get appSheetAddClone => 'Добавить клон';

  @override
  String get appSheetAddAnother => 'Добавить ещё';

  @override
  String get appSheetShareApp => 'Поделиться приложением';

  @override
  String get appSheetAppDetails => 'Сведения о приложении';

  @override
  String get appDetailsTitle => 'Сведения о приложении';

  @override
  String get appDetailsAdvanced => 'Расширенные сведения';

  @override
  String get appDetailsPackageName => 'Имя пакета';

  @override
  String get appDetailsVersion => 'Версия';

  @override
  String get appDetailsArchitecture => 'Архитектура';

  @override
  String get appDetailsBitness => 'Разрядность';

  @override
  String get appDetailsPackageType => 'Тип пакета';

  @override
  String get appDetailsApkComponents => 'Компоненты APK';

  @override
  String get appDetailsTotalApkSize => 'Общий размер APK';

  @override
  String get appDetailsSigningSha256 => 'SHA-256 сертификата подписи';

  @override
  String get appDetailsSigningUnreadable => 'не удалось прочитать';

  @override
  String get appDetailsNoApkFiles =>
      'Менеджер пакетов не сообщил ни об одном файле APK для этого приложения.';

  @override
  String get compatibilityNotAnalysed => 'Не проанализировано';

  @override
  String get compatibilitySupported => 'Поддерживается';

  @override
  String get compatibilityLimited => 'Ограниченно';

  @override
  String get compatibilityUnsupported => 'Не поддерживается';

  @override
  String get compatibilityUnexaminedMessage =>
      'Это приложение не удалось проверить, поэтому неизвестно, насколько хорошо оно будет работать. При создании клона оно всё ещё может быть отклонено.';

  @override
  String get compatibilityNoProblems => 'Известных проблем совместимости нет.';

  @override
  String compatibilityExistingClones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'У вас уже есть $count клонов этого приложения. Новый начнётся пустым со своими данными.',
      few:
          'У вас уже есть $count клона этого приложения. Новый начнётся пустым со своими данными.',
      one:
          'У вас уже есть $count клон этого приложения. Новый начнётся пустым со своими данными.',
    );
    return '$_temp0';
  }

  @override
  String get compatibilityAddClone => 'Добавить клон';

  @override
  String get compatibilityCannotClone => 'Нельзя клонировать';

  @override
  String get findingAppNotFound =>
      'Это приложение не установлено на устройстве.';

  @override
  String get findingSecureEnvRequired =>
      'Это приложение требует защищённой среды и не может быть виртуализировано.';

  @override
  String findingSelfClone(String appName) {
    return '$appName не может клонировать сам себя.';
  }

  @override
  String get findingSystemComponent =>
      'Системные компоненты нельзя клонировать.';

  @override
  String get findingAbiNotSupported =>
      'Нативные библиотеки этого приложения не собраны под архитектуру, поддерживаемую движком.';

  @override
  String get findingRequiresGms =>
      'Сервисы Google Play доступны внутри клона, но функции Google, которым нужно проверить собственную личность этого приложения, не поддерживаются — включая вход и привязанные к личности API, такие как проверка по геопозиции и по SMS.';

  @override
  String findingPushUnsupported(String appName) {
    return 'Push-уведомления не будут работать в клоне. Сервисы Google Play не зарегистрируют это приложение для push, пока оно работает под личностью $appName, поэтому отправленные клону сообщения никогда не доходят. В остальном приложение пригодно к работе, но при первом запуске ждите паузы, пока оно ожидает регистрацию push, которая не может завершиться.';
  }

  @override
  String findingStorageUnavailable(String appName) {
    return 'Это приложение использует общее хранилище, а эта сборка $appName не объявляет доступ ко всем файлам. Его клон не сможет добраться до ваших файлов и работать не будет.';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return 'Это приложение использует общее хранилище. Предоставьте $appName «доступ ко всем файлам» в Настройках → Специальный доступ приложений, прежде чем запускать клон, иначе он может быть отклонён при запуске.';
  }

  @override
  String get factsNoNativeCode => 'Без нативного кода';

  @override
  String get factsAnyNoNativeCode => 'Любая — без нативного кода';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => 'Одиночный APK';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Split APK · $count файлов',
      few: 'Split APK · $count файла',
      one: 'Split APK · $count файл',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => 'неизвестно';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => 'Импорт через файловый менеджер';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get renameTitle => 'Переименовать профиль';

  @override
  String get renameFieldLabel => 'Имя профиля';

  @override
  String get uninstallTitle => 'Удалить этот клон?';

  @override
  String uninstallSpaceOf(int index, int count) {
    return 'Пространство $index из $count';
  }

  @override
  String get uninstallMessage =>
      'Это удалит выбранную копию приложения и её локальные данные.';

  @override
  String get uninstallConfirm => 'Удалить';

  @override
  String get calculatorError => 'Ошибка';

  @override
  String get disclosureTitle => 'Прежде чем начать';

  @override
  String disclosureIntro(String appName) {
    return '$appName запускает вторую копию приложений, которые вы выберете. Вот что именно он читает и о чём вас попросит.';
  }

  @override
  String get disclosureAppsTitle => 'Ваши установленные приложения';

  @override
  String disclosureAppsBody(String appName) {
    return 'Чтобы показать выбор клонов, $appName читает список установленных на этом устройстве приложений — их названия, значки и версии. Этот список остаётся на вашем устройстве. Он никогда не загружается, не продаётся и не передаётся, а в приложении нет рекламы, аналитики и трекеров.';
  }

  @override
  String get disclosurePermissionsTitle => 'Разрешения от имени клонов';

  @override
  String disclosurePermissionsBody(String appName) {
    return 'Клонированные приложения работают внутри $appName, поэтому некоторые разрешения Android применяются к нему от их имени. Возможно, вас один раз попросят исключить его из оптимизации батареи, чтобы клонированные мессенджеры продолжали доставлять сообщения. Только при клонировании файлового или медиаприложения вам может понадобиться выдать доступ ко всем файлам в Настройках.';
  }

  @override
  String get disclosureControlTitle => 'Решение остаётся за вами';

  @override
  String get disclosureControlBody =>
      'Ничего не запрашивается тайно. Вы можете отклонить любой из этих запросов и продолжить пользоваться приложением, а передумать можно в любой момент в настройках Android.';

  @override
  String get disclosureAccept => 'Принять и продолжить';

  @override
  String get privateSpaceTitle => 'Личное пространство';

  @override
  String get privateSpaceOffTitle => 'Личное пространство выключено';

  @override
  String get privateSpaceOffMessage =>
      'Включите его, чтобы скрывать клоны за PIN-кодом. Скрытые приложения исчезают с главной сетки и открываются только здесь.';

  @override
  String get privateSpaceSetUp => 'Настроить личное пространство';

  @override
  String get privateSpaceChangePin => 'Изменить PIN-код';

  @override
  String get privateSpaceUnlockSection => 'Разблокировка';

  @override
  String get privateSpaceFingerprint => 'Разблокировка отпечатком';

  @override
  String get privateSpaceFingerprintAvailable =>
      'Вы по-прежнему можете использовать PIN-код в любой момент.';

  @override
  String get privateSpaceFingerprintUnavailable =>
      'На этом устройстве не настроены отпечаток или лицо.';

  @override
  String get privateSpaceDisguiseSection => 'Маскировка';

  @override
  String get privateSpaceDisguiseAsCalculator =>
      'Замаскировать под калькулятор';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return 'Заменяет значок $appName калькулятором. Введите PIN-код личного пространства и нажмите =, чтобы открыть приложение.';
  }

  @override
  String get privateSpaceTurnOff => 'Выключить личное пространство';

  @override
  String get privateSpaceTurnOffNote =>
      'При выключении все скрытые приложения вернутся на главную сетку. Сами клоны не удаляются.';

  @override
  String get privateSpaceDisguiseOnTitle => 'Замаскировать под калькулятор?';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return 'Снова показать $appName?';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return 'Значок $appName заменяется калькулятором с названием «Calculator». Чтобы открыть $appName, введите PIN-код личного пространства и нажмите =. Если вы забудете PIN-код, открыть приложение не получится.';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName снова покажет собственный значок и название на главном экране.';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => 'Замаскировать';

  @override
  String get privateSpaceDisguiseConfirmOff => 'Показать приложение';

  @override
  String get privateSpaceDisguiseFailed =>
      'Не удалось изменить внешний вид приложения.';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '$appName теперь выглядит как калькулятор на вашем главном экране.';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName снова на вашем главном экране.';
  }

  @override
  String get privateSpaceTurnOffTitle => 'Выключить личное пространство?';

  @override
  String get privateSpaceTurnOffMessage =>
      'Все скрытые приложения вернутся на главную сетку, а PIN-код будет забыт. Клоны сохраняются.';

  @override
  String get privateSpaceTurnOffConfirm => 'Выключить';

  @override
  String get privateSpaceTurnedOff => 'Личное пространство выключено.';

  @override
  String get pinCreateTitle => 'Создать PIN-код';

  @override
  String get pinChangeTitle => 'Изменить PIN-код';

  @override
  String get pinCreateMessage =>
      'Этот PIN-код блокирует личное пространство. Запишите его там, где не забудете: без него скрытый клон восстановить невозможно.';

  @override
  String get pinChangeMessage =>
      'Введите текущий PIN-код, затем выберите новый.';

  @override
  String get pinCurrentLabel => 'Текущий PIN-код';

  @override
  String get pinNewLabel => 'Новый PIN-код';

  @override
  String get pinConfirmLabel => 'Подтвердите PIN-код';

  @override
  String get pinCreateConfirm => 'Создать личное пространство';

  @override
  String get pinSaveConfirm => 'Сохранить PIN-код';

  @override
  String pinLengthError(int minimum, int maximum) {
    return 'Используйте от $minimum до $maximum цифр.';
  }

  @override
  String get pinMismatchError => 'PIN-коды не совпадают.';

  @override
  String get pinCurrentIncorrect => 'Текущий PIN-код неверен.';

  @override
  String get unlockTitle => 'Разблокировать личное пространство';

  @override
  String get unlockPinLabel => 'PIN-код';

  @override
  String get unlockUseFingerprint => 'Использовать отпечаток';

  @override
  String get unlockConfirm => 'Разблокировать';

  @override
  String get unlockIncorrectPin => 'Неверный PIN-код';

  @override
  String get unlockFingerprintUnavailable =>
      'Разблокировка отпечатком сейчас недоступна.';

  @override
  String get unlockFingerprintNotRecognised => 'Отпечаток не распознан.';

  @override
  String get unlockBiometricReason => 'Разблокируйте личное пространство';

  @override
  String get privateTileEmpty => 'Личное пространство, пусто';

  @override
  String privateTileHidden(int count) {
    return 'Личное пространство, скрыто: $count';
  }

  @override
  String get settingsSectionPrivacy => 'Конфиденциальность';

  @override
  String get settingsPrivateSpaceSubtitle =>
      'Скрывайте приложения за PIN-кодом';

  @override
  String get settingsOn => 'Вкл.';

  @override
  String get settingsOff => 'Выкл.';

  @override
  String get componentBaseApk => 'Базовый APK';

  @override
  String get componentSplitApk => 'Split APK';

  @override
  String get componentNoNativeLibraries => 'Нет нативных библиотек';
}
