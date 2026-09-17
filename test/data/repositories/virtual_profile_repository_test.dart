import 'dart:convert';

import 'package:duplika/core/services/profile_storage.dart';
import 'package:duplika/data/models/clone_icon_color.dart';
import 'package:duplika/data/models/virtual_profile_model.dart';
import 'package:duplika/data/repositories/virtual_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// What happens when two changes to the stored clones are in flight at once.
///
/// Every write here is a read of the whole list, a change to one entry, and a write of
/// the whole list back — and each of those three steps is separated from the next by an
/// `await`. Two overlapping writes can therefore both read the same list and both write
/// their own version of it, and the second one undoes the first.
///
/// That is reachable from the app: deleting a clone tears down a container, which takes
/// seconds, and the grid stays interactive throughout — so a user can start a second
/// delete, or a rename, while the first is still running.
///
/// The storage below makes the interleaving happen on purpose rather than waiting for it
/// to happen by luck, so these tests either pass or fail rather than flaking.
void main() {
  late _SlowStorage storage;
  late VirtualProfileRepository repository;

  setUp(() {
    storage = _SlowStorage();
    repository = VirtualProfileRepository(storage: storage);
  });

  Future<List<VirtualProfileModel>> seed(int count) async {
    final List<VirtualProfileModel> made = <VirtualProfileModel>[];
    for (int i = 1; i <= count; i++) {
      made.add(
        await repository.createProfile(
          packageName: 'com.example.app$i',
          appName: 'App $i',
          profileName: 'App $i',
        ),
      );
    }
    return made;
  }

  test('two deletes at once remove both clones', () async {
    final List<VirtualProfileModel> made = await seed(3);

    // Started together and awaited together, which is what the grid does when a second
    // uninstall is confirmed while the first is still tearing its container down.
    await Future.wait(<Future<void>>[
      repository.deleteProfile(made[0].id),
      repository.deleteProfile(made[1].id),
    ]);

    final List<VirtualProfileModel> left = await repository.getProfiles();
    expect(
      left.map((VirtualProfileModel p) => p.id),
      <String>[made[2].id],
      reason: 'a delete that was overwritten puts a clone back on the grid whose '
          'container has already been destroyed',
    );
  });

  test('a delete and a rename at once keep both', () async {
    final List<VirtualProfileModel> made = await seed(2);

    await Future.wait(<Future<void>>[
      repository.deleteProfile(made[0].id),
      repository.updateProfile(made[1].id, profileName: 'Renamed'),
    ]);

    final List<VirtualProfileModel> left = await repository.getProfiles();
    expect(left.length, 1);
    expect(left.single.id, made[1].id);
    expect(left.single.profileName, 'Renamed');
  });

  test('a delete and a new clone at once keep the new one', () async {
    final List<VirtualProfileModel> made = await seed(1);

    final List<Object> results = await Future.wait(<Future<Object>>[
      repository.deleteProfile(made[0].id).then((_) => 'deleted'),
      repository.createProfile(
        packageName: 'com.example.new',
        appName: 'New',
        profileName: 'New',
      ),
    ]);

    final List<VirtualProfileModel> left = await repository.getProfiles();
    expect(results.first, 'deleted');
    expect(left.map((VirtualProfileModel p) => p.packageName), <String>['com.example.new']);
  });

  test('several changes to different clones at once all land', () async {
    final List<VirtualProfileModel> made = await seed(3);

    await Future.wait(<Future<void>>[
      repository.updateProfile(made[0].id, profileName: 'One'),
      repository.updateProfile(made[1].id, iconColor: CloneIconColor.blue),
      repository.setHidden(made[2].id, true),
    ]);

    final List<VirtualProfileModel> left = await repository.getProfiles();
    expect(left[0].profileName, 'One');
    expect(left[1].iconColor, CloneIconColor.blue);
    expect(left[2].hidden, isTrue);
  });

  test('a refused change does not block the ones behind it', () async {
    // The queue is shared, so a write that throws must not leave every later write
    // waiting on a future that never completes.
    final List<VirtualProfileModel> made = await seed(1);

    final Future<void> refused = repository.deleteProfile('no-such-profile');
    final Future<void> accepted = repository.deleteProfile(made[0].id);

    await expectLater(refused, throwsA(isA<Exception>()));
    await accepted;
    expect(await repository.getProfiles(), isEmpty);
  });

  test('deleting the same clone twice reports the second as missing', () async {
    final List<VirtualProfileModel> made = await seed(1);

    await repository.deleteProfile(made[0].id);

    await expectLater(
      repository.deleteProfile(made[0].id),
      throwsA(isA<Exception>()),
    );
  });
}

/// Key/value storage that yields to the event loop on every call.
///
/// A real `SharedPreferences` read and write are both asynchronous, so the app already
/// has these suspension points; this only makes them land in a fixed order instead of
/// whichever order the platform happened to produce on the day.
class _SlowStorage implements ProfileStorage {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async {
    await Future<void>.delayed(Duration.zero);
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    await Future<void>.delayed(Duration.zero);
    // Decoded and re-encoded so a test that stores nonsense fails here rather than three
    // steps later, on the read.
    jsonDecode(value);
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    await Future<void>.delayed(Duration.zero);
    _values.remove(key);
  }
}
