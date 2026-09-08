import 'package:flutter/foundation.dart';

import 'diagnostic_event.dart';

/// What the console is currently showing.
///
/// Immutable and value-compared so the controller can tell a real filter change from
/// a rebuild, and so "reset filters" is a single assignment rather than clearing six
/// separate pieces of state.
///
/// An empty set means "no restriction on this axis", not "show nothing" — the
/// alternative would make an empty filter chip row hide the whole log.
@immutable
class DiagnosticFilter {
  const DiagnosticFilter({
    this.minimumLevel,
    this.levels = const <DiagLevel>{},
    this.sources = const <DiagnosticSource>{},
    this.categories = const <DiagnosticCategory>{},
    this.packageNames = const <String>{},
    this.profileIds = const <String>{},
    this.operationId,
    this.query = '',
  });

  static const DiagnosticFilter none = DiagnosticFilter();

  /// "This level and above". Independent of [levels]: a developer either picks exact
  /// levels or sets a floor, and mixing the two silently is how a filter starts lying.
  final DiagLevel? minimumLevel;

  final Set<DiagLevel> levels;
  final Set<DiagnosticSource> sources;
  final Set<DiagnosticCategory> categories;
  final Set<String> packageNames;
  final Set<String> profileIds;
  final String? operationId;

  /// Free-text search across message, details, exception type and operation id.
  final String query;

  bool get isActive =>
      minimumLevel != null ||
      levels.isNotEmpty ||
      sources.isNotEmpty ||
      categories.isNotEmpty ||
      packageNames.isNotEmpty ||
      profileIds.isNotEmpty ||
      operationId != null ||
      query.trim().isNotEmpty;

  /// How many axes are restricted, for the "Filters (3)" affordance.
  int get activeCount => <bool>[
        minimumLevel != null,
        levels.isNotEmpty,
        sources.isNotEmpty,
        categories.isNotEmpty,
        packageNames.isNotEmpty,
        profileIds.isNotEmpty,
        operationId != null,
        query.trim().isNotEmpty,
      ].where((bool active) => active).length;

  bool matches(DiagnosticEvent event) {
    if (minimumLevel != null && event.level.severity < minimumLevel!.severity) {
      return false;
    }
    if (levels.isNotEmpty && !levels.contains(event.level)) {
      return false;
    }
    if (sources.isNotEmpty && !sources.contains(event.source)) {
      return false;
    }
    if (categories.isNotEmpty && !categories.contains(event.category)) {
      return false;
    }
    if (packageNames.isNotEmpty &&
        (event.packageName == null || !packageNames.contains(event.packageName))) {
      return false;
    }
    if (profileIds.isNotEmpty &&
        (event.profileId == null || !profileIds.contains(event.profileId))) {
      return false;
    }
    if (operationId != null && event.operation != operationId) {
      return false;
    }

    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    return event.message.toLowerCase().contains(needle) ||
        (event.details?.toLowerCase().contains(needle) ?? false) ||
        (event.exceptionType?.toLowerCase().contains(needle) ?? false) ||
        (event.operation?.toLowerCase().contains(needle) ?? false) ||
        (event.packageName?.toLowerCase().contains(needle) ?? false) ||
        event.source.wire.toLowerCase().contains(needle) ||
        event.category.wire.toLowerCase().contains(needle);
  }

  DiagnosticFilter copyWith({
    DiagLevel? minimumLevel,
    bool clearMinimumLevel = false,
    Set<DiagLevel>? levels,
    Set<DiagnosticSource>? sources,
    Set<DiagnosticCategory>? categories,
    Set<String>? packageNames,
    Set<String>? profileIds,
    String? operationId,
    bool clearOperationId = false,
    String? query,
  }) =>
      DiagnosticFilter(
        minimumLevel: clearMinimumLevel ? null : (minimumLevel ?? this.minimumLevel),
        levels: levels ?? this.levels,
        sources: sources ?? this.sources,
        categories: categories ?? this.categories,
        packageNames: packageNames ?? this.packageNames,
        profileIds: profileIds ?? this.profileIds,
        operationId: clearOperationId ? null : (operationId ?? this.operationId),
        query: query ?? this.query,
      );

  /// A short human description, used in the export header so a partial report says
  /// what it was filtered to.
  String describe() {
    if (!isActive) {
      return 'no filter';
    }
    final List<String> parts = <String>[
      if (minimumLevel != null) '>= ${minimumLevel!.wire}',
      if (levels.isNotEmpty)
        'levels: ${levels.map((DiagLevel l) => l.wire).join('/')}',
      if (sources.isNotEmpty)
        'sources: ${sources.map((DiagnosticSource s) => s.wire).join('/')}',
      if (categories.isNotEmpty)
        'categories: ${categories.map((DiagnosticCategory c) => c.wire).join('/')}',
      if (packageNames.isNotEmpty) 'packages: ${packageNames.join('/')}',
      if (profileIds.isNotEmpty) 'profiles: ${profileIds.join('/')}',
      if (operationId != null) 'operation: $operationId',
      if (query.trim().isNotEmpty) 'search: "${query.trim()}"',
    ];
    return parts.join('; ');
  }

  @override
  bool operator ==(Object other) =>
      other is DiagnosticFilter &&
      other.minimumLevel == minimumLevel &&
      setEquals(other.levels, levels) &&
      setEquals(other.sources, sources) &&
      setEquals(other.categories, categories) &&
      setEquals(other.packageNames, packageNames) &&
      setEquals(other.profileIds, profileIds) &&
      other.operationId == operationId &&
      other.query == query;

  @override
  int get hashCode => Object.hash(
        minimumLevel,
        Object.hashAllUnordered(levels),
        Object.hashAllUnordered(sources),
        Object.hashAllUnordered(categories),
        Object.hashAllUnordered(packageNames),
        Object.hashAllUnordered(profileIds),
        operationId,
        query,
      );
}
