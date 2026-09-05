import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';
import '../data/models/engine_result.dart';
import '../data/models/installed_app_model.dart';
import '../data/models/platform_info.dart';
import '../data/models/test_app_model.dart';

/// The only place in the Dart codebase that talks to the platform channel.
///
/// Callers receive typed models; [MethodChannel], [PlatformException] and raw
/// maps never escape this class.
class NativeBridge {
  NativeBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'virtual_space/native_bridge';

  final MethodChannel _channel;
  final AppLogger _logger = const AppLogger('NativeBridge');

  Future<PlatformInfo> getPlatformInfo() async {
    final Map<String, dynamic> result = await _invokeMap('getPlatformInfo');
    return PlatformInfo.fromMap(result);
  }

  Future<bool> isTestAppInstalled() async {
    try {
      final bool? installed = await _channel.invokeMethod<bool>('isTestAppInstalled');
      return installed ?? false;
    } on PlatformException catch (error, stackTrace) {
      _logger.error('isTestAppInstalled failed', error, stackTrace);
      throw NativeBridgeException('Could not check whether the test app is installed.');
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
    final Map<String, dynamic> result = await _invokeMap('isVirtualizationAvailable');
    return VirtualizationAvailability.fromMap(result);
  }

  Future<EngineResponse> initializeVirtualization() =>
      _invokeEngine('initializeVirtualization');

  Future<bool> isAppSupported(String packageName) async {
    final EngineResponse response =
        await _invokeEngine('isAppSupported', <String, dynamic>{'packageName': packageName});
    return response.data['supported'] as bool? ?? false;
  }

  Future<bool> checkSecureEnvironmentRequirement(String packageName) async {
    final EngineResponse response = await _invokeEngine(
      'checkSecureEnvironmentRequirement',
      <String, dynamic>{'packageName': packageName},
    );
    return response.data['requiresSecureEnv'] as bool? ?? false;
  }

  Future<EngineResponse> installAppToProfile(String profileId, String packageName) =>
      _invokeEngine('installAppToProfile', _profileArgs(profileId, packageName));

  /// Launchable apps on the device, for the clone picker.
  Future<List<InstalledAppModel>> listInstalledApps({bool includeIcons = true}) async {
    final EngineResponse response = await _invokeEngine(
      'listInstalledApps',
      <String, dynamic>{'includeIcons': includeIcons},
    );
    final List<dynamic> apps = response.data['apps'] as List<dynamic>? ?? <dynamic>[];
    return apps
        .map((dynamic app) => InstalledAppModel.fromMap(
              (app as Map<Object?, Object?>)
                  .map((Object? k, Object? v) => MapEntry<String, dynamic>('$k', v)),
            ))
        .toList(growable: false);
  }

  /// Icons for specific packages only.
  ///
  /// Prefer this over [listInstalledApps] when the caller already knows which packages it
  /// needs — decoding every launchable app's icon is expensive.
  Future<Map<String, Uint8List>> getAppIcons(Iterable<String> packageNames) async {
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
  Future<ApkCandidate> inspectApk(String apkPath) async {
    final EngineResponse response =
        await _invokeEngine('inspectApk', <String, dynamic>{'apkPath': apkPath});
    if (!response.success) {
      throw VirtualizationException(response.message, code: response.code);
    }
    return ApkCandidate.fromMap(apkPath, response.data);
  }

  Future<EngineResponse> installApkToProfile(
    String profileId,
    String apkPath,
    String packageName,
  ) =>
      _invokeEngine('installApkToProfile', <String, dynamic>{
        'profileId': profileId,
        'packageName': packageName,
        'apkPath': apkPath,
      });

  Future<EngineResponse> uninstallAppFromProfile(String profileId, String packageName) =>
      _invokeEngine('uninstallAppFromProfile', _profileArgs(profileId, packageName));

  Future<VirtualProfileState> profileState(String profileId, String packageName) async {
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

  Future<EngineResponse> deleteVirtualProfile(String profileId, String packageName) =>
      _invokeEngine('deleteProfile', _profileArgs(profileId, packageName));

  Map<String, dynamic> _profileArgs(String profileId, String packageName) =>
      <String, dynamic>{'profileId': profileId, 'packageName': packageName};

  Future<EngineResponse> _invokeEngine(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    final Map<String, dynamic> result = await _invokeMap(method, arguments);
    return EngineResponse.fromMap(result);
  }

  Future<Map<String, dynamic>> _invokeMap(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    try {
      final Map<Object?, Object?>? raw =
          await _channel.invokeMethod<Map<Object?, Object?>>(method, arguments);
      if (raw == null) {
        throw NativeBridgeException('The native bridge returned no data for $method.');
      }
      return raw.map((Object? key, Object? value) => MapEntry<String, dynamic>('$key', value));
    } on PlatformException catch (error, stackTrace) {
      _logger.error('$method failed', error, stackTrace);
      throw NativeBridgeException('The native bridge call "$method" failed.');
    } on MissingPluginException catch (error, stackTrace) {
      _logger.error('$method unavailable on this platform', error, stackTrace);
      throw NativeBridgeException('This feature is only available on Android.');
    }
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
