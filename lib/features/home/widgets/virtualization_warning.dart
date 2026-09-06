import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shown only when the engine cannot deliver isolated containers on this device.
///
/// Nothing is drawn on the healthy path: a banner restating that the app works is
/// clutter on every launch, and it trains people to skip the one case that matters.
/// When virtualization is degraded, clones cannot run, and a launch failure with no
/// explanation reads as a broken app rather than an unsupported device.
class VirtualizationWarning extends StatelessWidget {
  const VirtualizationWarning({
    required this.virtualizationActive,
    this.problem,
    super.key,
  });

  final bool virtualizationActive;

  /// What the native backend said, when it said anything.
  final String? problem;

  @override
  Widget build(BuildContext context) {
    if (virtualizationActive) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.warning_amber_outlined,
            size: 20.r,
            color: theme.colorScheme.onErrorContainer,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              problem ??
                  'The virtualization engine is not active on this device, so clones '
                      'cannot run in isolated containers.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
