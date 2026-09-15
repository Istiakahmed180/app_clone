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
/// Not built into a release APK; the route is registered only outside one (see
/// [AppRoutes.developerTools]).
///
/// That is a change of position, and it costs something real. Release behaviour is the
/// thing this project most needs to be able to diagnose, and this console was the only
/// way to do it on a device the developer does not have in front of them. Capture is
/// unaffected — the Flutter logger, the native logger and the crash handler all still
/// run in a release build, and the native log files are still written — but nothing in
/// a shipped app can read them back or hand them to the share sheet, because
/// `DiagnosticsExporter` is reached only from this screen and goes with it. In a
/// release build the evidence exists on disk and needs adb to collect.
///
/// The judgement behind that: a console one tap from the home screen puts raw logs,
/// subsystem probes and device facts in front of whoever is holding the phone, and a
/// shipped app has no business offering that. If release diagnostics are wanted back,
/// the thing to add is a support-flow export, not this screen.
///
/// Because it cannot run in a release build, nothing in here gates on one any more.
/// The self-test's release confirmation went with it rather than being left as a branch
/// that can no longer be reached.
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
        // Unconfirmed. The self-test raises a real exception in Kotlin, which used to be
        // worth a question because this screen could be opened on a build someone was
        // actually using. It cannot be any more, and asking a developer to confirm a
        // button they just pressed on purpose is friction with nothing behind it.
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
