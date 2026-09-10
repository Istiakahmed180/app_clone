// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsSectionSupport => 'Hỗ trợ';

  @override
  String get settingsSectionLegal => 'Pháp lý';

  @override
  String get settingsSectionAbout => 'Giới thiệu';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsAppearance => 'Giao diện';

  @override
  String get settingsContact => 'Liên hệ';

  @override
  String get settingsContactSubtitle => 'Câu hỏi hoặc góp ý';

  @override
  String get settingsRate => 'Đánh giá';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Bạn thích $appName? Hãy để lại đánh giá';
  }

  @override
  String get settingsPrivacyPolicy => 'Chính sách bảo mật';

  @override
  String get settingsTermsOfService => 'Điều khoản dịch vụ';

  @override
  String get settingsVersion => 'Phiên bản';

  @override
  String get settingsArchitecture => 'Kiến trúc thiết bị';

  @override
  String get settingsArchitectureSubtitle => 'Khả năng tương thích ứng dụng';

  @override
  String get settingsBits64 => '64-bit';

  @override
  String get settingsBits32 => '32-bit';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'ABI được hỗ trợ';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Chưa công bố';

  @override
  String get settingsNotListedYet => 'Chưa có trên cửa hàng';

  @override
  String get settingsNotSetUpYet => 'Chưa thiết lập';

  @override
  String get commonUnavailable => 'không có';

  @override
  String get appearanceTitle => 'Giao diện';

  @override
  String get appearancePreview => 'Xem trước';

  @override
  String get appearanceChooseTheme => 'Chọn giao diện';

  @override
  String get appearanceSystem => 'Mặc định hệ thống';

  @override
  String get appearanceSystemSubtitle => 'Theo cài đặt thiết bị';

  @override
  String get appearanceLight => 'Sáng';

  @override
  String get appearanceLightSubtitle => 'Luôn dùng giao diện sáng';

  @override
  String get appearanceDark => 'Tối';

  @override
  String get appearanceDarkSubtitle => 'Luôn dùng giao diện tối';

  @override
  String appearanceInstantNote(String appName) {
    return 'Thay đổi giao diện áp dụng ngay trên toàn bộ $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Xem trước giao diện $theme';
  }

  @override
  String get languageTitle => 'Ngôn ngữ';

  @override
  String get languageSearchHint => 'Tìm ngôn ngữ';

  @override
  String get languageClearSearch => 'Xoá tìm kiếm';

  @override
  String languageNote(String appName) {
    return 'Chọn ngôn ngữ dùng trong $appName.';
  }

  @override
  String get languageSectionHeader => 'Ngôn ngữ';

  @override
  String get languageSystem => 'Mặc định hệ thống';

  @override
  String get languageSystemSubtitle => 'Dùng ngôn ngữ của thiết bị';

  @override
  String get languageInstantNote => 'Thay đổi ngôn ngữ áp dụng ngay lập tức.';

  @override
  String languageNoMatches(String query) {
    return 'Không có ngôn ngữ nào khớp với “$query”.';
  }

  @override
  String get contactTitle => 'Liên hệ';

  @override
  String get contactHeroTitle => 'Chúng tôi có thể giúp gì?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Chọn cách bạn muốn liên hệ với đội ngũ $appName.';
  }

  @override
  String get contactSectionOptions => 'Cách liên hệ';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Trò chuyện với đội hỗ trợ';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Nhắn tin cho chúng tôi trên Telegram';

  @override
  String get contactEmail => 'Email';

  @override
  String get contactEmailSubtitle => 'Gửi email cho chúng tôi';

  @override
  String get contactResponseTime => 'Thời gian phản hồi';

  @override
  String get contactResponseTimeValue =>
      'Chúng tôi thường trả lời trong 1–2 ngày làm việc.';

  @override
  String get contactPrivacyNote =>
      'Chúng tôi chỉ dùng tin nhắn của bạn để hỗ trợ.';

  @override
  String contactNoMailApp(String email) {
    return 'Không mở được ứng dụng email nào. Hãy viết tới $email.';
  }

  @override
  String get contactWhatsAppFailed => 'Không thể mở WhatsApp.';

  @override
  String get contactTelegramFailed => 'Không thể mở Telegram.';

  @override
  String get contactPlayStoreFailed => 'Không thể mở Play Store.';

  @override
  String contactLegalOpenFailed(String document) {
    return 'Không thể mở $document.';
  }
}
