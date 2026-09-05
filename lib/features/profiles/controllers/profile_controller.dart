import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/virtualization/virtualization_engine.dart';

class ProfileController extends GetxController {
  ProfileController({required VirtualizationEngine engine}) : _engine = engine;

  final VirtualizationEngine _engine;

  final TextEditingController nameController = TextEditingController();
  final RxBool isSaving = false.obs;
  final RxnString errorMessage = RxnString();

  String get packageName => AppConstants.testAppPackage;

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  /// Creates the profile and reports whether it succeeded. Any failure message is
  /// exposed through [errorMessage] so the view stays free of business logic.
  Future<bool> submit({required String appName}) async {
    if (isSaving.value) {
      return false;
    }

    isSaving.value = true;
    errorMessage.value = null;
    try {
      await _engine.createProfile(
        packageName: packageName,
        appName: appName,
        profileName: nameController.text,
      );
      return true;
    } on AppException catch (error) {
      errorMessage.value = error.message;
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
