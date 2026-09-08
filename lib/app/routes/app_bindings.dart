import 'package:get/get.dart';

import '../../core/diagnostics/diagnostics_repository.dart';
import '../../core/diagnostics/native_diagnostics.dart';
import '../../core/virtualization/real_virtualization_engine.dart';
import '../../core/virtualization/virtualization_engine.dart';
import '../../data/repositories/virtual_profile_repository.dart';
import '../../features/apps/controllers/app_picker_controller.dart';
import '../../features/diagnostics/controllers/diagnostics_controller.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/onboarding/controllers/onboarding_controller.dart';
import '../../native/native_bridge.dart';

/// Registers the long-lived dependency graph once, before the first route builds.
class AppBinding extends Bindings {
  AppBinding();

  @override
  void dependencies() {
    // Diagnostics come first, and the native stream is attached here rather than when
    // the console opens: events that happen before anyone looks are exactly the ones a
    // console is opened to find.
    final NativeDiagnostics nativeDiagnostics = Get.put<NativeDiagnostics>(
      NativeDiagnostics(),
      permanent: true,
    );
    nativeDiagnostics.attach();
    Get.put<DiagnosticsRepository>(
      DiagnosticsRepository(native: nativeDiagnostics),
      permanent: true,
    );

    Get.put<NativeBridge>(NativeBridge(), permanent: true);
    Get.put<VirtualProfileRepository>(VirtualProfileRepository(), permanent: true);
    // Phase 2 backs profiles with the native container engine. DemoVirtualizationEngine
    // is kept in the tree as the reference no-op implementation of the same interface.
    Get.put<VirtualizationEngine>(
      RealVirtualizationEngine(
        repository: Get.find<VirtualProfileRepository>(),
        nativeBridge: Get.find<NativeBridge>(),
      ),
      permanent: true,
    );
  }
}

class HomeBinding extends Bindings {
  HomeBinding();

  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(
        engine: Get.find<VirtualizationEngine>(),
        nativeBridge: Get.find<NativeBridge>(),
        repository: Get.find<VirtualProfileRepository>(),
      ),
    );
    Get.lazyPut<OnboardingController>(
      () => OnboardingController(nativeBridge: Get.find<NativeBridge>()),
    );
  }
}

class DiagnosticsBinding extends Bindings {
  DiagnosticsBinding();

  @override
  void dependencies() {
    // The repository is permanent (it holds the merged window and the live
    // subscription); the controller is not, so closing the console releases its view
    // state without discarding the loaded history.
    Get.lazyPut<DiagnosticsController>(
      () => DiagnosticsController(repository: Get.find<DiagnosticsRepository>()),
    );
  }
}

class AppPickerBinding extends Bindings {
  AppPickerBinding();

  @override
  void dependencies() {
    Get.lazyPut<AppPickerController>(
      () => AppPickerController(
        bridge: Get.find<NativeBridge>(),
        engine: Get.find<VirtualizationEngine>(),
        repository: Get.find<VirtualProfileRepository>(),
      ),
    );
  }
}
