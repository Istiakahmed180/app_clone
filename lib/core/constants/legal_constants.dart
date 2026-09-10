/// The legal surface the app links to.
///
/// Every value here is a placeholder. Settings links to these URLs, so they must be real
/// before any build reaches a user: pointing a Privacy Policy row at a URL that does not
/// serve the policy is worse than having no row at all.
class LegalConstants {
  const LegalConstants._();

  // TODO(release): replace with the published policy URLs.
  static const String privacyPolicyUrl = 'https://example.com/duplika/privacy';
  static const String termsOfServiceUrl = 'https://example.com/duplika/terms';

  /// True while the URLs above are still placeholders.
  ///
  /// Read by Settings, which will not present unpublished links as if they were the real
  /// policy. Flip it in the same commit that fills in the URLs.
  static const bool policiesArePlaceholders = true;
}
