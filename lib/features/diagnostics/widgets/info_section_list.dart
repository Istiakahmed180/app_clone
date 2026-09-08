import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/diagnostics/system_info.dart';

/// Renders labelled key/value blocks.
///
/// Shared by the System Information screen and by every subsystem probe, so a native
/// probe that adds a field needs no Dart change to be displayed.
class InfoSectionList extends StatelessWidget {
  const InfoSectionList({
    required this.sections,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
    this.emptyMessage = 'Nothing to show yet.',
    super.key,
  });

  final List<SystemInfoSection> sections;
  final EdgeInsetsGeometry padding;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: padding,
      itemCount: sections.length,
      itemBuilder: (BuildContext context, int index) =>
          _SectionCard(section: sections[index]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final SystemInfoSection section;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(section.title, style: theme.textTheme.titleSmall),
                  ),
                  IconButton(
                    tooltip: 'Copy this section',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.copy_all_outlined, size: 18),
                    onPressed: () => _copy(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              for (final SystemInfoField field in section.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        field.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Selectable, because half of what these rows are for is being
                      // pasted into a bug report or a shell command.
                      SelectableText(
                        field.value,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontFamilyFallback: <String>['Roboto Mono', 'Menlo', 'Courier'],
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final String text = <String>[
      section.title,
      ...section.fields.map((SystemInfoField f) => '${f.label}: ${f.value}'),
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${section.title} copied.')));
    }
  }
}
