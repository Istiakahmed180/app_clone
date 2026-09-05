import 'package:get/get.dart';

import '../../features/apps/views/app_picker_view.dart';
import '../../features/home/views/home_view.dart';
import 'app_bindings.dart';

class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String appPicker = '/apps/pick';

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
      ];
}
