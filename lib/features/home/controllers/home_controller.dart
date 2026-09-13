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
import '../../../data/models/clone_budget.dart';
import '../../../data/models/device_capacity.dart';
import '../../../data/models/test_app_model.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../../data/repositories/virtual_profile_repository.dart';
import '../../../native/native_bridge.dart';
import '../../private_space/controllers/private_space_controller.dart';

class HomeController extends GetxController {
  HomeController({
    required this._engine,
    required this._nativeBridge,
    required this._repository,
    required this._privateSpace,
  });

  final VirtualizationEngine _engine;
  final NativeBridge _nativeBridge;

  /// Consulted only for what a new clone should be called. The same seam the picker
  /// uses, so both flows name clones by one rule.
  final VirtualProfileRepository _repository;

  /// The lock and the hidden-clone flag. The grid reads [visibleProfiles] and the
  /// Private space screen reads [hiddenProfiles] from the same loaded list.
  final PrivateSpaceController _privateSpace;
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

  /// True once the user has set up the Private space. While it is false, the `hidden`
  /// flag is simply not applied — there is no lock for a hidden clone to sit behind.
  bool get privateSpaceEnabled => _privateSpace.enabled;

  /// Clones shown on the main grid.
  List<VirtualProfileModel> get visibleProfiles => privateSpaceEnabled
      ? profiles.where((VirtualProfileModel p) => !p.hidden).toList(growable: false)
      : profiles.toList(growable: false);

  /// Clones kept behind the lock, in the same grouped order as the main grid.
  List<VirtualProfileModel> get hiddenProfiles => privateSpaceEnabled
      ? profiles.where((VirtualProfileModel p) => p.hidden).toList(growable: false)
      : const <VirtualProfileModel>[];

  int get hiddenCount => hiddenProfiles.length;

  /// Whether the grid is currently showing the hidden clones instead of the main set.
  ///
  /// Session-only: leaving the app or locking the space drops back to the main grid, so
  /// handing the phone over cannot leave the hidden apps on screen.
  final RxBool viewingPrivate = false.obs;

  PrivateSpaceController get privateSpace => _privateSpace;

  void enterPrivateSpace() {
    if (privateSpaceEnabled) {
      viewingPrivate.value = true;
    }
  }

  void exitPrivateSpace() => viewingPrivate.value = false;

  /// Moves a clone in or out of the Private space, then lets the grid reload.
  Future<void> setHidden(VirtualProfileModel profile, bool hidden) =>
      _privateSpace.setHidden(profile.id, hidden);

  Future<void> unhideAll() => _privateSpace.unhideAll();

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
  void onInit() {
    super.onInit();
    // Hiding or unhiding a clone, or turning the space off, rewrites the same list this
    // controller shows. Reloading on the revision counter keeps the two in step without
    // either controller reaching into the other's state.
    ever<int>(_privateSpace.revision, (_) => refreshAll());
    // Relocking the space (on a timer, on backgrounding, or when it is turned off) also
    // drops the grid back to the main set, so the hidden clones are never left on screen.
    ever<bool>(_privateSpace.unlocked, (bool unlocked) {
      if (!unlocked) {
        viewingPrivate.value = false;
      }
    });
  }

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
  /// A batch beyond what the device can take is refused before any of it is attempted:
  /// filling the disk one container at a time takes a minute to arrive at a failure
  /// [cloneBudget] already knew about.
  ///
  /// Returns null when every clone was created, or a user-facing message otherwise.
  Future<String?> createClones(
    VirtualProfileModel profile,
    int count, {
    void Function(int created, int total)? onProgress,
  }) async {
    final String? refusal = await _budgetRefusal(profile, count);
    if (refusal != null) {
      return refusal;
    }

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

  /// The most clones the dialog will ever offer, whatever the device could take.
  ///
  /// A stepper is for a small number. Past twenty the honest control is a text field,
  /// and nobody has asked for one.
  static const int _absoluteMaximum = 20;

  /// Space the device keeps for itself, held back from the clone estimate.
  ///
  /// Android starts refusing writes and running its own cleanup well before a volume
  /// reaches zero, so a batch sized to the last free byte would fail anyway — and take
  /// the user's other apps down with it.
  static const int _storageHeadroomBytes = 512 * 1024 * 1024;

  /// What one more clone of an app that already has one actually costs on disk.
  ///
  /// Measured, not guessed: forty-five containers of a single app occupied 2.6 MB of the
  /// engine's store — about 40 KB each — because the package is installed once and every
  /// clone after it gets only its own empty data directories. Rounded up for the odd
  /// device with larger blocks.
  ///
  /// It is deliberately not the app's APK size. Charging a clone for a copy of the
  /// archive that is never made refuses batches the device would have taken easily.
  static const int _perCloneBytes = 64 * 1024;

  /// How many more clones this device should be offered, and why.
  ///
  /// The count dialog takes its ceiling from here and [createClones] checks against the
  /// same figure, so the app can never offer a number it will then refuse.
  ///
  /// A device that will not answer gets the full offer. A capability check that failed
  /// must not stand between the user and a clone that would have worked.
  Future<CloneBudget> cloneBudget() async {
    final DeviceCapacity capacity;
    try {
      capacity = await _nativeBridge.deviceCapacity();
    } on AppException catch (error) {
      _logger.warning('Clone budget fell back to the default: ${error.message}');
      return const CloneBudget(
        maximum: _absoluteMaximum,
        reason: 'Choose from 1 to $_absoluteMaximum',
      );
    }

    final int usable = capacity.freeBytes - _storageHeadroomBytes;
    final int storageCap = capacity.knowsStorage
        ? (usable <= 0 ? 0 : usable ~/ _perCloneBytes)
        : _absoluteMaximum;
    final int memoryCap = _memoryCap(capacity);
    final int maximum = <int>[
      _absoluteMaximum,
      storageCap,
      memoryCap,
    ].reduce((int a, int b) => a < b ? a : b);

    // Decided after the minimum, not before it: a volume with room for part of a clone
    // clears the headroom check and still lands on nothing, and 'Up to 0' is not a
    // sentence. Only storage can bring the figure this low, so it is what gets named.
    //
    // States the two figures and stops. Callers put this after a sentence that has
    // already said there is no room, so repeating the verdict here would say it twice.
    if (maximum <= 0) {
      return CloneBudget(
        maximum: 0,
        reason:
            'Only ${capacity.freeLabel} is free, and the device keeps half a '
            'gigabyte spare.',
      );
    }

    if (maximum >= _absoluteMaximum) {
      return const CloneBudget(
        maximum: _absoluteMaximum,
        reason: 'Choose from 1 to $_absoluteMaximum',
      );
    }
    // Name the figure that actually bound the offer, so the number reads as this
    // device's answer rather than as an arbitrary cap.
    if (storageCap <= memoryCap) {
      return CloneBudget(
        maximum: maximum,
        reason: 'Up to $maximum — ${capacity.freeLabel} of space left',
      );
    }
    // "at a time", because that is all this bound is. Memory does not shrink as idle
    // containers pile up, so repeating the action reaches any total the storage floor
    // allows — and a reason that read as a device ceiling would be promising otherwise.
    // The storage wording above needs no such qualifier: free space really does fall
    // with every clone made, so that figure is a ceiling and corrects itself.
    return CloneBudget(
      maximum: maximum,
      reason:
          'Up to $maximum at a time on a device with '
          '${capacity.totalMemLabel} of memory',
    );
  }

  /// What this device should be encouraged to *run*, which is a different question.
  ///
  /// An idle container costs [_perCloneBytes] and no memory at all, so RAM does not
  /// bound how many clones can exist. It bounds how many are usable at once — which is
  /// what someone who made twenty of them is about to try. These tiers are a judgement
  /// about that, not a measurement of anything: tune them, do not trust them.
  ///
  /// It caps a batch, not a total. Nothing here counts the clones already made, so
  /// repeating the action reaches any number the storage floor permits. That is
  /// deliberate — locking someone out of their own device on a guessed tier would be
  /// worse than the friction — and it is why the offer says "at a time".
  int _memoryCap(DeviceCapacity capacity) {
    if (capacity.isLowRamDevice ?? false) {
      return 4;
    }
    if (!capacity.knowsMemory) {
      return _absoluteMaximum;
    }
    const int gb = 1024 * 1024 * 1024;
    final int total = capacity.totalMemBytes!;
    if (total < 3 * gb) {
      return 6;
    }
    if (total < 6 * gb) {
      return 12;
    }
    return _absoluteMaximum;
  }

  /// Why [count] more clones of [profile] cannot be made, or null to go ahead.
  ///
  /// A backstop rather than the main guard: the dialog already offers no more than the
  /// budget allows. This catches the case where the device filled up between the offer
  /// and the confirmation.
  Future<String?> _budgetRefusal(VirtualProfileModel profile, int count) async {
    final CloneBudget budget = await cloneBudget();
    if (count <= budget.maximum) {
      return null;
    }
    if (budget.allowsNone) {
      return 'There is no room for another ${profile.appName} clone. '
          '${budget.reason}';
    }
    // Quotes the budget rather than paraphrasing it, so the sentence the user is
    // refused with is the one the stepper already showed them.
    return 'Not enough room for $count more ${profile.appName} clones. '
        '${budget.reason}.';
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
