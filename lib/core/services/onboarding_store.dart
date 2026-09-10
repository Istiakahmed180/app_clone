import 'profile_storage.dart';

/// What the user has already been asked, and answered.
///
/// Backed by the same [ProfileStorage] seam as profiles, so onboarding logic is testable
/// without SharedPreferences or a device.
class OnboardingStore {
  const OnboardingStore({ProfileStorage? storage})
      : _storage = storage ?? const SharedPreferencesProfileStorage();

  static const String backgroundPromptKey = 'duplika.onboarding.background_prompt_dismissed';

  final ProfileStorage _storage;

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
  }
}
