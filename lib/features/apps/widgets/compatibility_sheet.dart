import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/compatibility_report.dart';

/// The user's answer from [CompatibilitySheet]: whether to create the clone.
///
/// Previously also carried an `installGms` opt-in for per-container Google Play services
/// provisioning. That option was retired: the container copy it created could not
/// bootstrap its Chimera modules, and — once host GMS passthrough landed — it actively
/// *shadowed* the path that works, because the engine's PackageManager hooks answer from
/// the container before falling back to the host. Opting in therefore made a clone worse.
/// See `docs/level10-gms-provider-migration.md`.
class CloneDecision {
  const CloneDecision({required this.proceed});

  const CloneDecision.cancelled() : proceed = false;

  final bool proceed;
}

/// Shows what will and will not work before a clone is created.
///
/// The point of this sheet is that the user finds out *before* committing, rather than
/// after an app silently misbehaves inside the container.
class CompatibilitySheet extends StatelessWidget {
  const CompatibilitySheet({
    required this.appName,
    required this.report,
    required this.existingClones,
    super.key,
  });

  final String appName;
  final CompatibilityReport report;
  final int existingClones;

  static Future<CloneDecision> show(
    BuildContext context, {
    required String appName,
    required CompatibilityReport report,
    required int existingClones,
  }) async {
    final CloneDecision? decision = await showModalBottomSheet<CloneDecision>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => CompatibilitySheet(
        appName: appName,
        report: report,
        existingClones: existingClones,
      ),
    );
    return decision ?? const CloneDecision.cancelled();
  }

  @override
  Widget build(BuildContext context) => _SheetBody(
        appName: appName,
        initialReport: report,
        existingClones: existingClones,
      );
}

class _SheetBody extends StatefulWidget {
  const _SheetBody({
    required this.appName,
    required this.initialReport,
    required this.existingClones,
  });

  final String appName;
  final CompatibilityReport initialReport;
  final int existingClones;

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  late final CompatibilityReport _report = widget.initialReport;

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

            // No Google Play services opt-in here any more. A GMS-dependent app still
            // gets its REQUIRES_GMS warning through the findings list above; what is gone
            // is the checkbox that provisioned a container-local copy of Play services,
            // which degraded the clone rather than helping it.

            SizedBox(height: 20.h),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(const CloneDecision.cancelled()),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: FilledButton(
                    onPressed: _report.canClone
                        ? () => Navigator.of(context).pop(
                              const CloneDecision(proceed: true),
                            )
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
