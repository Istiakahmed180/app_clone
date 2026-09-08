import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/diagnostics_controller.dart';
import 'error_center_tab.dart';
import 'live_log_tab.dart';
import 'operations_tab.dart';
import 'subsystems_tab.dart';
import 'system_info_tab.dart';

/// Developer Tools.
///
/// Five tabs, in the order a failure is actually investigated: what is happening now,
/// what went wrong, which operation it belonged to, which subsystem to interrogate, and
/// what machine it happened on.
///
/// Available in release as well as debug. Release compatibility is the thing this
/// project most needs to be able to diagnose, so removing the console there would
/// remove it exactly where it is most useful; instead the destructive and
/// data-revealing actions are gated (see [DiagnosticsController.isReleaseBuild]).
class DeveloperConsoleView extends StatefulWidget {
  const DeveloperConsoleView({super.key});

  @override
  State<DeveloperConsoleView> createState() => _DeveloperConsoleViewState();
}

class _DeveloperConsoleViewState extends State<DeveloperConsoleView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 5, vsync: this);
  late final DiagnosticsController controller = Get.find<DiagnosticsController>();

  Worker? _statusWorker;

  @override
  void initState() {
    super.initState();
    // Status messages are reported once, as a snack bar, rather than parked in the UI:
    // "export finished" is news, not state.
    _statusWorker = ever<String?>(controller.statusMessage, (String? message) {
      if (message == null || !mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      controller.statusMessage.value = null;
    });
  }

  @override
  void dispose() {
    _statusWorker?.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Tools'),
        actions: <Widget>[
          Obx(
            () => IconButton(
              tooltip: controller.isPaused.value ? 'Resume live logs' : 'Pause live logs',
              onPressed: controller.togglePause,
              icon: Badge(
                isLabelVisible: controller.bufferedWhilePaused.value > 0,
                label: Text('${controller.bufferedWhilePaused.value}'),
                child: Icon(
                  controller.isPaused.value ? Icons.play_arrow : Icons.pause,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Reload history',
            onPressed: () {
              controller.reload();
              controller.refreshSystemInfo();
            },
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<_ConsoleAction>(
            onSelected: _onAction,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<_ConsoleAction>>[
              const PopupMenuItem<_ConsoleAction>(
                value: _ConsoleAction.export,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.ios_share),
                  title: Text('Export diagnostics'),
                ),
              ),
              const PopupMenuItem<_ConsoleAction>(
                value: _ConsoleAction.selfTest,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.science_outlined),
                  title: Text('Run native self-test'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<_ConsoleAction>(
                value: _ConsoleAction.clear,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline),
                  title: Text('Clear logs'),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: <Widget>[
            const Tab(text: 'Live'),
            Tab(
              child: Obx(() {
                // Recomputed from the loaded window rather than counted separately, so
                // the badge can never disagree with the list behind it.
                final int count = controller.visible.isEmpty && controller.isLoading.value
                    ? 0
                    : controller.failureCount;
                return Row(
                  children: <Widget>[
                    const Text('Errors'),
                    if (count > 0) ...<Widget>[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onError,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ),
            const Tab(text: 'Operations'),
            const Tab(text: 'Subsystems'),
            const Tab(text: 'System'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: <Widget>[
          LiveLogTab(controller: controller),
          ErrorCenterTab(controller: controller),
          OperationsTab(controller: controller),
          SubsystemsTab(controller: controller),
          SystemInfoTab(controller: controller),
        ],
      ),
    );
  }

  Future<void> _onAction(_ConsoleAction action) async {
    switch (action) {
      case _ConsoleAction.export:
        await controller.exportAndShare();
      case _ConsoleAction.selfTest:
        // The self-test deliberately raises a real exception in Kotlin. In debug that is
        // unremarkable; in a release build someone may actually be using the app, so it
        // is confirmed first rather than removed — release capture is one of the things
        // most worth verifying on a device.
        if (controller.isReleaseBuild) {
          final bool confirmed = await _confirmSelfTest() ?? false;
          if (!confirmed) {
            return;
          }
        }
        await controller.runNativeSelfTest();
      case _ConsoleAction.clear:
        // Confirmed always, and worded so it is clear this is not just the screen being
        // emptied: clearing drops the native store too, including whatever was captured
        // in a guest process before the console was opened.
        final bool confirmed = await _confirmClear() ?? false;
        if (confirmed) {
          await controller.clearAll();
        }
    }
  }

  Future<bool?> _confirmSelfTest() => showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Raise a test exception?'),
          content: const Text(
            'This throws a real exception inside the native logger so that native '
            'capture can be verified on this build. It is caught immediately and does '
            'not affect any clone, but it will appear in the log as an ERROR.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Run'),
            ),
          ],
        ),
      );

  Future<bool?> _confirmClear() => showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Clear diagnostic history?'),
          content: const Text(
            'This deletes the in-memory buffer, the stored Flutter log and the native '
            'log files for every Duplika process, including the ones written while '
            'guest apps were running. It cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear'),
            ),
          ],
        ),
      );
}

enum _ConsoleAction { export, selfTest, clear }
