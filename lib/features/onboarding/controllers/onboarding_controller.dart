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

  /// Everything blocking is done; the app is usable.
  ready,
}

/// Runs the first-launch sequence: the data disclosure, then the Doze offer.
///
/// One step now blocks, and deliberately so: the data-and-permissions disclosure Play
/// requires for the installed-app inventory. It is shown before anything behind it, with
/// an explicit accept, and the answer is remembered. Everything after it is still
/// non-blocking — the Doze exemption is a convenience the user is free to ignore.
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

  /// Whether the disclosure has been accepted. `null` while the stored answer is being
  /// read, so the view can hold rather than flash the wrong thing.
  final RxnBool accepted = RxnBool();

  /// Whether to offer the Doze exemption. False once granted or dismissed.
  final RxBool showBackgroundPrompt = false.obs;

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
    await _evaluateBackgroundPrompt();
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
