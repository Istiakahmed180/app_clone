import '../../../core/errors/app_error_text.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/models/clone_batch_result.dart';
import '../../../data/models/clone_budget.dart';
import '../../../l10n/app_localizations.dart';

/// Says a [CloneBudget]'s reason in the user's language.
///
/// The controller decides which fact bound the offer and hands over the figures the
/// platform already formatted; the wording lives here, beside the rest of the screen's
/// text, the way [settingsStatusMessage] does for Settings.
String cloneBudgetReason(AppLocalizations l10n, CloneBudget budget) {
  switch (budget.limit) {
    case CloneBudgetLimit.appCeiling:
      return l10n.cloneBudgetRange(budget.maximum);
    case CloneBudgetLimit.storageExhausted:
      return l10n.cloneBudgetNoStorage(budget.freeLabel ?? l10n.commonUnavailable);
    case CloneBudgetLimit.storage:
      return l10n.cloneBudgetStorage(
        budget.maximum,
        budget.freeLabel ?? l10n.commonUnavailable,
      );
    case CloneBudgetLimit.memory:
      return l10n.cloneBudgetMemory(
        budget.maximum,
        budget.totalMemLabel ?? l10n.commonUnavailable,
      );
  }
}

/// Why there is no room for another clone of [appName] at all.
String cloneBudgetRefusal(
  AppLocalizations l10n,
  CloneBudget budget,
  String appName,
) =>
    l10n.cloneBudgetNoRoom(appName, cloneBudgetReason(l10n, budget));

/// What to tell the user about a finished batch, or null when it simply worked.
String? cloneBatchFailure(
  AppLocalizations l10n,
  CloneBatchResult result,
  String appName,
) {
  final CloneBudget? refusedBy = result.refusedBy;
  if (refusedBy != null) {
    // Quotes the budget rather than paraphrasing it, so the sentence the user is
    // refused with is the one the stepper already showed them.
    if (refusedBy.allowsNone) {
      return cloneBudgetRefusal(l10n, refusedBy, appName);
    }
    return l10n.cloneBudgetNotEnoughRoom(
      result.requested,
      appName,
      cloneBudgetReason(l10n, refusedBy),
    );
  }

  final AppException? failure = result.failure;
  if (failure == null) {
    return null;
  }
  // A batch that landed nothing has only the refusal to offer; one that landed some
  // needs the tally as well, or a partial result reads as a total failure.
  final String said = appErrorMessage(l10n, failure);
  return result.isPartial
      ? l10n.cloneCreatedPartly(result.created, result.requested, said)
      : said;
}
