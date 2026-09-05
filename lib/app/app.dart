import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../core/constants/app_constants.dart';
import 'routes/app_bindings.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class VirtualSpaceApp extends StatelessWidget {
  const VirtualSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ScreenUtil is initialised exactly once, at the root of the widget tree.
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (BuildContext context, Widget? child) {
        return GetMaterialApp(
          title: AppConstants.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          initialBinding: AppBinding(),
          initialRoute: AppRoutes.home,
          getPages: AppRoutes.pages(),
        );
      },
    );
  }
}
