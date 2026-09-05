import '../../data/models/engine_result.dart';
import '../../data/models/virtual_profile_model.dart';

/// Integration boundary for a future, real Android virtualization engine.
///
/// Phase 1 ships only [DemoVirtualizationEngine]. The interface exists so a later
/// native implementation can replace it without touching the UI or controllers.
abstract class VirtualizationEngine {
  Future<VirtualProfileModel> createProfile({
    required String packageName,
    required String appName,
    required String profileName,
  });

  Future<void> deleteProfile(String profileId);

  Future<void> renameProfile(String profileId, String profileName);

  Future<void> launchProfile(String profileId);

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
    required String apkPath,
    required String packageName,
    required String appName,
    required String profileName,
  });
}
