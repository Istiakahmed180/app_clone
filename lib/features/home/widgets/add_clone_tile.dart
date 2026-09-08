import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_theme.dart';

/// The tinted square that starts a new clone.
///
/// It sits in the grid as its first cell rather than floating over it, so it scrolls
/// with the clones and never covers the last one. That is why there is no floating
/// action button on this screen.
class AddCloneTile extends StatelessWidget {
  const AddCloneTile({required this.onTap, this.label = 'Add app', super.key});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(AppTheme.tileRadius.r);

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: theme.colorScheme.primaryContainer,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          // No fixed size: the tile is the first cell of the clone grid, so the grid
          // decides how big it is and it stays the same size as every icon beside it.
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: theme.colorScheme.primary, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 46.r,
                  height: 46.r,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    size: 26.r,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
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
