import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/virtualization/virtualization_engine.dart';
import '../../../data/models/platform_info.dart';
import '../../../data/models/test_app_model.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../../native/native_bridge.dart';

class HomeController extends GetxController {
  HomeController({
    required VirtualizationEngine engine,
    required NativeBridge nativeBridge,
  })  : _engine = engine,
        _nativeBridge = nativeBridge;

  final VirtualizationEngine _engine;
  final NativeBridge _nativeBridge;
  final AppLogger _logger = const AppLogger('HomeController');

  final RxList<VirtualProfileModel> profiles = <VirtualProfileModel>[].obs;
  final Rxn<TestAppModel> testApp = Rxn<TestAppModel>();
  final Rxn<PlatformInfo> platformInfo = Rxn<PlatformInfo>();
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  bool get isTestAppInstalled => testApp.value?.installed ?? false;

  bool get providesRuntimeIsolation => _engine.providesRuntimeIsolation;

  String get testAppName => testApp.value?.displayName ?? AppConstants.testAppFallbackName;

  @override
  void onReady() {
    super.onReady();
    refreshAll();
  }

  Future<void> refreshAll() async {
    isLoading.value = true;
    await Future.wait<void>(<Future<void>>[_loadProfiles(), _loadTestApp()]);
    isLoading.value = false;
  }

  Future<void> _loadProfiles() async {
    try {
      profiles.assignAll(await _engine.getProfiles());
      errorMessage.value = null;
    } on AppException catch (error) {
      errorMessage.value = error.message;
    }
  }

  Future<void> _loadTestApp() async {
    try {
      testApp.value = await _nativeBridge.getTestAppInfo() ??
          const TestAppModel.notInstalled(AppConstants.testAppPackage);
      platformInfo.value = await _nativeBridge.getPlatformInfo();
    } on NativeBridgeException catch (error, stackTrace) {
      _logger.error('Native lookup failed', error, stackTrace);
      testApp.value = const TestAppModel.notInstalled(AppConstants.testAppPackage);
    }
  }

  /// Returns `null` on success, or a user-facing message on failure.
  Future<String?> launchProfile(VirtualProfileModel profile) async {
    try {
      await _engine.launchProfile(profile.id);
      return null;
    } on AppException catch (error) {
      return error.message;
    }
  }

  Future<String?> renameProfile(VirtualProfileModel profile, String name) async {
    try {
      await _engine.renameProfile(profile.id, name);
      await _loadProfiles();
      return null;
    } on AppException catch (error) {
      return error.message;
    }
  }

  Future<String?> deleteProfile(VirtualProfileModel profile) async {
    try {
      await _engine.deleteProfile(profile.id);
      await _loadProfiles();
      return null;
    } on AppException catch (error) {
      return error.message;
    }
  }
}
