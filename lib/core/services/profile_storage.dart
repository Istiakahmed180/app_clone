import 'package:shared_preferences/shared_preferences.dart';

/// Key/value persistence used by [VirtualProfileRepository].
///
/// Extracted behind an interface so repository behaviour can be tested without a
/// platform channel or a connected device.
abstract class ProfileStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class SharedPreferencesProfileStorage implements ProfileStorage {
  const SharedPreferencesProfileStorage();

  @override
  Future<String?> read(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Future<void> delete(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
