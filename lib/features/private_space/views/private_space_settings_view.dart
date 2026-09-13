import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../settings/widgets/settings_row.dart';
import '../../settings/widgets/settings_section.dart';
import '../controllers/private_space_controller.dart';
import '../widgets/unlock_dialog.dart';
import 'private_space_setup_view.dart';
import '../../disguise/controllers/disguise_controller.dart';
import '../../../data/models/app_disguise_mode.dart';

/// The lock's own settings: set it up, change the PIN, pick the biometric, turn it off.
///
/// Kept apart from the general Settings screen because turning the lock off is a
/// security-relevant act that deserves its own confirmation, not a switch that can be
/// flicked by a thumb on the way past.
class PrivateSpaceSettingsView extends StatelessWidget {
  const PrivateSpaceSettingsView({required this.privateSpace, super.key});

  final PrivateSpaceController privateSpace;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Private space')),
      body: Obx(
        () => privateSpace.enabled ? _enabled(context) : _disabled(context),
      ),
    );
  }

  Widget _disabled(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 28.h),
      children: <Widget>[
        Icon(
          Icons.lock_outline,
          size: 56.r,
          color: theme.colorScheme.primary,
        ),
        SizedBox(height: 16.h),
        Text(
          'Private space is off',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          'Turn it on to hide clones behind a PIN. Hidden apps disappear from the main '
          'grid and open only here.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24.h),
        FilledButton(
          onPressed: () => _openSetup(context, PrivateSpaceSetupMode.create),
          child: const Text('Set up Private space'),
        ),
      ],
    );
  }

  Widget _enabled(BuildContext context) {
    final bool biometricAvailable = privateSpace.biometricAvailable.value;
    final DisguiseController disguise = Get.find<DisguiseController>();

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
      children: <Widget>[
        SettingsSection(
          children: <Widget>[
            SettingsRow(
              icon: Icons.password_outlined,
              title: 'Change PIN',
              onTap: () => _openSetup(context, PrivateSpaceSetupMode.change),
            ),
          ],
        ),
        SizedBox(height: 22.h),
        SettingsSection(
          title: 'Unlock',
          children: <Widget>[
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              value: privateSpace.biometricEnabled,
              onChanged: biometricAvailable
                  ? (bool value) => privateSpace.setBiometricEnabled(value)
                  : null,
              title: const Text('Unlock with fingerprint'),
              subtitle: Text(
                biometricAvailable
                    ? 'You can still use your PIN at any time.'
                    : 'No fingerprint or face is set up on this device.',
              ),
            ),
          ],
        ),
        SizedBox(height: 22.h),
        SettingsSection(
          title: 'Disguise',
          children: <Widget>[
            SwitchListTile(
              secondary: const Icon(Icons.calculate_outlined),
              value: disguise.disguised,
              onChanged: (bool value) => _setDisguise(context, value),
              title: const Text('Disguise as Calculator'),
              subtitle: const Text(
                'Replaces Duplika\'s icon with a calculator. Type your Private space PIN '
                'and press = to open the app.',
              ),
            ),
          ],
        ),
        SizedBox(height: 22.h),
        TextButton.icon(
          onPressed: () => _turnOff(context),
          icon: const Icon(Icons.lock_open_outlined),
          label: const Text('Turn off Private space'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Turning it off brings every hidden app back to the main grid. The clones '
          'themselves are not deleted.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Future<void> _setDisguise(BuildContext context, bool enable) async {
    final DisguiseController disguise = Get.find<DisguiseController>();
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(enable ? 'Disguise as Calculator?' : 'Show Duplika again?'),
            content: Text(
              enable
                  ? 'Duplika\'s icon is replaced by a calculator named "Calculator". To '
                      'open Duplika, type your Private space PIN and press =. If you '
                      'forget the PIN you will not be able to open the app.'
                  : 'Duplika will show its own icon and name on the home screen again.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(enable ? 'Disguise' : 'Show app'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return;
    }

    final AppDisguiseMode? applied = await disguise.setMode(
      enable ? AppDisguiseMode.calculator : AppDisguiseMode.normal,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            applied == null
                ? 'Could not change how the app appears.'
                : enable
                    ? 'Duplika now looks like Calculator on your home screen.'
                    : 'Duplika is back on your home screen.',
          ),
        ),
      );
  }

  Future<void> _openSetup(
    BuildContext context,
    PrivateSpaceSetupMode mode,
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => PrivateSpaceSetupView(
          privateSpace: privateSpace,
          mode: mode,
        ),
      ),
    );
  }

  Future<void> _turnOff(BuildContext context) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Turn off Private space?'),
            content: const Text(
              'Every hidden app will return to the main grid, and the PIN will be '
              'forgotten. The clones themselves are kept.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Turn off'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return;
    }

    final bool unlocked =
        await showPrivateSpaceUnlockDialog(context, privateSpace);
    if (!unlocked || !context.mounted) {
      return;
    }
    await privateSpace.disable();
    // The disguise is unlocked with this PIN, so it cannot outlive the PIN: leaving it on
    // would leave only a calculator and no way in.
    final DisguiseController disguise = Get.find<DisguiseController>();
    if (disguise.disguised) {
      await disguise.setMode(AppDisguiseMode.normal);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Private space turned off.')),
        );
    }
  }
}
