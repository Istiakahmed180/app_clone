import 'profile_storage.dart';

/// What the user has already been asked, and answered.
///
/// Backed by the same [ProfileStorage] seam as profiles, so onboarding logic is testable
/// without SharedPreferences or a device.
class OnboardingStore {
  const OnboardingStore({ProfileStorage? storage})
      : _storage = storage ?? const SharedPreferencesProfileStorage();

  static const String backgroundPromptKey = 'duplika.onboarding.background_prompt_dismissed';
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

  /// Whether the user has waved away the Doze exemption prompt.
  ///
  /// Dismissal is permanent by design: the exemption is a convenience, and re-offering it
  /// on every launch is the pattern this app is trying not to be.
  Future<bool> backgroundPromptDismissed() async =>
      await _storage.read(backgroundPromptKey) == 'true';

  Future<void> dismissBackgroundPrompt() => _storage.write(backgroundPromptKey, 'true');

  /// Clears every onboarding answer. Development and tests only.
  Future<void> reset() async {
    await _storage.delete(backgroundPromptKey);
    await _storage.delete(disclosureKey);
  }
}
