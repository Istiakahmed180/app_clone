import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/onboarding_controller.dart';

/// Drives the first-launch sequence for whatever screen it wraps.
///
/// Stateful only because the sequence has to react to the app coming back to the
/// foreground; the sequence itself lives in [OnboardingController]. The controller
/// decides *what* comes next, this decides *how* it appears.
class OnboardingHost extends StatefulWidget {
  const OnboardingHost({required this.child, super.key});

  final Widget child;

  @override
  State<OnboardingHost> createState() => _OnboardingHostState();
}

class _OnboardingHostState extends State<OnboardingHost> with WidgetsBindingObserver {
  final OnboardingController _controller = Get.find<OnboardingController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) => widget.child;
}
