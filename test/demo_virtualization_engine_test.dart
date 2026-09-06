import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duplika/core/constants/app_constants.dart';
import 'package:duplika/core/errors/app_exception.dart';
import 'package:duplika/core/virtualization/demo_virtualization_engine.dart';
import 'package:duplika/data/models/virtual_profile_model.dart';
import 'package:duplika/data/repositories/virtual_profile_repository.dart';
import 'package:duplika/native/native_bridge.dart';

import 'fakes/in_memory_profile_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(NativeBridge.channelName);
  late InMemoryProfileStorage storage;
  late DemoVirtualizationEngine engine;
  late List<String> nativeCalls;

  setUp(() {
    storage = InMemoryProfileStorage();
    nativeCalls = <String>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      nativeCalls.add(call.method);
      return <Object?, Object?>{'success': true};
    });

    engine = DemoVirtualizationEngine(
      repository: VirtualProfileRepository(storage: storage),
      nativeBridge: NativeBridge(channel: channel),
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<VirtualProfileModel> create(String name) => engine.createProfile(
        packageName: AppConstants.testAppPackage,
        appName: AppConstants.testAppFallbackName,
        profileName: name,
      );

  test('reports honestly that it does not isolate runtime state', () {
    expect(engine.providesRuntimeIsolation, isFalse);
  });

  test('launching a profile starts the real, unvirtualized package', () async {
    final VirtualProfileModel profile = await create('Profile 1');

    await engine.launchProfile(profile.id);

    expect(nativeCalls, <String>['launchTestApp']);
  });

  test('launching an unknown profile throws before touching the platform', () async {
    expect(
      engine.launchProfile('missing-id'),
      throwsA(isA<ProfileNotFoundException>()),
    );
    expect(nativeCalls, isEmpty);
  });

  test('refuses to launch a profile pointing at an unsupported package', () async {
    final VirtualProfileModel profile = await engine.createProfile(
      packageName: 'com.example.some.other.app',
      appName: 'Other App',
      profileName: 'Profile 1',
    );

    expect(
      engine.launchProfile(profile.id),
      throwsA(isA<LaunchException>()
          .having((LaunchException e) => e.code, 'code', 'UNSUPPORTED_PACKAGE')),
    );
    expect(nativeCalls, isEmpty);
  });

  test('deleting a profile removes metadata only, never the package', () async {
    final VirtualProfileModel profile = await create('Profile 1');

    await engine.deleteProfile(profile.id);

    expect(await engine.getProfiles(), isEmpty);
    expect(nativeCalls, isEmpty);
  });

  test('renaming delegates to the repository', () async {
    final VirtualProfileModel profile = await create('Profile 1');

    await engine.renameProfile(profile.id, 'Renamed');

    expect((await engine.getProfiles()).single.profileName, 'Renamed');
  });
}
