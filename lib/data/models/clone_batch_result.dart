import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import 'clone_budget.dart';

/// What a request for more clones came to.
///
/// Three outcomes rather than a message, for the same reason [CloneBudget] carries a
/// [CloneBudgetLimit]: the controller knows what happened, the view knows how to say it,
/// and only the view can say it in the user's language.
@immutable
class CloneBatchResult {
  const CloneBatchResult({
    required this.requested,
    required this.created,
    this.refusedBy,
    this.failure,
  });

  /// Every clone asked for was made.
  const CloneBatchResult.success(int count)
      : requested = count,
        created = count,
        refusedBy = null,
        failure = null;

  final int requested;
  final int created;

  /// Set when the batch was never attempted because the device had no room. Carries the
  /// budget itself, so the refusal can quote the sentence the stepper already showed.
  final CloneBudget? refusedBy;

  /// The first clone that failed, as it was thrown.
  ///
  /// The exception rather than its message: the view translates it by code, and only a
  /// code the table has no wording for falls back to the engine's own prose.
  final AppException? failure;

  bool get isSuccess => refusedBy == null && failure == null;

  /// True when the batch was refused outright, so nothing at all was attempted.
  bool get wasRefused => refusedBy != null;

  /// True when some clones landed and some did not.
  bool get isPartial => failure != null && created > 0;
}
