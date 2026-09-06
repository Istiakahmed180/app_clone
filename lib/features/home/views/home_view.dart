import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/profile_card.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../../onboarding/widgets/background_permission_banner.dart';
import '../../onboarding/widgets/onboarding_host.dart';
import '../../profiles/widgets/profile_dialogs.dart';
import '../controllers/home_controller.dart';
import '../widgets/virtualization_warning.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProfile,
        icon: const Icon(Icons.add),
        label: const Text('Add clone'),
      ),
      bottomNavigationBar: Obx(
        () => _onboarding.showBackgroundPrompt.value
            ? BackgroundPermissionBanner(
                onConfirm: () => _confirmBackgroundPermission(context),
                onDismiss: _onboarding.dismissBackgroundPrompt,
              )
            : const SizedBox.shrink(),
      ),
      body: OnboardingHost(
        child: SafeArea(
          child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: controller.refreshAll,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
              children: <Widget>[
                VirtualizationWarning(
                  virtualizationActive: controller.providesRuntimeIsolation,
                  problem: controller.virtualizationProblem,
                ),
                Text(
                  'Your Virtual Apps',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 12.h),
                if (controller.errorMessage.value != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Text(
                      controller.errorMessage.value!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ..._buildProfileSection(context),
              ],
              ),
            );
          }),
        ),
      ),
    );
  }

  OnboardingController get _onboarding => Get.find<OnboardingController>();

  /// Opens the Doze exemption screen and re-checks the answer when the user returns.
  Future<void> _confirmBackgroundPermission(BuildContext context) async {
    final String? message = await _onboarding.requestBackgroundPermission();
    if (message != null && context.mounted) {
      _showMessage(context, message);
    }
    // Android owns the answer, so ask it rather than assuming the prompt succeeded.
    await _onboarding.refreshBackgroundPrompt();
  }

  List<Widget> _buildProfileSection(BuildContext context) {
    if (controller.profiles.isEmpty) {
      return <Widget>[
        SizedBox(height: 48.h),
        const EmptyState(
          title: 'No clones yet',
          message: 'Add a clone of an installed app, or import an APK.',
        ),
      ];
    }

    return controller.profiles
        .map((VirtualProfileModel profile) => ProfileCard(
              profile: profile,
              state: controller.stateFor(profile),
              icon: controller.iconFor(profile),
              siblingCount: controller.siblingCount(profile),
              instanceIndex: controller.instanceIndex(profile),
              warnings: controller.warningsFor(profile),
              canLaunch: controller.providesRuntimeIsolation,
              onLaunch: () => _launch(context, profile),
              needsPermissions: controller.needsPermissions(profile),
              onAction: (ProfileCardAction action) =>
                  _handleAction(context, profile, action),
            ))
        .toList(growable: false);
  }

  Future<void> _openAddProfile() async {
    final Object? created = await Get.toNamed<Object?>(AppRoutes.appPicker);
    if (created == true) {
      await controller.refreshAll();
    }
  }

  Future<void> _launch(BuildContext context, VirtualProfileModel profile) async {
    final String? error = await controller.launchProfile(profile);
    if (!context.mounted) {
      return;
    }
    _showMessage(
      context,
      error ?? 'Launched ${profile.appName} in ${profile.profileName}.',
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    VirtualProfileModel profile,
    ProfileCardAction action,
  ) async {
    switch (action) {
      case ProfileCardAction.grantPermissions:
        final String? error = await controller.grantPermissions(profile);
        if (!context.mounted) {
          return;
        }
        _showMessage(
          context,
          error ??
              (controller.needsPermissions(profile)
                  ? 'Some permissions are still missing. The clone will keep working '
                      'without them, but features that need them will not.'
                  : 'Permissions granted. Relaunch the clone to pick them up.'),
        );
      case ProfileCardAction.rename:
        final String? name = await showRenameProfileDialog(
          context,
          currentName: profile.profileName,
        );
        if (name == null || !context.mounted) {
          return;
        }
        final String? error = await controller.renameProfile(profile, name);
        if (error != null && context.mounted) {
          _showMessage(context, error);
        }
      case ProfileCardAction.clone:
        // Reuse the picker pre-filtered to this app rather than duplicating the flow.
        final Object? created = await Get.toNamed<Object?>(
          AppRoutes.appPicker,
          arguments: profile.packageName,
        );
        if (created == true) {
          await controller.refreshAll();
        }
      case ProfileCardAction.addShortcut:
        final String? error = await controller.addShortcut(profile);
        if (!context.mounted) {
          return;
        }
        _showMessage(
          context,
          error ?? 'Confirm the shortcut on your home screen to finish adding it.',
        );
      case ProfileCardAction.delete:
        final bool confirmed = await showDeleteProfileDialog(
          context,
          profileName: profile.profileName,
        );
        if (!confirmed || !context.mounted) {
          return;
        }
        final String? error = await controller.deleteProfile(profile);
        if (error != null && context.mounted) {
          _showMessage(context, error);
        }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
