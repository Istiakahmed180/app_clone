/// The legal surface shown before the app can be used.
///
/// Every value here is a placeholder. The terms dialog links to these URLs and stores
/// the version the user agreed to, so both must be real before any build reaches a user:
/// pointing a consent screen at a URL that does not serve the policy is worse than
/// having no screen at all.
class LegalConstants {
  const LegalConstants._();

  // TODO(release): replace with the published policy URLs.
  static const String privacyPolicyUrl = 'https://example.com/duplika/privacy';
  static const String termsOfServiceUrl = 'https://example.com/duplika/terms';

  /// True while the URLs above are still placeholders.
  ///
  /// Read by the terms dialog, which will not present unpublished links as if they were
  /// the real policy. Flip it in the same commit that fills in the URLs.
  static const bool policiesArePlaceholders = true;

  /// Bumped whenever the terms change materially.
  ///
  /// Acceptance is stored per version, so raising this re-prompts everyone. Do not raise
  /// it for typo fixes -- an unnecessary re-prompt teaches users to dismiss without
  /// reading.
  static const int termsVersion = 1;
}
