import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/virtualization/virtualization_engine.dart';
import '../../../data/models/engine_result.dart';
import '../../../data/models/platform_info.dart';
import '../../../data/models/test_app_model.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../../native/native_bridge.dart';

class HomeController extends GetxController {
  HomeController({
    required this._engine,
    required this._nativeBridge,
  });

  final VirtualizationEngine _engine;
  final NativeBridge _nativeBridge;
  final AppLogger _logger = const AppLogger('HomeController');

  final RxList<VirtualProfileModel> profiles = <VirtualProfileModel>[].obs;
  final Rxn<TestAppModel> testApp = Rxn<TestAppModel>();
  final Rxn<PlatformInfo> platformInfo = Rxn<PlatformInfo>();
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<VirtualizationAvailability> virtualization =
      Rxn<VirtualizationAvailability>();
  final RxMap<String, VirtualProfileState> profileStates =
      <String, VirtualProfileState>{}.obs;

  bool get isTestAppInstalled => testApp.value?.installed ?? false;

  /// True only when the abstraction claims isolation AND the native backend confirms
  /// it is actually usable on this device.
  bool get providesRuntimeIsolation =>
      _engine.providesRuntimeIsolation && (virtualization.value?.available ?? false);

  String? get virtualizationProblem {
    final VirtualizationAvailability? state = virtualization.value;
    if (state == null || state.available) {
      return null;
    }
    return state.message ?? 'The virtualization engine is unavailable on this device.';
  }

  VirtualProfileState stateFor(VirtualProfileModel profile) =>
      profileStates[profile.id] ?? VirtualProfileState.unknown;

  String get testAppName => testApp.value?.displayName ?? AppConstants.testAppFallbackName;

  @override
  void onReady() {
    super.onReady();
    refreshAll();
  }

  Future<void> refreshAll() async {
    isLoading.value = true;
    await _loadVirtualization();
    await Future.wait<void>(<Future<void>>[_loadProfiles(), _loadTestApp()]);
    await _loadProfileStates();
    isLoading.value = false;
  }

  Future<void> _loadVirtualization() async {
    try {
      virtualization.value = await _nativeBridge.isVirtualizationAvailable();
    } on AppException catch (error, stackTrace) {
      _logger.error('Virtualization availability lookup failed', error, stackTrace);
      virtualization.value = null;
    }
  }

  /// Engine state is read per profile rather than inferred, so the card never shows
  /// "Ready" for a container the engine does not actually have.
  Future<void> _loadProfileStates() async {
    final Map<String, VirtualProfileState> states = <String, VirtualProfileState>{};
    for (final VirtualProfileModel profile in profiles) {
      try {
        states[profile.id] = await _engine.profileState(profile.id);
      } on AppException {
        states[profile.id] = VirtualProfileState.unknown;
      }
    }
    profileStates.assignAll(states);
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
      await _loadProfileStates();
      return null;
    } on AppException catch (error) {
      return error.message;
    }
  }

  Future<String?> deleteProfile(VirtualProfileModel profile) async {
    try {
      await _engine.deleteProfile(profile.id);
      await _loadProfiles();
      await _loadProfileStates();
      return null;
    } on AppException catch (error) {
      return error.message;
    }
  }
}
