import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The home screen's title block.
///
/// Deliberately not an [AppBar]: the reference layout puts a two-line identity block in
/// the content, where it scrolls away with everything else, rather than a fixed bar that
/// spends a permanent strip of a phone screen restating the app's own name.
class HomeHeader extends StatelessWidget {
  const HomeHeader({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 28.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.headlineMedium),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
