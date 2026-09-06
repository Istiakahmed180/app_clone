import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

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

  /// Apps matching the current search, by name or package.
  List<InstalledAppModel> get visibleApps {
    final String needle = query.value.trim().toLowerCase();
    if (needle.isEmpty) {
      return apps;
    }
    return apps
        .where((InstalledAppModel app) =>
            app.appName.toLowerCase().contains(needle) ||
            app.packageName.toLowerCase().contains(needle))
        .toList(growable: false);
  }

  /// [visibleApps] cut into alphabetical sections, in draw order.
  ///
  /// Sections are what keep the list lazy under a grouped layout: the outer list builds
  /// one bordered group at a time, so a device with three hundred apps still only lays
  /// out what is on screen. Anything not starting with a letter collects under '#',
  /// last, rather than being scattered through A-Z by its raw code point.
  List<AppSection> get sections {
    final List<InstalledAppModel> visible = visibleApps.toList()
      ..sort((InstalledAppModel a, InstalledAppModel b) =>
          a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));

    final Map<String, List<InstalledAppModel>> grouped =
        <String, List<InstalledAppModel>>{};
    for (final InstalledAppModel app in visible) {
      grouped.putIfAbsent(_initial(app.appName), () => <InstalledAppModel>[]).add(app);
    }

    final List<String> letters = grouped.keys.toList()..sort();
    // '#' sorts before 'A' by code point, which would open the list on the odd names.
    if (letters.remove('#')) {
      letters.add('#');
    }

    return letters
        .map((String letter) => AppSection(letter: letter, apps: grouped[letter]!))
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
      _logger.error('Compatibility analysis failed for $packageName', error, stackTrace);
      return CompatibilityReport.unknown;
    }
  }

  /// Compatibility verdict for a picked APK, read from the archive rather than assumed.
  Future<CompatibilityReport> analyzeApk(ApkCandidate candidate) async {
    try {
      return await _bridge.analyzeApk(candidate.apkPath, candidate.packageName);
    } on AppException catch (error, stackTrace) {
      _logger.error('APK analysis failed for ${candidate.packageName}', error, stackTrace);
      return CompatibilityReport.unknown;
    }
  }

  /// Asks for the permissions the guest needs. Returns null when it could not be asked.
  Future<PermissionRequestResult?> requestPermissions(String packageName) async {
    try {
      final PermissionRequestResult result =
          await _bridge.requestGuestPermissions(packageName);
      _reports.remove(packageName); // grants changed; the cached verdict is stale
      return result;
    } on AppException catch (error) {
      errorMessage.value = error.message;
      return null;
    }
  }

  final Map<String, CompatibilityReport> _reports = <String, CompatibilityReport>{};

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
  Future<ApkCandidate?> pickApk() async {
    final PlatformFile? picked = await FilePicker.pickFile();
    if (picked == null) {
      return null;
    }

    if (!picked.name.toLowerCase().endsWith('.apk')) {
      errorMessage.value = 'Please choose an .apk file.';
      return null;
    }

    isWorking.value = true;
    try {
      final String path = await _materialise(picked);
      return await _bridge.inspectApk(path);
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
  }

  /// Copies the picked file into app cache and returns its real path.
  ///
  /// Android's document picker hands back a `content://` URI, which has no filesystem
  /// path; both `getPackageArchiveInfo` and the engine's installer need a real file.
  /// The copy is streamed so a large APK never has to sit in memory.
  Future<String> _materialise(PlatformFile picked) async {
    final Directory cache = await getTemporaryDirectory();
    final Directory imports = Directory('${cache.path}/apk_imports');

    // A previous import can be hundreds of megabytes; clear the staging area rather than
    // letting copies accumulate. The engine keeps its own retained copy of anything that
    // was actually installed, so nothing here is needed after this call.
    if (imports.existsSync()) {
      imports.deleteSync(recursive: true);
    }
    imports.createSync(recursive: true);

    final File target = File('${imports.path}/${DateTime.now().millisecondsSinceEpoch}.apk');
    final IOSink sink = target.openWrite();
    try {
      await sink.addStream(picked.readAsByteStream());
    } finally {
      await sink.close();
    }
    return target.path;
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
        apkPath: candidate.apkPath,
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
