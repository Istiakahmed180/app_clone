import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/profile_card.dart';
import '../../profiles/widgets/profile_dialogs.dart';
import '../controllers/home_controller.dart';
import '../widgets/phase_notice.dart';
import '../widgets/test_app_status_card.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProfile,
        icon: const Icon(Icons.add),
        label: const Text('Add Profile'),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: controller.refreshAll,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
              children: <Widget>[
                PhaseNotice(
                  virtualizationActive: controller.providesRuntimeIsolation,
                  problem: controller.virtualizationProblem,
                ),
                TestAppStatusCard(
                  testApp: controller.testApp.value,
                  platformInfo: controller.platformInfo.value,
                ),
                SizedBox(height: 24.h),
                Text(
                  'Your Virtual Apps',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 12.h),
                if (controller.errorMessage.value != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Text(
                      controller.errorMessage.value!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ..._buildProfileSection(context),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildProfileSection(BuildContext context) {
    if (controller.profiles.isEmpty) {
      return <Widget>[
        SizedBox(height: 48.h),
        const EmptyState(
          title: 'No profiles yet',
          message: 'Create a profile to see it listed here.',
        ),
      ];
    }

    return controller.profiles
        .map((VirtualProfileModel profile) => ProfileCard(
              profile: profile,
              state: controller.stateFor(profile),
              canLaunch: controller.stateFor(profile).installed,
              onLaunch: () => _launch(context, profile),
              onAction: (ProfileCardAction action) =>
                  _handleAction(context, profile, action),
            ))
        .toList(growable: false);
  }

  Future<void> _openAddProfile() async {
    final Object? created = await Get.toNamed<Object?>(AppRoutes.addProfile);
    if (created == true) {
      await controller.refreshAll();
    }
  }

  Future<void> _launch(BuildContext context, VirtualProfileModel profile) async {
    final String? error = await controller.launchProfile(profile);
    if (!context.mounted) {
      return;
    }
    _showMessage(
      context,
      error ?? 'Launched ${profile.appName} in ${profile.profileName}.',
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    VirtualProfileModel profile,
    ProfileCardAction action,
  ) async {
    switch (action) {
      case ProfileCardAction.rename:
        final String? name = await showRenameProfileDialog(
          context,
          currentName: profile.profileName,
        );
        if (name == null || !context.mounted) {
          return;
        }
        final String? error = await controller.renameProfile(profile, name);
        if (error != null && context.mounted) {
          _showMessage(context, error);
        }
      case ProfileCardAction.delete:
        final bool confirmed = await showDeleteProfileDialog(
          context,
          profileName: profile.profileName,
        );
        if (!confirmed || !context.mounted) {
          return;
        }
        final String? error = await controller.deleteProfile(profile);
        if (error != null && context.mounted) {
          _showMessage(context, error);
        }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
