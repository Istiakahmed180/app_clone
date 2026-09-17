import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_context.dart';
import '../../../data/models/compatibility_report.dart';
import '../../../data/models/engine_result.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../../widgets/app_icon.dart';
import '../../apps/widgets/compatibility_text.dart';

/// What the user can ask of one clone.
///
/// No `launch`: tapping the tile does that, and repeating it here would make the sheet
/// a menu for the one thing the user has just stopped short of doing.
enum CloneAction {
  clone,
  addShortcut,
  spaceInfo,
  rename,
  changeIcon,
  forceStop,
  clearCache,
  clearStorage,
  toggleHidden,
  permissions,
  installGoogleServices,
  shareApp,
  delete,
}

/// Everything the user can do to one clone, reached by holding its tile.
///
/// Three bands, in the order the actions are actually reached for:
///
/// * **three primary tiles** — things done *with* a clone: make another, put it on the
///   home screen, look at what it is;
/// * **Manage** — things done *to* it, ordered by cost: harmless (rename), recoverable
///   (force stop, clear cache), then costly (clear storage). The Google services row
///   appears only for a clone whose app needs them and does not have them yet: a clone
///   that already has them needs nothing said;
/// * **Uninstall**, alone below a divider, because it is the only one that destroys the
///   clone itself.
///
/// Returns the chosen action, or null if dismissed.
Future<CloneAction?> showCloneActionSheet(
  BuildContext context, {
  required VirtualProfileModel profile,
  required VirtualProfileState state,
  Uint8List? icon,
  int siblingCount = 1,
  int instanceIndex = 1,
  bool hidden = false,
  bool requiresGoogleServices = false,
  bool googleServicesInstalled = false,
  CompatibilityReport? compatibility,
}) {
  return showModalBottomSheet<CloneAction>(
    context: context,
    // Scroll-controlled and draggable, like the filter sheet: the content grows with the
    // warnings it has to show, and a sheet fixed at half the screen would make the user
    // scroll a small window instead of growing it. Dragging or scrolling up takes it to
    // full height; dragging down past the minimum dismisses it.
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => _CloneActionSheet(
      profile: profile,
      state: state,
      icon: icon,
      siblingCount: siblingCount,
      instanceIndex: instanceIndex,
      hidden: hidden,
      requiresGoogleServices: requiresGoogleServices,
      googleServicesInstalled: googleServicesInstalled,
      compatibility: compatibility,
    ),
  );
}

class _CloneActionSheet extends StatelessWidget {
  const _CloneActionSheet({
    required this.profile,
    required this.state,
    required this.icon,
    required this.siblingCount,
    required this.instanceIndex,
    required this.hidden,
    required this.requiresGoogleServices,
    required this.googleServicesInstalled,
    required this.compatibility,
  });

  final VirtualProfileModel profile;
  final VirtualProfileState state;
  final Uint8List? icon;
  final int siblingCount;
  final int instanceIndex;
  final bool hidden;

  /// Whether this clone's app depends on Google services. Only then is the install row
  /// ever offered — see `HomeController.requiresGoogleServices`.
  final bool requiresGoogleServices;

  /// Whether the container already carries them. When it does the sheet says nothing at
  /// all; the install row is offered only while they are missing.
  final bool googleServicesInstalled;

  /// What the analyzer last said about this clone's app, or null when it could not be
  /// asked. Only the blocking findings are shown -- see [_blockers].
  final CompatibilityReport? compatibility;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      // Same shape as the filter sheet: it opens part-way, grows to the top as the user
      // scrolls past the content, and can be dragged down to dismiss. A plain
      // scroll-controlled sheet sized to this much content instead pinned itself to the
      // top of the screen and could not be dragged away.
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 1,
      snap: true,
      snapSizes: const <double>[0.72],
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) => Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              // The sheet's own controller, so dragging/scrolling past the top moves the
              // sheet rather than stopping dead at the content's edge.
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                20.w,
                8.h,
                20.w,
                16.h + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _DragHandle(),
                  _header(context),
                  ..._findings(context),
                  SizedBox(height: 20.h),
                  _primaryRow(context),
                  SizedBox(height: 24.h),
                  Text(
                    context.l10n.cloneActionsManage,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: 10.h),
                  _manageGrid(context),
                  SizedBox(height: 18.h),
                  const Divider(height: 1),
                  SizedBox(height: 14.h),
                  _ActionRow(
                    action: CloneAction.delete,
                    icon: Icons.delete_outline,
                    label: context.l10n.cloneActionUninstall,
                    destructive: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// What the analyzer found about this clone's app, worst first.
  ///
  /// A clone is only ever made from an app the picker judged clonable, so a **blocking**
  /// finding here means the host's copy changed underneath the clone — most plainly that
  /// the app was uninstalled, because a container holds no copy of the APK, only a record
  /// pointing at the host's. The clone's own data survives and comes back if the app is
  /// reinstalled, but until then it cannot start, and nothing else in the app said why:
  /// the tile looked ordinary, the sheet offered every action, and the launch failed.
  ///
  /// The rest are limitations the clone is already running with. They are shown too, and
  /// more quietly, because the useful one is not a complaint but an instruction — that
  /// shared storage needs All files access granted to the host before the clone can reach
  /// any files — and the only place it was ever said is the picker, which the user passed
  /// through once, before this clone existed.
  List<Widget> _findings(BuildContext context) {
    final List<CompatibilityFinding> findings =
        compatibility?.findings ?? const <CompatibilityFinding>[];
    final List<CompatibilityFinding> blocking = findings
        .where((CompatibilityFinding finding) => finding.blocking)
        .toList(growable: false);
    final List<CompatibilityFinding> cautions = findings
        .where((CompatibilityFinding finding) => !finding.blocking)
        .toList(growable: false);
    if (blocking.isEmpty && cautions.isEmpty) {
      return const <Widget>[];
    }

    final ThemeData theme = Theme.of(context);
    return <Widget>[
      SizedBox(height: 16.h),
      if (blocking.isNotEmpty)
        _FindingBlock(
          icon: Icons.error_outline,
          background: theme.colorScheme.errorContainer,
          foreground: theme.colorScheme.onErrorContainer,
          findings: blocking,
        ),
      if (blocking.isNotEmpty && cautions.isNotEmpty) SizedBox(height: 8.h),
      if (cautions.isNotEmpty)
        _FindingBlock(
          icon: Icons.info_outline,
          background: theme.colorScheme.surfaceContainerHighest,
          foreground: theme.colorScheme.onSurfaceVariant,
          findings: cautions,
        ),
    ];
  }

  Widget _header(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        AppIcon(bytes: icon, size: 52.r, onPlate: true),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                profile.profileName,
                style: theme.textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                // "Space 2" rather than the app name again: every clone is named after
                // its app, so this line's only job is to say *which* one this is.
                context.l10n.cloneSpaceLabel(instanceIndex),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: context.l10n.commonClose,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _primaryRow(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Row(
      children: <Widget>[
        Expanded(
          child: _PrimaryTile(
            action: CloneAction.clone,
            icon: Icons.copy_all_outlined,
            label: l10n.cloneActionClone,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PrimaryTile(
            action: CloneAction.addShortcut,
            icon: Icons.add_box_outlined,
            label: l10n.cloneActionShortcut,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PrimaryTile(
            action: CloneAction.spaceInfo,
            icon: Icons.info_outline,
            label: l10n.cloneActionSpaceInfo,
          ),
        ),
      ],
    );
  }

  /// Two per row, in increasing cost, with Share on its own line.
  ///
  /// Force stop is offered whatever the engine reports about `running`: that flag comes
  /// from the backend and is not always right, so greying it out would leave a stuck
  /// clone with no way to be stopped.
  Widget _manageGrid(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _ActionRow(
                action: CloneAction.rename,
                icon: Icons.edit_outlined,
                label: l10n.cloneActionEditName,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _ActionRow(
                action: CloneAction.changeIcon,
                icon: Icons.palette_outlined,
                label: l10n.cloneActionChangeIcon,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: <Widget>[
            Expanded(
              child: _ActionRow(
                action: CloneAction.forceStop,
                icon: Icons.highlight_off,
                label: l10n.cloneActionForceStop,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _ActionRow(
                action: CloneAction.clearCache,
                icon: Icons.cleaning_services_outlined,
                label: l10n.cloneActionClearCache,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: <Widget>[
            Expanded(
              child: _ActionRow(
                action: CloneAction.clearStorage,
                icon: Icons.storage_outlined,
                label: l10n.cloneActionClearStorage,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _ActionRow(
                action: CloneAction.toggleHidden,
                icon: hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                label: hidden ? l10n.cloneActionUnhide : l10n.cloneActionHide,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: <Widget>[
            Expanded(
              child: _ActionRow(
                action: CloneAction.shareApp,
                icon: Icons.share_outlined,
                label: l10n.cloneActionShareApp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _ActionRow(
                action: CloneAction.permissions,
                icon: Icons.admin_panel_settings_outlined,
                label: l10n.cloneActionPermissions,
              ),
            ),
          ],
        ),
        // Full width on its own line: the label does not fit the two-column grid without
        // being ellipsised. Offered only while it is missing -- a clone that already has
        // it needs nothing said, and naming what provides it is not the user's business.
        if (requiresGoogleServices && !googleServicesInstalled) ...<Widget>[
          SizedBox(height: 12.h),
          _ActionRow(
            action: CloneAction.installGoogleServices,
            icon: Icons.cloud_download_outlined,
            label: l10n.cloneActionInstallGoogleServices,
          ),
        ],
      ],
    );
  }
}

/// One of the three square actions at the top: icon above label.
class _PrimaryTile extends StatelessWidget {
  const _PrimaryTile({
    required this.action,
    required this.icon,
    required this.label,
  });

  final CloneAction action;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(AppTheme.cardRadius.r);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(action),
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Column(
              children: <Widget>[
                Icon(icon, size: 22.r, color: theme.colorScheme.primary),
                SizedBox(height: 10.h),
                Text(
                  label,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A bordered row: icon beside label. Used for the Manage actions and for Uninstall.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.action,
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final CloneAction action;
  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(AppTheme.cardRadius.r);
    final Color tint =
        destructive ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(action),
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            // The destructive action is outlined in its own colour: it sits alone below
            // a divider and still has to be unmistakable at a glance.
            border: Border.all(
              color: destructive
                  ? theme.colorScheme.error
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 20.r,
                  color: destructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(color: tint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The pill at the top of a draggable sheet, so it reads as something that can be pulled.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Container(
        width: 40.w,
        height: 4.h,
        margin: EdgeInsets.only(bottom: 18.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
    );
  }
}

/// One severity's worth of findings, in a tinted block.
class _FindingBlock extends StatelessWidget {
  const _FindingBlock({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.findings,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final List<CompatibilityFinding> findings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18.r, color: foreground),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int i = 0; i < findings.length; i++) ...<Widget>[
                  if (i > 0) SizedBox(height: 6.h),
                  Text(
                    compatibilityFindingMessage(context.l10n, findings[i]),
                    style: theme.textTheme.bodySmall?.copyWith(color: foreground),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
