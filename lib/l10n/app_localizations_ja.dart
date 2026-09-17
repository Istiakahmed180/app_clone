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

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNotNow => '後で';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonMore => 'その他';

  @override
  String get commonFailureTitle => '実行できませんでした';

  @override
  String get homePrivateSpaceTitle => 'プライベートスペース';

  @override
  String get homeSubtitle => 'あなたのプライベートスペース';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '非表示のアプリ $count 件',
      zero: '非表示のアプリはありません',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => 'ロックして閉じる';

  @override
  String get homeMenuSettings => '設定';

  @override
  String get homeMenuDeveloperTools => '開発者ツール';

  @override
  String get homeAddApp => 'アプリを追加';

  @override
  String get homeEmptyTitle => 'スペースは空です';

  @override
  String get homeEmptyMessage => 'アプリを追加して、最初のプライベートインスタンスを作成しましょう。';

  @override
  String get homeEmptyAction => '最初のアプリを追加';

  @override
  String get homePrivateEmptyTitle => 'まだ何も隠していません';

  @override
  String get homePrivateEmptyMessage => 'メイングリッドのアプリを長押しして「非表示」を選ぶと、ここに移動します。';

  @override
  String get homeSetUpPrivateSpaceTitle => 'プライベートスペースを設定しますか？';

  @override
  String get homeSetUpPrivateSpaceMessage =>
      'クローンを隠すにはプライベートスペースが必要です。まず PIN で作成してください。';

  @override
  String get homeSetUpPrivateSpaceConfirm => '設定';

  @override
  String get homeEngineInactive =>
      'このデバイスでは仮想化エンジンが有効でないため、クローンを分離コンテナで実行できません。';

  @override
  String get homeEngineUnavailable => 'このデバイスでは仮想化エンジンを利用できません。';

  @override
  String cloneSpaceLabel(int index) {
    return 'スペース $index';
  }

  @override
  String get cloneActionsManage => '管理';

  @override
  String get cloneActionUninstall => 'アンインストール';

  @override
  String get cloneActionClone => 'クローン';

  @override
  String get cloneActionShortcut => 'ショートカット';

  @override
  String get cloneActionSpaceInfo => 'スペース情報';

  @override
  String get cloneActionEditName => '名前を編集';

  @override
  String get cloneActionChangeIcon => 'アイコンを変更';

  @override
  String get cloneIconPickerChoose => '画像を選ぶ';

  @override
  String get cloneIconPickerUseAppIcon => 'アプリのアイコンを使う';

  @override
  String get errorCloneIconFailed => 'その画像はアイコンとして使えませんでした。別の画像をお試しください。';

  @override
  String get errorCloneDeleteFailed => 'このクローンを削除できませんでした。もう一度お試しください。';

  @override
  String get cloneIconPickerTitle => 'このクローンのアイコン';

  @override
  String get cloneIconPickerMessage =>
      '好きな画像を設定するか、アプリのアイコンのまま色で印を付けられます。どちらでも、同じアプリの他のクローンとひと目で見分けられます。';

  @override
  String get cloneIconColorRed => '赤';

  @override
  String get cloneIconColorOrange => 'オレンジ';

  @override
  String get cloneIconColorAmber => '琥珀色';

  @override
  String get cloneIconColorGreen => '緑';

  @override
  String get cloneIconColorTeal => 'ティール';

  @override
  String get cloneIconColorBlue => '青';

  @override
  String get cloneIconColorViolet => '紫';

  @override
  String get cloneIconColorPink => 'ピンク';

  @override
  String get cloneIconColorNone => '色なし';

  @override
  String get cloneActionForceStop => '強制停止';

  @override
  String get cloneActionClearCache => 'キャッシュを削除';

  @override
  String get cloneActionClearStorage => 'データを削除';

  @override
  String get cloneActionHide => '非表示';

  @override
  String get cloneActionUnhide => '再表示';

  @override
  String get cloneActionShareApp => 'アプリを共有';

  @override
  String get cloneActionPermissions => '権限';

  @override
  String get cloneActionInstallGoogleServices => 'Google サービスをインストール';

  @override
  String cloneTileSibling(int index, int count) {
    return '、$count 個中 $index 番目のクローン';
  }

  @override
  String get cloneTileOpening => '、起動中';

  @override
  String get cloneTileRunning => '、実行中';

  @override
  String cloneTileMark(String color) {
    return '、$color でマーク';
  }

  @override
  String get cloneTileCannotLaunch => '、このデバイスでは起動できません';

  @override
  String get cloneForceStopTitle => 'このアプリを強制停止しますか？';

  @override
  String get cloneForceStopMessage => '次に開くまでアプリは動作を停止します。';

  @override
  String get cloneForceStopConfirm => '強制停止';

  @override
  String get cloneClearCacheTitle => 'アプリのキャッシュを削除しますか？';

  @override
  String get cloneClearCacheMessage => 'このクローンの一時ファイルが削除されます。';

  @override
  String get cloneClearCacheConfirm => 'キャッシュを削除';

  @override
  String get cloneClearStorageTitle => 'アプリのデータを削除しますか？';

  @override
  String get cloneClearStorageMessage => 'このクローンのアカウント、設定、ローカルデータが完全に削除されます。';

  @override
  String get cloneClearStorageConfirm => 'データを削除';

  @override
  String get cloneInstallGoogleServicesTitle => 'Google サービスをインストールしますか？';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName は Google Play サービスをこのクローンにインストールします。クローンのデータは保持されます。数秒かかることがあります。';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => 'インストール';

  @override
  String cloneStopped(String name) {
    return '$name を停止しました。';
  }

  @override
  String cloneCacheCleared(String name) {
    return '$name のキャッシュを削除しました。';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name をリセットしました。次回の起動は初回起動になります。';
  }

  @override
  String cloneHidden(String name) {
    return '$name をプライベートスペースに隠しました。';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name はメイングリッドに戻りました。';
  }

  @override
  String get cloneShortcutAdded => '追加を完了するには、ホーム画面でショートカットを確認してください。';

  @override
  String get cloneGoogleServicesInstalling => 'Google サービスをインストールしています…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return '$name に Google サービスをインストールしました。';
  }

  @override
  String get cloneCountTitle => 'アプリをクローン';

  @override
  String cloneCountMessage(String appName) {
    return '$appName のコピーをさらに作成します。';
  }

  @override
  String get cloneCountLabel => 'クローンの数';

  @override
  String get cloneCountDecrease => '1 つ減らす';

  @override
  String get cloneCountIncrease => '1 つ増やす';

  @override
  String get cloneCountConfirm => 'クローン';

  @override
  String cloneCreating(int created, int total) {
    return '$total 個中 $created 個を作成中…';
  }

  @override
  String get cloneCreatingFinishing => '仕上げ中…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$appName のコピーを $count 個追加しました。',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return '$total 個中 $created 個を作成しました。$failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return '1 〜 $maximum から選択';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return '空きは $free しかなく、デバイスは 0.5 GB を予備に残します。';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return '最大 $maximum — 残り $free';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return 'メモリ $memory のデバイスでは同時に最大 $maximum';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return '$appName のクローンをもう 1 つ作る空きがありません。$reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return '$appName のクローンをあと $count 個作るには空きが足りません。$reason。';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return '権限 · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => '権限を読み取れませんでした';

  @override
  String get clonePermissionsEmptyTitle => '制限する項目はありません';

  @override
  String get clonePermissionsEmptyMessage =>
      'このアプリは危険な権限を宣言していないため、このクローンについて許可または拒否するものはありません。';

  @override
  String clonePermissionsNote(String appName) {
    return 'これはこのクローンにのみ適用されます。クローンされたアプリは通常、権限を使う前に確認しますが、その答えがここで制限されます。確認を省くアプリは、$appName 自身の権限を通じてハードウェアに到達する可能性があります。';
  }

  @override
  String get spaceInfoTitle => 'スペース情報';

  @override
  String get spaceInfoIdentifiers => 'デバイス識別子';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => 'エンジン利用不可';

  @override
  String get spaceInfoStateRunning => '実行中';

  @override
  String get spaceInfoStateActive => '有効';

  @override
  String get spaceInfoStateRebuilds => '起動時に再構築';

  @override
  String get spaceInfoNoContainer =>
      'このスペースにはまだコンテナがないため、識別子もありません。一度起動すると、ここに表示されます。';

  @override
  String get spaceInfoDeviceId => 'デバイス ID';

  @override
  String get spaceInfoAndroidId => 'Android ID';

  @override
  String get spaceInfoSerialNumber => 'シリアル番号';

  @override
  String get spaceInfoWifiMac => 'Wi-Fi MAC';

  @override
  String get spaceInfoBluetoothMac => 'Bluetooth MAC';

  @override
  String spaceInfoCopy(String label) {
    return '$label をコピー';
  }

  @override
  String spaceInfoCopied(String label) {
    return '$label をコピーしました。';
  }

  @override
  String get commonBack => '戻る';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonApply => '適用';

  @override
  String get pickerTitle => 'アプリを追加';

  @override
  String get pickerSearchHint => 'アプリを検索';

  @override
  String get pickerFilterTooltip => '絞り込みと並べ替え';

  @override
  String get pickerErrorTitle => 'アプリを一覧表示できませんでした';

  @override
  String get pickerNoMatchesTitle => '一致するアプリがありません';

  @override
  String get pickerNoMatchesMessage => '別の語で検索するか、APK をインポートしてください。';

  @override
  String get pickerPopular => '人気';

  @override
  String get pickerQuickPicks => 'クイック選択';

  @override
  String get pickerInstalledApps => 'インストール済みアプリ';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個のアプリ',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => 'システム';

  @override
  String get pickerCannotClone => 'このデバイスではこのアプリをクローンできません。';

  @override
  String get pickerCloneInProgress =>
      'A clone is already being created. Wait for it to finish, then try again.';

  @override
  String get pickerApkUnreadable => '選択した APK を読み取れませんでした。';

  @override
  String pickerHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'このデバイスの $count 個のアプリはクローンできないため、一覧に表示されていません',
    );
    return '$_temp0';
  }

  @override
  String get filterTitle => '絞り込みと並べ替え';

  @override
  String get filterSort => '並べ替え';

  @override
  String get filterSortName => 'アプリ名';

  @override
  String get filterSortRecentlyInstalled => '最近インストール';

  @override
  String get filterSortRecentlyUpdated => '最近更新';

  @override
  String get filterFilter => '絞り込み';

  @override
  String get filterAllApps => 'すべてのアプリ';

  @override
  String get filterUserApps => 'ユーザーアプリ';

  @override
  String get filterSystemApps => 'システムアプリ';

  @override
  String get filterNotAdded => '未追加';

  @override
  String get filterAlreadyAdded => '追加済み';

  @override
  String get filterArchitecture => 'アーキテクチャ';

  @override
  String get filterArch64 => '64 ビット';

  @override
  String get filterArch32 => '32 ビット';

  @override
  String get filterArchNoNativeCode => 'ネイティブコードなし';

  @override
  String get filterPackageType => 'パッケージ種別';

  @override
  String get filterPackageSingle => '単一 APK';

  @override
  String get filterPackageSplit => '分割 APK';

  @override
  String filterImportApk(String appName) {
    return '$appName アプリパッケージを開く';
  }

  @override
  String get appSheetAddClone => 'クローンを追加';

  @override
  String get appSheetAddAnother => 'もう 1 つ追加';

  @override
  String get appSheetShareApp => 'アプリを共有';

  @override
  String get appSheetAppDetails => 'アプリの詳細';

  @override
  String get appDetailsTitle => 'アプリの詳細';

  @override
  String get appDetailsAdvanced => '詳細情報';

  @override
  String get appDetailsPackageName => 'パッケージ名';

  @override
  String get appDetailsVersion => 'バージョン';

  @override
  String get appDetailsArchitecture => 'アーキテクチャ';

  @override
  String get appDetailsBitness => 'ビット幅';

  @override
  String get appDetailsPackageType => 'パッケージ種別';

  @override
  String get appDetailsApkComponents => 'APK コンポーネント';

  @override
  String get appDetailsTotalApkSize => 'APK の合計サイズ';

  @override
  String get appDetailsSigningSha256 => '署名証明書の SHA-256';

  @override
  String get appDetailsSigningUnreadable => '読み取れませんでした';

  @override
  String get appDetailsNoApkFiles => 'パッケージマネージャーはこのアプリの APK ファイルを報告しませんでした。';

  @override
  String get findingAppNotFound => 'このアプリケーションはデバイスにインストールされていません。';

  @override
  String get findingSecureEnvRequired => 'このアプリケーションはセキュアな環境を必要とするため、仮想化できません。';

  @override
  String findingSelfClone(String appName) {
    return '$appName は自分自身をクローンできません。';
  }

  @override
  String get findingSystemComponent => 'システムコンポーネントはクローンできません。';

  @override
  String get findingAbiNotSupported =>
      'このアプリのネイティブライブラリは、エンジンが対応するアーキテクチャ向けにビルドされていません。';

  @override
  String get findingAppArchiveUnavailable =>
      'This app\'s installation files are not on the device. It has been archived, or its installation is incomplete.';

  @override
  String findingStorageUnavailable(String appName) {
    return 'このアプリは共有ストレージを使用しますが、この $appName のビルドは「すべてのファイルへのアクセス」を宣言していません。そのクローンはあなたのファイルに到達できず、動作しません。';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return 'このアプリは共有ストレージを使用します。クローンを起動する前に、設定 → 特別なアプリアクセスで $appName に「すべてのファイルへのアクセス」を許可してください。許可しないと起動時に拒否される場合があります。';
  }

  @override
  String get factsNoNativeCode => 'ネイティブコードなし';

  @override
  String get factsAnyNoNativeCode => 'すべて — ネイティブコードなし';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => '単一 APK';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '分割 APK · $count ファイル',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => '不明';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => 'ファイルマネージャーからインポート';

  @override
  String get commonSave => '保存';

  @override
  String get renameTitle => 'プロフィール名を変更';

  @override
  String get renameFieldLabel => 'プロフィール名';

  @override
  String get uninstallTitle => 'このクローンをアンインストールしますか？';

  @override
  String uninstallSpaceOf(int index, int count) {
    return '$count 個中スペース $index';
  }

  @override
  String get uninstallMessage => '選択したアプリのインスタンスとそのローカルデータが削除されます。';

  @override
  String get uninstallConfirm => 'アンインストール';

  @override
  String get calculatorError => 'エラー';

  @override
  String get disclosureTitle => 'はじめる前に';

  @override
  String disclosureIntro(String appName) {
    return '$appName は、選んだアプリの 2 つ目のコピーを実行します。何を読み取り、何をお願いするかをここに正確に記します。';
  }

  @override
  String get disclosureAppsTitle => 'インストール済みのアプリ';

  @override
  String disclosureAppsBody(String appName) {
    return 'クローンの選択画面を表示するため、$appName はこのデバイスにインストールされたアプリの一覧（名前、アイコン、バージョン）を読み取ります。この一覧は端末内にとどまります。アップロード・販売・共有は一切行わず、本アプリには広告も解析もトラッカーもありません。';
  }

  @override
  String get disclosurePermissionsTitle => 'クローンに代わる権限';

  @override
  String disclosurePermissionsBody(String appName) {
    return 'クローンされたアプリは $appName の中で動作するため、一部の Android 権限はクローンに代わって $appName に適用されます。クローンしたメッセンジャーが通知を受け取り続けられるよう、電池の最適化から除外するよう一度だけ求められることがあります。ファイルやメディアのアプリをクローンする場合にかぎり、設定で「すべてのファイルへのアクセス」の許可が必要になることがあります。';
  }

  @override
  String get disclosureControlTitle => '主導権はあなたにあります';

  @override
  String get disclosureControlBody =>
      '黙って要求されるものは何もありません。どの要求も拒否したままアプリを使えますし、Android の設定でいつでも考えを変えられます。';

  @override
  String get disclosureAccept => '同意して続行';

  @override
  String get privateSpaceTitle => 'プライベートスペース';

  @override
  String get privateSpaceOffTitle => 'プライベートスペースはオフです';

  @override
  String get privateSpaceOffMessage =>
      'オンにすると、クローンを PIN の内側に隠せます。隠したアプリはメイングリッドから消え、ここからだけ開けます。';

  @override
  String get privateSpaceSetUp => 'プライベートスペースを設定';

  @override
  String get privateSpaceChangePin => 'PIN を変更';

  @override
  String get privateSpaceUnlockSection => 'ロック解除';

  @override
  String get privateSpaceFingerprint => '指紋でロック解除';

  @override
  String get privateSpaceFingerprintAvailable => 'PIN もいつでも使えます。';

  @override
  String get privateSpaceFingerprintUnavailable => 'このデバイスには指紋も顔も登録されていません。';

  @override
  String get privateSpaceDisguiseSection => '偽装';

  @override
  String get privateSpaceDisguiseAsCalculator => '電卓に偽装';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return '$appName のアイコンを電卓に置き換えます。プライベートスペースの PIN を入力して = を押すとアプリが開きます。';
  }

  @override
  String get privateSpaceTurnOff => 'プライベートスペースをオフにする';

  @override
  String get privateSpaceTurnOffNote =>
      'オフにすると、隠していたアプリはすべてメイングリッドに戻ります。クローン自体は削除されません。';

  @override
  String get privateSpaceDisguiseOnTitle => '電卓に偽装しますか？';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return '$appName を再表示しますか？';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return '$appName のアイコンは「Calculator」という名前の電卓に置き換わります。$appName を開くには、プライベートスペースの PIN を入力して = を押してください。PIN を忘れるとアプリを開けなくなります。';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName はホーム画面で元のアイコンと名前を再び表示します。';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => '偽装';

  @override
  String get privateSpaceDisguiseConfirmOff => 'アプリを表示';

  @override
  String get privateSpaceDisguiseFailed => 'アプリの見た目を変更できませんでした。';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '$appName はホーム画面で電卓のように表示されるようになりました。';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName がホーム画面に戻りました。';
  }

  @override
  String get privateSpaceTurnOffTitle => 'プライベートスペースをオフにしますか？';

  @override
  String get privateSpaceTurnOffMessage =>
      '隠していたアプリはすべてメイングリッドに戻り、PIN は破棄されます。クローンは保持されます。';

  @override
  String get privateSpaceTurnOffConfirm => 'オフにする';

  @override
  String get privateSpaceTurnedOff => 'プライベートスペースをオフにしました。';

  @override
  String get pinCreateTitle => 'PIN を作成';

  @override
  String get pinChangeTitle => 'PIN を変更';

  @override
  String get pinCreateMessage =>
      'この PIN でプライベートスペースをロックします。忘れない場所に控えてください。PIN なしで隠したクローンを復元する方法はありません。';

  @override
  String get pinChangeMessage => '現在の PIN を入力し、新しい PIN を選んでください。';

  @override
  String get pinCurrentLabel => '現在の PIN';

  @override
  String get pinNewLabel => '新しい PIN';

  @override
  String get pinConfirmLabel => 'PIN を確認';

  @override
  String get pinCreateConfirm => 'プライベートスペースを作成';

  @override
  String get pinSaveConfirm => 'PIN を保存';

  @override
  String pinLengthError(int minimum, int maximum) {
    return '$minimum 〜 $maximum 桁で入力してください。';
  }

  @override
  String get pinMismatchError => '2 つの PIN が一致しません。';

  @override
  String get pinCurrentIncorrect => '現在の PIN が正しくありません。';

  @override
  String get unlockTitle => 'プライベートスペースのロック解除';

  @override
  String get unlockPinLabel => 'PIN';

  @override
  String get unlockUseFingerprint => '指紋を使う';

  @override
  String get unlockConfirm => 'ロック解除';

  @override
  String get unlockIncorrectPin => 'PIN が違います';

  @override
  String get unlockFingerprintUnavailable => '指紋によるロック解除は現在利用できません。';

  @override
  String get unlockFingerprintNotRecognised => '指紋を認識できませんでした。';

  @override
  String get unlockBiometricReason => 'プライベートスペースのロックを解除';

  @override
  String get privateTileEmpty => 'プライベートスペース、空';

  @override
  String privateTileHidden(int count) {
    return 'プライベートスペース、非表示 $count 件';
  }

  @override
  String get settingsSectionPrivacy => 'プライバシー';

  @override
  String get settingsPrivateSpaceSubtitle => 'アプリを PIN の内側に隠す';

  @override
  String get settingsOn => 'オン';

  @override
  String get settingsOff => 'オフ';

  @override
  String get componentBaseApk => 'ベース APK';

  @override
  String get componentSplitApk => '分割 APK';

  @override
  String get componentNoNativeLibraries => 'ネイティブライブラリなし';

  @override
  String get errorProfileNameEmpty => 'クローンには名前が必要です。';

  @override
  String errorProfileNameTooLong(int maximum) {
    return 'クローンの名前は最大 $maximum 文字です。';
  }

  @override
  String get errorProfileStorageUnreadable => '保存されたクローンを読み取れませんでした。';

  @override
  String get errorProfileNotFound => 'そのクローンはもうありません。';

  @override
  String get errorBridgeFailed => 'クローンを管理する部分との通信で問題が起きました。';

  @override
  String get errorBridgeUnsupportedPlatform => 'この機能は Android でのみ利用できます。';

  @override
  String get errorTestAppCheckFailed => 'テストアプリがインストールされているか確認できませんでした。';

  @override
  String get errorEngineInitFailed => 'このデバイスで仮想化エンジンを起動できませんでした。';

  @override
  String get errorEngineAndroidTooOld => '仮想化エンジンにはより新しい Android が必要です。';

  @override
  String get errorEngineNoResponse => '仮想化エンジンが応答しませんでした。もう一度お試しください。';

  @override
  String get errorNoContainer => 'このクローンにはまだコンテナがありません。一度起動してからもう一度お試しください。';

  @override
  String get errorLaunchRefused => 'エンジンがこのクローンの起動を拒否しました。';

  @override
  String get errorAlreadyCloned => 'このアプリはすでにクローンされています。';

  @override
  String get errorClearCacheFailed => 'このクローンのキャッシュの一部を削除できませんでした。';

  @override
  String get errorClearDataFailed => 'このクローンのデータを削除できませんでした。';

  @override
  String get errorShortcutsUnsupported => 'このランチャーはショートカットの追加に対応していません。';

  @override
  String get errorShortcutRefused => 'ランチャーがショートカットを拒否しました。';

  @override
  String get errorApkGone => 'このクローンの APK はデバイスに残っていないため、共有するものがありません。';

  @override
  String get errorShareFailed => 'アプリを共有できませんでした。';

  @override
  String get errorApkUnreadable => '選択した APK のひとつを読み取れませんでした。';

  @override
  String get errorApkPackageMismatch => '選択した APK はすべて同じアプリのものである必要があります。';

  @override
  String get errorApkVersionMismatch => '選択した APK はすべて同じバージョンである必要があります。';

  @override
  String get errorApkBaseRequired =>
      'ベース APK をちょうど 1 つと、設定スプリットを 1 つ以上選んでください。';

  @override
  String get errorApkDuplicateSplit => '同じ APK スプリットが複数回選択されました。';
}
