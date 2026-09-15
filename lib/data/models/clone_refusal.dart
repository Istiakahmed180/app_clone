import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
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

  /// The engine was asked and refused. [failure] is the refusal as it was thrown, so
  /// the view can translate it by code rather than showing the engine's English.
  const CloneRefusal.failed(AppException this.failure) : finding = null;

  final CompatibilityFinding? finding;
  final AppException? failure;
}
