import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/profile_controller.dart';

class AddProfileView extends GetView<ProfileController> {
  const AddProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String appName = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>().testAppName
        : AppConstants.testAppFallbackName;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Application', style: theme.textTheme.labelLarge),
              SizedBox(height: 4.h),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(appName),
                subtitle: Text(controller.packageName),
                leading: const Icon(Icons.android),
              ),
              SizedBox(height: 16.h),
              Text('Profile Name', style: theme.textTheme.labelLarge),
              SizedBox(height: 8.h),
              TextField(
                controller: controller.nameController,
                autofocus: true,
                maxLength: AppConstants.maxProfileNameLength,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Profile 1',
                ),
                onSubmitted: (_) => _submit(context, appName),
              ),
              Obx(() {
                final String? error = controller.errorMessage.value;
                if (error == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Text(error, style: TextStyle(color: theme.colorScheme.error)),
                );
              }),
              SizedBox(height: 8.h),
              Obx(
                () => FilledButton(
                  onPressed:
                      controller.isSaving.value ? null : () => _submit(context, appName),
                  child: const Text('Create Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, String appName) async {
    final bool created = await controller.submit(appName: appName);
    if (created) {
      Get.back<bool>(result: true);
    }
  }
}
