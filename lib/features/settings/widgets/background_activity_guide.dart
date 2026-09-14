import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_context.dart';

/// Which instructions fit this device.
///
/// The two worlds read differently: on the builds with a switch of their own the user has
/// to walk into a sub-page, while everywhere else the system asks its own one-tap question.
/// [unknown] is a state that could not be read at all, and gets the shortest true sentence
/// rather than a guess.
enum BackgroundActivityGuideVariant { oem, stock, unknown }

/// Explains what "background activity" is, why a clone goes quiet without it, and exactly
/// which taps turn it on.
///
/// The row's own subtitle can only carry a fragment; this is the part that answers "which
/// background?" before sending the user into a system screen that never uses the word the
/// way the app does.
Future<void> showBackgroundActivityGuide(
  BuildContext context, {
  required BackgroundActivityGuideVariant variant,
  required VoidCallback onOpen,
}) {
  final AppLocalizations l10n = context.l10n;
  final bool opensAppInfo = variant != BackgroundActivityGuideVariant.stock;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final ThemeData theme = Theme.of(sheetContext);

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.backgroundGuideTitle,
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: 8.h),
              Text(
                l10n.backgroundGuideWhy,
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 16.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.checklist_outlined,
                    size: 20.r,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      switch (variant) {
                        BackgroundActivityGuideVariant.oem =>
                          l10n.backgroundGuideStepsOem,
                        BackgroundActivityGuideVariant.stock =>
                          l10n.backgroundGuideStepsStock,
                        BackgroundActivityGuideVariant.unknown =>
                          l10n.backgroundGuideStepsUnknown,
                      },
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onOpen();
                  },
                  child: Text(
                    opensAppInfo
                        ? l10n.backgroundGuideOpenAppInfo
                        : l10n.backgroundGuideAllow,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(l10n.backgroundGuideLater),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
