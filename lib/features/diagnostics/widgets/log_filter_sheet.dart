import 'package:flutter/material.dart';

import '../../../core/diagnostics/diagnostic_event.dart';
import '../../../core/diagnostics/diagnostic_filter.dart';
import 'diagnostic_visuals.dart';

/// Opens the filter editor and returns the chosen filter, or null if dismissed.
Future<DiagnosticFilter?> showDiagnosticFilterSheet(
  BuildContext context, {
  required DiagnosticFilter current,
  required List<String> packages,
  required List<String> profiles,
}) {
  return showModalBottomSheet<DiagnosticFilter>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) => _FilterSheet(
      initial: current,
      packages: packages,
      profiles: profiles,
    ),
  );
}

/// The filter editor.
///
/// Edits a working copy and only returns it on Apply. Filtering live as chips are
/// tapped sounds friendlier but makes the sheet fight the list underneath it, and
/// there is no way back to what you had before you started tapping.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initial,
    required this.packages,
    required this.profiles,
  });

  final DiagnosticFilter initial;
  final List<String> packages;
  final List<String> profiles;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late DiagnosticFilter _draft = widget.initial;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text('Filters', style: theme.textTheme.titleLarge),
                ),
                TextButton(
                  onPressed: () => setState(() => _draft = DiagnosticFilter.none),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _heading(theme, 'Minimum level'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final DiagLevel level in DiagLevel.values)
                          FilterChip(
                            label: Text(level.wire),
                            selected: _draft.minimumLevel == level,
                            selectedColor: DiagnosticVisuals.colorFor(context, level)
                                .withValues(alpha: 0.18),
                            onSelected: (bool selected) => setState(() {
                              _draft = selected
                                  ? _draft.copyWith(minimumLevel: level)
                                  : _draft.copyWith(clearMinimumLevel: true);
                            }),
                          ),
                      ],
                    ),
                    _heading(theme, 'Exact levels'),
                    _chipSet<DiagLevel>(
                      values: DiagLevel.values,
                      selected: _draft.levels,
                      labelOf: (DiagLevel level) => level.wire,
                      onChanged: (Set<DiagLevel> next) =>
                          setState(() => _draft = _draft.copyWith(levels: next)),
                    ),
                    _heading(theme, 'Sources'),
                    _chipSet<DiagnosticSource>(
                      values: DiagnosticSource.values,
                      selected: _draft.sources,
                      labelOf: (DiagnosticSource source) => source.wire,
                      onChanged: (Set<DiagnosticSource> next) =>
                          setState(() => _draft = _draft.copyWith(sources: next)),
                    ),
                    _heading(theme, 'Categories'),
                    _chipSet<DiagnosticCategory>(
                      values: DiagnosticCategory.values,
                      selected: _draft.categories,
                      labelOf: (DiagnosticCategory category) => category.wire,
                      onChanged: (Set<DiagnosticCategory> next) =>
                          setState(() => _draft = _draft.copyWith(categories: next)),
                    ),
                    if (widget.packages.isNotEmpty) ...<Widget>[
                      _heading(theme, 'Packages'),
                      _chipSet<String>(
                        values: widget.packages,
                        selected: _draft.packageNames,
                        labelOf: (String value) => value,
                        onChanged: (Set<String> next) =>
                            setState(() => _draft = _draft.copyWith(packageNames: next)),
                      ),
                    ],
                    if (widget.profiles.isNotEmpty) ...<Widget>[
                      _heading(theme, 'Profiles'),
                      _chipSet<String>(
                        values: widget.profiles,
                        selected: _draft.profileIds,
                        // Profile ids are UUIDs; the first segment is enough to tell
                        // them apart and short enough to fit on a chip.
                        labelOf: (String value) => value.split('-').first,
                        onChanged: (Set<String> next) =>
                            setState(() => _draft = _draft.copyWith(profileIds: next)),
                      ),
                    ],
                    if (_draft.operationId != null) ...<Widget>[
                      _heading(theme, 'Operation'),
                      InputChip(
                        label: Text(_draft.operationId!),
                        onDeleted: () => setState(
                          () => _draft = _draft.copyWith(clearOperationId: true),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_draft),
                child: Text(
                  _draft.isActive ? 'Apply ${_draft.activeCount} filter(s)' : 'Show everything',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(text, style: theme.textTheme.titleSmall),
      );

  Widget _chipSet<T>({
    required List<T> values,
    required Set<T> selected,
    required String Function(T value) labelOf,
    required ValueChanged<Set<T>> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final T value in values)
          FilterChip(
            label: Text(labelOf(value)),
            selected: selected.contains(value),
            onSelected: (bool isSelected) {
              final Set<T> next = Set<T>.of(selected);
              if (isSelected) {
                next.add(value);
              } else {
                next.remove(value);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}
