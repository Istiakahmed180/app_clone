import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_space_demo/core/constants/app_constants.dart';
import 'package:virtual_space_demo/core/errors/app_exception.dart';
import 'package:virtual_space_demo/core/virtualization/real_virtualization_engine.dart';
import 'package:virtual_space_demo/data/models/engine_result.dart';
import 'package:virtual_space_demo/data/models/virtual_profile_model.dart';
import 'package:virtual_space_demo/data/repositories/virtual_profile_repository.dart';
import 'package:virtual_space_demo/native/native_bridge.dart';

import 'fakes/in_memory_profile_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(NativeBridge.channelName);
  late InMemoryProfileStorage storage;
  late VirtualProfileRepository repository;
  late RealVirtualizationEngine engine;
  late List<String> calls;
  late Map<String, Object?> lastArgs;
  late Map<String, Map<Object?, Object?>> responses;

  Map<Object?, Object?> ok(String code, [Map<String, Object?> data = const <String, Object?>{}]) =>
      <Object?, Object?>{'success': true, 'code': code, 'message': 'ok', 'data': data};

  Map<Object?, Object?> fail(String code, String message) =>
      <Object?, Object?>{'success': false, 'code': code, 'message': message, 'data': <Object?, Object?>{}};

  setUp(() {
    storage = InMemoryProfileStorage();
    repository = VirtualProfileRepository(storage: storage);
    calls = <String>[];
    lastArgs = <String, Object?>{};
    responses = <String, Map<Object?, Object?>>{
      'installAppToProfile': ok('APP_INSTALLED'),
      'launchProfile': ok('PROFILE_LAUNCHED'),
      'deleteProfile': ok('PROFILE_DELETED'),
      'stopProfile': ok('PROFILE_STOPPED'),
      'initializeVirtualization': ok('ENGINE_READY'),
      'isAppInstalledInProfile': ok('PROFILE_STATE', <String, Object?>{
        'installed': true,
        'running': false,
        'virtualUserId': 0,
      }),
    };

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call.method);
      lastArgs[call.method] = call.arguments;
      return responses[call.method];
    });

    engine = RealVirtualizationEngine(
      repository: repository,
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

  test('claims runtime isolation', () {
    expect(engine.providesRuntimeIsolation, isTrue);
  });

  test('creating a profile installs it into the engine', () async {
    final VirtualProfileModel profile = await create('Profile 1');

    expect(calls, contains('installAppToProfile'));
    expect(await repository.getProfile(profile.id), isNotNull);
  });

  test('GMS provisioning is off by default in the install call', () async {
    await create('Profile 1');

    final Map<Object?, Object?> args =
        lastArgs['installAppToProfile']! as Map<Object?, Object?>;
    expect(args['installGms'], isFalse);
  });

  test('opting in forwards installGms to the engine', () async {
    await engine.createProfile(
      packageName: AppConstants.testAppPackage,
      appName: AppConstants.testAppFallbackName,
      profileName: 'Profile 1',
      installGms: true,
    );

    final Map<Object?, Object?> args =
        lastArgs['installAppToProfile']! as Map<Object?, Object?>;
    expect(args['installGms'], isTrue);
  });

  test('a failed install rolls the profile metadata back', () async {
    responses['installAppToProfile'] =
        fail('APP_INSTALL_FAILED', 'Engine refused the install.');

    await expectLater(
      create('Profile 1'),
      throwsA(isA<VirtualizationException>()
          .having((VirtualizationException e) => e.code, 'code', 'APP_INSTALL_FAILED')),
    );

    // The host must not keep a profile the engine never provisioned.
    expect(await repository.getProfiles(), isEmpty);
  });

  test('a rejected secure-environment app surfaces its code and stores nothing', () async {
    responses['installAppToProfile'] = fail(
      AppConstants.errorSecureEnvRequired,
      'This application requires a secure environment.',
    );

    await expectLater(
      create('Profile 1'),
      throwsA(isA<VirtualizationException>().having(
        (VirtualizationException e) => e.code,
        'code',
        AppConstants.errorSecureEnvRequired,
      )),
    );
    expect(await repository.getProfiles(), isEmpty);
  });

  test('launching a profile goes through the engine, not the platform launcher', () async {
    final VirtualProfileModel profile = await create('Profile 1');
    calls.clear();

    await engine.launchProfile(profile.id);

    expect(calls, contains('launchProfile'));
    expect(calls, isNot(contains('launchTestApp')));
  });

  test('a failed launch reports the engine code', () async {
    final VirtualProfileModel profile = await create('Profile 1');
    responses['launchProfile'] =
        fail('VIRTUAL_APP_LAUNCH_FAILED', 'Engine refused to launch.');

    expect(
      engine.launchProfile(profile.id),
      throwsA(isA<VirtualizationException>().having(
        (VirtualizationException e) => e.code,
        'code',
        'VIRTUAL_APP_LAUNCH_FAILED',
      )),
    );
  });

  test('launching an unknown profile never reaches the engine', () async {
    calls.clear();
    await expectLater(
      engine.launchProfile('missing-id'),
      throwsA(isA<ProfileNotFoundException>()),
    );
    expect(calls, isEmpty);
  });

  test('renaming touches metadata only', () async {
    final VirtualProfileModel profile = await create('Profile 1');
    calls.clear();

    await engine.renameProfile(profile.id, 'Personal');

    expect(calls, isEmpty);
    expect((await repository.getProfile(profile.id))?.profileName, 'Personal');
  });

  test('deleting removes the container before the metadata', () async {
    final VirtualProfileModel profile = await create('Profile 1');
    calls.clear();

    await engine.deleteProfile(profile.id);

    expect(calls, contains('deleteProfile'));
    expect(await repository.getProfiles(), isEmpty);
  });

  test('a failed container delete keeps the profile visible for retry', () async {
    final VirtualProfileModel profile = await create('Profile 1');
    responses['deleteProfile'] =
        fail('PROFILE_DELETE_FAILED', 'Engine could not release the container.');

    await expectLater(
      engine.deleteProfile(profile.id),
      throwsA(isA<VirtualizationException>()),
    );
    expect(await repository.getProfile(profile.id), isNotNull);
  });

  test('profileState reflects what the engine reports', () async {
    final VirtualProfileModel profile = await create('Profile 1');

    final VirtualProfileState state = await engine.profileState(profile.id);

    expect(state.installed, isTrue);
    expect(state.virtualUserId, 0);
  });

  group('multi-app and APK import', () {
    test('creating a profile from an APK installs it and keeps the metadata', () async {
      responses['installApkToProfile'] = ok('APP_INSTALLED');

      final VirtualProfileModel profile = await engine.createProfileFromApk(
        apkPath: '/tmp/example.apk',
        packageName: 'org.example.imported',
        appName: 'Imported App',
        profileName: 'Imported App',
      );

      expect(calls, contains('installApkToProfile'));
      expect((await repository.getProfile(profile.id))?.packageName, 'org.example.imported');
      expect(
        (lastArgs['installApkToProfile']! as Map<Object?, Object?>)['installGms'],
        isFalse,
        reason: 'APK import must also default GMS provisioning off',
      );
    });

    test('opting in forwards installGms on the APK path too', () async {
      responses['installApkToProfile'] = ok('APP_INSTALLED');

      await engine.createProfileFromApk(
        apkPath: '/tmp/example.apk',
        packageName: 'org.example.imported',
        appName: 'Imported App',
        profileName: 'Imported App',
        installGms: true,
      );

      expect(
        (lastArgs['installApkToProfile']! as Map<Object?, Object?>)['installGms'],
        isTrue,
      );
    });

    test('a failed APK install rolls the profile back', () async {
      responses['installApkToProfile'] = fail('APK_INVALID', 'Not a valid APK.');

      await expectLater(
        engine.createProfileFromApk(
          apkPath: '/tmp/bad.apk',
          packageName: 'org.example.imported',
          appName: 'Imported App',
          profileName: 'Imported App',
        ),
        throwsA(isA<VirtualizationException>()
            .having((VirtualizationException e) => e.code, 'code', 'APK_INVALID')),
      );
      expect(await repository.getProfiles(), isEmpty);
    });

    test('profiles for different packages coexist', () async {
      await create('Test App');
      responses['installApkToProfile'] = ok('APP_INSTALLED');
      await engine.createProfileFromApk(
        apkPath: '/tmp/example.apk',
        packageName: 'org.example.imported',
        appName: 'Imported App',
        profileName: 'Imported App',
      );

      final List<VirtualProfileModel> profiles = await repository.getProfiles();
      expect(profiles.map((VirtualProfileModel p) => p.packageName).toSet(), <String>{
        AppConstants.testAppPackage,
        'org.example.imported',
      });
    });
  });

  group('multi-instance naming', () {
    test('suggests an unnumbered name for the first clone', () async {
      expect(
        await repository.suggestProfileName(
          appName: 'Telegram',
          packageName: 'org.telegram.messenger',
        ),
        'Telegram',
      );
    });

    test('numbers subsequent clones of the same app', () async {
      await repository.createProfile(
        packageName: 'org.telegram.messenger',
        appName: 'Telegram',
        profileName: 'Telegram',
      );

      expect(
        await repository.suggestProfileName(
          appName: 'Telegram',
          packageName: 'org.telegram.messenger',
        ),
        'Telegram 2',
      );
    });

    test('skips names already taken by a different app', () async {
      await repository.createProfile(
        packageName: 'org.telegram.messenger',
        appName: 'Telegram',
        profileName: 'Telegram',
      );
      await repository.createProfile(
        packageName: 'org.other.app',
        appName: 'Other',
        profileName: 'Telegram 2',
      );

      expect(
        await repository.suggestProfileName(
          appName: 'Telegram',
          packageName: 'org.telegram.messenger',
        ),
        'Telegram 3',
      );
    });

    test('counts instances per package', () async {
      await create('Clone A');
      await create('Clone B');
      await repository.createProfile(
        packageName: 'org.other.app',
        appName: 'Other',
        profileName: 'Other',
      );

      expect(await repository.instanceCountFor(AppConstants.testAppPackage), 2);
      expect(await repository.instanceCountFor('org.other.app'), 1);
      expect(await repository.instanceCountFor('org.nothing'), 0);
    });

    test('several clones of one package get distinct ids', () async {
      final VirtualProfileModel first = await create('Clone A');
      final VirtualProfileModel second = await create('Clone B');

      expect(first.packageName, second.packageName);
      expect(first.id, isNot(second.id));
    });
  });

  test('initialize surfaces an unavailable engine', () async {
    responses['initializeVirtualization'] =
        fail('VIRTUALIZATION_NOT_AVAILABLE', 'Engine unavailable.');

    expect(
      engine.initialize(),
      throwsA(isA<VirtualizationException>().having(
        (VirtualizationException e) => e.code,
        'code',
        'VIRTUALIZATION_NOT_AVAILABLE',
      )),
    );
  });
}
