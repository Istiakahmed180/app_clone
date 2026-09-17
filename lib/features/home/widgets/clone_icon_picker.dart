import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/clone_icon_color.dart';
import 'clone_icon_color_text.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_context.dart';

/// Lets the user mark one clone so they can tell it from its siblings.
///
/// Colours rather than replacement icons: a clone keeps its own app's icon, because that
/// is what says *which app this is* -- the one thing the grid cannot afford to lose. What
/// the user picks here colours the small badge drawn over that icon.
///
/// What the user asked for. Null from the sheet means they dismissed it.
sealed class CloneIconChoice {
  const CloneIconChoice();
}

/// Mark the clone with this colour. [CloneIconColor.none] clears the mark.
class CloneIconColorChosen extends CloneIconChoice {
  const CloneIconColorChosen(this.color);

  final CloneIconColor color;
}

/// Open the gallery and use whatever the user picks.
class CloneIconPictureRequested extends CloneIconChoice {
  const CloneIconPictureRequested();
}

/// Throw the picture away and go back to the app's own icon.
class CloneIconAppIconRequested extends CloneIconChoice {
  const CloneIconAppIconRequested();
}

/// Returns what the user asked for, or null when the sheet is dismissed.
///
/// [hasCustomIcon] decides whether going back to the app's icon is offered at all: a
/// clone that never had a picture has nothing to undo.
Future<CloneIconChoice?> showCloneIconPicker(
  BuildContext context, {
  required CloneIconColor current,
  required bool hasCustomIcon,
}) {
  return showModalBottomSheet<CloneIconChoice>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (BuildContext context) => _CloneIconPicker(
      current: current,
      hasCustomIcon: hasCustomIcon,
    ),
  );
}

class _CloneIconPicker extends StatelessWidget {
  const _CloneIconPicker({required this.current, required this.hasCustomIcon});

  final CloneIconColor current;
  final bool hasCustomIcon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Text(l10n.cloneIconPickerTitle, style: theme.textTheme.titleMedium),
            SizedBox(height: 6.h),
            Text(
              l10n.cloneIconPickerMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 16.h),
            // Replacing the icon outright comes first: someone who opened this sheet to
            // change the picture should not have to read past a row of colours to find it.
            _WideButton(
              icon: Icons.image_outlined,
              label: l10n.cloneIconPickerChoose,
              onTap: () => Navigator.of(context)
                  .pop(const CloneIconPictureRequested()),
            ),
            if (hasCustomIcon) ...<Widget>[
              SizedBox(height: 10.h),
              _WideButton(
                icon: Icons.restart_alt,
                label: l10n.cloneIconPickerUseAppIcon,
                onTap: () => Navigator.of(context)
                    .pop(const CloneIconAppIconRequested()),
              ),
            ],
            SizedBox(height: 20.h),
            Wrap(
              spacing: 14.w,
              runSpacing: 14.h,
              children: <Widget>[
                for (final CloneIconColor color in CloneIconColor.palette)
                  _Swatch(color: color, selected: color == current),
                // Last rather than first: clearing is what someone comes back for, not
                // what they choose the first time.
                _Swatch(
                  color: CloneIconColor.none,
                  selected: current == CloneIconColor.none,
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonCancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One tappable colour. [CloneIconColor.none] renders as an outlined circle with a slash,
/// so "no mark" reads as a deliberate option rather than a missing swatch.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected});

  final CloneIconColor color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int? argb = color.argb;
    final double size = 40.r;

    return Semantics(
      // Named, because the colour is the whole of what the control says and a screen
      // reader cannot see it. Without this the sheet reads as nine unlabelled buttons,
      // and the one thing the user came here to choose is the one thing not announced.
      label: cloneIconColorLabel(context.l10n, color),
      selected: selected,
      button: true,
      child: InkResponse(
        onTap: () => Navigator.of(context).pop(CloneIconColorChosen(color)),
        radius: size,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: argb == null ? Colors.transparent : Color(argb),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2.5.r : 1.r,
            ),
          ),
          child: argb == null
              ? Icon(
                  Icons.block,
                  size: 18.r,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : selected
                  ? Icon(Icons.check, size: 20.r, color: Colors.white)
                  : null,
        ),
      ),
    );
  }
}

/// A full-width row, styled like the clone action sheet's so the two sheets read as one
/// family rather than two designs.
class _WideButton extends StatelessWidget {
  const _WideButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(12.r);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 20.r, color: theme.colorScheme.primary),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(label, style: theme.textTheme.titleSmall),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
