import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duplika/app/theme/app_theme.dart';

/// The inverted surfaces are the easy ones to get wrong: they run opposite to the rest
/// of the screen, so a colour picked against the normal background reads as correct in
/// one mode and vanishes in the other. `inversePrimary` was undefined once and Flutter
/// resolved it to white, which left the banner's only action at 1.2:1 in dark mode.
void main() {
  double channel(double v) {
    final double s = (v * 255).round() / 255.0;
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);

  double contrast(Color a, Color b) {
    final double la = luminance(a);
    final double lb = luminance(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  // WCAG AA for body-sized text. The banner's message and its action are both that.
  const double aa = 4.5;

  for (final MapEntry<String, ThemeData> mode in <String, ThemeData>{
    'light': AppTheme.light(),
    'dark': AppTheme.dark(),
  }.entries) {
    group('${mode.key} mode', () {
      final ColorScheme scheme = mode.value.colorScheme;

      test('the message on an inverted surface is readable', () {
        expect(
          contrast(scheme.onInverseSurface, scheme.inverseSurface),
          greaterThanOrEqualTo(aa),
        );
      });

      test('the action on an inverted surface is readable', () {
        expect(
          contrast(scheme.inversePrimary, scheme.inverseSurface),
          greaterThanOrEqualTo(aa),
        );
      });

      test('the snack bar action is the inverse accent, not the flat one', () {
        // The flat accent is legible on one inverted surface and not the other, so a
        // theme that reached for it directly would be right only half the time.
        expect(
          mode.value.snackBarTheme.actionTextColor,
          scheme.inversePrimary,
        );
        expect(
          contrast(mode.value.snackBarTheme.actionTextColor!, scheme.inverseSurface),
          greaterThanOrEqualTo(aa),
        );
      });

      test('the inverted surface really is inverted', () {
        // Guards the premise: if both schemes ever pointed at the same background, one
        // of the accents above would be checked against a surface it never sits on.
        final bool surfaceIsDark = luminance(scheme.inverseSurface) < 0.5;
        expect(surfaceIsDark, mode.key == 'light');
      });
    });
  }
}
