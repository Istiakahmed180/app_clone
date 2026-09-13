import 'package:duplika/core/services/biometric_authenticator.dart';
import 'package:duplika/core/services/private_space_store.dart';
import 'package:duplika/data/models/engine_result.dart';
import 'package:duplika/data/models/virtual_profile_model.dart';
import 'package:duplika/data/repositories/virtual_profile_repository.dart';
import 'package:duplika/features/home/widgets/clone_action_sheet.dart';
import 'package:duplika/features/private_space/controllers/private_space_controller.dart';
import 'package:duplika/features/private_space/views/private_space_settings_view.dart';
import 'package:duplika/features/private_space/widgets/private_space_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/in_memory_profile_storage.dart';

class _FakeBiometric extends BiometricAuthenticator {
  bool available = true;

  @override
  Future<bool> isAvailable() async => available;
}

VirtualProfileModel _profile() => VirtualProfileModel(
      id: 'p1',
      packageName: 'org.example',
      appName: 'Example',
      profileName: 'Example',
      createdAt: DateTime(2026),
    );

const VirtualProfileState _state = VirtualProfileState(
  installed: true,
  running: false,
  virtualUserId: 0,
);

Widget _host(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (BuildContext context, Widget? _) => MaterialApp(home: child),
  );
}

void main() {
  testWidgets('the action sheet offers Hide for a clone on the grid', (
    WidgetTester tester,
  ) async {
    CloneAction? chosen;

    await tester.pumpWidget(
      _host(
        Builder(
          builder: (BuildContext context) => ElevatedButton(
            onPressed: () async {
              chosen = await showCloneActionSheet(
                context,
                profile: _profile(),
                state: _state,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Hide'), findsOneWidget);
    expect(find.text('Unhide'), findsNothing);

    await tester.tap(find.text('Hide'));
    await tester.pumpAndSettle();

    expect(chosen, CloneAction.toggleHidden);
  });

  testWidgets('the action sheet offers Unhide inside the space', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (BuildContext context) => ElevatedButton(
            onPressed: () => showCloneActionSheet(
              context,
              profile: _profile().copyWith(hidden: true),
              state: _state,
              hidden: true,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Unhide'), findsOneWidget);
    expect(find.text('Hide'), findsNothing);
  });

  testWidgets('the Private space tile shows its count and opens', (
    WidgetTester tester,
  ) async {
    int taps = 0;

    await tester.pumpWidget(
      _host(
        PrivateSpaceTile(hiddenCount: 3, onTap: () => taps++),
      ),
    );

    expect(find.text('Private space'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.text('Private space'));
    expect(taps, 1);
  });

  testWidgets('the settings screen offers setup while the space is off', (
    WidgetTester tester,
  ) async {
    final PrivateSpaceStore store =
        PrivateSpaceStore(storage: InMemoryProfileStorage());
    final PrivateSpaceController controller = PrivateSpaceController(
      repository: VirtualProfileRepository(storage: InMemoryProfileStorage()),
      store: store,
      biometric: _FakeBiometric(),
    );

    await tester.pumpWidget(
      _host(PrivateSpaceSettingsView(privateSpace: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set up Private space'), findsOneWidget);
    expect(find.text('Change PIN'), findsNothing);
  });

  testWidgets('an enabled space offers Change PIN and the biometric row', (
    WidgetTester tester,
  ) async {
    final InMemoryProfileStorage storage = InMemoryProfileStorage();
    await storage.write(PrivateSpaceStore.enabledKey, 'true');
    await storage.write(PrivateSpaceStore.hashKey, '00' * 32);
    final PrivateSpaceController controller = PrivateSpaceController(
      repository: VirtualProfileRepository(storage: storage),
      store: PrivateSpaceStore(storage: storage),
      biometric: _FakeBiometric(),
    );
    await controller.reload();

    await tester.pumpWidget(
      _host(PrivateSpaceSettingsView(privateSpace: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Change PIN'), findsOneWidget);
    expect(find.text('Unlock with fingerprint'), findsOneWidget);
    expect(find.text('Turn off Private space'), findsOneWidget);
  });
}
