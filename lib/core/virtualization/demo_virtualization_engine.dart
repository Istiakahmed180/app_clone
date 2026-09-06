import '../../data/models/engine_result.dart';
import '../../data/models/virtual_profile_model.dart';
import '../../data/repositories/virtual_profile_repository.dart';
import '../../native/native_bridge.dart';
import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import 'virtualization_engine.dart';

/// Phase 1 engine: metadata-only profiles plus a normal Android app launch.
///
/// It performs NO virtualization. There is no UID, process, package, storage or
/// framework isolation, and every profile that points at the same package shares
/// that package's single real runtime state.
class DemoVirtualizationEngine implements VirtualizationEngine {
  const DemoVirtualizationEngine({
    required this._repository,
    required this._nativeBridge,
  });

  final VirtualProfileRepository _repository;
  final NativeBridge _nativeBridge;

  @override
  bool get providesRuntimeIsolation => false;

  @override
  Future<VirtualProfileModel> createProfileFromApk({
    required String apkPath,
    required String packageName,
    required String appName,
    required String profileName,
    bool installGms = false,
  }) {
    throw const VirtualizationException(
      'This engine cannot install APKs.',
      code: 'VIRTUALIZATION_NOT_AVAILABLE',
    );
  }

  @override
  Future<void> initialize() async {
    // Nothing to prepare: this engine has no backend.
  }

  @override
  Future<VirtualProfileState> profileState(String profileId) async =>
      VirtualProfileState.unknown;

  @override
  Future<List<VirtualProfileModel>> getProfiles() => _repository.getProfiles();

  @override
  Future<VirtualProfileModel> createProfile({
    required String packageName,
    required String appName,
    required String profileName,
    bool installGms = false,
  }) {
    // This engine performs no virtualization, so there is nothing to provision GMS into;
    // the flag is accepted to satisfy the interface and ignored.
    return _repository.createProfile(
      packageName: packageName,
      appName: appName,
      profileName: profileName,
    );
  }

  /// Removes profile metadata only. The installed application is left untouched.
  @override
  Future<void> deleteProfile(String profileId) => _repository.deleteProfile(profileId);

  @override
  Future<void> renameProfile(String profileId, String profileName) async {
    await _repository.updateProfile(profileId, profileName: profileName);
  }

  @override
  Future<void> launchProfile(String profileId) async {
    final VirtualProfileModel? profile = await _repository.getProfile(profileId);
    if (profile == null) {
      throw ProfileNotFoundException(profileId);
    }

    // Phase 1 can only launch the one controlled package. Fail loudly rather than
    // silently starting the test app for a profile that points somewhere else.
    if (profile.packageName != AppConstants.testAppPackage) {
      throw const LaunchException(
        'Only the controlled test application can be launched in Phase 1.',
        code: 'UNSUPPORTED_PACKAGE',
      );
    }

    // Selecting the profile has no runtime effect yet; the real package is started.
    await _nativeBridge.launchTestApp();
  }
}
