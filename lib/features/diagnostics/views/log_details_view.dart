import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/diagnostics/diagnostic_event.dart';
import '../controllers/diagnostics_controller.dart';
import '../widgets/diagnostic_visuals.dart';
import '../widgets/log_event_tile.dart';
import 'operation_timeline_view.dart';

/// Everything recorded about one event, plus the events around it.
///
/// The neighbours matter as much as the event: an error on its own says what broke, and
/// the five lines before it usually say why. Two kinds of context are offered — the
/// same operation, and simple adjacency — because an error that was never given an
/// operation id still has a story before it.
class LogDetailsView extends StatelessWidget {
  const LogDetailsView({
    required this.event,
    required this.controller,
    super.key,
  });

  final DiagnosticEvent event;
  final DiagnosticsController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color levelColor = DiagnosticVisuals.colorFor(context, event.level);
    final List<DiagnosticEvent> related = controller.relatedTo(event);
    final List<DiagnosticEvent> neighbours = controller.neighboursOf(event);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event details'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Copy as text',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () => _copy(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          Row(
            children: <Widget>[
              DiagnosticTag(
                label: event.level.wire,
                color: levelColor,
                icon: DiagnosticVisuals.iconFor(event.level),
              ),
              const SizedBox(width: 6),
              DiagnosticTag(label: event.source.wire),
              const SizedBox(width: 6),
              DiagnosticTag(label: event.category.wire),
            ],
          ),
          const SizedBox(height: 14),
          SelectableText(
            event.message,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: DiagnosticVisuals.weightFor(event.level),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            DiagnosticEvent.formatFullTimestamp(event.timestamp),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          _facts(context),
          if (event.details != null && event.details!.isNotEmpty) ...<Widget>[
            _heading(theme, 'Details'),
            DiagnosticCodeBlock(text: event.details!),
          ],
          if (event.metadata.isNotEmpty) ...<Widget>[
            _heading(theme, 'Metadata'),
            DiagnosticCodeBlock(
              text: event.metadata.entries
                  .map((MapEntry<String, String> e) => '${e.key}: ${e.value}')
                  .join('\n'),
            ),
          ],
          if (event.stackTrace != null && event.stackTrace!.isNotEmpty) ...<Widget>[
            _heading(theme, 'Stack trace'),
            DiagnosticCodeBlock(text: event.stackTrace!),
          ] else if (event.isFailure) ...<Widget>[
            _heading(theme, 'Stack trace'),
            // Stated rather than omitted. A failure with no trace is a real category —
            // an engine verdict returned as data, a native crash whose tombstone the app
            // cannot read — and an empty space would look like a bug in the console.
            Text(
              'No stack trace was captured for this event. Engine and platform failures '
              'that arrive as a result code carry a message and an error code but no '
              'Dart or JVM trace.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (event.operation != null) ...<Widget>[
            _heading(theme, 'Operation'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.timeline),
                title: Text(event.operationName ?? event.operation!),
                subtitle: Text(
                  '${event.operation}  ·  ${related.length + 1} event(s)',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OperationTimelineView(
                      operationId: event.operation!,
                      controller: controller,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (neighbours.length > 1) ...<Widget>[
            _heading(theme, 'Events around this one'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  for (int index = 0; index < neighbours.length; index++) ...<Widget>[
                    if (index > 0) const Divider(height: 1),
                    Container(
                      color: neighbours[index].id == event.id
                          ? theme.colorScheme.primary.withValues(alpha: 0.07)
                          : null,
                      child: LogEventTile(event: neighbours[index], dense: true),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _facts(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<(String, String?)> rows = <(String, String?)>[
      ('Event id', event.id),
      ('Exception type', event.exceptionType),
      ('Package', event.packageName),
      ('Profile', event.profileId),
      ('Virtual user', event.virtualUserId?.toString()),
      ('Process', event.processName),
      ('Thread', event.thread),
      ('Build', event.buildType),
      ('App version', event.appVersion),
      ('Device', event.deviceInfo),
    ].where((( String, String?) row) => row.$2 != null && row.$2!.isNotEmpty).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final (String label, String? value) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 108,
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        value!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontFamilyFallback: <String>['Roboto Mono', 'Menlo', 'Courier'],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _heading(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 8),
        child: Text(text, style: theme.textTheme.titleSmall),
      );

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: event.toLogLine()));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Event copied.')));
    }
  }
}
