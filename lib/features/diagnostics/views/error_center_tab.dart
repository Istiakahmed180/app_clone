import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/diagnostics/diagnostic_event.dart';
import '../controllers/diagnostics_controller.dart';
import '../widgets/diagnostic_visuals.dart';
import '../widgets/log_event_tile.dart';
import 'log_details_view.dart';
import 'operation_timeline_view.dart';

/// Every error and fatal event, newest first, grouped by kind.
///
/// Separate from a level filter on the live log because the question is different: the
/// live log answers "what is happening", this answers "what is broken". It also splits
/// the list by where the failure came from, since an unhandled Flutter exception and an
/// engine verdict need completely different next steps.
class ErrorCenterTab extends StatelessWidget {
  const ErrorCenterTab({required this.controller, super.key});

  final DiagnosticsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final List<DiagnosticEvent> failures = controller.failures;
      if (failures.isEmpty) {
        return _empty(context);
      }

      final List<_ErrorGroup> groups = _group(failures);

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          _summary(context, failures),
          const SizedBox(height: 12),
          for (final _ErrorGroup group in groups) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
              child: Text(
                '${group.title}  ·  ${group.events.length}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  for (int index = 0; index < group.events.length; index++) ...<Widget>[
                    if (index > 0) const Divider(height: 1),
                    LogEventTile(
                      event: group.events[index],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LogDetailsView(
                            event: group.events[index],
                            controller: controller,
                          ),
                        ),
                      ),
                      onOperationTap: (String operationId) =>
                          Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => OperationTimelineView(
                            operationId: operationId,
                            controller: controller,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _summary(BuildContext context, List<DiagnosticEvent> failures) {
    final ThemeData theme = Theme.of(context);
    final int fatal = failures
        .where((DiagnosticEvent event) => event.level == DiagLevel.fatal)
        .length;
    final int withTraces = failures
        .where((DiagnosticEvent event) =>
            event.stackTrace != null && event.stackTrace!.isNotEmpty)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Failures in the retained window', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                DiagnosticTag(
                  label: '${failures.length} total',
                  color: theme.colorScheme.error,
                ),
                if (fatal > 0)
                  DiagnosticTag(
                    label: '$fatal fatal',
                    color: theme.colorScheme.error,
                    icon: Icons.dangerous_outlined,
                  ),
                DiagnosticTag(label: '$withTraces with a stack trace'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.check_circle_outline,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('No errors recorded', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              'This covers the retained window only. Clearing the log or a long session '
              'can push older failures out of it.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// Groups by what a developer would do about it, not by source alphabetically.
  static List<_ErrorGroup> _group(List<DiagnosticEvent> failures) {
    final Map<String, List<DiagnosticEvent>> buckets =
        <String, List<DiagnosticEvent>>{};

    for (final DiagnosticEvent event in failures) {
      buckets.putIfAbsent(_titleFor(event), () => <DiagnosticEvent>[]).add(event);
    }

    // Fixed order, so the list does not reshuffle as new failures arrive. Crashes lead
    // because an unhandled exception outranks a handled verdict.
    const List<String> order = <String>[
      'Crashes and unhandled exceptions',
      'Virtualization engine',
      'Backend (Bcore)',
      'Install and import',
      'Guest lifecycle',
      'Platform channel',
      'Storage',
      'Other',
    ];

    return <_ErrorGroup>[
      for (final String title in order)
        if (buckets[title] != null) _ErrorGroup(title, buckets[title]!),
    ];
  }

  static String _titleFor(DiagnosticEvent event) {
    if (event.category == DiagnosticCategory.crash ||
        event.level == DiagLevel.fatal) {
      return 'Crashes and unhandled exceptions';
    }
    return switch (event.source) {
      DiagnosticSource.virtualEngine => 'Virtualization engine',
      DiagnosticSource.bcore => 'Backend (Bcore)',
      DiagnosticSource.apkImporter ||
      DiagnosticSource.packageInstaller =>
        'Install and import',
      DiagnosticSource.guestProcess || DiagnosticSource.activity => 'Guest lifecycle',
      DiagnosticSource.methodChannel => 'Platform channel',
      DiagnosticSource.storage => 'Storage',
      _ => 'Other',
    };
  }
}

class _ErrorGroup {
  const _ErrorGroup(this.title, this.events);

  final String title;
  final List<DiagnosticEvent> events;
}
