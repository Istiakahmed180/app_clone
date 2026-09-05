/// Values shared across layers. Kept deliberately small for Phase 1.
class AppConstants {
  const AppConstants._();

  static const String appTitle = 'Virtual Space';

  /// The single controlled application Phase 1 knows about.
  static const String testAppPackage = 'com.example.virtualtestapp';
  static const String testAppFallbackName = 'Virtual Test App';

  static const String profilesStorageKey = 'virtual_space.profiles.v1';

  static const int maxProfileNameLength = 40;

  /// Stable native error codes surfaced by the virtualization engine.
  static const String errorSecureEnvRequired = 'SECURE_ENV_REQUIRED';
  static const String errorAppNotSupported = 'APP_NOT_SUPPORTED';
  static const String errorVirtualAppNotInstalled = 'VIRTUAL_APP_NOT_INSTALLED';
}
