import 'dart:async';

import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/onboarding_store.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/battery_prompt_screen.dart';
import '../../../native/native_bridge.dart';

/// Where the first-launch sequence has got to.
///
/// The controller owns the order; the view only renders whatever step is current. That
/// keeps the sequencing testable without pumping widgets.
enum OnboardingStep {
  /// Nothing has been asked yet.
  idle,

  /// The terms dialog is waiting on the user.
  terms,

  /// Everything blocking is done; the app is usable.
  ready,
}

/// Runs the first-launch sequence: the terms, then the Doze offer.
///
/// Only the terms step can actually block. The Doze exemption is a convenience the user
/// is free to ignore, so it cannot strand someone on a screen they cannot leave.
class OnboardingController extends GetxController {
  OnboardingController({
    required NativeBridge nativeBridge,
    OnboardingStore? store,
  })  : _bridge = nativeBridge,
        _store = store ?? const OnboardingStore();

  final NativeBridge _bridge;
  final OnboardingStore _store;
  final AppLogger _logger = const AppLogger('OnboardingController');

  final Rx<OnboardingStep> step = OnboardingStep.idle.obs;

  /// Set when the user declines the terms. The view closes the app on this.
  final RxBool declined = false.obs;

  /// Whether to offer the Doze exemption. False once granted or dismissed.
  final RxBool showBackgroundPrompt = false.obs;

  @override
  void onReady() {
    super.onReady();
    // Deferred to onReady so the first frame is on screen before a dialog covers it: a
    // dialog over a blank window looks broken.
    unawaited(start());
  }

  /// Runs the sequence from wherever the user left off.
  Future<void> start() async {
    if (await _store.hasAcceptedCurrentTerms()) {
      step.value = OnboardingStep.ready;
      await _evaluateBackgroundPrompt();
      return;
    }
    step.value = OnboardingStep.terms;
  }

  /// The user accepted the terms. Records the version and moves on.
  Future<void> acceptTerms() async {
    try {
      await _store.acceptTerms();
    } on Object catch (error, stackTrace) {
      // Failing to persist means we ask again next launch. Annoying, not broken, and far
      // better than treating an unrecorded acceptance as recorded.
      _logger.error('Could not record terms acceptance', error, stackTrace);
    }
    step.value = OnboardingStep.ready;
    await _evaluateBackgroundPrompt();
  }

  /// The user declined. The app cannot be used without the terms, so the view exits.
  void declineTerms() {
    _logger.info('Terms declined; closing');
    declined.value = true;
  }

  /// Opens the Doze exemption prompt.
  ///
  /// Returns a message to show the user, or `null` when the system dialog handled it
  /// and there is nothing to say. The prompt stays visible until Android confirms the
  /// exemption, because opening a screen is not the same as being granted anything.
  Future<String?> requestBackgroundPermission() async {
    try {
      final BatteryPromptScreen screen = await _bridge.requestIgnoreBatteryOptimizations();
      switch (screen) {
        case BatteryPromptScreen.none:
          showBackgroundPrompt.value = false;
          return null;
        case BatteryPromptScreen.dialog:
          return null;
        case BatteryPromptScreen.settings:
          // The one-tap dialog was unavailable, so the user has to find the app in a
          // list. Saying so is the difference between "nothing happened" and "your turn".
          return 'Find Duplika in the list and choose "Don\'t optimise".';
      }
    } on AppException catch (error) {
      _logger.error('Battery prompt failed: ${error.message}');
      return error.message;
    }
  }

  /// Re-checks the exemption, e.g. after returning from the system screen.
  Future<void> refreshBackgroundPrompt() => _evaluateBackgroundPrompt();

  /// The user waved the prompt away. It does not come back.
  Future<void> dismissBackgroundPrompt() async {
    showBackgroundPrompt.value = false;
    try {
      await _store.dismissBackgroundPrompt();
    } on Object catch (error, stackTrace) {
      _logger.error('Could not record prompt dismissal', error, stackTrace);
    }
  }

  Future<void> _evaluateBackgroundPrompt() async {
    if (await _store.backgroundPromptDismissed()) {
      showBackgroundPrompt.value = false;
      return;
    }
    showBackgroundPrompt.value = !await _bridge.isIgnoringBatteryOptimizations();
  }
}
