import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// How [ThemeMode] is named to the user.
///
/// 'System default' rather than 'System': the Settings row shows this string as its
/// current value, and 'System' there reads like a place rather than a choice.
String appearanceLabel(AppLocalizations l10n, ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return l10n.appearanceSystem;
    case ThemeMode.light:
      return l10n.appearanceLight;
    case ThemeMode.dark:
      return l10n.appearanceDark;
  }
}

/// The line under the name on the Appearance screen — what the mode actually does.
String appearanceDescription(AppLocalizations l10n, ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return l10n.appearanceSystemSubtitle;
    case ThemeMode.light:
      return l10n.appearanceLightSubtitle;
    case ThemeMode.dark:
      return l10n.appearanceDarkSubtitle;
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
