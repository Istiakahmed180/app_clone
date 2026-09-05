import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/compatibility_report.dart';

/// Shows what will and will not work before a clone is created.
///
/// The point of this sheet is that the user finds out *before* committing, rather than
/// after an app silently misbehaves inside the container.
class CompatibilitySheet extends StatelessWidget {
  const CompatibilitySheet({
    required this.appName,
    required this.report,
    required this.existingClones,
    required this.onGrantPermissions,
    super.key,
  });

  final String appName;
  final CompatibilityReport report;
  final int existingClones;

  /// Returns the refreshed report after the user has answered the permission dialog.
  final Future<CompatibilityReport> Function() onGrantPermissions;

  static Future<bool> show(
    BuildContext context, {
    required String appName,
    required CompatibilityReport report,
    required int existingClones,
    required Future<CompatibilityReport> Function() onGrantPermissions,
  }) async {
    final bool? proceed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => CompatibilitySheet(
        appName: appName,
        report: report,
        existingClones: existingClones,
        onGrantPermissions: onGrantPermissions,
      ),
    );
    return proceed ?? false;
  }

  @override
  Widget build(BuildContext context) => _SheetBody(
        appName: appName,
        initialReport: report,
        existingClones: existingClones,
        onGrantPermissions: onGrantPermissions,
      );
}

class _SheetBody extends StatefulWidget {
  const _SheetBody({
    required this.appName,
    required this.initialReport,
    required this.existingClones,
    required this.onGrantPermissions,
  });

  final String appName;
  final CompatibilityReport initialReport;
  final int existingClones;
  final Future<CompatibilityReport> Function() onGrantPermissions;

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  late CompatibilityReport _report = widget.initialReport;
  bool _requesting = false;

  Future<void> _grant() async {
    setState(() => _requesting = true);
    final CompatibilityReport refreshed = await widget.onGrantPermissions();
    if (!mounted) {
      return;
    }
    setState(() {
      _report = refreshed;
      _requesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ({String label, Color color, IconData icon}) badge = _badge(theme.colorScheme);

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(badge.icon, color: badge.color),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(widget.appName, style: theme.textTheme.titleLarge),
                ),
                Text(badge.label, style: theme.textTheme.labelLarge?.copyWith(color: badge.color)),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              _report.packageName,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 16.h),

            if (!_report.analysed)
              _Line(
                icon: Icons.help_outline,
                color: theme.colorScheme.onSurfaceVariant,
                text: 'This app could not be examined, so nothing is known about how well '
                    'it will run. It may still be refused when the clone is created.',
              )
            else if (_report.findings.isEmpty)
              _Line(
                icon: Icons.check_circle_outline,
                color: theme.colorScheme.primary,
                text: 'No known compatibility problems.',
              ),

            for (final CompatibilityFinding finding in _report.findings)
              _Line(
                icon: finding.blocking ? Icons.block : Icons.warning_amber_outlined,
                color: finding.blocking ? theme.colorScheme.error : theme.colorScheme.tertiary,
                text: finding.message,
              ),

            if (widget.existingClones > 0) ...<Widget>[
              SizedBox(height: 8.h),
              _Line(
                icon: Icons.copy_all_outlined,
                color: theme.colorScheme.onSurfaceVariant,
                text: 'You already have ${widget.existingClones} clone'
                    '${widget.existingClones == 1 ? '' : 's'} of this app. '
                    'The new one starts empty with its own data.',
              ),
            ],

            if (_report.needsPermissions) ...<Widget>[
              SizedBox(height: 16.h),
              FilledButton.tonalIcon(
                onPressed: _requesting ? null : _grant,
                icon: const Icon(Icons.lock_open_outlined),
                label: Text(
                  _requesting
                      ? 'Waiting for your answer…'
                      : 'Grant ${_report.missingPermissions.length} permission(s)',
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Clones run under Virtual Space\'s identity, so these are granted to '
                'Virtual Space itself. You can decline and clone anyway.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],

            SizedBox(height: 20.h),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: FilledButton(
                    onPressed: _report.canClone
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    child: Text(_report.canClone ? 'Add clone' : 'Cannot clone'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ({String label, Color color, IconData icon}) _badge(ColorScheme scheme) {
    if (!_report.analysed) {
      return (label: 'Not analysed', color: scheme.onSurfaceVariant, icon: Icons.help_outline);
    }
    return _verdictBadge(scheme);
  }

  ({String label, Color color, IconData icon}) _verdictBadge(ColorScheme scheme) =>
      switch (_report.verdict) {
        CompatibilityVerdict.supported =>
          (label: 'Supported', color: scheme.primary, icon: Icons.verified_outlined),
        CompatibilityVerdict.limited =>
          (label: 'Limited', color: scheme.tertiary, icon: Icons.info_outline),
        CompatibilityVerdict.unsupported =>
          (label: 'Unsupported', color: scheme.error, icon: Icons.block),
      };
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18.r, color: color),
          SizedBox(width: 8.w),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
