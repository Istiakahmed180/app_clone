import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';
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

  Future<Map<String, dynamic>> _invokeMap(String method) async {
    try {
      final Map<Object?, Object?>? raw =
          await _channel.invokeMethod<Map<Object?, Object?>>(method);
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
