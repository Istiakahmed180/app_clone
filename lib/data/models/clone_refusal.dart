import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import 'clone_budget.dart';
import 'compatibility_report.dart';

/// Why a clone was not made.
///
/// Four different facts, kept apart so each can be said properly: the compatibility layer
/// ruled the app out, the device has no room, the engine tried and failed, or nothing was
/// attempted at all because a clone was already being made. All but the engine failure
/// are something this app has words for — a failure arrives as finished prose from the
/// native side.
@immutable
class CloneRefusal {
  /// The compatibility layer said no before anything was attempted.
  ///
  /// [finding] is the blocking one, or null for a verdict that carried no finding at
  /// all — which the caller words for itself rather than inventing a reason.
  const CloneRefusal.blocked(this.finding)
    : failure = null,
      budget = null,
      busy = false;

  /// The engine was asked and refused. [failure] is the refusal as it was thrown, so
  /// the view can translate it by code rather than showing the engine's English.
  const CloneRefusal.failed(AppException this.failure)
    : finding = null,
      budget = null,
      busy = false;

  /// A clone was already being made, so this request was not started.
  ///
  /// It exists because the alternative was silence dressed as success. The tap used to
  /// return "no refusal", which every caller reads as "it worked" — so a second app
  /// tapped while the first was still installing closed the picker, said a clone had been
  /// made, and made nothing. One request at a time is the right rule; not saying so was
  /// the bug.
  const CloneRefusal.busy()
    : finding = null,
      failure = null,
      budget = null,
      busy = true;

  /// The device has no room for another clone, and nothing was attempted.
  ///
  /// [budget] is the same answer the count dialog would have shown, so the sentence the
  /// user is refused with here is the one the other clone route would have used.
  const CloneRefusal.noRoom(CloneBudget this.budget)
    : finding = null,
      failure = null,
      busy = false;

  final CompatibilityFinding? finding;
  final AppException? failure;

  /// What the device had room for, when that is why nothing happened.
  final CloneBudget? budget;

  /// Whether nothing was attempted because another clone was already in flight.
  final bool busy;
}
