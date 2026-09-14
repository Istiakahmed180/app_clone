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
  String get settingsSectionDelivery => '전달';

  @override
  String get settingsBackgroundActivity => '백그라운드 활동';

  @override
  String get settingsBackgroundActivitySubtitle => '복제한 앱이 닫혀 있어도 알림을 받도록 합니다';

  @override
  String get settingsBackgroundActivityAllowed => '허용됨';

  @override
  String get settingsBackgroundActivityRestricted => '제한됨';

  @override
  String get settingsBackgroundActivityCheck => '확인';

  @override
  String get backgroundGuideTitle => '백그라운드 활동';

  @override
  String get backgroundGuideWhy =>
      'Android가 Duplika를 백그라운드에서 중지하면 Duplika를 다시 열기 전까지 복제한 앱이 알림을 받지 못합니다.';

  @override
  String get backgroundGuideStepsOem =>
      '앱 정보에서 \'배터리 사용량\'을 누르고 \'백그라운드 활동 허용\'을 켜세요.';

  @override
  String get backgroundGuideStepsStock =>
      '열리는 시스템 질문에서 \'허용\'을 누르면 백그라운드에서 실행할 수 있습니다.';

  @override
  String get backgroundGuideStepsUnknown => '앱 정보에서 백그라운드 활동을 허용하세요.';

  @override
  String get backgroundGuideOpenAppInfo => '앱 정보 열기';

  @override
  String get backgroundGuideAllow => '허용';

  @override
  String get backgroundGuideLater => '나중에';

  @override
  String get settingsBackgroundActivityFix => '여기를 눌러 백그라운드 활동을 허용하세요';

  @override
  String get settingsBackgroundActivityFixBatteryUsage =>
      '여기를 누른 뒤 배터리 사용량, 그다음 백그라운드 활동 허용을 선택하세요';

  @override
  String get settingsBackgroundActivityFailed => '백그라운드 활동 설정을 열 수 없습니다.';

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
}
