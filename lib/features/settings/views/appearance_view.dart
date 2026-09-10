import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../controllers/settings_controller.dart';
import '../widgets/appearance_labels.dart';
import '../widgets/settings_section.dart';
import '../widgets/theme_preview.dart';

/// Which palette the app uses.
///
/// A page rather than a dialog because of the preview: the choice is about how the
/// whole app looks, and the two mockups are what makes 'System default' a decision
/// rather than a guess. The ring marks the palette in effect right now, which for
/// 'System default' is whichever one the device is currently in.
class AppearanceView extends StatelessWidget {
  const AppearanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: Obx(() {
        final ThemeMode mode = controller.themeMode.value;
        final Brightness effective = effectiveBrightness(mode, context);

        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
          children: <Widget>[
            _previewCard(context, effective),
            SizedBox(height: 22.h),
            SettingsSection(
              title: 'Choose a theme',
              children: <Widget>[
                for (final ThemeMode option in ThemeMode.values)
                  _ThemeOption(
                    mode: option,
                    selected: option == mode,
                    onSelect: () => controller.setThemeMode(option),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            _instantNote(context),
          ],
        );
      }),
    );
  }

  Widget _previewCard(BuildContext context, Brightness effective) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Preview', style: theme.textTheme.titleMedium),
            SizedBox(height: 14.h),
            // Centred as a pair, so the two mockups stay side by side and equally
            // weighted rather than one being pinned to an edge.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ThemePreview(
                  brightness: Brightness.light,
                  selected: effective == Brightness.light,
                ),
                SizedBox(width: 14.w),
                ThemePreview(
                  brightness: Brightness.dark,
                  selected: effective == Brightness.dark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _instantNote(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Container(
          width: 34.r,
          height: 34.r,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.schedule,
            size: 18.r,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            'Theme changes apply instantly across ${AppConstants.appTitle}.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// One theme choice. The whole row is the target, not just the radio.
class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.onSelect,
  });

  final ThemeMode mode;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: onSelect,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: <Widget>[
            Container(
              width: 34.r,
              height: 34.r,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                appearanceIcon(mode),
                size: 18.r,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(appearanceLabel(mode), style: theme.textTheme.titleSmall),
                  SizedBox(height: 2.h),
                  Text(
                    appearanceDescription(mode),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            RadioGroup<ThemeMode>(
              groupValue: selected ? mode : null,
              onChanged: (ThemeMode? chosen) => chosen == null ? null : onSelect(),
              child: Radio<ThemeMode>(
                value: mode,
                // The row is the tap target, so the control does not need its own 48dp
                // one on top of it.
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
