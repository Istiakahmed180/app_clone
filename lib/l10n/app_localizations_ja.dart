// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSectionSupport => 'サポート';

  @override
  String get settingsSectionLegal => '法的情報';

  @override
  String get settingsSectionAbout => 'アプリについて';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsAppearance => '外観';

  @override
  String get settingsContact => 'お問い合わせ';

  @override
  String get settingsContactSubtitle => 'ご質問・ご意見';

  @override
  String get settingsRate => '評価する';

  @override
  String settingsRateSubtitle(String appName) {
    return '$appName は気に入りましたか？レビューを書く';
  }

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsTermsOfService => '利用規約';

  @override
  String get settingsVersion => 'バージョン';

  @override
  String get settingsArchitecture => '端末のアーキテクチャ';

  @override
  String get settingsArchitectureSubtitle => 'アプリの互換性';

  @override
  String get settingsBits64 => '64ビット';

  @override
  String get settingsBits32 => '32ビット';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width・$abi';
  }

  @override
  String get settingsSupportedAbis => '対応 ABI';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => '未公開';

  @override
  String get settingsNotListedYet => 'ストア未掲載';

  @override
  String get settingsNotSetUpYet => '未設定';

  @override
  String get commonUnavailable => '取得できません';

  @override
  String get appearanceTitle => '外観';

  @override
  String get appearancePreview => 'プレビュー';

  @override
  String get appearanceChooseTheme => 'テーマを選択';

  @override
  String get appearanceSystem => 'システムのデフォルト';

  @override
  String get appearanceSystemSubtitle => '端末の設定に合わせる';

  @override
  String get appearanceLight => 'ライト';

  @override
  String get appearanceLightSubtitle => '常にライトテーマ';

  @override
  String get appearanceDark => 'ダーク';

  @override
  String get appearanceDarkSubtitle => '常にダークテーマ';

  @override
  String appearanceInstantNote(String appName) {
    return 'テーマの変更は $appName 全体にすぐ反映されます。';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return '$themeテーマのプレビュー';
  }

  @override
  String get languageTitle => '言語';

  @override
  String get languageSearchHint => '言語を検索';

  @override
  String get languageClearSearch => '検索をクリア';

  @override
  String languageNote(String appName) {
    return '$appName で使用する言語を選択します。';
  }

  @override
  String get languageSectionHeader => '言語';

  @override
  String get languageSystem => 'システムのデフォルト';

  @override
  String get languageSystemSubtitle => '端末の言語を使用';

  @override
  String get languageInstantNote => '言語の変更はすぐに反映されます。';

  @override
  String languageNoMatches(String query) {
    return '「$query」に一致する言語はありません。';
  }

  @override
  String get contactTitle => 'お問い合わせ';

  @override
  String get contactHeroTitle => 'どうされましたか？';

  @override
  String contactHeroSubtitle(String appName) {
    return '$appName チームへの連絡方法をお選びください。';
  }

  @override
  String get contactSectionOptions => '連絡方法';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'サポートチームとチャット';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Telegram でメッセージを送る';

  @override
  String get contactEmail => 'メール';

  @override
  String get contactEmailSubtitle => 'メールを送る';

  @override
  String get contactResponseTime => '返信までの目安';

  @override
  String get contactResponseTimeValue => '通常 1〜2 営業日以内に返信します。';

  @override
  String get contactPrivacyNote => 'いただいたメッセージはサポートのためにのみ使用します。';

  @override
  String contactNoMailApp(String email) {
    return 'メールアプリを開けませんでした。代わりに $email までご連絡ください。';
  }

  @override
  String get contactWhatsAppFailed => 'WhatsApp を開けませんでした。';

  @override
  String get contactTelegramFailed => 'Telegram を開けませんでした。';

  @override
  String get contactPlayStoreFailed => 'Play ストアを開けませんでした。';

  @override
  String contactLegalOpenFailed(String document) {
    return '$document を開けませんでした。';
  }
}
