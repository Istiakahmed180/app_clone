import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/diagnostics/diagnostics_repository.dart';
import '../controllers/diagnostics_controller.dart';
import '../widgets/diagnostic_visuals.dart';
import 'operation_timeline_view.dart';

/// Every correlated operation in the retained window, newest first.
///
/// This is the index into the timelines: each row is one thing the user (or a shortcut)
/// asked for, with how long it took and how it ended, so a failed launch can be opened
/// without first finding one of its events in the log.
class OperationsTab extends StatelessWidget {
  const OperationsTab({required this.controller, super.key});

  final DiagnosticsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final List<OperationTimeline> operations = controller.operations;
      if (operations.isEmpty) {
        return _empty(context);
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: operations.length,
        itemBuilder: (BuildContext context, int index) =>
            _OperationCard(timeline: operations[index], controller: controller),
      );
    });
  }

  Widget _empty(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.timeline, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No operations recorded', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              'Operations are created by the actions worth correlating: engine start-up, '
              'APK import, clone creation, launch and delete.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({required this.timeline, required this.controller});

  final OperationTimeline timeline;
  final DiagnosticsController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color outcomeColor = DiagnosticVisuals.colorFor(context, timeline.outcome);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OperationTimelineView(
                operationId: timeline.operationId,
                controller: controller,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: outcomeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        timeline.name,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  timeline.operationId,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: <Widget>[
                    DiagnosticTag(
                      label: timeline.failed ? 'FAILED' : timeline.outcome.wire,
                      color: outcomeColor,
                      icon: DiagnosticVisuals.iconFor(timeline.outcome),
                    ),
                    DiagnosticTag(label: '${timeline.events.length} events'),
                    DiagnosticTag(
                      label: '${timeline.duration?.inMilliseconds ?? 0} ms',
                    ),
                  ],
                ),
                if (timeline.failures.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  // The first failure, not the last: in a timeline the earliest error is
                  // usually the cause and everything after it is consequence.
                  Text(
                    timeline.failures.first.message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
