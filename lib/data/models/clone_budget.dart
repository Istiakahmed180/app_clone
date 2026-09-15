import 'package:flutter/foundation.dart';

/// Which fact about the device settled the offer.
///
/// The controller decides this; the view says it. Keeping the wording out of here is
/// what lets the reason be spoken in the user's language — the controller has no
/// `BuildContext` and nothing to translate with.
enum CloneBudgetLimit {
  /// Nothing about the device bound the offer, so it is the app's own ceiling.
  appCeiling,

  /// Free storage left room for none at all.
  storageExhausted,

  /// Free storage bound how many can be made.
  storage,

  /// Memory bound how many can usefully run at once.
  memory,
}

/// How many more clones this device should be offered, and the reason in words.
///
/// One answer used twice: it sets the ceiling the count dialog will let a person pick,
/// and it is what [maximum] is checked against when they confirm. Deriving the offer and
/// the refusal from the same figure is what stops the app offering twenty and then
/// refusing five.
@immutable
class CloneBudget {
  const CloneBudget({
    required this.maximum,
    required this.limit,
    this.freeLabel,
    this.totalMemLabel,
  });

  /// Zero when the device has no room at all. The caller says so and never opens a
  /// stepper whose every value is invalid.
  final int maximum;

  /// What bound [maximum]. Shown under the stepper, in place of a bare "choose from 1
  /// to 20": a ceiling with no reason beside it reads as an arbitrary limit rather than
  /// as this device's.
  final CloneBudgetLimit limit;

  /// Free space, already formatted by the platform. Set for the storage limits, which
  /// are the only ones that name it.
  final String? freeLabel;

  /// Total memory, already formatted by the platform. Set for [CloneBudgetLimit.memory].
  final String? totalMemLabel;

  bool get allowsNone => maximum <= 0;
}
