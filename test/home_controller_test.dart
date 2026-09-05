import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_space_demo/core/constants/app_constants.dart';
import 'package:virtual_space_demo/core/virtualization/real_virtualization_engine.dart';
import 'package:virtual_space_demo/data/models/virtual_profile_model.dart';
import 'package:virtual_space_demo/data/repositories/virtual_profile_repository.dart';
import 'package:virtual_space_demo/features/home/controllers/home_controller.dart';
import 'package:virtual_space_demo/native/native_bridge.dart';

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
}
