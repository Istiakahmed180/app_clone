import 'dart:convert';
import 'dart:isolate';

import '../../data/models/private_space_state.dart';
import 'pin_hasher.dart';
import 'profile_storage.dart';

/// Persistence for the Private space lock.
///
/// Secrets live here and nowhere else. The hash and its salt are never returned to a
/// caller: [verifyPin] takes a candidate and answers yes or no, so no screen and no
/// controller ever holds a value that could be replayed.
///
/// Backed by the same [ProfileStorage] seam as profiles and settings, so it is testable
/// without SharedPreferences or a device. A four-digit PIN over SharedPreferences is not
/// a secure enclave, but the derived key plus a random salt is the strongest thing a
/// normal Android app can store without a keystore dependency, and it keeps a plaintext
/// PIN out of the filesystem.
class PrivateSpaceStore {
  const PrivateSpaceStore({ProfileStorage? storage, PinHasher? hasher})
      : _storage = storage ?? const SharedPreferencesProfileStorage(),
        _hasher = hasher ?? const PinHasher();

  static const String enabledKey = 'duplika.private_space.enabled';
  static const String saltKey = 'duplika.private_space.pin_salt';
  static const String hashKey = 'duplika.private_space.pin_hash';
  static const String iterationsKey = 'duplika.private_space.pin_iterations';
  static const String biometricKey = 'duplika.private_space.biometric';

  static const int minPinLength = 4;
  static const int maxPinLength = 6;

  final ProfileStorage _storage;
  final PinHasher _hasher;

  static bool isValidPin(String pin) =>
      RegExp('^[0-9]{$minPinLength,$maxPinLength}\$').hasMatch(pin);

  Future<PrivateSpaceState> load() async {
    final String? enabled = await _storage.read(enabledKey);
    final String? hash = await _storage.read(hashKey);
    final String? biometric = await _storage.read(biometricKey);
    return PrivateSpaceState(
      enabled: enabled == 'true',
      hasPin: hash != null && hash.isNotEmpty,
      biometricEnabled: biometric == 'true',
    );
  }

  Future<void> setEnabled(bool enabled) =>
      _storage.write(enabledKey, enabled ? 'true' : 'false');

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(biometricKey, enabled ? 'true' : 'false');

  /// Replaces the PIN. The salt is regenerated every time, so setting the same PIN
  /// twice still produces a different stored hash.
  Future<void> setPin(String pin) async {
    if (!isValidPin(pin)) {
      throw ArgumentError.value(
        pin,
        'pin',
        'PIN must be $minPinLength to $maxPinLength digits.',
      );
    }
    final PinHasher hasher = _hasher;
    final List<int> salt = hasher.generateSalt();
    final String hash = await Isolate.run(
      () => hasher.deriveHex(pin, salt),
    );
    await _storage.write(saltKey, base64Encode(salt));
    await _storage.write(hashKey, hash);
    await _storage.write(iterationsKey, '${hasher.iterations}');
  }

  /// True when [pin] matches. False when no PIN is set, which is also how a disabled
  /// space answers.
  Future<bool> verifyPin(String pin) async {
    final String? salt = await _storage.read(saltKey);
    final String? hash = await _storage.read(hashKey);
    if (salt == null || hash == null || hash.isEmpty) {
      return false;
    }
    final List<int>? saltBytes = _decode(salt);
    if (saltBytes == null) {
      return false;
    }
    final int iterations =
        int.tryParse(await _storage.read(iterationsKey) ?? '') ??
            _hasher.iterations;

    final PinHasher hasher = _hasher;
    return Isolate.run(
      () => hasher.verify(
        pin,
        salt: saltBytes,
        hashHex: hash,
        iterations: iterations,
      ),
    );
  }

  Future<void> clearPin() async {
    await _storage.delete(saltKey);
    await _storage.delete(hashKey);
    await _storage.delete(iterationsKey);
  }

  /// Forgets the lock entirely. Callers are responsible for unhiding the clones.
  Future<void> disable() async {
    await clearPin();
    await setBiometricEnabled(false);
    await setEnabled(false);
  }

  static List<int>? _decode(String value) {
    try {
      return base64Decode(value);
    } on FormatException {
      return null;
    }
  }
}
