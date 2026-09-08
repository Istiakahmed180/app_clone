import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/diagnostics/diagnostic_logger.dart';
import '../../../core/diagnostics/system_info.dart';
import '../controllers/diagnostics_controller.dart';
import '../widgets/info_section_list.dart';

/// Build, device and engine facts, plus what the diagnostics system itself is holding.
///
/// Deliberately narrow: build facts and device capabilities only. No serial, no
/// `ANDROID_ID`, no advertising id, no accounts — a report gets shared, and none of
/// that would help anyone read it.
class SystemInfoTab extends StatelessWidget {
  const SystemInfoTab({required this.controller, super.key});

  final DiagnosticsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final SystemInfoSnapshot? info = controller.systemInfo.value;
      if (info == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return InfoSectionList(
        sections: <SystemInfoSection>[
          ...info.sections(),
          _diagnosticsSection(),
        ],
      );
    });
  }

  /// What the logging system is currently holding, so a developer reading a short log
  /// can tell "nothing happened" from "the buffer wrapped".
  SystemInfoSection _diagnosticsSection() {
    final DiagnosticLogger logger = DiagnosticLogger.instance;
    return SystemInfoSection('Diagnostics (Flutter side)', <SystemInfoField>[
      SystemInfoField('Loaded events', '${controller.totalLoaded}'),
      SystemInfoField('Failures loaded', '${controller.failureCount}'),
      SystemInfoField(
        'Memory buffer',
        '${logger.buffer.length} of ${logger.buffer.capacity}'
            '${logger.buffer.hasOverflowed ? ' (wrapped)' : ''}',
      ),
      SystemInfoField('Recorded this session', '${logger.buffer.totalRecorded}'),
      SystemInfoField('Build type', DiagnosticLogger.buildType),
      SystemInfoField(
        'Native channel',
        controller.nativeAvailable ? 'answering' : 'not answering',
      ),
      SystemInfoField('Active filter', controller.filter.value.describe()),
    ]);
  }
}
