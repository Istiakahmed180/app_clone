import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_theme.dart';

/// A miniature of the clone launcher, drawn in one palette.
///
/// Built from [AppTheme]'s own schemes rather than from `Theme.of(context)`, because the
/// point of the pair is to show the palette the app is *not* currently in. Nothing here
/// is interactive: it says what the choice below will look like, and a mockup that
/// responded to taps would compete with the radio list for being the control.
class ThemePreview extends StatelessWidget {
  const ThemePreview({required this.brightness, required this.selected, super.key});

  final Brightness brightness;

  /// Whether this is the palette currently in effect. Drawn with an accent ring, the
  /// same way a selected tile is marked elsewhere in the app.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
        brightness == Brightness.light ? AppTheme.light() : AppTheme.dark();
    final ColorScheme scheme = theme.colorScheme;

    return Semantics(
      label: '${brightness == Brightness.light ? 'Light' : 'Dark'} theme preview',
      selected: selected,
      child: Container(
        width: 140.w,
        height: 218.h,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.tileRadius.r),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _titleBar(scheme),
            SizedBox(height: 12.h),
            _accentCard(scheme),
            SizedBox(height: 12.h),
            _listRow(scheme),
            SizedBox(height: 8.h),
            _listRow(scheme),
            SizedBox(height: 8.h),
            _listRow(scheme),
            const Spacer(),
            _dots(scheme),
          ],
        ),
      ),
    );
  }

  /// The app's own header: the shield, and the block where the title sits.
  Widget _titleBar(ColorScheme scheme) {
    return Row(
      children: <Widget>[
        Icon(Icons.shield_outlined, size: 12.r, color: scheme.primary),
        const Spacer(),
        _bar(scheme.surfaceContainerHighest, width: 30.w, height: 7.h),
      ],
    );
  }

  Widget _accentCard(ColorScheme scheme) {
    return Container(
      height: 52.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 18.r,
            height: 18.r,
            decoration: BoxDecoration(
              color: scheme.onPrimary.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 7.w),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _bar(scheme.onPrimary.withValues(alpha: 0.55), height: 5.h),
                SizedBox(height: 4.h),
                _bar(
                  scheme.onPrimary.withValues(alpha: 0.35),
                  width: 34.w,
                  height: 5.h,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _listRow(ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 12.r,
            height: 12.r,
            decoration: BoxDecoration(
              color: brightness == Brightness.light
                  ? scheme.outlineVariant
                  : scheme.onSurface,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: _bar(scheme.surfaceContainerHighest, height: 5.h),
          ),
          SizedBox(width: 4.w),
          Icon(Icons.chevron_right, size: 10.r, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }

  /// A page indicator. Present because the real screen has one, and a preview missing
  /// the bottom of the screen reads as a cropped screenshot.
  Widget _dots(ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (int index = 0; index < 5; index++)
          Container(
            width: 5.r,
            height: 5.r,
            decoration: BoxDecoration(
              color: index == 0 ? scheme.primary : scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _bar(Color color, {required double height, double? width}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height),
      ),
    );
  }
}
