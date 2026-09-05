import 'package:get/get.dart';

import '../../core/virtualization/demo_virtualization_engine.dart';
import '../../core/virtualization/virtualization_engine.dart';
import '../../data/repositories/virtual_profile_repository.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/profiles/controllers/profile_controller.dart';
import '../../native/native_bridge.dart';

/// Registers the long-lived dependency graph once, before the first route builds.
class AppBinding extends Bindings {
  AppBinding();

  @override
  void dependencies() {
    Get.put<NativeBridge>(NativeBridge(), permanent: true);
    Get.put<VirtualProfileRepository>(VirtualProfileRepository(), permanent: true);
    Get.put<VirtualizationEngine>(
      DemoVirtualizationEngine(
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

class AddProfileBinding extends Bindings {
  AddProfileBinding();

  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(
      () => ProfileController(engine: Get.find<VirtualizationEngine>()),
    );
  }
}
