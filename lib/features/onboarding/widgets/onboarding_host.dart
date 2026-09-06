import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/onboarding_controller.dart';
import 'terms_dialog.dart';

/// Drives the first-launch sequence for whatever screen it wraps.
///
/// Stateful only because showing a dialog needs a [BuildContext] and a guard against
/// showing it twice; the sequence itself lives in [OnboardingController]. The controller
/// decides *what* comes next, this decides *how* it appears.
class OnboardingHost extends StatefulWidget {
  const OnboardingHost({required this.child, super.key});

  final Widget child;

  @override
  State<OnboardingHost> createState() => _OnboardingHostState();
}

class _OnboardingHostState extends State<OnboardingHost> with WidgetsBindingObserver {
  final OnboardingController _controller = Get.find<OnboardingController>();
  final List<Worker> _workers = <Worker>[];
  bool _termsVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _workers
      ..add(ever<OnboardingStep>(_controller.step, _onStep))
      ..add(ever<bool>(_controller.declined, _onDeclined));
    // The controller may already be past the first step when this mounts (a rebuild, or
    // a hot reload), so act on the current value rather than waiting for a change.
    _onStep(_controller.step.value);
  }

  @override
  void dispose() {
    for (final Worker worker in _workers) {
      worker.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The Doze exemption is granted on a system screen, outside this app, so the only
    // reliable moment to re-check it is when the user comes back.
    if (state == AppLifecycleState.resumed) {
      _controller.refreshBackgroundPrompt();
    }
  }

  void _onStep(OnboardingStep step) {
    if (step != OnboardingStep.terms || _termsVisible) {
      return;
    }
    _termsVisible = true;
    // Deferred: `ever` can fire mid-build, and showDialog cannot run during a build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTerms());
  }

  Future<void> _showTerms() async {
    if (!mounted) {
      return;
    }
    final bool accepted = await TermsDialog.show(context);
    _termsVisible = false;
    if (accepted) {
      await _controller.acceptTerms();
    } else {
      _controller.declineTerms();
    }
  }

  void _onDeclined(bool declined) {
    if (declined) {
      // Nothing in the app is usable without the terms, so leaving is the honest
      // outcome rather than parking the user on a screen that refuses to work.
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
