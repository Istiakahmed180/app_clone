import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/onboarding_controller.dart';
import 'data_disclosure.dart';

/// Drives the first-launch sequence for whatever screen it wraps.
///
/// The data disclosure is a gate: until it is accepted, the wrapped screen is not built.
/// Everything after it is additive (the Doze banner), so the controller still owns the
/// order and this only decides *how* a step appears.
///
/// Stateful only because the sequence has to react to the app coming back to the
/// foreground; the sequence itself lives in [OnboardingController].
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
  Widget build(BuildContext context) {
    return Obx(() {
      // Null means the stored answer has not been read yet. Nothing is shown rather than
      // the wrapped screen, so a first launch never flashes the picker before the
      // disclosure.
      switch (_controller.accepted.value) {
        case null:
          return const SizedBox.shrink();
        case false:
          return DataDisclosure(onAccept: _controller.acceptDisclosure);
        case true:
          return widget.child;
      }
    });
  }
}
