import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/virtualization/virtualization_engine.dart';
import '../../../data/models/compatibility_report.dart';
import '../../../data/models/engine_result.dart';
import '../../../data/models/platform_info.dart';
import '../../../data/models/space_identity.dart';
import '../../../data/models/test_app_model.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../../data/repositories/virtual_profile_repository.dart';
import '../../../native/native_bridge.dart';

class HomeController extends GetxController {
  HomeController({
    required this._engine,
    required this._nativeBridge,
    required this._repository,
  });

  final VirtualizationEngine _engine;
  final NativeBridge _nativeBridge;

  /// Consulted only for what a new clone should be called. The same seam the picker
  /// uses, so both flows name clones by one rule.
  final VirtualProfileRepository _repository;
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
      profiles.assignAll(_grouped(await _engine.getProfiles()));
      errorMessage.value = null;
    } on AppException catch (error) {
      errorMessage.value = error.message;
    }
  }

  /// Grid order: clones of the same app together, numbered ascending, apps A-Z.
  ///
  /// The repository returns creation order, which on a grid of icons scatters an app's
  /// clones — Facebook 1, WhatsApp 1, Facebook 2 — and makes the instance numbers
  /// unreadable. Grouping puts every Facebook side by side, in order.
  ///
  /// Sorted on [VirtualProfileModel.appName], not [VirtualProfileModel.profileName]:
  /// grouping is by *app*, so renaming one clone must never move it away from its
  /// siblings. [packageName] breaks the tie between two different apps that share a
  /// name (a device can genuinely have two apps called "Notes"), so each package's
  /// clones stay contiguous, and [createdAt] then puts clone 1 before clone 2 — the
  /// same order [instanceIndex] numbers them in.
  static List<VirtualProfileModel> _grouped(
    List<VirtualProfileModel> profiles,
  ) {
    return profiles.toList()
      ..sort((VirtualProfileModel a, VirtualProfileModel b) {
        final int byApp = a.appName.toLowerCase().compareTo(
          b.appName.toLowerCase(),
        );
        if (byApp != 0) {
          return byApp;
        }
        final int byPackage = a.packageName.compareTo(b.packageName);
        if (byPackage != 0) {
          return byPackage;
        }
        final int byAge = a.createdAt.compareTo(b.createdAt);
        // Two clones created in the same millisecond would otherwise order
        // unpredictably between reloads.
        return byAge != 0 ? byAge : a.id.compareTo(b.id);
      });
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
  /// Clones whose guest process is being started.
  ///
  /// Kept here so the tile itself can say so. A launch takes a second or two — the
  /// engine has to bring up a stub process and hand it the package — and a tile that
  /// looked untouched for that long read as a tap that did not register.
  final RxSet<String> launching = <String>{}.obs;

  Future<String?> launchProfile(VirtualProfileModel profile) async {
    launching.add(profile.id);
    try {
      await _engine.launchProfile(profile.id);
      return null;
    } on AppException catch (error) {
      return error.message;
    } finally {
      // In `finally`, so a refused launch clears the tile rather than leaving it
      // spinning on a guest that is never going to start.
      launching.remove(profile.id);
      // The guest is running now, which the tile's dot reports.
      await _loadProfileStates();
    }
  }

  /// What a pinned shortcut should be called.
  ///
  /// Every clone carries its app's own name, so three copies of one app would pin three
  /// shortcuts all called "CABEX-FX" — and the launcher's answer to that is to append
  /// "-1", "-2" itself, which says nothing about *which* clone. Appending the space
  /// number instead makes the label say it.
  ///
  /// A clone the user renamed keeps that name untouched: they already chose something
  /// distinctive, and numbering it would be second-guessing them.
  String shortcutLabel(VirtualProfileModel profile) {
    if (profile.profileName.trim() != profile.appName.trim()) {
      return profile.profileName;
    }
    return siblingCount(profile) > 1
        ? '${profile.profileName} ${instanceIndex(profile)}'
        : profile.profileName;
  }

  /// Asks the launcher to add this clone to the home screen.
  ///
  /// Returns null when the request was accepted, or a user-facing message otherwise.
  Future<String?> addShortcut(VirtualProfileModel profile) async {
    try {
      await _nativeBridge.pinCloneShortcut(
        profileId: profile.id,
        packageName: profile.packageName,
        label: shortcutLabel(profile),
        spaceIndex: instanceIndex(profile),
        spaceCount: siblingCount(profile),
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

  /// The identifiers this space presents as its own.
  ///
  /// [action] is `read`, `regenerate` or `reset`. Not cached: Modify and Reset change
  /// the answer, and a stale set on this screen would be a set the user cannot trust.
  Future<SpaceIdentity> spaceIdentity(
    VirtualProfileModel profile, {
    String action = 'read',
    Map<String, String>? values,
  }) => _nativeBridge.spaceIdentity(profile.id, action: action, values: values);

  /// Makes [count] more clones of this app.
  ///
  /// Each one is a container install of a few seconds, so [onProgress] reports as they
  /// land and the caller can say so — twenty clones is close to a minute of work, and
  /// a screen that simply froze would look broken.
  ///
  /// Keeps going after a failure and reports the tally. Stopping at the first error
  /// would leave the user with an unexplained partial result; carrying on gets them as
  /// many as the engine will give and then says exactly what happened.
  ///
  /// Returns null when every clone was created, or a user-facing message otherwise.
  Future<String?> createClones(
    VirtualProfileModel profile,
    int count, {
    void Function(int created, int total)? onProgress,
  }) async {
    int created = 0;
    String? firstFailure;

    for (int index = 0; index < count; index++) {
      try {
        await _engine.createProfile(
          packageName: profile.packageName,
          appName: profile.appName,
          profileName: await _repository.suggestProfileName(
            appName: profile.appName,
            packageName: profile.packageName,
          ),
        );
        created++;
      } on AppException catch (error) {
        firstFailure ??= error.message;
      }
      onProgress?.call(created, count);
    }

    await refreshAll();

    if (firstFailure == null) {
      return null;
    }
    if (created == 0) {
      return firstFailure;
    }
    return 'Created $created of $count. $firstFailure';
  }

  /// Stops the guest if it is running. Returns null on success.
  Future<String?> forceStop(VirtualProfileModel profile) async {
    try {
      await _engine.stopProfile(profile.id);
      // The card's dot is driven by engine-reported state, so re-read it rather than
      // assuming the stop took effect.
      await _loadProfileStates();
      return null;
    } on AppException catch (error) {
      return error.message;
    }
  }

  /// Empties this clone's caches. Logins and settings survive.
  Future<String?> clearCache(VirtualProfileModel profile) async {
    try {
      await _engine.clearProfileCache(profile.id);
      return null;
    } on AppException catch (error) {
      return error.message;
    }
  }

  /// Empties this clone's container. The next launch is a first launch.
  Future<String?> clearStorage(VirtualProfileModel profile) async {
    try {
      await _engine.clearProfileData(profile.id);
      await _loadProfileStates();
      return null;
    } on AppException catch (error) {
      return error.message;
    }
  }

  /// Offers this clone's APK to the share sheet.
  ///
  /// Goes straight to the bridge rather than through [VirtualizationEngine]: sharing a
  /// file is a host operation, not something a container backend would implement — the
  /// same reason shortcuts and permission requests bypass the engine.
  Future<String?> shareApp(VirtualProfileModel profile) async {
    try {
      await _nativeBridge.shareProfileApk(
        profileId: profile.id,
        packageName: profile.packageName,
        label: profile.appName,
      );
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

  /// How long a tile takes to fade out of the grid.
  ///
  /// Short: this is the gap between the user confirming and the clone being gone, and
  /// an uninstall that feels slow feels broken.
  static const Duration removalAnimation = Duration(milliseconds: 220);

  /// Clones whose tiles are on their way out.
  ///
  /// Kept here rather than in the view so the grid keeps rendering the tile while it
  /// animates: a profile removed from [profiles] first has nothing left to animate, and
  /// the tile would simply blink out of existence.
  final RxSet<String> removing = <String>{}.obs;

  /// Removes the clone, letting its tile animate out first.
  ///
  /// Returns the error message if the engine refused, in which case the tile comes back
  /// rather than staying half-faded on a grid it is still part of.
  Future<String?> uninstall(VirtualProfileModel profile) async {
    removing.add(profile.id);
    await Future<void>.delayed(removalAnimation);
    final String? error = await deleteProfile(profile);
    removing.remove(profile.id);
    return error;
  }
}
