import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Renders an application icon delivered as PNG bytes from the platform.
///
/// Falls back to a neutral placeholder when an icon could not be decoded, so a single
/// unreadable icon never breaks the list.
///
/// The bytes arrive already normalised: the native side trims each icon's transparent
/// border and scales the remaining art to a fixed share of its canvas, so two icons of
/// the same [size] genuinely look the same size. Without that, a legacy icon's baked-in
/// margin made it visibly smaller than an adaptive icon beside it.
class AppIcon extends StatelessWidget {
  const AppIcon({
    required this.bytes,
    required this.size,
    this.onPlate = false,
    super.key,
  });

  final Uint8List? bytes;

  /// The width and height of the whole widget, plate included.
  final double size;

  /// Draws the icon on a rounded, tinted square.
  ///
  /// The plate is what makes a grid of icons read as one set: app icons are every
  /// shape and colour, and a shared base under them gives the eye a repeating unit to
  /// follow. Off by default — in a list row the surrounding card already does that job,
  /// and a second plate inside it is just another box.
  final bool onPlate;

  @override
  Widget build(BuildContext context) {
    if (!onPlate) {
      return _image(context, size);
    }

    final ThemeData theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      // The inset is what keeps a full-bleed square icon from touching the plate's
      // corners, where the rounding would clip it.
      child: _image(context, size * 0.72),
    );
  }

  Widget _image(BuildContext context, double extent) {
    final Uint8List? data = bytes;
    if (data == null || data.isEmpty) {
      return Icon(
        Icons.android,
        size: extent,
        color: Theme.of(context).colorScheme.outline,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(extent * 0.22),
      child: Image.memory(
        data,
        width: extent,
        height: extent,
        filterQuality: FilterQuality.medium,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
            Icon(Icons.android, size: extent),
      ),
    );
  }
}
