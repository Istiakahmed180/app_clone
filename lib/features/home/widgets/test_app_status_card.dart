import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/platform_info.dart';
import '../../../data/models/test_app_model.dart';

class TestAppStatusCard extends StatelessWidget {
  const TestAppStatusCard({
    required this.testApp,
    required this.platformInfo,
    super.key,
  });

  final TestAppModel? testApp;
  final PlatformInfo? platformInfo;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool installed = testApp?.installed ?? false;
    final String name = testApp?.displayName ?? 'Virtual Test App';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  installed ? Icons.check_circle_outline : Icons.error_outline,
                  color: installed ? theme.colorScheme.primary : theme.colorScheme.error,
                ),
                SizedBox(width: 8.w),
                Expanded(child: Text(name, style: theme.textTheme.titleMedium)),
                Text(
                  installed ? 'Installed' : 'Not Installed',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: installed ? theme.colorScheme.primary : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            if (installed)
              Text(
                '${testApp!.packageName} · v${testApp!.versionName ?? '?'} '
                '(${testApp!.versionCode ?? '?'})',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            else
              Text(
                'Install the Virtual Test App APK to enable launching.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            if (platformInfo != null) ...<Widget>[
              SizedBox(height: 4.h),
              Text(
                platformInfo!.summary,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
