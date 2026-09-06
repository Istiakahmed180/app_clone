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
