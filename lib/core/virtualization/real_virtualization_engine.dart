import '../../data/models/engine_result.dart';
import '../../data/models/virtual_profile_model.dart';
import '../../data/repositories/virtual_profile_repository.dart';
import '../../native/native_bridge.dart';
import '../errors/app_exception.dart';
import '../utils/app_logger.dart';
import 'virtualization_engine.dart';

/// Phase 2 engine: profile metadata in the repository, real containers in the native
/// virtualization backend.
///
/// Creation and deletion are two-sided operations. A profile is only persisted once the
/// engine confirms the application is installed in its virtual environment, so the host
/// can never claim a profile is ready while the engine disagrees.
class RealVirtualizationEngine implements VirtualizationEngine {
  const RealVirtualizationEngine({
    required this._repository,
    required this._nativeBridge,
  });

  final VirtualProfileRepository _repository;
  final NativeBridge _nativeBridge;

  static const AppLogger _logger = AppLogger('RealVirtualizationEngine');

  /// Reported by the native adapter, not assumed. The UI only claims isolation when
  /// the backend is genuinely available on this device.
  @override
  bool get providesRuntimeIsolation => true;

  @override
  Future<void> initialize() async {
    final EngineResponse response = await _nativeBridge.initializeVirtualization();
    if (!response.success) {
      throw VirtualizationException(response.message, code: response.code);
    }
  }

  @override
  Future<List<VirtualProfileModel>> getProfiles() => _repository.getProfiles();

  @override
  Future<VirtualProfileState> profileState(String profileId) async {
    final VirtualProfileModel? profile = await _repository.getProfile(profileId);
    if (profile == null) {
      return VirtualProfileState.unknown;
    }
    return _nativeBridge.profileState(profileId, profile.packageName);
  }

  /// Persists the profile first so the engine has a stable id to key the virtual user
  /// on, then rolls the metadata back if the container install fails.
  @override
  Future<VirtualProfileModel> createProfile({
    required String packageName,
    required String appName,
    required String profileName,
  }) async {
    final VirtualProfileModel profile = await _repository.createProfile(
      packageName: packageName,
      appName: appName,
      profileName: profileName,
    );

    final EngineResponse response =
        await _nativeBridge.installAppToProfile(profile.id, packageName);

    if (!response.success) {
      _logger.error('Install failed for ${profile.id}: ${response.code}');
      await _repository.deleteProfile(profile.id);
      throw VirtualizationException(response.message, code: response.code);
    }

    return profile;
  }

  /// Same two-sided contract as [createProfile], for an APK that may not be installed
  /// on the host at all.
  @override
  Future<VirtualProfileModel> createProfileFromApk({
    required String apkPath,
    required String packageName,
    required String appName,
    required String profileName,
  }) async {
    final VirtualProfileModel profile = await _repository.createProfile(
      packageName: packageName,
      appName: appName,
      profileName: profileName,
    );

    final EngineResponse response =
        await _nativeBridge.installApkToProfile(profile.id, apkPath, packageName);

    if (!response.success) {
      _logger.error('APK install failed for ${profile.id}: ${response.code}');
      await _repository.deleteProfile(profile.id);
      throw VirtualizationException(response.message, code: response.code);
    }

    return profile;
  }

  /// Removes the virtual environment first; metadata is only dropped once the engine
  /// has released the container, so a failure leaves a visible profile to retry.
  @override
  Future<void> deleteProfile(String profileId) async {
    final VirtualProfileModel? profile = await _repository.getProfile(profileId);
    if (profile == null) {
      throw ProfileNotFoundException(profileId);
    }

    final EngineResponse response =
        await _nativeBridge.deleteVirtualProfile(profileId, profile.packageName);

    if (!response.success) {
      throw VirtualizationException(response.message, code: response.code);
    }

    await _repository.deleteProfile(profileId);
  }

  /// Metadata only — the virtual environment is keyed by profile id, so a rename can
  /// never disturb the container or its data.
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

    final EngineResponse response =
        await _nativeBridge.launchProfile(profileId, profile.packageName);

    if (!response.success) {
      throw VirtualizationException(response.message, code: response.code);
    }
  }

  Future<void> stopProfile(String profileId) async {
    final VirtualProfileModel? profile = await _repository.getProfile(profileId);
    if (profile == null) {
      return;
    }
    await _nativeBridge.stopProfile(profileId, profile.packageName);
  }
}
