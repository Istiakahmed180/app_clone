// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSectionSupport => '지원';

  @override
  String get settingsSectionLegal => '법적 고지';

  @override
  String get settingsSectionAbout => '앱 정보';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsAppearance => '화면 모드';

  @override
  String get settingsContact => '문의하기';

  @override
  String get settingsContactSubtitle => '질문 또는 의견';

  @override
  String get settingsRate => '평가하기';

  @override
  String settingsRateSubtitle(String appName) {
    return '$appName이 마음에 드세요? 리뷰를 남겨 주세요';
  }

  @override
  String get settingsPrivacyPolicy => '개인정보 처리방침';

  @override
  String get settingsTermsOfService => '서비스 이용약관';

  @override
  String get settingsVersion => '버전';

  @override
  String get settingsArchitecture => '기기 아키텍처';

  @override
  String get settingsArchitectureSubtitle => '앱 호환성';

  @override
  String get settingsBits64 => '64비트';

  @override
  String get settingsBits32 => '32비트';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => '지원 ABI';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => '아직 공개되지 않음';

  @override
  String get settingsNotListedYet => '아직 스토어에 없음';

  @override
  String get settingsNotSetUpYet => '아직 설정되지 않음';

  @override
  String get commonUnavailable => '확인할 수 없음';

  @override
  String get appearanceTitle => '화면 모드';

  @override
  String get appearancePreview => '미리보기';

  @override
  String get appearanceChooseTheme => '테마 선택';

  @override
  String get appearanceSystem => '시스템 기본값';

  @override
  String get appearanceSystemSubtitle => '기기 설정 따르기';

  @override
  String get appearanceLight => '라이트';

  @override
  String get appearanceLightSubtitle => '항상 라이트 테마 사용';

  @override
  String get appearanceDark => '다크';

  @override
  String get appearanceDarkSubtitle => '항상 다크 테마 사용';

  @override
  String appearanceInstantNote(String appName) {
    return '테마 변경은 $appName 전체에 즉시 적용됩니다.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return '$theme 테마 미리보기';
  }

  @override
  String get languageTitle => '언어';

  @override
  String get languageSearchHint => '언어 검색';

  @override
  String get languageClearSearch => '검색 지우기';

  @override
  String languageNote(String appName) {
    return '$appName에서 사용할 언어를 선택하세요.';
  }

  @override
  String get languageSectionHeader => '언어';

  @override
  String get languageSystem => '시스템 기본값';

  @override
  String get languageSystemSubtitle => '기기 언어 사용';

  @override
  String get languageInstantNote => '언어 변경은 즉시 적용됩니다.';

  @override
  String languageNoMatches(String query) {
    return '‘$query’와 일치하는 언어가 없습니다.';
  }

  @override
  String get contactTitle => '문의하기';

  @override
  String get contactHeroTitle => '무엇을 도와드릴까요?';

  @override
  String contactHeroSubtitle(String appName) {
    return '$appName 팀에 연락할 방법을 선택하세요.';
  }

  @override
  String get contactSectionOptions => '문의 방법';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => '지원팀과 채팅하기';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Telegram으로 메시지 보내기';

  @override
  String get contactEmail => '이메일';

  @override
  String get contactEmailSubtitle => '이메일 보내기';

  @override
  String get contactResponseTime => '응답 시간';

  @override
  String get contactResponseTimeValue => '보통 1~2 영업일 이내에 답변드립니다.';

  @override
  String get contactPrivacyNote => '보내 주신 메시지는 지원 목적으로만 사용합니다.';

  @override
  String contactNoMailApp(String email) {
    return '메일 앱을 열 수 없습니다. 대신 $email로 보내 주세요.';
  }

  @override
  String get contactWhatsAppFailed => 'WhatsApp을 열 수 없습니다.';

  @override
  String get contactTelegramFailed => 'Telegram을 열 수 없습니다.';

  @override
  String get contactPlayStoreFailed => 'Play 스토어를 열 수 없습니다.';

  @override
  String contactLegalOpenFailed(String document) {
    return '$document을 열 수 없습니다.';
  }

  @override
  String get commonCancel => '취소';

  @override
  String get commonOk => '확인';

  @override
  String get commonNotNow => '나중에';

  @override
  String get commonClose => '닫기';

  @override
  String get commonMore => '더보기';

  @override
  String get commonFailureTitle => '실행하지 못했습니다';

  @override
  String get homePrivateSpaceTitle => '프라이빗 스페이스';

  @override
  String get homeSubtitle => '나만의 프라이빗 스페이스';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '숨긴 앱 $count개',
      zero: '숨긴 앱 없음',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => '잠그고 닫기';

  @override
  String get homeMenuSettings => '설정';

  @override
  String get homeMenuDeveloperTools => '개발자 도구';

  @override
  String get homeAddApp => '앱 추가';

  @override
  String get homeEmptyTitle => '스페이스가 비어 있습니다';

  @override
  String get homeEmptyMessage => '앱을 추가해 첫 번째 프라이빗 인스턴스를 만들어 보세요.';

  @override
  String get homeEmptyAction => '첫 앱 추가하기';

  @override
  String get homePrivateEmptyTitle => '아직 숨긴 항목이 없습니다';

  @override
  String get homePrivateEmptyMessage =>
      '메인 그리드에서 앱을 길게 누르고 \'숨기기\'를 선택하면 이곳으로 옮겨집니다.';

  @override
  String get homeSetUpPrivateSpaceTitle => '프라이빗 스페이스를 설정할까요?';

  @override
  String get homeSetUpPrivateSpaceMessage =>
      '클론을 숨기려면 프라이빗 스페이스가 필요합니다. 먼저 PIN으로 하나 만드세요.';

  @override
  String get homeSetUpPrivateSpaceConfirm => '설정';

  @override
  String get homeEngineInactive =>
      '이 기기에서는 가상화 엔진이 활성화되어 있지 않아 클론을 격리된 컨테이너에서 실행할 수 없습니다.';

  @override
  String get homeEngineUnavailable => '이 기기에서는 가상화 엔진을 사용할 수 없습니다.';

  @override
  String cloneSpaceLabel(int index) {
    return '스페이스 $index';
  }

  @override
  String get cloneActionsManage => '관리';

  @override
  String get cloneActionUninstall => '제거';

  @override
  String get cloneActionClone => '복제';

  @override
  String get cloneActionShortcut => '바로가기';

  @override
  String get cloneActionSpaceInfo => '스페이스 정보';

  @override
  String get cloneActionEditName => '이름 수정';

  @override
  String get cloneActionChangeIcon => '아이콘 변경';

  @override
  String get cloneIconPickerChoose => '사진 선택';

  @override
  String get cloneIconPickerUseAppIcon => '앱 아이콘 사용';

  @override
  String get errorCloneIconFailed => '그 사진은 아이콘으로 사용할 수 없습니다. 다른 사진을 선택해 주세요.';

  @override
  String get errorCloneDeleteFailed => '이 클론을 삭제하지 못했습니다. 다시 시도해 주세요.';

  @override
  String get cloneIconPickerTitle => '이 클론의 아이콘';

  @override
  String get cloneIconPickerMessage =>
      '직접 고른 사진을 넣거나, 앱 아이콘을 그대로 두고 색으로 표시할 수 있습니다. 어느 쪽이든 같은 앱의 다른 클론과 한눈에 구분됩니다.';

  @override
  String get cloneIconColorRed => '빨강';

  @override
  String get cloneIconColorOrange => '주황';

  @override
  String get cloneIconColorAmber => '호박색';

  @override
  String get cloneIconColorGreen => '초록';

  @override
  String get cloneIconColorTeal => '청록';

  @override
  String get cloneIconColorBlue => '파랑';

  @override
  String get cloneIconColorViolet => '보라';

  @override
  String get cloneIconColorPink => '분홍';

  @override
  String get cloneIconColorNone => '색 없음';

  @override
  String get cloneActionForceStop => '강제 중지';

  @override
  String get cloneActionClearCache => '캐시 삭제';

  @override
  String get cloneActionClearStorage => '데이터 삭제';

  @override
  String get cloneActionHide => '숨기기';

  @override
  String get cloneActionUnhide => '표시';

  @override
  String get cloneActionShareApp => '앱 공유';

  @override
  String get cloneActionPermissions => '권한';

  @override
  String get cloneActionInstallGoogleServices => 'Google 서비스 설치';

  @override
  String cloneTileSibling(int index, int count) {
    return ', $count개 중 $index번째 클론';
  }

  @override
  String get cloneTileOpening => ', 여는 중';

  @override
  String get cloneTileRunning => ', 실행 중';

  @override
  String cloneTileMark(String color) {
    return ', 표시 $color';
  }

  @override
  String get cloneTileCannotLaunch => ', 이 기기에서는 실행할 수 없음';

  @override
  String get cloneForceStopTitle => '이 앱을 강제 중지할까요?';

  @override
  String get cloneForceStopMessage => '다시 열 때까지 앱이 실행을 멈춥니다.';

  @override
  String get cloneForceStopConfirm => '강제 중지';

  @override
  String get cloneClearCacheTitle => '앱 캐시를 삭제할까요?';

  @override
  String get cloneClearCacheMessage => '이 클론의 임시 파일이 삭제됩니다.';

  @override
  String get cloneClearCacheConfirm => '캐시 삭제';

  @override
  String get cloneClearStorageTitle => '앱 데이터를 삭제할까요?';

  @override
  String get cloneClearStorageMessage => '이 클론의 계정, 설정, 로컬 데이터가 영구히 삭제됩니다.';

  @override
  String get cloneClearStorageConfirm => '데이터 삭제';

  @override
  String get cloneInstallGoogleServicesTitle => 'Google 서비스를 설치할까요?';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName이(가) Google Play 서비스를 이 클론에 설치합니다. 클론의 데이터는 유지됩니다. 몇 초 걸릴 수 있습니다.';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => '설치';

  @override
  String cloneStopped(String name) {
    return '$name을(를) 중지했습니다.';
  }

  @override
  String cloneCacheCleared(String name) {
    return '$name의 캐시를 삭제했습니다.';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name이(가) 초기화되었습니다. 다음 실행은 첫 실행이 됩니다.';
  }

  @override
  String cloneHidden(String name) {
    return '$name을(를) 프라이빗 스페이스에 숨겼습니다.';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name이(가) 메인 그리드로 돌아왔습니다.';
  }

  @override
  String get cloneShortcutAdded => '추가를 마치려면 홈 화면에서 바로가기를 확인하세요.';

  @override
  String get cloneGoogleServicesInstalling => 'Google 서비스를 설치하는 중…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return '$name에 Google 서비스를 설치했습니다.';
  }

  @override
  String get cloneCountTitle => '앱 복제';

  @override
  String cloneCountMessage(String appName) {
    return '$appName의 사본을 더 만듭니다.';
  }

  @override
  String get cloneCountLabel => '클론 개수';

  @override
  String get cloneCountDecrease => '하나 줄이기';

  @override
  String get cloneCountIncrease => '하나 늘리기';

  @override
  String get cloneCountConfirm => '복제';

  @override
  String cloneCreating(int created, int total) {
    return '$total개 중 $created개 생성 중…';
  }

  @override
  String get cloneCreatingFinishing => '마무리하는 중…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$appName 사본을 $count개 더 추가했습니다.',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return '$total개 중 $created개를 만들었습니다. $failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return '1부터 $maximum까지 선택';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return '여유 공간이 $free뿐이며, 기기는 0.5GB를 남겨 둡니다.';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return '최대 $maximum개 — 남은 공간 $free';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return '메모리 $memory인 기기에서는 한 번에 최대 $maximum개';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return '$appName 클론을 하나 더 만들 공간이 없습니다. $reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return '$appName 클론을 $count개 더 만들 공간이 부족합니다. $reason.';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return '권한 · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => '권한을 읽을 수 없습니다';

  @override
  String get clonePermissionsEmptyTitle => '제한할 항목 없음';

  @override
  String get clonePermissionsEmptyMessage =>
      '이 앱은 위험 권한을 선언하지 않으므로 이 클론에 대해 허용하거나 거부할 항목이 없습니다.';

  @override
  String clonePermissionsNote(String appName) {
    return '이 클론에만 적용됩니다. 복제된 앱은 보통 권한을 쓰기 전에 묻는데, 그 답이 여기서 제한됩니다. 묻지 않고 넘어가는 앱은 $appName 자체의 권한을 통해 하드웨어에 접근할 수도 있습니다.';
  }

  @override
  String get spaceInfoTitle => '스페이스 정보';

  @override
  String get spaceInfoIdentifiers => '기기 식별자';

  @override
  String get spaceInfoIdentifiersNote =>
      '이 값은 공간 자체를 식별합니다. 안에서 실행되는 앱은 이 값을 보지 못하고 이 기기의 실제 식별자를 그대로 읽으므로, 클론이 다른 기기처럼 보이지는 않습니다.';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => '엔진 사용 불가';

  @override
  String get spaceInfoStateRunning => '실행 중';

  @override
  String get spaceInfoStateActive => '활성';

  @override
  String get spaceInfoStateRebuilds => '실행 시 재생성';

  @override
  String get spaceInfoNoContainer =>
      '이 스페이스에는 아직 컨테이너가 없어 식별자도 없습니다. 한 번 실행하면 여기에 나타납니다.';

  @override
  String get spaceInfoDeviceId => '기기 ID';

  @override
  String get spaceInfoAndroidId => 'Android ID';

  @override
  String get spaceInfoSerialNumber => '일련번호';

  @override
  String get spaceInfoWifiMac => 'Wi-Fi MAC';

  @override
  String get spaceInfoBluetoothMac => '블루투스 MAC';

  @override
  String spaceInfoCopy(String label) {
    return '$label 복사';
  }

  @override
  String spaceInfoCopied(String label) {
    return '$label을(를) 복사했습니다.';
  }

  @override
  String get commonBack => '뒤로';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonApply => '적용';

  @override
  String get pickerTitle => '앱 추가';

  @override
  String get pickerSearchHint => '앱 검색';

  @override
  String get pickerFilterTooltip => '필터 및 정렬';

  @override
  String get pickerErrorTitle => '앱 목록을 불러올 수 없습니다';

  @override
  String get pickerNoMatchesTitle => '일치하는 앱이 없습니다';

  @override
  String get pickerNoMatchesMessage => '다른 검색어를 시도하거나 APK를 가져오세요.';

  @override
  String get pickerPopular => '인기';

  @override
  String get pickerQuickPicks => '빠른 선택';

  @override
  String get pickerInstalledApps => '설치된 앱';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '앱 $count개',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => '시스템';

  @override
  String get pickerCannotClone => '이 기기에서는 이 앱을 복제할 수 없습니다.';

  @override
  String get pickerCloneInProgress =>
      'A clone is already being created. Wait for it to finish, then try again.';

  @override
  String get pickerApkUnreadable => '선택한 APK를 읽을 수 없습니다.';

  @override
  String pickerHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이 기기의 앱 $count개는 복제할 수 없어 목록에 표시되지 않습니다',
    );
    return '$_temp0';
  }

  @override
  String get filterTitle => '필터 및 정렬';

  @override
  String get filterSort => '정렬';

  @override
  String get filterSortName => '앱 이름';

  @override
  String get filterSortRecentlyInstalled => '최근 설치';

  @override
  String get filterSortRecentlyUpdated => '최근 업데이트';

  @override
  String get filterFilter => '필터';

  @override
  String get filterAllApps => '모든 앱';

  @override
  String get filterUserApps => '사용자 앱';

  @override
  String get filterSystemApps => '시스템 앱';

  @override
  String get filterNotAdded => '추가되지 않음';

  @override
  String get filterAlreadyAdded => '이미 추가됨';

  @override
  String get filterArchitecture => '아키텍처';

  @override
  String get filterArch64 => '64비트';

  @override
  String get filterArch32 => '32비트';

  @override
  String get filterArchNoNativeCode => '네이티브 코드 없음';

  @override
  String get filterPackageType => '패키지 유형';

  @override
  String get filterPackageSingle => '단일 APK';

  @override
  String get filterPackageSplit => '분할 APK';

  @override
  String filterImportApk(String appName) {
    return '$appName 앱 패키지 열기';
  }

  @override
  String get appSheetAddClone => '클론 추가';

  @override
  String get appSheetAddAnother => '하나 더 추가';

  @override
  String get appSheetShareApp => '앱 공유';

  @override
  String get appSheetAppDetails => '앱 세부정보';

  @override
  String get appDetailsTitle => '앱 세부정보';

  @override
  String get appDetailsAdvanced => '고급 정보';

  @override
  String get appDetailsPackageName => '패키지 이름';

  @override
  String get appDetailsVersion => '버전';

  @override
  String get appDetailsArchitecture => '아키텍처';

  @override
  String get appDetailsBitness => '비트 폭';

  @override
  String get appDetailsPackageType => '패키지 유형';

  @override
  String get appDetailsApkComponents => 'APK 구성요소';

  @override
  String get appDetailsTotalApkSize => '전체 APK 크기';

  @override
  String get appDetailsSigningSha256 => '서명 인증서 SHA-256';

  @override
  String get appDetailsSigningUnreadable => '읽을 수 없음';

  @override
  String get appDetailsNoApkFiles => '패키지 관리자가 이 앱의 APK 파일을 보고하지 않았습니다.';

  @override
  String get findingAppNotFound => '이 애플리케이션은 기기에 설치되어 있지 않습니다.';

  @override
  String get findingSecureEnvRequired => '이 애플리케이션은 보안 환경이 필요해 가상화할 수 없습니다.';

  @override
  String findingSelfClone(String appName) {
    return '$appName은(는) 자기 자신을 복제할 수 없습니다.';
  }

  @override
  String get findingSystemComponent => '시스템 구성요소는 복제할 수 없습니다.';

  @override
  String get findingAbiNotSupported =>
      '이 앱의 네이티브 라이브러리는 엔진이 지원하는 아키텍처용으로 빌드되지 않았습니다.';

  @override
  String get findingAppArchiveUnavailable =>
      'This app\'s installation files are not on the device. It has been archived, or its installation is incomplete.';

  @override
  String findingStorageUnavailable(String appName) {
    return '이 앱은 공유 저장소를 사용하는데, 이 $appName 빌드는 \'모든 파일 접근\'을 선언하지 않습니다. 이 앱의 클론은 파일에 접근하지 못해 작동하지 않습니다.';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return '이 앱은 공유 저장소를 사용합니다. 클론을 실행하기 전에 설정 → 특별한 앱 접근에서 $appName에 \'모든 파일 접근\'을 허용하세요. 그렇지 않으면 실행 시 거부될 수 있습니다.';
  }

  @override
  String get factsNoNativeCode => '네이티브 코드 없음';

  @override
  String get factsAnyNoNativeCode => '모두 — 네이티브 코드 없음';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => '단일 APK';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '분할 APK · 파일 $count개',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => '알 수 없음';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => '파일 관리자로 가져오기';

  @override
  String get commonSave => '저장';

  @override
  String get renameTitle => '프로필 이름 변경';

  @override
  String get renameFieldLabel => '프로필 이름';

  @override
  String get uninstallTitle => '이 클론을 제거할까요?';

  @override
  String uninstallSpaceOf(int index, int count) {
    return '$count개 중 스페이스 $index';
  }

  @override
  String get uninstallMessage => '선택한 앱 인스턴스와 로컬 데이터가 삭제됩니다.';

  @override
  String get uninstallConfirm => '제거';

  @override
  String get calculatorError => '오류';

  @override
  String get disclosureTitle => '시작하기 전에';

  @override
  String disclosureIntro(String appName) {
    return '$appName은(는) 선택한 앱의 두 번째 사본을 실행합니다. 무엇을 읽고 무엇을 요청하는지 그대로 알려드립니다.';
  }

  @override
  String get disclosureAppsTitle => '설치된 앱 목록';

  @override
  String disclosureAppsBody(String appName) {
    return '클론 선택 화면을 보여주기 위해 $appName은(는) 이 기기에 설치된 앱 목록(이름, 아이콘, 버전)을 읽습니다. 이 목록은 기기 안에만 남습니다. 업로드하거나 판매하거나 공유하지 않으며, 이 앱에는 광고도 분석도 트래커도 없습니다.';
  }

  @override
  String get disclosurePermissionsTitle => '클론을 대신한 권한';

  @override
  String disclosurePermissionsBody(String appName) {
    return '복제된 앱은 $appName 안에서 실행되므로 일부 Android 권한이 그들을 대신해 $appName에 적용됩니다. 복제한 메신저가 계속 알림을 받도록 배터리 최적화에서 제외해 달라는 요청을 한 번 받을 수 있습니다. 파일이나 미디어 앱을 복제할 때만 설정에서 \'모든 파일 접근\'을 허용해야 할 수 있습니다.';
  }

  @override
  String get disclosureControlTitle => '선택권은 사용자에게 있습니다';

  @override
  String get disclosureControlBody =>
      '몰래 요청하는 것은 없습니다. 어떤 요청이든 거부하고도 앱을 계속 쓸 수 있고, 언제든 Android 설정에서 생각을 바꿀 수 있습니다.';

  @override
  String get disclosureAccept => '동의하고 계속';

  @override
  String get privateSpaceTitle => '프라이빗 스페이스';

  @override
  String get privateSpaceOffTitle => '프라이빗 스페이스가 꺼져 있습니다';

  @override
  String get privateSpaceOffMessage =>
      '켜면 클론을 PIN 뒤에 숨길 수 있습니다. 숨긴 앱은 메인 그리드에서 사라지고 여기서만 열립니다.';

  @override
  String get privateSpaceSetUp => '프라이빗 스페이스 설정';

  @override
  String get privateSpaceChangePin => 'PIN 변경';

  @override
  String get privateSpaceUnlockSection => '잠금 해제';

  @override
  String get privateSpaceFingerprint => '지문으로 잠금 해제';

  @override
  String get privateSpaceFingerprintAvailable => '언제든 PIN도 사용할 수 있습니다.';

  @override
  String get privateSpaceFingerprintUnavailable =>
      '이 기기에는 지문이나 얼굴이 설정되어 있지 않습니다.';

  @override
  String get privateSpaceDisguiseSection => '위장';

  @override
  String get privateSpaceDisguiseAsCalculator => '계산기로 위장';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return '$appName의 아이콘을 계산기로 바꿉니다. 프라이빗 스페이스 PIN을 입력하고 =를 누르면 앱이 열립니다.';
  }

  @override
  String get privateSpaceTurnOff => '프라이빗 스페이스 끄기';

  @override
  String get privateSpaceTurnOffNote =>
      '끄면 숨긴 앱이 모두 메인 그리드로 돌아옵니다. 클론 자체는 삭제되지 않습니다.';

  @override
  String get privateSpaceDisguiseOnTitle => '계산기로 위장할까요?';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return '$appName을(를) 다시 표시할까요?';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return '$appName의 아이콘이 \'Calculator\'라는 계산기로 바뀝니다. $appName을(를) 열려면 프라이빗 스페이스 PIN을 입력하고 =를 누르세요. PIN을 잊으면 앱을 열 수 없습니다.';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName이(가) 홈 화면에 원래 아이콘과 이름을 다시 표시합니다.';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => '위장';

  @override
  String get privateSpaceDisguiseConfirmOff => '앱 표시';

  @override
  String get privateSpaceDisguiseFailed => '앱의 모습을 바꿀 수 없습니다.';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '이제 홈 화면에서 $appName이(가) 계산기처럼 보입니다.';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName이(가) 홈 화면으로 돌아왔습니다.';
  }

  @override
  String get privateSpaceTurnOffTitle => '프라이빗 스페이스를 끌까요?';

  @override
  String get privateSpaceTurnOffMessage =>
      '숨긴 앱이 모두 메인 그리드로 돌아오고 PIN은 지워집니다. 클론은 그대로 유지됩니다.';

  @override
  String get privateSpaceTurnOffConfirm => '끄기';

  @override
  String get privateSpaceTurnedOff => '프라이빗 스페이스를 껐습니다.';

  @override
  String get pinCreateTitle => 'PIN 만들기';

  @override
  String get pinChangeTitle => 'PIN 변경';

  @override
  String get pinCreateMessage =>
      '이 PIN이 프라이빗 스페이스를 잠급니다. 잊지 않을 곳에 보관하세요. PIN 없이는 숨긴 클론을 되찾을 방법이 없습니다.';

  @override
  String get pinChangeMessage => '현재 PIN을 입력한 뒤 새 PIN을 선택하세요.';

  @override
  String get pinCurrentLabel => '현재 PIN';

  @override
  String get pinNewLabel => '새 PIN';

  @override
  String get pinConfirmLabel => 'PIN 확인';

  @override
  String get pinCreateConfirm => '프라이빗 스페이스 만들기';

  @override
  String get pinSaveConfirm => 'PIN 저장';

  @override
  String pinLengthError(int minimum, int maximum) {
    return '$minimum~$maximum자리 숫자를 사용하세요.';
  }

  @override
  String get pinMismatchError => '두 PIN이 일치하지 않습니다.';

  @override
  String get pinCurrentIncorrect => '현재 PIN이 올바르지 않습니다.';

  @override
  String get unlockTitle => '프라이빗 스페이스 잠금 해제';

  @override
  String get unlockPinLabel => 'PIN';

  @override
  String get unlockUseFingerprint => '지문 사용';

  @override
  String get unlockConfirm => '잠금 해제';

  @override
  String get unlockIncorrectPin => '잘못된 PIN';

  @override
  String get unlockFingerprintUnavailable => '지금은 지문 잠금 해제를 사용할 수 없습니다.';

  @override
  String get unlockFingerprintNotRecognised => '지문을 인식하지 못했습니다.';

  @override
  String get unlockBiometricReason => '프라이빗 스페이스 잠금 해제';

  @override
  String get privateTileEmpty => '프라이빗 스페이스, 비어 있음';

  @override
  String privateTileHidden(int count) {
    return '프라이빗 스페이스, $count개 숨김';
  }

  @override
  String get settingsSectionPrivacy => '개인정보 보호';

  @override
  String get settingsPrivateSpaceSubtitle => '앱을 PIN 뒤에 숨기기';

  @override
  String get settingsOn => '켜짐';

  @override
  String get settingsOff => '꺼짐';

  @override
  String get componentBaseApk => '기본 APK';

  @override
  String get componentSplitApk => '분할 APK';

  @override
  String get componentNoNativeLibraries => '네이티브 라이브러리 없음';

  @override
  String get errorProfileNameEmpty => '클론에는 이름이 필요합니다.';

  @override
  String errorProfileNameTooLong(int maximum) {
    return '클론 이름은 최대 $maximum자까지 가능합니다.';
  }

  @override
  String get errorProfileStorageUnreadable => '저장된 클론을 읽을 수 없습니다.';

  @override
  String get errorProfileNotFound => '그 클론은 더 이상 없습니다.';

  @override
  String get errorBridgeFailed => '클론을 관리하는 부분과 통신하는 중 문제가 발생했습니다.';

  @override
  String get errorBridgeUnsupportedPlatform => '이 기능은 Android에서만 사용할 수 있습니다.';

  @override
  String get errorTestAppCheckFailed => '테스트 앱이 설치되어 있는지 확인할 수 없습니다.';

  @override
  String get errorEngineInitFailed => '이 기기에서 가상화 엔진을 시작하지 못했습니다.';

  @override
  String get errorEngineAndroidTooOld => '가상화 엔진에는 더 새로운 Android 버전이 필요합니다.';

  @override
  String get errorEngineNoResponse => '가상화 엔진이 응답하지 않았습니다. 다시 시도하세요.';

  @override
  String get errorNoContainer => '이 클론에는 아직 컨테이너가 없습니다. 한 번 실행한 뒤 다시 시도하세요.';

  @override
  String get errorLaunchRefused => '엔진이 이 클론 실행을 거부했습니다.';

  @override
  String get errorAlreadyCloned => '이 앱은 이미 복제되어 있습니다.';

  @override
  String get errorClearCacheFailed => '이 클론의 캐시 일부를 삭제하지 못했습니다.';

  @override
  String get errorClearDataFailed => '이 클론의 데이터를 삭제하지 못했습니다.';

  @override
  String get errorShortcutsUnsupported => '이 런처는 바로가기 추가를 지원하지 않습니다.';

  @override
  String get errorShortcutRefused => '런처가 바로가기를 거부했습니다.';

  @override
  String get errorApkGone => '이 클론의 APK가 기기에 없어 공유할 것이 없습니다.';

  @override
  String get errorShareFailed => '앱을 공유하지 못했습니다.';

  @override
  String get errorApkUnreadable => '선택한 APK 중 하나를 읽을 수 없습니다.';

  @override
  String get errorApkPackageMismatch => '선택한 APK는 모두 같은 앱의 것이어야 합니다.';

  @override
  String get errorApkVersionMismatch => '선택한 APK는 모두 같은 버전이어야 합니다.';

  @override
  String get errorApkBaseRequired => '기본 APK 하나와 구성 분할 하나 이상을 선택하세요.';

  @override
  String get errorApkDuplicateSplit => '같은 APK 분할이 여러 번 선택되었습니다.';
}
