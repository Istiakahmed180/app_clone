import 'package:local_auth/local_auth.dart';

/// What came of asking the device for a biometric.
enum BiometricResult {
  /// The device confirmed the user.
  success,

  /// The user dismissed the prompt, or the system did.
  cancelled,

  /// There is no enrolled biometric, or no hardware to use.
  unavailable,

  /// The prompt ran and the fingerprint or face did not match.
  failed,
}

/// The device biometric, behind a seam.
///
/// Wrapped rather than called directly so the Private space controller can be tested
/// without a platform channel, and so the one plugin that could throw a platform-specific
/// exception is the only place that has to catch it.
class BiometricAuthenticator {
  BiometricAuthenticator({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Whether the device can present a biometric prompt at all right now.
  ///
  /// A device with no enrolled fingerprint answers false here, which is why the lock
  /// treats the PIN as mandatory and biometric as optional.
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) {
        return false;
      }
      return await _auth.canCheckBiometrics;
    } on Object {
      return false;
    }
  }

  /// Prompts for a biometric. `biometricOnly` keeps the OS from offering the device
  /// passcode instead: the Private space has its own PIN for that.
  Future<BiometricResult> authenticate({required String reason}) async {
    try {
      final bool ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
      return ok ? BiometricResult.success : BiometricResult.failed;
    } on LocalAuthException catch (error) {
      return switch (error.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.userRequestedFallback =>
          BiometricResult.cancelled,
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
          BiometricResult.unavailable,
        _ => BiometricResult.failed,
      };
    } on Object {
      return BiometricResult.failed;
    }
  }
}
