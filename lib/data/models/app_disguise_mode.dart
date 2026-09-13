/// What the app presents itself as on the launcher.
///
/// The value is not stored in Dart: the enabled `activity-alias` is the source of truth, and
/// [AppDisguiseMode] is just its wire shape. A build that cannot answer reads as [normal],
/// because a failed lookup must never leave the app hidden with no way back in.
enum AppDisguiseMode {
  /// The app's own icon and name.
  normal,

  /// A calculator icon and name that opens a calculator until the Private space PIN is
  /// entered.
  calculator;

  static AppDisguiseMode parse(String? raw) => switch (raw) {
        'CALCULATOR' => AppDisguiseMode.calculator,
        _ => AppDisguiseMode.normal,
      };

  String get wireName => name.toUpperCase();
}
