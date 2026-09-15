import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/models/app_details.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_context.dart';
import '../widgets/app_facts_text.dart';
import '../../../data/models/installed_app_model.dart';
import '../controllers/app_picker_controller.dart';

/// Everything Duplika knows about one installed app, before anything is cloned.
///
/// A page rather than a sheet: the component list is as long as the package has splits,
/// and the paths and the certificate hash are there to be read and copied.
class AppDetailsView extends StatefulWidget {
  const AppDetailsView({
    required this.controller,
    required this.app,
    super.key,
  });

  final AppPickerController controller;
  final InstalledAppModel app;

  @override
  State<AppDetailsView> createState() => _AppDetailsViewState();
}

class _AppDetailsViewState extends State<AppDetailsView> {
  AppDetails? _details;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final AppDetails details = await widget.controller.appDetails(
        widget.app.packageName,
      );
      if (mounted) {
        setState(() => _details = details);
      }
    } on AppException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appDetailsTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
        children: <Widget>[
          _header(theme),
          SizedBox(height: 20.h),
          if (_error != null)
            _card(child: Text(_error!, style: theme.textTheme.bodySmall))
          else if (_details == null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 48.h),
              child: const Center(child: CircularProgressIndicator()),
            )
          else ...<Widget>[
            _factsCard(theme, l10n, _details!),
            SizedBox(height: 24.h),
            Text(l10n.appDetailsAdvanced, style: theme.textTheme.titleLarge),
            SizedBox(height: 10.h),
            _componentsCard(theme, l10n, _details!),
          ],
        ],
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Row(
      children: <Widget>[
        // The icon is already loaded for the picker row, so the header does not wait on
        // the details read to show which app this is.
        _Icon(bytes: widget.app.icon, size: 56.r),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.app.appName, style: theme.textTheme.titleLarge),
              SizedBox(height: 2.h),
              Text(widget.app.packageName, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _factsCard(ThemeData theme, AppLocalizations l10n, AppDetails details) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _fact(theme, l10n.appDetailsPackageName, details.packageName),
          _fact(theme, l10n.appDetailsVersion, versionLabel(l10n, details)),
          _fact(
            theme,
            l10n.appDetailsArchitecture,
            detailsArchitectureLabel(l10n, details),
          ),
          _fact(
            theme,
            l10n.appDetailsBitness,
            bitnessLabel(
              l10n,
              supports32Bit: details.supports32Bit,
              supports64Bit: details.supports64Bit,
            ),
          ),
          _fact(
            theme,
            l10n.appDetailsPackageType,
            packageTypeLabel(l10n, details.apkCount),
          ),
          _fact(theme, l10n.appDetailsApkComponents, '${details.apkCount}'),
          _fact(
            theme,
            l10n.appDetailsTotalApkSize,
            totalSizeLabel(l10n, details.totalSizeBytes),
          ),
          _fact(
            theme,
            l10n.appDetailsSigningSha256,
            details.signingSha256 ?? l10n.appDetailsSigningUnreadable,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _componentsCard(
    ThemeData theme,
    AppLocalizations l10n,
    AppDetails details,
  ) {
    if (details.components.isEmpty) {
      return _card(
        child: Text(
          l10n.appDetailsNoApkFiles,
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int index = 0; index < details.components.length; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == details.components.length - 1 ? 0 : 18.h,
              ),
              child: _Component(component: details.components[index]),
            ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius.r),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: child,
  );

  Widget _fact(
    ThemeData theme,
    String label,
    String value, {
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 18.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4.h),
          // Selectable throughout: a package name, a path and a certificate hash are
          // all things people copy out rather than read.
          SelectableText(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// One APK file: its name, what it is, and where it lives.
class _Component extends StatelessWidget {
  const _Component({required this.component});

  final ApkComponent component;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(component.name, style: theme.textTheme.titleSmall),
        SizedBox(height: 2.h),
        Text(
          apkComponentSummary(context.l10n, component),
          style: theme.textTheme.bodySmall,
        ),
        SizedBox(height: 2.h),
        SelectableText(
          component.path,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The app's icon on a rounded plate, matching the picker's own rows.
class _Icon extends StatelessWidget {
  const _Icon({required this.bytes, required this.size});

  final Uint8List? bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (bytes == null || bytes!.isEmpty) {
      return Icon(Icons.android, size: size, color: theme.colorScheme.outline);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.memory(
        bytes!,
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
            Icon(Icons.android, size: size),
      ),
    );
  }
}
