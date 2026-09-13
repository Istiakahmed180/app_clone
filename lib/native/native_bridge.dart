import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';
import '../core/diagnostics/channel_diagnostics.dart';
import '../core/diagnostics/diagnostic_operation.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';
import '../data/models/app_details.dart';
import '../data/models/app_disguise_mode.dart';
import '../data/models/battery_prompt_screen.dart';
import '../data/models/clone_permissions.dart';
import '../data/models/compatibility_report.dart';
import '../data/models/engine_result.dart';
import '../data/models/installed_app_model.dart';
import '../data/models/platform_info.dart';
import '../data/models/space_identity.dart';
import '../data/models/device_capacity.dart';
import '../data/models/test_app_model.dart';

/// The only place in the Dart codebase that talks to the platform channel.
///
/// Callers receive typed models; [MethodChannel], [PlatformException] and raw
/// maps never escape this class.
class NativeBridge {
  NativeBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'duplika/native_bridge';

  final MethodChannel _channel;
  final AppLogger _logger = const AppLogger('NativeBridge');

  Future<PlatformInfo> getPlatformInfo() async {
    final Map<String, dynamic> result = await _invokeMap('getPlatformInfo');
    return PlatformInfo.fromMap(result);
  }

  /// Space to keep containers in, and memory to run them in.
  ///
  /// Read on demand rather than cached with [getPlatformInfo]: both figures move, and
  /// one from app start would be the wrong one by the time a clone is requested.
  Future<DeviceCapacity> deviceCapacity() async {
    final Map<String, dynamic> result = await _invokeMap('getDeviceCapacity');
    return DeviceCapacity.fromMap(result);
  }

  /// What the app currently presents as on the launcher.
  ///
  /// The enabled manifest alias is the source of truth, so this is a real query rather than
  /// a stored preference. A failure reads as [AppDisguiseMode.normal], which never hides the
  /// app.
  Future<AppDisguiseMode> getAppDisguise() async {
    try {
      final EngineResponse response = await _invokeEngine('getAppDisguise');
      return AppDisguiseMode.parse(response.data['mode'] as String?);
    } on AppException catch (error, stackTrace) {
      _logger.error('Could not read the launcher disguise', error, stackTrace);
      return AppDisguiseMode.normal;
    }
  }

  /// Switches the launcher icon/name, and returns the state the platform reports afterwards
  /// — not the requested one, so a refused change cannot read as applied.
  Future<AppDisguiseMode> setAppDisguise(AppDisguiseMode mode) async {
    final EngineResponse response = await _invokeEngine(
      'setAppDisguise',
      <String, dynamic>{'mode': mode.wireName},
    );
    if (!response.success) {
      throw VirtualizationException(response.message, code: response.code);
    }
      return AppDisguiseMode.parse(response.data['mode'] as String?);
  }

  /// Opens Android's notification settings, where each clone is its own channel.
  ///
  /// Guests post under Duplika, but the engine namespaces each clone's channels and labels
  /// them with a clone number, so one clone can be silenced without the others. Returns
  /// normally when a screen opened; throws otherwise.
  Future<void> openCloneNotificationSettings() async {
    final EngineResponse response = await _invokeEngine('openCloneNotificationSettings');
    if (!response.success) {
      throw VirtualizationException(response.message, code: response.code);
    }
  }

  /// The dangerous permissions a clone's app declares, and which the user has denied for
  /// this clone. Throws when the clone has no container yet.
  Future<ClonePermissions> getClonePermissions({
    required String profileId,
    required String packageName,
  }) async {
    final EngineResponse response = await _invokeEngine(
      'getClonePermissions',
      <String, dynamic>{'profileId': profileId, 'packageName': packageName},
    );
    if (!response.success) {
      throw VirtualizationException(response.message, code: response.code);
    }
    return ClonePermissions.fromMap(response.data);
  }

  /// Allows or denies [permission] for one clone. See [ClonePermissions] for what this does
  /// and does not enforce.
  Future<void> setClonePermission({
    required String profileId,
    required String permission,
    required bool allowed,
  }) async {
    final EngineResponse response = await _invokeEngine('setClonePermission', <String, dynamic>{
      'profileId': profileId,
      'permission': permission,
      'allowed': allowed,
    });
    if (!response.success) {
      throw VirtualizationException(response.message, code: response.code);
    }
  }


  Future<bool> isTestAppInstalled() async {
    try {
      final bool? installed = await _channel.invokeMethod<bool>(
        'isTestAppInstalled',
      );
      return installed ?? false;
    } on PlatformException catch (error, stackTrace) {
      _logger.error('isTestAppInstalled failed', error, stackTrace);
      throw NativeBridgeException(
        'Could not check whether the test app is installed.',
      );
    } on MissingPluginException {
      // The host platform has no native bridge (unit tests, desktop, web).
      return false;
    }
  }

  /// Returns the test app's package metadata, or `null` when it is not installed.
  Future<TestAppModel?> getTestAppInfo() async {
    final Map<String, dynamic> result = await _invokeMap('getTestAppInfo');
    final TestAppModel model = TestAppModel.fromMap(result);
    return model.installed ? model : null;
  }

  /// Starts the real, unvirtualized test application.
  ///
  /// Throws [LaunchException] with the native error code when the launch could
  /// not be performed.
  Future<bool> launchTestApp() async {
    final Map<String, dynamic> result = await _invokeMap('launchTestApp');
    final bool success = result['success'] as bool? ?? false;
    if (success) {
      return true;
    }

    final String code = result['error'] as String? ?? 'LAUNCH_FAILED';
    throw LaunchException(_launchMessageFor(code), code: code);
  }

  // ---------------------------------------------------------------------------
  // Phase 2: virtualization engine
  // ---------------------------------------------------------------------------

  Future<VirtualizationAvailability> isVirtualizationAvailable() async {
    final Map<String, dynamic> result = await _invokeMap(
      'isVirtualizationAvailable',
    );
    return VirtualizationAvailability.fromMap(result);
  }

  Future<EngineResponse> initializeVirtualization() =>
      _invokeEngine('initializeVirtualization');

  Future<bool> isAppSupported(String packageName) async {
    final EngineResponse response = await _invokeEngine(
      'isAppSupported',
      <String, dynamic>{'packageName': packageName},
    );
    return response.data['supported'] as bool? ?? false;
  }

  Future<bool> checkSecureEnvironmentRequirement(String packageName) async {
    final EngineResponse response = await _invokeEngine(
      'checkSecureEnvironmentRequirement',
      <String, dynamic>{'packageName': packageName},
    );
    return response.data['requiresSecureEnv'] as bool? ?? false;
  }

  Future<EngineResponse> installAppToProfile(
    String profileId,
    String packageName, {
    bool installGms = false,
  }) => _invokeEngine('installAppToProfile', <String, dynamic>{
    ..._profileArgs(profileId, packageName),
    'installGms': installGms,
  });

  /// Launchable apps on the device, for the clone picker.
  ///
  /// Raises on failure rather than returning an empty list: the picker renders an empty
  /// result as "No matching apps", which would tell the user they have no apps when in
  /// fact the call failed. The caller already has an error path for this.
  Future<List<InstalledAppModel>> listInstalledApps({
    bool includeIcons = true,
  }) async {
    final EngineResponse response = await _invokeEngine(
      'listInstalledApps',
      <String, dynamic>{'includeIcons': includeIcons},
    );

    if (!response.success) {
      throw VirtualizationException(response.message, code: response.code);
    }

    final Object? apps = response.data['apps'];
    if (apps is! List) {
      return const <InstalledAppModel>[];
    }

    // A single malformed entry must not lose the whole list.
    return apps
        .whereType<Map<Object?, Object?>>()
        .map(
          (Map<Object?, Object?> app) => InstalledAppModel.fromMap(
            app.map(
              (Object? k, Object? v) => MapEntry<String, dynamic>('$k', v),
            ),
          ),
        )
        .toList(growable: false);
  }

  /// What will and will not work if this app is cloned.
  Future<CompatibilityReport> analyzeApp(String packageName) async {
    final EngineResponse response = await _invokeEngine(
      'analyzeApp',
      <String, dynamic>{'packageName': packageName},
    );
    return _reportOf(response, packageName);
  }

  /// What will and will not work if this APK is cloned, read from the archive itself.
  ///
  /// Unlike [analyzeApp] this needs no installed package, so an imported APK can be judged
  /// before anything is installed.
  Future<CompatibilityReport> analyzeApk(
    String apkPath,
    String packageName,
  ) async {
    final EngineResponse response = await _invokeEngine(
      'analyzeApk',
      <String, dynamic>{'apkPath': apkPath, 'packageName': packageName},
    );
    return _reportOf(response, packageName);
  }

  /// A failed analysis means nothing is known — not that the app is unsupported.
  ///
  /// Parsing an empty payload would yield `UNSUPPORTED` with no findings, which reads to
  /// the user as "blocked, for no stated reason". [CompatibilityReport.unknown] says
  /// plainly that it was not analysed instead.
  CompatibilityReport _reportOf(EngineResponse response, String packageName) {
    if (!response.success || response.data.isEmpty) {
      _logger.error(
        'Compatibility analysis unavailable for $packageName: ${response.code}',
      );
      return CompatibilityReport.unknown;
    }
    return CompatibilityReport.fromMap(response.data);
  }

  /// Whether the current launcher can pin shortcuts at all.
  Future<bool> areShortcutsSupported() async {    final EngineResponse response = await _invokeEngine(
      'areShortcutsSupported',
    );
    return response.data['supported'] as bool? ?? false;
  }

  /// Asks the launcher to put a clone on the home screen.
  ///
  /// Success means the launcher accepted the request; it still shows its own confirmation,
  /// so this does not mean the shortcut exists yet.
  Future<void> pinCloneShortcut({
    required String profileId,
    required String packageName,
    required String label,
    int spaceIndex = 1,
    int spaceCount = 1,
  }) async {
    final EngineResponse
    response = await _invokeEngine('pinCloneShortcut', <String, dynamic>{
      'profileId': profileId,
      'packageName': packageName,
      'label': label,
      // Which of the app's clones this is. The native side draws it onto the icon when
      // there is more than one, since otherwise every clone's shortcut is the same tile.
      'spaceIndex': spaceIndex,
      'spaceCount': spaceCount,
    });
    if (!response.success) {
      throw VirtualizationException(response.message, code: response.code);
    }
  }

  /// Icons for specific packages only.
  ///
  /// Prefer this over [listInstalledApps] when the caller already knows which packages it
  /// needs — decoding every launchable app's icon is expensive.
  Future<Map<String, Uint8List>> getAppIcons(
    Iterable<String> packageNames,
  ) async {
    final List<String> packages = packageNames.toSet().toList(growable: false);
    if (packages.isEmpty) {
      return <String, Uint8List>{};
    }

    final EngineResponse response = await _invokeEngine(
      'getAppIcons',
      <String, dynamic>{'packageNames': packages},
    );

    final Object? raw = response.data['icons'];
    if (raw is! Map) {
      return <String, Uint8List>{};
    }

    final Map<String, Uint8List> icons = <String, Uint8List>{};
    raw.forEach((Object? key, Object? value) {
      if (value is String && value.isNotEmpty) {
        icons['$key'] = base64Decode(value);
      }
    });
    return icons;
  }

  /// Reads an imported APK's identity. Throws [VirtualizationException] if unreadable.
  Future<ApkCandidate> inspectApk(List<String> apkPaths) async {
    final EngineResponse response = await _invokeEngine(
      'inspectApk',
      <String, dynamic>{'apkPaths': apkPaths},
    );
    if (!response.success) {
      throw VirtualizationException(response.message, code: response.code);
    }
    return ApkCandidate.fromMap(apkPaths, response.data);
  }

  Future<EngineResponse> installApkToProfile(
    String profileId,
    List<String> apkPaths,
    String packageName, {
    bool installGms = false,
  }) => _invokeEngine('installApkToProfile', <String, dynamic>{
    'profileId': profileId,
    'packageName': packageName,
    'apkPaths': apkPaths,
    'installGms': installGms,
  });

  Future<EngineResponse> uninstallAppFromProfile(
    String profileId,
    String packageName,
  ) => _invokeEngine(
    'uninstallAppFromProfile',
    _profileArgs(profileId, packageName),
  );

  Future<VirtualProfileState> profileState(
    String profileId,
    String packageName,
  ) async {
    final EngineResponse response = await _invokeEngine(
      'isAppInstalledInProfile',
      _profileArgs(profileId, packageName),
    );
    return VirtualProfileState.fromMap(response.data);
  }

  Future<EngineResponse> launchProfile(String profileId, String packageName) =>
      _invokeEngine('launchProfile', _profileArgs(profileId, packageName));

  Future<EngineResponse> stopProfile(String profileId, String packageName) =>
      _invokeEngine('stopProfile', _profileArgs(profileId, packageName));

  /// Empties this clone's container. The package stays installed.
  Future<EngineResponse> clearProfileData(
    String profileId,
    String packageName,
  ) => _invokeEngine('clearProfileData', _profileArgs(profileId, packageName));

  /// Empties only this clone's caches.
  Future<EngineResponse> clearProfileCache(
    String profileId,
    String packageName,
  ) => _invokeEngine('clearProfileCache', _profileArgs(profileId, packageName));

  /// Reads, regenerates or resets the identifiers one space presents as its own.
  ///
  /// One method for all three because they answer with the same shape: the caller always
  /// wants the resulting set, whichever way it got there.
  /// Reads, replaces or regenerates a space's identifier set.
  ///
  /// [values] is only sent for `'update'`.
  Future<SpaceIdentity> spaceIdentity(
    String profileId, {
    String action = 'read',
    Map<String, String>? values,
  }) async {
    final EngineResponse response = await _invokeEngine(
      'spaceIdentity',
      <String, dynamic>{
        'profileId': profileId,
        'action': action,
        if (values != null) 'values': values,
      },
    );
    if (!response.success) {
      throw VirtualizationException(response.message, code: response.code);
    }
    return SpaceIdentity.fromMap(response.data);
  }

  /// Offers this clone's APK to the Android share sheet.
  ///
  /// Success means the chooser opened, not that anything was sent — the user still picks
  /// a target, or dismisses it.
  Future<void> shareProfileApk({
    required String profileId,
    required String packageName,
    required String label,
  }) async {
    final EngineResponse response = await _invokeEngine(
      'shareProfileApk',
      <String, dynamic>{
        ..._profileArgs(profileId, packageName),
        'label': label,
      },
    );
    if (!response.success) {
      throw VirtualizationException(response.message, code: response.code);
    }
  }

  /// Everything Duplika can say about one installed package's archive.
  Future<AppDetails> appDetails(String packageName) async {
    final EngineResponse response = await _invokeEngine(
      'getAppDetails',
      <String, dynamic>{'packageName': packageName},
    );
    if (!response.success) {
      throw VirtualizationException(response.message, code: response.code);
    }
    return AppDetails.fromMap(response.data);
  }

  /// Offers a host-installed app's own APK to the share sheet.
  ///
  /// The picker's rows have no clone yet, so there is no profile to name.
  Future<void> shareInstalledApk({
    required String packageName,
    required String label,
  }) async {
    final EngineResponse response = await _invokeEngine(
      'shareInstalledApk',
      <String, dynamic>{'packageName': packageName, 'label': label},
    );
    if (!response.success) {
      throw VirtualizationException(response.message, code: response.code);
    }
  }

  Future<EngineResponse> deleteVirtualProfile(
    String profileId,
    String packageName,
  ) => _invokeEngine('deleteProfile', _profileArgs(profileId, packageName));

  // ---------------------------------------------------------------------------
  // Onboarding: Doze exemption
  // ---------------------------------------------------------------------------

  /// Whether Android currently exempts Duplika from Doze.
  ///
  /// Returns `false` rather than throwing when the platform cannot answer: the caller
  /// uses this to decide whether to offer the prompt, and offering it needlessly is a
  /// smaller harm than a crash on a device that has no power manager.
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final EngineResponse response = await _invokeEngine(
        'isIgnoringBatteryOptimizations',
      );
      return response.data['ignoring'] as bool? ?? false;
    } on NativeBridgeException catch (error, stackTrace) {
      _logger.error(
        'Battery optimisation state unavailable',
        error,
        stackTrace,
      );
      return false;
    }
  }

  /// Opens the Doze exemption prompt and reports which screen the system showed.
  ///
  /// Success means a screen opened, not that the exemption was granted -- Android owns
  /// the answer. Re-read [isIgnoringBatteryOptimizations] after the user returns.
  Future<BatteryPromptScreen> requestIgnoreBatteryOptimizations() async {
    final EngineResponse response = await _invokeEngine(
      'requestIgnoreBatteryOptimizations',
    );
    if (!response.success) {
      throw VirtualizationException(response.message, code: response.code);
    }
    return BatteryPromptScreen.parse(response.data['screen'] as String?);
  }

  Map<String, dynamic> _profileArgs(String profileId, String packageName) =>
      <String, dynamic>{'profileId': profileId, 'packageName': packageName};

  Future<EngineResponse> _invokeEngine(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    final Map<String, dynamic> result = await _invokeMap(method, arguments);
    return EngineResponse.fromMap(result);
  }

  /// Every platform call goes through here, which is why the diagnostics wrapper lives
  /// here and not at the thirty-odd call sites above: a method added later is
  /// instrumented by construction rather than by remembering to instrument it.
  Future<Map<String, dynamic>> _invokeMap(
    String method, [
    Map<String, dynamic>? arguments,
  ]) {
    final Map<String, dynamic>? payload = _withCorrelation(arguments);
    return ChannelDiagnostics.trace<Map<String, dynamic>>(
      channel: channelName,
      method: method,
      arguments: payload,
      // The envelope's own verdict, not the payload: a result summary that reprinted
      // the data would put installed-app lists and icon maps into the log.
      describeResult: (Map<String, dynamic> result) =>
          'success=${result['success'] ?? '-'} code=${result['code'] ?? '-'}',
      call: () => _rawInvoke(method, payload),
    );
  }

  Future<Map<String, dynamic>> _rawInvoke(
    String method,
    Map<String, dynamic>? arguments,
  ) async {
    try {
      final Map<Object?, Object?>? raw = await _channel
          .invokeMethod<Map<Object?, Object?>>(method, arguments);
      if (raw == null) {
        throw NativeBridgeException(
          'The native bridge returned no data for $method.',
        );
      }
      return raw.map(
        (Object? key, Object? value) =>
            MapEntry<String, dynamic>('$key', value),
      );
    } on PlatformException catch (error, stackTrace) {
      _logger.error('$method failed', error, stackTrace);
      throw NativeBridgeException('The native bridge call "$method" failed.');
    } on MissingPluginException catch (error, stackTrace) {
      _logger.error('$method unavailable on this platform', error, stackTrace);
      throw NativeBridgeException('This feature is only available on Android.');
    }
  }

  /// Adds the ambient operation id to a call's arguments.
  ///
  /// This is what lets the Kotlin side tag its own events — engine, installer, guest
  /// process — with the operation that caused them, so a failed launch reads as one
  /// timeline instead of as unrelated host and native lines. The keys are prefixed with
  /// `__` so they can never collide with a real parameter, and native code that does not
  /// look for them simply ignores them.
  ///
  /// Returns null when there is nothing to add, so a call that took no arguments still
  /// takes none.
  Map<String, dynamic>? _withCorrelation(Map<String, dynamic>? arguments) {
    final DiagnosticOperation? operation = DiagnosticOperation.current;
    if (operation == null) {
      return arguments;
    }
    return <String, dynamic>{
      ...?arguments,
      '__opId': operation.id,
      '__opName': operation.name,
    };
  }

  String _launchMessageFor(String code) {
    switch (code) {
      case 'TEST_APP_NOT_INSTALLED':
        return 'Install ${AppConstants.testAppFallbackName} to launch this profile.';
      default:
        return 'The test application could not be launched.';
    }
  }
}
