import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/onboarding_controller.dart';
import 'data_disclosure.dart';

/// Drives the first-launch sequence for whatever screen it wraps.
///
/// The data disclosure is a gate: until it is accepted, the wrapped screen is not built.
/// The sequence itself lives in [OnboardingController]; this only decides *how* a step
/// appears.
class OnboardingHost extends StatelessWidget {
  const OnboardingHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final OnboardingController controller = Get.find<OnboardingController>();

    return Obx(() {
      // Null means the stored answer has not been read yet. Nothing is shown rather than
      // the wrapped screen, so a first launch never flashes the picker before the
      // disclosure.
      switch (controller.accepted.value) {
        case null:
          return const SizedBox.shrink();
        case false:
          return DataDisclosure(onAccept: controller.acceptDisclosure);
        case true:
          return child;
      }
    });
  }
}
