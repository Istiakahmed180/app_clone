import 'package:get/get.dart';

import '../../core/virtualization/real_virtualization_engine.dart';
import '../../core/virtualization/virtualization_engine.dart';
import '../../data/repositories/virtual_profile_repository.dart';
import '../../features/apps/controllers/app_picker_controller.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../native/native_bridge.dart';

/// Registers the long-lived dependency graph once, before the first route builds.
class AppBinding extends Bindings {
  AppBinding();

  @override
  void dependencies() {
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
      ),
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
