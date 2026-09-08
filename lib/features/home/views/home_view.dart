import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../../onboarding/widgets/background_permission_banner.dart';
import '../../onboarding/widgets/onboarding_host.dart';
import '../../profiles/widgets/profile_dialogs.dart';
import '../controllers/home_controller.dart';
import '../widgets/add_clone_tile.dart';
import '../widgets/clone_action_sheet.dart';
import '../widgets/clone_tile.dart';
import '../widgets/home_header.dart';
import '../widgets/virtualization_warning.dart';

/// The clone launcher.
///
/// A three-column grid whose first cell adds a clone, because that is what this screen
/// is: a home screen for cloned apps. Tapping a tile opens the clone; holding it opens
/// everything else — status, warnings, rename, shortcut, delete — the way a launcher
/// icon behaves.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  /// Three across, matching a launcher's own density at this width.
  static const int _columns = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
                children: <Widget>[
                  HomeHeader(
                    title: AppConstants.appTitle,
                    subtitle: 'Your private copies',
                    trailing: _overflowMenu(context),
                  ),
                  VirtualizationWarning(
                    virtualizationActive: controller.providesRuntimeIsolation,
                    problem: controller.virtualizationProblem,
                  ),
                  if (controller.errorMessage.value != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Text(
                        controller.errorMessage.value!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  _grid(context),
                  if (controller.profiles.isEmpty) _emptyHint(context),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  OnboardingController get _onboarding => Get.find<OnboardingController>();

  /// App-level actions. Kept as one menu so the header stays an identity block rather
  /// than a row of icons.
  Widget _overflowMenu(BuildContext context) {
    return PopupMenuButton<_HomeMenuAction>(
      tooltip: 'More',
      onSelected: (_HomeMenuAction action) {
        switch (action) {
          case _HomeMenuAction.refresh:
            controller.refreshAll();
          case _HomeMenuAction.developerTools:
            Get.toNamed<void>(AppRoutes.developerTools);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<_HomeMenuAction>>[
        const PopupMenuItem<_HomeMenuAction>(
          value: _HomeMenuAction.refresh,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.refresh),
            title: Text('Refresh'),
          ),
        ),
        const PopupMenuItem<_HomeMenuAction>(
          value: _HomeMenuAction.developerTools,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.terminal_outlined),
            title: Text('Developer Tools'),
          ),
        ),
      ],
    );
  }

  /// The grid. `shrinkWrap` because it sits inside the page's scroll view rather than
  /// owning its own — the header, the engine warning and the hint scroll with it, and
  /// the controller already builds every profile eagerly, so nothing lazy is lost.
  Widget _grid(BuildContext context) {
    return GridView.count(
      crossAxisCount: _columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12.w,
      crossAxisSpacing: 12.w,
      // Square cells. At three across this leaves the icon, the name and the corner
      // badge comfortable room without the tile turning into a card.
      childAspectRatio: 1,
      children: <Widget>[
        AddCloneTile(onTap: _openAddProfile),
        ...controller.profiles.map(
          (VirtualProfileModel profile) => CloneTile(
            profile: profile,
            state: controller.stateFor(profile),
            icon: controller.iconFor(profile),
            siblingCount: controller.siblingCount(profile),
            instanceIndex: controller.instanceIndex(profile),
            warnings: controller.warningsFor(profile),
            needsPermissions: controller.needsPermissions(profile),
            canLaunch: controller.providesRuntimeIsolation,
            onTap: () => _launch(context, profile),
            onLongPress: () => _openActions(context, profile),
          ),
        ),
      ],
    );
  }

  /// Shown only while there is nothing to launch. One line under the grid rather than a
  /// panel: the "Add app" tile is already on screen saying what to do, and a full empty
  /// state next to it would say it twice.
  Widget _emptyHint(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: Text(
        'No clones yet. Tap Add app to copy an installed app, or import an APK.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  /// Opens the Doze exemption screen and re-checks the answer when the user returns.
  Future<void> _confirmBackgroundPermission(BuildContext context) async {
    final String? message = await _onboarding.requestBackgroundPermission();
    if (message != null && context.mounted) {
      _showMessage(context, message);
    }
    // Android owns the answer, so ask it rather than assuming the prompt succeeded.
    await _onboarding.refreshBackgroundPrompt();
  }

  Future<void> _openAddProfile() async {
    final Object? created = await Get.toNamed<Object?>(AppRoutes.appPicker);
    if (created == true) {
      await controller.refreshAll();
    }
  }

  Future<void> _launch(
    BuildContext context,
    VirtualProfileModel profile,
  ) async {
    final String? error = await controller.launchProfile(profile);
    if (!context.mounted) {
      return;
    }
    _showMessage(
      context,
      error ?? 'Launched ${profile.appName} in ${profile.profileName}.',
    );
  }

  Future<void> _openActions(
    BuildContext context,
    VirtualProfileModel profile,
  ) async {
    final CloneAction? action = await showCloneActionSheet(
      context,
      profile: profile,
      state: controller.stateFor(profile),
      icon: controller.iconFor(profile),
      siblingCount: controller.siblingCount(profile),
      instanceIndex: controller.instanceIndex(profile),
      warnings: controller.warningsFor(profile),
      needsPermissions: controller.needsPermissions(profile),
      canLaunch: controller.providesRuntimeIsolation,
    );
    if (action == null || !context.mounted) {
      return;
    }
    await _handleAction(context, profile, action);
  }

  Future<void> _handleAction(
    BuildContext context,
    VirtualProfileModel profile,
    CloneAction action,
  ) async {
    switch (action) {
      case CloneAction.launch:
        await _launch(context, profile);
      case CloneAction.grantPermissions:
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
      case CloneAction.rename:
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
      case CloneAction.clone:
        // Reuse the picker pre-filtered to this app rather than duplicating the flow.
        final Object? created = await Get.toNamed<Object?>(
          AppRoutes.appPicker,
          arguments: profile.packageName,
        );
        if (created == true) {
          await controller.refreshAll();
        }
      case CloneAction.addShortcut:
        final String? error = await controller.addShortcut(profile);
        if (!context.mounted) {
          return;
        }
        _showMessage(
          context,
          error ??
              'Confirm the shortcut on your home screen to finish adding it.',
        );
      case CloneAction.delete:
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

enum _HomeMenuAction { refresh, developerTools }
