import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duplika/core/constants/app_constants.dart';
import 'package:duplika/core/virtualization/real_virtualization_engine.dart';
import 'package:duplika/data/models/clone_budget.dart';
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

  // The clone budget. Figures are chosen against the controller's own constants:
  // 512 MB of storage headroom, ~64 KB per clone, and an absolute ceiling of 20.
  const int mb = 1024 * 1024;

  void withCapacity({
    required int freeMb,
    int? totalMemGb = 8,
    bool lowRam = false,
  }) {
    responses['getDeviceCapacity'] = <Object?, Object?>{
      'freeBytes': freeMb * mb,
      'totalBytes': 64 * 1024 * mb,
      'totalMemBytes': totalMemGb == null ? null : totalMemGb * 1024 * mb,
      'isLowRamDevice': lowRam,
    };
  }

  group('clone budget', () {
    test('a roomy device is offered the full range', () async {
      withCapacity(freeMb: 8192);

      final CloneBudget budget = await controller.cloneBudget();

      expect(budget.maximum, 20);
      expect(budget.reason, 'Choose from 1 to 20');
    });

    test('a device inside its own headroom is offered nothing', () async {
      // Below the 512 MB the device keeps spare, so there is no usable room at all.
      withCapacity(freeMb: 400);

      final CloneBudget budget = await controller.cloneBudget();

      expect(budget.allowsNone, isTrue);
      // The figure is named so the user knows what to clear.
      expect(budget.reason, contains('400 MB'));
      // The caller's sentence already carries the verdict; saying it again here is
      // what made the composed message repeat itself.
      expect(budget.reason, isNot(contains('no room')));
    });

    test('room for part of a clone is room for none, and reads like it', () async {
      // Clears the 512 MB headroom by 30 KB — less than one clone costs. The figure
      // reaches zero only after the minimum, which is where the wording is decided.
      responses['getDeviceCapacity'] = <Object?, Object?>{
        'freeBytes': 512 * mb + 30 * 1024,
        'totalBytes': 64 * 1024 * mb,
        'totalMemBytes': 8 * 1024 * mb,
        'isLowRamDevice': false,
      };

      final CloneBudget budget = await controller.cloneBudget();

      expect(budget.allowsNone, isTrue);
      // 'Up to 0 — 512 MB of space left' is not a sentence anyone should be shown.
      expect(budget.reason, isNot(contains('Up to 0')));
      expect(budget.reason, startsWith('Only 512 MB is free'));
    });

    test('a low-RAM device is held to a handful, and told why', () async {
      withCapacity(freeMb: 8192, lowRam: true);

      final CloneBudget budget = await controller.cloneBudget();

      expect(budget.maximum, 4);
      expect(budget.reason, contains('memory'));
    });

    test('a modest phone is offered fewer than a large one', () async {
      withCapacity(freeMb: 8192, totalMemGb: 2);
      expect((await controller.cloneBudget()).maximum, 6);

      withCapacity(freeMb: 8192, totalMemGb: 4);
      expect((await controller.cloneBudget()).maximum, 12);

      withCapacity(freeMb: 8192, totalMemGb: 8);
      expect((await controller.cloneBudget()).maximum, 20);
    });

    test('a nearly-full device is bound by space, and says so', () async {
      // 512 MB headroom + 512 KB usable: eight clones at 64 KB each.
      withCapacity(freeMb: 512, totalMemGb: 8);
      responses['getDeviceCapacity'] = <Object?, Object?>{
        'freeBytes': 512 * mb + 512 * 1024,
        'totalBytes': 64 * 1024 * mb,
        'totalMemBytes': 8 * 1024 * mb,
        'isLowRamDevice': false,
      };

      final CloneBudget budget = await controller.cloneBudget();

      expect(budget.maximum, 8);
      expect(budget.reason, contains('space left'));
    });

    test('a device that will not answer is offered everything', () async {
      // `getDeviceCapacity` is absent from `responses`, so the bridge throws. A failed
      // capability check must not stand between the user and a clone that would work.
      final CloneBudget budget = await controller.cloneBudget();

      expect(budget.maximum, 20);
    });
  });

  group('creating clones against the budget', () {
    test('a batch beyond the budget is refused before anything is made', () async {
      final VirtualProfileModel profile = await seedClone();
      withCapacity(freeMb: 8192, lowRam: true); // budget of 4
      await controller.refreshAll();

      final String? error = await controller.createClones(profile, 9);

      expect(error, contains('Not enough room for 9 more'));
      expect(error, contains('can take 4'));
      // Refused up front: the one seeded clone is still the only one.
      expect(await repository.getProfiles(), hasLength(1));
    });

    test('a device with no room names the app it is refusing', () async {
      final VirtualProfileModel profile = await seedClone();
      withCapacity(freeMb: 400);
      await controller.refreshAll();

      final String? error = await controller.createClones(profile, 3);

      expect(error, contains('another Virtual Test App clone'));
      expect(await repository.getProfiles(), hasLength(1));
    });

    test('a batch within the budget is created', () async {
      final VirtualProfileModel profile = await seedClone();
      withCapacity(freeMb: 8192, lowRam: true); // budget of 4
      await controller.refreshAll();

      final String? error = await controller.createClones(profile, 4);

      expect(error, isNull);
      expect(await repository.getProfiles(), hasLength(5));
    });

    test('clones are still created when the check cannot run', () async {
      final VirtualProfileModel profile = await seedClone();
      await controller.refreshAll();

      final String? error = await controller.createClones(profile, 2);

      expect(error, isNull);
      expect(await repository.getProfiles(), hasLength(3));
    });

    test('an app\'s archive size has no say in the budget', () async {
      final VirtualProfileModel profile = await seedClone();
      // A 4 GB app on a device with 1 GB usable. The old model charged a clone for a
      // copy of the archive and would have refused; the engine installs the package
      // once and every clone after it costs only its own empty directories.
      responses['getAppDetails'] = ok('APP_DETAILS', <String, Object?>{
        'packageName': AppConstants.testAppPackage,
        'appName': 'Virtual Test App',
        'apkCount': 1,
        'totalSizeBytes': 4 * 1024 * mb,
        'abis': <Object?>[],
        'components': <Object?>[],
      });
      withCapacity(freeMb: 512 + 1024, totalMemGb: 8);
      await controller.refreshAll();

      final String? error = await controller.createClones(profile, 5);

      expect(error, isNull);
      expect(await repository.getProfiles(), hasLength(6));
    });
  });
}
