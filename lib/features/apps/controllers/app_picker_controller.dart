import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/diagnostics/diagnostic_event.dart';
import '../../../core/diagnostics/diagnostic_operation.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/virtualization/virtualization_engine.dart';
import '../../../data/models/compatibility_report.dart';
import '../../../data/models/installed_app_model.dart';
import '../../../data/repositories/virtual_profile_repository.dart';
import '../../../native/native_bridge.dart';

/// Backs the "add a clone" flow: pick an installed app, or import an APK.
class AppPickerController extends GetxController {
  AppPickerController({
    required this._bridge,
    required this._engine,
    required this._repository,
  });

  final NativeBridge _bridge;
  final VirtualizationEngine _engine;
  final VirtualProfileRepository _repository;
  final AppLogger _logger = const AppLogger('AppPickerController');

  final RxList<InstalledAppModel> apps = <InstalledAppModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isWorking = false.obs;
  final RxString query = ''.obs;
  final RxnString errorMessage = RxnString();

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
    final String needle = query.value.trim().toLowerCase();

    final List<InstalledAppModel> matching = apps.where((
      InstalledAppModel app,
    ) {
      if (needle.isNotEmpty &&
          !app.appName.toLowerCase().contains(needle) &&
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
  int Function(InstalledAppModel, InstalledAppModel) get _comparator =>
      switch (sort.value) {
        AppSort.name =>
          (InstalledAppModel a, InstalledAppModel b) =>
              a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
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
          .putIfAbsent(_initial(app.appName), () => <InstalledAppModel>[])
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

  static String _initial(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '#';
    }
    final String first = trimmed[0].toUpperCase();
    return RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
  }

  /// When opened from a profile card, the picker arrives pre-filtered to that package
  /// so "Add another clone" lands on the right app.
  @override
  void onInit() {
    super.onInit();
    final Object? argument = Get.arguments;
    if (argument is String && argument.isNotEmpty) {
      query.value = argument;
    }
  }

  @override
  void onReady() {
    super.onReady();
    loadApps();
  }

  Future<void> loadApps() async {
    isLoading.value = true;
    try {
      apps.assignAll(await _bridge.listInstalledApps());
      clonedPackages.assignAll(await _repository.clonedPackageNames());
      errorMessage.value = null;
    } on AppException catch (error, stackTrace) {
      _logger.error('Could not list installed apps', error, stackTrace);
      errorMessage.value = error.message;
    }
    isLoading.value = false;
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
      return await _bridge.analyzeApk(candidate.apkPath, candidate.packageName);
    } on AppException catch (error, stackTrace) {
      _logger.error(
        'APK analysis failed for ${candidate.packageName}',
        error,
        stackTrace,
      );
      return CompatibilityReport.unknown;
    }
  }

  /// Asks for the permissions the guest needs. Returns null when it could not be asked.
  Future<PermissionRequestResult?> requestPermissions(
    String packageName,
  ) async {
    try {
      final PermissionRequestResult result = await _bridge
          .requestGuestPermissions(packageName);
      _reports.remove(
        packageName,
      ); // grants changed; the cached verdict is stale
      return result;
    } on AppException catch (error) {
      errorMessage.value = error.message;
      return null;
    }
  }

  final Map<String, CompatibilityReport> _reports =
      <String, CompatibilityReport>{};

  /// Clones an installed app. Returns `null` on success, or a user-facing message.
  Future<String?> cloneInstalledApp(
    InstalledAppModel app, {
    bool installGms = false,
  }) async {
    if (isWorking.value) {
      return null;
    }
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
      return null;
    } on AppException catch (error) {
      return error.message;
    } finally {
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
    final List<PlatformFile> picked = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: packageFormat
          ? <String>['bin']
          : <String>['apk', 'bin'],
      withData: false,
      withReadStream: true,
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
          errorMessage.value = error.message;
          return null;
        } on IOException catch (error, stackTrace) {
          _logger.error('Could not copy the selected APK', error, stackTrace);
          errorMessage.value = 'The selected APK could not be read.';
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
  Future<String?> cloneApk(
    ApkCandidate candidate, {
    bool installGms = false,
  }) async {
    if (isWorking.value) {
      return null;
    }
    isWorking.value = true;
    try {
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
      return null;
    } on AppException catch (error) {
      return error.message;
    } finally {
      isWorking.value = false;
    }
  }
}

/// One alphabetical group in the picker.
@immutable
class AppSection {
  const AppSection({required this.letter, required this.apps});

  /// The heading: a single A-Z letter, or '#' for everything else.
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
