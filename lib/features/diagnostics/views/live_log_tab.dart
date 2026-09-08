import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/diagnostics/diagnostic_event.dart';
import '../../../core/diagnostics/diagnostic_filter.dart';
import '../controllers/diagnostics_controller.dart';
import '../widgets/log_event_tile.dart';
import '../widgets/log_filter_sheet.dart';
import 'log_details_view.dart';
import 'operation_timeline_view.dart';

/// The live log: search, filters, ordering, and the events themselves.
class LiveLogTab extends StatefulWidget {
  const LiveLogTab({required this.controller, super.key});

  final DiagnosticsController controller;

  @override
  State<LiveLogTab> createState() => _LiveLogTabState();
}

class _LiveLogTabState extends State<LiveLogTab> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();

  Worker? _autoScrollWorker;

  DiagnosticsController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // Auto-scroll follows the list rather than driving it: the list is newest-first by
    // default, in which case "follow" means staying at offset zero, and only in
    // oldest-first order does it mean chasing the bottom.
    _autoScrollWorker = ever<List<DiagnosticEvent>>(controller.visible, (_) {
      if (!controller.autoScroll.value || controller.isPaused.value) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) {
          return;
        }
        final double target =
            controller.newestFirst.value ? 0 : _scroll.position.maxScrollExtent;
        _scroll.jumpTo(target);
      });
    });
  }

  @override
  void dispose() {
    _autoScrollWorker?.dispose();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _toolbar(context),
        const Divider(height: 1),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.visible.isEmpty) {
              return _empty(context);
            }
            return ListView.separated(
              controller: _scroll,
              // Physics left at the default: a log the user is reading must not be
              // yanked by an arriving event, which is what auto-scroll is a toggle for.
              itemCount: controller.visible.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                final DiagnosticEvent event = controller.visible[index];
                return LogEventTile(
                  event: event,
                  onTap: () => _openDetails(event),
                  onOperationTap: _openTimeline,
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _toolbar(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _search,
            onChanged: controller.setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search message, exception, package, operation',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: Obx(
                () => controller.filter.value.query.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _search.clear();
                          controller.setQuery('');
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  ActionChip(
                    avatar: const Icon(Icons.filter_alt_outlined, size: 16),
                    label: Text(
                      controller.filter.value.activeCount > 0
                          ? 'Filters (${controller.filter.value.activeCount})'
                          : 'Filters',
                    ),
                    onPressed: _openFilters,
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: Icon(
                      controller.newestFirst.value
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      size: 16,
                    ),
                    label: Text(controller.newestFirst.value ? 'Newest first' : 'Oldest first'),
                    onPressed: controller.toggleOrder,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    avatar: const Icon(Icons.vertical_align_bottom, size: 16),
                    label: const Text('Auto-scroll'),
                    selected: controller.autoScroll.value,
                    onSelected: (_) => controller.toggleAutoScroll(),
                  ),
                  if (controller.filter.value.isActive) ...<Widget>[
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear filters'),
                      onPressed: () {
                        _search.clear();
                        controller.clearFilter();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Obx(
            () => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _statusLine(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLine() {
    final int shown = controller.visible.length;
    final int total = controller.totalLoaded;
    final StringBuffer buffer = StringBuffer('$shown of $total events');
    if (controller.isPaused.value) {
      buffer.write(' · paused');
    }
    if (!controller.nativeAvailable) {
      // Said out loud rather than left as an empty-looking log: "no native events" and
      // "the native channel never answered" are very different findings.
      buffer.write(' · native channel unavailable');
    }
    return buffer.toString();
  }

  Widget _empty(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool filtered = controller.filter.value.isActive;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              filtered ? Icons.filter_alt_off_outlined : Icons.inbox_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              filtered ? 'No events match these filters' : 'No events recorded yet',
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              filtered
                  ? controller.filter.value.describe()
                  : 'Use the app — import an APK, launch a clone — and the sequence '
                      'will appear here.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilters() async {
    final DiagnosticFilter? next = await showDiagnosticFilterSheet(
      context,
      current: controller.filter.value,
      packages: controller.knownPackages,
      profiles: controller.knownProfiles,
    );
    if (next != null) {
      controller.applyFilter(next);
      _search.text = next.query;
    }
  }

  void _openDetails(DiagnosticEvent event) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LogDetailsView(event: event, controller: controller),
        ),
      );

  void _openTimeline(String operationId) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OperationTimelineView(
            operationId: operationId,
            controller: controller,
          ),
        ),
      );
}
