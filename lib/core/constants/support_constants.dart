/// Where the app points the user when they want to reach a human, or to review it.
///
/// Both values below still have to be confirmed before a build reaches a user, the same
/// way [LegalConstants] does: a Contact row that opens a mailbox nobody reads, or a
/// review link to a listing that does not exist, is worse than no row at all.
class SupportConstants {
  const SupportConstants._();

  /// The inbox the Contact row opens. Change this if support is handled elsewhere.
  static const String supportEmail = 'support@tdevs.co';

  static const String applicationId = 'co.tdevs.duplika';

  /// The Play Store listing. `market:` hands off to the Play app when it is installed;
  /// the web URL is the fallback for when it is not.
  static const String playStoreUri = 'market://details?id=$applicationId';
  static const String playStoreWebUrl =
      'https://play.google.com/store/apps/details?id=$applicationId';

  /// True until Duplika is actually listed on the Play Store.
  ///
  /// Read by the Settings screen, which will not offer a review link that lands on a
  /// missing listing. Flip it in the same commit that publishes the app.
  static const bool isListedOnPlayStore = false;
}
