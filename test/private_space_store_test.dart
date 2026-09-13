import 'package:duplika/core/services/pin_hasher.dart';
import 'package:duplika/core/services/private_space_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/in_memory_profile_storage.dart';

void main() {
  late InMemoryProfileStorage storage;
  late PrivateSpaceStore store;

  setUp(() {
    storage = InMemoryProfileStorage();
    // A low iteration count keeps the test fast; the derivation itself is pinned by
    // pin_hasher_test.
    store = PrivateSpaceStore(
      storage: storage,
      hasher: const PinHasher(iterations: 1000),
    );
  });

  test('a fresh install is off with no PIN', () async {
    final state = await store.load();

    expect(state.enabled, isFalse);
    expect(state.hasPin, isFalse);
    expect(state.biometricEnabled, isFalse);
  });

  test('a set PIN verifies and never appears in storage', () async {
    await store.setPin('1234');

    expect(await store.verifyPin('1234'), isTrue);
    expect(await store.verifyPin('0000'), isFalse);
    expect((await store.load()).hasPin, isTrue);
    expect(
      storage.values.values.any((String value) => value.contains('1234')),
      isFalse,
      reason: 'the PIN itself must never be written down',
    );
  });

  test('setting the same PIN twice stores a different hash', () async {
    await store.setPin('1234');
    final String first = storage.values[PrivateSpaceStore.hashKey]!;

    await store.setPin('1234');
    final String second = storage.values[PrivateSpaceStore.hashKey]!;

    expect(second, isNot(first), reason: 'the salt is regenerated each time');
    expect(await store.verifyPin('1234'), isTrue);
  });

  test('rejects a PIN outside the 4 to 6 digit range', () async {
    expect(store.setPin('123'), throwsArgumentError);
    expect(store.setPin('1234567'), throwsArgumentError);
    expect(store.setPin('12a4'), throwsArgumentError);
  });

  test('enabled and biometric flags round-trip', () async {
    await store.setPin('1234');
    await store.setEnabled(true);
    await store.setBiometricEnabled(true);

    final state = await store.load();
    expect(state.enabled, isTrue);
    expect(state.biometricEnabled, isTrue);
  });

  test('disable forgets the PIN, the biometric and the lock', () async {
    await store.setPin('1234');
    await store.setEnabled(true);
    await store.setBiometricEnabled(true);

    await store.disable();

    final state = await store.load();
    expect(state.enabled, isFalse);
    expect(state.hasPin, isFalse);
    expect(state.biometricEnabled, isFalse);
    expect(await store.verifyPin('1234'), isFalse);
  });

  test('verify answers false when no PIN was ever set', () async {
    expect(await store.verifyPin('1234'), isFalse);
  });
}
