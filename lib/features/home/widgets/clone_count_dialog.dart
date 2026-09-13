import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_theme.dart';

/// Asks how many more copies of an app to make.
///
/// A stepper rather than a text field: the answer is a small number, every value in
/// range is one tap away, and there is no way to type something that has to be rejected.
///
/// The bound is real, not decorative. Each clone is a container install of a few
/// seconds, so twenty is already close to a minute of work — and the caller sizes
/// [maximum] to what this device can actually take.
///
/// [reason] is shown in place of the plain range. A ceiling with nothing beside it
/// reads as an arbitrary limit; the same number next to "1.2 GB of space left" reads
/// as this device's answer, and tells the user what to change to raise it.
///
/// Returns the chosen count, or null if cancelled.
Future<int?> showCloneCountDialog(
  BuildContext context, {
  required String appName,
  int minimum = 1,
  int maximum = 20,
  String? reason,
}) {
  return showDialog<int>(
    context: context,
    builder: (BuildContext context) => _CloneCountDialog(
      appName: appName,
      minimum: minimum,
      maximum: maximum,
      reason: reason,
    ),
  );
}

class _CloneCountDialog extends StatefulWidget {
  const _CloneCountDialog({
    required this.appName,
    required this.minimum,
    required this.maximum,
    this.reason,
  });

  final String appName;
  final int minimum;
  final int maximum;
  final String? reason;

  @override
  State<_CloneCountDialog> createState() => _CloneCountDialogState();
}

class _CloneCountDialogState extends State<_CloneCountDialog> {
  late int _count = widget.minimum;

  void _by(int delta) {
    final int next = (_count + delta).clamp(widget.minimum, widget.maximum);
    if (next != _count) {
      setState(() => _count = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: <Widget>[
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.copy_all_outlined,
              size: 22.r,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Clone app', style: theme.textTheme.titleLarge),
                SizedBox(height: 2.h),
                Text(
                  'Create additional copies of ${widget.appName}.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Number of clones', style: theme.textTheme.titleSmall),
          SizedBox(height: 10.h),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius.r),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: <Widget>[
                _StepButton(
                  icon: Icons.remove,
                  tooltip: 'One fewer',
                  onPressed: _count > widget.minimum ? () => _by(-1) : null,
                ),
                Expanded(
                  child: Text(
                    '$_count',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                _StepButton(
                  icon: Icons.add,
                  tooltip: 'One more',
                  onPressed: _count < widget.maximum ? () => _by(1) : null,
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            widget.reason ??
                'Choose from ${widget.minimum} to ${widget.maximum}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_count),
          child: const Text('Clone'),
        ),
      ],
    );
  }
}

/// One end of the stepper. Disabled at the bound rather than hidden, so the control
/// keeps its shape and the limit is visible before it is hit.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 22.r),
      color: Theme.of(context).colorScheme.primary,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
    );
  }
}
