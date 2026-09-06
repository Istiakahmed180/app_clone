/// Values shared across layers. Kept deliberately small for Phase 1.
class AppConstants {
  const AppConstants._();

  static const String appTitle = 'Duplika';

  /// The controlled test application.
  ///
  /// Any installed app can be cloned; this one is singled out only because the home
  /// screen reports whether it is present, and the test suite uses it as a known
  /// quantity.
  static const String testAppPackage = 'com.example.virtualtestapp';
  static const String testAppFallbackName = 'Virtual Test App';

  static const String profilesStorageKey = 'duplika.profiles.v1';

  static const int maxProfileNameLength = 40;

  /// Stable native error codes surfaced by the virtualization engine.
  static const String errorSecureEnvRequired = 'SECURE_ENV_REQUIRED';
  static const String errorAppNotSupported = 'APP_NOT_SUPPORTED';
  static const String errorAppNotFound = 'APP_NOT_FOUND';
  static const String errorVirtualAppNotInstalled = 'VIRTUAL_APP_NOT_INSTALLED';
}
