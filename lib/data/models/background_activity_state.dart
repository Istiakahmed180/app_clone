/// Whether Android lets Duplika run in the background, as far as it can be read.
///
/// Two separate controls decide this and neither implies the other: the Doze exemption
/// ([exempt]) and the platform's background restriction ([restricted]). A clone runs inside
/// Duplika's process group, so when either one closes, a cloned messenger stops delivering
/// while the user believes it is running.
class BackgroundActivityState {
  const BackgroundActivityState({
    required this.exempt,
    required this.restricted,
    required this.standbyBucket,
    this.nextStep,
  });

  /// Whether Doze exempts Duplika — the "Optimise battery use: Don't optimise" switch.
  final bool exempt;

  /// Android's background restriction. Null on releases that cannot answer.
  final bool? restricted;

  /// The app standby bucket Android put Duplika in. Reported, not acted on.
  final String standbyBucket;

  /// The extra tap the OEM's screen needs, when it is a known one — `batteryUsage` on the
  /// OEM builds where the switch sits under that row. Null when the info page is the whole
  /// story.
  final String? nextStep;

  /// Whether Android's own controls are all there is to check.
  ///
  /// False on the builds that keep a switch of their own ([nextStep] is the extra tap that
  /// finds it). That switch is read by nothing: measured on a OnePlus with it off,
  /// [`isBackgroundRestricted`], the `RUN_ANY_IN_BACKGROUND` app-op and the standby bucket
  /// all keep reading as if nothing had changed. So on those builds the state cannot be
  /// called allowed -- not because it is broken, but because the app cannot see it, and a
  /// green `Allowed` over a switch it never read is how a user ends up trusting a setting
  /// that is off.
  bool get verifiable => nextStep == null;

  /// Whether the user has allowed it: Doze exempts the app and Android has not been told
  /// to restrict it.
  ///
  /// Two states by product decision, because the honest middle ground is worse UX than it
  /// is information: Android's own "Optimised" is the default the fresh-install flow lands
  /// in, and showing it beside a green system toggle reads as a fault. Anything that is
  /// not this state is `Not allowed`, and the guide is what turns it into this state.
  ///
  /// On the OEM builds whose second switch cannot be read, this is as far as the app can
  /// see: the switch itself is invisible ([verifiable] is false), so a user who turns it
  /// off is not detected here. That is a measured platform limit, not a bug.
  bool get allowed => exempt && restricted != true;

  factory BackgroundActivityState.fromMap(Map<String, dynamic> map) {
    return BackgroundActivityState(
      exempt: map['exempt'] as bool? ?? false,
      restricted: map['restricted'] as bool?,
      standbyBucket: map['standbyBucket'] as String? ?? 'unknown',
      nextStep: map['nextStep'] as String?,
    );
  }
}

/// Which system page opened when asked for the background activity settings.
enum BackgroundActivityScreen {
  /// Nothing opened.
  none,

  /// The app's own info page, where the OEM's battery page starts.
  appInfo,

  /// The battery optimisation list, where Duplika has to be found by hand.
  batterySettings;

  static BackgroundActivityScreen parse(String? raw) {
    switch (raw) {
      case 'appInfo':
        return BackgroundActivityScreen.appInfo;
      case 'batterySettings':
        return BackgroundActivityScreen.batterySettings;
      default:
        return BackgroundActivityScreen.none;
    }
  }
}
