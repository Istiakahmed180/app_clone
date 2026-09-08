import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/status_colors.dart';
import '../../../data/models/compatibility_report.dart';
import '../../../data/models/engine_result.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../../widgets/app_icon.dart';

/// What "Space info" opens: everything known about one clone, and the one action that
/// belongs with it.
///
/// This screen exists because the tile deliberately carries no warning marker and the
/// action sheet carries no status line — both were making a home screen look like a
/// fault list. The facts still have to live somewhere reachable, and this is it: the
/// engine's own verdict on the container, the compatibility findings in full, and
/// "Grant permissions", which is the only fix a user can actually apply from here.
///
/// Returns true when the user asked to grant permissions.
Future<bool> showSpaceInfoSheet(
  BuildContext context, {
  required VirtualProfileModel profile,
  required VirtualProfileState state,
  Uint8List? icon,
  int siblingCount = 1,
  int instanceIndex = 1,
  List<CompatibilityFinding> warnings = const <CompatibilityFinding>[],
  bool needsPermissions = false,
  bool engineActive = true,
}) async {
  final bool? grant = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => _SpaceInfoSheet(
      profile: profile,
      state: state,
      icon: icon,
      siblingCount: siblingCount,
      instanceIndex: instanceIndex,
      warnings: warnings,
      needsPermissions: needsPermissions,
      engineActive: engineActive,
    ),
  );
  return grant ?? false;
}

class _SpaceInfoSheet extends StatelessWidget {
  const _SpaceInfoSheet({
    required this.profile,
    required this.state,
    required this.icon,
    required this.siblingCount,
    required this.instanceIndex,
    required this.warnings,
    required this.needsPermissions,
    required this.engineActive,
  });

  final VirtualProfileModel profile;
  final VirtualProfileState state;
  final Uint8List? icon;
  final int siblingCount;
  final int instanceIndex;
  final List<CompatibilityFinding> warnings;
  final bool needsPermissions;
  final bool engineActive;

  /// Status is derived from what the engine reports, never assumed from the fact that
  /// a profile row exists.
  ({String label, Color color}) _status(ColorScheme scheme, StatusColors status) {
    if (!engineActive) {
      return (label: 'Engine unavailable', color: scheme.error);
    }
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
    final ({String label, Color color}) status =
        _status(theme.colorScheme, StatusColors.of(context));

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
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
                      SizedBox(height: 4.h),
                      Row(
                        children: <Widget>[
                          Icon(Icons.circle, size: 9.r, color: status.color),
                          SizedBox(width: 6.w),
                          Text(status.label, style: theme.textTheme.labelMedium),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            if (warnings.isNotEmpty) ...<Widget>[
              // Every finding, blocking first: they are the ones that decide whether it
              // runs at all.
              for (final CompatibilityFinding finding in _orderedWarnings)
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _Warning(finding: finding),
                ),
              SizedBox(height: 8.h),
            ],
            if (needsPermissions) ...<Widget>[
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.lock_open_outlined),
                  label: const Text('Grant permissions'),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                // Said plainly, because it surprises people: a clone has no identity of
                // its own to grant anything to.
                'Clones run under Duplika\'s identity, so these are granted to Duplika '
                'itself and apply to every clone.',
                style: theme.textTheme.bodySmall,
              ),
              SizedBox(height: 20.h),
            ],
            const Divider(height: 1),
            SizedBox(height: 12.h),
            _fact(theme, 'App', profile.appName),
            _fact(theme, 'Package', profile.packageName),
            _fact(theme, 'Space', '$instanceIndex of $siblingCount'),
            _fact(
              theme,
              'Container',
              state.virtualUserId == null
                  ? 'not allocated yet'
                  : 'virtual user ${state.virtualUserId}',
            ),
            _fact(theme, 'Created', _formatDate(profile.createdAt)),
            _fact(theme, 'Profile id', profile.id),
          ],
        ),
      ),
    );
  }

  List<CompatibilityFinding> get _orderedWarnings => <CompatibilityFinding>[
        ...warnings.where((CompatibilityFinding f) => f.blocking),
        ...warnings.where((CompatibilityFinding f) => !f.blocking),
      ];

  Widget _fact(ThemeData theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96.w,
            child: Text(
              label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          // Selectable: a package name or profile id is something people paste into an
          // adb command or a bug report.
          Expanded(child: SelectableText(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  static String _formatDate(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}

/// One compatibility problem, in full.
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
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            finding.message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colour),
          ),
        ),
      ],
    );
  }
}
