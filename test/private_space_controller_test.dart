import 'package:duplika/core/services/biometric_authenticator.dart';
import 'package:duplika/core/services/pin_hasher.dart';
import 'package:duplika/core/services/private_space_store.dart';
import 'package:duplika/data/models/virtual_profile_model.dart';
import 'package:duplika/data/repositories/virtual_profile_repository.dart';
import 'package:duplika/features/private_space/controllers/private_space_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/in_memory_profile_storage.dart';

/// Answers from fields instead of a platform channel.
class _FakeBiometric extends BiometricAuthenticator {
  bool available = true;
  BiometricResult result = BiometricResult.success;
  int calls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BiometricResult> authenticate({required String reason}) async {
    calls++;
    return result;
  }
}

void main() {
  late InMemoryProfileStorage storage;
  late VirtualProfileRepository repository;
  late _FakeBiometric biometric;
  late PrivateSpaceController controller;

  setUp(() {
    storage = InMemoryProfileStorage();
    repository = VirtualProfileRepository(storage: storage);
    biometric = _FakeBiometric();
    controller = PrivateSpaceController(
      repository: repository,
      store: PrivateSpaceStore(
        storage: storage,
        hasher: const PinHasher(iterations: 1000),
      ),
      biometric: biometric,
    );
  });

  Future<VirtualProfileModel> seed() => repository.createProfile(
        packageName: 'com.example.app',
        appName: 'Example',
        profileName: 'Example',
      );

  group('create', () {
    test('turns the lock on, records the biometric and unlocks the session', () async {
      await controller.create('1234', useBiometric: true);

      expect(controller.enabled, isTrue);
      expect(controller.hasPin, isTrue);
      expect(controller.biometricEnabled, isTrue);
      expect(controller.unlocked.value, isTrue);
    });

    test('does not record a biometric the device cannot show', () async {
      biometric.available = false;

      await controller.create('1234', useBiometric: true);

      expect(controller.biometricEnabled, isFalse);
    });

    test('leaves the biometric off when it was not asked for', () async {
      await controller.create('1234');

      expect(controller.biometricEnabled, isFalse);
    });
  });

  group('unlock', () {
    setUp(() async {
      await controller.create('1234');
      controller.lock();
    });

    test('a correct PIN unlocks and a wrong one does not', () async {
      expect(await controller.unlockWithPin('0000'), isFalse);
      expect(controller.unlocked.value, isFalse);

      expect(await controller.unlockWithPin('1234'), isTrue);
      expect(controller.unlocked.value, isTrue);
    });

    test('a successful biometric unlocks', () async {
      final BiometricResult result = await controller.unlockWithBiometric();

      expect(result, BiometricResult.success);
      expect(controller.unlocked.value, isTrue);
      expect(biometric.calls, 1);
    });

    test('a cancelled biometric leaves it locked', () async {
      biometric.result = BiometricResult.cancelled;

      await controller.unlockWithBiometric();

      expect(controller.unlocked.value, isFalse);
    });
  });

  group('change pin', () {
    test('rejects a wrong current PIN and accepts the right one', () async {
      await controller.create('1234');
      controller.lock();

      expect(
        await controller.changePin(currentPin: '9999', newPin: '5678'),
        isFalse,
      );
      expect(await controller.unlockWithPin('1234'), isTrue);
    });

    test('replaces the PIN on success', () async {
      await controller.create('1234');
      controller.lock();

      expect(
        await controller.changePin(currentPin: '1234', newPin: '5678'),
        isTrue,
      );
      expect(await controller.unlockWithPin('1234'), isFalse);
      expect(await controller.unlockWithPin('5678'), isTrue);
    });
  });

  group('hidden clones', () {
    test('setHidden writes the flag and bumps the revision', () async {
      await controller.create('1234');
      final VirtualProfileModel profile = await seed();
      final int before = controller.revision.value;

      await controller.setHidden(profile.id, true);

      expect((await repository.getProfile(profile.id))!.hidden, isTrue);
      expect(controller.revision.value, before + 1);
    });

    test('disable unhides everything and turns the lock off', () async {
      await controller.create('1234');
      final VirtualProfileModel profile = await seed();
      await controller.setHidden(profile.id, true);
      final int before = controller.revision.value;

      await controller.disable();

      expect(controller.enabled, isFalse);
      expect((await repository.getProfile(profile.id))!.hidden, isFalse);
      expect(controller.revision.value, before + 1);
    });
  });
}
