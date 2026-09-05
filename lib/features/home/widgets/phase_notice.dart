import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Permanent, non-dismissible statement of what Phase 1 actually does.
class PhaseNotice extends StatelessWidget {
  const PhaseNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, size: 20.r, color: theme.colorScheme.onTertiaryContainer),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'This is the Phase 1 demo launcher. The application is not yet '
              'virtualized — every profile opens the same real installed app and '
              'shares its state.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
