import '../../data/models/virtual_profile_model.dart';
import '../../data/repositories/virtual_profile_repository.dart';
import '../../native/native_bridge.dart';
import '../errors/app_exception.dart';
import 'virtualization_engine.dart';

/// Phase 1 engine: metadata-only profiles plus a normal Android app launch.
///
/// It performs NO virtualization. There is no UID, process, package, storage or
/// framework isolation, and every profile that points at the same package shares
/// that package's single real runtime state.
class DemoVirtualizationEngine implements VirtualizationEngine {
  const DemoVirtualizationEngine({
    required VirtualProfileRepository repository,
    required NativeBridge nativeBridge,
  })  : _repository = repository,
        _nativeBridge = nativeBridge;

  final VirtualProfileRepository _repository;
  final NativeBridge _nativeBridge;

  @override
  bool get providesRuntimeIsolation => false;

  @override
  Future<List<VirtualProfileModel>> getProfiles() => _repository.getProfiles();

  @override
  Future<VirtualProfileModel> createProfile({
    required String packageName,
    required String appName,
    required String profileName,
  }) {
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

    // Selecting the profile has no runtime effect yet; the real package is started.
    await _nativeBridge.launchTestApp();
  }
}
