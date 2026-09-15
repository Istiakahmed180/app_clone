import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../settings/widgets/settings_row.dart';
import '../../settings/widgets/settings_section.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_context.dart';
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
      appBar: AppBar(title: Text(context.l10n.privateSpaceTitle)),
      body: Obx(
        () => privateSpace.enabled ? _enabled(context) : _disabled(context),
      ),
    );
  }

  Widget _disabled(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;

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
          l10n.privateSpaceOffTitle,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          l10n.privateSpaceOffMessage,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24.h),
        FilledButton(
          onPressed: () => _openSetup(context, PrivateSpaceSetupMode.create),
          child: Text(l10n.privateSpaceSetUp),
        ),
      ],
    );
  }

  Widget _enabled(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool biometricAvailable = privateSpace.biometricAvailable.value;
    final DisguiseController disguise = Get.find<DisguiseController>();

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
      children: <Widget>[
        SettingsSection(
          children: <Widget>[
            SettingsRow(
              icon: Icons.password_outlined,
              title: l10n.privateSpaceChangePin,
              onTap: () => _openSetup(context, PrivateSpaceSetupMode.change),
            ),
          ],
        ),
        SizedBox(height: 22.h),
        SettingsSection(
          title: l10n.privateSpaceUnlockSection,
          children: <Widget>[
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              value: privateSpace.biometricEnabled,
              onChanged: biometricAvailable
                  ? (bool value) => privateSpace.setBiometricEnabled(value)
                  : null,
              title: Text(l10n.privateSpaceFingerprint),
              subtitle: Text(
                biometricAvailable
                    ? l10n.privateSpaceFingerprintAvailable
                    : l10n.privateSpaceFingerprintUnavailable,
              ),
            ),
          ],
        ),
        SizedBox(height: 22.h),
        SettingsSection(
          title: l10n.privateSpaceDisguiseSection,
          children: <Widget>[
            SwitchListTile(
              secondary: const Icon(Icons.calculate_outlined),
              value: disguise.disguised,
              onChanged: (bool value) => _setDisguise(context, value),
              title: Text(l10n.privateSpaceDisguiseAsCalculator),
              subtitle: Text(
                l10n.privateSpaceDisguiseSubtitle(AppConstants.appTitle),
              ),
            ),
          ],
        ),
        SizedBox(height: 22.h),
        TextButton.icon(
          onPressed: () => _turnOff(context),
          icon: const Icon(Icons.lock_open_outlined),
          label: Text(l10n.privateSpaceTurnOff),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          l10n.privateSpaceTurnOffNote,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Future<void> _setDisguise(BuildContext context, bool enable) async {
    final AppLocalizations l10n = context.l10n;
    final DisguiseController disguise = Get.find<DisguiseController>();
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(
              enable
                  ? l10n.privateSpaceDisguiseOnTitle
                  : l10n.privateSpaceDisguiseOffTitle(AppConstants.appTitle),
            ),
            content: Text(
              enable
                  ? l10n.privateSpaceDisguiseOnMessage(AppConstants.appTitle)
                  : l10n.privateSpaceDisguiseOffMessage(AppConstants.appTitle),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.commonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  enable
                      ? l10n.privateSpaceDisguiseConfirmOn
                      : l10n.privateSpaceDisguiseConfirmOff,
                ),
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
                ? l10n.privateSpaceDisguiseFailed
                : enable
                    ? l10n.privateSpaceDisguiseNowCalculator(AppConstants.appTitle)
                    : l10n.privateSpaceDisguiseRestored(AppConstants.appTitle),
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
    final AppLocalizations l10n = context.l10n;
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(l10n.privateSpaceTurnOffTitle),
            content: Text(l10n.privateSpaceTurnOffMessage),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.commonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.privateSpaceTurnOffConfirm),
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
          SnackBar(content: Text(l10n.privateSpaceTurnedOff)),
        );
    }
  }
}
