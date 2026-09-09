import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_theme.dart';
import '../../../data/models/compatibility_report.dart';
import '../../../data/models/installed_app_model.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/empty_state.dart';
import '../controllers/app_picker_controller.dart';
import '../widgets/app_filter_sheet.dart';
import '../widgets/compatibility_sheet.dart';
import 'app_details_view.dart';
import '../widgets/installed_app_sheet.dart';

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
                  return _centred(
                    EmptyState(
                      title: 'Could not list apps',
                      message: controller.errorMessage.value!,
                      icon: Icons.error_outline,
                    ),
                  );
                }

                final List<AppSection> sections = controller.sections;

                // Read here, not in the item builder. `Obx` only records the observables
                // touched during its own build, and an item builder runs later, during
                // layout — so reading these there registered no dependency and the marks
                // never updated until something else rebuilt the list. Snapshots also
                // keep a row from seeing the set change mid-frame.
                final Set<String> cloned = controller.clonedPackages.toSet();
                final Set<String> cloning = controller.cloning.toSet();
                final List<InstalledAppModel> picks = controller.quickPicks;
                final int visibleCount = controller.visibleApps.length;

                if (sections.isEmpty) {
                  return _centred(
                    const EmptyState(
                      title: 'No matching apps',
                      message:
                          'Try a different search, or import an APK instead.',
                      icon: Icons.search_off,
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
                  // One item per group, not per app: the grouped layout would otherwise
                  // cost a full layout pass over every installed app on first frame.
                  itemCount: sections.length + 1,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _quickPicks(context, picks, cloned, cloning),
                          _installedHeading(context, visibleCount),
                        ],
                      );
                    }
                    final AppSection section = sections[index - 1];
                    return _SectionGroup(
                      section: section,
                      clonedPackages: cloned,
                      cloningPackages: cloning,
                      onTap: (InstalledAppModel app) => _openApp(context, app),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      // Only when no row is already saying it. Cloning shows its progress on the row
      // itself; this bar is what covers the work with no row to point at — staging and
      // parsing an imported APK.
      bottomNavigationBar: Obx(
        () => controller.isWorking.value && controller.cloning.isEmpty
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
          Text('Add app', style: Theme.of(context).textTheme.headlineMedium),
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
          // Sort, filter and both import routes live behind one button beside the
          // search: they all answer the same question the search does — which app —
          // and there are too many of them for a header.
          Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius.r),
            child: InkWell(
              onTap: () => _openFilters(context),
              borderRadius: BorderRadius.circular(AppTheme.cardRadius.r),
              child: Ink(
                width: 56.w,
                height: 56.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius.r),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Tooltip(
                  message: 'Filter and sort',
                  child: Icon(
                    Icons.tune,
                    size: 22.r,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A short row of the apps people most often clone.
  ///
  /// Not a popularity measurement — Duplika cannot see what the user actually uses, and
  /// a "Popular" list computed from nothing would be a decoration. It is a fixed set of
  /// well-known apps, shown only where they are installed, to save scrolling past two
  /// hundred rows for the common case. Hidden while a search is active, where the list
  /// itself is already the answer.
  Widget _quickPicks(
    BuildContext context,
    List<InstalledAppModel> picks,
    Set<String> cloned,
    Set<String> cloning,
  ) {
    final ThemeData theme = Theme.of(context);
    if (picks.isEmpty || controller.query.value.trim().isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Popular', style: theme.textTheme.titleLarge),
        SizedBox(height: 2.h),
        Text('Quick picks', style: theme.textTheme.bodySmall),
        SizedBox(height: 12.h),
        SizedBox(
          height: 108.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            // Bleeds into the screen's own margin at both ends, so a card that is
            // half off the edge reads as "there is more" rather than as clipped.
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            clipBehavior: Clip.none,
            itemCount: picks.length,
            separatorBuilder: (BuildContext context, int index) =>
                SizedBox(width: 10.w),
            itemBuilder: (BuildContext context, int index) => _QuickPickCard(
              app: picks[index],
              isCloned: controller.clonedPackages.contains(
                picks[index].packageName,
              ),
              isCloning: controller.cloning.contains(picks[index].packageName),
              onTap: () => _quickClone(context, picks[index]),
            ),
          ),
        ),
        SizedBox(height: 20.h),
      ],
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
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Clones straight away, with no sheet in between.
  ///
  /// Both routes into cloning an installed app come here — the Popular card and a list
  /// row's Add clone — so neither asks anything. The row shows its own progress; see
  /// [AppPickerController.cloneNow].
  ///
  /// Nothing raises the non-blocking findings any more: the missing host permissions and
  /// the Play services option lived in the sheet this replaced, and there is no other
  /// route to either for an installed app.
  Future<void> _quickClone(BuildContext context, InstalledAppModel app) async {
    final String? error = await controller.cloneNow(app);
    if (!context.mounted) {
      return;
    }
    if (error != null) {
      _showMessage(context, error);
      return;
    }

    // A beat before leaving, so the row is seen finishing rather than the screen
    // changing under the finger. Short enough not to be a wait of its own.
    await Future<void>.delayed(_cloneSettle);
    if (context.mounted) {
      Get.back<bool>(result: true);
    }
  }

  /// How long the finished row stays on screen before the picker closes.
  static const Duration _cloneSettle = Duration(milliseconds: 240);

  /// What a picker row does when tapped.
  ///
  /// A row used to clone on tap. That made a row's only action its most consequential
  /// one, with no way to look at an app or pass it on without cloning it first.
  Future<void> _openApp(BuildContext context, InstalledAppModel app) async {
    final int existing = await controller.instanceCount(app.packageName);
    if (!context.mounted) {
      return;
    }

    final InstalledAppAction? action = await showInstalledAppSheet(
      context,
      app: app,
      existingClones: existing,
    );
    if (action == null || !context.mounted) {
      return;
    }

    switch (action) {
      case InstalledAppAction.addClone:
        // Straight to the clone, the same one-tap path the Popular row uses. Note the
        // cost: nothing in this flow now offers the host permission grant or the Play
        // services option — both lived in the sheet this replaced, and neither has
        // another route for an installed app.
        await _quickClone(context, app);
      case InstalledAppAction.shareApp:
        final String? error = await controller.shareInstalledApp(app);
        if (error != null && context.mounted) {
          _showMessage(context, error);
        }
      case InstalledAppAction.appDetails:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                AppDetailsView(controller: controller, app: app),
          ),
        );
    }
  }

  /// Opens the sort/filter sheet and acts on whichever way it was closed.
  Future<void> _openFilters(BuildContext context) async {
    final AppFilterResult? result = await showAppFilterSheet(
      context,
      current: AppFilterSelection(
        sort: controller.sort.value,
        filter: controller.filter.value,
        architecture: controller.architecture.value,
        packageType: controller.packageType.value,
      ),
    );
    if (result == null || !context.mounted) {
      return;
    }

    if (result.importFiles) {
      await _importApk(context);
      return;
    }
    if (result.importPackage) {
      await _importApk(context, packageFormat: true);
      return;
    }

    final AppFilterSelection selection = result.selection!;
    controller.sort.value = selection.sort;
    controller.filter.value = selection.filter;
    controller.architecture.value = selection.architecture;
    controller.packageType.value = selection.packageType;
  }

  Future<void> _importApk(
    BuildContext context, {
    bool packageFormat = false,
  }) async {
    final ApkCandidate? candidate = await controller.pickApk(
      packageFormat: packageFormat,
    );
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
      onGrantPermissions: () =>
          _grantPermissions(context, candidate.packageName),
    );

    if (!decision.proceed || !context.mounted) {
      return;
    }

    // No GMS argument: provisioning is retired, so both clone routes -- installed app and
    // imported APK -- now behave identically and leave it off.
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

  /// Runs the permission request and reports why it did not happen, if it did not.
  ///
  /// A request can be refused before the dialog is ever shown (another one is open, or the
  /// host went away); saying nothing would leave the sheet looking unchanged for no reason.
  Future<CompatibilityReport> _grantPermissions(
    BuildContext context,
    String packageName,
  ) async {
    final PermissionRequestResult? result = await controller.requestPermissions(
      packageName,
    );

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

/// One group of apps in a single bordered card, under its letter.
///
/// The letter is empty under a time sort, where the whole list is one group.
class _SectionGroup extends StatelessWidget {
  const _SectionGroup({
    required this.section,
    required this.clonedPackages,
    required this.cloningPackages,
    required this.onTap,
  });

  final AppSection section;
  final Set<String> clonedPackages;
  final Set<String> cloningPackages;
  final ValueChanged<InstalledAppModel> onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // No letter under a time sort: an A-Z header over a list ordered by install
          // date would label a group that is not one.
          if (section.letter.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
              child: Text(
                section.letter,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
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
                    isCloned: clonedPackages.contains(
                      section.apps[i].packageName,
                    ),
                    isCloning: cloningPackages.contains(
                      section.apps[i].packageName,
                    ),
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
  const _AppRow({
    required this.app,
    required this.isCloned,
    required this.isCloning,
    required this.onTap,
  });

  final InstalledAppModel app;

  /// Whether this app already has at least one clone. Marked on the icon, because a
  /// user scanning two hundred rows for "did I already do this one" should not have to
  /// read anything.
  final bool isCloned;

  /// Whether a clone of this app is being created right now.
  final bool isCloning;
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
            _IconWithTick(icon: app.icon, size: 44.r, isCloned: isCloned),
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
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: <Widget>[
                      // What the archive is, before what version it is: whether an app
                      // is 32-bit or a split set decides whether it can be cloned at
                      // all on a given device, and the picker's filters are about
                      // exactly these two facts.
                      _Chip(label: app.architectureLabel),
                      _Chip(label: app.packageTypeLabel),
                      if (app.versionName != null)
                        _Chip(label: 'v${app.versionName}'),
                      if (app.isSystem) const _Chip(label: 'System'),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            _AddMark(isCloning: isCloning),
          ],
        ),
      ),
    );
  }
}

/// The row's right-hand affordance.
///
/// Always the same mark, because every row does the same thing. It used to show the
/// compatibility verdict instead — a block or an info glyph — which meant the icon on
/// the right answered a question the user had not asked yet and never showed the one
/// action the row actually performs. The verdict is reported where it can be acted on:
/// in the clone flow, and on the app's details screen.
class _AddMark extends StatelessWidget {
  const _AddMark({this.isCloning = false});

  /// True while this app's clone is being created. The mark becomes a spinner in place,
  /// on the row the user tapped — which app is being cloned is the part they need to
  /// see, and a bar across the bottom of the screen does not say it.
  final bool isCloning;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    if (isCloning) {
      return SizedBox(
        width: 28.r,
        height: 28.r,
        child: Padding(
          padding: EdgeInsets.all(2.r),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: scheme.primary,
          ),
        ),
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

/// An app icon carrying the "already cloned" tick.
class _IconWithTick extends StatelessWidget {
  const _IconWithTick({
    required this.icon,
    required this.size,
    required this.isCloned,
  });

  final Uint8List? icon;
  final double size;
  final bool isCloned;

  @override
  Widget build(BuildContext context) {
    final AppIcon image = AppIcon(bytes: icon, size: size);
    if (!isCloned) {
      return image;
    }

    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        image,
        Positioned(
          right: -2.r,
          bottom: -2.r,
          child: Container(
            width: 16.r,
            height: 16.r,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
              // Ringed in the surface colour so the tick reads as an overlay rather
              // than as part of the app's own artwork.
              border: Border.all(color: scheme.surface, width: 1.5),
            ),
            child: Icon(Icons.check, size: 10.r, color: scheme.onPrimary),
          ),
        ),
      ],
    );
  }
}

/// One card in the Popular row.
///
/// Square, so a row of them reads as a set of icons rather than a row of boxes, and
/// deliberately smaller than a list row: this is a shortcut, not the list.
class _QuickPickCard extends StatelessWidget {
  const _QuickPickCard({
    required this.app,
    required this.isCloned,
    required this.isCloning,
    required this.onTap,
  });

  final InstalledAppModel app;
  final bool isCloned;
  final bool isCloning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(AppTheme.tileRadius.r);

    return SizedBox(
      width: 96.w,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Stack(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(6.w, 18.h, 6.w, 10.h),
                  child: Column(
                    children: <Widget>[
                      _IconWithTick(
                        icon: app.icon,
                        size: 44.r,
                        isCloned: isCloned,
                      ),
                      SizedBox(height: 10.h),
                      // Takes the space that is left and centres in it, so one-line and
                      // two-line names sit on the same baseline across the row.
                      Expanded(
                        child: Center(
                          child: Text(
                            app.appName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 6.h,
                  right: 6.w,
                  child: isCloning
                      ? SizedBox(
                          width: 18.r,
                          height: 18.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Container(
                          width: 18.r,
                          height: 18.r,
                          decoration: BoxDecoration(
                            // A tinted disc, not a bare glyph: on a busy icon the plus
                            // alone read as part of the artwork.
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            size: 12.r,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
