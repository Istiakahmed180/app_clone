import '../../data/models/engine_result.dart';
import '../../data/models/virtual_profile_model.dart';

/// Integration boundary for the Android virtualization backend.
///
/// [RealVirtualizationEngine] is what ships: it backs each profile with a real container
/// through the native adapter. [DemoVirtualizationEngine] remains as the reference no-op
/// implementation of this same interface, and is not bound in production.
///
/// The interface exists so the backend can be replaced without touching the UI or
/// controllers.
abstract class VirtualizationEngine {
  Future<VirtualProfileModel> createProfile({
    required String packageName,
    required String appName,
    required String profileName,
  /// Retired: per-container Google Play services provisioning.
  ///
  /// No production flow sets this any more -- the compatibility sheet's opt-in was removed
  /// once host GMS passthrough made it counterproductive: the engine's PackageManager
  /// hooks answer from the container first, so a provisioned copy *shadows* the host's
  /// genuine Play services, and the copy cannot bootstrap its own Chimera modules. Kept as
  /// a parameter so the native capability stays reachable for diagnostics and for a future
  /// provider that might provision legitimately. Defaults off; leave it off.
  /// See `docs/level10-gms-provider-migration.md`.
    bool installGms = false,
  });

  Future<void> deleteProfile(String profileId);

  Future<void> renameProfile(String profileId, String profileName);

  Future<void> launchProfile(String profileId);

  /// Stops the guest if it is running. Doing nothing is a valid outcome: a clone that
  /// was not running is already stopped.
  Future<void> stopProfile(String profileId);

  /// Empties this clone's container — databases, preferences, files, caches — leaving
  /// the package installed, so the next launch is a first launch.
  Future<void> clearProfileData(String profileId);

  /// Empties only this clone's caches. Logins and settings survive.
  Future<void> clearProfileCache(String profileId);

  Future<List<VirtualProfileModel>> getProfiles();

  /// Whether profiles launched by this engine get isolated runtime state.
  ///
  /// The UI uses this to describe honestly what a launch actually does.
  bool get providesRuntimeIsolation;

  /// Engine-observed state for one profile. Implementations that keep no runtime
  /// state return [VirtualProfileState.unknown].
  Future<VirtualProfileState> profileState(String profileId);

  /// Prepares the backend. Safe to call more than once.
  Future<void> initialize();

  /// Creates a profile from a standalone APK the user imported.
  Future<VirtualProfileModel> createProfileFromApk({
    required List<String> apkPaths,
    required String packageName,
    required String appName,
    required String profileName,
  /// Retired: per-container Google Play services provisioning.
  ///
  /// No production flow sets this any more -- the compatibility sheet's opt-in was removed
  /// once host GMS passthrough made it counterproductive: the engine's PackageManager
  /// hooks answer from the container first, so a provisioned copy *shadows* the host's
  /// genuine Play services, and the copy cannot bootstrap its own Chimera modules. Kept as
  /// a parameter so the native capability stays reachable for diagnostics and for a future
  /// provider that might provision legitimately. Defaults off; leave it off.
  /// See `docs/level10-gms-provider-migration.md`.
    bool installGms = false,
  });
}
