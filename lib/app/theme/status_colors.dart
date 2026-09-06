import 'package:flutter/material.dart';

/// Semantic colours [ColorScheme] has no slot for.
///
/// Status here is not one axis. A clone can be settled and fine, or working but
/// degraded, or blocked — and Material's scheme only names `error`. Before this
/// existed both "Ready" and "needs a permission it does not have" were painted with
/// `tertiary`, which meant the palette could not be changed without one of them
/// coming out wrong.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({required this.positive, required this.warning});

  /// Settled: it works and there is nothing to do about it.
  final Color positive;

  /// It works, but something about it is worth reading. Never used for a blocked
  /// state — that is `ColorScheme.error`.
  final Color warning;

  /// The colours in scope, or a light-theme fallback when the extension is missing.
  ///
  /// The fallback exists so a widget test that pumps a bare `MaterialApp` still renders
  /// something legible instead of throwing on a null.
  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>() ?? _fallback;

  static const StatusColors _fallback = StatusColors(
    positive: Color(0xFF12A150),
    warning: Color(0xFFB54708),
  );

  @override
  StatusColors copyWith({Color? positive, Color? warning}) => StatusColors(
        positive: positive ?? this.positive,
        warning: warning ?? this.warning,
      );

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) {
      return this;
    }
    return StatusColors(
      positive: Color.lerp(positive, other.positive, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}
