import 'package:get/get.dart';

import '../../features/apps/views/app_picker_view.dart';
import '../../features/diagnostics/views/developer_console_view.dart';
import '../../features/home/views/home_view.dart';
import 'app_bindings.dart';

class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String appPicker = '/apps/pick';

  /// The in-app Developer Console. Reachable in release as well as debug, because
  /// release behaviour is what most needs diagnosing; the destructive and
  /// data-revealing actions inside it are gated on the build type instead.
  static const String developerTools = '/developer/tools';

  static List<GetPage<dynamic>> pages() => <GetPage<dynamic>>[
        GetPage<dynamic>(
          name: home,
          page: () => const HomeView(),
          binding: HomeBinding(),
        ),
        GetPage<dynamic>(
          name: appPicker,
          page: () => const AppPickerView(),
          binding: AppPickerBinding(),
        ),
        GetPage<dynamic>(
          name: developerTools,
          page: () => const DeveloperConsoleView(),
          binding: DiagnosticsBinding(),
        ),
      ];
}
