import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Renders an application icon delivered as PNG bytes from the platform.
///
/// Falls back to a neutral placeholder when an icon could not be decoded, so a single
/// unreadable icon never breaks the list.
class AppIcon extends StatelessWidget {
  const AppIcon({required this.bytes, required this.size, super.key});

  final Uint8List? bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Uint8List? data = bytes;
    if (data == null || data.isEmpty) {
      return Icon(Icons.android, size: size, color: Theme.of(context).colorScheme.outline);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.memory(
        data,
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
            Icon(Icons.android, size: size),
      ),
    );
  }
}
