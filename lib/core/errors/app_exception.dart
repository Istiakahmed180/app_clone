/// Base type for errors this application raises deliberately.
///
/// Anything thrown as an [AppException] carries a message that is safe to show
/// to a user; raw platform stack traces never reach the UI.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// A user-supplied value failed validation before it reached the repository.
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Reading or writing local profile storage failed.
class StorageException extends AppException {
  const StorageException(super.message);
}

/// A call across the platform channel failed or returned an unusable shape.
class NativeBridgeException extends AppException {
  const NativeBridgeException(super.message);
}

/// The requested virtual profile does not exist.
class ProfileNotFoundException extends AppException {
  const ProfileNotFoundException(String profileId)
      : super('No profile exists with id $profileId');
}

/// Launching the controlled test application did not succeed.
class LaunchException extends AppException {
  const LaunchException(super.message, {required this.code});

  final String code;
}
