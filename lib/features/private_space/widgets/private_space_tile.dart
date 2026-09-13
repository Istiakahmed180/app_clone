import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_theme.dart';

/// The locked door to the Private space, shown on the main grid once the lock exists.
///
/// Deliberately not a live preview of the hidden clones: the tile is on the main grid,
/// which is what the user hands to someone else, so it must not leak how many apps are
/// behind it beyond a plain count — and it shows even when that count is zero, because
/// otherwise the only way back into the space would be through Settings.
class PrivateSpaceTile extends StatelessWidget {
  const PrivateSpaceTile({
    required this.hiddenCount,
    required this.onTap,
    super.key,
  });

  final int hiddenCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(AppTheme.tileRadius.r);

    return Semantics(
      button: true,
      label: hiddenCount == 0
          ? 'Private space, empty'
          : 'Private space, $hiddenCount hidden',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Stack(
              children: <Widget>[
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 46.r,
                        height: 46.r,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 24.r,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Text(
                          'Private space',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hiddenCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      alignment: Alignment.center,
                      constraints: BoxConstraints(minWidth: 18.r, minHeight: 18.r),
                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9.r),
                      ),
                      child: Text(
                        '$hiddenCount',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
