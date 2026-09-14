import 'profile_storage.dart';

/// What the user has already been asked, and answered.
///
/// Backed by the same [ProfileStorage] seam as profiles, so onboarding logic is testable
/// without SharedPreferences or a device.
class OnboardingStore {
  const OnboardingStore({ProfileStorage? storage})
      : _storage = storage ?? const SharedPreferencesProfileStorage();

  static const String disclosureKey = 'duplika.onboarding.disclosure_accepted';

  final ProfileStorage _storage;

  /// Whether the user has accepted the data-and-permissions disclosure.
  ///
  /// Play requires a *prominent disclosure* for the installed-app inventory that
  /// `QUERY_ALL_PACKAGES` makes readable. The old terms dialog that carried it was
  /// removed, so this is the surface that replaces it, and it is remembered here.
  Future<bool> disclosureAccepted() async =>
      await _storage.read(disclosureKey) == 'true';

  Future<void> acceptDisclosure() => _storage.write(disclosureKey, 'true');

  /// Clears every onboarding answer. Development and tests only.
  Future<void> reset() async {
    await _storage.delete(disclosureKey);
  }
}
