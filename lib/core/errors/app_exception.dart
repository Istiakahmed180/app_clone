/// Stable codes for the failures this app diagnoses itself.
///
/// The engine's own codes live in the `EngineErrorCodes` object in
/// `VirtualizationEngineAdapter.kt` and arrive over the channel; these are the ones with
/// no native counterpart, so they are declared here and never collide with those.
abstract final class AppErrorCodes {
  static const String profileNameEmpty = 'PROFILE_NAME_EMPTY';
  static const String profileNameTooLong = 'PROFILE_NAME_TOO_LONG';
  static const String profileStorageUnreadable = 'PROFILE_STORAGE_UNREADABLE';
  static const String profileNotFound = 'PROFILE_NOT_FOUND';

  /// A picture the user picked could not be read, decoded or stored as a clone's icon.
  static const String cloneIconFailed = 'CLONE_ICON_FAILED';
  static const String cloneDeleteFailed = 'CLONE_DELETE_FAILED';

  /// The channel answered, but with nothing usable in it.
  static const String bridgeNoData = 'BRIDGE_NO_DATA';

  /// The channel call itself failed.
  static const String bridgeCallFailed = 'BRIDGE_CALL_FAILED';

  /// Reached on a platform that has no native side at all.
  static const String bridgeUnsupportedPlatform = 'BRIDGE_UNSUPPORTED_PLATFORM';

  /// The test application's installed state could not be read.
  static const String testAppCheckFailed = 'TEST_APP_CHECK_FAILED';

  /// A backend that models the engine's shape without providing it.
  static const String demoEngineUnsupported = 'DEMO_ENGINE_UNSUPPORTED';
}

/// Base type for errors this application raises deliberately.
///
/// Every one carries a [code] as well as a [message]. The code is what the UI translates
/// — see `appErrorMessage` — and what a caller branches on; the message is the English
/// original, kept as the fallback for a code nothing has wording for yet, and as the only
/// carrier of detail the engine put in words rather than in structure.
///
/// Raw platform stack traces never reach either field.
sealed class AppException implements Exception {
  const AppException(this.code, this.message);

  /// Stable, never shown to a user.
  final String code;

  /// Safe to show, but only as a last resort: it is not translated.
  final String message;

  @override
  String toString() => '$runtimeType($code): $message';
}

/// A user-supplied value failed validation before it reached the repository.
class ValidationException extends AppException {
  const ValidationException(super.code, super.message);
}

/// Reading or writing local profile storage failed.
class StorageException extends AppException {
  const StorageException(super.code, super.message);
}

/// A call across the platform channel failed or returned an unusable shape.
class NativeBridgeException extends AppException {
  const NativeBridgeException(super.code, super.message);
}

/// The requested virtual profile does not exist.
class ProfileNotFoundException extends AppException {
  const ProfileNotFoundException(String profileId)
      : super(AppErrorCodes.profileNotFound, 'No profile exists with id $profileId');
}

/// Launching the controlled test application did not succeed.
class LaunchException extends AppException {
  const LaunchException(String message, {required String code})
      : super(code, message);
}

/// A virtualization engine operation failed.
///
/// [code] is the stable native error code (the `EngineErrorCodes` object in
/// `VirtualizationEngineAdapter.kt`), so callers can branch — and the UI can translate —
/// without parsing messages.
class VirtualizationException extends AppException {
  const VirtualizationException(String message, {required String code})
      : super(code, message);
}
