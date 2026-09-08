import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/status_colors.dart';
import '../../../data/models/compatibility_report.dart';
import '../../../data/models/engine_result.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../../widgets/app_icon.dart';

/// What the user can ask of one clone.
enum CloneAction {
  launch,
  grantPermissions,
  rename,
  clone,
  addShortcut,
  delete,
}

/// Everything about one clone that does not fit on its tile.
///
/// A tile can hold an icon, a name and one marker. The status the engine reports, the
/// virtual user id, the full text of a compatibility finding and the five actions all
/// have to live somewhere, and a sheet is where a launcher grid puts them — reached the
/// way people already expect on a home screen, by holding the icon.
///
/// Returns the chosen action, or null if dismissed.
Future<CloneAction?> showCloneActionSheet(
  BuildContext context, {
  required VirtualProfileModel profile,
  required VirtualProfileState state,
  Uint8List? icon,
  int siblingCount = 1,
  int instanceIndex = 1,
  List<CompatibilityFinding> warnings = const <CompatibilityFinding>[],
  bool needsPermissions = false,
  bool canLaunch = true,
}) {
  return showModalBottomSheet<CloneAction>(
    context: context,
    showDragHandle: true,
    // Scroll-controlled and scrollable inside: the header, up to three findings and six
    // actions do not fit a bottom sheet's default half-screen budget, and they fit even
    // less at a large text scale or in landscape.
    isScrollControlled: true,
    builder: (BuildContext context) => _CloneActionSheet(
      profile: profile,
      state: state,
      icon: icon,
      siblingCount: siblingCount,
      instanceIndex: instanceIndex,
      warnings: warnings,
      needsPermissions: needsPermissions,
      canLaunch: canLaunch,
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
    required this.warnings,
    required this.needsPermissions,
    required this.canLaunch,
  });

  final VirtualProfileModel profile;
  final VirtualProfileState state;
  final Uint8List? icon;
  final int siblingCount;
  final int instanceIndex;
  final List<CompatibilityFinding> warnings;
  final bool needsPermissions;
  final bool canLaunch;

  /// Status is derived from what the engine reports, never assumed from the fact that
  /// a profile row exists.
  ({String label, Color color}) _status(
    ColorScheme scheme,
    StatusColors status,
  ) {
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
    final ({String label, Color color}) status = _status(
      theme.colorScheme,
      StatusColors.of(context),
    );

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
              child: Row(
                children: <Widget>[
                  AppIcon(bytes: icon, size: 44.r),
                  SizedBox(width: 14.w),
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
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: <Widget>[
                            Icon(Icons.circle, size: 9.r, color: status.color),
                            SizedBox(width: 6.w),
                            Text(
                              status.label,
                              style: theme.textTheme.labelMedium,
                            ),
                            if (state.virtualUserId != null) ...<Widget>[
                              SizedBox(width: 8.w),
                              Text(
                                'user ${state.virtualUserId}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (warnings.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
                // Every finding, not just the worst one. The tile already showed that
                // there is a problem; this is the screen where the detail belongs.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final CompatibilityFinding finding in _orderedWarnings)
                      Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: _Warning(finding: finding),
                      ),
                  ],
                ),
              ),
            const Divider(height: 1),
            _action(
              context,
              CloneAction.launch,
              Icons.play_arrow_rounded,
              'Launch',
              enabled: canLaunch,
              subtitle: canLaunch
                  ? null
                  : 'The virtualization engine is not active on this device.',
            ),
            if (needsPermissions)
              _action(
                context,
                CloneAction.grantPermissions,
                Icons.lock_open_outlined,
                'Grant permissions',
                // Guests run under the host's identity, so this is the only place the
                // grant can land — and without it the clone silently gets nothing.
                subtitle: 'Ask for the permissions this app needs',
              ),
            _action(context, CloneAction.rename, Icons.edit_outlined, 'Rename'),
            _action(
              context,
              CloneAction.clone,
              Icons.control_point_duplicate_outlined,
              'Add another clone',
            ),
            _action(
              context,
              CloneAction.addShortcut,
              Icons.add_to_home_screen_outlined,
              'Add to home screen',
            ),
            _action(
              context,
              CloneAction.delete,
              Icons.delete_outline,
              'Delete',
              destructive: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Blocking findings first: they are the ones that decide whether it runs at all.
  List<CompatibilityFinding> get _orderedWarnings => <CompatibilityFinding>[
    ...warnings.where((CompatibilityFinding f) => f.blocking),
    ...warnings.where((CompatibilityFinding f) => !f.blocking),
  ];

  Widget _action(
    BuildContext context,
    CloneAction action,
    IconData icon,
    String label, {
    String? subtitle,
    bool enabled = true,
    bool destructive = false,
  }) {
    final ThemeData theme = Theme.of(context);
    final Color? colour = destructive ? theme.colorScheme.error : null;

    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: colour),
      title: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(color: colour),
      ),
      subtitle: subtitle == null ? null : Text(subtitle),
      onTap: () => Navigator.of(context).pop(action),
    );
  }
}

/// One compatibility problem, in full.
class _Warning extends StatelessWidget {
  const _Warning({required this.finding});

  final CompatibilityFinding finding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color colour = finding.blocking
        ? scheme.error
        : StatusColors.of(context).warning;

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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colour),
          ),
        ),
      ],
    );
  }
}
