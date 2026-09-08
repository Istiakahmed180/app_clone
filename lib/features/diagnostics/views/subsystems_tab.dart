import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/diagnostics/diagnostic_event.dart';
import '../../../core/diagnostics/native_diagnostics.dart';
import '../controllers/diagnostics_controller.dart';
import '../widgets/info_section_list.dart';

/// Manual probes, plus shortcuts into the log for each subsystem.
///
/// The probes are on demand rather than continuous on purpose. Instrumenting every
/// filesystem call or permission check would produce thousands of events a second
/// during a media scan and bury everything else; a probe answers the same question at
/// the moment it is asked, and says so in the log when it ran.
class SubsystemsTab extends StatelessWidget {
  const SubsystemsTab({required this.controller, super.key});

  final DiagnosticsController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Deliberately not wrapped in a single Obx. This list is static; the reactive
    // state — which probe is running, and what it found — belongs to the individual
    // cards, and an Obx whose own builder reads no observable is an error in GetX.
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        if (!controller.nativeAvailable)
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'The native diagnostics channel is not answering, so probes cannot '
                'run. On Android this means the platform channel failed to attach; '
                'off Android there is no native side at all.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        for (final DiagnosticProbe probe in DiagnosticProbe.values)
          _ProbeCard(probe: probe, controller: controller),
        const SizedBox(height: 8),
        Text('Jump into the log', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final DiagnosticSource source in _jumpTargets)
              ActionChip(
                label: Text(source.wire),
                onPressed: () => controller.focusSource(source),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _limitations(context),
      ],
    );
  }

  /// The sources worth a one-tap filter: the ones that own a subsystem rather than the
  /// generic `DART`/`KOTLIN`/`SYSTEM` buckets.
  static const List<DiagnosticSource> _jumpTargets = <DiagnosticSource>[
    DiagnosticSource.virtualEngine,
    DiagnosticSource.bcore,
    DiagnosticSource.apkImporter,
    DiagnosticSource.packageInstaller,
    DiagnosticSource.guestProcess,
    DiagnosticSource.activity,
    DiagnosticSource.permission,
    DiagnosticSource.storage,
    DiagnosticSource.webview,
    DiagnosticSource.notification,
    DiagnosticSource.jobScheduler,
    DiagnosticSource.methodChannel,
  ];

  Widget _limitations(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text('What cannot be captured', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 10),
            // Stated in the UI, not only in the docs. A developer reading an empty
            // section needs to know whether nothing happened or nothing is observable.
            for (final String line in _knownLimitations)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('•  ', style: theme.textTheme.bodySmall),
                    Expanded(child: Text(line, style: theme.textTheme.bodySmall)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const List<String> _knownLimitations = <String>[
    'Native (SIGSEGV/SIGABRT) crashes never reach a Java handler. Android writes a '
        'tombstone under /data/tombstones, which only the system and adb bugreport can '
        'read — an app cannot read its own.',
    'Another application’s logs and private data are outside the sandbox. Only '
        'Duplika’s own processes are covered, and a clone runs inside one of those, '
        'so a clone is covered and a normally installed app is not.',
    'A guest WebView’s renderer-crash callbacks belong to the guest’s own '
        'WebViewClient and are not reachable from the host.',
    'Low-memory kills, ANR watchdog kills and Process.killProcess end the process '
        'without unwinding, so no event is recorded for them.',
    'JobScheduler start and finish are only observable for jobs whose service Duplika '
        'hosts; the schedule request and the pending list always are.',
    'Host network errors are recorded only where Duplika’s own code sees them. '
        'A guest’s sockets are not intercepted, and no VPN capture is used.',
  ];
}

class _ProbeCard extends StatelessWidget {
  const _ProbeCard({required this.probe, required this.controller});

  final DiagnosticProbe probe;
  final DiagnosticsController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // The Obx belongs here, where the observables are actually read.
    return Obx(() {
      final NativeProbeResult? result = controller.probeResults[probe];
      final bool isRunning = controller.runningProbe.value == probe;
      final bool anyRunning = controller.runningProbe.value != null;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(probe.label, style: theme.textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(probe.description, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isRunning)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      OutlinedButton(
                        onPressed: anyRunning || !controller.nativeAvailable
                            ? null
                            : () => controller.runProbe(probe),
                        child: Text(result == null ? 'Run' : 'Re-run'),
                      ),
                  ],
                ),
                if (result != null && result.sections.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: Text(
                      '${result.sections.length} section(s), '
                      '${result.eventCount} event(s) recorded',
                      style: theme.textTheme.labelMedium,
                    ),
                    children: <Widget>[
                      // Bounded height: a storage probe on a multi-volume device
                      // produces more rows than a card should grow to fit.
                      SizedBox(
                        height: 360,
                        child: InfoSectionList(
                          sections: result.sections,
                          padding: const EdgeInsets.only(bottom: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
