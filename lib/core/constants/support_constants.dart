/// Where the app points the user when they want to reach a human, or to review it.
///
/// Every value here has to be confirmed before a build reaches a user, the same way
/// `LegalConstants` does: a Contact row that opens a mailbox nobody reads, or a review
/// link to a listing that does not exist, is worse than no row at all.
class SupportConstants {
  const SupportConstants._();

  /// The inbox the Contact screen's Email row opens. Change this if support is handled
  /// elsewhere.
  static const String supportEmail = 'support@tdevs.co';

  /// The WhatsApp number support answers on: country code first, digits only, no `+`,
  /// spaces or dashes — that is the form `wa.me` takes.
  ///
  /// Empty until it is known. The Contact screen renders the row inert rather than
  /// dropping it, so an unconfigured channel is visible as unconfigured instead of
  /// silently missing.
  static const String whatsAppNumber = '';

  /// The Telegram username support answers on, without the leading `@`.
  static const String telegramHandle = '';

  static bool get hasWhatsApp => whatsAppNumber.isNotEmpty;

  static bool get hasTelegram => telegramHandle.isNotEmpty;

  static String get whatsAppUrl => 'https://wa.me/$whatsAppNumber';

  static String get telegramUrl => 'https://t.me/$telegramHandle';

  /// Roughly how long a reply takes. Shown to the user, so it has to stay true.
  static const String responseTime = 'We usually reply within 1\u20132 business days.';

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
