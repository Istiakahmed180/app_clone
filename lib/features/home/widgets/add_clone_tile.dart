import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_theme.dart';

/// The tinted square that starts a new clone.
///
/// It sits in the content rather than floating over it, so it scrolls with the list and
/// never covers the last card. That is the trade the reference layout makes, and it is
/// why there is no floating action button on this screen.
class AddCloneTile extends StatelessWidget {
  const AddCloneTile({required this.onTap, this.label = 'Add clone', super.key});

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
          child: Ink(
            width: 104.w,
            height: 112.h,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: theme.colorScheme.primary, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 52.r,
                  height: 52.r,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    size: 28.r,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(label, style: theme.textTheme.titleSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
