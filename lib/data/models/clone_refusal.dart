import 'package:flutter/foundation.dart';

import 'compatibility_report.dart';

/// Why a clone was not made.
///
/// Two different facts, kept apart so each can be said properly: the compatibility layer
/// ruled the app out, or the engine tried and failed. Only the first is something this
/// app has words for — an engine failure arrives as finished prose from the native side.
@immutable
class CloneRefusal {
  /// The compatibility layer said no before anything was attempted.
  ///
  /// [finding] is the blocking one, or null for a verdict that carried no finding at
  /// all — which the caller words for itself rather than inventing a reason.
  const CloneRefusal.blocked(this.finding) : failure = null;

  /// The engine was asked and refused. [failure] is its own message.
  const CloneRefusal.failed(String this.failure) : finding = null;

  final CompatibilityFinding? finding;
  final String? failure;
}
