import 'package:flutter/foundation.dart';

/// How many more clones this device should be offered, and the reason in words.
///
/// One answer used twice: it sets the ceiling the count dialog will let a person pick,
/// and it is what [maximum] is checked against when they confirm. Deriving the offer and
/// the refusal from the same figure is what stops the app offering twenty and then
/// refusing five.
@immutable
class CloneBudget {
  const CloneBudget({required this.maximum, required this.reason});

  /// Zero when the device has no room at all. The caller says so and never opens a
  /// stepper whose every value is invalid.
  final int maximum;

  /// Shown under the stepper, in place of a bare "choose from 1 to 20". A ceiling with
  /// no reason beside it reads as an arbitrary limit rather than as this device's.
  final String reason;

  bool get allowsNone => maximum <= 0;
}
