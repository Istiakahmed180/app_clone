// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionSupport => '支持';

  @override
  String get settingsSectionLegal => '法律信息';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsContact => '联系我们';

  @override
  String get settingsContactSubtitle => '问题或反馈';

  @override
  String get settingsRate => '给我们评分';

  @override
  String settingsRateSubtitle(String appName) {
    return '喜欢 $appName 吗？写个评价吧';
  }

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsTermsOfService => '服务条款';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsArchitecture => '设备架构';

  @override
  String get settingsArchitectureSubtitle => '应用兼容性';

  @override
  String get settingsBits64 => '64 位';

  @override
  String get settingsBits32 => '32 位';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => '支持的 ABI';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => '尚未发布';

  @override
  String get settingsNotListedYet => '尚未上架';

  @override
  String get settingsNotSetUpYet => '尚未设置';

  @override
  String get commonUnavailable => '无法获取';

  @override
  String get appearanceTitle => '外观';

  @override
  String get appearancePreview => '预览';

  @override
  String get appearanceChooseTheme => '选择主题';

  @override
  String get appearanceSystem => '跟随系统';

  @override
  String get appearanceSystemSubtitle => '与设备设置保持一致';

  @override
  String get appearanceLight => '浅色';

  @override
  String get appearanceLightSubtitle => '始终使用浅色主题';

  @override
  String get appearanceDark => '深色';

  @override
  String get appearanceDarkSubtitle => '始终使用深色主题';

  @override
  String appearanceInstantNote(String appName) {
    return '主题更改会立即应用到整个 $appName。';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return '$theme主题预览';
  }

  @override
  String get languageTitle => '语言';

  @override
  String get languageSearchHint => '搜索语言';

  @override
  String get languageClearSearch => '清除搜索';

  @override
  String languageNote(String appName) {
    return '选择 $appName 使用的语言。';
  }

  @override
  String get languageSectionHeader => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageSystemSubtitle => '使用设备语言';

  @override
  String get languageInstantNote => '语言更改会立即生效。';

  @override
  String languageNoMatches(String query) {
    return '没有与“$query”匹配的语言。';
  }

  @override
  String get contactTitle => '联系我们';

  @override
  String get contactHeroTitle => '需要什么帮助？';

  @override
  String contactHeroSubtitle(String appName) {
    return '选择你希望联系 $appName 团队的方式。';
  }

  @override
  String get contactSectionOptions => '联系方式';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => '与我们的支持团队聊天';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => '在 Telegram 上给我们发消息';

  @override
  String get contactEmail => '电子邮件';

  @override
  String get contactEmailSubtitle => '给我们发邮件';

  @override
  String get contactResponseTime => '回复时间';

  @override
  String get contactResponseTimeValue => '我们通常在 1–2 个工作日内回复。';

  @override
  String get contactPrivacyNote => '我们仅将你的消息用于提供支持。';

  @override
  String contactNoMailApp(String email) {
    return '无法打开邮件应用。请改为写信至 $email。';
  }

  @override
  String get contactWhatsAppFailed => '无法打开 WhatsApp。';

  @override
  String get contactTelegramFailed => '无法打开 Telegram。';

  @override
  String get contactPlayStoreFailed => '无法打开 Play 商店。';

  @override
  String contactLegalOpenFailed(String document) {
    return '无法打开$document。';
  }

  @override
  String get commonCancel => '取消';

  @override
  String get commonOk => '确定';

  @override
  String get commonNotNow => '暂不';

  @override
  String get commonClose => '关闭';

  @override
  String get commonMore => '更多';

  @override
  String get commonFailureTitle => '无法完成';

  @override
  String get homePrivateSpaceTitle => '隐私空间';

  @override
  String get homeSubtitle => '你的隐私空间';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个隐藏的应用',
      zero: '没有隐藏的应用',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => '锁定并关闭';

  @override
  String get homeMenuSettings => '设置';

  @override
  String get homeMenuDeveloperTools => '开发者工具';

  @override
  String get homeAddApp => '添加应用';

  @override
  String get homeEmptyTitle => '你的空间是空的';

  @override
  String get homeEmptyMessage => '添加一个应用，创建你的第一个私有实例。';

  @override
  String get homeEmptyAction => '添加第一个应用';

  @override
  String get homePrivateEmptyTitle => '还没有隐藏任何内容';

  @override
  String get homePrivateEmptyMessage => '在主网格中长按任意应用并选择“隐藏”，即可把它移到这里。';

  @override
  String get homeSetUpPrivateSpaceTitle => '设置隐私空间？';

  @override
  String get homeSetUpPrivateSpaceMessage => '隐藏分身需要隐私空间。请先用 PIN 码创建一个。';

  @override
  String get homeSetUpPrivateSpaceConfirm => '设置';

  @override
  String get homeEngineInactive => '本设备上的虚拟化引擎未启用，因此分身无法在隔离容器中运行。';

  @override
  String get homeEngineUnavailable => '本设备上无法使用虚拟化引擎。';

  @override
  String cloneSpaceLabel(int index) {
    return '空间 $index';
  }

  @override
  String get cloneActionsManage => '管理';

  @override
  String get cloneActionUninstall => '卸载';

  @override
  String get cloneActionClone => '克隆';

  @override
  String get cloneActionShortcut => '快捷方式';

  @override
  String get cloneActionSpaceInfo => '空间信息';

  @override
  String get cloneActionEditName => '编辑名称';

  @override
  String get cloneActionForceStop => '强制停止';

  @override
  String get cloneActionClearCache => '清除缓存';

  @override
  String get cloneActionClearStorage => '清除数据';

  @override
  String get cloneActionHide => '隐藏';

  @override
  String get cloneActionUnhide => '取消隐藏';

  @override
  String get cloneActionShareApp => '分享应用';

  @override
  String get cloneActionPermissions => '权限';

  @override
  String get cloneActionInstallGoogleServices => '安装 Google 服务';

  @override
  String cloneTileSibling(int index, int count) {
    return '，第 $index 个分身，共 $count 个';
  }

  @override
  String get cloneTileOpening => '，正在打开';

  @override
  String get cloneTileRunning => '，正在运行';

  @override
  String get cloneTileCannotLaunch => '，无法在本设备上启动';

  @override
  String get cloneForceStopTitle => '强制停止此应用？';

  @override
  String get cloneForceStopMessage => '在你再次打开之前，应用将停止运行。';

  @override
  String get cloneForceStopConfirm => '强制停止';

  @override
  String get cloneClearCacheTitle => '清除应用缓存？';

  @override
  String get cloneClearCacheMessage => '这将删除此分身的临时文件。';

  @override
  String get cloneClearCacheConfirm => '清除缓存';

  @override
  String get cloneClearStorageTitle => '清除应用数据？';

  @override
  String get cloneClearStorageMessage => '这将永久删除此分身的账号、设置和本地数据。';

  @override
  String get cloneClearStorageConfirm => '清除数据';

  @override
  String get cloneInstallGoogleServicesTitle => '安装 Google 服务？';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName 会把 Google Play 服务安装到此分身中。分身的数据会保留。这可能需要几秒钟。';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => '安装';

  @override
  String cloneStopped(String name) {
    return '已停止 $name。';
  }

  @override
  String cloneCacheCleared(String name) {
    return '已清除 $name 的缓存。';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name 已重置。下次启动将是首次启动。';
  }

  @override
  String cloneHidden(String name) {
    return '$name 已隐藏到隐私空间。';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name 已回到主网格。';
  }

  @override
  String get cloneShortcutAdded => '请在主屏幕上确认快捷方式，以完成添加。';

  @override
  String get cloneGoogleServicesInstalling => '正在安装 Google 服务…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return '已在 $name 中安装 Google 服务。';
  }

  @override
  String get cloneCountTitle => '克隆应用';

  @override
  String cloneCountMessage(String appName) {
    return '再创建几个 $appName 的副本。';
  }

  @override
  String get cloneCountLabel => '分身数量';

  @override
  String get cloneCountDecrease => '减少一个';

  @override
  String get cloneCountIncrease => '增加一个';

  @override
  String get cloneCountConfirm => '克隆';

  @override
  String cloneCreating(int created, int total) {
    return '正在创建第 $created 个，共 $total 个…';
  }

  @override
  String get cloneCreatingFinishing => '正在收尾…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已再添加 $count 个 $appName 副本。',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return '已创建 $created 个，共 $total 个。$failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return '请选择 1 到 $maximum';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return '仅剩 $free 可用空间，而设备会保留半个 GB。';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return '最多 $maximum 个 — 还剩 $free 空间';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return '在 $memory 内存的设备上，一次最多 $maximum 个';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return '没有空间再创建一个 $appName 分身。$reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return '空间不足，无法再创建 $count 个 $appName 分身。$reason。';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return '权限 · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => '无法读取权限';

  @override
  String get clonePermissionsEmptyTitle => '没有可限制的项目';

  @override
  String get clonePermissionsEmptyMessage => '此应用未声明危险权限，因此这个分身没有可允许或拒绝的项目。';

  @override
  String clonePermissionsNote(String appName) {
    return '这些设置只对此分身生效。被克隆的应用通常会在使用权限前询问，而这里限制的正是那个答案——跳过询问的应用，仍可能通过 $appName 自身的授权访问硬件。';
  }

  @override
  String get spaceInfoTitle => '空间信息';

  @override
  String get spaceInfoIdentifiers => '设备标识符';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => '引擎不可用';

  @override
  String get spaceInfoStateRunning => '正在运行';

  @override
  String get spaceInfoStateActive => '已激活';

  @override
  String get spaceInfoStateRebuilds => '启动时重建';

  @override
  String get spaceInfoNoContainer => '此空间还没有容器，因此也没有标识符。启动一次后它们就会出现在这里。';

  @override
  String get spaceInfoDeviceId => '设备 ID';

  @override
  String get spaceInfoAndroidId => 'Android ID';

  @override
  String get spaceInfoSerialNumber => '序列号';

  @override
  String get spaceInfoWifiMac => 'Wi-Fi MAC';

  @override
  String get spaceInfoBluetoothMac => '蓝牙 MAC';

  @override
  String spaceInfoCopy(String label) {
    return '复制$label';
  }

  @override
  String spaceInfoCopied(String label) {
    return '已复制$label。';
  }

  @override
  String get commonBack => '返回';

  @override
  String get commonApply => '应用';

  @override
  String get pickerTitle => '添加应用';

  @override
  String get pickerSearchHint => '搜索应用';

  @override
  String get pickerFilterTooltip => '筛选和排序';

  @override
  String get pickerErrorTitle => '无法列出应用';

  @override
  String get pickerNoMatchesTitle => '没有匹配的应用';

  @override
  String get pickerNoMatchesMessage => '换个关键词搜索，或改为导入 APK。';

  @override
  String get pickerPopular => '热门';

  @override
  String get pickerQuickPicks => '快捷选择';

  @override
  String get pickerInstalledApps => '已安装的应用';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个应用',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => '系统';

  @override
  String get pickerCannotClone => '此应用无法在本设备上克隆。';

  @override
  String get pickerApkUnreadable => '无法读取所选的 APK。';

  @override
  String get filterTitle => '筛选和排序';

  @override
  String get filterSort => '排序';

  @override
  String get filterSortName => '应用名称';

  @override
  String get filterSortRecentlyInstalled => '最近安装';

  @override
  String get filterSortRecentlyUpdated => '最近更新';

  @override
  String get filterFilter => '筛选';

  @override
  String get filterAllApps => '全部应用';

  @override
  String get filterUserApps => '用户应用';

  @override
  String get filterSystemApps => '系统应用';

  @override
  String get filterNotAdded => '未添加';

  @override
  String get filterAlreadyAdded => '已添加';

  @override
  String get filterArchitecture => '架构';

  @override
  String get filterArch64 => '64 位';

  @override
  String get filterArch32 => '32 位';

  @override
  String get filterArchNoNativeCode => '无原生代码';

  @override
  String get filterPackageType => '包类型';

  @override
  String get filterPackageSingle => '单个 APK';

  @override
  String get filterPackageSplit => '拆分 APK';

  @override
  String filterImportApk(String appName) {
    return '打开 $appName 应用包';
  }

  @override
  String get appSheetAddClone => '添加分身';

  @override
  String get appSheetAddAnother => '再添加一个';

  @override
  String get appSheetShareApp => '分享应用';

  @override
  String get appSheetAppDetails => '应用详情';

  @override
  String get appDetailsTitle => '应用详情';

  @override
  String get appDetailsAdvanced => '高级详情';

  @override
  String get appDetailsPackageName => '包名';

  @override
  String get appDetailsVersion => '版本';

  @override
  String get appDetailsArchitecture => '架构';

  @override
  String get appDetailsBitness => '位宽';

  @override
  String get appDetailsPackageType => '包类型';

  @override
  String get appDetailsApkComponents => 'APK 组件';

  @override
  String get appDetailsTotalApkSize => 'APK 总大小';

  @override
  String get appDetailsSigningSha256 => '签名证书 SHA-256';

  @override
  String get appDetailsSigningUnreadable => '无法读取';

  @override
  String get appDetailsNoApkFiles => '包管理器未报告此应用的任何 APK 文件。';

  @override
  String get findingAppNotFound => '此应用未安装在设备上。';

  @override
  String get findingSecureEnvRequired => '此应用需要安全环境，无法被虚拟化。';

  @override
  String findingSelfClone(String appName) {
    return '$appName 无法克隆自身。';
  }

  @override
  String get findingSystemComponent => '系统组件无法被克隆。';

  @override
  String get findingAbiNotSupported => '此应用的原生库并非为引擎支持的架构构建。';

  @override
  String findingStorageUnavailable(String appName) {
    return '此应用使用共享存储，而当前这个 $appName 版本没有声明“所有文件访问权限”。它的分身无法访问你的文件，也无法正常工作。';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return '此应用使用共享存储。请在启动分身前，于「设置 → 特殊应用权限」中授予 $appName“所有文件访问权限”，否则分身可能在启动时被拒绝。';
  }

  @override
  String get factsNoNativeCode => '无原生代码';

  @override
  String get factsAnyNoNativeCode => '任意 — 无原生代码';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => '单个 APK';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '拆分 APK · $count 个文件',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => '未知';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => '通过文件管理器导入';

  @override
  String get commonSave => '保存';

  @override
  String get renameTitle => '重命名配置';

  @override
  String get renameFieldLabel => '配置名称';

  @override
  String get uninstallTitle => '卸载此分身？';

  @override
  String uninstallSpaceOf(int index, int count) {
    return '空间 $index，共 $count 个';
  }

  @override
  String get uninstallMessage => '这将移除所选的应用实例及其本地数据。';

  @override
  String get uninstallConfirm => '卸载';

  @override
  String get calculatorError => '错误';

  @override
  String get disclosureTitle => '开始之前';

  @override
  String disclosureIntro(String appName) {
    return '$appName 会运行你所选应用的第二份副本。以下正是它读取的内容，以及它会向你请求的权限。';
  }

  @override
  String get disclosureAppsTitle => '你已安装的应用';

  @override
  String disclosureAppsBody(String appName) {
    return '为了显示分身选择列表，$appName 会读取本设备上已安装的应用列表——它们的名称、图标和版本。该列表仅保留在你的设备上，绝不会上传、出售或分享，并且本应用没有广告、没有统计分析、没有跟踪器。';
  }

  @override
  String get disclosurePermissionsTitle => '代表分身的权限';

  @override
  String disclosurePermissionsBody(String appName) {
    return '被克隆的应用在 $appName 内部运行，因此部分 Android 权限会代表它们应用到 $appName 上。你可能会被请求一次，把它从电池优化中排除，让克隆的即时通讯应用持续收发消息。只有在克隆文件或媒体类应用时，你才可能需要在设置中授予“所有文件访问权限”。';
  }

  @override
  String get disclosureControlTitle => '掌控权在你手中';

  @override
  String get disclosureControlBody =>
      '没有任何请求是悄悄进行的。你可以拒绝其中任何一项，仍然正常使用本应用，也可以随时在 Android 设置中改变主意。';

  @override
  String get disclosureAccept => '同意并继续';

  @override
  String get privateSpaceTitle => '隐私空间';

  @override
  String get privateSpaceOffTitle => '隐私空间已关闭';

  @override
  String get privateSpaceOffMessage =>
      '开启后即可用 PIN 码把分身藏起来。隐藏的应用会从主网格中消失，只能在这里打开。';

  @override
  String get privateSpaceSetUp => '设置隐私空间';

  @override
  String get privateSpaceChangePin => '更改 PIN 码';

  @override
  String get privateSpaceUnlockSection => '解锁';

  @override
  String get privateSpaceFingerprint => '使用指纹解锁';

  @override
  String get privateSpaceFingerprintAvailable => '你仍可随时使用 PIN 码。';

  @override
  String get privateSpaceFingerprintUnavailable => '本设备未设置指纹或人脸。';

  @override
  String get privateSpaceDisguiseSection => '伪装';

  @override
  String get privateSpaceDisguiseAsCalculator => '伪装成计算器';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return '把 $appName 的图标替换为计算器。输入隐私空间 PIN 码并按 = 即可打开应用。';
  }

  @override
  String get privateSpaceTurnOff => '关闭隐私空间';

  @override
  String get privateSpaceTurnOffNote => '关闭后，所有隐藏的应用都会回到主网格。分身本身不会被删除。';

  @override
  String get privateSpaceDisguiseOnTitle => '伪装成计算器？';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return '重新显示 $appName？';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return '$appName 的图标会被替换为名为“Calculator”的计算器。要打开 $appName，请输入隐私空间 PIN 码并按 =。若忘记 PIN 码，你将无法打开本应用。';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName 会在主屏幕上重新显示自己的图标和名称。';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => '伪装';

  @override
  String get privateSpaceDisguiseConfirmOff => '显示应用';

  @override
  String get privateSpaceDisguiseFailed => '无法更改应用的外观。';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '$appName 现在在你的主屏幕上看起来像一个计算器。';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName 已回到你的主屏幕。';
  }

  @override
  String get privateSpaceTurnOffTitle => '关闭隐私空间？';

  @override
  String get privateSpaceTurnOffMessage => '所有隐藏的应用都会回到主网格，PIN 码也会被清除。分身会保留。';

  @override
  String get privateSpaceTurnOffConfirm => '关闭';

  @override
  String get privateSpaceTurnedOff => '已关闭隐私空间。';

  @override
  String get pinCreateTitle => '创建 PIN 码';

  @override
  String get pinChangeTitle => '更改 PIN 码';

  @override
  String get pinCreateMessage => '此 PIN 码用于锁定隐私空间。请记在不会忘记的地方：没有它就无法找回被隐藏的分身。';

  @override
  String get pinChangeMessage => '先输入当前 PIN 码，再选择新的。';

  @override
  String get pinCurrentLabel => '当前 PIN 码';

  @override
  String get pinNewLabel => '新 PIN 码';

  @override
  String get pinConfirmLabel => '确认 PIN 码';

  @override
  String get pinCreateConfirm => '创建隐私空间';

  @override
  String get pinSaveConfirm => '保存 PIN 码';

  @override
  String pinLengthError(int minimum, int maximum) {
    return '请使用 $minimum 到 $maximum 位数字。';
  }

  @override
  String get pinMismatchError => '两次输入的 PIN 码不一致。';

  @override
  String get pinCurrentIncorrect => '当前 PIN 码不正确。';

  @override
  String get unlockTitle => '解锁隐私空间';

  @override
  String get unlockPinLabel => 'PIN 码';

  @override
  String get unlockUseFingerprint => '使用指纹';

  @override
  String get unlockConfirm => '解锁';

  @override
  String get unlockIncorrectPin => 'PIN 码不正确';

  @override
  String get unlockFingerprintUnavailable => '指纹解锁当前不可用。';

  @override
  String get unlockFingerprintNotRecognised => '未能识别指纹。';

  @override
  String get unlockBiometricReason => '解锁你的隐私空间';

  @override
  String get privateTileEmpty => '隐私空间，空';

  @override
  String privateTileHidden(int count) {
    return '隐私空间，已隐藏 $count 个';
  }

  @override
  String get settingsSectionPrivacy => '隐私';

  @override
  String get settingsPrivateSpaceSubtitle => '用 PIN 码把应用藏起来';

  @override
  String get settingsOn => '已开启';

  @override
  String get settingsOff => '已关闭';

  @override
  String get componentBaseApk => '基础 APK';

  @override
  String get componentSplitApk => '拆分 APK';

  @override
  String get componentNoNativeLibraries => '无原生库';

  @override
  String get errorProfileNameEmpty => '分身需要一个名称。';

  @override
  String errorProfileNameTooLong(int maximum) {
    return '分身名称最多 $maximum 个字符。';
  }

  @override
  String get errorProfileStorageUnreadable => '无法读取你保存的分身。';

  @override
  String get errorProfileNotFound => '该分身已不存在。';

  @override
  String get errorBridgeFailed => '与管理分身的那部分应用通信时出错。';

  @override
  String get errorBridgeUnsupportedPlatform => '此功能仅在 Android 上可用。';

  @override
  String get errorTestAppCheckFailed => '无法检查测试应用是否已安装。';

  @override
  String get errorEngineInitFailed => '虚拟化引擎无法在本设备上启动。';

  @override
  String get errorEngineAndroidTooOld => '虚拟化引擎需要更新版本的 Android。';

  @override
  String get errorEngineNoResponse => '虚拟化引擎没有响应，请重试。';

  @override
  String get errorNoContainer => '此分身还没有容器。先打开一次再重试。';

  @override
  String get errorLaunchRefused => '引擎拒绝打开此分身。';

  @override
  String get errorAlreadyCloned => '此应用已经克隆过了。';

  @override
  String get errorClearCacheFailed => '此分身的部分缓存无法删除。';

  @override
  String get errorClearDataFailed => '无法清除此分身的数据。';

  @override
  String get errorShortcutsUnsupported => '此启动器不支持添加快捷方式。';

  @override
  String get errorShortcutRefused => '启动器拒绝了该快捷方式。';

  @override
  String get errorApkGone => '此分身的 APK 已不在设备上，因此没有可分享的内容。';

  @override
  String get errorShareFailed => '无法分享该应用。';

  @override
  String get errorApkUnreadable => '无法读取所选 APK 中的一个。';

  @override
  String get errorApkPackageMismatch => '所选的 APK 必须属于同一个应用。';

  @override
  String get errorApkVersionMismatch => '所选的 APK 必须是同一版本。';

  @override
  String get errorApkBaseRequired => '请选择恰好一个基础 APK 和一个或多个配置拆分包。';

  @override
  String get errorApkDuplicateSplit => '同一个 APK 拆分包被选择了多次。';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionSupport => '支持';

  @override
  String get settingsSectionLegal => '法律信息';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsContact => '联系我们';

  @override
  String get settingsContactSubtitle => '问题或反馈';

  @override
  String get settingsRate => '给我们评分';

  @override
  String settingsRateSubtitle(String appName) {
    return '喜欢 $appName 吗？写个评价吧';
  }

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsTermsOfService => '服务条款';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsArchitecture => '设备架构';

  @override
  String get settingsArchitectureSubtitle => '应用兼容性';

  @override
  String get settingsBits64 => '64 位';

  @override
  String get settingsBits32 => '32 位';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => '支持的 ABI';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => '尚未发布';

  @override
  String get settingsNotListedYet => '尚未上架';

  @override
  String get settingsNotSetUpYet => '尚未设置';

  @override
  String get commonUnavailable => '无法获取';

  @override
  String get appearanceTitle => '外观';

  @override
  String get appearancePreview => '预览';

  @override
  String get appearanceChooseTheme => '选择主题';

  @override
  String get appearanceSystem => '跟随系统';

  @override
  String get appearanceSystemSubtitle => '与设备设置保持一致';

  @override
  String get appearanceLight => '浅色';

  @override
  String get appearanceLightSubtitle => '始终使用浅色主题';

  @override
  String get appearanceDark => '深色';

  @override
  String get appearanceDarkSubtitle => '始终使用深色主题';

  @override
  String appearanceInstantNote(String appName) {
    return '主题更改会立即应用到整个 $appName。';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return '$theme主题预览';
  }

  @override
  String get languageTitle => '语言';

  @override
  String get languageSearchHint => '搜索语言';

  @override
  String get languageClearSearch => '清除搜索';

  @override
  String languageNote(String appName) {
    return '选择 $appName 使用的语言。';
  }

  @override
  String get languageSectionHeader => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageSystemSubtitle => '使用设备语言';

  @override
  String get languageInstantNote => '语言更改会立即生效。';

  @override
  String languageNoMatches(String query) {
    return '没有与“$query”匹配的语言。';
  }

  @override
  String get contactTitle => '联系我们';

  @override
  String get contactHeroTitle => '需要什么帮助？';

  @override
  String contactHeroSubtitle(String appName) {
    return '选择你希望联系 $appName 团队的方式。';
  }

  @override
  String get contactSectionOptions => '联系方式';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => '与我们的支持团队聊天';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => '在 Telegram 上给我们发消息';

  @override
  String get contactEmail => '电子邮件';

  @override
  String get contactEmailSubtitle => '给我们发邮件';

  @override
  String get contactResponseTime => '回复时间';

  @override
  String get contactResponseTimeValue => '我们通常在 1–2 个工作日内回复。';

  @override
  String get contactPrivacyNote => '我们仅将你的消息用于提供支持。';

  @override
  String contactNoMailApp(String email) {
    return '无法打开邮件应用。请改为写信至 $email。';
  }

  @override
  String get contactWhatsAppFailed => '无法打开 WhatsApp。';

  @override
  String get contactTelegramFailed => '无法打开 Telegram。';

  @override
  String get contactPlayStoreFailed => '无法打开 Play 商店。';

  @override
  String contactLegalOpenFailed(String document) {
    return '无法打开$document。';
  }

  @override
  String get commonCancel => '取消';

  @override
  String get commonOk => '确定';

  @override
  String get commonNotNow => '暂不';

  @override
  String get commonClose => '关闭';

  @override
  String get commonMore => '更多';

  @override
  String get commonFailureTitle => '无法完成';

  @override
  String get homePrivateSpaceTitle => '隐私空间';

  @override
  String get homeSubtitle => '你的隐私空间';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个隐藏的应用',
      zero: '没有隐藏的应用',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => '锁定并关闭';

  @override
  String get homeMenuSettings => '设置';

  @override
  String get homeMenuDeveloperTools => '开发者工具';

  @override
  String get homeAddApp => '添加应用';

  @override
  String get homeEmptyTitle => '你的空间是空的';

  @override
  String get homeEmptyMessage => '添加一个应用，创建你的第一个私有实例。';

  @override
  String get homeEmptyAction => '添加第一个应用';

  @override
  String get homePrivateEmptyTitle => '还没有隐藏任何内容';

  @override
  String get homePrivateEmptyMessage => '在主网格中长按任意应用并选择“隐藏”，即可把它移到这里。';

  @override
  String get homeSetUpPrivateSpaceTitle => '设置隐私空间？';

  @override
  String get homeSetUpPrivateSpaceMessage => '隐藏分身需要隐私空间。请先用 PIN 码创建一个。';

  @override
  String get homeSetUpPrivateSpaceConfirm => '设置';

  @override
  String get homeEngineInactive => '本设备上的虚拟化引擎未启用，因此分身无法在隔离容器中运行。';

  @override
  String get homeEngineUnavailable => '本设备上无法使用虚拟化引擎。';

  @override
  String cloneSpaceLabel(int index) {
    return '空间 $index';
  }

  @override
  String get cloneActionsManage => '管理';

  @override
  String get cloneActionUninstall => '卸载';

  @override
  String get cloneActionClone => '克隆';

  @override
  String get cloneActionShortcut => '快捷方式';

  @override
  String get cloneActionSpaceInfo => '空间信息';

  @override
  String get cloneActionEditName => '编辑名称';

  @override
  String get cloneActionForceStop => '强制停止';

  @override
  String get cloneActionClearCache => '清除缓存';

  @override
  String get cloneActionClearStorage => '清除数据';

  @override
  String get cloneActionHide => '隐藏';

  @override
  String get cloneActionUnhide => '取消隐藏';

  @override
  String get cloneActionShareApp => '分享应用';

  @override
  String get cloneActionPermissions => '权限';

  @override
  String get cloneActionInstallGoogleServices => '安装 Google 服务';

  @override
  String cloneTileSibling(int index, int count) {
    return '，第 $index 个分身，共 $count 个';
  }

  @override
  String get cloneTileOpening => '，正在打开';

  @override
  String get cloneTileRunning => '，正在运行';

  @override
  String get cloneTileCannotLaunch => '，无法在本设备上启动';

  @override
  String get cloneForceStopTitle => '强制停止此应用？';

  @override
  String get cloneForceStopMessage => '在你再次打开之前，应用将停止运行。';

  @override
  String get cloneForceStopConfirm => '强制停止';

  @override
  String get cloneClearCacheTitle => '清除应用缓存？';

  @override
  String get cloneClearCacheMessage => '这将删除此分身的临时文件。';

  @override
  String get cloneClearCacheConfirm => '清除缓存';

  @override
  String get cloneClearStorageTitle => '清除应用数据？';

  @override
  String get cloneClearStorageMessage => '这将永久删除此分身的账号、设置和本地数据。';

  @override
  String get cloneClearStorageConfirm => '清除数据';

  @override
  String get cloneInstallGoogleServicesTitle => '安装 Google 服务？';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName 会把 Google Play 服务安装到此分身中。分身的数据会保留。这可能需要几秒钟。';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => '安装';

  @override
  String cloneStopped(String name) {
    return '已停止 $name。';
  }

  @override
  String cloneCacheCleared(String name) {
    return '已清除 $name 的缓存。';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name 已重置。下次启动将是首次启动。';
  }

  @override
  String cloneHidden(String name) {
    return '$name 已隐藏到隐私空间。';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name 已回到主网格。';
  }

  @override
  String get cloneShortcutAdded => '请在主屏幕上确认快捷方式，以完成添加。';

  @override
  String get cloneGoogleServicesInstalling => '正在安装 Google 服务…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return '已在 $name 中安装 Google 服务。';
  }

  @override
  String get cloneCountTitle => '克隆应用';

  @override
  String cloneCountMessage(String appName) {
    return '再创建几个 $appName 的副本。';
  }

  @override
  String get cloneCountLabel => '分身数量';

  @override
  String get cloneCountDecrease => '减少一个';

  @override
  String get cloneCountIncrease => '增加一个';

  @override
  String get cloneCountConfirm => '克隆';

  @override
  String cloneCreating(int created, int total) {
    return '正在创建第 $created 个，共 $total 个…';
  }

  @override
  String get cloneCreatingFinishing => '正在收尾…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已再添加 $count 个 $appName 副本。',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return '已创建 $created 个，共 $total 个。$failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return '请选择 1 到 $maximum';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return '仅剩 $free 可用空间，而设备会保留半个 GB。';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return '最多 $maximum 个 — 还剩 $free 空间';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return '在 $memory 内存的设备上，一次最多 $maximum 个';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return '没有空间再创建一个 $appName 分身。$reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return '空间不足，无法再创建 $count 个 $appName 分身。$reason。';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return '权限 · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => '无法读取权限';

  @override
  String get clonePermissionsEmptyTitle => '没有可限制的项目';

  @override
  String get clonePermissionsEmptyMessage => '此应用未声明危险权限，因此这个分身没有可允许或拒绝的项目。';

  @override
  String clonePermissionsNote(String appName) {
    return '这些设置只对此分身生效。被克隆的应用通常会在使用权限前询问，而这里限制的正是那个答案——跳过询问的应用，仍可能通过 $appName 自身的授权访问硬件。';
  }

  @override
  String get spaceInfoTitle => '空间信息';

  @override
  String get spaceInfoIdentifiers => '设备标识符';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => '引擎不可用';

  @override
  String get spaceInfoStateRunning => '正在运行';

  @override
  String get spaceInfoStateActive => '已激活';

  @override
  String get spaceInfoStateRebuilds => '启动时重建';

  @override
  String get spaceInfoNoContainer => '此空间还没有容器，因此也没有标识符。启动一次后它们就会出现在这里。';

  @override
  String get spaceInfoDeviceId => '设备 ID';

  @override
  String get spaceInfoAndroidId => 'Android ID';

  @override
  String get spaceInfoSerialNumber => '序列号';

  @override
  String get spaceInfoWifiMac => 'Wi-Fi MAC';

  @override
  String get spaceInfoBluetoothMac => '蓝牙 MAC';

  @override
  String spaceInfoCopy(String label) {
    return '复制$label';
  }

  @override
  String spaceInfoCopied(String label) {
    return '已复制$label。';
  }

  @override
  String get commonBack => '返回';

  @override
  String get commonApply => '应用';

  @override
  String get pickerTitle => '添加应用';

  @override
  String get pickerSearchHint => '搜索应用';

  @override
  String get pickerFilterTooltip => '筛选和排序';

  @override
  String get pickerErrorTitle => '无法列出应用';

  @override
  String get pickerNoMatchesTitle => '没有匹配的应用';

  @override
  String get pickerNoMatchesMessage => '换个关键词搜索，或改为导入 APK。';

  @override
  String get pickerPopular => '热门';

  @override
  String get pickerQuickPicks => '快捷选择';

  @override
  String get pickerInstalledApps => '已安装的应用';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个应用',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => '系统';

  @override
  String get pickerCannotClone => '此应用无法在本设备上克隆。';

  @override
  String get pickerApkUnreadable => '无法读取所选的 APK。';

  @override
  String get filterTitle => '筛选和排序';

  @override
  String get filterSort => '排序';

  @override
  String get filterSortName => '应用名称';

  @override
  String get filterSortRecentlyInstalled => '最近安装';

  @override
  String get filterSortRecentlyUpdated => '最近更新';

  @override
  String get filterFilter => '筛选';

  @override
  String get filterAllApps => '全部应用';

  @override
  String get filterUserApps => '用户应用';

  @override
  String get filterSystemApps => '系统应用';

  @override
  String get filterNotAdded => '未添加';

  @override
  String get filterAlreadyAdded => '已添加';

  @override
  String get filterArchitecture => '架构';

  @override
  String get filterArch64 => '64 位';

  @override
  String get filterArch32 => '32 位';

  @override
  String get filterArchNoNativeCode => '无原生代码';

  @override
  String get filterPackageType => '包类型';

  @override
  String get filterPackageSingle => '单个 APK';

  @override
  String get filterPackageSplit => '拆分 APK';

  @override
  String filterImportApk(String appName) {
    return '打开 $appName 应用包';
  }

  @override
  String get appSheetAddClone => '添加分身';

  @override
  String get appSheetAddAnother => '再添加一个';

  @override
  String get appSheetShareApp => '分享应用';

  @override
  String get appSheetAppDetails => '应用详情';

  @override
  String get appDetailsTitle => '应用详情';

  @override
  String get appDetailsAdvanced => '高级详情';

  @override
  String get appDetailsPackageName => '包名';

  @override
  String get appDetailsVersion => '版本';

  @override
  String get appDetailsArchitecture => '架构';

  @override
  String get appDetailsBitness => '位宽';

  @override
  String get appDetailsPackageType => '包类型';

  @override
  String get appDetailsApkComponents => 'APK 组件';

  @override
  String get appDetailsTotalApkSize => 'APK 总大小';

  @override
  String get appDetailsSigningSha256 => '签名证书 SHA-256';

  @override
  String get appDetailsSigningUnreadable => '无法读取';

  @override
  String get appDetailsNoApkFiles => '包管理器未报告此应用的任何 APK 文件。';

  @override
  String get findingAppNotFound => '此应用未安装在设备上。';

  @override
  String get findingSecureEnvRequired => '此应用需要安全环境，无法被虚拟化。';

  @override
  String findingSelfClone(String appName) {
    return '$appName 无法克隆自身。';
  }

  @override
  String get findingSystemComponent => '系统组件无法被克隆。';

  @override
  String get findingAbiNotSupported => '此应用的原生库并非为引擎支持的架构构建。';

  @override
  String findingStorageUnavailable(String appName) {
    return '此应用使用共享存储，而当前这个 $appName 版本没有声明“所有文件访问权限”。它的分身无法访问你的文件，也无法正常工作。';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return '此应用使用共享存储。请在启动分身前，于「设置 → 特殊应用权限」中授予 $appName“所有文件访问权限”，否则分身可能在启动时被拒绝。';
  }

  @override
  String get factsNoNativeCode => '无原生代码';

  @override
  String get factsAnyNoNativeCode => '任意 — 无原生代码';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => '单个 APK';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '拆分 APK · $count 个文件',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => '未知';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => '通过文件管理器导入';

  @override
  String get commonSave => '保存';

  @override
  String get renameTitle => '重命名配置';

  @override
  String get renameFieldLabel => '配置名称';

  @override
  String get uninstallTitle => '卸载此分身？';

  @override
  String uninstallSpaceOf(int index, int count) {
    return '空间 $index，共 $count 个';
  }

  @override
  String get uninstallMessage => '这将移除所选的应用实例及其本地数据。';

  @override
  String get uninstallConfirm => '卸载';

  @override
  String get calculatorError => '错误';

  @override
  String get disclosureTitle => '开始之前';

  @override
  String disclosureIntro(String appName) {
    return '$appName 会运行你所选应用的第二份副本。以下正是它读取的内容，以及它会向你请求的权限。';
  }

  @override
  String get disclosureAppsTitle => '你已安装的应用';

  @override
  String disclosureAppsBody(String appName) {
    return '为了显示分身选择列表，$appName 会读取本设备上已安装的应用列表——它们的名称、图标和版本。该列表仅保留在你的设备上，绝不会上传、出售或分享，并且本应用没有广告、没有统计分析、没有跟踪器。';
  }

  @override
  String get disclosurePermissionsTitle => '代表分身的权限';

  @override
  String disclosurePermissionsBody(String appName) {
    return '被克隆的应用在 $appName 内部运行，因此部分 Android 权限会代表它们应用到 $appName 上。你可能会被请求一次，把它从电池优化中排除，让克隆的即时通讯应用持续收发消息。只有在克隆文件或媒体类应用时，你才可能需要在设置中授予“所有文件访问权限”。';
  }

  @override
  String get disclosureControlTitle => '掌控权在你手中';

  @override
  String get disclosureControlBody =>
      '没有任何请求是悄悄进行的。你可以拒绝其中任何一项，仍然正常使用本应用，也可以随时在 Android 设置中改变主意。';

  @override
  String get disclosureAccept => '同意并继续';

  @override
  String get privateSpaceTitle => '隐私空间';

  @override
  String get privateSpaceOffTitle => '隐私空间已关闭';

  @override
  String get privateSpaceOffMessage =>
      '开启后即可用 PIN 码把分身藏起来。隐藏的应用会从主网格中消失，只能在这里打开。';

  @override
  String get privateSpaceSetUp => '设置隐私空间';

  @override
  String get privateSpaceChangePin => '更改 PIN 码';

  @override
  String get privateSpaceUnlockSection => '解锁';

  @override
  String get privateSpaceFingerprint => '使用指纹解锁';

  @override
  String get privateSpaceFingerprintAvailable => '你仍可随时使用 PIN 码。';

  @override
  String get privateSpaceFingerprintUnavailable => '本设备未设置指纹或人脸。';

  @override
  String get privateSpaceDisguiseSection => '伪装';

  @override
  String get privateSpaceDisguiseAsCalculator => '伪装成计算器';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return '把 $appName 的图标替换为计算器。输入隐私空间 PIN 码并按 = 即可打开应用。';
  }

  @override
  String get privateSpaceTurnOff => '关闭隐私空间';

  @override
  String get privateSpaceTurnOffNote => '关闭后，所有隐藏的应用都会回到主网格。分身本身不会被删除。';

  @override
  String get privateSpaceDisguiseOnTitle => '伪装成计算器？';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return '重新显示 $appName？';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return '$appName 的图标会被替换为名为“Calculator”的计算器。要打开 $appName，请输入隐私空间 PIN 码并按 =。若忘记 PIN 码，你将无法打开本应用。';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName 会在主屏幕上重新显示自己的图标和名称。';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => '伪装';

  @override
  String get privateSpaceDisguiseConfirmOff => '显示应用';

  @override
  String get privateSpaceDisguiseFailed => '无法更改应用的外观。';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '$appName 现在在你的主屏幕上看起来像一个计算器。';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName 已回到你的主屏幕。';
  }

  @override
  String get privateSpaceTurnOffTitle => '关闭隐私空间？';

  @override
  String get privateSpaceTurnOffMessage => '所有隐藏的应用都会回到主网格，PIN 码也会被清除。分身会保留。';

  @override
  String get privateSpaceTurnOffConfirm => '关闭';

  @override
  String get privateSpaceTurnedOff => '已关闭隐私空间。';

  @override
  String get pinCreateTitle => '创建 PIN 码';

  @override
  String get pinChangeTitle => '更改 PIN 码';

  @override
  String get pinCreateMessage => '此 PIN 码用于锁定隐私空间。请记在不会忘记的地方：没有它就无法找回被隐藏的分身。';

  @override
  String get pinChangeMessage => '先输入当前 PIN 码，再选择新的。';

  @override
  String get pinCurrentLabel => '当前 PIN 码';

  @override
  String get pinNewLabel => '新 PIN 码';

  @override
  String get pinConfirmLabel => '确认 PIN 码';

  @override
  String get pinCreateConfirm => '创建隐私空间';

  @override
  String get pinSaveConfirm => '保存 PIN 码';

  @override
  String pinLengthError(int minimum, int maximum) {
    return '请使用 $minimum 到 $maximum 位数字。';
  }

  @override
  String get pinMismatchError => '两次输入的 PIN 码不一致。';

  @override
  String get pinCurrentIncorrect => '当前 PIN 码不正确。';

  @override
  String get unlockTitle => '解锁隐私空间';

  @override
  String get unlockPinLabel => 'PIN 码';

  @override
  String get unlockUseFingerprint => '使用指纹';

  @override
  String get unlockConfirm => '解锁';

  @override
  String get unlockIncorrectPin => 'PIN 码不正确';

  @override
  String get unlockFingerprintUnavailable => '指纹解锁当前不可用。';

  @override
  String get unlockFingerprintNotRecognised => '未能识别指纹。';

  @override
  String get unlockBiometricReason => '解锁你的隐私空间';

  @override
  String get privateTileEmpty => '隐私空间，空';

  @override
  String privateTileHidden(int count) {
    return '隐私空间，已隐藏 $count 个';
  }

  @override
  String get settingsSectionPrivacy => '隐私';

  @override
  String get settingsPrivateSpaceSubtitle => '用 PIN 码把应用藏起来';

  @override
  String get settingsOn => '已开启';

  @override
  String get settingsOff => '已关闭';

  @override
  String get componentBaseApk => '基础 APK';

  @override
  String get componentSplitApk => '拆分 APK';

  @override
  String get componentNoNativeLibraries => '无原生库';

  @override
  String get errorProfileNameEmpty => '分身需要一个名称。';

  @override
  String errorProfileNameTooLong(int maximum) {
    return '分身名称最多 $maximum 个字符。';
  }

  @override
  String get errorProfileStorageUnreadable => '无法读取你保存的分身。';

  @override
  String get errorProfileNotFound => '该分身已不存在。';

  @override
  String get errorBridgeFailed => '与管理分身的那部分应用通信时出错。';

  @override
  String get errorBridgeUnsupportedPlatform => '此功能仅在 Android 上可用。';

  @override
  String get errorTestAppCheckFailed => '无法检查测试应用是否已安装。';

  @override
  String get errorEngineInitFailed => '虚拟化引擎无法在本设备上启动。';

  @override
  String get errorEngineAndroidTooOld => '虚拟化引擎需要更新版本的 Android。';

  @override
  String get errorEngineNoResponse => '虚拟化引擎没有响应，请重试。';

  @override
  String get errorNoContainer => '此分身还没有容器。先打开一次再重试。';

  @override
  String get errorLaunchRefused => '引擎拒绝打开此分身。';

  @override
  String get errorAlreadyCloned => '此应用已经克隆过了。';

  @override
  String get errorClearCacheFailed => '此分身的部分缓存无法删除。';

  @override
  String get errorClearDataFailed => '无法清除此分身的数据。';

  @override
  String get errorShortcutsUnsupported => '此启动器不支持添加快捷方式。';

  @override
  String get errorShortcutRefused => '启动器拒绝了该快捷方式。';

  @override
  String get errorApkGone => '此分身的 APK 已不在设备上，因此没有可分享的内容。';

  @override
  String get errorShareFailed => '无法分享该应用。';

  @override
  String get errorApkUnreadable => '无法读取所选 APK 中的一个。';

  @override
  String get errorApkPackageMismatch => '所选的 APK 必须属于同一个应用。';

  @override
  String get errorApkVersionMismatch => '所选的 APK 必须是同一版本。';

  @override
  String get errorApkBaseRequired => '请选择恰好一个基础 APK 和一个或多个配置拆分包。';

  @override
  String get errorApkDuplicateSplit => '同一个 APK 拆分包被选择了多次。';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSectionSupport => '支援';

  @override
  String get settingsSectionLegal => '法律資訊';

  @override
  String get settingsSectionAbout => '關於';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsAppearance => '外觀';

  @override
  String get settingsContact => '聯絡我們';

  @override
  String get settingsContactSubtitle => '問題或意見';

  @override
  String get settingsRate => '為我們評分';

  @override
  String settingsRateSubtitle(String appName) {
    return '喜歡 $appName 嗎？留下評論吧';
  }

  @override
  String get settingsPrivacyPolicy => '隱私權政策';

  @override
  String get settingsTermsOfService => '服務條款';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsArchitecture => '裝置架構';

  @override
  String get settingsArchitectureSubtitle => '應用程式相容性';

  @override
  String get settingsBits64 => '64 位元';

  @override
  String get settingsBits32 => '32 位元';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => '支援的 ABI';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => '尚未發佈';

  @override
  String get settingsNotListedYet => '尚未上架';

  @override
  String get settingsNotSetUpYet => '尚未設定';

  @override
  String get commonUnavailable => '無法取得';

  @override
  String get appearanceTitle => '外觀';

  @override
  String get appearancePreview => '預覽';

  @override
  String get appearanceChooseTheme => '選擇主題';

  @override
  String get appearanceSystem => '跟隨系統';

  @override
  String get appearanceSystemSubtitle => '與裝置設定一致';

  @override
  String get appearanceLight => '淺色';

  @override
  String get appearanceLightSubtitle => '一律使用淺色主題';

  @override
  String get appearanceDark => '深色';

  @override
  String get appearanceDarkSubtitle => '一律使用深色主題';

  @override
  String appearanceInstantNote(String appName) {
    return '主題變更會立即套用至整個 $appName。';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return '$theme主題預覽';
  }

  @override
  String get languageTitle => '語言';

  @override
  String get languageSearchHint => '搜尋語言';

  @override
  String get languageClearSearch => '清除搜尋';

  @override
  String languageNote(String appName) {
    return '選擇 $appName 使用的語言。';
  }

  @override
  String get languageSectionHeader => '語言';

  @override
  String get languageSystem => '跟隨系統';

  @override
  String get languageSystemSubtitle => '使用裝置語言';

  @override
  String get languageInstantNote => '語言變更會立即生效。';

  @override
  String languageNoMatches(String query) {
    return '沒有符合「$query」的語言。';
  }

  @override
  String get contactTitle => '聯絡我們';

  @override
  String get contactHeroTitle => '需要什麼協助？';

  @override
  String contactHeroSubtitle(String appName) {
    return '選擇你想聯絡 $appName 團隊的方式。';
  }

  @override
  String get contactSectionOptions => '聯絡方式';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => '與我們的支援團隊聊天';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => '在 Telegram 上傳訊息給我們';

  @override
  String get contactEmail => '電子郵件';

  @override
  String get contactEmailSubtitle => '寄電子郵件給我們';

  @override
  String get contactResponseTime => '回覆時間';

  @override
  String get contactResponseTimeValue => '我們通常在 1–2 個工作日內回覆。';

  @override
  String get contactPrivacyNote => '我們僅將你的訊息用於提供支援。';

  @override
  String contactNoMailApp(String email) {
    return '無法開啟郵件應用程式。請改寄至 $email。';
  }

  @override
  String get contactWhatsAppFailed => '無法開啟 WhatsApp。';

  @override
  String get contactTelegramFailed => '無法開啟 Telegram。';

  @override
  String get contactPlayStoreFailed => '無法開啟 Play 商店。';

  @override
  String contactLegalOpenFailed(String document) {
    return '無法開啟$document。';
  }

  @override
  String get commonCancel => '取消';

  @override
  String get commonOk => '確定';

  @override
  String get commonNotNow => '暫不';

  @override
  String get commonClose => '關閉';

  @override
  String get commonMore => '更多';

  @override
  String get commonFailureTitle => '無法完成';

  @override
  String get homePrivateSpaceTitle => '私密空間';

  @override
  String get homeSubtitle => '你的私密空間';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個隱藏的應用程式',
      zero: '沒有隱藏的應用程式',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => '鎖定並關閉';

  @override
  String get homeMenuSettings => '設定';

  @override
  String get homeMenuDeveloperTools => '開發者工具';

  @override
  String get homeAddApp => '新增應用程式';

  @override
  String get homeEmptyTitle => '你的空間是空的';

  @override
  String get homeEmptyMessage => '新增一個應用程式，建立你的第一個私有執行個體。';

  @override
  String get homeEmptyAction => '新增第一個應用程式';

  @override
  String get homePrivateEmptyTitle => '還沒有隱藏任何內容';

  @override
  String get homePrivateEmptyMessage => '在主格線中長按任一應用程式並選擇「隱藏」，就能把它移到這裡。';

  @override
  String get homeSetUpPrivateSpaceTitle => '設定私密空間？';

  @override
  String get homeSetUpPrivateSpaceMessage => '隱藏分身需要私密空間。請先用 PIN 碼建立一個。';

  @override
  String get homeSetUpPrivateSpaceConfirm => '設定';

  @override
  String get homeEngineInactive => '本裝置上的虛擬化引擎未啟用，因此分身無法在隔離容器中執行。';

  @override
  String get homeEngineUnavailable => '本裝置上無法使用虛擬化引擎。';

  @override
  String cloneSpaceLabel(int index) {
    return '空間 $index';
  }

  @override
  String get cloneActionsManage => '管理';

  @override
  String get cloneActionUninstall => '解除安裝';

  @override
  String get cloneActionClone => '複製';

  @override
  String get cloneActionShortcut => '捷徑';

  @override
  String get cloneActionSpaceInfo => '空間資訊';

  @override
  String get cloneActionEditName => '編輯名稱';

  @override
  String get cloneActionForceStop => '強制停止';

  @override
  String get cloneActionClearCache => '清除快取';

  @override
  String get cloneActionClearStorage => '清除資料';

  @override
  String get cloneActionHide => '隱藏';

  @override
  String get cloneActionUnhide => '取消隱藏';

  @override
  String get cloneActionShareApp => '分享應用程式';

  @override
  String get cloneActionPermissions => '權限';

  @override
  String get cloneActionInstallGoogleServices => '安裝 Google 服務';

  @override
  String cloneTileSibling(int index, int count) {
    return '，第 $index 個分身，共 $count 個';
  }

  @override
  String get cloneTileOpening => '，正在開啟';

  @override
  String get cloneTileRunning => '，正在執行';

  @override
  String get cloneTileCannotLaunch => '，無法在本裝置上啟動';

  @override
  String get cloneForceStopTitle => '強制停止這個應用程式？';

  @override
  String get cloneForceStopMessage => '在你再次開啟之前，應用程式會停止執行。';

  @override
  String get cloneForceStopConfirm => '強制停止';

  @override
  String get cloneClearCacheTitle => '清除應用程式快取？';

  @override
  String get cloneClearCacheMessage => '這會刪除這個分身的暫存檔。';

  @override
  String get cloneClearCacheConfirm => '清除快取';

  @override
  String get cloneClearStorageTitle => '清除應用程式資料？';

  @override
  String get cloneClearStorageMessage => '這會永久刪除這個分身的帳號、設定與本機資料。';

  @override
  String get cloneClearStorageConfirm => '清除資料';

  @override
  String get cloneInstallGoogleServicesTitle => '安裝 Google 服務？';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName 會把 Google Play 服務安裝到這個分身中。分身的資料會保留。這可能需要幾秒鐘。';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => '安裝';

  @override
  String cloneStopped(String name) {
    return '已停止 $name。';
  }

  @override
  String cloneCacheCleared(String name) {
    return '已清除 $name 的快取。';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name 已重設。下次啟動會是首次啟動。';
  }

  @override
  String cloneHidden(String name) {
    return '$name 已隱藏到私密空間。';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name 已回到主格線。';
  }

  @override
  String get cloneShortcutAdded => '請在主畫面上確認捷徑，以完成新增。';

  @override
  String get cloneGoogleServicesInstalling => '正在安裝 Google 服務…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return '已在 $name 中安裝 Google 服務。';
  }

  @override
  String get cloneCountTitle => '複製應用程式';

  @override
  String cloneCountMessage(String appName) {
    return '再建立幾個 $appName 的副本。';
  }

  @override
  String get cloneCountLabel => '分身數量';

  @override
  String get cloneCountDecrease => '減少一個';

  @override
  String get cloneCountIncrease => '增加一個';

  @override
  String get cloneCountConfirm => '複製';

  @override
  String cloneCreating(int created, int total) {
    return '正在建立第 $created 個，共 $total 個…';
  }

  @override
  String get cloneCreatingFinishing => '正在收尾…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已再新增 $count 個 $appName 副本。',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return '已建立 $created 個，共 $total 個。$failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return '請選擇 1 到 $maximum';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return '僅剩 $free 可用空間，而裝置會保留半個 GB。';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return '最多 $maximum 個 — 還剩 $free 空間';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return '在 $memory 記憶體的裝置上，一次最多 $maximum 個';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return '沒有空間再建立一個 $appName 分身。$reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return '空間不足，無法再建立 $count 個 $appName 分身。$reason。';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return '權限 · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => '無法讀取權限';

  @override
  String get clonePermissionsEmptyTitle => '沒有可限制的項目';

  @override
  String get clonePermissionsEmptyMessage => '這個應用程式未宣告危險權限，因此這個分身沒有可允許或拒絕的項目。';

  @override
  String clonePermissionsNote(String appName) {
    return '這些設定只對這個分身生效。被複製的應用程式通常會在使用權限前詢問，而這裡限制的正是那個答案——略過詢問的應用程式，仍可能透過 $appName 本身的授權存取硬體。';
  }

  @override
  String get spaceInfoTitle => '空間資訊';

  @override
  String get spaceInfoIdentifiers => '裝置識別碼';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => '引擎無法使用';

  @override
  String get spaceInfoStateRunning => '正在執行';

  @override
  String get spaceInfoStateActive => '已啟用';

  @override
  String get spaceInfoStateRebuilds => '啟動時重建';

  @override
  String get spaceInfoNoContainer => '這個空間還沒有容器，因此也沒有識別碼。啟動一次後它們就會出現在這裡。';

  @override
  String get spaceInfoDeviceId => '裝置 ID';

  @override
  String get spaceInfoAndroidId => 'Android ID';

  @override
  String get spaceInfoSerialNumber => '序號';

  @override
  String get spaceInfoWifiMac => 'Wi-Fi MAC';

  @override
  String get spaceInfoBluetoothMac => '藍牙 MAC';

  @override
  String spaceInfoCopy(String label) {
    return '複製$label';
  }

  @override
  String spaceInfoCopied(String label) {
    return '已複製$label。';
  }

  @override
  String get commonBack => '返回';

  @override
  String get commonApply => '套用';

  @override
  String get pickerTitle => '新增應用程式';

  @override
  String get pickerSearchHint => '搜尋應用程式';

  @override
  String get pickerFilterTooltip => '篩選與排序';

  @override
  String get pickerErrorTitle => '無法列出應用程式';

  @override
  String get pickerNoMatchesTitle => '沒有符合的應用程式';

  @override
  String get pickerNoMatchesMessage => '換個關鍵字搜尋，或改為匯入 APK。';

  @override
  String get pickerPopular => '熱門';

  @override
  String get pickerQuickPicks => '快速選擇';

  @override
  String get pickerInstalledApps => '已安裝的應用程式';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個應用程式',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => '系統';

  @override
  String get pickerCannotClone => '這個應用程式無法在本裝置上複製。';

  @override
  String get pickerApkUnreadable => '無法讀取所選的 APK。';

  @override
  String get filterTitle => '篩選與排序';

  @override
  String get filterSort => '排序';

  @override
  String get filterSortName => '應用程式名稱';

  @override
  String get filterSortRecentlyInstalled => '最近安裝';

  @override
  String get filterSortRecentlyUpdated => '最近更新';

  @override
  String get filterFilter => '篩選';

  @override
  String get filterAllApps => '全部應用程式';

  @override
  String get filterUserApps => '使用者應用程式';

  @override
  String get filterSystemApps => '系統應用程式';

  @override
  String get filterNotAdded => '未新增';

  @override
  String get filterAlreadyAdded => '已新增';

  @override
  String get filterArchitecture => '架構';

  @override
  String get filterArch64 => '64 位元';

  @override
  String get filterArch32 => '32 位元';

  @override
  String get filterArchNoNativeCode => '無原生程式碼';

  @override
  String get filterPackageType => '套件類型';

  @override
  String get filterPackageSingle => '單一 APK';

  @override
  String get filterPackageSplit => '分割 APK';

  @override
  String filterImportApk(String appName) {
    return '開啟 $appName 應用程式套件';
  }

  @override
  String get appSheetAddClone => '新增分身';

  @override
  String get appSheetAddAnother => '再新增一個';

  @override
  String get appSheetShareApp => '分享應用程式';

  @override
  String get appSheetAppDetails => '應用程式詳細資料';

  @override
  String get appDetailsTitle => '應用程式詳細資料';

  @override
  String get appDetailsAdvanced => '進階詳細資料';

  @override
  String get appDetailsPackageName => '套件名稱';

  @override
  String get appDetailsVersion => '版本';

  @override
  String get appDetailsArchitecture => '架構';

  @override
  String get appDetailsBitness => '位元寬度';

  @override
  String get appDetailsPackageType => '套件類型';

  @override
  String get appDetailsApkComponents => 'APK 元件';

  @override
  String get appDetailsTotalApkSize => 'APK 總大小';

  @override
  String get appDetailsSigningSha256 => '簽署憑證 SHA-256';

  @override
  String get appDetailsSigningUnreadable => '無法讀取';

  @override
  String get appDetailsNoApkFiles => '套件管理員未回報這個應用程式的任何 APK 檔案。';

  @override
  String get findingAppNotFound => '這個應用程式未安裝在裝置上。';

  @override
  String get findingSecureEnvRequired => '這個應用程式需要安全環境，無法被虛擬化。';

  @override
  String findingSelfClone(String appName) {
    return '$appName 無法複製自己。';
  }

  @override
  String get findingSystemComponent => '系統元件無法被複製。';

  @override
  String get findingAbiNotSupported => '這個應用程式的原生程式庫並非為引擎支援的架構建置。';

  @override
  String findingStorageUnavailable(String appName) {
    return '這個應用程式使用共用儲存空間，而目前這個 $appName 版本沒有宣告「所有檔案存取權」。它的分身無法存取你的檔案，也無法正常運作。';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return '這個應用程式使用共用儲存空間。請在啟動分身前，於「設定 → 特殊應用程式存取權」中授予 $appName「所有檔案存取權」，否則分身可能在啟動時被拒絕。';
  }

  @override
  String get factsNoNativeCode => '無原生程式碼';

  @override
  String get factsAnyNoNativeCode => '任意 — 無原生程式碼';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => '單一 APK';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '分割 APK · $count 個檔案',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => '未知';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => '透過檔案管理員匯入';

  @override
  String get commonSave => '儲存';

  @override
  String get renameTitle => '重新命名設定檔';

  @override
  String get renameFieldLabel => '設定檔名稱';

  @override
  String get uninstallTitle => '解除安裝這個分身？';

  @override
  String uninstallSpaceOf(int index, int count) {
    return '空間 $index，共 $count 個';
  }

  @override
  String get uninstallMessage => '這會移除所選的應用程式執行個體及其本機資料。';

  @override
  String get uninstallConfirm => '解除安裝';

  @override
  String get calculatorError => '錯誤';

  @override
  String get disclosureTitle => '開始之前';

  @override
  String disclosureIntro(String appName) {
    return '$appName 會執行你所選應用程式的第二份副本。以下正是它讀取的內容，以及它會向你請求的權限。';
  }

  @override
  String get disclosureAppsTitle => '你已安裝的應用程式';

  @override
  String disclosureAppsBody(String appName) {
    return '為了顯示分身選擇清單，$appName 會讀取本裝置上已安裝的應用程式清單——它們的名稱、圖示與版本。該清單只保留在你的裝置上，絕不會上傳、販售或分享，而且本應用程式沒有廣告、沒有分析統計、沒有追蹤器。';
  }

  @override
  String get disclosurePermissionsTitle => '代表分身的權限';

  @override
  String disclosurePermissionsBody(String appName) {
    return '被複製的應用程式在 $appName 內部執行，因此部分 Android 權限會代表它們套用到 $appName 上。你可能會被請求一次，把它從電池最佳化中排除，讓複製的通訊應用程式持續收發訊息。只有在複製檔案或媒體類應用程式時，你才可能需要在設定中授予「所有檔案存取權」。';
  }

  @override
  String get disclosureControlTitle => '主導權在你手上';

  @override
  String get disclosureControlBody =>
      '沒有任何請求是悄悄進行的。你可以拒絕其中任何一項，仍然正常使用本應用程式，也可以隨時在 Android 設定中改變主意。';

  @override
  String get disclosureAccept => '同意並繼續';

  @override
  String get privateSpaceTitle => '私密空間';

  @override
  String get privateSpaceOffTitle => '私密空間已關閉';

  @override
  String get privateSpaceOffMessage =>
      '開啟後即可用 PIN 碼把分身藏起來。隱藏的應用程式會從主格線中消失，只能在這裡開啟。';

  @override
  String get privateSpaceSetUp => '設定私密空間';

  @override
  String get privateSpaceChangePin => '變更 PIN 碼';

  @override
  String get privateSpaceUnlockSection => '解鎖';

  @override
  String get privateSpaceFingerprint => '使用指紋解鎖';

  @override
  String get privateSpaceFingerprintAvailable => '你仍可隨時使用 PIN 碼。';

  @override
  String get privateSpaceFingerprintUnavailable => '本裝置未設定指紋或臉部。';

  @override
  String get privateSpaceDisguiseSection => '偽裝';

  @override
  String get privateSpaceDisguiseAsCalculator => '偽裝成計算機';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return '把 $appName 的圖示換成計算機。輸入私密空間 PIN 碼並按 = 即可開啟應用程式。';
  }

  @override
  String get privateSpaceTurnOff => '關閉私密空間';

  @override
  String get privateSpaceTurnOffNote => '關閉後，所有隱藏的應用程式都會回到主格線。分身本身不會被刪除。';

  @override
  String get privateSpaceDisguiseOnTitle => '偽裝成計算機？';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return '重新顯示 $appName？';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return '$appName 的圖示會被換成名為「Calculator」的計算機。要開啟 $appName，請輸入私密空間 PIN 碼並按 =。若忘記 PIN 碼，你將無法開啟本應用程式。';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName 會在主畫面上重新顯示自己的圖示與名稱。';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => '偽裝';

  @override
  String get privateSpaceDisguiseConfirmOff => '顯示應用程式';

  @override
  String get privateSpaceDisguiseFailed => '無法變更應用程式的外觀。';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '$appName 現在在你的主畫面上看起來像一個計算機。';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName 已回到你的主畫面。';
  }

  @override
  String get privateSpaceTurnOffTitle => '關閉私密空間？';

  @override
  String get privateSpaceTurnOffMessage => '所有隱藏的應用程式都會回到主格線，PIN 碼也會被清除。分身會保留。';

  @override
  String get privateSpaceTurnOffConfirm => '關閉';

  @override
  String get privateSpaceTurnedOff => '已關閉私密空間。';

  @override
  String get pinCreateTitle => '建立 PIN 碼';

  @override
  String get pinChangeTitle => '變更 PIN 碼';

  @override
  String get pinCreateMessage => '這組 PIN 碼用來鎖定私密空間。請記在不會忘記的地方：沒有它就無法找回被隱藏的分身。';

  @override
  String get pinChangeMessage => '先輸入目前的 PIN 碼，再選擇新的。';

  @override
  String get pinCurrentLabel => '目前的 PIN 碼';

  @override
  String get pinNewLabel => '新的 PIN 碼';

  @override
  String get pinConfirmLabel => '確認 PIN 碼';

  @override
  String get pinCreateConfirm => '建立私密空間';

  @override
  String get pinSaveConfirm => '儲存 PIN 碼';

  @override
  String pinLengthError(int minimum, int maximum) {
    return '請使用 $minimum 到 $maximum 位數字。';
  }

  @override
  String get pinMismatchError => '兩次輸入的 PIN 碼不一致。';

  @override
  String get pinCurrentIncorrect => '目前的 PIN 碼不正確。';

  @override
  String get unlockTitle => '解鎖私密空間';

  @override
  String get unlockPinLabel => 'PIN 碼';

  @override
  String get unlockUseFingerprint => '使用指紋';

  @override
  String get unlockConfirm => '解鎖';

  @override
  String get unlockIncorrectPin => 'PIN 碼不正確';

  @override
  String get unlockFingerprintUnavailable => '指紋解鎖目前無法使用。';

  @override
  String get unlockFingerprintNotRecognised => '未能辨識指紋。';

  @override
  String get unlockBiometricReason => '解鎖你的私密空間';

  @override
  String get privateTileEmpty => '私密空間，空';

  @override
  String privateTileHidden(int count) {
    return '私密空間，已隱藏 $count 個';
  }

  @override
  String get settingsSectionPrivacy => '隱私';

  @override
  String get settingsPrivateSpaceSubtitle => '用 PIN 碼把應用程式藏起來';

  @override
  String get settingsOn => '已開啟';

  @override
  String get settingsOff => '已關閉';

  @override
  String get componentBaseApk => '基礎 APK';

  @override
  String get componentSplitApk => '分割 APK';

  @override
  String get componentNoNativeLibraries => '無原生程式庫';

  @override
  String get errorProfileNameEmpty => '分身需要一個名稱。';

  @override
  String errorProfileNameTooLong(int maximum) {
    return '分身名稱最多 $maximum 個字元。';
  }

  @override
  String get errorProfileStorageUnreadable => '無法讀取你儲存的分身。';

  @override
  String get errorProfileNotFound => '該分身已不存在。';

  @override
  String get errorBridgeFailed => '與管理分身的那部分應用程式通訊時發生錯誤。';

  @override
  String get errorBridgeUnsupportedPlatform => '此功能僅在 Android 上可用。';

  @override
  String get errorTestAppCheckFailed => '無法檢查測試應用程式是否已安裝。';

  @override
  String get errorEngineInitFailed => '虛擬化引擎無法在本裝置上啟動。';

  @override
  String get errorEngineAndroidTooOld => '虛擬化引擎需要更新版本的 Android。';

  @override
  String get errorEngineNoResponse => '虛擬化引擎沒有回應，請再試一次。';

  @override
  String get errorNoContainer => '此分身還沒有容器。先開啟一次再重試。';

  @override
  String get errorLaunchRefused => '引擎拒絕開啟此分身。';

  @override
  String get errorAlreadyCloned => '此應用程式已經複製過了。';

  @override
  String get errorClearCacheFailed => '此分身的部分快取無法刪除。';

  @override
  String get errorClearDataFailed => '無法清除此分身的資料。';

  @override
  String get errorShortcutsUnsupported => '此啟動器不支援新增捷徑。';

  @override
  String get errorShortcutRefused => '啟動器拒絕了該捷徑。';

  @override
  String get errorApkGone => '此分身的 APK 已不在裝置上，因此沒有可分享的內容。';

  @override
  String get errorShareFailed => '無法分享該應用程式。';

  @override
  String get errorApkUnreadable => '無法讀取所選 APK 其中之一。';

  @override
  String get errorApkPackageMismatch => '所選的 APK 必須屬於同一個應用程式。';

  @override
  String get errorApkVersionMismatch => '所選的 APK 必須是同一版本。';

  @override
  String get errorApkBaseRequired => '請選擇剛好一個基礎 APK 和一個或多個設定分割包。';

  @override
  String get errorApkDuplicateSplit => '同一個 APK 分割包被選擇了多次。';
}

/// The translations for Chinese, as used in Hong Kong, using the Han script (`zh_Hant_HK`).
class AppLocalizationsZhHantHk extends AppLocalizationsZh {
  AppLocalizationsZhHantHk() : super('zh_Hant_HK');

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSectionSupport => '支援';

  @override
  String get settingsSectionLegal => '法律資訊';

  @override
  String get settingsSectionAbout => '關於';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsAppearance => '外觀';

  @override
  String get settingsContact => '聯絡我們';

  @override
  String get settingsContactSubtitle => '問題或意見';

  @override
  String get settingsRate => '為我們評分';

  @override
  String settingsRateSubtitle(String appName) {
    return '喜歡 $appName 嗎？留下評論吧';
  }

  @override
  String get settingsPrivacyPolicy => '私隱政策';

  @override
  String get settingsTermsOfService => '服務條款';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsArchitecture => '裝置架構';

  @override
  String get settingsArchitectureSubtitle => '應用程式兼容性';

  @override
  String get settingsBits64 => '64 位元';

  @override
  String get settingsBits32 => '32 位元';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => '支援的 ABI';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => '尚未發佈';

  @override
  String get settingsNotListedYet => '尚未上架';

  @override
  String get settingsNotSetUpYet => '尚未設定';

  @override
  String get commonUnavailable => '無法取得';

  @override
  String get appearanceTitle => '外觀';

  @override
  String get appearancePreview => '預覽';

  @override
  String get appearanceChooseTheme => '選擇主題';

  @override
  String get appearanceSystem => '跟隨系統';

  @override
  String get appearanceSystemSubtitle => '與裝置設定一致';

  @override
  String get appearanceLight => '淺色';

  @override
  String get appearanceLightSubtitle => '一律使用淺色主題';

  @override
  String get appearanceDark => '深色';

  @override
  String get appearanceDarkSubtitle => '一律使用深色主題';

  @override
  String appearanceInstantNote(String appName) {
    return '主題變更會立即套用至整個 $appName。';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return '$theme主題預覽';
  }

  @override
  String get languageTitle => '語言';

  @override
  String get languageSearchHint => '搜尋語言';

  @override
  String get languageClearSearch => '清除搜尋';

  @override
  String languageNote(String appName) {
    return '選擇 $appName 使用的語言。';
  }

  @override
  String get languageSectionHeader => '語言';

  @override
  String get languageSystem => '跟隨系統';

  @override
  String get languageSystemSubtitle => '使用裝置語言';

  @override
  String get languageInstantNote => '語言變更會立即生效。';

  @override
  String languageNoMatches(String query) {
    return '沒有符合「$query」的語言。';
  }

  @override
  String get contactTitle => '聯絡我們';

  @override
  String get contactHeroTitle => '需要什麼協助？';

  @override
  String contactHeroSubtitle(String appName) {
    return '選擇你想聯絡 $appName 團隊的方式。';
  }

  @override
  String get contactSectionOptions => '聯絡方式';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => '與我們的支援團隊聊天';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => '在 Telegram 上傳訊息給我們';

  @override
  String get contactEmail => '電郵';

  @override
  String get contactEmailSubtitle => '寄電郵給我們';

  @override
  String get contactResponseTime => '回覆時間';

  @override
  String get contactResponseTimeValue => '我們通常在 1–2 個工作日內回覆。';

  @override
  String get contactPrivacyNote => '我們僅將你的訊息用於提供支援。';

  @override
  String contactNoMailApp(String email) {
    return '無法開啟郵件應用程式。請改寄至 $email。';
  }

  @override
  String get contactWhatsAppFailed => '無法開啟 WhatsApp。';

  @override
  String get contactTelegramFailed => '無法開啟 Telegram。';

  @override
  String get contactPlayStoreFailed => '無法開啟 Play 商店。';

  @override
  String contactLegalOpenFailed(String document) {
    return '無法開啟$document。';
  }

  @override
  String get commonCancel => '取消';

  @override
  String get commonOk => '確定';

  @override
  String get commonNotNow => '暫不';

  @override
  String get commonClose => '關閉';

  @override
  String get commonMore => '更多';

  @override
  String get commonFailureTitle => '無法完成';

  @override
  String get homePrivateSpaceTitle => '私密空間';

  @override
  String get homeSubtitle => '你的私密空間';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個隱藏的應用程式',
      zero: '沒有隱藏的應用程式',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => '鎖定並關閉';

  @override
  String get homeMenuSettings => '設定';

  @override
  String get homeMenuDeveloperTools => '開發者工具';

  @override
  String get homeAddApp => '新增應用程式';

  @override
  String get homeEmptyTitle => '你的空間是空的';

  @override
  String get homeEmptyMessage => '新增一個應用程式，建立你的第一個私有執行個體。';

  @override
  String get homeEmptyAction => '新增第一個應用程式';

  @override
  String get homePrivateEmptyTitle => '還沒有隱藏任何內容';

  @override
  String get homePrivateEmptyMessage => '在主格線中長按任一應用程式並選擇「隱藏」，就能把它移到這裡。';

  @override
  String get homeSetUpPrivateSpaceTitle => '設定私密空間？';

  @override
  String get homeSetUpPrivateSpaceMessage => '隱藏分身需要私密空間。請先用 PIN 碼建立一個。';

  @override
  String get homeSetUpPrivateSpaceConfirm => '設定';

  @override
  String get homeEngineInactive => '本裝置上的虛擬化引擎未啟用，因此分身無法在隔離容器中執行。';

  @override
  String get homeEngineUnavailable => '本裝置上無法使用虛擬化引擎。';

  @override
  String cloneSpaceLabel(int index) {
    return '空間 $index';
  }

  @override
  String get cloneActionsManage => '管理';

  @override
  String get cloneActionUninstall => '解除安裝';

  @override
  String get cloneActionClone => '複製';

  @override
  String get cloneActionShortcut => '捷徑';

  @override
  String get cloneActionSpaceInfo => '空間資訊';

  @override
  String get cloneActionEditName => '編輯名稱';

  @override
  String get cloneActionForceStop => '強制停止';

  @override
  String get cloneActionClearCache => '清除快取';

  @override
  String get cloneActionClearStorage => '清除資料';

  @override
  String get cloneActionHide => '隱藏';

  @override
  String get cloneActionUnhide => '取消隱藏';

  @override
  String get cloneActionShareApp => '分享應用程式';

  @override
  String get cloneActionPermissions => '權限';

  @override
  String get cloneActionInstallGoogleServices => '安裝 Google 服務';

  @override
  String cloneTileSibling(int index, int count) {
    return '，第 $index 個分身，共 $count 個';
  }

  @override
  String get cloneTileOpening => '，正在開啟';

  @override
  String get cloneTileRunning => '，正在執行';

  @override
  String get cloneTileCannotLaunch => '，無法在本裝置上啟動';

  @override
  String get cloneForceStopTitle => '強制停止這個應用程式？';

  @override
  String get cloneForceStopMessage => '在你再次開啟之前，應用程式會停止執行。';

  @override
  String get cloneForceStopConfirm => '強制停止';

  @override
  String get cloneClearCacheTitle => '清除應用程式快取？';

  @override
  String get cloneClearCacheMessage => '這會刪除這個分身的暫存檔。';

  @override
  String get cloneClearCacheConfirm => '清除快取';

  @override
  String get cloneClearStorageTitle => '清除應用程式資料？';

  @override
  String get cloneClearStorageMessage => '這會永久刪除這個分身的帳號、設定與本機資料。';

  @override
  String get cloneClearStorageConfirm => '清除資料';

  @override
  String get cloneInstallGoogleServicesTitle => '安裝 Google 服務？';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName 會把 Google Play 服務安裝到這個分身中。分身的資料會保留。這可能需要幾秒鐘。';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => '安裝';

  @override
  String cloneStopped(String name) {
    return '已停止 $name。';
  }

  @override
  String cloneCacheCleared(String name) {
    return '已清除 $name 的快取。';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name 已重設。下次啟動會是首次啟動。';
  }

  @override
  String cloneHidden(String name) {
    return '$name 已隱藏到私密空間。';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name 已回到主格線。';
  }

  @override
  String get cloneShortcutAdded => '請在主畫面上確認捷徑，以完成新增。';

  @override
  String get cloneGoogleServicesInstalling => '正在安裝 Google 服務…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return '已在 $name 中安裝 Google 服務。';
  }

  @override
  String get cloneCountTitle => '複製應用程式';

  @override
  String cloneCountMessage(String appName) {
    return '再建立幾個 $appName 的副本。';
  }

  @override
  String get cloneCountLabel => '分身數量';

  @override
  String get cloneCountDecrease => '減少一個';

  @override
  String get cloneCountIncrease => '增加一個';

  @override
  String get cloneCountConfirm => '複製';

  @override
  String cloneCreating(int created, int total) {
    return '正在建立第 $created 個，共 $total 個…';
  }

  @override
  String get cloneCreatingFinishing => '正在收尾…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已再新增 $count 個 $appName 副本。',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return '已建立 $created 個，共 $total 個。$failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return '請選擇 1 到 $maximum';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return '僅剩 $free 可用空間，而裝置會保留半個 GB。';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return '最多 $maximum 個 — 還剩 $free 空間';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return '在 $memory 記憶體的裝置上，一次最多 $maximum 個';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return '沒有空間再建立一個 $appName 分身。$reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return '空間不足，無法再建立 $count 個 $appName 分身。$reason。';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return '權限 · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => '無法讀取權限';

  @override
  String get clonePermissionsEmptyTitle => '沒有可限制的項目';

  @override
  String get clonePermissionsEmptyMessage => '這個應用程式未宣告危險權限，因此這個分身沒有可允許或拒絕的項目。';

  @override
  String clonePermissionsNote(String appName) {
    return '這些設定只對這個分身生效。被複製的應用程式通常會在使用權限前詢問，而這裡限制的正是那個答案——略過詢問的應用程式，仍可能透過 $appName 本身的授權存取硬體。';
  }

  @override
  String get spaceInfoTitle => '空間資訊';

  @override
  String get spaceInfoIdentifiers => '裝置識別碼';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => '引擎無法使用';

  @override
  String get spaceInfoStateRunning => '正在執行';

  @override
  String get spaceInfoStateActive => '已啟用';

  @override
  String get spaceInfoStateRebuilds => '啟動時重建';

  @override
  String get spaceInfoNoContainer => '這個空間還沒有容器，因此也沒有識別碼。啟動一次後它們就會出現在這裡。';

  @override
  String get spaceInfoDeviceId => '裝置 ID';

  @override
  String get spaceInfoAndroidId => 'Android ID';

  @override
  String get spaceInfoSerialNumber => '序號';

  @override
  String get spaceInfoWifiMac => 'Wi-Fi MAC';

  @override
  String get spaceInfoBluetoothMac => '藍牙 MAC';

  @override
  String spaceInfoCopy(String label) {
    return '複製$label';
  }

  @override
  String spaceInfoCopied(String label) {
    return '已複製$label。';
  }

  @override
  String get commonBack => '返回';

  @override
  String get commonApply => '套用';

  @override
  String get pickerTitle => '新增應用程式';

  @override
  String get pickerSearchHint => '搜尋應用程式';

  @override
  String get pickerFilterTooltip => '篩選與排序';

  @override
  String get pickerErrorTitle => '無法列出應用程式';

  @override
  String get pickerNoMatchesTitle => '沒有符合的應用程式';

  @override
  String get pickerNoMatchesMessage => '換個關鍵字搜尋，或改為匯入 APK。';

  @override
  String get pickerPopular => '熱門';

  @override
  String get pickerQuickPicks => '快速選擇';

  @override
  String get pickerInstalledApps => '已安裝的應用程式';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個應用程式',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => '系統';

  @override
  String get pickerCannotClone => '這個應用程式無法在本裝置上複製。';

  @override
  String get pickerApkUnreadable => '無法讀取所選的 APK。';

  @override
  String get filterTitle => '篩選與排序';

  @override
  String get filterSort => '排序';

  @override
  String get filterSortName => '應用程式名稱';

  @override
  String get filterSortRecentlyInstalled => '最近安裝';

  @override
  String get filterSortRecentlyUpdated => '最近更新';

  @override
  String get filterFilter => '篩選';

  @override
  String get filterAllApps => '全部應用程式';

  @override
  String get filterUserApps => '使用者應用程式';

  @override
  String get filterSystemApps => '系統應用程式';

  @override
  String get filterNotAdded => '未新增';

  @override
  String get filterAlreadyAdded => '已新增';

  @override
  String get filterArchitecture => '架構';

  @override
  String get filterArch64 => '64 位元';

  @override
  String get filterArch32 => '32 位元';

  @override
  String get filterArchNoNativeCode => '無原生程式碼';

  @override
  String get filterPackageType => '套件類型';

  @override
  String get filterPackageSingle => '單一 APK';

  @override
  String get filterPackageSplit => '分割 APK';

  @override
  String filterImportApk(String appName) {
    return '開啟 $appName 應用程式套件';
  }

  @override
  String get appSheetAddClone => '新增分身';

  @override
  String get appSheetAddAnother => '再新增一個';

  @override
  String get appSheetShareApp => '分享應用程式';

  @override
  String get appSheetAppDetails => '應用程式詳細資料';

  @override
  String get appDetailsTitle => '應用程式詳細資料';

  @override
  String get appDetailsAdvanced => '進階詳細資料';

  @override
  String get appDetailsPackageName => '套件名稱';

  @override
  String get appDetailsVersion => '版本';

  @override
  String get appDetailsArchitecture => '架構';

  @override
  String get appDetailsBitness => '位元寬度';

  @override
  String get appDetailsPackageType => '套件類型';

  @override
  String get appDetailsApkComponents => 'APK 元件';

  @override
  String get appDetailsTotalApkSize => 'APK 總大小';

  @override
  String get appDetailsSigningSha256 => '簽署憑證 SHA-256';

  @override
  String get appDetailsSigningUnreadable => '無法讀取';

  @override
  String get appDetailsNoApkFiles => '套件管理員未回報這個應用程式的任何 APK 檔案。';

  @override
  String get findingAppNotFound => '這個應用程式未安裝在裝置上。';

  @override
  String get findingSecureEnvRequired => '這個應用程式需要安全環境，無法被虛擬化。';

  @override
  String findingSelfClone(String appName) {
    return '$appName 無法複製自己。';
  }

  @override
  String get findingSystemComponent => '系統元件無法被複製。';

  @override
  String get findingAbiNotSupported => '這個應用程式的原生程式庫並非為引擎支援的架構建置。';

  @override
  String findingStorageUnavailable(String appName) {
    return '這個應用程式使用共用儲存空間，而目前這個 $appName 版本沒有宣告「所有檔案存取權」。它的分身無法存取你的檔案，也無法正常運作。';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return '這個應用程式使用共用儲存空間。請在啟動分身前，於「設定 → 特殊應用程式存取權」中授予 $appName「所有檔案存取權」，否則分身可能在啟動時被拒絕。';
  }

  @override
  String get factsNoNativeCode => '無原生程式碼';

  @override
  String get factsAnyNoNativeCode => '任意 — 無原生程式碼';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => '單一 APK';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '分割 APK · $count 個檔案',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => '未知';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => '透過檔案管理員匯入';

  @override
  String get commonSave => '儲存';

  @override
  String get renameTitle => '重新命名設定檔';

  @override
  String get renameFieldLabel => '設定檔名稱';

  @override
  String get uninstallTitle => '解除安裝這個分身？';

  @override
  String uninstallSpaceOf(int index, int count) {
    return '空間 $index，共 $count 個';
  }

  @override
  String get uninstallMessage => '這會移除所選的應用程式執行個體及其本機資料。';

  @override
  String get uninstallConfirm => '解除安裝';

  @override
  String get calculatorError => '錯誤';

  @override
  String get disclosureTitle => '開始之前';

  @override
  String disclosureIntro(String appName) {
    return '$appName 會執行你所選應用程式的第二份副本。以下正是它讀取的內容，以及它會向你請求的權限。';
  }

  @override
  String get disclosureAppsTitle => '你已安裝的應用程式';

  @override
  String disclosureAppsBody(String appName) {
    return '為了顯示分身選擇清單，$appName 會讀取本裝置上已安裝的應用程式清單——它們的名稱、圖示與版本。該清單只保留在你的裝置上，絕不會上傳、販售或分享，而且本應用程式沒有廣告、沒有分析統計、沒有追蹤器。';
  }

  @override
  String get disclosurePermissionsTitle => '代表分身的權限';

  @override
  String disclosurePermissionsBody(String appName) {
    return '被複製的應用程式在 $appName 內部執行，因此部分 Android 權限會代表它們套用到 $appName 上。你可能會被請求一次，把它從電池最佳化中排除，讓複製的通訊應用程式持續收發訊息。只有在複製檔案或媒體類應用程式時，你才可能需要在設定中授予「所有檔案存取權」。';
  }

  @override
  String get disclosureControlTitle => '主導權在你手上';

  @override
  String get disclosureControlBody =>
      '沒有任何請求是悄悄進行的。你可以拒絕其中任何一項，仍然正常使用本應用程式，也可以隨時在 Android 設定中改變主意。';

  @override
  String get disclosureAccept => '同意並繼續';

  @override
  String get privateSpaceTitle => '私密空間';

  @override
  String get privateSpaceOffTitle => '私密空間已關閉';

  @override
  String get privateSpaceOffMessage =>
      '開啟後即可用 PIN 碼把分身藏起來。隱藏的應用程式會從主格線中消失，只能在這裡開啟。';

  @override
  String get privateSpaceSetUp => '設定私密空間';

  @override
  String get privateSpaceChangePin => '變更 PIN 碼';

  @override
  String get privateSpaceUnlockSection => '解鎖';

  @override
  String get privateSpaceFingerprint => '使用指紋解鎖';

  @override
  String get privateSpaceFingerprintAvailable => '你仍可隨時使用 PIN 碼。';

  @override
  String get privateSpaceFingerprintUnavailable => '本裝置未設定指紋或臉部。';

  @override
  String get privateSpaceDisguiseSection => '偽裝';

  @override
  String get privateSpaceDisguiseAsCalculator => '偽裝成計數機';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return '把 $appName 的圖示換成計數機。輸入私密空間 PIN 碼並按 = 即可開啟應用程式。';
  }

  @override
  String get privateSpaceTurnOff => '關閉私密空間';

  @override
  String get privateSpaceTurnOffNote => '關閉後，所有隱藏的應用程式都會回到主格線。分身本身不會被刪除。';

  @override
  String get privateSpaceDisguiseOnTitle => '偽裝成計數機？';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return '重新顯示 $appName？';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return '$appName 的圖示會被換成名為「Calculator」的計數機。要開啟 $appName，請輸入私密空間 PIN 碼並按 =。若忘記 PIN 碼，你將無法開啟本應用程式。';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName 會在主畫面上重新顯示自己的圖示與名稱。';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => '偽裝';

  @override
  String get privateSpaceDisguiseConfirmOff => '顯示應用程式';

  @override
  String get privateSpaceDisguiseFailed => '無法變更應用程式的外觀。';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '$appName 現在在你的主畫面上看起來像一部計數機。';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName 已回到你的主畫面。';
  }

  @override
  String get privateSpaceTurnOffTitle => '關閉私密空間？';

  @override
  String get privateSpaceTurnOffMessage => '所有隱藏的應用程式都會回到主格線，PIN 碼也會被清除。分身會保留。';

  @override
  String get privateSpaceTurnOffConfirm => '關閉';

  @override
  String get privateSpaceTurnedOff => '已關閉私密空間。';

  @override
  String get pinCreateTitle => '建立 PIN 碼';

  @override
  String get pinChangeTitle => '變更 PIN 碼';

  @override
  String get pinCreateMessage => '這組 PIN 碼用來鎖定私密空間。請記在不會忘記的地方：沒有它就無法找回被隱藏的分身。';

  @override
  String get pinChangeMessage => '先輸入目前的 PIN 碼，再選擇新的。';

  @override
  String get pinCurrentLabel => '目前的 PIN 碼';

  @override
  String get pinNewLabel => '新的 PIN 碼';

  @override
  String get pinConfirmLabel => '確認 PIN 碼';

  @override
  String get pinCreateConfirm => '建立私密空間';

  @override
  String get pinSaveConfirm => '儲存 PIN 碼';

  @override
  String pinLengthError(int minimum, int maximum) {
    return '請使用 $minimum 到 $maximum 位數字。';
  }

  @override
  String get pinMismatchError => '兩次輸入的 PIN 碼不一致。';

  @override
  String get pinCurrentIncorrect => '目前的 PIN 碼不正確。';

  @override
  String get unlockTitle => '解鎖私密空間';

  @override
  String get unlockPinLabel => 'PIN 碼';

  @override
  String get unlockUseFingerprint => '使用指紋';

  @override
  String get unlockConfirm => '解鎖';

  @override
  String get unlockIncorrectPin => 'PIN 碼不正確';

  @override
  String get unlockFingerprintUnavailable => '指紋解鎖目前無法使用。';

  @override
  String get unlockFingerprintNotRecognised => '未能辨識指紋。';

  @override
  String get unlockBiometricReason => '解鎖你的私密空間';

  @override
  String get privateTileEmpty => '私密空間，空';

  @override
  String privateTileHidden(int count) {
    return '私密空間，已隱藏 $count 個';
  }

  @override
  String get settingsSectionPrivacy => '隱私';

  @override
  String get settingsPrivateSpaceSubtitle => '用 PIN 碼把應用程式藏起來';

  @override
  String get settingsOn => '已開啟';

  @override
  String get settingsOff => '已關閉';

  @override
  String get componentBaseApk => '基礎 APK';

  @override
  String get componentSplitApk => '分割 APK';

  @override
  String get componentNoNativeLibraries => '無原生程式庫';

  @override
  String get errorProfileNameEmpty => '分身需要一個名稱。';

  @override
  String errorProfileNameTooLong(int maximum) {
    return '分身名稱最多 $maximum 個字元。';
  }

  @override
  String get errorProfileStorageUnreadable => '無法讀取你儲存的分身。';

  @override
  String get errorProfileNotFound => '該分身已不存在。';

  @override
  String get errorBridgeFailed => '與管理分身的那部分應用程式通訊時發生錯誤。';

  @override
  String get errorBridgeUnsupportedPlatform => '此功能僅在 Android 上可用。';

  @override
  String get errorTestAppCheckFailed => '無法檢查測試應用程式是否已安裝。';

  @override
  String get errorEngineInitFailed => '虛擬化引擎無法在本裝置上啟動。';

  @override
  String get errorEngineAndroidTooOld => '虛擬化引擎需要更新版本的 Android。';

  @override
  String get errorEngineNoResponse => '虛擬化引擎沒有回應，請再試一次。';

  @override
  String get errorNoContainer => '此分身還沒有容器。先開啟一次再重試。';

  @override
  String get errorLaunchRefused => '引擎拒絕開啟此分身。';

  @override
  String get errorAlreadyCloned => '此應用程式已經複製過了。';

  @override
  String get errorClearCacheFailed => '此分身的部分快取無法刪除。';

  @override
  String get errorClearDataFailed => '無法清除此分身的資料。';

  @override
  String get errorShortcutsUnsupported => '此啟動器不支援新增捷徑。';

  @override
  String get errorShortcutRefused => '啟動器拒絕了該捷徑。';

  @override
  String get errorApkGone => '此分身的 APK 已不在裝置上，因此沒有可分享的內容。';

  @override
  String get errorShareFailed => '無法分享該應用程式。';

  @override
  String get errorApkUnreadable => '無法讀取所選 APK 其中之一。';

  @override
  String get errorApkPackageMismatch => '所選的 APK 必須屬於同一個應用程式。';

  @override
  String get errorApkVersionMismatch => '所選的 APK 必須是同一版本。';

  @override
  String get errorApkBaseRequired => '請選擇剛好一個基礎 APK 和一個或多個設定分割包。';

  @override
  String get errorApkDuplicateSplit => '同一個 APK 分割包被選擇了多次。';
}
