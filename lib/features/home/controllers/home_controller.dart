import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/virtualization/virtualization_engine.dart';
import '../../../data/models/compatibility_report.dart';
import '../../../data/models/engine_result.dart';
import '../../../data/models/platform_info.dart';
import '../../../data/models/test_app_model.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../../native/native_bridge.dart';

class HomeController extends GetxController {
  HomeController({required this._engine, required this._nativeBridge});

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
  final RxMap<String, Uint8List> appIcons = <String, Uint8List>{}.obs;
  final RxMap<String, CompatibilityReport> compatibility =
      <String, CompatibilityReport>{}.obs;

  bool get isTestAppInstalled => testApp.value?.installed ?? false;

  /// True only when the abstraction claims isolation AND the native backend confirms
  /// it is actually usable on this device.
  bool get providesRuntimeIsolation =>
      _engine.providesRuntimeIsolation &&
      (virtualization.value?.available ?? false);

  String? get virtualizationProblem {
    final VirtualizationAvailability? state = virtualization.value;
    if (state == null || state.available) {
      return null;
    }
    return state.message ??
        'The virtualization engine is unavailable on this device.';
  }

  VirtualProfileState stateFor(VirtualProfileModel profile) =>
      profileStates[profile.id] ?? VirtualProfileState.unknown;

  /// Compatibility problems worth showing on an existing clone's card.
  ///
  /// `APP_NOT_FOUND` is filtered out deliberately: it only means the package is not
  /// installed on the host, which is the normal state for a clone created from an imported
  /// APK. That clone has its own container and works fine, so flagging it would be a false
  /// alarm about the very feature that put it there.
  List<CompatibilityFinding> warningsFor(VirtualProfileModel profile) {
    final CompatibilityReport? report = compatibility[profile.packageName];
    if (report == null || !report.analysed) {
      return const <CompatibilityFinding>[];
    }
    return report.findings
        .where(
          (CompatibilityFinding f) => f.code != AppConstants.errorAppNotFound,
        )
        .toList(growable: false);
  }

  /// Whether this clone's app still needs runtime permissions the host does not hold.
  ///
  /// Read from the same analysis the warning text comes from, so the menu entry appears
  /// exactly when the warning does.
  bool needsPermissions(VirtualProfileModel profile) =>
      compatibility[profile.packageName]?.needsPermissions ?? false;

  /// Asks the user to grant the guest's outstanding permissions to Duplika.
  ///
  /// Guests run under the host's identity, so the grant has to land on the host. Without
  /// this the card could only state the problem: a clone whose app needs media access would
  /// sit there with nothing to show and no way to fix it.
  ///
  /// Returns null on success, or a user-facing message.
  Future<String?> grantPermissions(VirtualProfileModel profile) async {
    try {
      await _nativeBridge.requestGuestPermissions(profile.packageName);
      // The grant changes the verdict, so re-analyse rather than trusting the cached one.
      await _loadCompatibility();
      return null;
    } on AppException catch (error) {
      return error.message;
    }
  }

  /// Icon for a profile's package, or null for a clone whose APK is not installed
  /// on the host (the card then falls back to a placeholder).
  Uint8List? iconFor(VirtualProfileModel profile) =>
      appIcons[profile.packageName];

  /// How many profiles share this profile's package, used to label multi-instance clones.
  int siblingCount(VirtualProfileModel profile) => _siblings(profile).length;

  /// This clone's 1-based position among clones of the same app, ordered by creation.
  int instanceIndex(VirtualProfileModel profile) {
    final int index = _siblings(
      profile,
    ).indexWhere((VirtualProfileModel other) => other.id == profile.id);
    return index < 0 ? 1 : index + 1;
  }

  List<VirtualProfileModel> _siblings(VirtualProfileModel profile) =>
      profiles
          .where(
            (VirtualProfileModel other) =>
                other.packageName == profile.packageName,
          )
          .toList(growable: false)
        ..sort(
          (VirtualProfileModel a, VirtualProfileModel b) =>
              a.createdAt.compareTo(b.createdAt),
        );

  String get testAppName =>
      testApp.value?.displayName ?? AppConstants.testAppFallbackName;

  @override
  void onReady() {
    super.onReady();
    refreshAll();
  }

  Future<void> refreshAll() async {
    isLoading.value = true;
    await _loadVirtualization();
    await Future.wait<void>(<Future<void>>[_loadProfiles(), _loadTestApp()]);
    await Future.wait<void>(<Future<void>>[
      _loadProfileStates(),
      _loadIcons(),
      _loadCompatibility(),
    ]);
    isLoading.value = false;
  }

  Future<void> _loadVirtualization() async {
    try {
      // NativeApplication attaches Bcore before Flutter starts, but the Dart engine
      // still needs to complete its readiness handshake before the UI enables clone
      // launch. Without this call RealVirtualizationEngine remains in its initial
      // unavailable state even though the native backend is healthy.
      await _engine.initialize();
      virtualization.value = await _nativeBridge.isVirtualizationAvailable();
    } on AppException catch (error, stackTrace) {
      _logger.error(
        'Virtualization availability lookup failed',
        error,
        stackTrace,
      );
      try {
        virtualization.value = await _nativeBridge.isVirtualizationAvailable();
      } on AppException catch (availabilityError, availabilityStackTrace) {
        _logger.error(
          'Virtualization availability lookup failed after initialization',
          availabilityError,
          availabilityStackTrace,
        );
        virtualization.value = null;
      }
    }
  }

  /// Engine state is read per profile rather than inferred, so the card never shows
  /// "Ready" for a container the engine does not actually have.
  Future<void> _loadProfileStates() async {
    final Map<String, VirtualProfileState> states =
        <String, VirtualProfileState>{};
    for (final VirtualProfileModel profile in profiles) {
      try {
        states[profile.id] = await _engine.profileState(profile.id);
      } on AppException {
        states[profile.id] = VirtualProfileState.unknown;
      }
    }
    profileStates.assignAll(states);
  }

  /// Icons come from the host package manager, so clones of apps that are not installed
  /// normally simply have none.
  Future<void> _loadIcons() async {
    if (profiles.isEmpty) {
      return;
    }
    try {
      // Only the packages actually cloned, not every launchable app on the device.
      final Set<String> packages = profiles
          .map((VirtualProfileModel p) => p.packageName)
          .toSet();
      appIcons.assignAll(await _nativeBridge.getAppIcons(packages));
    } on AppException catch (error, stackTrace) {
      _logger.error('Could not load app icons', error, stackTrace);
    }
  }

  /// Analyses each distinct cloned package once, not once per clone.
  Future<void> _loadCompatibility() async {
    final Set<String> packages = profiles
        .map((VirtualProfileModel p) => p.packageName)
        .toSet();
    if (packages.isEmpty) {
      compatibility.clear();
      return;
    }

    final Map<String, CompatibilityReport> reports =
        <String, CompatibilityReport>{};
    for (final String packageName in packages) {
      try {
        reports[packageName] = await _nativeBridge.analyzeApp(packageName);
      } on AppException catch (error, stackTrace) {
        _logger.error(
          'Compatibility analysis failed for $packageName',
          error,
          stackTrace,
        );
      }
    }
    compatibility.assignAll(reports);
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
      testApp.value =
          await _nativeBridge.getTestAppInfo() ??
          const TestAppModel.notInstalled(AppConstants.testAppPackage);
      platformInfo.value = await _nativeBridge.getPlatformInfo();
    } on NativeBridgeException catch (error, stackTrace) {
      _logger.error('Native lookup failed', error, stackTrace);
      testApp.value = const TestAppModel.notInstalled(
        AppConstants.testAppPackage,
      );
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

  /// Asks the launcher to add this clone to the home screen.
  ///
  /// Returns null when the request was accepted, or a user-facing message otherwise.
  Future<String?> addShortcut(VirtualProfileModel profile) async {
    try {
      await _nativeBridge.pinCloneShortcut(
        profileId: profile.id,
        packageName: profile.packageName,
        label: profile.profileName,
      );
      return null;
    } on AppException catch (error) {
      return error.message;
    }
  }

  Future<String?> renameProfile(
    VirtualProfileModel profile,
    String name,
  ) async {
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
