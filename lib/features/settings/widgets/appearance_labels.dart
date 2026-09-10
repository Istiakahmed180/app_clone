import 'package:flutter/material.dart';

/// How [ThemeMode] is named to the user.
///
/// 'System default' rather than 'System': the Settings row shows this string as its
/// current value, and 'System' there reads like a place rather than a choice.
String appearanceLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return 'System default';
    case ThemeMode.light:
      return 'Light';
    case ThemeMode.dark:
      return 'Dark';
  }
}

/// The line under the name on the Appearance screen — what the mode actually does.
String appearanceDescription(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return 'Match your device settings';
    case ThemeMode.light:
      return 'Always use light theme';
    case ThemeMode.dark:
      return 'Always use dark theme';
  }
}

IconData appearanceIcon(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return Icons.contrast_outlined;
    case ThemeMode.light:
      return Icons.light_mode_outlined;
    case ThemeMode.dark:
      return Icons.dark_mode_outlined;
  }
}

/// Which palette a mode actually resolves to right now.
///
/// [ThemeMode.system] has no fixed answer, so the device's own setting decides — which
/// is why the preview needs a context to work this out and cannot be told statically.
Brightness effectiveBrightness(ThemeMode mode, BuildContext context) {
  switch (mode) {
    case ThemeMode.light:
      return Brightness.light;
    case ThemeMode.dark:
      return Brightness.dark;
    case ThemeMode.system:
      return MediaQuery.platformBrightnessOf(context);
  }
}
