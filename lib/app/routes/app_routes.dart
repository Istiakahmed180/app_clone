import 'package:get/get.dart';

import '../../features/home/views/home_view.dart';
import '../../features/profiles/views/add_profile_view.dart';
import 'app_bindings.dart';

class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String addProfile = '/profiles/add';

  static List<GetPage<dynamic>> pages() => <GetPage<dynamic>>[
        GetPage<dynamic>(
          name: home,
          page: () => const HomeView(),
          binding: HomeBinding(),
        ),
        GetPage<dynamic>(
          name: addProfile,
          page: () => const AddProfileView(),
          binding: AddProfileBinding(),
        ),
      ];
}
