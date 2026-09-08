import 'package:flutter/material.dart';

import '../../../core/diagnostics/diagnostic_event.dart';
import 'diagnostic_visuals.dart';

/// One row of the live log.
///
/// Laid out for scanning, in the order the questions get asked: when, how bad, which
/// subsystem, then what happened. The package and operation sit underneath, because
/// they are what you reach for only once a line has caught your eye.
class LogEventTile extends StatelessWidget {
  const LogEventTile({
    required this.event,
    this.onTap,
    this.onOperationTap,
    this.dense = false,
    super.key,
  });

  final DiagnosticEvent event;
  final VoidCallback? onTap;
  final ValueChanged<String>? onOperationTap;

  /// Drops the second line. Used inside the timeline and the "events around this one"
  /// panel, where the surrounding screen already states the operation.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color levelColor = DiagnosticVisuals.colorFor(context, event.level);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // A colour bar rather than an icon per row: at this density a column of
            // icons reads as texture, while a bar gives the eye a straight edge to
            // follow down the list.
            Container(
              width: 3,
              height: dense ? 28 : 38,
              margin: const EdgeInsets.only(top: 2, right: 10),
              decoration: BoxDecoration(
                color: levelColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
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
                      const SizedBox(width: 8),
                      DiagnosticTag(
                        label: event.level.wire,
                        color: levelColor,
                        icon: DiagnosticVisuals.iconFor(event.level),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: DiagnosticTag(label: event.source.wire),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.message,
                    maxLines: dense ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: event.isFailure ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (!dense) _metadataLine(context, theme),
                ],
              ),
            ),
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _metadataLine(BuildContext context, ThemeData theme) {
    final List<Widget> parts = <Widget>[
      if (event.packageName != null) DiagnosticTag(label: event.packageName!),
      if (event.operation != null)
        DiagnosticTag(
          label: event.operation!,
          icon: Icons.timeline,
          color: theme.colorScheme.primary,
          onTap: onOperationTap == null
              ? null
              : () => onOperationTap!(event.operation!),
        ),
      if (event.exceptionType != null)
        DiagnosticTag(
          label: event.exceptionType!.split('.').last,
          color: theme.colorScheme.error,
        ),
    ];

    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(spacing: 6, runSpacing: 4, children: parts),
    );
  }
}
