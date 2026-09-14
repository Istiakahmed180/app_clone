import 'dart:async';

import 'package:get/get.dart';

import '../../../core/services/onboarding_store.dart';
import '../../../core/utils/app_logger.dart';

/// Where the first-launch sequence has got to.
///
/// The controller owns the order; the view only renders whatever step is current. That
/// keeps the sequencing testable without pumping widgets.
enum OnboardingStep {
  /// Nothing has been asked yet.
  idle,

  /// Everything blocking is done; the app is usable.
  ready,
}

/// Runs the first-launch sequence: the data disclosure.
///
/// One step, and deliberately blocking: the data-and-permissions disclosure Play requires
/// for the installed-app inventory. It is shown before anything behind it, with an explicit
/// accept, and the answer is remembered.
///
/// The background-activity ask is not part of this sequence. It used to be a home-screen
/// banner offering the Doze exemption; that duplicated what Settings already reports, so
/// the Settings row is now the only surface for it -- one place, with the state on show.
class OnboardingController extends GetxController {
  OnboardingController({OnboardingStore? store})
      : _store = store ?? const OnboardingStore();

  final OnboardingStore _store;
  final AppLogger _logger = const AppLogger('OnboardingController');

  final Rx<OnboardingStep> step = OnboardingStep.idle.obs;

  /// Whether the disclosure has been accepted. `null` while the stored answer is being
  /// read, so the view can hold rather than flash the wrong thing.
  final RxnBool accepted = RxnBool();

  @override
  void onReady() {
    super.onReady();
    // Deferred to onReady so the first frame is on screen before anything can cover it.
    unawaited(start());
  }

  /// Runs the sequence from wherever the user left off.
  Future<void> start() async {
    step.value = OnboardingStep.ready;
    accepted.value = await _store.disclosureAccepted();
  }

  /// Records the user's acceptance of the data-and-permissions disclosure.
  Future<void> acceptDisclosure() async {
    accepted.value = true;
    try {
      await _store.acceptDisclosure();
    } on Object catch (error, stackTrace) {
      // Shown either way: re-asking a user who has already agreed is worse than asking
      // once more next launch after a storage failure.
      _logger.error('Could not record disclosure acceptance', error, stackTrace);
    }
  }
}
