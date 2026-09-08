import '../../data/models/engine_result.dart';
import '../../data/models/virtual_profile_model.dart';
import '../../data/repositories/virtual_profile_repository.dart';
import '../../native/native_bridge.dart';
import '../diagnostics/diagnostic_event.dart';
import '../diagnostics/diagnostic_operation.dart';
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
  RealVirtualizationEngine({
    required this._repository,
    required this._nativeBridge,
  });

  final VirtualProfileRepository _repository;
  final NativeBridge _nativeBridge;

  static const AppLogger _logger = AppLogger('RealVirtualizationEngine');

  bool _available = false;

  /// Reported by the native adapter, not assumed. The UI only claims isolation when
  /// the backend is genuinely available on this device.
  @override
  bool get providesRuntimeIsolation => _available;

  /// Correlation ids are minted here, at the top of each user-visible operation.
  ///
  /// This layer is the right place for them: it is the outermost point that knows what
  /// the user asked for, and everything below it — the channel, the Kotlin engine, the
  /// installer, Bcore — inherits the id without being told about it. A launch that fails
  /// four layers down then reads as one timeline rather than as scattered lines.
  static const DiagnosticSource _source = DiagnosticSource.virtualEngine;

  @override
  Future<void> initialize() => DiagnosticOperation.run<void>(
        'engine_init',
        (DiagnosticOperation operation) async {
          final VirtualizationAvailability availability =
              await _nativeBridge.isVirtualizationAvailable();
          operation.step(
            'Engine availability: ${availability.available ? 'available' : 'unavailable'}'
            ' (${availability.backend})',
            source: _source,
            category: DiagnosticCategory.appLifecycle,
            level: availability.available
                ? DiagLevel.info
                : DiagLevel.warning,
            metadata: <String, String>{
              if (availability.code != null) 'code': availability.code!,
            },
          );

          if (!availability.available) {
            _available = false;
            throw VirtualizationException(
              availability.message ?? 'The virtualization engine is unavailable.',
              code: availability.code ?? 'VIRTUALIZATION_NOT_AVAILABLE',
            );
          }

          final EngineResponse response = await _nativeBridge.initializeVirtualization();
          if (!response.success) {
            _available = false;
            throw VirtualizationException(response.message, code: response.code);
          }
          _available = true;
        },
        name: 'engine initialization',
        source: _source,
        category: DiagnosticCategory.appLifecycle,
      );

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
    bool installGms = false,
  }) =>
      DiagnosticOperation.run<VirtualProfileModel>(
        'clone',
        (DiagnosticOperation operation) async {
          final VirtualProfileModel profile = await _repository.createProfile(
            packageName: packageName,
            appName: appName,
            profileName: profileName,
          );
          operation.step(
            'Profile metadata written: ${profile.id}',
            source: _source,
            category: DiagnosticCategory.profile,
            metadata: <String, String>{'installGms': '$installGms'},
          );

          final EngineResponse response = await _nativeBridge.installAppToProfile(
            profile.id,
            packageName,
            installGms: installGms,
          );

          if (!response.success) {
            _logger.error('Install failed for ${profile.id}: ${response.code}');
            operation.step(
              'Rolling back profile metadata after a failed install',
              source: _source,
              category: DiagnosticCategory.profile,
              level: DiagLevel.warning,
              metadata: <String, String>{'code': response.code},
            );
            await _repository.deleteProfile(profile.id);
            throw VirtualizationException(response.message, code: response.code);
          }

          return profile;
        },
        name: 'clone $appName',
        packageName: packageName,
        source: _source,
        category: DiagnosticCategory.install,
      );

  /// Same two-sided contract as [createProfile], for an APK that may not be installed
  /// on the host at all.
  @override
  Future<VirtualProfileModel> createProfileFromApk({
    required List<String> apkPaths,
    required String packageName,
    required String appName,
    required String profileName,
    bool installGms = false,
  }) =>
      DiagnosticOperation.run<VirtualProfileModel>(
        'import',
        (DiagnosticOperation operation) async {
          final VirtualProfileModel profile = await _repository.createProfile(
            packageName: packageName,
            appName: appName,
            profileName: profileName,
          );
          operation.step(
            'Profile metadata written for an imported APK set: ${profile.id}',
            source: _source,
            category: DiagnosticCategory.import,
            metadata: <String, String>{
              'apkCount': '${apkPaths.length}',
              'installGms': '$installGms',
            },
          );

          final EngineResponse response = await _nativeBridge.installApkToProfile(
            profile.id,
            apkPaths,
            packageName,
            installGms: installGms,
          );

          if (!response.success) {
            _logger.error('APK install failed for ${profile.id}: ${response.code}');
            operation.step(
              'Rolling back profile metadata after a failed APK install',
              source: _source,
              category: DiagnosticCategory.import,
              level: DiagLevel.warning,
              metadata: <String, String>{'code': response.code},
            );
            await _repository.deleteProfile(profile.id);
            throw VirtualizationException(response.message, code: response.code);
          }

          return profile;
        },
        name: 'import $appName',
        packageName: packageName,
        source: _source,
        category: DiagnosticCategory.import,
      );

  /// Removes the virtual environment first; metadata is only dropped once the engine
  /// has released the container, so a failure leaves a visible profile to retry.
  @override
  Future<void> deleteProfile(String profileId) async {
    // Resolved before the operation starts so the timeline can be labelled with the app
    // and package rather than with a bare UUID.
    final VirtualProfileModel? profile = await _repository.getProfile(profileId);
    if (profile == null) {
      throw ProfileNotFoundException(profileId);
    }

    return DiagnosticOperation.run<void>(
      'delete',
      (DiagnosticOperation operation) async {
        final EngineResponse response =
            await _nativeBridge.deleteVirtualProfile(profileId, profile.packageName);

        if (!response.success) {
          throw VirtualizationException(response.message, code: response.code);
        }

        await _repository.deleteProfile(profileId);
        operation.step(
          'Profile metadata removed',
          source: _source,
          category: DiagnosticCategory.profile,
          level: DiagLevel.success,
        );
      },
      name: 'delete ${profile.appName}',
      packageName: profile.packageName,
      profileId: profileId,
      source: _source,
      category: DiagnosticCategory.profile,
    );
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

    return DiagnosticOperation.run<void>(
      'launch',
      (DiagnosticOperation operation) async {
        operation.step(
          'Profile resolved: ${profile.profileName} (${profile.packageName})',
          source: _source,
          category: DiagnosticCategory.launch,
        );

        final EngineResponse response =
            await _nativeBridge.launchProfile(profileId, profile.packageName);

        if (!response.success) {
          throw VirtualizationException(response.message, code: response.code);
        }
      },
      name: 'launch ${profile.appName}',
      packageName: profile.packageName,
      profileId: profileId,
      source: _source,
      category: DiagnosticCategory.launch,
    );
  }

  Future<void> stopProfile(String profileId) async {
    final VirtualProfileModel? profile = await _repository.getProfile(profileId);
    if (profile == null) {
      return;
    }
    await _nativeBridge.stopProfile(profileId, profile.packageName);
  }
}
