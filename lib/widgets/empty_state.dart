import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A bordered panel for "there is nothing here yet", with an optional way out of it.
///
/// Rendered as a card rather than centred text on bare background: an empty screen that
/// is merely blank reads as a screen that failed to load. The panel says the app got
/// here on purpose, and [actionLabel] gives the state somewhere to go.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    this.icon = Icons.verified_user_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(
          (actionLabel == null) == (onAction == null),
          'An action needs both a label and a callback, or neither.',
        );

  final String title;
  final String message;
  final IconData icon;

  /// The call to action. Omit both to render the panel without a button.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72.r,
              height: 72.r,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34.r, color: theme.colorScheme.primary),
            ),
            SizedBox(height: 20.h),
            Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (onAction != null) ...<Widget>[
              SizedBox(height: 24.h),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
