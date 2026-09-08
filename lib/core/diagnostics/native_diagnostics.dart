import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'diagnostic_event.dart';
import 'diagnostic_logger.dart';
import 'system_info.dart';

/// Result of a manual subsystem probe (storage, WebView).
///
/// Reuses [SystemInfoSection] so a probe's findings can be rendered by the same widget
/// as the system information screen and written by the same exporter.
@immutable
class NativeProbeResult {
  const NativeProbeResult({
    required this.sections,
    required this.text,
    this.eventCount = 0,
  });

  factory NativeProbeResult.fromMap(Map<String, dynamic> map) {
    final Object? rawSections = map['sections'];
    final List<SystemInfoSection> sections = <SystemInfoSection>[];
    if (rawSections is List) {
      for (final Object? rawSection in rawSections) {
        if (rawSection is! Map) {
          continue;
        }
        final Object? rawFields = rawSection['fields'];
        sections.add(
          SystemInfoSection(
            '${rawSection['title'] ?? 'Section'}',
            rawFields is List
                ? rawFields
                    .whereType<Map<Object?, Object?>>()
                    .map(
                      (Map<Object?, Object?> field) => SystemInfoField(
                        '${field['label'] ?? ''}',
                        '${field['value'] ?? ''}',
                      ),
                    )
                    .toList(growable: false)
                : const <SystemInfoField>[],
          ),
        );
      }
    }
    return NativeProbeResult(
      sections: sections,
      text: map['text'] as String? ?? '',
      eventCount: map['eventCount'] as int? ?? 0,
    );
  }

  final List<SystemInfoSection> sections;

  /// The same findings as plain text, for the export bundle.
  final String text;

  /// How many diagnostic events the probe emitted.
  final int eventCount;
}

/// The Dart end of the native diagnostics channels.
///
/// Two channels, because the two jobs have different shapes: a method channel for
/// request/response (system info, history, probes) and an event channel for the live
/// stream. Live events could have been polled over the method channel, but polling
/// either lags or burns battery, and the native side already knows when it has
/// something to say.
class NativeDiagnostics {
  NativeDiagnostics({
    MethodChannel? methods,
    EventChannel? events,
    this._logger,
  })  : _methods = methods ?? const MethodChannel(methodChannelName),
        _events = events ?? const EventChannel(eventChannelName);

  static const String methodChannelName = 'duplika/diagnostics';
  static const String eventChannelName = 'duplika/diagnostics/events';

  final MethodChannel _methods;
  final EventChannel _events;
  final DiagnosticLogger? _logger;

  StreamSubscription<dynamic>? _subscription;

  DiagnosticLogger get _sink => _logger ?? DiagnosticLogger.instance;

  /// Whether the platform answered the last call. False on a host with no native side
  /// (unit tests, desktop), which the console reports rather than hiding.
  bool get isAvailable => _available;
  bool _available = true;

  /// Starts forwarding live native events into the central logger.
  ///
  /// Attached at app start rather than when the console opens, so events that happen
  /// before anyone looks are still recorded — which is the whole point of having a
  /// console to look at afterwards.
  Future<void> attach() async {
    if (_subscription != null) {
      return;
    }
    try {
      _subscription = _events.receiveBroadcastStream().listen(
        _onNativeEvent,
        onError: (Object error, StackTrace stackTrace) {
          // The stream itself failing is worth one event, not a retry loop: the native
          // side re-sends its buffered events when a listener next attaches.
          _sink.warning(
            DiagnosticSource.methodChannel,
            DiagnosticCategory.appLifecycle,
            'The native diagnostics stream reported an error',
            error: error,
            stackTrace: stackTrace,
          );
        },
        cancelOnError: false,
      );
    } on MissingPluginException {
      _available = false;
    }
  }

  Future<void> detach() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _onNativeEvent(Object? payload) {
    if (payload is! Map) {
      return;
    }
    _sink.recordExternal(
      DiagnosticEvent.fromJson(
        payload.map((Object? key, Object? value) => MapEntry<String, dynamic>('$key', value)),
      ),
    );
  }

  /// The native history, read from the per-process log files on disk.
  ///
  /// Native events are persisted natively rather than being pushed to Dart and stored
  /// there, because guest apps run in separate host processes (`:p0`, `:p1`, ...) where
  /// no Flutter engine exists. A launch failure inside one of those processes can only
  /// be recovered from a file the main process reads back.
  Future<List<DiagnosticEvent>> readHistory({int limit = 2000}) async {
    final Object? result = await _invoke('readEvents', <String, dynamic>{'limit': limit});
    if (result is! List) {
      return const <DiagnosticEvent>[];
    }
    return result
        .whereType<Map<Object?, Object?>>()
        .map(
          (Map<Object?, Object?> raw) => DiagnosticEvent.fromJson(
            raw.map((Object? k, Object? v) => MapEntry<String, dynamic>('$k', v)),
          ),
        )
        .toList(growable: false);
  }

  Future<SystemInfoSnapshot> systemInfo() async {
    final Object? result = await _invoke('getSystemInfo');
    if (result is! Map) {
      return SystemInfoSnapshot.unavailable(
        'The native diagnostics channel did not answer on this platform.',
      );
    }
    final Map<String, dynamic> map = result.map(
      (Object? key, Object? value) => MapEntry<String, dynamic>('$key', value),
    );
    _sink.describeEnvironment(
      appVersion: map['appVersion'] as String?,
      deviceInfo: map['model'] as String?,
      processName: map['processName'] as String?,
    );
    return SystemInfoSnapshot.from(map);
  }

  Future<void> clearHistory() => _invoke('clearEvents');

  /// Runs the storage probe on demand. Read-only except for a write test inside
  /// Duplika's own directories.
  Future<NativeProbeResult> runStorageDiagnostics() async =>
      _probe('runStorageDiagnostics');

  Future<NativeProbeResult> runWebViewDiagnostics() => _probe('runWebViewDiagnostics');

  Future<NativeProbeResult> runPermissionDiagnostics() =>
      _probe('runPermissionDiagnostics');

  Future<NativeProbeResult> runNotificationDiagnostics() =>
      _probe('runNotificationDiagnostics');

  Future<NativeProbeResult> runJobDiagnostics() => _probe('runJobDiagnostics');

  /// Hands the exported report files to the Android share sheet.
  ///
  /// Returns false when nothing could be shared. Sharing goes through a `FileProvider`
  /// content URI with a temporary read grant, so no storage permission is involved and
  /// the files never leave Duplika's own cache.
  Future<bool> shareReport(List<String> paths, {String? subject}) async {
    final Object? result = await _invoke('shareReport', <String, dynamic>{
      'paths': paths,
      'subject': ?subject,
    });
    return result == true;
  }

  /// Raises a real exception inside the Kotlin logger and returns nothing.
  ///
  /// Exists so "does native capture actually work on this build" can be answered on a
  /// device instead of assumed. The event it produces is labelled as a self-test, so
  /// it can never be mistaken for a genuine failure.
  Future<void> raiseNativeSelfTest() => _invoke('selfTest');

  Future<NativeProbeResult> _probe(String method) async {
    final Object? result = await _invoke(method);
    if (result is! Map) {
      return const NativeProbeResult(
        sections: <SystemInfoSection>[],
        text: 'This probe is not available on this platform.',
      );
    }
    return NativeProbeResult.fromMap(
      result.map((Object? key, Object? value) => MapEntry<String, dynamic>('$key', value)),
    );
  }

  /// Every failure mode here is reported as a diagnostic and then swallowed: the
  /// console must still open when the channel is broken, since a broken channel is one
  /// of the things a developer opens it to find out about.
  Future<Object?> _invoke(String method, [Map<String, dynamic>? arguments]) async {
    try {
      final Object? result = await _methods.invokeMethod<Object?>(method, arguments);
      _available = true;
      return result;
    } on MissingPluginException {
      _available = false;
      return null;
    } on PlatformException catch (error, stackTrace) {
      _available = false;
      _sink.error(
        DiagnosticSource.methodChannel,
        DiagnosticCategory.unknown,
        'Native diagnostics call "$method" failed',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
