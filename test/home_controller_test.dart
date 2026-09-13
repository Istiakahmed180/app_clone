import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duplika/core/constants/app_constants.dart';
import 'package:duplika/core/virtualization/real_virtualization_engine.dart';
import 'package:duplika/data/models/virtual_profile_model.dart';
import 'package:duplika/data/repositories/virtual_profile_repository.dart';
import 'package:duplika/features/home/controllers/home_controller.dart';
import 'package:duplika/native/native_bridge.dart';

import 'fakes/in_memory_profile_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(NativeBridge.channelName);
  late VirtualProfileRepository repository;
  late HomeController controller;
  late Map<String, Map<Object?, Object?>> responses;

  Map<Object?, Object?> ok(String code, Map<String, Object?> data) => <Object?, Object?>{
        'success': true,
        'code': code,
        'message': 'ok',
        'data': data,
      };

  Map<String, Object?> reportWith(List<Map<String, Object?>> findings) => <String, Object?>{
        'packageName': AppConstants.testAppPackage,
        'verdict': findings.isEmpty ? 'SUPPORTED' : 'UNSUPPORTED',
        'findings': findings,
        'bridgeablePermissions': <Object?>[],
        'missingPermissions': <Object?>[],
        'requiresGms': false,
      };

  setUp(() {
    repository = VirtualProfileRepository(storage: InMemoryProfileStorage());
    responses = <String, Map<Object?, Object?>>{
      'isVirtualizationAvailable': <Object?, Object?>{'available': true, 'backend': 'test'},
      'getTestAppInfo': <Object?, Object?>{'installed': false, 'packageName': 'x'},
      'getPlatformInfo': <Object?, Object?>{},
      'installAppToProfile': ok('APP_INSTALLED', <String, Object?>{}),
      'isAppInstalledInProfile': ok('PROFILE_STATE', <String, Object?>{
        'installed': true,
        'running': false,
        'virtualUserId': 0,
      }),
      'getAppIcons': ok('ICONS_LOADED', <String, Object?>{'icons': <Object?, Object?>{}}),
    };

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async => responses[call.method]);

    final NativeBridge bridge = NativeBridge(channel: channel);
    controller = HomeController(
      engine: RealVirtualizationEngine(repository: repository, nativeBridge: bridge),
      nativeBridge: bridge,
      repository: repository,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<VirtualProfileModel> seedClone() => repository.createProfile(
        packageName: AppConstants.testAppPackage,
        appName: 'Virtual Test App',
        profileName: 'Clone',
      );

  test('the grid groups an app\'s clones together, numbered, apps A-Z', () async {
    // The repository hands back creation order, which scatters an app's clones across
    // the grid — Facebook 1, WhatsApp 1, Facebook 2 — and makes the instance numbers
    // unreadable.
    Future<void> clone(String app, String package) => repository.createProfile(
          packageName: package,
          appName: app,
          profileName: app,
        );

    await clone('WhatsApp', 'com.whatsapp');
    await clone('Facebook', 'com.facebook.katana');
    await clone('WhatsApp', 'com.whatsapp');
    await clone('Instagram', 'com.instagram.android');
    await clone('Facebook', 'com.facebook.katana');
    await clone('Instagram', 'com.instagram.android');

    await controller.refreshAll();

    expect(
      controller.profiles.map(
        (VirtualProfileModel p) =>
            '${p.appName} ${controller.instanceIndex(p)}',
      ),
      <String>[
        'Facebook 1',
        'Facebook 2',
        'Instagram 1',
        'Instagram 2',
        'WhatsApp 1',
        'WhatsApp 2',
      ],
    );
  });

  test('two different apps sharing a name keep their own clones contiguous', () async {
    // A device can genuinely have two apps called "Notes".
    await repository.createProfile(
      packageName: 'com.oneplus.note',
      appName: 'Notes',
      profileName: 'Notes',
    );
    await repository.createProfile(
      packageName: 'org.fossify.notes',
      appName: 'Notes',
      profileName: 'Notes',
    );
    await repository.createProfile(
      packageName: 'com.oneplus.note',
      appName: 'Notes',
      profileName: 'Notes',
    );

    await controller.refreshAll();

    expect(
      controller.profiles.map((VirtualProfileModel p) => p.packageName),
      <String>['com.oneplus.note', 'com.oneplus.note', 'org.fossify.notes'],
    );
  });

  test('renaming a clone does not move it away from its siblings', () async {
    // Grouping is by app, not by the label the user typed.
    await repository.createProfile(
      packageName: 'com.whatsapp',
      appName: 'WhatsApp',
      profileName: 'WhatsApp',
    );
    final VirtualProfileModel second = await repository.createProfile(
      packageName: 'com.whatsapp',
      appName: 'WhatsApp',
      profileName: 'WhatsApp',
    );
    await repository.createProfile(
      packageName: 'com.facebook.katana',
      appName: 'Facebook',
      profileName: 'Facebook',
    );

    await repository.updateProfile(second.id, profileName: 'Aaa work account');
    await controller.refreshAll();

    expect(
      controller.profiles.map((VirtualProfileModel p) => p.appName),
      <String>['Facebook', 'WhatsApp', 'WhatsApp'],
    );
  });

  group('shortcut labels', () {
    Future<VirtualProfileModel> clone(String app, String package) =>
        repository.createProfile(
          packageName: package,
          appName: app,
          profileName: app,
        );

    test('a lone clone is called after its app, with no number', () async {
      await clone('Camera', 'com.android.camera2');
      await controller.refreshAll();

      expect(controller.shortcutLabel(controller.profiles.single), 'Camera');
    });

    test('several clones of one app are numbered by space', () async {
      // Otherwise every shortcut is called "Camera" and the launcher appends "-1", "-2"
      // itself, which says nothing about which clone is which.
      await clone('Camera', 'com.android.camera2');
      await clone('Camera', 'com.android.camera2');
      await clone('Camera', 'com.android.camera2');
      await controller.refreshAll();

      expect(
        controller.profiles.map(controller.shortcutLabel),
        <String>['Camera 1', 'Camera 2', 'Camera 3'],
      );
    });

    test('a renamed clone keeps the name the user chose', () async {
      await clone('Camera', 'com.android.camera2');
      final VirtualProfileModel second = await clone('Camera', 'com.android.camera2');
      await repository.updateProfile(second.id, profileName: 'Work camera');
      await controller.refreshAll();

      final VirtualProfileModel renamed = controller.profiles
          .firstWhere((VirtualProfileModel p) => p.id == second.id);
      expect(controller.shortcutLabel(renamed), 'Work camera');
    });
  });

  test('a real problem is surfaced on the clone', () async {
    final VirtualProfileModel profile = await seedClone();
    responses['analyzeApp'] = ok('APP_ANALYZED', reportWith(<Map<String, Object?>>[
      <String, Object?>{
        'code': AppConstants.errorSecureEnvRequired,
        'message': 'This application requires a secure environment.',
        'blocking': true,
      },
    ]));

    await controller.refreshAll();

    expect(controller.warningsFor(profile), hasLength(1));
    expect(controller.warningsFor(profile).single.blocking, isTrue);
  });

  test('a clone of an app that is not installed on the host is not flagged', () async {
    // This is the normal state for a clone created from an imported APK: the container
    // exists and works, the package simply is not installed here. Reporting that as a
    // problem would be a false alarm about the import feature itself.
    final VirtualProfileModel profile = await seedClone();
    responses['analyzeApp'] = ok('APP_ANALYZED', reportWith(<Map<String, Object?>>[
      <String, Object?>{
        'code': AppConstants.errorAppNotFound,
        'message': 'This application is not installed on the device.',
        'blocking': true,
      },
    ]));

    await controller.refreshAll();

    expect(controller.warningsFor(profile), isEmpty);
  });

  test('a healthy app produces no warnings', () async {
    final VirtualProfileModel profile = await seedClone();
    responses['analyzeApp'] = ok('APP_ANALYZED', reportWith(<Map<String, Object?>>[]));

    await controller.refreshAll();

    expect(controller.warningsFor(profile), isEmpty);
  });

  test('an analysis that could not run produces no warnings', () async {
    final VirtualProfileModel profile = await seedClone();
    responses['analyzeApp'] = <Object?, Object?>{
      'success': false,
      'code': 'BRIDGE_ERROR',
      'message': 'failed',
      'data': <Object?, Object?>{},
    };

    await controller.refreshAll();

    expect(controller.compatibility[profile.packageName]?.analysed, isFalse);
    expect(controller.warningsFor(profile), isEmpty);
  });

  // The clone space check. Sizes are chosen against the controller's own 512 MB
  // headroom: `usable = free - 512 MB`, and a clone is estimated at its APK size.
  const int mb = 1024 * 1024;

  void withSpace({required int freeMb, required int appMb}) {
    responses['getStorageStatus'] = <Object?, Object?>{
      'freeBytes': freeMb * mb,
      'totalBytes': 64 * 1024 * mb,
    };
    responses['getAppDetails'] = ok('APP_DETAILS', <String, Object?>{
      'packageName': AppConstants.testAppPackage,
      'appName': 'Virtual Test App',
      'apkCount': 1,
      'totalSizeBytes': appMb * mb,
      'abis': <Object?>[],
      'components': <Object?>[],
    });
  }

  test('a batch that cannot fit is refused before anything is created', () async {
    final VirtualProfileModel profile = await seedClone();
    // 250 MB usable, 100 MB each: two fit, five were asked for.
    withSpace(freeMb: 512 + 250, appMb: 100);
    await controller.refreshAll();

    final String? error = await controller.createClones(profile, 5);

    expect(error, contains('Not enough space for 5 more'));
    expect(error, contains('room for 2'));
    // Refused up front: the one seeded clone is still the only one.
    expect(await repository.getProfiles(), hasLength(1));
  });

  test('the refusal names the app when not even one more fits', () async {
    final VirtualProfileModel profile = await seedClone();
    // 10 MB usable against a 100 MB app: nothing fits.
    withSpace(freeMb: 512 + 10, appMb: 100);
    await controller.refreshAll();

    final String? error = await controller.createClones(profile, 3);

    expect(error, contains('another Virtual Test App clone'));
    expect(await repository.getProfiles(), hasLength(1));
  });

  test('a batch that fits is created', () async {
    final VirtualProfileModel profile = await seedClone();
    // 400 MB usable, 100 MB each: four fit, two were asked for.
    withSpace(freeMb: 512 + 400, appMb: 100);
    await controller.refreshAll();

    final String? error = await controller.createClones(profile, 2);

    expect(error, isNull);
    expect(await repository.getProfiles(), hasLength(3));
  });

  test('clones are still created when the space check cannot run', () async {
    // `getStorageStatus` is absent from `responses`, so the bridge throws. A failed
    // diagnostic must not stand between the user and a clone that would have worked.
    final VirtualProfileModel profile = await seedClone();
    await controller.refreshAll();

    final String? error = await controller.createClones(profile, 2);

    expect(error, isNull);
    expect(await repository.getProfiles(), hasLength(3));
  });

  test('an app whose size is unknown is not refused', () async {
    final VirtualProfileModel profile = await seedClone();
    // Plenty free, but a zero size is "could not read", not "costs nothing".
    withSpace(freeMb: 512 + 400, appMb: 0);
    await controller.refreshAll();

    final String? error = await controller.createClones(profile, 2);

    expect(error, isNull);
    expect(await repository.getProfiles(), hasLength(3));
  });
}
