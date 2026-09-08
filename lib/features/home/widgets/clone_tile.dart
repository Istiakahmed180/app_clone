import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/status_colors.dart';
import '../../../data/models/compatibility_report.dart';
import '../../../data/models/engine_result.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../../widgets/app_icon.dart';

/// One clone, as a launcher tile.
///
/// A grid of icons rather than a list of cards, because that is what the thing actually
/// is: a home screen for cloned apps. The trade is that a tile has room for the icon,
/// the name and roughly one more piece of information — so only what changes a decision
/// is drawn on it, and everything else moves into the long-press sheet.
///
/// What earns a place on the tile:
/// * the **instance number**, when more than one clone of the same app exists. Without
///   it two identical icons are indistinguishable.
/// * a **problem marker**, when the app has a compatibility finding or is missing a
///   permission. A clone that will not work has to say so before it is tapped.
/// * a **running dot**, because "is it already open" changes what a tap does.
///
/// Status text, the virtual user id, the full warning and every action live in
/// [showCloneActionSheet].
class CloneTile extends StatelessWidget {
  const CloneTile({
    required this.profile,
    required this.state,
    required this.onTap,
    required this.onLongPress,
    this.icon,
    this.siblingCount = 1,
    this.instanceIndex = 1,
    this.warnings = const <CompatibilityFinding>[],
    this.needsPermissions = false,
    this.canLaunch = true,
    super.key,
  });

  final VirtualProfileModel profile;
  final VirtualProfileState state;
  final Uint8List? icon;

  /// How many clones share this package; >1 means the instance number is shown.
  final int siblingCount;

  /// This clone's 1-based position among those siblings.
  final int instanceIndex;

  final List<CompatibilityFinding> warnings;
  final bool needsPermissions;

  /// False when the engine cannot host containers on this device. The tile is dimmed
  /// but stays interactive: the long-press sheet is the only way to rename or delete a
  /// clone, and losing that because the engine is down would be worse than a dim tile.
  final bool canLaunch;

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// The finding worth drawing. A blocking one wins: it is the difference between
  /// "works, with a caveat" and "will not run".
  CompatibilityFinding? get _marker {
    if (warnings.isEmpty) {
      return null;
    }
    return warnings.firstWhere(
      (CompatibilityFinding finding) => finding.blocking,
      orElse: () => warnings.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(AppTheme.tileRadius.r);
    final CompatibilityFinding? marker = _marker;

    return Semantics(
      button: true,
      label: _semanticLabel(),
      // The label already spells out the name, the instance number, the running dot and
      // the problem marker, so the descendants' own semantics are excluded rather than
      // merged — otherwise a screen reader would read the name twice and the badge and
      // dot not at all. The two gestures are re-declared here because excluding the
      // descendants also excludes the InkWell's.
      excludeSemantics: true,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: radius,
          child: Opacity(
            opacity: canLaunch ? 1 : 0.55,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Stack(
                  children: <Widget>[
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _iconWithRunningDot(context),
                          SizedBox(height: 8.h),
                          Padding(
                            // Keeps a long name clear of the badge in the corner.
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Text(
                              profile.profileName,
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: theme.colorScheme.onSurface),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (siblingCount > 1)
                      Positioned(top: 0, right: 0, child: _InstanceBadge(instanceIndex)),
                    if (marker != null || needsPermissions)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _ProblemMarker(
                          blocking: marker?.blocking ?? false,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The icon, with a presence dot when the engine reports the guest as running.
  Widget _iconWithRunningDot(BuildContext context) {
    final Widget appIcon = AppIcon(bytes: icon, size: 46.r);
    if (!state.running) {
      return appIcon;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        appIcon,
        Positioned(
          right: -2.r,
          bottom: -2.r,
          child: Container(
            width: 12.r,
            height: 12.r,
            decoration: BoxDecoration(
              color: StatusColors.of(context).positive,
              shape: BoxShape.circle,
              // Ringed in the tile's own colour so the dot reads as an overlay on the
              // icon rather than as part of it.
              border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  /// Screen readers get everything the tile encodes visually, since a badge and a
  /// coloured dot are invisible to them.
  String _semanticLabel() {
    final StringBuffer buffer = StringBuffer(profile.profileName);
    if (siblingCount > 1) {
      buffer.write(', clone $instanceIndex of $siblingCount');
    }
    if (state.running) {
      buffer.write(', running');
    }
    final CompatibilityFinding? marker = _marker;
    if (marker != null) {
      buffer.write(marker.blocking ? ', will not run' : ', has a warning');
    } else if (needsPermissions) {
      buffer.write(', needs permissions');
    }
    if (!canLaunch) {
      buffer.write(', cannot be launched on this device');
    }
    return buffer.toString();
  }
}

/// The instance number, for telling two clones of the same app apart.
class _InstanceBadge extends StatelessWidget {
  const _InstanceBadge(this.index);

  final int index;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      alignment: Alignment.center,
      constraints: BoxConstraints(minWidth: 18.r, minHeight: 18.r),
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      decoration: BoxDecoration(
        // The accent at low opacity rather than a second colour: this is identity, not
        // a status, and a grid of tiles already has one accent doing work.
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9.r),
      ),
      child: Text(
        '$index',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Marks a clone whose app has a compatibility problem or a missing permission.
class _ProblemMarker extends StatelessWidget {
  const _ProblemMarker({required this.blocking});

  final bool blocking;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color colour =
        blocking ? scheme.error : StatusColors.of(context).warning;

    return Icon(
      blocking ? Icons.block : Icons.warning_amber_rounded,
      size: 16.r,
      color: colour,
    );
  }
}
