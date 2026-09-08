import 'package:flutter/material.dart';

import '../../../app/theme/status_colors.dart';
import '../../../core/diagnostics/diagnostic_event.dart';

/// How a level is painted.
///
/// Colours come from the theme, never from literals: the console is a screen inside
/// Duplika, not a separate tool, and a hard-coded red here would be the one thing in
/// the app that ignores dark mode.
///
/// Severity is carried by colour *and* by the level's own word, so it survives a
/// grayscale screenshot in a bug report and does not depend on colour vision.
class DiagnosticVisuals {
  const DiagnosticVisuals._();

  static Color colorFor(BuildContext context, DiagLevel level) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final StatusColors status = StatusColors.of(context);
    return switch (level) {
      DiagLevel.debug => scheme.onSurfaceVariant,
      DiagLevel.info => scheme.onSurfaceVariant,
      DiagLevel.success => status.positive,
      DiagLevel.warning => status.warning,
      DiagLevel.error => scheme.error,
      // Fatal shares `error`'s colour and is separated by weight and label instead.
      // A second red would read as a different kind of problem rather than a worse one.
      DiagLevel.fatal => scheme.error,
    };
  }

  static IconData iconFor(DiagLevel level) => switch (level) {
        DiagLevel.debug => Icons.bug_report_outlined,
        DiagLevel.info => Icons.info_outline,
        DiagLevel.success => Icons.check_circle_outline,
        DiagLevel.warning => Icons.warning_amber_outlined,
        DiagLevel.error => Icons.error_outline,
        DiagLevel.fatal => Icons.dangerous_outlined,
      };

  static FontWeight weightFor(DiagLevel level) =>
      level == DiagLevel.fatal ? FontWeight.w800 : FontWeight.w700;
}

/// A small labelled pill. Used for levels, sources, categories and operation ids.
class DiagnosticTag extends StatelessWidget {
  const DiagnosticTag({
    required this.label,
    this.color,
    this.icon,
    this.onTap,
    super.key,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color tint = color ?? theme.colorScheme.onSurfaceVariant;

    final Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        // A tinted fill rather than a solid one: a row can carry three of these, and
        // three solid blocks of colour would compete with the message itself.
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: tint),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: content,
    );
  }
}

/// Monospaced block for stack traces and raw payloads.
class DiagnosticCodeBlock extends StatelessWidget {
  const DiagnosticCodeBlock({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      // Horizontal scrolling rather than wrapping: a wrapped stack frame is much harder
      // to read than one that runs off the edge.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          text,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontFamilyFallback: <String>['Roboto Mono', 'Menlo', 'Courier'],
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}
