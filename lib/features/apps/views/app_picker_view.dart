import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../data/models/installed_app_model.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/empty_state.dart';
import '../controllers/app_picker_controller.dart';

/// Lets the user clone an installed app, or import an APK that is not installed.
class AppPickerView extends GetView<AppPickerController> {
  const AppPickerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a clone'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Import APK',
            onPressed: () => _importApk(context),
            icon: const Icon(Icons.folder_open_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: TextField(
                onChanged: (String value) => controller.query.value = value,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  hintText: 'Search apps',
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.errorMessage.value != null) {
                  return EmptyState(
                    title: 'Could not list apps',
                    message: controller.errorMessage.value!,
                    icon: Icons.error_outline,
                  );
                }

                final List<InstalledAppModel> apps = controller.visibleApps;
                if (apps.isEmpty) {
                  return const EmptyState(
                    title: 'No matching apps',
                    message: 'Try a different search, or import an APK instead.',
                    icon: Icons.search_off,
                  );
                }

                return ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (BuildContext context, int index) =>
                      _AppRow(app: apps[index], onTap: () => _clone(context, apps[index])),
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => controller.isWorking.value
            ? const LinearProgressIndicator()
            : const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _clone(BuildContext context, InstalledAppModel app) async {
    final int existing = await controller.instanceCount(app.packageName);
    if (!context.mounted) {
      return;
    }

    // Cloning an app that already has clones is normal, but say so explicitly so the
    // user knows they are creating an additional, independent instance.
    if (existing > 0) {
      final bool confirmed = await _confirmExtraInstance(context, app, existing);
      if (!confirmed || !context.mounted) {
        return;
      }
    }

    final String? error = await controller.cloneInstalledApp(app);
    if (!context.mounted) {
      return;
    }
    if (error != null) {
      _showMessage(context, error);
      return;
    }
    Get.back<bool>(result: true);
  }

  Future<bool> _confirmExtraInstance(
    BuildContext context,
    InstalledAppModel app,
    int existing,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Add another ${app.appName}?'),
        content: Text(
          'You already have $existing clone${existing == 1 ? '' : 's'} of this app. '
          'The new one starts empty and keeps its own separate data.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add clone'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _importApk(BuildContext context) async {
    final ApkCandidate? candidate = await controller.pickApk();
    if (candidate == null) {
      if (context.mounted && controller.errorMessage.value != null) {
        _showMessage(context, controller.errorMessage.value!);
      }
      return;
    }
    if (!context.mounted) {
      return;
    }

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Install ${candidate.appName}?'),
        content: Text(
          '${candidate.packageName}\n'
          'Version ${candidate.versionName ?? '?'} (${candidate.versionCode ?? '?'})\n\n'
          '${candidate.installedOnHost ? 'This app is also installed normally on this device. The clone stays separate from it.' : 'This app is not installed on this device. It will run only inside Virtual Space.'}',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Install'),
          ),
        ],
      ),
    );

    if (proceed != true || !context.mounted) {
      return;
    }

    final String? error = await controller.cloneApk(candidate);
    if (!context.mounted) {
      return;
    }
    if (error != null) {
      _showMessage(context, error);
      return;
    }
    Get.back<bool>(result: true);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.app, required this.onTap});

  final InstalledAppModel app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: AppIcon(bytes: app.icon, size: 40.r),
      title: Text(app.appName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(app.packageName, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: app.isSystem
          ? Chip(
              label: const Text('System'),
              visualDensity: VisualDensity.compact,
              labelStyle: Theme.of(context).textTheme.labelSmall,
            )
          : null,
    );
  }
}
