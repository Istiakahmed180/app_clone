import 'package:flutter/material.dart' show ThemeMode;

import 'profile_storage.dart';

/// The app-level preferences the user sets for themselves.
///
/// Backed by the same [ProfileStorage] seam as profiles and onboarding, so preference
/// behaviour is testable without SharedPreferences or a device.
class SettingsStore {
  const SettingsStore({ProfileStorage? storage})
      : _storage = storage ?? const SharedPreferencesProfileStorage();

  static const String themeModeKey = 'duplika.settings.theme_mode';

  final ProfileStorage _storage;

  /// The stored appearance choice, defaulting to following the system.
  ///
  /// An unrecognised stored value also means "follow the system": a preference file
  /// written by a build that named the modes differently should land the user on the
  /// default rather than on whichever mode a parse failure happens to produce.
  Future<ThemeMode> themeMode() async {
    switch (await _storage.read(themeModeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case _:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _storage.write(themeModeKey, mode.name);
}
