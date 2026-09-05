import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Prompts for a new profile name. Returns `null` when the user cancels.
Future<String?> showRenameProfileDialog(
  BuildContext context, {
  required String currentName,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => _RenameProfileDialog(currentName: currentName),
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
  late final TextEditingController _controller =
      TextEditingController(text: widget.currentName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename profile'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: AppConstants.maxProfileNameLength,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(labelText: 'Profile name'),
        onSubmitted: (_) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

Future<bool> showDeleteProfileDialog(
  BuildContext context, {
  required String profileName,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Delete $profileName?'),
        content: const Text(
          'This removes the virtual profile and its isolated application data. The '
          'normally installed Virtual Test App and other profiles are not affected.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}
