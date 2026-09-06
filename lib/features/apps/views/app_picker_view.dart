import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/status_colors.dart';
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _header(context),
            _searchRow(context),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.errorMessage.value != null) {
                  return _centred(EmptyState(
                    title: 'Could not list apps',
                    message: controller.errorMessage.value!,
                    icon: Icons.error_outline,
                  ));
                }

                final List<AppSection> sections = controller.sections;
                if (sections.isEmpty) {
                  return _centred(const EmptyState(
                    title: 'No matching apps',
                    message: 'Try a different search, or import an APK instead.',
                    icon: Icons.search_off,
                  ));
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
                  // One item per group, not per app: the grouped layout would otherwise
                  // cost a full layout pass over every installed app on first frame.
                  itemCount: sections.length + 1,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return _installedHeading(context, controller.visibleApps.length);
                    }
                    final AppSection section = sections[index - 1];
                    return _SectionGroup(
                      section: section,
                      analyze: controller.analyze,
                      onTap: (InstalledAppModel app) => _clone(context, app),
                    );
                  },
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

  Widget _centred(Widget child) => ListView(
        padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 32.h),
        children: <Widget>[child],
      );

  Widget _header(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 8.h, 16.w, 20.h),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: Get.back<void>,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new),
            iconSize: 20.r,
          ),
          Text('Add a clone', style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }

  Widget _searchRow(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              onChanged: (String value) => controller.query.value = value,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search apps',
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // The APK import sits beside the search rather than in the header: both are
          // ways of naming the app to clone, and the header is only an identity block.
          Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius.r),
            child: InkWell(
              onTap: () => _importApk(context),
              borderRadius: BorderRadius.circular(AppTheme.cardRadius.r),
              child: Ink(
                width: 56.w,
                height: 56.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius.r),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Icon(
                  Icons.folder_open_outlined,
                  size: 22.r,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _installedHeading(BuildContext context, int count) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Text('Installed apps', style: theme.textTheme.titleLarge),
          Text(
            count == 1 ? '1 app' : '$count apps',
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
          ),
        ],
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

/// One alphabetical group: the letter, then its apps in a single bordered card.
class _SectionGroup extends StatelessWidget {
  const _SectionGroup({
    required this.section,
    required this.analyze,
    required this.onTap,
  });

  final AppSection section;
  final Future<CompatibilityReport> Function(String packageName) analyze;
  final ValueChanged<InstalledAppModel> onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
            child: Text(
              section.letter,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
          Card(
            // Rows are clipped to the card so a row's ripple cannot paint over the
            // rounded corner it sits in.
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < section.apps.length; i++) ...<Widget>[
                  if (i > 0) const Divider(),
                  _AppRow(
                    app: section.apps[i],
                    // Analysis is per-app and cached, so the badge resolves lazily as
                    // rows scroll into view rather than stalling the whole list.
                    analyze: () => analyze(section.apps[i].packageName),
                    onTap: () => onTap(section.apps[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.app, required this.analyze, required this.onTap});

  final InstalledAppModel app;
  final Future<CompatibilityReport> Function() analyze;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: <Widget>[
            AppIcon(bytes: app.icon, size: 44.r),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    app.appName,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    app.packageName,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (app.versionName != null || app.isSystem) ...<Widget>[
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: <Widget>[
                        if (app.versionName != null) _Chip(label: 'v${app.versionName}'),
                        if (app.isSystem) const _Chip(label: 'System'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            _Trailing(analyze: analyze),
          ],
        ),
      ),
    );
  }
}

/// The row's right-hand affordance: the compatibility verdict when there is one to
/// report, and otherwise the plain "this row adds a clone" mark.
class _Trailing extends StatelessWidget {
  const _Trailing({required this.analyze});

  final Future<CompatibilityReport> Function() analyze;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return FutureBuilder<CompatibilityReport>(
      future: analyze(),
      builder: (BuildContext context, AsyncSnapshot<CompatibilityReport> snapshot) {
        final CompatibilityReport? report = snapshot.data;
        if (report != null && report.verdict != CompatibilityVerdict.supported) {
          final bool blocked = report.verdict == CompatibilityVerdict.unsupported;
          return Icon(
            blocked ? Icons.block : Icons.info_outline,
            size: 22.r,
            color: blocked ? scheme.error : StatusColors.of(context).warning,
          );
        }
        return Container(
          width: 28.r,
          height: 28.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary, width: 1.5),
          ),
          child: Icon(Icons.add, size: 18.r, color: scheme.primary),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}
