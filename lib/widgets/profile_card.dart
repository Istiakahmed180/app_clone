import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/models/engine_result.dart';
import '../data/models/virtual_profile_model.dart';

enum ProfileCardAction { rename, delete }

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.profile,
    required this.state,
    required this.canLaunch,
    required this.onLaunch,
    required this.onAction,
    super.key,
  });

  final VirtualProfileModel profile;
  final VirtualProfileState state;
  final bool canLaunch;
  final VoidCallback onLaunch;
  final ValueChanged<ProfileCardAction> onAction;

  /// Status is derived from what the engine reports, never assumed from the fact that
  /// a profile row exists.
  ({String label, Color color}) _status(ColorScheme scheme) {
    if (state.running) {
      return (label: 'Running', color: scheme.primary);
    }
    if (state.installed) {
      return (label: 'Ready', color: scheme.tertiary);
    }
    return (label: 'Not installed', color: scheme.error);
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(profile.appName, style: theme.textTheme.titleMedium),
                      SizedBox(height: 2.h),
                      Text(
                        profile.profileName,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<ProfileCardAction>(
                  onSelected: onAction,
                  itemBuilder: (BuildContext context) =>
                      const <PopupMenuEntry<ProfileCardAction>>[
                    PopupMenuItem<ProfileCardAction>(
                      value: ProfileCardAction.rename,
                      child: Text('Rename'),
                    ),
                    PopupMenuItem<ProfileCardAction>(
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
                final ({String label, Color color}) status = _status(theme.colorScheme);
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
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: FilledButton.tonalIcon(
                  onPressed: canLaunch ? onLaunch : null,
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
