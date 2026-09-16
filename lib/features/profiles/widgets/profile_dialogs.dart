import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../l10n/l10n_context.dart';
import '../../../widgets/app_icon.dart';

/// Prompts for a new profile name. Returns `null` when the user cancels.
Future<String?> showRenameProfileDialog(
  BuildContext context, {
  required String currentName,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) =>
        _RenameProfileDialog(currentName: currentName),
  );
}

/// Owns its own [TextEditingController].
///
/// Disposing the controller from the dialog future's `whenComplete` instead raced with
/// the route teardown and tripped a framework assertion (`_dependents.isEmpty`) once the
/// caller began refreshing engine state during the pop animation.
class _RenameProfileDialog extends StatefulWidget {
  const _RenameProfileDialog({required this.currentName});

  final String currentName;

  @override
  State<_RenameProfileDialog> createState() => _RenameProfileDialogState();
}

class _RenameProfileDialogState extends State<_RenameProfileDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Whether the field holds a name the repository will accept.
  ///
  /// The same rule as `_validateName`, checked here so an empty field disables Save
  /// rather than being taken and answered with an error dialog. The length bound is the
  /// field's own `maxLength`, so only emptiness can be got wrong.
  bool get _isValid => _controller.text.trim().isNotEmpty;

  void _submit() {
    if (!_isValid) {
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.renameTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: AppConstants.maxProfileNameLength,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(labelText: context.l10n.renameFieldLabel),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _isValid ? _submit : null,
          child: Text(context.l10n.commonSave),
        ),
      ],
    );
  }
}

/// Confirms removing one clone.
///
/// Names and shows the instance it is about to remove. The generic wording alone was
/// not enough: with several clones of the same app on the grid, "this clone" gave the
/// user no way to check they had held the right tile before agreeing to lose its data.
Future<bool> showUninstallCloneDialog(
  BuildContext context, {
  required String appName,
  required int spaceIndex,
  required int spaceCount,
  Uint8List? icon,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      final ThemeData theme = Theme.of(context);

      return AlertDialog(
        title: Text(context.l10n.uninstallTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AppIcon(bytes: icon, size: 40.r, onPlate: true),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(appName, style: theme.textTheme.titleSmall),
                      SizedBox(height: 2.h),
                      Text(
                        spaceCount > 1
                            ? context.l10n.uninstallSpaceOf(spaceIndex, spaceCount)
                            : context.l10n.cloneSpaceLabel(spaceIndex),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(context.l10n.uninstallMessage),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.uninstallConfirm),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}
