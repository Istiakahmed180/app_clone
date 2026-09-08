import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../../widgets/empty_state.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../../onboarding/widgets/background_permission_banner.dart';
import '../../onboarding/widgets/onboarding_host.dart';
import '../../profiles/widgets/profile_dialogs.dart';
import '../controllers/home_controller.dart';
import '../widgets/add_clone_tile.dart';
import '../widgets/clone_action_sheet.dart';
import '../widgets/clone_count_dialog.dart';
import '../widgets/clone_tile.dart';
import '../widgets/home_header.dart';
import '../widgets/virtualization_warning.dart';
import 'space_info_view.dart';

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
                    subtitle: 'Your private space',
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
                  if (controller.profiles.isEmpty) _emptyState(),
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
  ///
  /// No Refresh entry: the grid is already a [RefreshIndicator], so pulling down does
  /// the same thing, and a menu item that duplicates a gesture the screen already has
  /// only makes the menu longer.
  Widget _overflowMenu(BuildContext context) {
    return PopupMenuButton<void>(
      tooltip: 'More',
      itemBuilder: (BuildContext context) => <PopupMenuEntry<void>>[
        PopupMenuItem<void>(
          onTap: () => Get.toNamed<void>(AppRoutes.developerTools),
          child: const ListTile(
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
            canLaunch: controller.providesRuntimeIsolation,
            onTap: () => _launch(context, profile),
            onLongPress: () => _openActions(context, profile),
          ),
        ),
      ],
    );
  }

  /// Shown only while there is nothing to launch.
  ///
  /// A panel rather than a line of text: a first run where the grid holds one tinted
  /// square and nothing else reads as a screen that failed to load. The panel says the
  /// app got here on purpose and names the next step.
  Widget _emptyState() {
    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: EmptyState(
        title: 'Your space is empty',
        message: 'Add an app to create your first private instance.',
        actionLabel: 'Add your first app',
        onAction: _openAddProfile,
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
    );
    if (action == null || !context.mounted) {
      return;
    }
    await _handleAction(context, profile, action);
  }

  /// Makes more copies of an app the user already has a clone of.
  ///
  /// Asks for a count and creates them here, rather than sending the user back through
  /// the picker to choose the app they just long-pressed. The picker is still how a
  /// *new* app is cloned; this is the shortcut for one already on the grid.
  Future<void> _cloneAgain(
    BuildContext context,
    VirtualProfileModel profile,
  ) async {
    final int? count = await showCloneCountDialog(
      context,
      appName: profile.appName,
    );
    if (count == null || !context.mounted) {
      return;
    }

    // Each clone is a container install of a few seconds. A barrier that reports its
    // progress is the honest thing to show; a frozen grid would read as a hang.
    final ValueNotifier<String> progress = ValueNotifier<String>(
      'Creating 1 of $count…',
    );
    _showProgress(context, profile, progress);

    final String? error = await controller.createClones(
      profile,
      count,
      onProgress: (int created, int total) => progress.value = created >= total
          ? 'Finishing…'
          : 'Creating ${created + 1} of $total…',
    );

    if (!context.mounted) {
      progress.dispose();
      return;
    }
    // Closes the barrier, whose route is the top one.
    Navigator.of(context).pop();
    progress.dispose();

    _showMessage(
      context,
      error ??
          (count == 1
              ? 'Added another ${profile.appName}.'
              : 'Added $count more copies of ${profile.appName}.'),
    );
  }

  void _showProgress(
    BuildContext context,
    VirtualProfileModel profile,
    ValueNotifier<String> progress,
  ) {
    showDialog<void>(
      context: context,
      // Not dismissible: the work carries on regardless, and letting the user close the
      // barrier would leave clones appearing behind a screen that says nothing.
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        content: Row(
          children: <Widget>[
            SizedBox(
              width: 22.r,
              height: 22.r,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 18.w),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: progress,
                builder:
                    (BuildContext context, String message, Widget? child) =>
                        Text(message),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the facts about one clone, and applies the one fix it offers.
  /// Opens the space's own page.
  ///
  /// A page and not a sheet: it carries the space's identifiers, which are there to be
  /// read and copied, and a sheet that tall is worse than a screen at both.
  Future<void> _openSpaceInfo(
    BuildContext context,
    VirtualProfileModel profile,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SpaceInfoView(
          controller: controller,
          profile: profile,
          state: controller.stateFor(profile),
          instanceIndex: controller.instanceIndex(profile),
          engineActive: controller.providesRuntimeIsolation,
        ),
      ),
    );
  }

  /// Confirms a force stop.
  ///
  /// Stopping a guest is not destructive, but it is abrupt: whatever the clone was
  /// doing — an upload, a call, a form half filled in — ends there, and the tile gives
  /// no warning of that. One tap of confirmation is cheaper than losing the work.
  Future<bool?> _confirmForceStop(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Force stop this app?'),
        content: const Text(
          'The app will stop running until you open it again.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Force stop'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmClearStorage(
    BuildContext context,
    VirtualProfileModel profile,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Clear ${profile.profileName}?'),
        content: const Text(
          'Everything this clone has stored \u2014 accounts, messages, settings, '
          'downloads \u2014 is deleted. The clone itself stays, and its next launch '
          'will be a first launch. This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    VirtualProfileModel profile,
    CloneAction action,
  ) async {
    switch (action) {
      case CloneAction.spaceInfo:
        await _openSpaceInfo(context, profile);
      case CloneAction.forceStop:
        final bool confirmed = await _confirmForceStop(context) ?? false;
        if (!confirmed || !context.mounted) {
          return;
        }
        final String? error = await controller.forceStop(profile);
        if (!context.mounted) {
          return;
        }
        _showMessage(context, error ?? 'Stopped ${profile.profileName}.');
      case CloneAction.clearCache:
        final String? error = await controller.clearCache(profile);
        if (!context.mounted) {
          return;
        }
        _showMessage(
          context,
          error ?? 'Cache cleared for ${profile.profileName}.',
        );
      case CloneAction.clearStorage:
        // Confirmed: this is every login, message and setting inside the clone, and
        // there is no undo. Uninstall is the only other action that asks.
        final bool confirmed =
            await _confirmClearStorage(context, profile) ?? false;
        if (!confirmed || !context.mounted) {
          return;
        }
        final String? error = await controller.clearStorage(profile);
        if (!context.mounted) {
          return;
        }
        _showMessage(
          context,
          error ??
              '${profile.profileName} was reset. Its next launch is a first launch.',
        );
      case CloneAction.shareApp:
        final String? error = await controller.shareApp(profile);
        // Only a failure is worth saying: on success the share sheet is already on
        // screen, and a snack bar behind it would be talking over the answer.
        if (error != null && context.mounted) {
          _showMessage(context, error);
        }
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
        await _cloneAgain(context, profile);
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
