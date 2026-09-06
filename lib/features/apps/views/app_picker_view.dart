import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../data/models/compatibility_report.dart';
import '../../../data/models/installed_app_model.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/empty_state.dart';
import '../controllers/app_picker_controller.dart';
import '../widgets/compatibility_sheet.dart';

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
                  itemBuilder: (BuildContext context, int index) => _AppRow(
                    app: apps[index],
                    // Analysis is per-app and cached, so the badge resolves lazily as
                    // rows scroll into view rather than stalling the whole list.
                    analyze: () => controller.analyze(apps[index].packageName),
                    onTap: () => _clone(context, apps[index]),
                  ),
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
    final CompatibilityReport report = await controller.analyze(app.packageName);
    if (!context.mounted) {
      return;
    }

    // Always surface the compatibility verdict first: an app may be unsupported, need
    // permissions the host does not hold, or already have clones.
    final CloneDecision decision = await CompatibilitySheet.show(
      context,
      appName: app.appName,
      report: report,
      existingClones: existing,
      onGrantPermissions: () => _grantPermissions(context, app.packageName),
    );
    if (!decision.proceed || !context.mounted) {
      return;
    }

    final String? error =
        await controller.cloneInstalledApp(app, installGms: decision.installGms);
    if (!context.mounted) {
      return;
    }
    if (error != null) {
      _showMessage(context, error);
      return;
    }
    Get.back<bool>(result: true);
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

    // Read from the archive itself, so an APK that is not installed here is still judged
    // properly instead of being presented as problem-free.
    final CompatibilityReport report = await controller.analyzeApk(candidate);
    final int existing = await controller.instanceCount(candidate.packageName);
    if (!context.mounted) {
      return;
    }

    final CloneDecision decision = await CompatibilitySheet.show(
      context,
      appName: candidate.appName,
      report: report,
      existingClones: existing,
      onGrantPermissions: () => _grantPermissions(context, candidate.packageName),
    );

    if (!decision.proceed || !context.mounted) {
      return;
    }

    final String? error =
        await controller.cloneApk(candidate, installGms: decision.installGms);
    if (!context.mounted) {
      return;
    }
    if (error != null) {
      _showMessage(context, error);
      return;
    }
    Get.back<bool>(result: true);
  }

  /// Runs the permission request and reports why it did not happen, if it did not.
  ///
  /// A request can be refused before the dialog is ever shown (another one is open, or the
  /// host went away); saying nothing would leave the sheet looking unchanged for no reason.
  Future<CompatibilityReport> _grantPermissions(
    BuildContext context,
    String packageName,
  ) async {
    final PermissionRequestResult? result =
        await controller.requestPermissions(packageName);

    if (result == null && context.mounted) {
      final String? reason = controller.errorMessage.value;
      if (reason != null) {
        _showMessage(context, reason);
      }
    }

    return controller.analyze(packageName);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.app, required this.analyze, required this.onTap});

  final InstalledAppModel app;
  final Future<CompatibilityReport> Function() analyze;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: AppIcon(bytes: app.icon, size: 40.r),
      title: Text(app.appName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(app.packageName, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: FutureBuilder<CompatibilityReport>(
        future: analyze(),
        builder: (BuildContext context, AsyncSnapshot<CompatibilityReport> snapshot) {
          final CompatibilityReport? report = snapshot.data;
          if (report == null || report.verdict == CompatibilityVerdict.supported) {
            return const SizedBox.shrink();
          }
          final ColorScheme scheme = Theme.of(context).colorScheme;
          final bool blocked = report.verdict == CompatibilityVerdict.unsupported;
          return Icon(
            blocked ? Icons.block : Icons.info_outline,
            size: 20.r,
            color: blocked ? scheme.error : scheme.tertiary,
          );
        },
      ),
    );
  }
}
