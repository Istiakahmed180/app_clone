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

  @override
  String get commonCancel => 'Huỷ';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNotNow => 'Để sau';

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonMore => 'Thêm';

  @override
  String get commonFailureTitle => 'Không thực hiện được';

  @override
  String get homePrivateSpaceTitle => 'Không gian riêng';

  @override
  String get homeSubtitle => 'Không gian riêng của bạn';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ứng dụng ẩn',
      zero: 'Không có ứng dụng ẩn',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => 'Khoá và đóng';

  @override
  String get homeMenuSettings => 'Cài đặt';

  @override
  String get homeMenuDeveloperTools => 'Công cụ nhà phát triển';

  @override
  String get homeAddApp => 'Thêm ứng dụng';

  @override
  String get homeEmptyTitle => 'Không gian của bạn đang trống';

  @override
  String get homeEmptyMessage =>
      'Thêm một ứng dụng để tạo bản sao riêng đầu tiên của bạn.';

  @override
  String get homeEmptyAction => 'Thêm ứng dụng đầu tiên';

  @override
  String get homePrivateEmptyTitle => 'Chưa ẩn gì cả';

  @override
  String get homePrivateEmptyMessage =>
      'Giữ bất kỳ ứng dụng nào trên lưới chính rồi chọn Ẩn để chuyển nó vào đây.';

  @override
  String get homeSetUpPrivateSpaceTitle => 'Thiết lập không gian riêng?';

  @override
  String get homeSetUpPrivateSpaceMessage =>
      'Muốn ẩn một bản sao thì cần không gian riêng. Hãy tạo một cái với mã PIN trước.';

  @override
  String get homeSetUpPrivateSpaceConfirm => 'Thiết lập';

  @override
  String get homeEngineInactive =>
      'Công cụ ảo hoá không hoạt động trên thiết bị này, nên các bản sao không thể chạy trong vùng chứa riêng.';

  @override
  String get homeEngineUnavailable =>
      'Công cụ ảo hoá không khả dụng trên thiết bị này.';

  @override
  String cloneSpaceLabel(int index) {
    return 'Không gian $index';
  }

  @override
  String get cloneActionsManage => 'Quản lý';

  @override
  String get cloneActionUninstall => 'Gỡ cài đặt';

  @override
  String get cloneActionClone => 'Nhân bản';

  @override
  String get cloneActionShortcut => 'Lối tắt';

  @override
  String get cloneActionSpaceInfo => 'Thông tin không gian';

  @override
  String get cloneActionEditName => 'Sửa tên';

  @override
  String get cloneActionChangeIcon => 'Đổi biểu tượng';

  @override
  String get cloneIconPickerChoose => 'Chọn một ảnh';

  @override
  String get cloneIconPickerUseAppIcon => 'Dùng biểu tượng của ứng dụng';

  @override
  String get errorCloneIconFailed =>
      'Không thể dùng ảnh đó làm biểu tượng. Hãy thử ảnh khác.';

  @override
  String get cloneIconPickerTitle => 'Biểu tượng của bản sao này';

  @override
  String get cloneIconPickerMessage =>
      'Đặt ảnh của riêng bạn, hoặc giữ biểu tượng của ứng dụng và đánh dấu bằng một màu — cách nào bạn cũng nhận ra nó ngay giữa các bản sao khác của cùng ứng dụng.';

  @override
  String get cloneIconColorRed => 'Đỏ';

  @override
  String get cloneIconColorOrange => 'Cam';

  @override
  String get cloneIconColorAmber => 'Hổ phách';

  @override
  String get cloneIconColorGreen => 'Xanh lá';

  @override
  String get cloneIconColorTeal => 'Xanh mòng két';

  @override
  String get cloneIconColorBlue => 'Xanh dương';

  @override
  String get cloneIconColorViolet => 'Tím';

  @override
  String get cloneIconColorPink => 'Hồng';

  @override
  String get cloneIconColorNone => 'Không màu';

  @override
  String get cloneActionForceStop => 'Buộc dừng';

  @override
  String get cloneActionClearCache => 'Xoá bộ nhớ đệm';

  @override
  String get cloneActionClearStorage => 'Xoá dữ liệu';

  @override
  String get cloneActionHide => 'Ẩn';

  @override
  String get cloneActionUnhide => 'Hiện';

  @override
  String get cloneActionShareApp => 'Chia sẻ ứng dụng';

  @override
  String get cloneActionPermissions => 'Quyền';

  @override
  String get cloneActionInstallGoogleServices => 'Cài dịch vụ Google';

  @override
  String cloneTileSibling(int index, int count) {
    return ', bản sao $index trên $count';
  }

  @override
  String get cloneTileOpening => ', đang mở';

  @override
  String get cloneTileRunning => ', đang chạy';

  @override
  String cloneTileMark(String color) {
    return ', đánh dấu $color';
  }

  @override
  String get cloneTileCannotLaunch => ', không thể khởi chạy trên thiết bị này';

  @override
  String get cloneForceStopTitle => 'Buộc dừng ứng dụng này?';

  @override
  String get cloneForceStopMessage =>
      'Ứng dụng sẽ ngừng chạy cho đến khi bạn mở lại.';

  @override
  String get cloneForceStopConfirm => 'Buộc dừng';

  @override
  String get cloneClearCacheTitle => 'Xoá bộ nhớ đệm của ứng dụng?';

  @override
  String get cloneClearCacheMessage =>
      'Thao tác này sẽ xoá các tệp tạm của bản sao này.';

  @override
  String get cloneClearCacheConfirm => 'Xoá bộ nhớ đệm';

  @override
  String get cloneClearStorageTitle => 'Xoá dữ liệu của ứng dụng?';

  @override
  String get cloneClearStorageMessage =>
      'Thao tác này sẽ xoá vĩnh viễn tài khoản, cài đặt và dữ liệu cục bộ của bản sao này.';

  @override
  String get cloneClearStorageConfirm => 'Xoá dữ liệu';

  @override
  String get cloneInstallGoogleServicesTitle => 'Cài dịch vụ Google?';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return '$appName sẽ cài dịch vụ Google Play vào bản sao này. Bản sao vẫn giữ dữ liệu. Việc này có thể mất vài giây.';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => 'Cài đặt';

  @override
  String cloneStopped(String name) {
    return 'Đã dừng $name.';
  }

  @override
  String cloneCacheCleared(String name) {
    return 'Đã xoá bộ nhớ đệm của $name.';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name đã được đặt lại. Lần mở tới sẽ như lần mở đầu tiên.';
  }

  @override
  String cloneHidden(String name) {
    return '$name đã được ẩn trong không gian riêng.';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name đã trở lại lưới chính.';
  }

  @override
  String get cloneShortcutAdded =>
      'Xác nhận lối tắt trên màn hình chính để hoàn tất việc thêm.';

  @override
  String get cloneGoogleServicesInstalling => 'Đang cài dịch vụ Google…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return 'Đã cài dịch vụ Google trong $name.';
  }

  @override
  String get cloneCountTitle => 'Nhân bản ứng dụng';

  @override
  String cloneCountMessage(String appName) {
    return 'Tạo thêm bản sao của $appName.';
  }

  @override
  String get cloneCountLabel => 'Số bản sao';

  @override
  String get cloneCountDecrease => 'Bớt một';

  @override
  String get cloneCountIncrease => 'Thêm một';

  @override
  String get cloneCountConfirm => 'Nhân bản';

  @override
  String cloneCreating(int created, int total) {
    return 'Đang tạo $created trên $total…';
  }

  @override
  String get cloneCreatingFinishing => 'Đang hoàn tất…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã thêm $count bản sao $appName nữa.',
      one: 'Đã thêm một bản sao $appName nữa.',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return 'Đã tạo $created trên $total. $failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return 'Chọn từ 1 đến $maximum';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return 'Chỉ còn trống $free, và thiết bị giữ lại nửa gigabyte dự phòng.';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return 'Tối đa $maximum — còn $free dung lượng';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return 'Tối đa $maximum cùng lúc trên thiết bị có $memory bộ nhớ';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return 'Không còn chỗ cho một bản sao $appName nữa. $reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return 'Không đủ chỗ cho $count bản sao $appName nữa. $reason.';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return 'Quyền · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => 'Không đọc được các quyền';

  @override
  String get clonePermissionsEmptyTitle => 'Không có gì để giới hạn';

  @override
  String get clonePermissionsEmptyMessage =>
      'Ứng dụng này không khai báo quyền nguy hiểm nào, nên không có gì để cho phép hay từ chối với bản sao này.';

  @override
  String clonePermissionsNote(String appName) {
    return 'Chỉ áp dụng cho bản sao này. Ứng dụng được nhân bản thường hỏi trước khi dùng một quyền, và đây là nơi câu trả lời đó bị giới hạn — ứng dụng bỏ qua bước hỏi vẫn có thể chạm tới phần cứng qua quyền của chính $appName.';
  }

  @override
  String get spaceInfoTitle => 'Thông tin không gian';

  @override
  String get spaceInfoIdentifiers => 'Định danh thiết bị';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => 'Công cụ không khả dụng';

  @override
  String get spaceInfoStateRunning => 'Đang chạy';

  @override
  String get spaceInfoStateActive => 'Đang hoạt động';

  @override
  String get spaceInfoStateRebuilds => 'Dựng lại khi mở';

  @override
  String get spaceInfoNoContainer =>
      'Không gian này chưa có vùng chứa nên chưa có định danh. Hãy mở nó một lần và chúng sẽ xuất hiện ở đây.';

  @override
  String get spaceInfoDeviceId => 'ID thiết bị';

  @override
  String get spaceInfoAndroidId => 'Android ID';

  @override
  String get spaceInfoSerialNumber => 'Số sê-ri';

  @override
  String get spaceInfoWifiMac => 'MAC Wi-Fi';

  @override
  String get spaceInfoBluetoothMac => 'MAC Bluetooth';

  @override
  String spaceInfoCopy(String label) {
    return 'Sao chép $label';
  }

  @override
  String spaceInfoCopied(String label) {
    return 'Đã sao chép $label.';
  }

  @override
  String get commonBack => 'Quay lại';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonApply => 'Áp dụng';

  @override
  String get pickerTitle => 'Thêm ứng dụng';

  @override
  String get pickerSearchHint => 'Tìm ứng dụng';

  @override
  String get pickerFilterTooltip => 'Lọc và sắp xếp';

  @override
  String get pickerErrorTitle => 'Không liệt kê được ứng dụng';

  @override
  String get pickerNoMatchesTitle => 'Không có ứng dụng nào khớp';

  @override
  String get pickerNoMatchesMessage =>
      'Thử tìm kiếm khác, hoặc nhập một tệp APK.';

  @override
  String get pickerPopular => 'Phổ biến';

  @override
  String get pickerQuickPicks => 'Chọn nhanh';

  @override
  String get pickerInstalledApps => 'Ứng dụng đã cài';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ứng dụng',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => 'Hệ thống';

  @override
  String get pickerCannotClone =>
      'Không thể nhân bản ứng dụng này trên thiết bị này.';

  @override
  String get pickerCloneInProgress =>
      'A clone is already being created. Wait for it to finish, then try again.';

  @override
  String get pickerApkUnreadable => 'Không đọc được tệp APK đã chọn.';

  @override
  String pickerHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ứng dụng trên thiết bị này không thể nhân bản nên không được liệt kê',
    );
    return '$_temp0';
  }

  @override
  String get filterTitle => 'Lọc và sắp xếp';

  @override
  String get filterSort => 'Sắp xếp';

  @override
  String get filterSortName => 'Tên ứng dụng';

  @override
  String get filterSortRecentlyInstalled => 'Mới cài gần đây';

  @override
  String get filterSortRecentlyUpdated => 'Mới cập nhật';

  @override
  String get filterFilter => 'Lọc';

  @override
  String get filterAllApps => 'Tất cả ứng dụng';

  @override
  String get filterUserApps => 'Ứng dụng người dùng';

  @override
  String get filterSystemApps => 'Ứng dụng hệ thống';

  @override
  String get filterNotAdded => 'Chưa thêm';

  @override
  String get filterAlreadyAdded => 'Đã thêm';

  @override
  String get filterArchitecture => 'Kiến trúc';

  @override
  String get filterArch64 => '64-bit';

  @override
  String get filterArch32 => '32-bit';

  @override
  String get filterArchNoNativeCode => 'Không có mã native';

  @override
  String get filterPackageType => 'Loại gói';

  @override
  String get filterPackageSingle => 'APK đơn';

  @override
  String get filterPackageSplit => 'APK tách';

  @override
  String filterImportApk(String appName) {
    return 'Mở gói ứng dụng $appName';
  }

  @override
  String get appSheetAddClone => 'Thêm bản sao';

  @override
  String get appSheetAddAnother => 'Thêm bản nữa';

  @override
  String get appSheetShareApp => 'Chia sẻ ứng dụng';

  @override
  String get appSheetAppDetails => 'Chi tiết ứng dụng';

  @override
  String get appDetailsTitle => 'Chi tiết ứng dụng';

  @override
  String get appDetailsAdvanced => 'Chi tiết nâng cao';

  @override
  String get appDetailsPackageName => 'Tên gói';

  @override
  String get appDetailsVersion => 'Phiên bản';

  @override
  String get appDetailsArchitecture => 'Kiến trúc';

  @override
  String get appDetailsBitness => 'Độ rộng bit';

  @override
  String get appDetailsPackageType => 'Loại gói';

  @override
  String get appDetailsApkComponents => 'Thành phần APK';

  @override
  String get appDetailsTotalApkSize => 'Tổng kích thước APK';

  @override
  String get appDetailsSigningSha256 => 'SHA-256 của chứng chỉ ký';

  @override
  String get appDetailsSigningUnreadable => 'không đọc được';

  @override
  String get appDetailsNoApkFiles =>
      'Trình quản lý gói không báo tệp APK nào cho ứng dụng này.';

  @override
  String get findingAppNotFound => 'Ứng dụng này chưa được cài trên thiết bị.';

  @override
  String get findingSecureEnvRequired =>
      'Ứng dụng này yêu cầu môi trường bảo mật và không thể ảo hoá.';

  @override
  String findingSelfClone(String appName) {
    return '$appName không thể tự nhân bản chính nó.';
  }

  @override
  String get findingSystemComponent =>
      'Không thể nhân bản các thành phần hệ thống.';

  @override
  String get findingAbiNotSupported =>
      'Thư viện native của ứng dụng này không được biên dịch cho kiến trúc mà công cụ hỗ trợ.';

  @override
  String get findingAppArchiveUnavailable =>
      'This app\'s installation files are not on the device. It has been archived, or its installation is incomplete.';

  @override
  String findingStorageUnavailable(String appName) {
    return 'Ứng dụng này dùng bộ nhớ dùng chung, còn bản dựng $appName này không khai báo quyền truy cập mọi tệp. Bản sao của nó không thể chạm tới tệp của bạn và sẽ không hoạt động.';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return 'Ứng dụng này dùng bộ nhớ dùng chung. Hãy cấp cho $appName “quyền truy cập mọi tệp” trong Cài đặt → Quyền truy cập đặc biệt của ứng dụng trước khi mở bản sao, nếu không nó có thể bị từ chối khi khởi chạy.';
  }

  @override
  String get factsNoNativeCode => 'Không có mã native';

  @override
  String get factsAnyNoNativeCode => 'Bất kỳ — không có mã native';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => 'APK đơn';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'APK tách · $count tệp',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => 'không rõ';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => 'Nhập qua trình quản lý tệp';

  @override
  String get commonSave => 'Lưu';

  @override
  String get renameTitle => 'Đổi tên hồ sơ';

  @override
  String get renameFieldLabel => 'Tên hồ sơ';

  @override
  String get uninstallTitle => 'Gỡ cài đặt bản sao này?';

  @override
  String uninstallSpaceOf(int index, int count) {
    return 'Không gian $index trên $count';
  }

  @override
  String get uninstallMessage =>
      'Thao tác này sẽ xoá bản sao ứng dụng đã chọn và dữ liệu cục bộ của nó.';

  @override
  String get uninstallConfirm => 'Gỡ cài đặt';

  @override
  String get calculatorError => 'Lỗi';

  @override
  String get disclosureTitle => 'Trước khi bắt đầu';

  @override
  String disclosureIntro(String appName) {
    return '$appName chạy một bản sao thứ hai của những ứng dụng bạn chọn. Đây chính xác là những gì nó đọc và những gì nó sẽ hỏi bạn.';
  }

  @override
  String get disclosureAppsTitle => 'Ứng dụng đã cài của bạn';

  @override
  String disclosureAppsBody(String appName) {
    return 'Để hiển thị danh sách chọn bản sao, $appName đọc danh sách ứng dụng đã cài trên thiết bị này — tên, biểu tượng và phiên bản. Danh sách này ở lại trên thiết bị của bạn. Nó không bao giờ được tải lên, bán hay chia sẻ, và ứng dụng không có quảng cáo, không phân tích và không trình theo dõi.';
  }

  @override
  String get disclosurePermissionsTitle => 'Quyền thay mặt các bản sao';

  @override
  String disclosurePermissionsBody(String appName) {
    return 'Ứng dụng được nhân bản chạy bên trong $appName, nên một số quyền Android áp dụng cho nó thay mặt chúng. Bạn có thể được hỏi một lần để miễn trừ nó khỏi tối ưu hoá pin, giúp các ứng dụng nhắn tin được nhân bản vẫn nhận tin. Chỉ khi bạn nhân bản một ứng dụng tệp hoặc đa phương tiện, bạn mới có thể cần cấp quyền truy cập mọi tệp trong Cài đặt.';
  }

  @override
  String get disclosureControlTitle => 'Bạn vẫn kiểm soát';

  @override
  String get disclosureControlBody =>
      'Không có gì được yêu cầu âm thầm. Bạn có thể từ chối bất kỳ yêu cầu nào mà vẫn dùng được ứng dụng, và bạn có thể đổi ý trong Cài đặt Android bất cứ lúc nào.';

  @override
  String get disclosureAccept => 'Đồng ý và tiếp tục';

  @override
  String get privateSpaceTitle => 'Không gian riêng';

  @override
  String get privateSpaceOffTitle => 'Không gian riêng đang tắt';

  @override
  String get privateSpaceOffMessage =>
      'Bật nó lên để ẩn bản sao sau một mã PIN. Ứng dụng ẩn biến khỏi lưới chính và chỉ mở được ở đây.';

  @override
  String get privateSpaceSetUp => 'Thiết lập không gian riêng';

  @override
  String get privateSpaceChangePin => 'Đổi mã PIN';

  @override
  String get privateSpaceUnlockSection => 'Mở khoá';

  @override
  String get privateSpaceFingerprint => 'Mở khoá bằng vân tay';

  @override
  String get privateSpaceFingerprintAvailable =>
      'Bạn vẫn có thể dùng mã PIN bất cứ lúc nào.';

  @override
  String get privateSpaceFingerprintUnavailable =>
      'Thiết bị này chưa thiết lập vân tay hay khuôn mặt.';

  @override
  String get privateSpaceDisguiseSection => 'Nguỵ trang';

  @override
  String get privateSpaceDisguiseAsCalculator => 'Nguỵ trang thành máy tính';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return 'Thay biểu tượng $appName bằng một máy tính. Nhập mã PIN không gian riêng và nhấn = để mở ứng dụng.';
  }

  @override
  String get privateSpaceTurnOff => 'Tắt không gian riêng';

  @override
  String get privateSpaceTurnOffNote =>
      'Tắt nó sẽ đưa mọi ứng dụng ẩn về lại lưới chính. Bản thân các bản sao không bị xoá.';

  @override
  String get privateSpaceDisguiseOnTitle => 'Nguỵ trang thành máy tính?';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return 'Hiện lại $appName?';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return 'Biểu tượng của $appName được thay bằng một máy tính tên “Calculator”. Để mở $appName, hãy nhập mã PIN không gian riêng và nhấn =. Nếu quên mã PIN, bạn sẽ không mở được ứng dụng.';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return '$appName sẽ hiện lại biểu tượng và tên của chính nó trên màn hình chính.';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => 'Nguỵ trang';

  @override
  String get privateSpaceDisguiseConfirmOff => 'Hiện ứng dụng';

  @override
  String get privateSpaceDisguiseFailed =>
      'Không thay đổi được diện mạo của ứng dụng.';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return '$appName giờ trông như một máy tính trên màn hình chính của bạn.';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return '$appName đã trở lại màn hình chính của bạn.';
  }

  @override
  String get privateSpaceTurnOffTitle => 'Tắt không gian riêng?';

  @override
  String get privateSpaceTurnOffMessage =>
      'Mọi ứng dụng ẩn sẽ về lại lưới chính, và mã PIN sẽ bị quên. Các bản sao vẫn được giữ.';

  @override
  String get privateSpaceTurnOffConfirm => 'Tắt';

  @override
  String get privateSpaceTurnedOff => 'Đã tắt không gian riêng.';

  @override
  String get pinCreateTitle => 'Tạo mã PIN';

  @override
  String get pinChangeTitle => 'Đổi mã PIN';

  @override
  String get pinCreateMessage =>
      'Mã PIN này khoá không gian riêng. Hãy giữ nó ở nơi bạn không quên: không có cách nào lấy lại bản sao ẩn nếu thiếu nó.';

  @override
  String get pinChangeMessage => 'Nhập mã PIN hiện tại, rồi chọn mã mới.';

  @override
  String get pinCurrentLabel => 'Mã PIN hiện tại';

  @override
  String get pinNewLabel => 'Mã PIN mới';

  @override
  String get pinConfirmLabel => 'Xác nhận mã PIN';

  @override
  String get pinCreateConfirm => 'Tạo không gian riêng';

  @override
  String get pinSaveConfirm => 'Lưu mã PIN';

  @override
  String pinLengthError(int minimum, int maximum) {
    return 'Dùng từ $minimum đến $maximum chữ số.';
  }

  @override
  String get pinMismatchError => 'Hai mã PIN không khớp.';

  @override
  String get pinCurrentIncorrect => 'Mã PIN hiện tại không đúng.';

  @override
  String get unlockTitle => 'Mở khoá không gian riêng';

  @override
  String get unlockPinLabel => 'Mã PIN';

  @override
  String get unlockUseFingerprint => 'Dùng vân tay';

  @override
  String get unlockConfirm => 'Mở khoá';

  @override
  String get unlockIncorrectPin => 'Mã PIN sai';

  @override
  String get unlockFingerprintUnavailable =>
      'Mở khoá bằng vân tay hiện không khả dụng.';

  @override
  String get unlockFingerprintNotRecognised => 'Không nhận ra vân tay.';

  @override
  String get unlockBiometricReason => 'Mở khoá không gian riêng của bạn';

  @override
  String get privateTileEmpty => 'Không gian riêng, trống';

  @override
  String privateTileHidden(int count) {
    return 'Không gian riêng, $count ứng dụng ẩn';
  }

  @override
  String get settingsSectionPrivacy => 'Quyền riêng tư';

  @override
  String get settingsPrivateSpaceSubtitle => 'Ẩn ứng dụng sau một mã PIN';

  @override
  String get settingsOn => 'Bật';

  @override
  String get settingsOff => 'Tắt';

  @override
  String get componentBaseApk => 'APK cơ sở';

  @override
  String get componentSplitApk => 'APK tách';

  @override
  String get componentNoNativeLibraries => 'Không có thư viện native';

  @override
  String get errorProfileNameEmpty => 'Bản sao cần một tên.';

  @override
  String errorProfileNameTooLong(int maximum) {
    return 'Tên bản sao dài tối đa $maximum ký tự.';
  }

  @override
  String get errorProfileStorageUnreadable =>
      'Không đọc được các bản sao đã lưu của bạn.';

  @override
  String get errorProfileNotFound => 'Bản sao đó không còn nữa.';

  @override
  String get errorBridgeFailed =>
      'Có lỗi khi trao đổi với phần ứng dụng quản lý các bản sao.';

  @override
  String get errorBridgeUnsupportedPlatform =>
      'Tính năng này chỉ có trên Android.';

  @override
  String get errorTestAppCheckFailed =>
      'Không kiểm tra được ứng dụng thử nghiệm đã cài hay chưa.';

  @override
  String get errorEngineInitFailed =>
      'Công cụ ảo hoá không khởi động được trên thiết bị này.';

  @override
  String get errorEngineAndroidTooOld =>
      'Công cụ ảo hoá cần phiên bản Android mới hơn.';

  @override
  String get errorEngineNoResponse =>
      'Công cụ ảo hoá không phản hồi. Hãy thử lại.';

  @override
  String get errorNoContainer =>
      'Bản sao này chưa có vùng chứa. Hãy mở nó một lần rồi thử lại.';

  @override
  String get errorLaunchRefused => 'Công cụ đã từ chối mở bản sao này.';

  @override
  String get errorAlreadyCloned => 'Ứng dụng này đã được nhân bản rồi.';

  @override
  String get errorClearCacheFailed =>
      'Một phần bộ nhớ đệm của bản sao này không xoá được.';

  @override
  String get errorClearDataFailed => 'Không xoá được dữ liệu của bản sao này.';

  @override
  String get errorShortcutsUnsupported =>
      'Trình khởi chạy này không hỗ trợ thêm lối tắt.';

  @override
  String get errorShortcutRefused => 'Trình khởi chạy đã từ chối lối tắt.';

  @override
  String get errorApkGone =>
      'Tệp APK của bản sao này không còn trên thiết bị nên không có gì để chia sẻ.';

  @override
  String get errorShareFailed => 'Không chia sẻ được ứng dụng.';

  @override
  String get errorApkUnreadable =>
      'Không đọc được một trong các tệp APK đã chọn.';

  @override
  String get errorApkPackageMismatch =>
      'Tất cả APK đã chọn phải thuộc cùng một ứng dụng.';

  @override
  String get errorApkVersionMismatch =>
      'Tất cả APK đã chọn phải cùng một phiên bản.';

  @override
  String get errorApkBaseRequired =>
      'Hãy chọn đúng một APK cơ sở và một hoặc nhiều tệp tách cấu hình.';

  @override
  String get errorApkDuplicateSplit =>
      'Cùng một tệp tách APK đã được chọn nhiều lần.';
}
