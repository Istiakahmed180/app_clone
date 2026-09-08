import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/diagnostics/diagnostic_event.dart';
import '../../../core/diagnostics/diagnostic_filter.dart';
import '../../../core/diagnostics/diagnostic_logger.dart';
import '../../../core/diagnostics/diagnostics_exporter.dart';
import '../../../core/diagnostics/diagnostics_repository.dart';
import '../../../core/diagnostics/native_diagnostics.dart';
import '../../../core/diagnostics/system_info.dart';

/// Which subsystem probe a card in the console refers to.
enum DiagnosticProbe {
  storage('Storage', 'Reads the paths and permissions this process actually has.'),
  webview('WebView', 'Process isolation and which WebView implementation is in use.'),
  permissions('Permissions', "The host's grants, which are what a guest is checked against."),
  notifications('Notifications', 'Channels and whether the host may post at all.'),
  jobs('Jobs', 'JobScheduler entries for this UID, guests included.');

  const DiagnosticProbe(this.label, this.description);

  final String label;
  final String description;
}

/// Backs the Developer Console.
///
/// Holds the view state (filters, pause, ordering) and leaves the merging and querying
/// of events to [DiagnosticsRepository], so the two can be reasoned about — and
/// tested — separately.
class DiagnosticsController extends GetxController {
  DiagnosticsController({
    DiagnosticsRepository? repository,
    DiagnosticsExporter? exporter,
  }) : repository = repository ?? DiagnosticsRepository() {
    // The exporter reads through the repository, so it can only be built once the
    // repository is resolved — hence the body rather than an initialiser.
    _exporter = exporter ?? DiagnosticsExporter(repository: this.repository);
  }

  final DiagnosticsRepository repository;
  late final DiagnosticsExporter _exporter;

  /// The events the list is currently showing, already filtered and ordered.
  final RxList<DiagnosticEvent> visible = <DiagnosticEvent>[].obs;

  final Rx<DiagnosticFilter> filter = DiagnosticFilter.none.obs;

  final RxBool isLoading = true.obs;

  /// Paused means "stop moving", not "stop recording". Events keep arriving and are
  /// counted; nothing is dropped, because the point of pausing is usually to read the
  /// line that just scrolled past.
  final RxBool isPaused = false.obs;
  final RxInt bufferedWhilePaused = 0.obs;

  final RxBool newestFirst = true.obs;
  final RxBool autoScroll = true.obs;

  final Rxn<SystemInfoSnapshot> systemInfo = Rxn<SystemInfoSnapshot>();
  final RxMap<DiagnosticProbe, NativeProbeResult> probeResults =
      <DiagnosticProbe, NativeProbeResult>{}.obs;
  final Rxn<DiagnosticProbe> runningProbe = Rxn<DiagnosticProbe>();

  /// One-line feedback for the last console action, shown as a snack bar by the view.
  final RxnString statusMessage = RxnString();
  final RxBool isExporting = false.obs;

  final List<DiagnosticEvent> _heldWhilePaused = <DiagnosticEvent>[];
  StreamSubscription<DiagnosticEvent>? _subscription;

  /// True in a release build. The console stays available — release compatibility is
  /// exactly what this project needs to test — but actions that could expose more than
  /// a report does are gated on it.
  bool get isReleaseBuild => kReleaseMode;

  bool get nativeAvailable => repository.nativeAvailable;

  int get totalLoaded => repository.events.length;

  int get failureCount => repository.recentFailures().length;

  List<String> get knownPackages => repository.knownPackages();

  List<String> get knownProfiles => repository.knownProfiles();

  List<DiagnosticEvent> get failures => repository.recentFailures();

  List<OperationTimeline> get operations => repository.operations();

  @override
  void onInit() {
    super.onInit();
    // Subscribed before the first load, so an event that arrives while the history is
    // being read is held rather than missed.
    _subscription = repository.liveEvents.listen(_onLiveEvent);
    reload();
    refreshSystemInfo();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _subscription = null;
    super.onClose();
  }

  Future<void> reload() async {
    isLoading.value = true;
    await repository.load();
    _recompute();
    isLoading.value = false;
  }

  Future<void> refreshSystemInfo() async {
    systemInfo.value = await repository.systemInfo();
  }

  void setQuery(String query) {
    if (filter.value.query == query) {
      return;
    }
    filter.value = filter.value.copyWith(query: query);
    _recompute();
  }

  void applyFilter(DiagnosticFilter next) {
    if (filter.value == next) {
      return;
    }
    filter.value = next;
    _recompute();
  }

  void clearFilter() => applyFilter(DiagnosticFilter.none);

  /// Narrows to one operation. Used by the timeline and by tapping an operation chip.
  void focusOperation(String operationId) =>
      applyFilter(DiagnosticFilter(operationId: operationId));

  void focusSource(DiagnosticSource source) =>
      applyFilter(DiagnosticFilter(sources: <DiagnosticSource>{source}));

  void focusPackage(String packageName) =>
      applyFilter(DiagnosticFilter(packageNames: <String>{packageName}));

  void toggleOrder() {
    newestFirst.toggle();
    _recompute();
  }

  void toggleAutoScroll() => autoScroll.toggle();

  void togglePause() {
    if (isPaused.value) {
      isPaused.value = false;
      // Held events are ingested in arrival order, so resuming shows what happened
      // rather than jumping to now.
      for (final DiagnosticEvent event in _heldWhilePaused) {
        _ingest(event);
      }
      _heldWhilePaused.clear();
      bufferedWhilePaused.value = 0;
    } else {
      isPaused.value = true;
    }
  }

  OperationTimeline timelineFor(String operationId) =>
      repository.timelineFor(operationId);

  List<DiagnosticEvent> relatedTo(DiagnosticEvent event) => repository.relatedTo(event);

  List<DiagnosticEvent> neighboursOf(DiagnosticEvent event) =>
      repository.neighboursOf(event);

  Future<void> runProbe(DiagnosticProbe probe) async {
    if (runningProbe.value != null) {
      return;
    }
    runningProbe.value = probe;
    try {
      final NativeProbeResult result = switch (probe) {
        DiagnosticProbe.storage => await repository.native.runStorageDiagnostics(),
        DiagnosticProbe.webview => await repository.native.runWebViewDiagnostics(),
        DiagnosticProbe.permissions => await repository.native.runPermissionDiagnostics(),
        DiagnosticProbe.notifications =>
          await repository.native.runNotificationDiagnostics(),
        DiagnosticProbe.jobs => await repository.native.runJobDiagnostics(),
      };
      probeResults[probe] = result;
      statusMessage.value = result.sections.isEmpty
          ? '${probe.label} diagnostics are not available on this platform.'
          : '${probe.label} diagnostics finished (${result.eventCount} event(s) recorded).';
    } finally {
      runningProbe.value = null;
    }
  }

  /// Raises a real exception in Kotlin so native capture can be verified on a device.
  Future<void> runNativeSelfTest() async {
    await repository.native.raiseNativeSelfTest();
    await reload();
    statusMessage.value = 'Native self-test raised. Look for the FATAL/ERROR pair in '
        'the KOTLIN source.';
  }

  /// Writes the report bundle and offers it to the Android share sheet.
  Future<void> exportAndShare() async {
    if (isExporting.value) {
      return;
    }
    isExporting.value = true;
    try {
      // Previous bundles are cleared first: they are unbounded copies of a bounded log,
      // and the cache is not the place to accumulate them.
      await _exporter.clearPrevious();
      final DiagnosticsExport export = await _exporter.write(
        filter: filter.value,
        systemInfo: systemInfo.value,
        subsystemReports: <String, NativeProbeResult>{
          for (final MapEntry<DiagnosticProbe, NativeProbeResult> entry
              in probeResults.entries)
            entry.key.name: entry.value,
        },
      );

      final bool shared = await repository.native.shareReport(
        export.files,
        subject: 'Duplika diagnostics '
            '(${export.eventCount} events, ${_formatBytes(export.totalBytes)})',
      );

      statusMessage.value = shared
          ? 'Exported ${export.files.length} file(s) and opened the share sheet.'
          : 'Exported ${export.files.length} file(s) to ${export.directory}. '
              'The share sheet could not be opened.';
    } catch (error, stackTrace) {
      DiagnosticLogger.instance.error(
        DiagnosticSource.flutter,
        DiagnosticCategory.appLifecycle,
        'Diagnostics export failed',
        error: error,
        stackTrace: stackTrace,
      );
      statusMessage.value = 'The export failed: $error';
    } finally {
      isExporting.value = false;
    }
  }

  /// Empties the in-memory buffer, the Dart store and the native store.
  Future<void> clearAll() async {
    await repository.clear();
    _heldWhilePaused.clear();
    bufferedWhilePaused.value = 0;
    probeResults.clear();
    _recompute();
    statusMessage.value = 'Diagnostic history cleared.';
  }

  void _onLiveEvent(DiagnosticEvent event) {
    if (isPaused.value) {
      _heldWhilePaused.add(event);
      bufferedWhilePaused.value = _heldWhilePaused.length;
      // Bounded even while paused: a console left paused overnight must not become the
      // app's largest allocation.
      if (_heldWhilePaused.length > DiagnosticsRepository.maxLoadedEvents) {
        _heldWhilePaused.removeAt(0);
      }
      return;
    }
    _ingest(event);
  }

  /// Inserts one event without re-filtering the whole window.
  ///
  /// A full recompute per event was measurably wasteful during a burst — an install
  /// emits dozens in a few hundred milliseconds — and the answer for a single event is
  /// exactly one predicate call plus one insert.
  void _ingest(DiagnosticEvent event) {
    if (!repository.add(event)) {
      return;
    }
    if (!filter.value.matches(event)) {
      return;
    }
    if (newestFirst.value) {
      visible.insert(0, event);
    } else {
      visible.add(event);
    }
    if (visible.length > DiagnosticsRepository.maxLoadedEvents) {
      if (newestFirst.value) {
        visible.removeLast();
      } else {
        visible.removeAt(0);
      }
    }
  }

  void _recompute() {
    final List<DiagnosticEvent> filtered = repository.filter(filter.value);
    visible.assignAll(
      newestFirst.value ? filtered.reversed.toList(growable: false) : filtered,
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
