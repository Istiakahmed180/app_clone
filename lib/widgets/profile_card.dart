import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'dart:typed_data';

import '../data/models/compatibility_report.dart';
import '../data/models/engine_result.dart';
import '../data/models/virtual_profile_model.dart';
import '../app/theme/status_colors.dart';
import 'app_icon.dart';

enum ProfileCardAction { grantPermissions, rename, clone, addShortcut, delete }

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.profile,
    required this.state,
    required this.canLaunch,
    required this.onLaunch,
    required this.onAction,
    this.icon,
    this.siblingCount = 1,
    this.instanceIndex = 1,
    this.warnings = const <CompatibilityFinding>[],
    this.needsPermissions = false,
    super.key,
  });

  final VirtualProfileModel profile;
  final VirtualProfileState state;
  final Uint8List? icon;

  /// How many clones share this package; >1 means the user has multiple instances.
  final int siblingCount;

  /// This clone's 1-based position among those siblings.
  final int instanceIndex;

  /// Compatibility problems affecting this clone's app, if any.
  final List<CompatibilityFinding> warnings;

  /// Whether this clone's app needs runtime permissions the host does not hold yet.
  ///
  /// The card already warns about it, but a warning with no way to act on it is a dead end:
  /// the guest silently gets nothing (VLC, for example, sits on "Loading." forever with no
  /// media). When true, the menu offers granting them.
  final bool needsPermissions;
  final bool canLaunch;
  final VoidCallback onLaunch;
  final ValueChanged<ProfileCardAction> onAction;

  /// Status is derived from what the engine reports, never assumed from the fact that
  /// a profile row exists.
  ({String label, Color color}) _status(ColorScheme scheme, StatusColors status) {
    if (state.running) {
      return (label: 'Running', color: scheme.primary);
    }
    if (state.installed) {
      return (label: 'Ready', color: status.positive);
    }
    // The container is missing, but launching rebuilds it, so this is not an error.
    return (label: 'Rebuilds on launch', color: scheme.outline);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppIcon(bytes: icon, size: 44.r),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        profile.profileName,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        siblingCount > 1
                            ? '${profile.appName} · clone $instanceIndex of $siblingCount'
                            : profile.appName,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<ProfileCardAction>(
                  onSelected: onAction,
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<ProfileCardAction>>[
                    if (needsPermissions)
                      const PopupMenuItem<ProfileCardAction>(
                        value: ProfileCardAction.grantPermissions,
                        child: Text('Grant permissions'),
                      ),
                    const PopupMenuItem<ProfileCardAction>(
                      value: ProfileCardAction.rename,
                      child: Text('Rename'),
                    ),
                    const PopupMenuItem<ProfileCardAction>(
                      value: ProfileCardAction.clone,
                      child: Text('Add another clone'),
                    ),
                    const PopupMenuItem<ProfileCardAction>(
                      value: ProfileCardAction.addShortcut,
                      child: Text('Add to home screen'),
                    ),
                    const PopupMenuItem<ProfileCardAction>(
                      value: ProfileCardAction.delete,
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Builder(
              builder: (BuildContext context) {
                final ({String label, Color color}) status =
                    _status(theme.colorScheme, StatusColors.of(context));
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.circle, size: 10.r, color: status.color),
                    SizedBox(width: 6.w),
                    Text(status.label, style: theme.textTheme.labelLarge),
                    if (state.virtualUserId != null) ...<Widget>[
                      SizedBox(width: 8.w),
                      Text(
                        'user ${state.virtualUserId}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                );
              },
            ),
            if (warnings.isNotEmpty) ...<Widget>[
              SizedBox(height: 8.h),
              _Warning(finding: warnings.firstWhere(
                (CompatibilityFinding f) => f.blocking,
                orElse: () => warnings.first,
              )),
            ],
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: FilledButton.tonalIcon(
                  onPressed: canLaunch ? onLaunch : null,
                  // Compact: the theme's pill padding is sized for a screen's main call
                  // to action, and this one sits inside a card next to two others.
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Launch'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// A single compatibility problem shown on a clone's card.
class _Warning extends StatelessWidget {
  const _Warning({required this.finding});

  final CompatibilityFinding finding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color colour =
        finding.blocking ? scheme.error : StatusColors.of(context).warning;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          finding.blocking ? Icons.block : Icons.warning_amber_outlined,
          size: 16.r,
          color: colour,
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            finding.message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colour),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
