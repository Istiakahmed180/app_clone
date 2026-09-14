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
  String get settingsSectionDelivery => '推送';

  @override
  String get settingsBackgroundActivity => '后台活动';

  @override
  String get settingsBackgroundActivitySubtitle => '让克隆的应用在关闭后仍能收到通知';

  @override
  String get settingsBackgroundActivityAllowed => '已允许';

  @override
  String get settingsBackgroundActivityRestricted => '已限制';

  @override
  String get settingsBackgroundActivityCheck => '检查';

  @override
  String get backgroundGuideTitle => '后台活动';

  @override
  String get backgroundGuideWhy =>
      'Android 可能会在后台暂停 Duplika；此时克隆的应用将收不到通知，直到你再次打开 Duplika。';

  @override
  String get backgroundGuideStepsOem => '在“应用信息”中点按“电池使用情况”，然后开启“允许后台活动”。';

  @override
  String get backgroundGuideStepsStock => '在打开的系统询问中点按“允许”，让它可以在后台运行。';

  @override
  String get backgroundGuideStepsUnknown => '在“应用信息”中允许后台活动。';

  @override
  String get backgroundGuideOpenAppInfo => '打开应用信息';

  @override
  String get backgroundGuideAllow => '允许';

  @override
  String get backgroundGuideLater => '以后再说';

  @override
  String get settingsBackgroundActivityFix => '点按此处并允许后台活动';

  @override
  String get settingsBackgroundActivityFixBatteryUsage =>
      '点按此处，然后进入“电池使用情况”，再允许后台活动';

  @override
  String get settingsBackgroundActivityFailed => '无法打开后台活动设置。';

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
  String get settingsSectionDelivery => '推送';

  @override
  String get settingsBackgroundActivity => '后台活动';

  @override
  String get settingsBackgroundActivitySubtitle => '让克隆的应用在关闭后仍能收到通知';

  @override
  String get settingsBackgroundActivityAllowed => '已允许';

  @override
  String get settingsBackgroundActivityRestricted => '已限制';

  @override
  String get settingsBackgroundActivityCheck => '检查';

  @override
  String get backgroundGuideTitle => '后台活动';

  @override
  String get backgroundGuideWhy =>
      'Android 可能会在后台暂停 Duplika；此时克隆的应用将收不到通知，直到你再次打开 Duplika。';

  @override
  String get backgroundGuideStepsOem => '在“应用信息”中点按“电池使用情况”，然后开启“允许后台活动”。';

  @override
  String get backgroundGuideStepsStock => '在打开的系统询问中点按“允许”，让它可以在后台运行。';

  @override
  String get backgroundGuideStepsUnknown => '在“应用信息”中允许后台活动。';

  @override
  String get backgroundGuideOpenAppInfo => '打开应用信息';

  @override
  String get backgroundGuideAllow => '允许';

  @override
  String get backgroundGuideLater => '以后再说';

  @override
  String get settingsBackgroundActivityFix => '点按此处并允许后台活动';

  @override
  String get settingsBackgroundActivityFixBatteryUsage =>
      '点按此处，然后进入“电池使用情况”，再允许后台活动';

  @override
  String get settingsBackgroundActivityFailed => '无法打开后台活动设置。';

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
  String get settingsSectionDelivery => '推送';

  @override
  String get settingsBackgroundActivity => '背景活動';

  @override
  String get settingsBackgroundActivitySubtitle => '讓複製的應用程式在關閉後仍能收到通知';

  @override
  String get settingsBackgroundActivityAllowed => '已允許';

  @override
  String get settingsBackgroundActivityRestricted => '已限制';

  @override
  String get settingsBackgroundActivityCheck => '檢查';

  @override
  String get backgroundGuideTitle => '背景活動';

  @override
  String get backgroundGuideWhy =>
      'Android 可能會在背景暫停 Duplika；此時複製的應用程式將收不到通知，直到你再次開啟 Duplika。';

  @override
  String get backgroundGuideStepsOem => '在「應用程式資訊」中點一下「電池使用情況」，然後開啟「允許背景活動」。';

  @override
  String get backgroundGuideStepsStock => '在開啟的系統詢問中點一下「允許」，讓它可以在背景運行。';

  @override
  String get backgroundGuideStepsUnknown => '在「應用程式資訊」中允許背景活動。';

  @override
  String get backgroundGuideOpenAppInfo => '開啟應用程式資訊';

  @override
  String get backgroundGuideAllow => '允許';

  @override
  String get backgroundGuideLater => '稍後';

  @override
  String get settingsBackgroundActivityFix => '點此並允許背景活動';

  @override
  String get settingsBackgroundActivityFixBatteryUsage =>
      '點此，然後「電池使用情況」，再允許背景活動';

  @override
  String get settingsBackgroundActivityFailed => '無法開啟背景活動設定。';

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
  String get settingsSectionDelivery => '推送';

  @override
  String get settingsBackgroundActivity => '背景活動';

  @override
  String get settingsBackgroundActivitySubtitle => '讓複製的應用程式在關閉後仍能收到通知';

  @override
  String get settingsBackgroundActivityAllowed => '已允許';

  @override
  String get settingsBackgroundActivityRestricted => '已限制';

  @override
  String get settingsBackgroundActivityCheck => '檢查';

  @override
  String get backgroundGuideTitle => '背景活動';

  @override
  String get backgroundGuideWhy =>
      'Android 可能會在背景暫停 Duplika；此時複製的應用程式將收不到通知，直到你再次開啟 Duplika。';

  @override
  String get backgroundGuideStepsOem => '在「應用程式資訊」中點一下「電池使用情況」，然後開啟「允許背景活動」。';

  @override
  String get backgroundGuideStepsStock => '在開啟的系統詢問中點一下「允許」，讓它可以在背景運行。';

  @override
  String get backgroundGuideStepsUnknown => '在「應用程式資訊」中允許背景活動。';

  @override
  String get backgroundGuideOpenAppInfo => '開啟應用程式資訊';

  @override
  String get backgroundGuideAllow => '允許';

  @override
  String get backgroundGuideLater => '稍後';

  @override
  String get settingsBackgroundActivityFix => '點此並允許背景活動';

  @override
  String get settingsBackgroundActivityFixBatteryUsage =>
      '點此，然後「電池使用情況」，再允許背景活動';

  @override
  String get settingsBackgroundActivityFailed => '無法開啟背景活動設定。';

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
}
