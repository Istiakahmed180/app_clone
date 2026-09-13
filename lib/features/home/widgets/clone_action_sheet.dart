import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_theme.dart';
import '../../../data/models/compatibility_report.dart';
import '../../../data/models/engine_result.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../../widgets/app_icon.dart';

/// What the user can ask of one clone.
///
/// No `launch`: tapping the tile does that, and repeating it here would make the sheet
/// a menu for the one thing the user has just stopped short of doing.
enum CloneAction {
  clone,
  addShortcut,
  spaceInfo,
  rename,
  forceStop,
  clearCache,
  clearStorage,
  toggleHidden,
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
///   (force stop, clear cache), then costly (clear storage);
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
  List<CompatibilityFinding> findings = const <CompatibilityFinding>[],
}) {
  return showModalBottomSheet<CloneAction>(
    context: context,
    // Scroll-controlled and scrollable inside: nine actions plus a header do not fit a
    // bottom sheet's default half-screen budget, and fit even less at a large text
    // scale or in landscape.
    isScrollControlled: true,
    builder: (BuildContext context) => _CloneActionSheet(
      profile: profile,
      state: state,
      icon: icon,
      siblingCount: siblingCount,
      instanceIndex: instanceIndex,
      hidden: hidden,
      findings: findings,
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
    required this.findings,
  });

  final VirtualProfileModel profile;
  final VirtualProfileState state;
  final Uint8List? icon;
  final int siblingCount;
  final int instanceIndex;
  final bool hidden;
  final List<CompatibilityFinding> findings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _header(context),
            SizedBox(height: 20.h),
            _primaryRow(),
            if (findings.isNotEmpty) ...<Widget>[
              SizedBox(height: 24.h),
              Text('Compatibility', style: Theme.of(context).textTheme.titleSmall),
              SizedBox(height: 10.h),
              _findings(context),
            ],
            SizedBox(height: 24.h),
            Text('Manage', style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: 10.h),
            _manageGrid(),
            SizedBox(height: 18.h),
            const Divider(height: 1),
            SizedBox(height: 14.h),
            const _ActionRow(
              action: CloneAction.delete,
              icon: Icons.delete_outline,
              label: 'Uninstall',
              destructive: true,
            ),
          ],
        ),
      ),
    );
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
                'Space $instanceIndex',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _primaryRow() {
    return const Row(
      children: <Widget>[
        Expanded(
          child: _PrimaryTile(
            action: CloneAction.clone,
            icon: Icons.copy_all_outlined,
            label: 'Clone',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _PrimaryTile(
            action: CloneAction.addShortcut,
            icon: Icons.add_box_outlined,
            label: 'Shortcut',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _PrimaryTile(
            action: CloneAction.spaceInfo,
            icon: Icons.info_outline,
            label: 'Space info',
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
  /// The findings for this clone, blocking first, worded exactly as the pre-clone sheet
  /// words them.
  ///
  /// Shown here rather than on the tile because the tile deliberately stays clean: the grid
  /// is meant to read as a home screen, and this is where a held icon says what is wrong.
  Widget _findings(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<CompatibilityFinding> ordered = findings.toList()
      ..sort(
        (CompatibilityFinding a, CompatibilityFinding b) =>
            (b.blocking ? 1 : 0).compareTo(a.blocking ? 1 : 0),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final CompatibilityFinding finding in ordered)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  finding.blocking ? Icons.block : Icons.warning_amber_outlined,
                  size: 18.r,
                  color: finding.blocking
                      ? theme.colorScheme.error
                      : theme.colorScheme.tertiary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    finding.message,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _manageGrid() {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: _ActionRow(
                action: CloneAction.rename,
                icon: Icons.edit_outlined,
                label: 'Edit name',
              ),
            ),
            SizedBox(width: 12.w),
            const Expanded(
              child: _ActionRow(
                action: CloneAction.forceStop,
                icon: Icons.highlight_off,
                label: 'Force stop',
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: <Widget>[
            const Expanded(
              child: _ActionRow(
                action: CloneAction.clearCache,
                icon: Icons.cleaning_services_outlined,
                label: 'Clear cache',
              ),
            ),
            SizedBox(width: 12.w),
            const Expanded(
              child: _ActionRow(
                action: CloneAction.clearStorage,
                icon: Icons.storage_outlined,
                label: 'Clear storage',
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: <Widget>[
            Expanded(
              child: _ActionRow(
                action: CloneAction.toggleHidden,
                icon: hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                label: hidden ? 'Unhide' : 'Hide',
              ),
            ),
            SizedBox(width: 12.w),
            const Expanded(
              child: _ActionRow(
                action: CloneAction.shareApp,
                icon: Icons.share_outlined,
                label: 'Share app',
              ),
            ),
          ],
        ),
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
