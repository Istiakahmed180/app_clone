import 'package:virtual_space_demo/core/services/profile_storage.dart';

/// Storage fake that keeps values in a map, so repository behaviour (including
/// reload-from-storage) can be tested without a platform channel.
class InMemoryProfileStorage implements ProfileStorage {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
