// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get settingsTitle => 'Налаштування';

  @override
  String get settingsSectionSupport => 'Підтримка';

  @override
  String get settingsSectionLegal => 'Правова інформація';

  @override
  String get settingsSectionAbout => 'Про додаток';

  @override
  String get settingsLanguage => 'Мова';

  @override
  String get settingsAppearance => 'Вигляд';

  @override
  String get settingsContact => 'Звʼязатися з нами';

  @override
  String get settingsContactSubtitle => 'Запитання чи відгуки';

  @override
  String get settingsRate => 'Оцінити';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Вам подобається $appName? Залиште відгук';
  }

  @override
  String get settingsPrivacyPolicy => 'Політика конфіденційності';

  @override
  String get settingsTermsOfService => 'Умови використання';

  @override
  String get settingsVersion => 'Версія';

  @override
  String get settingsArchitecture => 'Архітектура пристрою';

  @override
  String get settingsArchitectureSubtitle => 'Сумісність додатків';

  @override
  String get settingsBits64 => '64-біт';

  @override
  String get settingsBits32 => '32-біт';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'Підтримувані ABI';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Ще не опубліковано';

  @override
  String get settingsNotListedYet => 'Ще немає в магазині';

  @override
  String get settingsNotSetUpYet => 'Ще не налаштовано';

  @override
  String get commonUnavailable => 'недоступно';

  @override
  String get appearanceTitle => 'Вигляд';

  @override
  String get appearancePreview => 'Перегляд';

  @override
  String get appearanceChooseTheme => 'Виберіть тему';

  @override
  String get appearanceSystem => 'Як у системі';

  @override
  String get appearanceSystemSubtitle =>
      'Використовувати налаштування пристрою';

  @override
  String get appearanceLight => 'Світла';

  @override
  String get appearanceLightSubtitle => 'Завжди світла тема';

  @override
  String get appearanceDark => 'Темна';

  @override
  String get appearanceDarkSubtitle => 'Завжди темна тема';

  @override
  String appearanceInstantNote(String appName) {
    return 'Зміни теми застосовуються одразу в усьому $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Перегляд теми: $theme';
  }

  @override
  String get languageTitle => 'Мова';

  @override
  String get languageSearchHint => 'Пошук мов';

  @override
  String get languageClearSearch => 'Очистити пошук';

  @override
  String languageNote(String appName) {
    return 'Виберіть мову, яка використовується в $appName.';
  }

  @override
  String get languageSectionHeader => 'Мова';

  @override
  String get languageSystem => 'Як у системі';

  @override
  String get languageSystemSubtitle => 'Використовувати мову пристрою';

  @override
  String get languageInstantNote => 'Зміни мови застосовуються одразу.';

  @override
  String languageNoMatches(String query) {
    return 'Немає мов за запитом «$query».';
  }

  @override
  String get contactTitle => 'Звʼязатися з нами';

  @override
  String get contactHeroTitle => 'Чим можемо допомогти?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Виберіть, як вам зручніше звернутися до команди $appName.';
  }

  @override
  String get contactSectionOptions => 'Способи звʼязку';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Напишіть нашій службі підтримки';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Напишіть нам у Telegram';

  @override
  String get contactEmail => 'Ел. пошта';

  @override
  String get contactEmailSubtitle => 'Надішліть нам листа';

  @override
  String get contactResponseTime => 'Час відповіді';

  @override
  String get contactResponseTimeValue =>
      'Зазвичай відповідаємо протягом 1–2 робочих днів.';

  @override
  String get contactPrivacyNote =>
      'Ми використаємо ваше повідомлення лише для підтримки.';

  @override
  String contactNoMailApp(String email) {
    return 'Не вдалося відкрити поштовий додаток. Напишіть на $email.';
  }

  @override
  String get contactWhatsAppFailed => 'Не вдалося відкрити WhatsApp.';

  @override
  String get contactTelegramFailed => 'Не вдалося відкрити Telegram.';

  @override
  String get contactPlayStoreFailed => 'Не вдалося відкрити Play Store.';

  @override
  String contactLegalOpenFailed(String document) {
    return 'Не вдалося відкрити «$document».';
  }

  @override
  String get commonCancel => 'Скасувати';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNotNow => 'Не зараз';

  @override
  String get commonClose => 'Закрити';

  @override
  String get commonMore => 'Ще';

  @override
  String get commonFailureTitle => 'Не вдалося';

  @override
  String get homePrivateSpaceTitle => 'Приватний простір';

  @override
  String get homeSubtitle => 'Ваш приватний простір';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count прихованих застосунків',
      few: '$count приховані застосунки',
      one: '$count прихований застосунок',
      zero: 'Немає прихованих застосунків',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => 'Заблокувати й закрити';

  @override
  String get homeMenuSettings => 'Налаштування';

  @override
  String get homeMenuDeveloperTools => 'Інструменти розробника';

  @override
  String get homeAddApp => 'Додати застосунок';

  @override
  String get homeEmptyTitle => 'Ваш простір порожній';

  @override
  String get homeEmptyMessage =>
      'Додайте застосунок, щоб створити першу приватну копію.';

  @override
  String get homeEmptyAction => 'Додати перший застосунок';

  @override
  String get homePrivateEmptyTitle => 'Поки нічого не приховано';

  @override
  String get homePrivateEmptyMessage =>
      'Утримуйте будь-який застосунок на головній сітці й виберіть «Приховати», щоб перенести його сюди.';

  @override
  String get homeSetUpPrivateSpaceTitle => 'Налаштувати приватний простір?';

  @override
  String get homeSetUpPrivateSpaceMessage =>
      'Щоб приховати клон, потрібен приватний простір. Спершу створіть його з PIN-кодом.';

  @override
  String get homeSetUpPrivateSpaceConfirm => 'Налаштувати';

  @override
  String get homeEngineInactive =>
      'Рушій віртуалізації не активний на цьому пристрої, тож клони не можуть працювати в ізольованих контейнерах.';

  @override
  String get homeEngineUnavailable =>
      'Рушій віртуалізації недоступний на цьому пристрої.';

  @override
  String cloneSpaceLabel(int index) {
    return 'Простір $index';
  }

  @override
  String get cloneActionsCompatibility => 'Сумісність';

  @override
  String get cloneActionsManage => 'Керування';

  @override
  String get cloneActionUninstall => 'Видалити';

  @override
  String get cloneActionClone => 'Клонувати';

  @override
  String get cloneActionShortcut => 'Ярлик';

  @override
  String get cloneActionSpaceInfo => 'Про простір';

  @override
  String get cloneActionEditName => 'Змінити назву';

  @override
  String get cloneActionForceStop => 'Зупинити';

  @override
  String get cloneActionClearCache => 'Очистити кеш';

  @override
  String get cloneActionClearStorage => 'Очистити дані';

  @override
  String get cloneActionHide => 'Приховати';

  @override
  String get cloneActionUnhide => 'Показати';

  @override
  String get cloneActionShareApp => 'Поділитися';

  @override
  String get cloneActionNotifications => 'Сповіщення';

  @override
  String get cloneActionPermissions => 'Дозволи';

  @override
  String get cloneActionGoogleServicesInstalled =>
      'Сервіси Google (microG) встановлено';

  @override
  String get cloneActionInstallGoogleServices =>
      'Встановити сервіси Google (microG)';

  @override
  String cloneTileSibling(int index, int count) {
    return ', клон $index з $count';
  }

  @override
  String get cloneTileOpening => ', відкривається';

  @override
  String get cloneTileRunning => ', працює';

  @override
  String get cloneTileCannotLaunch =>
      ', не може бути запущено на цьому пристрої';

  @override
  String get cloneForceStopTitle => 'Примусово зупинити цей застосунок?';

  @override
  String get cloneForceStopMessage =>
      'Застосунок перестане працювати, доки ви не відкриєте його знову.';

  @override
  String get cloneForceStopConfirm => 'Зупинити';

  @override
  String get cloneClearCacheTitle => 'Очистити кеш застосунку?';

  @override
  String get cloneClearCacheMessage =>
      'Це видалить тимчасові файли цього клону.';

  @override
  String get cloneClearCacheConfirm => 'Очистити кеш';

  @override
  String get cloneClearStorageTitle => 'Очистити дані застосунку?';

  @override
  String get cloneClearStorageMessage =>
      'Це назавжди видалить облікові записи, налаштування та локальні дані цього клону.';

  @override
  String get cloneClearStorageConfirm => 'Очистити дані';

  @override
  String get cloneInstallGoogleServicesTitle => 'Встановити сервіси Google?';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName встановить вбудований microG у цей клон як сервіси Google Play. Дані клону збережуться. Це може зайняти кілька секунд.';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => 'Встановити';

  @override
  String cloneStopped(String name) {
    return '$name зупинено.';
  }

  @override
  String cloneCacheCleared(String name) {
    return 'Кеш $name очищено.';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name скинуто. Наступний запуск буде як перший.';
  }

  @override
  String cloneHidden(String name) {
    return '$name приховано в приватному просторі.';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name знову на головній сітці.';
  }

  @override
  String get cloneShortcutAdded =>
      'Підтвердьте ярлик на головному екрані, щоб завершити додавання.';

  @override
  String get cloneGoogleServicesInstalling => 'Встановлення сервісів Google…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return 'Сервіси Google встановлено в $name.';
  }

  @override
  String get cloneCountTitle => 'Клонувати застосунок';

  @override
  String cloneCountMessage(String appName) {
    return 'Створити додаткові копії $appName.';
  }

  @override
  String get cloneCountLabel => 'Кількість клонів';

  @override
  String get cloneCountDecrease => 'На один менше';

  @override
  String get cloneCountIncrease => 'На один більше';

  @override
  String get cloneCountConfirm => 'Клонувати';

  @override
  String cloneCreating(int created, int total) {
    return 'Створення $created з $total…';
  }

  @override
  String get cloneCreatingFinishing => 'Завершення…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Додано ще $count копій $appName.',
      few: 'Додано ще $count копії $appName.',
      one: 'Додано ще $count копію $appName.',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return 'Створено $created з $total. $failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return 'Виберіть від 1 до $maximum';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return 'Вільно лише $free, а пристрій лишає пів гігабайта в запасі.';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return 'До $maximum — лишилося $free місця';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return 'До $maximum одночасно на пристрої з $memory пам\'яті';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return 'Немає місця для ще одного клону $appName. $reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return 'Недостатньо місця для ще $count клонів $appName. $reason.';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return 'Дозволи · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => 'Не вдалося прочитати дозволи';

  @override
  String get clonePermissionsEmptyTitle => 'Немає чого обмежувати';

  @override
  String get clonePermissionsEmptyMessage =>
      'Цей застосунок не оголошує небезпечних дозволів, тож для цього клону немає чого дозволяти чи забороняти.';

  @override
  String clonePermissionsNote(String appName) {
    return 'Діє лише для цього клону. Клонований застосунок зазвичай запитує перед використанням дозволу, і саме тут ця відповідь обмежується — застосунок, який пропускає запит, усе одно може дістатися до обладнання через власний дозвіл $appName.';
  }

  @override
  String get spaceInfoTitle => 'Про простір';

  @override
  String get spaceInfoIdentifiers => 'Ідентифікатори пристрою';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => 'Рушій недоступний';

  @override
  String get spaceInfoStateRunning => 'Працює';

  @override
  String get spaceInfoStateActive => 'Активний';

  @override
  String get spaceInfoStateRebuilds => 'Перебудовується при запуску';

  @override
  String get spaceInfoNoContainer =>
      'Цей простір ще не має контейнера, тож не має й ідентифікаторів. Відкрийте його один раз, і вони з\'являться тут.';

  @override
  String get spaceInfoDeviceId => 'ID пристрою';

  @override
  String get spaceInfoAndroidId => 'Android ID';

  @override
  String get spaceInfoSerialNumber => 'Серійний номер';

  @override
  String get spaceInfoWifiMac => 'MAC Wi-Fi';

  @override
  String get spaceInfoBluetoothMac => 'MAC Bluetooth';

  @override
  String spaceInfoCopy(String label) {
    return 'Копіювати $label';
  }

  @override
  String spaceInfoCopied(String label) {
    return '$label скопійовано.';
  }

  @override
  String get commonBack => 'Назад';

  @override
  String get commonApply => 'Застосувати';

  @override
  String get pickerTitle => 'Додати застосунок';

  @override
  String get pickerSearchHint => 'Пошук застосунків';

  @override
  String get pickerFilterTooltip => 'Фільтр і сортування';

  @override
  String get pickerErrorTitle => 'Не вдалося отримати список застосунків';

  @override
  String get pickerNoMatchesTitle => 'Немає відповідних застосунків';

  @override
  String get pickerNoMatchesMessage =>
      'Спробуйте інший запит або імпортуйте APK.';

  @override
  String get pickerPopular => 'Популярні';

  @override
  String get pickerQuickPicks => 'Швидкий вибір';

  @override
  String get pickerInstalledApps => 'Встановлені застосунки';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count застосунків',
      few: '$count застосунки',
      one: '$count застосунок',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => 'Системний';

  @override
  String get pickerCannotClone =>
      'Цей застосунок не можна клонувати на цьому пристрої.';

  @override
  String get pickerApkUnreadable => 'Не вдалося прочитати вибраний APK.';

  @override
  String get filterTitle => 'Фільтр і сортування';

  @override
  String get filterSort => 'Сортування';

  @override
  String get filterSortName => 'Назва застосунку';

  @override
  String get filterSortRecentlyInstalled => 'Нещодавно встановлені';

  @override
  String get filterSortRecentlyUpdated => 'Нещодавно оновлені';

  @override
  String get filterFilter => 'Фільтр';

  @override
  String get filterAllApps => 'Усі застосунки';

  @override
  String get filterUserApps => 'Користувацькі';

  @override
  String get filterSystemApps => 'Системні';

  @override
  String get filterNotAdded => 'Не додані';

  @override
  String get filterAlreadyAdded => 'Вже додані';

  @override
  String get filterArchitecture => 'Архітектура';

  @override
  String get filterArch64 => '64 біти';

  @override
  String get filterArch32 => '32 біти';

  @override
  String get filterArchNoNativeCode => 'Без нативного коду';

  @override
  String get filterPackageType => 'Тип пакета';

  @override
  String get filterPackageSingle => 'Одиночний APK';

  @override
  String get filterPackageSplit => 'Split APK';

  @override
  String filterImportApk(String appName) {
    return 'Відкрити пакет застосунку $appName';
  }

  @override
  String get appSheetAddClone => 'Додати клон';

  @override
  String get appSheetAddAnother => 'Додати ще';

  @override
  String get appSheetShareApp => 'Поділитися застосунком';

  @override
  String get appSheetAppDetails => 'Відомості про застосунок';

  @override
  String get appDetailsTitle => 'Відомості про застосунок';

  @override
  String get appDetailsAdvanced => 'Розширені відомості';

  @override
  String get appDetailsPackageName => 'Назва пакета';

  @override
  String get appDetailsVersion => 'Версія';

  @override
  String get appDetailsArchitecture => 'Архітектура';

  @override
  String get appDetailsBitness => 'Розрядність';

  @override
  String get appDetailsPackageType => 'Тип пакета';

  @override
  String get appDetailsApkComponents => 'Компоненти APK';

  @override
  String get appDetailsTotalApkSize => 'Загальний розмір APK';

  @override
  String get appDetailsSigningSha256 => 'SHA-256 сертифіката підпису';

  @override
  String get appDetailsSigningUnreadable => 'не вдалося прочитати';

  @override
  String get appDetailsNoApkFiles =>
      'Менеджер пакетів не повідомив про жодного файлу APK для цього застосунку.';

  @override
  String get compatibilityNotAnalysed => 'Не проаналізовано';

  @override
  String get compatibilitySupported => 'Підтримується';

  @override
  String get compatibilityLimited => 'Обмежено';

  @override
  String get compatibilityUnsupported => 'Не підтримується';

  @override
  String get compatibilityUnexaminedMessage =>
      'Цей застосунок не вдалося перевірити, тож невідомо, наскільки добре він працюватиме. Його ще можуть відхилити під час створення клону.';

  @override
  String get compatibilityNoProblems => 'Відомих проблем сумісності немає.';

  @override
  String compatibilityExistingClones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'У вас уже є $count клонів цього застосунку. Новий почнеться порожнім із власними даними.',
      few:
          'У вас уже є $count клони цього застосунку. Новий почнеться порожнім із власними даними.',
      one:
          'У вас уже є $count клон цього застосунку. Новий почнеться порожнім із власними даними.',
    );
    return '$_temp0';
  }

  @override
  String get compatibilityAddClone => 'Додати клон';

  @override
  String get compatibilityCannotClone => 'Неможливо клонувати';

  @override
  String get findingAppNotFound => 'Цей застосунок не встановлено на пристрої.';

  @override
  String get findingSecureEnvRequired =>
      'Цей застосунок вимагає захищеного середовища і не може бути віртуалізований.';

  @override
  String findingSelfClone(String appName) {
    return '$appName не може клонувати сам себе.';
  }

  @override
  String get findingSystemComponent =>
      'Системні компоненти не можна клонувати.';

  @override
  String get findingAbiNotSupported =>
      'Нативні бібліотеки цього застосунку не зібрані під архітектуру, яку підтримує рушій.';

  @override
  String get findingRequiresGms =>
      'Сервіси Google Play доступні всередині клону, але функції Google, яким потрібно перевірити власну ідентичність цього застосунку, не підтримуються — зокрема вхід і прив\'язані до ідентичності API, як-от перевірка за геопозицією та SMS.';

  @override
  String findingPushUnsupported(String appName) {
    return 'Push-сповіщення не працюватимуть у клоні. Сервіси Google Play не зареєструють цей застосунок для push, поки він працює під ідентичністю $appName, тож повідомлення, надіслані клону, ніколи не доходять. В іншому застосунок придатний до роботи, але на першому запуску очікуйте паузу, доки він чекає на реєстрацію push, яка не може завершитися.';
  }

  @override
  String findingStorageUnavailable(String appName) {
    return 'Цей застосунок використовує спільне сховище, а ця збірка $appName не оголошує доступ до всіх файлів. Його клон не зможе дістатися до ваших файлів і не працюватиме.';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return 'Цей застосунок використовує спільне сховище. Надайте $appName «доступ до всіх файлів» у Налаштуваннях → Спеціальний доступ застосунків, перш ніж запускати клон, інакше його можуть відхилити при запуску.';
  }

  @override
  String get factsNoNativeCode => 'Без нативного коду';

  @override
  String get factsAnyNoNativeCode => 'Будь-яка — без нативного коду';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => 'Одиночний APK';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Split APK · $count файлів',
      few: 'Split APK · $count файли',
      one: 'Split APK · $count файл',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => 'невідомо';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => 'Імпорт через файловий менеджер';

  @override
  String get commonSave => 'Зберегти';

  @override
  String get renameTitle => 'Перейменувати профіль';

  @override
  String get renameFieldLabel => 'Назва профілю';

  @override
  String get uninstallTitle => 'Видалити цей клон?';

  @override
  String uninstallSpaceOf(int index, int count) {
    return 'Простір $index з $count';
  }

  @override
  String get uninstallMessage =>
      'Це видалить вибрану копію застосунку та її локальні дані.';

  @override
  String get uninstallConfirm => 'Видалити';

  @override
  String get calculatorError => 'Помилка';

  @override
  String get disclosureTitle => 'Перш ніж почати';

  @override
  String disclosureIntro(String appName) {
    return '$appName запускає другу копію застосунків, які ви виберете. Ось що саме він читає і про що вас попросить.';
  }

  @override
  String get disclosureAppsTitle => 'Ваші встановлені застосунки';

  @override
  String disclosureAppsBody(String appName) {
    return 'Щоб показати вибір клонів, $appName читає список встановлених на цьому пристрої застосунків — їхні назви, значки та версії. Цей список лишається на вашому пристрої. Він ніколи не завантажується, не продається й не передається, а в застосунку немає реклами, аналітики та трекерів.';
  }

  @override
  String get disclosurePermissionsTitle => 'Дозволи від імені клонів';

  @override
  String disclosurePermissionsBody(String appName) {
    return 'Клоновані застосунки працюють усередині $appName, тож деякі дозволи Android застосовуються до нього від їхнього імені. Можливо, вас один раз попросять виключити його з оптимізації батареї, щоб клоновані месенджери й далі доставляли повідомлення. Лише під час клонування файлового чи медіазастосунку вам може знадобитися надати доступ до всіх файлів у Налаштуваннях.';
  }

  @override
  String get disclosureControlTitle => 'Рішення за вами';

  @override
  String get disclosureControlBody =>
      'Нічого не запитується потай. Ви можете відхилити будь-який із цих запитів і далі користуватися застосунком, а передумати можна будь-коли в налаштуваннях Android.';

  @override
  String get disclosureAccept => 'Прийняти й продовжити';

  @override
  String get privateSpaceTitle => 'Приватний простір';

  @override
  String get privateSpaceOffTitle => 'Приватний простір вимкнено';

  @override
  String get privateSpaceOffMessage =>
      'Увімкніть його, щоб приховувати клони за PIN-кодом. Приховані застосунки зникають із головної сітки й відкриваються лише тут.';

  @override
  String get privateSpaceSetUp => 'Налаштувати приватний простір';

  @override
  String get privateSpaceChangePin => 'Змінити PIN-код';

  @override
  String get privateSpaceUnlockSection => 'Розблокування';

  @override
  String get privateSpaceFingerprint => 'Розблокування відбитком';

  @override
  String get privateSpaceFingerprintAvailable =>
      'Ви й далі можете користуватися PIN-кодом будь-коли.';

  @override
  String get privateSpaceFingerprintUnavailable =>
      'На цьому пристрої не налаштовано відбиток чи обличчя.';

  @override
  String get privateSpaceDisguiseSection => 'Маскування';

  @override
  String get privateSpaceDisguiseAsCalculator => 'Замаскувати під калькулятор';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return 'Замінює значок $appName калькулятором. Введіть PIN-код приватного простору й натисніть =, щоб відкрити застосунок.';
  }

  @override
  String get privateSpaceTurnOff => 'Вимкнути приватний простір';

  @override
  String get privateSpaceTurnOffNote =>
      'Після вимкнення всі приховані застосунки повернуться на головну сітку. Самі клони не видаляються.';

  @override
  String get privateSpaceDisguiseOnTitle => 'Замаскувати під калькулятор?';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return 'Знову показати $appName?';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return 'Значок $appName замінюється калькулятором із назвою «Calculator». Щоб відкрити $appName, введіть PIN-код приватного простору й натисніть =. Якщо ви забудете PIN-код, відкрити застосунок не вдасться.';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName знову показуватиме власний значок і назву на головному екрані.';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => 'Замаскувати';

  @override
  String get privateSpaceDisguiseConfirmOff => 'Показати застосунок';

  @override
  String get privateSpaceDisguiseFailed =>
      'Не вдалося змінити вигляд застосунку.';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '$appName тепер має вигляд калькулятора на вашому головному екрані.';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName знову на вашому головному екрані.';
  }

  @override
  String get privateSpaceTurnOffTitle => 'Вимкнути приватний простір?';

  @override
  String get privateSpaceTurnOffMessage =>
      'Усі приховані застосунки повернуться на головну сітку, а PIN-код буде забуто. Клони зберігаються.';

  @override
  String get privateSpaceTurnOffConfirm => 'Вимкнути';

  @override
  String get privateSpaceTurnedOff => 'Приватний простір вимкнено.';

  @override
  String get pinCreateTitle => 'Створити PIN-код';

  @override
  String get pinChangeTitle => 'Змінити PIN-код';

  @override
  String get pinCreateMessage =>
      'Цей PIN-код блокує приватний простір. Запишіть його там, де не забудете: без нього відновити прихований клон неможливо.';

  @override
  String get pinChangeMessage =>
      'Введіть поточний PIN-код, потім виберіть новий.';

  @override
  String get pinCurrentLabel => 'Поточний PIN-код';

  @override
  String get pinNewLabel => 'Новий PIN-код';

  @override
  String get pinConfirmLabel => 'Підтвердьте PIN-код';

  @override
  String get pinCreateConfirm => 'Створити приватний простір';

  @override
  String get pinSaveConfirm => 'Зберегти PIN-код';

  @override
  String pinLengthError(int minimum, int maximum) {
    return 'Використайте від $minimum до $maximum цифр.';
  }

  @override
  String get pinMismatchError => 'PIN-коди не збігаються.';

  @override
  String get pinCurrentIncorrect => 'Поточний PIN-код неправильний.';

  @override
  String get unlockTitle => 'Розблокувати приватний простір';

  @override
  String get unlockPinLabel => 'PIN-код';

  @override
  String get unlockUseFingerprint => 'Використати відбиток';

  @override
  String get unlockConfirm => 'Розблокувати';

  @override
  String get unlockIncorrectPin => 'Неправильний PIN-код';

  @override
  String get unlockFingerprintUnavailable =>
      'Розблокування відбитком зараз недоступне.';

  @override
  String get unlockFingerprintNotRecognised => 'Відбиток не розпізнано.';

  @override
  String get unlockBiometricReason => 'Розблокуйте приватний простір';

  @override
  String get privateTileEmpty => 'Приватний простір, порожньо';

  @override
  String privateTileHidden(int count) {
    return 'Приватний простір, приховано: $count';
  }

  @override
  String get settingsSectionPrivacy => 'Конфіденційність';

  @override
  String get settingsPrivateSpaceSubtitle => 'Ховайте застосунки за PIN-кодом';

  @override
  String get settingsOn => 'Увімк.';

  @override
  String get settingsOff => 'Вимк.';

  @override
  String get componentBaseApk => 'Базовий APK';

  @override
  String get componentSplitApk => 'Split APK';

  @override
  String get componentNoNativeLibraries => 'Немає нативних бібліотек';

  @override
  String get errorProfileNameEmpty => 'Клону потрібна назва.';

  @override
  String errorProfileNameTooLong(int maximum) {
    return 'Назва клону може містити щонайбільше $maximum символів.';
  }

  @override
  String get errorProfileStorageUnreadable =>
      'Не вдалося прочитати збережені клони.';

  @override
  String get errorProfileNotFound => 'Цього клону більше немає.';

  @override
  String get errorBridgeFailed =>
      'Щось пішло не так під час звернення до частини застосунку, яка керує клонами.';

  @override
  String get errorBridgeUnsupportedPlatform =>
      'Ця можливість доступна лише на Android.';

  @override
  String get errorTestAppCheckFailed =>
      'Не вдалося перевірити, чи встановлено тестовий застосунок.';

  @override
  String get errorEngineInitFailed =>
      'Рушій віртуалізації не зміг запуститися на цьому пристрої.';

  @override
  String get errorEngineAndroidTooOld =>
      'Рушію віртуалізації потрібна новіша версія Android.';

  @override
  String get errorEngineNoResponse =>
      'Рушій віртуалізації не відповів. Спробуйте ще раз.';

  @override
  String get errorNoContainer =>
      'Цей клон ще не має контейнера. Відкрийте його один раз і спробуйте знову.';

  @override
  String get errorLaunchRefused => 'Рушій відмовився відкрити цей клон.';

  @override
  String get errorAlreadyCloned => 'Цей застосунок уже клоновано.';

  @override
  String get errorClearCacheFailed =>
      'Частину кешу цього клону не вдалося видалити.';

  @override
  String get errorClearDataFailed => 'Не вдалося очистити дані цього клону.';

  @override
  String get errorShortcutsUnsupported =>
      'Цей лаунчер не підтримує додавання ярликів.';

  @override
  String get errorShortcutRefused => 'Лаунчер відхилив ярлик.';

  @override
  String get errorApkGone =>
      'APK цього клону більше немає на пристрої, тож ділитися нічим.';

  @override
  String get errorShareFailed => 'Не вдалося поділитися застосунком.';

  @override
  String get errorApkUnreadable => 'Один із вибраних APK не вдалося прочитати.';

  @override
  String get errorApkPackageMismatch =>
      'Усі вибрані APK мають належати одному застосунку.';

  @override
  String get errorApkVersionMismatch =>
      'Усі вибрані APK мають мати однакову версію.';

  @override
  String get errorApkBaseRequired =>
      'Виберіть рівно один базовий APK і один або більше конфігураційних сплітів.';

  @override
  String get errorApkDuplicateSplit =>
      'Той самий спліт APK вибрано кілька разів.';
}
