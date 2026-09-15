import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_context.dart';

import '../controllers/app_picker_controller.dart';

/// The picker's sort and filter controls, plus the two ways in that are not a list row.
///
/// A sheet rather than a row of chips: there are four independent choices here and
/// eighteen options between them, which is more than a header can hold without becoming
/// the screen. The sheet applies nothing until [onApply] — a filter that reorders the
/// list under the user's finger while they are still choosing is hostile.
class AppFilterSelection {
  const AppFilterSelection({
    required this.sort,
    required this.filter,
    required this.architecture,
    required this.packageType,
  });

  final AppSort sort;
  final AppFilter filter;
  final ArchitectureFilter architecture;
  final PackageTypeFilter packageType;
}

/// What the sheet was closed with. Exactly one of these is set.
class AppFilterResult {
  const AppFilterResult.applied(this.selection)
    : importFiles = false,
      importPackage = false;
  const AppFilterResult.importFiles()
    : selection = null,
      importFiles = true,
      importPackage = false;
  const AppFilterResult.importPackage()
    : selection = null,
      importFiles = false,
      importPackage = true;

  final AppFilterSelection? selection;

  /// The user asked for the file manager, to pick an APK or a split set.
  final bool importFiles;

  /// The user asked to open a Duplika app package — the `.papk.bin` a share produces.
  final bool importPackage;
}

Future<AppFilterResult?> showAppFilterSheet(
  BuildContext context, {
  required AppFilterSelection current,
}) {
  return showModalBottomSheet<AppFilterResult>(
    context: context,
    // Scroll-controlled and draggable: there are eighteen options here, and a sheet
    // fixed at half the screen would make the user scroll a small window instead of
    // growing it. Dragging or scrolling up takes it to full height.
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => _AppFilterSheet(current: current),
  );
}

class _AppFilterSheet extends StatefulWidget {
  const _AppFilterSheet({required this.current});

  final AppFilterSelection current;

  @override
  State<_AppFilterSheet> createState() => _AppFilterSheetState();
}

class _AppFilterSheetState extends State<_AppFilterSheet> {
  late AppSort _sort = widget.current.sort;
  late AppFilter _filter = widget.current.filter;
  late ArchitectureFilter _architecture = widget.current.architecture;
  late PackageTypeFilter _packageType = widget.current.packageType;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;

    return DraggableScrollableSheet(
      // Opens tall enough to show the sort and most of the filters, and reaches the top
      // of the screen when the user keeps going. `expand: false` so it sizes itself to
      // the fraction rather than always filling the modal.
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 1,
      snap: true,
      snapSizes: const <double>[0.72],
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) => Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              // The sheet's own controller, so scrolling past the top of the content
              // drags the sheet up instead of stopping dead.
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 18.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  Text(l10n.filterTitle, style: theme.textTheme.titleLarge),
                  SizedBox(height: 18.h),

                  _label(theme, l10n.filterSort),
                  for (final (AppSort value, String text)
                      in <(AppSort, String)>[
                        (AppSort.name, l10n.filterSortName),
                        (AppSort.recentlyInstalled, l10n.filterSortRecentlyInstalled),
                        (AppSort.recentlyUpdated, l10n.filterSortRecentlyUpdated),
                      ])
                    _radio<AppSort>(
                      label: text,
                      value: value,
                      group: _sort,
                      onChanged: (AppSort next) => setState(() => _sort = next),
                    ),

                  SizedBox(height: 12.h),
                  _label(theme, l10n.filterFilter),
                  for (final (AppFilter value, String text)
                      in <(AppFilter, String)>[
                        (AppFilter.all, l10n.filterAllApps),
                        (AppFilter.userApps, l10n.filterUserApps),
                        (AppFilter.systemApps, l10n.filterSystemApps),
                        (AppFilter.notAdded, l10n.filterNotAdded),
                        (AppFilter.alreadyAdded, l10n.filterAlreadyAdded),
                      ])
                    _radio<AppFilter>(
                      label: text,
                      value: value,
                      group: _filter,
                      onChanged: (AppFilter next) =>
                          setState(() => _filter = next),
                    ),

                  SizedBox(height: 12.h),
                  _label(theme, l10n.filterArchitecture),
                  for (final (ArchitectureFilter value, String text)
                      in <(ArchitectureFilter, String)>[
                        (ArchitectureFilter.all, l10n.filterAllApps),
                        (ArchitectureFilter.only64Bit, l10n.filterArch64),
                        (ArchitectureFilter.only32Bit, l10n.filterArch32),
                        (ArchitectureFilter.both, l10n.filterArchBoth),
                        (ArchitectureFilter.noNativeCode, l10n.filterArchNoNativeCode),
                      ])
                    _radio<ArchitectureFilter>(
                      label: text,
                      value: value,
                      group: _architecture,
                      onChanged: (ArchitectureFilter next) =>
                          setState(() => _architecture = next),
                    ),

                  SizedBox(height: 12.h),
                  _label(theme, l10n.filterPackageType),
                  for (final (PackageTypeFilter value, String text)
                      in <(PackageTypeFilter, String)>[
                        (PackageTypeFilter.all, l10n.filterAllApps),
                        (PackageTypeFilter.single, l10n.filterPackageSingle),
                        (PackageTypeFilter.split, l10n.filterPackageSplit),
                      ])
                    _radio<PackageTypeFilter>(
                      label: text,
                      value: value,
                      group: _packageType,
                      onChanged: (PackageTypeFilter next) =>
                          setState(() => _packageType = next),
                    ),

                  SizedBox(height: 14.h),
                  // Both ways of cloning something that is not in the list. They sit here
                  // rather than in the header because they answer the same question the
                  // filters do — which app — and the header is already a search field.
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(const AppFilterResult.importFiles()),
                      icon: const Icon(Icons.folder_outlined),
                      label: Text(l10n.filterImportFiles),
                    ),
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(const AppFilterResult.importPackage()),
                      icon: const Icon(Icons.folder_zip_outlined),
                      label: Text(l10n.filterImportApk(AppConstants.appTitle)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Pinned, not scrolled with the options: once the sheet is dragged to full
          // height the end of a long list of choices is a screen away, and the button
          // that commits them should never be the thing you have to go looking for.
          //
          // Its own SafeArea: at full height the sheet reaches the bottom of the
          // screen, where the gesture bar sits on top of anything drawn there.
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    AppFilterResult.applied(
                      AppFilterSelection(
                        sort: _sort,
                        filter: _filter,
                        architecture: _architecture,
                        packageType: _packageType,
                      ),
                    ),
                  ),
                  child: Text(l10n.commonApply),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(ThemeData theme, String text) => Padding(
    padding: EdgeInsets.only(bottom: 4.h),
    child: Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.primary,
      ),
    ),
  );

  Widget _radio<T>({
    required String label,
    required T value,
    required T group,
    required ValueChanged<T> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: <Widget>[
            RadioGroup<T>(
              groupValue: group,
              onChanged: (T? next) => next == null ? null : onChanged(next),
              child: Radio<T>(
                value: value,
                // The row is the tap target, so the control does not need its own 48dp
                // one. Left at the default, eighteen options made the sheet twice as
                // tall as it needs to be.
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }
}
