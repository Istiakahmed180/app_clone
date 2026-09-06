import 'package:flutter_test/flutter_test.dart';
import 'package:duplika/core/constants/app_constants.dart';
import 'package:duplika/core/errors/app_exception.dart';
import 'package:duplika/data/models/virtual_profile_model.dart';
import 'package:duplika/data/repositories/virtual_profile_repository.dart';

import 'fakes/in_memory_profile_storage.dart';

void main() {
  late InMemoryProfileStorage storage;
  late VirtualProfileRepository repository;

  setUp(() {
    storage = InMemoryProfileStorage();
    repository = VirtualProfileRepository(storage: storage);
  });

  Future<VirtualProfileModel> create(String name) => repository.createProfile(
        packageName: AppConstants.testAppPackage,
        appName: AppConstants.testAppFallbackName,
        profileName: name,
      );

  group('creation', () {
    test('creates a profile with a unique id and trimmed name', () async {
      final VirtualProfileModel profile = await create('  Profile 1  ');

      expect(profile.id, isNotEmpty);
      expect(profile.profileName, 'Profile 1');
      expect(profile.packageName, AppConstants.testAppPackage);
      expect(profile.enabled, isTrue);
    });

    test('rejects an empty name', () {
      expect(create('   '), throwsA(isA<ValidationException>()));
    });

    test('rejects a name over the length limit', () {
      expect(
        create('x' * (AppConstants.maxProfileNameLength + 1)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects a duplicate name without overwriting the existing profile',
        () async {
      final VirtualProfileModel first = await create('Profile 1');

      expect(create('profile 1'), throwsA(isA<ValidationException>()));

      final List<VirtualProfileModel> profiles = await repository.getProfiles();
      expect(profiles, hasLength(1));
      expect(profiles.single.id, first.id);
    });

    test('allows several profiles referencing the same package', () async {
      final VirtualProfileModel first = await create('Profile 1');
      final VirtualProfileModel second = await create('Profile 2');

      expect(first.packageName, second.packageName);
      expect(first.id, isNot(second.id));
      expect(await repository.getProfiles(), hasLength(2));
    });
  });

  group('retrieval', () {
    test('returns an empty list when nothing is stored', () async {
      expect(await repository.getProfiles(), isEmpty);
    });

    test('getProfile finds a stored profile and returns null otherwise', () async {
      final VirtualProfileModel profile = await create('Profile 1');

      expect((await repository.getProfile(profile.id))?.profileName, 'Profile 1');
      expect(await repository.getProfile('missing-id'), isNull);
    });

    test('throws StorageException for corrupted stored data', () async {
      storage.values[AppConstants.profilesStorageKey] = 'not json';

      expect(repository.getProfiles(), throwsA(isA<StorageException>()));
    });
  });

  group('rename', () {
    test('updates the name and keeps the id and creation time', () async {
      final VirtualProfileModel profile = await create('Profile 1');

      final VirtualProfileModel renamed =
          await repository.updateProfile(profile.id, profileName: 'Work');

      expect(renamed.id, profile.id);
      expect(renamed.createdAt, profile.createdAt);
      expect(renamed.profileName, 'Work');
    });

    test('rejects renaming to an existing name', () async {
      await create('Profile 1');
      final VirtualProfileModel second = await create('Profile 2');

      expect(
        repository.updateProfile(second.id, profileName: 'Profile 1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('allows renaming a profile to its own current name', () async {
      final VirtualProfileModel profile = await create('Profile 1');

      final VirtualProfileModel renamed =
          await repository.updateProfile(profile.id, profileName: 'Profile 1');

      expect(renamed.profileName, 'Profile 1');
    });

    test('rejects an empty new name', () async {
      final VirtualProfileModel profile = await create('Profile 1');

      expect(
        repository.updateProfile(profile.id, profileName: ''),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws when the profile does not exist', () {
      expect(
        repository.updateProfile('missing-id', profileName: 'Any'),
        throwsA(isA<ProfileNotFoundException>()),
      );
    });
  });

  group('delete', () {
    test('removes only the requested profile', () async {
      final VirtualProfileModel first = await create('Profile 1');
      final VirtualProfileModel second = await create('Profile 2');

      await repository.deleteProfile(second.id);

      final List<VirtualProfileModel> profiles = await repository.getProfiles();
      expect(profiles, hasLength(1));
      expect(profiles.single.id, first.id);
    });

    test('throws when the profile does not exist', () {
      expect(
        repository.deleteProfile('missing-id'),
        throwsA(isA<ProfileNotFoundException>()),
      );
    });
  });

  group('persistence', () {
    test('profiles survive a repository reload backed by the same storage',
        () async {
      await create('Profile 1');
      await create('Profile 2');

      final VirtualProfileRepository reloaded =
          VirtualProfileRepository(storage: storage);
      final List<VirtualProfileModel> profiles = await reloaded.getProfiles();

      expect(
        profiles.map((VirtualProfileModel p) => p.profileName),
        <String>['Profile 1', 'Profile 2'],
      );
    });

    test('a rename survives a repository reload', () async {
      final VirtualProfileModel profile = await create('Profile 1');
      await repository.updateProfile(profile.id, profileName: 'Renamed');

      final VirtualProfileRepository reloaded =
          VirtualProfileRepository(storage: storage);

      expect((await reloaded.getProfile(profile.id))?.profileName, 'Renamed');
    });

    test('a delete survives a repository reload', () async {
      final VirtualProfileModel profile = await create('Profile 1');
      await repository.deleteProfile(profile.id);

      final VirtualProfileRepository reloaded =
          VirtualProfileRepository(storage: storage);

      expect(await reloaded.getProfiles(), isEmpty);
    });
  });
}
