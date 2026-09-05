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
}
