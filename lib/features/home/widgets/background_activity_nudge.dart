import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_context.dart';

/// Tells the user why a closed clone goes quiet, while that is still news.
///
/// The Settings row reports the state and offers the fix, but nobody opens Settings to
/// discover a problem they have not noticed yet. This is the one nudge that teaches: it
/// appears on the grid only once there is a clone to lose notifications for and Android
/// has actually restricted the app, says what that costs, and then it is gone for good --
/// either because the user allowed it or because they waved it away.
class BackgroundActivityNudge extends StatelessWidget {
  const BackgroundActivityNudge({
    required this.onAllow,
    required this.onDismiss,
    super.key,
  });

  final VoidCallback onAllow;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 4.w, 10.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.notifications_active_outlined,
            size: 20.r,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.homeBackgroundNudgeTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  // "Make sure" rather than "Allow": on the builds whose switch the app
                  // cannot read, this may already be on, and an instruction to change a
                  // setting that is already correct reads as a bug.
                  l10n.homeBackgroundNudgeMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: <Widget>[
              TextButton(
                onPressed: onAllow,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  minimumSize: Size(0, 32.h),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.homeBackgroundNudgeAllow),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
                iconSize: 16.sp,
                visualDensity: VisualDensity.compact,
                color: theme.colorScheme.onSecondaryContainer,
                tooltip: l10n.homeBackgroundNudgeDismiss,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
