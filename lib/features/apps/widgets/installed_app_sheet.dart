import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_theme.dart';
import '../../../data/models/installed_app_model.dart';
import '../../../widgets/app_icon.dart';

/// What a picker row offers when it is tapped.
enum InstalledAppAction {
  /// Make a clone of this app.
  addClone,

  /// Hand the host's own APK to the share sheet.
  shareApp,

  /// Show what Duplika knows about this app before it is cloned.
  appDetails,
}

/// The sheet a picker row opens.
///
/// The row used to clone on tap, straight into the compatibility sheet. That made the
/// only thing a row could do the most consequential one, and gave no way to look at an
/// app — or pass it on — without cloning it first.
Future<InstalledAppAction?> showInstalledAppSheet(
  BuildContext context, {
  required InstalledAppModel app,
  required int existingClones,
}) {
  return showModalBottomSheet<InstalledAppAction>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      final ThemeData theme = Theme.of(context);

      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 0, 0, 18.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppIcon(bytes: app.icon, size: 44.r),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(app.appName, style: theme.textTheme.titleLarge),
                          SizedBox(height: 2.h),
                          Text(
                            app.packageName,
                            style: theme.textTheme.bodySmall,
                          ),
                          SizedBox(height: 2.h),
                          // The same two facts the row shows, repeated here: the sheet
                          // covers the row it came from, so without them the user has
                          // nothing to check they held the right app.
                          Text(
                            app.architectureLabel,
                            style: theme.textTheme.labelSmall,
                          ),
                          Text(
                            app.packageTypeLabel,
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              _ActionRow(
                icon: Icons.copy_all_outlined,
                // Named for what it does to what is already there: "Add another" on an
                // app with no clones would be describing a clone that does not exist.
                label: existingClones > 0 ? 'Add another' : 'Add clone',
                action: InstalledAppAction.addClone,
              ),
              SizedBox(height: 10.h),
              const _ActionRow(
                icon: Icons.share_outlined,
                label: 'Share app',
                action: InstalledAppAction.shareApp,
              ),
              SizedBox(height: 10.h),
              const _ActionRow(
                icon: Icons.info_outline,
                label: 'App details',
                action: InstalledAppAction.appDetails,
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// One bordered, full-width action.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.action,
  });

  final IconData icon;
  final String label;
  final InstalledAppAction action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(AppTheme.cardRadius.r);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(action),
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 22.r, color: theme.colorScheme.primary),
                SizedBox(width: 16.w),
                Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
