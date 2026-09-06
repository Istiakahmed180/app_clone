import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Offers the Doze exemption, without demanding it.
///
/// Sits at the bottom of the home screen rather than arriving as a dialog: clones work
/// without the exemption, so this is an offer the user can ignore or dismiss for good.
class BackgroundPermissionBanner extends StatelessWidget {
  const BackgroundPermissionBanner({
    required this.onConfirm,
    required this.onDismiss,
    super.key,
  });

  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      minimum: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
      child: Material(
        color: theme.colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 8.h),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Allow Duplika to run in the background so your clones keep receiving '
                  'messages and notifications.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onInverseSurface),
                ),
              ),
              TextButton(
                onPressed: onConfirm,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.inversePrimary,
                ),
                child: const Text('Allow'),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
                iconSize: 18.sp,
                color: theme.colorScheme.onInverseSurface,
                tooltip: 'Dismiss',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
