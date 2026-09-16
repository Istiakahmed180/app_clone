import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_error_text.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/models/clone_batch_result.dart';
import '../../../data/models/clone_icon_color.dart';
import '../../../data/models/clone_budget.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_context.dart';
import '../../../widgets/empty_state.dart';
import '../../onboarding/widgets/onboarding_host.dart';
import '../../profiles/widgets/profile_dialogs.dart';
import '../../private_space/views/private_space_settings_view.dart';
import '../../private_space/widgets/private_space_tile.dart';
import '../../private_space/widgets/unlock_dialog.dart';
import '../controllers/home_controller.dart';
import 'clone_permissions_view.dart';
import '../widgets/add_clone_tile.dart';
import '../widgets/clone_action_sheet.dart';
import '../widgets/clone_icon_picker.dart';
import '../widgets/clone_budget_text.dart';
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
    // Back inside the Private space closes it rather than leaving the app, so a stray
    // back press does not background the app with the hidden grid still on screen.
    return Obx(
      () => PopScope<Object?>(
        canPop: !controller.viewingPrivate.value,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (!didPop && controller.viewingPrivate.value) {
            controller.privateSpace.lock();
            controller.exitPrivateSpace();
          }
        },
        child: Scaffold(
          body: OnboardingHost(
        child: SafeArea(
          // The header stays put; only the clones scroll. A launcher's title does not
          // slide away when you scroll its icons, and with enough clones to need
          // scrolling the header was the first thing to go.
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                child: Obx(
                  () => HomeHeader(
                    title: controller.viewingPrivate.value
                        ? context.l10n.homePrivateSpaceTitle
                        : AppConstants.appTitle,
                    subtitle: controller.viewingPrivate.value
                        ? context.l10n.homeHiddenApps(controller.hiddenCount)
                        : context.l10n.homeSubtitle,
                    trailing: controller.viewingPrivate.value
                        ? _privateCloseButton(context)
                        : _overflowMenu(context),
                  ),
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
                              appErrorMessage(
                                context.l10n,
                                controller.errorMessage.value!,
                              ),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        _grid(context),
                        if (!controller.viewingPrivate.value &&
                            controller.visibleProfiles.isEmpty)
                          _emptyState(context),
                        if (controller.viewingPrivate.value &&
                            controller.hiddenProfiles.isEmpty)
                          _privateEmptyState(context),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }

  /// App-level actions. Kept as one menu so the header stays an identity block rather
  /// than a row of icons.
  ///
  /// No Refresh entry: the grid is already a [RefreshIndicator], so pulling down does
  /// the same thing, and a menu item that duplicates a gesture the screen already has
  /// only makes the menu longer.
  Widget _overflowMenu(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return PopupMenuButton<void>(
      tooltip: l10n.commonMore,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<void>>[
        PopupMenuItem<void>(
          onTap: () => Get.toNamed<void>(AppRoutes.settings),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.homeMenuSettings),
          ),
        ),
        // Not built into a release APK. The console is a developer surface: it puts
        // raw logs, subsystem probes and device facts one tap from the home screen,
        // and a shipped app has no reason to offer that to the person using it. The
        // route is withheld in the same builds (see [AppRoutes.developerTools]), so
        // hiding the entry is not the only thing standing in the way.
        if (!kReleaseMode)
          PopupMenuItem<void>(
            onTap: () => Get.toNamed<void>(AppRoutes.developerTools),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.terminal_outlined),
              title: Text(l10n.homeMenuDeveloperTools),
            ),
          ),
      ],
    );
  }

  /// The grid. `shrinkWrap` because it sits inside the page's scroll view rather than
  /// owning its own — the header, the engine warning and the hint scroll with it, and
  /// the controller already builds every profile eagerly, so nothing lazy is lost.
  ///
  /// One grid serves both the main set and the Private space: entering the space swaps
  /// which profiles it maps, and adds a locked tile to get into it from the main set.
  Widget _grid(BuildContext context) {
    final bool private = controller.viewingPrivate.value;
    final List<VirtualProfileModel> profiles =
        private ? controller.hiddenProfiles : controller.visibleProfiles;

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
        if (!private) AddCloneTile(onTap: _openAddProfile),
        ...profiles.map(
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
            onLongPress: () => _openActions(context, profile, hidden: private),
          ),
        ),
        if (!private && controller.privateSpaceEnabled)
          PrivateSpaceTile(
            hiddenCount: controller.hiddenCount,
            onTap: () => _openPrivateSpace(context),
          ),
      ],
    );
  }

  /// Leaves the Private space and relocks it in the same tap.
  Widget _privateCloseButton(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.homeLockAndClose,
      icon: const Icon(Icons.lock_outline),
      onPressed: () {
        controller.privateSpace.lock();
        controller.exitPrivateSpace();
      },
    );
  }

  /// Opens the Private space, asking for the lock first when it is closed.
  Future<void> _openPrivateSpace(BuildContext context) async {
    if (controller.privateSpace.unlocked.value) {
      controller.enterPrivateSpace();
      return;
    }
    final bool unlocked = await showPrivateSpaceUnlockDialog(
      context,
      controller.privateSpace,
    );
    if (unlocked) {
      controller.enterPrivateSpace();
    }
  }

  /// Sends the user to set up the Private space before hiding their first clone.
  Future<void> _offerPrivateSpaceSetup(BuildContext context) async {
    final bool go = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(context.l10n.homeSetUpPrivateSpaceTitle),
            content: Text(context.l10n.homeSetUpPrivateSpaceMessage),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(context.l10n.commonNotNow),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(context.l10n.homeSetUpPrivateSpaceConfirm),
              ),
            ],
          ),
        ) ??
        false;
    if (!go || !context.mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => PrivateSpaceSettingsView(
          privateSpace: controller.privateSpace,
        ),
      ),
    );
  }

  /// Shown only while there is nothing to launch.
  ///
  /// A panel rather than a line of text: a first run where the grid holds one tinted
  /// square and nothing else reads as a screen that failed to load. The panel says the
  /// app got here on purpose and names the next step.
  Widget _emptyState(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: EmptyState(
        title: l10n.homeEmptyTitle,
        message: l10n.homeEmptyMessage,
        actionLabel: l10n.homeEmptyAction,
        onAction: _openAddProfile,
      ),
    );
  }

  /// Shown when the lock is open but nothing is hidden yet.
  Widget _privateEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: EmptyState(
        icon: Icons.visibility_off_outlined,
        title: context.l10n.homePrivateEmptyTitle,
        message: context.l10n.homePrivateEmptyMessage,
      ),
    );
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
    final AppException? error = await controller.launchProfile(profile);
    if (!context.mounted) {
      return;
    }
    // Only failures are announced. A launch that worked brings the guest to the front,
    // so a message about it lands on top of the app the user is now looking at.
    if (error != null) {
      await _showFailure(context, appErrorMessage(context.l10n, error));
    }
  }

  Future<void> _openActions(
    BuildContext context,
    VirtualProfileModel profile, {
    bool hidden = false,
  }) async {
    // Asked before the sheet opens: a clone whose app depends on Google services reports
    // whether microG is in its container, and offers to install it when it is not.
    final bool requiresGoogleServices =
        controller.requiresGoogleServices(profile);
    final bool googleServicesInstalled = requiresGoogleServices &&
        await controller.googleServicesInstalled(profile);
    if (!context.mounted) {
      return;
    }

    final CloneAction? action = await showCloneActionSheet(
      context,
      profile: profile,
      state: controller.stateFor(profile),
      icon: controller.iconFor(profile),
      siblingCount: controller.siblingCount(profile),
      instanceIndex: controller.instanceIndex(profile),
      hidden: hidden || profile.hidden,
      requiresGoogleServices: requiresGoogleServices,
      googleServicesInstalled: googleServicesInstalled,
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
    // Asked before the stepper is drawn, so the ceiling on offer is one this device can
    // actually deliver. A dialog that offered twenty and then refused five would teach
    // the user not to believe either number.
    final CloneBudget budget = await controller.cloneBudget();
    if (!context.mounted) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    if (budget.allowsNone) {
      // No stepper: every value it could offer is one that would be refused.
      await _showFailure(
        context,
        cloneBudgetRefusal(l10n, budget, profile.appName),
      );
      return;
    }

    final int? count = await showCloneCountDialog(
      context,
      appName: profile.appName,
      maximum: budget.maximum,
      reason: cloneBudgetReason(l10n, budget),
    );
    if (count == null || !context.mounted) {
      return;
    }

    // Each clone is a container install of a few seconds. A barrier that reports its
    // progress is the honest thing to show; a frozen grid would read as a hang.
    final ValueNotifier<String> progress = ValueNotifier<String>(
      l10n.cloneCreating(1, count),
    );
    _showProgress(context, profile, progress);

    final CloneBatchResult result = await controller.createClones(
      profile,
      count,
      // "Finishing" also covers a cancelled batch: the clone in flight when Cancel was
      // tapped still has to land, and naming the next one would promise work that is no
      // longer going to happen.
      onProgress: (int created, int total) => progress.value =
          created >= total || controller.cloneBatchCancelling.value
          ? l10n.cloneCreatingFinishing
          : l10n.cloneCreating(created + 1, total),
    );

    if (!context.mounted) {
      progress.dispose();
      return;
    }
    // Closes the barrier, whose route is the top one.
    Navigator.of(context).pop();
    progress.dispose();

    final String? failure = cloneBatchFailure(l10n, result, profile.appName);
    if (failure != null) {
      await _showFailure(context, failure);
      return;
    }
    // A cancelled batch stops short, so the tally is what actually landed rather than
    // what was asked for. Nothing is said when it landed none: the user stopped it
    // themselves and "0 clones added" tells them only what they already did.
    if (result.created == 0) {
      return;
    }
    _showMessage(context, l10n.cloneAdded(result.created, profile.appName));
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
        // The one way out of a barrier that is not dismissible. Twenty clones is close
        // to a minute, and a user who has changed their mind should not have to wait out
        // a decision they have already reversed. Disabled once asked: the clone being
        // installed still has to finish, and a button that invites a second tap would
        // suggest the first one was missed.
        actions: <Widget>[
          Obx(
            () => TextButton(
              onPressed: controller.cloneBatchCancelling.value
                  ? null
                  : controller.cancelCloneBatch,
              child: Text(context.l10n.commonCancel),
            ),
          ),
        ],
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
        title: Text(context.l10n.cloneForceStopTitle),
        content: Text(context.l10n.cloneForceStopMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.cloneForceStopConfirm),
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
        title: Text(context.l10n.cloneClearCacheTitle),
        content: Text(context.l10n.cloneClearCacheMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.cloneClearCacheConfirm),
          ),
        ],
      ),
    );
  }

  /// Confirms installing microG into an existing clone.
  ///
  /// Not destructive — the clone keeps its data — but it changes which implementation the
  /// clone sees for every Google API, and it takes several seconds, so it is asked rather
  /// than done on a mis-tap.
  Future<bool?> _confirmInstallGoogleServices(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(context.l10n.cloneInstallGoogleServicesTitle),
        content: Text(
          context.l10n.cloneInstallGoogleServicesMessage(AppConstants.appTitle),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.cloneInstallGoogleServicesConfirm),
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
        title: Text(context.l10n.cloneClearStorageTitle),
        content: Text(context.l10n.cloneClearStorageMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.cloneClearStorageConfirm),
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
    final AppLocalizations l10n = context.l10n;

    switch (action) {
      case CloneAction.spaceInfo:
        await _openSpaceInfo(context, profile);
      case CloneAction.forceStop:
        final bool confirmed = await _confirmForceStop(context) ?? false;
        if (!confirmed || !context.mounted) {
          return;
        }
        final AppException? error = await controller.forceStop(profile);
        if (!context.mounted) {
          return;
        }
        if (error != null) {
          await _showFailure(context, appErrorMessage(l10n, error));
        } else {
          _showMessage(context, l10n.cloneStopped(profile.profileName));
        }
      case CloneAction.clearCache:
        final bool confirmed = await _confirmClearCache(context) ?? false;
        if (!confirmed || !context.mounted) {
          return;
        }
        final AppException? error = await controller.clearCache(profile);
        if (!context.mounted) {
          return;
        }
        if (error != null) {
          await _showFailure(context, appErrorMessage(l10n, error));
        } else {
          _showMessage(context, l10n.cloneCacheCleared(profile.profileName));
        }
      case CloneAction.clearStorage:
        // Confirmed: this is every login, message and setting inside the clone, and
        // there is no undo. Uninstall is the only other action that asks.
        final bool confirmed = await _confirmClearStorage(context) ?? false;
        if (!confirmed || !context.mounted) {
          return;
        }
        final AppException? error = await controller.clearStorage(profile);
        if (!context.mounted) {
          return;
        }
        if (error != null) {
          await _showFailure(context, appErrorMessage(l10n, error));
        } else {
          _showMessage(context, l10n.cloneStorageCleared(profile.profileName));
        }
      case CloneAction.toggleHidden:
        if (!controller.privateSpaceEnabled) {
          await _offerPrivateSpaceSetup(context);
          return;
        }
        final bool willHide = !profile.hidden;
        await controller.setHidden(profile, willHide);
        if (context.mounted) {
          _showMessage(
            context,
            willHide
                ? l10n.cloneHidden(profile.profileName)
                : l10n.cloneUnhidden(profile.profileName),
          );
        }
      case CloneAction.shareApp:
        final AppException? error = await controller.shareApp(profile);
        // Only a failure is worth saying: on success the share sheet is already on
        // screen, and a dialog behind it would be talking over the answer.
        if (error != null && context.mounted) {
          await _showFailure(context, appErrorMessage(l10n, error));
        }
      case CloneAction.changeIcon:
        final CloneIconChoice? choice = await showCloneIconPicker(
          context,
          current: profile.iconColor,
          hasCustomIcon: profile.iconPath != null,
        );
        // Null is a dismissal. Every other answer is something the user asked for,
        // including CloneIconColor.none, which clears the mark.
        if (choice == null || !context.mounted) {
          return;
        }
        final AppException? iconError = switch (choice) {
          CloneIconColorChosen(:final CloneIconColor color) =>
            await controller.setIconColor(profile, color),
          CloneIconPictureRequested() => await controller.setCustomIcon(profile),
          CloneIconAppIconRequested() => await controller.clearCustomIcon(profile),
        };
        if (iconError != null && context.mounted) {
          await _showFailure(context, appErrorMessage(l10n, iconError));
        }
      case CloneAction.rename:
        final String? name = await showRenameProfileDialog(
          context,
          currentName: profile.profileName,
        );
        if (name == null || !context.mounted) {
          return;
        }
        final AppException? error = await controller.renameProfile(profile, name);
        if (error != null && context.mounted) {
          await _showFailure(context, appErrorMessage(l10n, error));
        }
      case CloneAction.clone:
        await _cloneAgain(context, profile);
      case CloneAction.addShortcut:
        final AppException? error = await controller.addShortcut(profile);
        if (!context.mounted) {
          return;
        }
        if (error != null) {
          await _showFailure(context, appErrorMessage(l10n, error));
        } else {
          _showMessage(context, l10n.cloneShortcutAdded);
        }
      case CloneAction.permissions:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => ClonePermissionsView(
              controller: controller,
              profile: profile,
            ),
          ),
        );
      case CloneAction.installGoogleServices:
        final bool confirmed =
            await _confirmInstallGoogleServices(context) ?? false;
        if (!confirmed || !context.mounted) {
          return;
        }
        // Installing the bundled artefact takes seconds, so the barrier stays up until
        // the engine answers rather than letting a second tap queue another install.
        final ValueNotifier<String> progress = ValueNotifier<String>(
          l10n.cloneGoogleServicesInstalling,
        );
        _showProgress(context, profile, progress);
        final AppException? error = await controller.installGoogleServices(profile);
        if (!context.mounted) {
          progress.dispose();
          return;
        }
        // Closes the barrier, whose route is the top one.
        Navigator.of(context).pop();
        progress.dispose();
        if (error != null) {
          await _showFailure(context, appErrorMessage(l10n, error));
        } else {
          _showMessage(
            context,
            l10n.cloneGoogleServicesInstalled(profile.profileName),
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
        final AppException? error = await controller.uninstall(profile);
        if (error != null && context.mounted) {
          await _showFailure(context, appErrorMessage(l10n, error));
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
        title: Text(context.l10n.commonFailureTitle),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonOk),
          ),
        ],
      ),
    );
  }
}
