import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/diagnostics/diagnostic_event.dart';
import '../../../core/diagnostics/diagnostic_operation.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/clone_budget_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/app_name_sort.dart';
import '../../../core/virtualization/virtualization_engine.dart';
import '../../../data/models/app_details.dart';
import '../../../data/models/clone_budget.dart';
import '../../../data/models/clone_refusal.dart';
import '../../../data/models/compatibility_report.dart';
import '../../../data/models/installed_app_model.dart';
import '../../../data/repositories/virtual_profile_repository.dart';
import '../../../native/native_bridge.dart';

/// A problem the picker diagnosed for itself, rather than one the engine reported.
///
/// A value, not a sentence: the controller has no `BuildContext`, so the wording lives
/// beside the screen that shows it. Mirrors `SettingsStatus`.
enum PickerStatus {
  /// The file the user picked could not be read off the device.
  apkUnreadable,
}

/// Backs the "add a clone" flow: pick an installed app, or import an APK.
class AppPickerController extends GetxController with WidgetsBindingObserver {
  AppPickerController({
    required this._bridge,
    required this._engine,
    required this._repository,
    required this._cloneBudgets,
  });

  final NativeBridge _bridge;
  final VirtualizationEngine _engine;
  final VirtualProfileRepository _repository;

  /// What this device has room for. The grid's clone route has always asked; this one
  /// did not, so the same device could refuse there and accept here — then fail in the
  /// engine and say so in the engine's words instead of "there is no room".
  final CloneBudgetService _cloneBudgets;
  final AppLogger _logger = const AppLogger('AppPickerController');

  final RxList<InstalledAppModel> apps = <InstalledAppModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isWorking = false.obs;
  final RxString query = ''.obs;

  /// What went wrong on the native side, as it was thrown.
  ///
  /// The exception rather than its message, so the view can translate it by code. A
  /// problem this app diagnoses itself goes in [status] instead — the same split
  /// `SettingsController` makes.
  final Rx<AppException?> errorMessage = Rx<AppException?>(null);

  /// A problem this app found for itself, waiting to be worded and shown once.
  final Rx<PickerStatus?> status = Rx<PickerStatus?>(null);

  /// How the list is ordered.
  final Rx<AppSort> sort = AppSort.name.obs;

  /// Which apps the list shows at all.
  ///
  /// Everything, by default: a user who came here to clone a specific app should find
  /// it, and hiding system apps meant the camera or the browser simply was not there
  /// with no hint that a filter was the reason.
  final Rx<AppFilter> filter = AppFilter.all.obs;
  final Rx<ArchitectureFilter> architecture = ArchitectureFilter.all.obs;
  final Rx<PackageTypeFilter> packageType = PackageTypeFilter.all.obs;

  /// Launchable apps on this device that cannot be cloned, and so are not in [apps].
  ///
  /// Shown under the list. An app the engine cannot host is deliberately left out — a row
  /// that can only fail is worse than no row — but leaving it out *silently* left a user
  /// looking for a missing app unable to tell a decision from a defect.
  final RxInt hiddenApps = 0.obs;

  /// Packages that already have at least one clone.
  ///
  /// Drives the tick on an app's icon and the Not added / Already added filters. Loaded
  /// with the list rather than queried per row, so a hundred rows do not mean a hundred
  /// repository reads.
  final RxSet<String> clonedPackages = <String>{}.obs;

  /// Well-known apps offered as a shortcut above the list.
  ///
  /// A fixed list intersected with what is installed, not a popularity measurement:
  /// Duplika cannot see how much anything is used, and claiming to would be a lie
  /// dressed as a feature. These are simply the apps people most often clone.
  static const List<String> quickPickPackages = <String>[
    'com.facebook.katana',
    'com.instagram.android',
    'org.telegram.messenger',
    'com.whatsapp',
    'com.zhiliaoapp.musically',
    'com.snapchat.android',
    'com.twitter.android',
    'com.facebook.orca',
    'com.viber.voip',
    'com.discord',
  ];

  /// The quick picks that are actually on this device, in the order above.
  List<InstalledAppModel> get quickPicks {
    final Map<String, InstalledAppModel> byPackage =
        <String, InstalledAppModel>{
          for (final InstalledAppModel app in apps) app.packageName: app,
        };
    return <InstalledAppModel>[
      for (final String package in quickPickPackages)
        if (byPackage[package] != null) byPackage[package]!,
    ];
  }

  /// Apps matching the search and every active filter, in the chosen order.
  List<InstalledAppModel> get visibleApps {
    // Folded like the sort key, so a search typed without the accents still finds the
    // app: someone looking for Écran types "ecran", and a keyboard that has no easy way
    // to reach É is the ordinary case rather than the exotic one.
    final String needle = foldSearchTerm(query.value.trim());

    final List<InstalledAppModel> matching = apps.where((
      InstalledAppModel app,
    ) {
      if (needle.isNotEmpty &&
          !appNameSortKey(app.appName).contains(needle) &&
          !app.packageName.toLowerCase().contains(needle)) {
        return false;
      }
      return _passesFilter(app) &&
          _passesArchitecture(app) &&
          _passesPackageType(app);
    }).toList();

    matching.sort(_comparator);
    return List<InstalledAppModel>.unmodifiable(matching);
  }

  bool _passesFilter(InstalledAppModel app) => switch (filter.value) {
    AppFilter.all => true,
    AppFilter.userApps => !app.isSystem,
    AppFilter.systemApps => app.isSystem,
    AppFilter.notAdded => !clonedPackages.contains(app.packageName),
    AppFilter.alreadyAdded => clonedPackages.contains(app.packageName),
  };

  bool _passesArchitecture(InstalledAppModel app) =>
      switch (architecture.value) {
        ArchitectureFilter.all => true,
        ArchitectureFilter.only64Bit => app.supports64Bit && !app.supports32Bit,
        ArchitectureFilter.only32Bit => app.supports32Bit && !app.supports64Bit,
        ArchitectureFilter.both => app.supports32Bit && app.supports64Bit,
        ArchitectureFilter.noNativeCode => !app.hasNativeCode,
      };

  bool _passesPackageType(InstalledAppModel app) => switch (packageType.value) {
    PackageTypeFilter.all => true,
    PackageTypeFilter.single => !app.isSplit,
    PackageTypeFilter.split => app.isSplit,
  };

  /// The sort comparator. Apps with no timestamp fall to the end of a time sort rather
  /// than to the top: "unknown" is not "newest".
  int Function(InstalledAppModel, InstalledAppModel)
  get _comparator => switch (sort.value) {
    // Not `toLowerCase().compareTo()`: that is UTF-16 code unit order, which filed
    // every accented name after `z`. See [compareAppNames].
    AppSort.name =>
      (InstalledAppModel a, InstalledAppModel b) =>
          compareAppNames(a.appName, b.appName),
    AppSort.recentlyInstalled =>
      (InstalledAppModel a, InstalledAppModel b) =>
          _descending(a.installedAt, b.installedAt),
    AppSort.recentlyUpdated =>
      (InstalledAppModel a, InstalledAppModel b) =>
          _descending(a.updatedAt, b.updatedAt),
  };

  static int _descending(DateTime? a, DateTime? b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return 1;
    }
    if (b == null) {
      return -1;
    }
    return b.compareTo(a);
  }

  /// Whether the list is grouped by initial letter.
  ///
  /// Only a name sort is: A-Z headers over a list ordered by install date would label
  /// groups that are not groups.
  bool get isAlphabetical => sort.value == AppSort.name;

  /// [visibleApps] cut into alphabetical sections, in draw order.
  ///
  /// Sections are what keep the list lazy under a grouped layout: the outer list builds
  /// one bordered group at a time, so a device with three hundred apps still only lays
  /// out what is on screen. Anything not starting with a letter collects under '#',
  /// last, rather than being scattered through A-Z by its raw code point.
  List<AppSection> get sections {
    final List<InstalledAppModel> visible = visibleApps;
    if (!isAlphabetical) {
      // One unlabelled group, so a time-ordered list stays in its order.
      return <AppSection>[
        if (visible.isNotEmpty) AppSection(letter: '', apps: visible),
      ];
    }

    final Map<String, List<InstalledAppModel>> grouped =
        <String, List<InstalledAppModel>>{};
    for (final InstalledAppModel app in visible) {
      grouped
          .putIfAbsent(appNameInitial(app.appName), () => <InstalledAppModel>[])
          .add(app);
    }

    final List<String> letters = grouped.keys.toList()..sort();
    // '#' sorts before 'A' by code point, which would open the list on the odd names.
    if (letters.remove('#')) {
      letters.add('#');
    }

    return letters
        .map(
          (String letter) => AppSection(letter: letter, apps: grouped[letter]!),
        )
        .toList(growable: false);
  }

  /// When opened from a profile card, the picker arrives pre-filtered to that package
  /// so "Add another clone" lands on the right app.
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _packageChanges = _bridge.packageChanges.listen(
      (void _) => _schedulePackageReload(),
    );
    final Object? argument = Get.arguments;
    if (argument is String && argument.isNotEmpty) {
      query.value = argument;
    }
  }

  /// The device telling us its apps changed while this screen is in front.
  ///
  /// Resume covers the common case — installing from Play means leaving and coming back —
  /// so this is for the rest: a sideload finishing behind the picker, an update Play
  /// applies on its own, an uninstall from a notification shade.
  StreamSubscription<void>? _packageChanges;
  Timer? _packageReload;

  /// How long to wait for the broadcasts to stop before reading the device.
  ///
  /// Installs arrive as a burst — an update is a remove and an add, and a Play session
  /// can write several packages in a row — and a listing per broadcast would read the
  /// whole device repeatedly to answer questions that are still changing. Long enough to
  /// collect a burst, short enough that the list is right before the user has finished
  /// looking for the app they just installed.
  static const Duration _packageSettle = Duration(milliseconds: 700);

  void _schedulePackageReload() {
    if (_disposed) {
      return;
    }
    _packageReload?.cancel();
    _packageReload = Timer(_packageSettle, () {
      if (!_disposed && _foreground) {
        unawaited(loadApps(background: true));
      }
    });
  }

  /// Re-reads the device when the app comes back to the foreground.
  ///
  /// The cached verdicts are the first reason. A verdict depends on whether Duplika holds
  /// All files access, its refusal tells the user to go to Settings and grant it, and
  /// Settings is another app — so the one journey the message asks for is exactly the one
  /// that ends with a resume and a verdict that is no longer true. Refusing the clone a
  /// second time, with the same instruction the user has just followed, is the worst
  /// answer available.
  ///
  /// The list is the second, and it used to be left alone here on the grounds that
  /// leaving for Settings does not change which apps are installed. True of Settings, and
  /// false of everywhere else a user goes: installing an app from Play and coming
  /// straight back is the ordinary way to arrive at this screen wanting to clone it, and
  /// the picker had no way to ever see it. An app uninstalled while the picker was open
  /// was worse — the row stayed, and tapping it failed.
  ///
  /// Reloaded in the background, so the list the user is looking at is not replaced by a
  /// spinner for work they did not ask for.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _reports.clear();
      unawaited(loadApps(background: true));
    }
  }

  /// Whether this screen is the one the user is looking at.
  ///
  /// Read only by [_schedulePackageReload]. A package broadcast that arrives while
  /// Duplika is in the background is real, but acting on it there would read the whole
  /// device for a screen nobody can see — and the resume that follows reads it again
  /// anyway. Coming back to the foreground is the refresh; this just keeps it from being
  /// done twice.
  bool _foreground = true;

  @override
  void onReady() {
    super.onReady();
    loadApps();
  }

  /// Whether a read of the device is already in flight.
  ///
  /// Three things ask for one now — opening the screen, coming back to the foreground,
  /// and pulling the list down — and two of them can land together. The second is
  /// dropped rather than queued: both would return the same device.
  bool _loading = false;

  /// Re-reads the device.
  ///
  /// [background] keeps the list and its scroll position on screen for the duration and
  /// leaves a failure unreported when there is still a usable list to show — a refresh
  /// nobody asked for must not replace one with an error screen. Opening the picker and
  /// tapping Retry both pass false and get the spinner.
  Future<void> loadApps({bool background = false}) async {
    if (_loading || _disposed) {
      return;
    }
    _loading = true;
    if (!background) {
      isLoading.value = true;
    }
    try {
      // What the list already holds, before it is replaced. The icons in it are worth
      // keeping — see [_carryIcon].
      final Map<String, InstalledAppModel> previous =
          <String, InstalledAppModel>{
            for (final InstalledAppModel app in apps) app.packageName: app,
          };

      // Metadata only. Decoding every launchable app's icon here took about fifteen
      // seconds on a real device; the icons arrive afterwards, for the rows that are
      // actually drawn. See [requestIcons].
      final InstalledAppListing listing = await _bridge.listInstalledApps(
        includeIcons: false,
      );
      if (_disposed) {
        return;
      }

      final List<InstalledAppModel> loaded = <InstalledAppModel>[
        for (final InstalledAppModel app in listing.apps)
          _carryIcon(app, previous[app.packageName]),
      ];

      // Reset here rather than before the read, so this bookkeeping is only ever
      // discarded together with the list it describes. Cleared up front, a read that
      // failed left the rows still on screen unmarked — every one of them re-requested
      // and re-decoded on the next rebuild, for a refresh that had changed nothing.
      //
      // An icon carried over counts as already requested: sparing that round trip is
      // the whole point of carrying it.
      _requestedIcons
        ..clear()
        ..addAll(<String>[
          for (final InstalledAppModel app in loaded)
            if (app.icon != null) app.packageName,
        ]);
      _pendingIcons.clear();
      // Dropped with the list they describe. See [didChangeAppLifecycleState] for why a
      // verdict is not a fact that can be kept.
      _reports.clear();

      apps.assignAll(loaded);
      hiddenApps.value = listing.hidden;
      errorMessage.value = null;

      // Caught separately, and still behind the spinner. Separately because these marks
      // are decoration on rows that are already usable, and losing them must not replace
      // a list the user can act on with an error screen. Behind the spinner because the
      // Not added / Already added filters read them: finishing the load without them
      // would show the list once with every tick missing, and under either of those
      // filters would show the wrong apps until they arrived.
      try {
        clonedPackages.assignAll(await _repository.clonedPackageNames());
      } on AppException catch (error, stackTrace) {
        _logger.error(
          'Could not read which packages are cloned',
          error,
          stackTrace,
        );
      }
    } on AppException catch (error, stackTrace) {
      _logger.error('Could not list installed apps', error, stackTrace);
      // A background refresh that fails leaves the list it could not replace exactly
      // where it was: the user did not ask for this read, and a screenful of error in
      // place of apps they can still act on is a worse answer than saying nothing.
      if (!background || apps.isEmpty) {
        errorMessage.value = error;
      }
    } finally {
      // In `finally` because a failure that is not an [AppException] — a channel fault,
      // a malformed reply — would otherwise leave the screen on its spinner forever.
      _loading = false;
      isLoading.value = false;
    }
  }

  /// Keeps an icon the list has already decoded across a reload.
  ///
  /// Without this every refresh — and one runs on every resume — put each visible row
  /// back on its placeholder until the icon batches came round again, which reads as a
  /// flicker over work the user did not ask for and re-decodes icons that had not
  /// changed.
  ///
  /// Dropped when the package has been updated since, because its icon may have been
  /// updated with it. That is the same key the native side uses to decide whether an
  /// app's archives are worth re-reading, so the two invalidate together.
  static InstalledAppModel _carryIcon(
    InstalledAppModel fresh,
    InstalledAppModel? previous,
  ) {
    if (previous?.icon == null || previous!.updatedAt != fresh.updatedAt) {
      return fresh;
    }
    return fresh.copyWith(icon: previous.icon);
  }

  /// How many icons one native round trip decodes.
  ///
  /// Small enough that a clone requested mid-load waits behind one batch rather than
  /// behind the whole list, large enough that the channel is not called per row.
  static const int _iconBatchSize = 8;

  /// Packages an icon has been asked for; one request per package per load.
  final Set<String> _requestedIcons = <String>{};

  /// Packages waiting for the next native batch.
  final Set<String> _pendingIcons = <String>{};

  bool _iconWorkerRunning = false;
  bool _disposed = false;

  /// Asks for icons for the packages the list is about to draw.
  ///
  /// Called from the list's item builder, which runs only for the groups being laid
  /// out, so icon work tracks what is on screen instead of the whole device. The
  /// request returns immediately; icons are attached to [apps] as batches arrive.
  void requestIcons(Iterable<String> packageNames) {
    if (_disposed) {
      return;
    }
    bool queued = false;
    for (final String packageName in packageNames) {
      if (_requestedIcons.contains(packageName)) {
        continue;
      }
      _requestedIcons.add(packageName);
      _pendingIcons.add(packageName);
      queued = true;
    }
    if (!queued || _iconWorkerRunning) {
      return;
    }
    _iconWorkerRunning = true;
    unawaited(_pumpIcons());
  }

  Future<void> _pumpIcons() async {
    try {
      while (_pendingIcons.isNotEmpty && !_disposed) {
        final List<String> batch = _pendingIcons
            .take(_iconBatchSize)
            .toList(growable: false);
        _pendingIcons.removeAll(batch);

        final Map<String, Uint8List> loaded;
        try {
          loaded = await _bridge.getAppIcons(batch);
        } on AppException catch (error, stackTrace) {
          _logger.error(
            'Could not load ${batch.length} app icon(s)',
            error,
            stackTrace,
          );
          // Unmarked, so a later rebuild can retry instead of leaving those rows on
          // the placeholder for the rest of the session.
          //
          // The queue behind the failed batch is unmarked too. Giving up here ends the
          // only worker, and a package that is still marked as requested is one that
          // [requestIcons] will skip — so anything left queued would never be asked for
          // again, and its row would keep the placeholder exactly as above.
          _requestedIcons.removeAll(batch);
          _requestedIcons.removeAll(_pendingIcons);
          _pendingIcons.clear();
          return;
        }

        if (_disposed) {
          return;
        }
        if (loaded.isNotEmpty) {
          _applyIcons(loaded);
        }
      }
    } finally {
      _iconWorkerRunning = false;
      // Anything queued while this worker was on its last batch has no worker of its
      // own: [requestIcons] saw one running and left the starting to it. Without this
      // those rows keep the placeholder until something else happens to queue more —
      // which, after a refresh cleared the queue mid-batch, is never.
      if (!_disposed && _pendingIcons.isNotEmpty) {
        _iconWorkerRunning = true;
        unawaited(_pumpIcons());
      }
    }
  }

  /// Attaches decoded icons to the list without disturbing its order.
  ///
  /// The models are immutable and the picker's sections are derived from [apps], so a
  /// replacement list is what makes the rows repaint with their icon.
  void _applyIcons(Map<String, Uint8List> loaded) {
    apps.assignAll(<InstalledAppModel>[
      for (final InstalledAppModel app in apps)
        loaded[app.packageName] != null
            ? app.copyWith(icon: loaded[app.packageName])
            : app,
    ]);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposed = true;
    _packageReload?.cancel();
    // Cancelling the last listener is what unregisters the native broadcast receiver, so
    // leaving this behind would keep the device waking Duplika up for a screen that no
    // longer exists.
    unawaited(_packageChanges?.cancel());
    _pendingIcons.clear();
    super.onClose();
  }

  /// Reads the full archive detail for one app.
  ///
  /// Not cached: it is asked for once per visit to the details screen, and a stale size
  /// or certificate after an app update would be worse than the read.
  Future<AppDetails> appDetails(String packageName) =>
      _bridge.appDetails(packageName);

  /// Shares the host's copy of this app's APK.
  ///
  /// Returns the refusal, or `null` when the chooser opened.
  Future<AppException?> shareInstalledApp(InstalledAppModel app) async {
    try {
      await _bridge.shareInstalledApk(
        packageName: app.packageName,
        label: app.appName,
      );
      return null;
    } on AppException catch (error) {
      return error;
    }
  }

  Future<int> instanceCount(String packageName) =>
      _repository.instanceCountFor(packageName);

  /// Compatibility verdict for one app, computed on demand and cached for the session.
  Future<CompatibilityReport> analyze(String packageName) async {
    final CompatibilityReport? cached = _reports[packageName];
    if (cached != null) {
      return cached;
    }
    try {
      final CompatibilityReport report = await _bridge.analyzeApp(packageName);
      _reports[packageName] = report;
      return report;
    } on AppException catch (error, stackTrace) {
      _logger.error(
        'Compatibility analysis failed for $packageName',
        error,
        stackTrace,
      );
      return CompatibilityReport.unknown;
    }
  }

  /// Compatibility verdict for a picked APK, read from the archive rather than assumed.
  Future<CompatibilityReport> analyzeApk(ApkCandidate candidate) async {
    try {
      return await _bridge.analyzeApk(
        candidate.apkPaths,
        candidate.packageName,
      );
    } on AppException catch (error, stackTrace) {
      _logger.error(
        'APK analysis failed for ${candidate.packageName}',
        error,
        stackTrace,
      );
      return CompatibilityReport.unknown;
    }
  }

  final Map<String, CompatibilityReport> _reports =
      <String, CompatibilityReport>{};

  /// Clones an installed app. Returns `null` on success, or the refusal to be worded
  /// by the caller.
  /// The stand-in for "not started, because one already is".
  ///
  /// The two clone routes answer with an [AppException], so refusing with one keeps their
  /// signature — and it is compared by identity rather than by code, so an engine failure
  /// that happened to share a code could never be mistaken for it.
  static const String cloneInProgressCode = 'CLONE_IN_PROGRESS';

  static const AppException _busy = VirtualizationException(
    'A clone is already being created.',
    code: cloneInProgressCode,
  );

  /// Packages a clone is being created for.
  ///
  /// Kept here so the row itself can say so. Creating a container takes a couple of
  /// seconds, and a row that looked untouched for that long read as a tap that did not
  /// register.
  final RxSet<String> cloning = <String>{}.obs;

  /// Analyses and clones in one call, marked as in flight for the whole of it.
  ///
  /// One method rather than the view stringing the two together, so `cloning` covers the
  /// analysis as well as the install. Marked separately, the row sat unmarked through the
  /// analysis — a second or so of nothing after a tap — and the global bar filled that
  /// gap instead, which is the thing the row spinner replaced.
  ///
  /// Returns why it did not happen, or null on success.
  Future<CloneRefusal?> cloneNow(InstalledAppModel app) async {
    if (cloning.contains(app.packageName) || isWorking.value) {
      // Said, not swallowed. Returning null here meant "no refusal", which the caller
      // reads as success: it closed the picker and reported a clone that was never
      // started. See [CloneRefusal.busy].
      return const CloneRefusal.busy();
    }
    cloning.add(app.packageName);
    try {
      // Before the compatibility question, because it is the cheaper refusal and the
      // one that is not about this app at all: an app that could be cloned on a device
      // with room should not be told it is unsupported.
      final CloneBudget budget = await _cloneBudgets.cloneBudget();
      if (budget.allowsNone) {
        return CloneRefusal.noRoom(budget);
      }

      final CompatibilityReport report = await analyze(app.packageName);
      if (report.verdict == CompatibilityVerdict.unsupported) {
        // Refused rather than walked into: the engine has already said this cannot
        // work, so starting the install would only fail later and less clearly.
        return CloneRefusal.blocked(report.blocker);
      }
      final AppException? failure = await cloneInstalledApp(app);
      if (failure != null) {
        return identical(failure, _busy)
            ? const CloneRefusal.busy()
            : CloneRefusal.failed(failure);
      }
      return null;
    } finally {
      cloning.remove(app.packageName);
    }
  }

  /// Returns the engine's refusal, null on success, or [_busy] when another clone was
  /// already in flight and this one was not started.
  Future<AppException?> cloneInstalledApp(
    InstalledAppModel app, {
    bool installGms = false,
  }) async {
    if (isWorking.value) {
      return _busy;
    }
    // Before `isWorking`, so no frame exists where the work is in flight and no row is
    // saying which app it is for — that frame showed the global bar instead.
    cloning.add(app.packageName);
    isWorking.value = true;
    try {
      final String profileName = await _repository.suggestProfileName(
        appName: app.appName,
        packageName: app.packageName,
      );
      await _engine.createProfile(
        packageName: app.packageName,
        appName: app.appName,
        profileName: profileName,
        installGms: installGms,
      );
      // The picker closes on success today, so nothing has been seen to go stale here.
      // Recorded anyway because the set is what the tick and the Already added / Not
      // added filters read, and "it happens to be torn down straight afterwards" is a
      // property of the caller, not of this method.
      clonedPackages.add(app.packageName);
      return null;
    } on AppException catch (error) {
      return error;
    } finally {
      // In `finally`, so a refused create clears the row rather than leaving it
      // spinning on a clone that is never going to exist.
      cloning.remove(app.packageName);
      isWorking.value = false;
    }
  }

  /// Lets the user pick an APK and returns its parsed identity, or `null` if cancelled.
  ///
  /// [packageFormat] narrows the picker to the `.papk.bin` files Duplika's own share
  /// produces. Two entry points rather than one filter for everything, because a user
  /// looking for a package Duplika sent them should not have to find it among every APK
  /// on the device — and a user importing a split set should not see only `.bin`.
  /// The `bin` extension is kept in step with `AppSharer.EXTENSION`.
  Future<ApkCandidate?> pickApk({bool packageFormat = false}) async {
    // `pickFiles` is the multi-select entry point (`pickFile` is the single-file one),
    // and it no longer takes the data/stream flags: whether a pick is read into memory or
    // streamed is decided per file, by whichever of `readAsBytes` and `readAsByteStream`
    // the caller reaches for. `_materialise` streams, which is what matters here — a
    // split set runs to hundreds of megabytes and must never be buffered whole.
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: packageFormat
          ? <String>['bin']
          : <String>['apk', 'bin'],
    );
    if (picked.isEmpty) {
      return null;
    }

    // The pick gets its own correlation id. Staging the files, reading their manifests
    // and validating the split set are three separate failure points across Dart and
    // Kotlin, and this is what makes them read as one sequence in the console.
    return DiagnosticOperation.run<ApkCandidate?>(
      'apk_import',
      (DiagnosticOperation operation) async {
        operation.step(
          'User selected ${picked.length} file(s) to import',
          source: DiagnosticSource.apkImporter,
          category: DiagnosticCategory.import,
          metadata: <String, String>{'selectedFiles': '${picked.length}'},
        );

        isWorking.value = true;
        try {
          final List<String> paths = await _materialise(picked);
          operation.step(
            'Staged ${paths.length} APK file(s) into the app cache',
            source: DiagnosticSource.apkImporter,
            category: DiagnosticCategory.import,
          );
          return await _bridge.inspectApk(paths);
        } on AppException catch (error) {
          errorMessage.value = error;
          return null;
        } on IOException catch (error, stackTrace) {
          _logger.error('Could not copy the selected APK', error, stackTrace);
          status.value = PickerStatus.apkUnreadable;
          return null;
        } finally {
          isWorking.value = false;
        }
      },
      name: 'APK import',
      source: DiagnosticSource.apkImporter,
      category: DiagnosticCategory.import,
    );
  }

  /// Copies the picked file into app cache and returns its real path.
  ///
  /// Android's document picker hands back a `content://` URI, which has no filesystem
  /// path; both `getPackageArchiveInfo` and the engine's installer need a real file.
  /// The copy is streamed so a large APK never has to sit in memory.
  Future<List<String>> _materialise(List<PlatformFile> pickedFiles) async {
    final Directory cache = await getTemporaryDirectory();
    final Directory imports = Directory('${cache.path}/apk_imports');

    // A previous import can be hundreds of megabytes; clear the staging area rather than
    // letting copies accumulate. The engine keeps its own retained copy of anything that
    // was actually installed, so nothing here is needed after this call.
    if (imports.existsSync()) {
      imports.deleteSync(recursive: true);
    }
    imports.createSync(recursive: true);

    final List<String> paths = <String>[];
    for (int index = 0; index < pickedFiles.length; index++) {
      final PlatformFile picked = pickedFiles[index];
      final String safeName = picked.name.replaceAll(
        RegExp(r'[^A-Za-z0-9._-]'),
        '_',
      );
      final File target = File('${imports.path}/${index}_$safeName');
      final IOSink sink = target.openWrite();
      try {
        await sink.addStream(picked.readAsByteStream());
      } finally {
        await sink.close();
      }
      paths.add(target.path);
    }
    return paths;
  }

  /// Installs a previously inspected APK as a new clone.
  ///
  /// Refuses an archive the engine cannot host before anything is created, the same way
  /// [cloneNow] does for an installed app: the two clone routes behave alike, and an
  /// impossible clone fails with its reason rather than by installing and then misbehaving.
  /// The refusal is a message, not a question -- nothing is put in front of the user first.
  Future<AppException?> cloneApk(
    ApkCandidate candidate, {
    bool installGms = false,
  }) async {
    if (isWorking.value) {
      return _busy;
    }
    isWorking.value = true;
    try {
      final CompatibilityReport report = await analyzeApk(candidate);
      final CompatibilityFinding? blocker = report.blocker;
      if (report.verdict == CompatibilityVerdict.unsupported &&
          blocker != null) {
        // Carries the finding's own code, so the view words it in the user's language
        // through the same table the installed-app refusal uses.
        return VirtualizationException(blocker.message, code: blocker.code);
      }
      final String profileName = await _repository.suggestProfileName(
        appName: candidate.appName,
        packageName: candidate.packageName,
      );
      await _engine.createProfileFromApk(
        apkPaths: candidate.apkPaths,
        packageName: candidate.packageName,
        appName: candidate.appName,
        profileName: profileName,
        installGms: installGms,
      );
      clonedPackages.add(candidate.packageName);
      return null;
    } on AppException catch (error) {
      return error;
    } finally {
      isWorking.value = false;
    }
  }
}

/// One alphabetical group in the picker.
@immutable
class AppSection {
  const AppSection({required this.letter, required this.apps});

  /// The heading: the initial the names in this group share, or '#' for everything
  /// that does not start with a letter.
  final String letter;
  final List<InstalledAppModel> apps;
}

/// How the picker orders its list.
enum AppSort { name, recentlyInstalled, recentlyUpdated }

/// Which apps the picker shows.
enum AppFilter { all, userApps, systemApps, notAdded, alreadyAdded }

/// Which architectures the picker shows.
enum ArchitectureFilter { all, only64Bit, only32Bit, both, noNativeCode }

/// Which package layouts the picker shows.
enum PackageTypeFilter { all, single, split }
