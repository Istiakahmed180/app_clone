import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/status_colors.dart';
import '../../../data/models/engine_result.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../../widgets/app_icon.dart';

/// One clone, as a launcher tile.
///
/// A grid of icons rather than a list of cards, because that is what the thing actually
/// is: a home screen for cloned apps. A tile has room for the icon, the name and
/// roughly one more mark, so it carries only:
///
/// * the **instance number**, when more than one clone of the same app exists. Without
///   it two identical icons are indistinguishable.
/// * a **running dot**, because "is it already open" changes what a tap does.
///
/// Everything else — the engine status, the virtual user id, compatibility warnings,
/// missing permissions and every action — lives in [showCloneActionSheet], reached by
/// holding the tile. Compatibility problems deliberately do **not** appear here: the
/// grid is meant to read as a home screen, and a warning badge on every tile made it
/// read as a list of faults.
class CloneTile extends StatelessWidget {
  const CloneTile({
    required this.profile,
    required this.state,
    required this.onTap,
    required this.onLongPress,
    this.icon,
    this.siblingCount = 1,
    this.instanceIndex = 1,
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

  /// False when the engine cannot host containers on this device. The tile is dimmed
  /// but stays interactive: the long-press sheet is the only way to rename or delete a
  /// clone, and losing that because the engine is down would be worse than a dim tile.
  final bool canLaunch;

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(AppTheme.tileRadius.r);

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
                          SizedBox(height: 6.h),
                          Padding(
                            // Keeps a long name clear of the badge in the corner.
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Text(
                              profile.profileName,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                              // Two lines: a real app name is often too long for one at
                              // a third of the screen's width, and 'CABEX-FXsa…' names
                              // nothing. The icon gives up the height for it.
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (siblingCount > 1)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _InstanceBadge(instanceIndex),
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
    final Widget appIcon = AppIcon(bytes: icon, size: 46.r, onPlate: true);
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
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              ),
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
