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
          // The header stays put; only the clones scroll. A launcher's title does not
          // slide away when you scroll its icons, and with enough clones to need
          // scrolling the header was the first thing to go.
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                child: HomeHeader(
                  title: AppConstants.appTitle,
                  subtitle: 'Your private space',
                  trailing: _overflowMenu(context),
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return RefreshIndicator(
                    onRefresh: controller.refreshAll,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 32.h),
                      children: <Widget>[
                        // Scrolls with the grid rather than pinned under the header:
                        // it only appears when the engine is down, and a conditional
                        // block in the fixed part would move the grid up and down as
                        // it came and went.
                        VirtualizationWarning(
                          virtualizationActive:
                              controller.providesRuntimeIsolation,
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
            ],
          ),
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
          onTap: () => Get.toNamed<void>(AppRoutes.settings),
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
          ),
        ),
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
            isRemoving: controller.removing.contains(profile.id),
            isLaunching: controller.launching.contains(profile.id),
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
      await _showFailure(context, message);
    }
    // Android owns the answer, so ask it rather than assuming the prompt succeeded.
    await _onboarding.refreshBackgroundPrompt();
  }

  Future<void> _openAddProfile() async {
    await Get.toNamed<Object?>(AppRoutes.appPicker);
    // Refreshed unconditionally rather than on the picker's return value: the system
    // back button pops with no result, and a clone the engine has already installed was
    // then invisible until the app was restarted.
    await controller.refreshAll();
  }

  Future<void> _launch(
    BuildContext context,
    VirtualProfileModel profile,
  ) async {
    final String? error = await controller.launchProfile(profile);
    if (!context.mounted) {
      return;
    }
    // Only failures are announced. A launch that worked brings the guest to the front,
    // so a message about it lands on top of the app the user is now looking at.
    if (error != null) {
      await _showFailure(context, error);
    }
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

    if (error != null) {
      await _showFailure(context, error);
      return;
    }
    _showMessage(
      context,
      count == 1
          ? 'Added another ${profile.appName}.'
          : 'Added $count more copies of ${profile.appName}.',
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
            child: const Text('Force stop'),
          ),
        ],
      ),
    );
  }

  /// Confirms a cache clear.
  ///
  /// Not destructive — logins and settings survive — but it is worth a question all the
  /// same, because it sits next to Clear storage in the same grid and the two names read
  /// alike. A confirmation that names what goes is what keeps a mis-tap harmless.
  Future<bool?> _confirmClearCache(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Clear app cache?'),
        content: const Text('This will remove temporary files for this clone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear cache'),
          ),
        ],
      ),
    );
  }

  /// Confirms a storage clear.
  ///
  /// The one dialog here that has to be unambiguous: this is every account, message and
  /// setting inside the clone, and there is no undo. It names what goes rather than
  /// naming the clone.
  Future<bool?> _confirmClearStorage(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Clear app storage?'),
        content: const Text(
          'This will permanently delete this clone\'s accounts, settings, and local '
          'data.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear Storage'),
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
        if (error != null) {
          await _showFailure(context, error);
        } else {
          _showMessage(context, 'Stopped ${profile.profileName}.');
        }
      case CloneAction.clearCache:
        final bool confirmed = await _confirmClearCache(context) ?? false;
        if (!confirmed || !context.mounted) {
          return;
        }
        final String? error = await controller.clearCache(profile);
        if (!context.mounted) {
          return;
        }
        if (error != null) {
          await _showFailure(context, error);
        } else {
          _showMessage(context, 'Cache cleared for ${profile.profileName}.');
        }
      case CloneAction.clearStorage:
        // Confirmed: this is every login, message and setting inside the clone, and
        // there is no undo. Uninstall is the only other action that asks.
        final bool confirmed = await _confirmClearStorage(context) ?? false;
        if (!confirmed || !context.mounted) {
          return;
        }
        final String? error = await controller.clearStorage(profile);
        if (!context.mounted) {
          return;
        }
        if (error != null) {
          await _showFailure(context, error);
        } else {
          _showMessage(
            context,
            '${profile.profileName} was reset. Its next launch is a first launch.',
          );
        }
      case CloneAction.shareApp:
        final String? error = await controller.shareApp(profile);
        // Only a failure is worth saying: on success the share sheet is already on
        // screen, and a dialog behind it would be talking over the answer.
        if (error != null && context.mounted) {
          await _showFailure(context, error);
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
          await _showFailure(context, error);
        }
      case CloneAction.clone:
        await _cloneAgain(context, profile);
      case CloneAction.addShortcut:
        final String? error = await controller.addShortcut(profile);
        if (!context.mounted) {
          return;
        }
        if (error != null) {
          await _showFailure(context, error);
        } else {
          _showMessage(
            context,
            'Confirm the shortcut on your home screen to finish adding it.',
          );
        }
      case CloneAction.delete:
        final bool confirmed = await showUninstallCloneDialog(
          context,
          appName: profile.appName,
          spaceIndex: controller.instanceIndex(profile),
          spaceCount: controller.siblingCount(profile),
          icon: controller.iconFor(profile),
        );
        if (!confirmed || !context.mounted) {
          return;
        }
        // `uninstall` rather than `deleteProfile`: it lets the tile animate out first,
        // so the clone that goes is the one the user watched go.
        final String? error = await controller.uninstall(profile);
        if (error != null && context.mounted) {
          await _showFailure(context, error);
        }
    }
  }

  /// Confirms something that worked, and gets out of the way.
  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Says why something did not happen, and waits to be dismissed.
  ///
  /// A snack bar was the wrong shape for these. They run to two lines, they land at the
  /// bottom of a grid the user is not looking at, and they leave on a timer — so a
  /// refusal the user never read is indistinguishable from a clone that silently failed
  /// to appear. Successes keep the snack bar: they need no reply, and a dialog for every
  /// one would be a tap tax on the path that worked.
  Future<void> _showFailure(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Couldn\'t do that'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
