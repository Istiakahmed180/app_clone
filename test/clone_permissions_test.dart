import 'package:duplika/core/services/private_space_store.dart';
import 'package:duplika/core/virtualization/real_virtualization_engine.dart';
import 'package:duplika/data/models/virtual_profile_model.dart';
import 'package:duplika/data/repositories/virtual_profile_repository.dart';
import 'package:duplika/features/home/controllers/home_controller.dart';
import 'package:duplika/features/home/views/clone_permissions_view.dart';
import 'package:duplika/features/private_space/controllers/private_space_controller.dart';
import 'package:duplika/native/native_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/in_memory_profile_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(NativeBridge.channelName);
  late Map<String, Map<Object?, Object?>> responses;
  late List<Map<Object?, Object?>> setCalls;

  Map<Object?, Object?> ok(String code, Map<String, Object?> data) => <Object?, Object?>{
        'success': true,
        'code': code,
        'message': 'ok',
        'data': data,
      };

  setUp(() {
    setCalls = <Map<Object?, Object?>>[];
    responses = <String, Map<Object?, Object?>>{
      'getClonePermissions': ok('CLONE_PERMISSIONS_READ', <String, Object?>{
        'virtualUserId': 0,
        'permissions': <Object?>['android.permission.CAMERA'],
        'denied': <Object?>[],
      }),
      'setClonePermission': ok('CLONE_PERMISSION_SET', <String, Object?>{'denied': <Object?>[]}),
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      if (call.method == 'setClonePermission' && call.arguments is Map) {
        setCalls.add((call.arguments as Map).cast<Object?, Object?>());
      }
      return responses[call.method];
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('a permission can be denied for one clone', (WidgetTester tester) async {
    final InMemoryProfileStorage storage = InMemoryProfileStorage();
    final VirtualProfileRepository repository = VirtualProfileRepository(storage: storage);
    final VirtualProfileModel profile = await repository.createProfile(
      packageName: 'com.example.app',
      appName: 'Example',
      profileName: 'Example',
    );
    final NativeBridge bridge = NativeBridge(channel: channel);
    final HomeController controller = HomeController(
      engine: RealVirtualizationEngine(repository: repository, nativeBridge: bridge),
      nativeBridge: bridge,
      repository: repository,
      privateSpace: PrivateSpaceController(
        repository: repository,
        store: PrivateSpaceStore(storage: storage),
      ),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (BuildContext context, Widget? child) => MaterialApp(
          home: ClonePermissionsView(controller: controller, profile: profile),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Camera'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(setCalls.single['permission'], 'android.permission.CAMERA');
    expect(setCalls.single['allowed'], isFalse);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
  });
}
