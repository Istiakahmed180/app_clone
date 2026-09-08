import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/diagnostics/diagnostic_event.dart';
import '../../../core/diagnostics/diagnostics_repository.dart';
import '../controllers/diagnostics_controller.dart';
import '../widgets/diagnostic_visuals.dart';
import 'log_details_view.dart';

/// One operation, start to finish.
///
/// Always oldest-first, unlike the live log: this screen exists to be read as a
/// sequence, and a sequence read backwards is not one.
///
/// The connector between rows is what makes it a timeline rather than a filtered list —
/// it shows that these events are consecutive steps of the same thing, and the gap
/// label shows where the time actually went.
class OperationTimelineView extends StatelessWidget {
  const OperationTimelineView({
    required this.operationId,
    required this.controller,
    super.key,
  });

  final String operationId;
  final DiagnosticsController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OperationTimeline timeline = controller.timelineFor(operationId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operation timeline'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Copy timeline',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () => _copy(context, timeline),
          ),
          IconButton(
            tooltip: 'Filter the live log to this operation',
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {
              controller.focusOperation(operationId);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: timeline.events.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No events are loaded for $operationId.\n\nIt may have aged out of '
                  'the retained window, or been cleared.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: <Widget>[
                _header(context, timeline),
                const SizedBox(height: 16),
                for (int index = 0; index < timeline.events.length; index++)
                  _TimelineRow(
                    event: timeline.events[index],
                    previous: index == 0 ? null : timeline.events[index - 1],
                    isFirst: index == 0,
                    isLast: index == timeline.events.length - 1,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LogDetailsView(
                          event: timeline.events[index],
                          controller: controller,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _header(BuildContext context, OperationTimeline timeline) {
    final ThemeData theme = Theme.of(context);
    final Color outcomeColor = DiagnosticVisuals.colorFor(context, timeline.outcome);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(timeline.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            SelectableText(
              timeline.operationId,
              style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                DiagnosticTag(
                  label: timeline.failed ? 'FAILED' : timeline.outcome.wire,
                  color: outcomeColor,
                  icon: DiagnosticVisuals.iconFor(timeline.outcome),
                ),
                DiagnosticTag(label: '${timeline.events.length} events'),
                DiagnosticTag(label: '${timeline.duration?.inMilliseconds ?? 0} ms'),
                if (timeline.failures.isNotEmpty)
                  DiagnosticTag(
                    label: '${timeline.failures.length} failure(s)',
                    color: theme.colorScheme.error,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, OperationTimeline timeline) async {
    final String text = <String>[
      'Operation ${timeline.operationId} — ${timeline.name}',
      'Outcome: ${timeline.outcome.wire}, '
          '${timeline.duration?.inMilliseconds ?? 0} ms, '
          '${timeline.events.length} events',
      '',
      ...timeline.events.map((DiagnosticEvent event) => event.toLogLine()),
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Timeline copied.')));
    }
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.event,
    required this.previous,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final DiagnosticEvent event;
  final DiagnosticEvent? previous;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = DiagnosticVisuals.colorFor(context, event.level);
    final int gapMs = previous == null
        ? 0
        : event.timestamp.difference(previous!.timestamp).inMilliseconds;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 28,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : theme.colorScheme.outlineVariant,
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 2),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : theme.colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 4, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          DiagnosticEvent.formatTimestamp(event.timestamp),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        // Only worth showing once a step actually took time; every row
                        // reading "+0 ms" would be noise.
                        if (gapMs >= 50) ...<Widget>[
                          const SizedBox(width: 6),
                          Text(
                            '+$gapMs ms',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        DiagnosticTag(label: event.level.wire, color: color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: event.isFailure ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: <Widget>[
                        DiagnosticTag(label: '${event.source.wire}/${event.category.wire}'),
                        if (event.metadata['event'] != null)
                          DiagnosticTag(
                            label: event.metadata['event']!,
                            color: theme.colorScheme.primary,
                          ),
                        if (event.virtualUserId != null)
                          DiagnosticTag(label: 'vuser ${event.virtualUserId}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
