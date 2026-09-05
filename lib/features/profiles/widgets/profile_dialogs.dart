import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Prompts for a new profile name. Returns `null` when the user cancels.
Future<String?> showRenameProfileDialog(
  BuildContext context, {
  required String currentName,
}) {
  final TextEditingController controller = TextEditingController(text: currentName);

  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Rename profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: AppConstants.maxProfileNameLength,
          decoration: const InputDecoration(labelText: 'Profile name'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      );
    },
  ).whenComplete(controller.dispose);
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
          'This removes the virtual profile only. The installed Virtual Test App '
          'is not uninstalled and its data is not touched.',
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
