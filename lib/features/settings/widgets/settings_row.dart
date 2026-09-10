import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One settings row: a tinted icon, a title, and whatever the row has to say on the
/// right.
///
/// Three shapes in one widget because the difference between them is only what sits at
/// the trailing edge — a value the user cannot change, a badge, or a chevron into
/// somewhere else. Splitting them into separate widgets made the leading medallion and
/// the row metrics diverge, which is the one thing a settings list must not do.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.badge,
    this.onTap,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// The current setting, or the fact being reported. Shown muted at the trailing edge.
  final String? value;

  /// A short pill, for a value that is a state rather than a setting.
  final String? badge;

  final VoidCallback? onTap;

  /// False for a row that exists but cannot be used yet. Rendered dimmed and inert
  /// rather than hidden: a row that disappears tells the user nothing about why.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool tappable = enabled && onTap != null;
    // One opacity over the whole row, so the icon, the title and the value dim together.
    final double opacity = enabled ? 1 : 0.45;

    return InkWell(
      onTap: tappable ? onTap : null,
      child: Opacity(
        opacity: opacity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          child: Row(
            children: <Widget>[
              Container(
                width: 34.r,
                height: 34.r,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18.r, color: theme.colorScheme.primary),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: theme.textTheme.titleSmall),
                    if (subtitle != null) ...<Widget>[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badge != null) _pill(theme, badge!),
              if (value != null)
                // Bounded so a long value wraps inside the row instead of squeezing the
                // title to nothing: 'Supported ABIs' can list four of them.
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 150.w),
                  child: Text(
                    value!,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (tappable) ...<Widget>[
                SizedBox(width: 4.w),
                Icon(
                  Icons.chevron_right,
                  size: 20.r,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(ThemeData theme, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
