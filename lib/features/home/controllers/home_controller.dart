import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/clone_icon_store.dart';
import '../../../core/virtualization/virtualization_engine.dart';
import '../../../data/models/clone_batch_result.dart';
import '../../../data/models/clone_budget.dart';
import '../../../data/models/clone_icon_color.dart';
import '../../../data/models/clone_permissions.dart';
import '../../../data/models/compatibility_report.dart';
import '../../../data/models/device_capacity.dart';
import '../../../data/models/engine_result.dart';
import '../../../data/models/platform_info.dart';
import '../../../data/models/space_identity.dart';
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
    CloneIconStore? iconStore,
  }) : _iconStore = iconStore ?? CloneIconStore();

  final VirtualizationEngine _engine;
  final NativeBridge _nativeBridge;

  /// Names a new clone -- the same seam the picker uses, so both flows name clones by one
  /// rule -- and records the mark the user puts on one. Both are host-side metadata that
  /// never reaches the container, which is why they do not go through the engine.
  final VirtualProfileRepository _repository;

  /// Where a picture the user chose for a clone lives. Injectable so the icon flow can be
  /// exercised without touching the device's storage.
  final CloneIconStore _iconStore;

  /// The lock and the hidden-clone flag. The grid reads [visibleProfiles] and the
  /// Private space screen reads [hiddenProfiles] from the same loaded list.
  final PrivateSpaceController _privateSpace;
  final AppLogger _logger = const AppLogger('HomeController');

  final RxList<VirtualProfileModel> profiles = <VirtualProfileModel>[].obs;
  final Rxn<TestAppModel> testApp = Rxn<TestAppModel>();
  final Rxn<PlatformInfo> platformInfo = Rxn<PlatformInfo>();
  final RxBool isLoading = true.obs;
  /// Why the grid could not be loaded, as it was thrown, so the view can word it.
  final Rx<AppException?> errorMessage = Rx<AppException?>(null);
  final Rxn<VirtualizationAvailability> virtualization =
      Rxn<VirtualizationAvailability>();
  final RxMap<String, VirtualProfileState> profileStates =
      <String, VirtualProfileState>{}.obs;
  final RxMap<String, Uint8List> appIcons = <String, Uint8List>{}.obs;

  /// Pictures the user chose, keyed by profile id rather than by package: two clones of
  /// one app can carry different ones, which is the whole point of them.
  final RxMap<String, Uint8List> customIcons = <String, Uint8List>{}.obs;

  /// Compatibility reports for the cloned packages, keyed by package name.
  ///
  /// Read by the clone action sheet so holding a tile says what will not work inside it.
  /// The tile itself stays clean on purpose — see `CloneTile`.
  final RxMap<String, CompatibilityReport> compatibility =
      <String, CompatibilityReport>{}.obs;

  bool get isTestAppInstalled => testApp.value?.installed ?? false;

  /// True only when the abstraction claims isolation AND the native backend confirms
  /// it is actually usable on this device.
  bool get providesRuntimeIsolation =>
      _engine.providesRuntimeIsolation &&
      (virtualization.value?.available ?? false);

  /// What the engine said about being unusable, or null when it is fine.
  ///
  /// An engine that failed without a message returns the empty string rather than a
  /// sentence: the caller is a widget, and only it can say "unavailable" in the user's
  /// language. Null still means "nothing is wrong", which is the distinction that
  /// matters here.
  String? get virtualizationProblem {
    final VirtualizationAvailability? state = virtualization.value;
    if (state == null || state.available) {
      return null;
    }
    return state.message ?? '';
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

  /// Icon for a profile's package, or null for a clone whose APK is not installed
  /// on the host (the card then falls back to a placeholder).
  /// What this clone is drawn with: the picture the user chose, or its app's own icon.
  Uint8List? iconFor(VirtualProfileModel profile) =>
      customIcons[profile.id] ?? appIcons[profile.packageName];

  /// The dangerous permissions this clone's app declares, and the ones denied for it.
  Future<ClonePermissions> clonePermissions(VirtualProfileModel profile) =>
      _nativeBridge.getClonePermissions(
        profileId: profile.id,
        packageName: profile.packageName,
      );

  /// Allows or denies one permission for this clone. Returns null on success, or the
  /// refusal for the caller to word.
  Future<AppException?> setClonePermission(
    VirtualProfileModel profile,
    String permission,
    bool allowed,
  ) async {
    try {
      await _nativeBridge.setClonePermission(
        profileId: profile.id,
        permission: permission,
        allowed: allowed,
      );
      return null;
    } on AppException catch (error) {
      return error;
    }
  }

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
  ///
  /// The result is read by [warningsFor], which the clone action sheet shows. It does not
  /// power a badge on the tile: the grid is meant to read as a home screen, not a list of
  /// faults.
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
      await _loadCustomIcons();
    } on AppException catch (error) {
      errorMessage.value = error;
    }
  }

  /// Reads the pictures the user chose, for the clones that have one.
  ///
  /// A file that has gone is simply not loaded, so the clone falls back to its app's icon
  /// rather than showing a hole. Failures are swallowed on purpose: an unreadable icon is
  /// a cosmetic loss, and taking the grid down over it would not be.
  Future<void> _loadCustomIcons() async {
    final Map<String, Uint8List> loaded = <String, Uint8List>{};
    for (final VirtualProfileModel profile in profiles) {
      final String? path = profile.iconPath;
      if (path == null) {
        continue;
      }
      try {
        final Uint8List? bytes = await _iconStore.read(path);
        if (bytes != null) {
          loaded[profile.id] = bytes;
        }
      } on Object catch (error, stackTrace) {
        _logger.error('Could not read the icon for ${profile.id}', error, stackTrace);
      }
    }
    customIcons.assignAll(loaded);
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

  /// Returns `null` on success, or the refusal for the caller to word.
  /// Clones whose guest process is being started.
  ///
  /// Kept here so the tile itself can say so. A launch takes a second or two — the
  /// engine has to bring up a stub process and hand it the package — and a tile that
  /// looked untouched for that long read as a tap that did not register.
  final RxSet<String> launching = <String>{}.obs;

  Future<AppException?> launchProfile(VirtualProfileModel profile) async {
    launching.add(profile.id);
    try {
      await _engine.launchProfile(profile.id);
      return null;
    } on AppException catch (error) {
      return error;
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
  /// Returns null when the request was accepted, or the refusal otherwise.
  Future<AppException?> addShortcut(VirtualProfileModel profile) async {
    try {
      await _nativeBridge.pinCloneShortcut(
        profileId: profile.id,
        packageName: profile.packageName,
        label: shortcutLabel(profile),
        spaceIndex: instanceIndex(profile),
        spaceCount: siblingCount(profile),
        badgeArgb: profile.iconColor.argb,
        iconPath: profile.iconPath,
      );
      return null;
    } on AppException catch (error) {
      return error;
    }
  }

  Future<AppException?> renameProfile(
    VirtualProfileModel profile,
    String name,
  ) async {
    try {
      await _engine.renameProfile(profile.id, name);
      await _loadProfiles();
      await _loadProfileStates();
      return null;
    } on AppException catch (error) {
      return error;
    }
  }

  /// Marks this clone with a colour, or clears the mark with [CloneIconColor.none].
  ///
  /// Host-side only: the container is untouched, so a running clone is not disturbed by
  /// being re-marked. A shortcut the launcher already holds is repainted too, so the home
  /// screen does not keep showing the mark the clone used to have.
  Future<AppException?> setIconColor(
    VirtualProfileModel profile,
    CloneIconColor color,
  ) async {
    try {
      await _repository.updateProfile(profile.id, iconColor: color);
      await _loadProfiles();
      await _refreshShortcut(profile.id);
      return null;
    } on AppException catch (error) {
      return error;
    }
  }

  /// Carries a changed icon out to this clone's pinned shortcut, if it has one.
  ///
  /// Read back from [profiles] rather than taken from the caller's copy: the caller holds
  /// the clone as it was *before* the change, and repainting the shortcut with that would
  /// undo on the home screen what was just done everywhere else.
  ///
  /// Never rethrows. The icon has already changed in the app; a launcher that will not
  /// take the update is not a reason to report the change as failed.
  Future<void> _refreshShortcut(String profileId) async {
    VirtualProfileModel? updated;
    for (final VirtualProfileModel profile in profiles) {
      if (profile.id == profileId) {
        updated = profile;
        break;
      }
    }
    if (updated == null) {
      return;
    }
    try {
      await _nativeBridge.refreshCloneShortcut(
        profileId: updated.id,
        packageName: updated.packageName,
        label: shortcutLabel(updated),
        spaceIndex: instanceIndex(updated),
        spaceCount: siblingCount(updated),
        badgeArgb: updated.iconColor.argb,
        iconPath: updated.iconPath,
      );
    } on Object catch (error, stackTrace) {
      _logger.error('Could not refresh the shortcut for $profileId', error, stackTrace);
    }
  }

  /// Puts a picture of the user's own on this clone, in place of its app's icon.
  ///
  /// Returns null when the icon was set *or* when the user backed out of the picker --
  /// both are "nothing went wrong". Non-null is a refusal for the caller to word.
  ///
  /// The picture is normalised and copied into the app's own storage, so the clone keeps
  /// its icon after the original is moved, renamed or deleted from the gallery.
  Future<AppException?> setCustomIcon(VirtualProfileModel profile) async {
    try {
      final List<PlatformFile> picked = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (picked.isEmpty) {
        return null;
      }
      final Uint8List source = await picked.first.readAsBytes();
      final String path = await _iconStore.save(
        profileId: profile.id,
        source: source,
      );
      await _repository.updateProfile(profile.id, iconPath: path);
      await _loadProfiles();
      await _refreshShortcut(profile.id);
      return null;
    } on AppException catch (error) {
      return error;
    } on Object catch (error, stackTrace) {
      // Decoding someone else's picture and writing a file are both things that can fail
      // for reasons this app did not cause -- an unreadable format, a full disk. The
      // caller says so in the user's language; the detail goes to the log.
      _logger.error('Could not set the icon for ${profile.id}', error, stackTrace);
      return const StorageException(
        AppErrorCodes.cloneIconFailed,
        'The picture could not be used as an icon.',
      );
    }
  }

  /// Gives this clone its app's own icon back, and forgets the picture.
  Future<AppException?> clearCustomIcon(VirtualProfileModel profile) async {
    try {
      await _repository.updateProfile(profile.id, clearIconPath: true);
      await _iconStore.delete(profile.id);
      await _loadProfiles();
      await _refreshShortcut(profile.id);
      return null;
    } on AppException catch (error) {
      return error;
    } on Object catch (error, stackTrace) {
      _logger.error('Could not clear the icon for ${profile.id}', error, stackTrace);
      return const StorageException(
        AppErrorCodes.cloneIconFailed,
        'The icon could not be removed.',
      );
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
  /// Reports what the batch came to; the caller words it.
  Future<CloneBatchResult> createClones(
    VirtualProfileModel profile,
    int count, {
    void Function(int created, int total)? onProgress,
  }) async {
    final CloneBudget? refusedBy = await _budgetRefusal(count);
    if (refusedBy != null) {
      return CloneBatchResult(
        requested: count,
        created: 0,
        refusedBy: refusedBy,
      );
    }

    int created = 0;
    AppException? firstFailure;

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
        firstFailure ??= error;
      }
      onProgress?.call(created, count);
    }

    await refreshAll();

    return CloneBatchResult(
      requested: count,
      created: created,
      failure: firstFailure,
    );
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
        limit: CloneBudgetLimit.appCeiling,
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
        limit: CloneBudgetLimit.storageExhausted,
        freeLabel: capacity.freeLabel,
      );
    }

    if (maximum >= _absoluteMaximum) {
      return const CloneBudget(
        maximum: _absoluteMaximum,
        limit: CloneBudgetLimit.appCeiling,
      );
    }
    // Name the figure that actually bound the offer, so the number reads as this
    // device's answer rather than as an arbitrary cap.
    if (storageCap <= memoryCap) {
      return CloneBudget(
        maximum: maximum,
        limit: CloneBudgetLimit.storage,
        freeLabel: capacity.freeLabel,
      );
    }
    // "at a time", because that is all this bound is. Memory does not shrink as idle
    // containers pile up, so repeating the action reaches any total the storage floor
    // allows — and a reason that read as a device ceiling would be promising otherwise.
    // The storage wording above needs no such qualifier: free space really does fall
    // with every clone made, so that figure is a ceiling and corrects itself.
    return CloneBudget(
      maximum: maximum,
      limit: CloneBudgetLimit.memory,
      totalMemLabel: capacity.totalMemLabel,
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

  /// The budget that refuses [count] more clones, or null to go ahead.
  ///
  /// A backstop rather than the main guard: the dialog already offers no more than the
  /// budget allows. This catches the case where the device filled up between the offer
  /// and the confirmation.
  ///
  /// Returns the budget itself rather than a sentence, so the refusal the user reads is
  /// worded once, in the view, from the same figures the stepper showed.
  Future<CloneBudget?> _budgetRefusal(int count) async {
    final CloneBudget budget = await cloneBudget();
    return count <= budget.maximum ? null : budget;
  }

  /// Stops the guest if it is running. Returns null on success.
  Future<AppException?> forceStop(VirtualProfileModel profile) async {
    try {
      await _engine.stopProfile(profile.id);
      // The card's dot is driven by engine-reported state, so re-read it rather than
      // assuming the stop took effect.
      await _loadProfileStates();
      return null;
    } on AppException catch (error) {
      return error;
    }
  }

  /// Empties this clone's caches. Logins and settings survive.
  Future<AppException?> clearCache(VirtualProfileModel profile) async {
    try {
      await _engine.clearProfileCache(profile.id);
      return null;
    } on AppException catch (error) {
      return error;
    }
  }

  /// Empties this clone's container. The next launch is a first launch.
  Future<AppException?> clearStorage(VirtualProfileModel profile) async {
    try {
      await _engine.clearProfileData(profile.id);
      await _loadProfileStates();
      return null;
    } on AppException catch (error) {
      return error;
    }
  }

  /// Whether this clone's app depends on Google services, per the compatibility
  /// analysis. The action sheet only offers microG when it does.
  bool requiresGoogleServices(VirtualProfileModel profile) =>
      compatibility[profile.packageName]?.requiresGms ?? false;

  /// Whether the clone's container already carries Google services.
  ///
  /// Asked of the engine rather than assumed: a clone made before microG was available
  /// has none. A check that cannot run reads as "not installed", which keeps the install
  /// action reachable instead of hiding it behind a failed lookup.
  Future<bool> googleServicesInstalled(VirtualProfileModel profile) async {
    try {
      final VirtualProfileState state = await _nativeBridge.profileState(
        profile.id,
        AppConstants.googleServicesPackage,
      );
      return state.installed;
    } on AppException catch (error, stackTrace) {
      _logger.error(
        'Google-services check failed for ${profile.id}',
        error,
        stackTrace,
      );
      return false;
    }
  }

  /// Installs the bundled microG into this clone without recreating it.
  Future<AppException?> installGoogleServices(VirtualProfileModel profile) async {
    try {
      await _engine.provisionMicroG(profile.id);
      return null;
    } on AppException catch (error) {
      return error;
    }
  }

  /// Offers this clone's APK to the share sheet.
  ///
  /// Goes straight to the bridge rather than through [VirtualizationEngine]: sharing a
  /// file is a host operation, not something a container backend would implement — the
  /// same reason shortcuts and permission requests bypass the engine.
  Future<AppException?> shareApp(VirtualProfileModel profile) async {
    try {
      await _nativeBridge.shareProfileApk(
        profileId: profile.id,
        packageName: profile.packageName,
        label: profile.appName,
      );
      return null;
    } on AppException catch (error) {
      return error;
    }
  }

  Future<AppException?> deleteProfile(VirtualProfileModel profile) async {
    try {
      await _engine.deleteProfile(profile.id);
      // After the clone is gone, and never in a way that can fail the delete: a picture
      // left behind is wasted bytes, but a delete refused because of one would leave the
      // user with a clone they asked to be rid of.
      try {
        await _iconStore.delete(profile.id);
      } on Object catch (error, stackTrace) {
        _logger.error('Could not remove the icon for ${profile.id}', error, stackTrace);
      }
      await _loadProfiles();
      await _loadProfileStates();
      return null;
    } on AppException catch (error) {
      return error;
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
  /// Returns the refusal if the engine refused, in which case the tile comes back
  /// rather than staying half-faded on a grid it is still part of.
  Future<AppException?> uninstall(VirtualProfileModel profile) async {
    removing.add(profile.id);
    await Future<void>.delayed(removalAnimation);
    final AppException? error = await deleteProfile(profile);
    removing.remove(profile.id);
    return error;
  }
}
