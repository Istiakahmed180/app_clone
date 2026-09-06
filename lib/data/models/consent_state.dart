/// The outcome of a GDPR/TCF consent request, as reported by the UMP SDK.
///
/// [failed] is deliberately not an error: Duplika shows no ads and sends no personal
/// data anywhere, so an unreachable or unconfigured consent form must not stop the user
/// reaching their clones. Callers record the reason and carry on.
class ConsentState {
  const ConsentState({
    required this.status,
    required this.formShown,
    required this.privacyOptionsRequired,
    this.errorCode,
    this.errorMessage,
  });

  /// The state before anything has been asked, and the state used when the platform
  /// has no native bridge at all (unit tests, desktop, web).
  static const ConsentState unknown = ConsentState(
    status: ConsentStatus.unknown,
    formShown: false,
    privacyOptionsRequired: false,
  );

  factory ConsentState.fromMap(Map<String, dynamic> map) => ConsentState(
        status: ConsentStatus.parse(map['status'] as String?),
        formShown: map['shown'] as bool? ?? false,
        privacyOptionsRequired: map['privacyOptionsRequired'] as bool? ?? false,
        errorCode: map['errorCode'] as int?,
        errorMessage: map['errorMessage'] as String?,
      );

  final ConsentStatus status;

  /// Whether a form was actually put in front of the user this time.
  final bool formShown;

  /// Whether consent must remain withdrawable from a "privacy options" entry point.
  /// The TCF requires one once consent has been gathered in a regulated region.
  final bool privacyOptionsRequired;

  final int? errorCode;
  final String? errorMessage;

  bool get failed => errorCode != null;

  /// Nothing more to ask: either the user answered, or no regulator requires it.
  bool get resolved =>
      status == ConsentStatus.obtained || status == ConsentStatus.notRequired;

  @override
  String toString() => 'ConsentState(${status.name}, shown: $formShown, error: $errorCode)';
}

enum ConsentStatus {
  unknown,
  required_,
  notRequired,
  obtained;

  static ConsentStatus parse(String? raw) {
    switch (raw) {
      case 'required':
        return ConsentStatus.required_;
      case 'notRequired':
        return ConsentStatus.notRequired;
      case 'obtained':
        return ConsentStatus.obtained;
      default:
        return ConsentStatus.unknown;
    }
  }
}

/// Which screen the system opened when asked to exempt Duplika from Doze.
///
/// The one-tap dialog is preferred, but not every device has it; the caller needs to
/// know which one appeared to word what happens next honestly.
enum BatteryPromptScreen {
  /// Already exempt; nothing was opened.
  none,

  /// The one-tap system dialog.
  dialog,

  /// The full battery-optimisation list, where the user must find Duplika themselves.
  settings;

  static BatteryPromptScreen parse(String? raw) {
    switch (raw) {
      case 'dialog':
        return BatteryPromptScreen.dialog;
      case 'settings':
        return BatteryPromptScreen.settings;
      default:
        return BatteryPromptScreen.none;
    }
  }
}
