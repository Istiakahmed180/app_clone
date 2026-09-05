import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Permanent, non-dismissible statement of what the current build actually does.
///
/// The text is driven by what the native engine reports, so the app never advertises
/// virtualization it is not delivering on this device.
class PhaseNotice extends StatelessWidget {
  const PhaseNotice({
    required this.virtualizationActive,
    this.problem,
    super.key,
  });

  final bool virtualizationActive;
  final String? problem;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool degraded = !virtualizationActive;
    final String text = virtualizationActive
        ? 'Clones run in real virtual containers. Each clone keeps its own isolated '
            'application data, separate from the normal install and from other clones.'
        : problem ??
            'The virtualization engine is not active on this device, so profiles '
            'cannot run in isolated containers.';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: degraded
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            degraded ? Icons.warning_amber_outlined : Icons.verified_user_outlined,
            size: 20.r,
            color: degraded
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onTertiaryContainer,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: degraded
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
