import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../core/constants/app_constants.dart';
import '../data/models/app_disguise_mode.dart';
import '../data/models/app_language.dart';
import '../features/disguise/controllers/disguise_controller.dart';
import '../features/disguise/views/calculator_view.dart';
import '../features/settings/controllers/settings_controller.dart';
import '../l10n/app_localizations.dart';
import 'routes/app_bindings.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class DuplikaApp extends StatefulWidget {
  const DuplikaApp({super.key});

  @override
  State<DuplikaApp> createState() => _DuplikaAppState();
}

class _DuplikaAppState extends State<DuplikaApp> {
  @override
  void initState() {
    super.initState();
    // Invoked here rather than handed to GetMaterialApp as its `initialBinding`: the
    // theme and locale are read from SettingsController, so it has to exist before the
    // first GetMaterialApp build rather than during it. AppBinding remains the one
    // place the graph is defined.
    AppBinding().dependencies();
  }

  @override
  Widget build(BuildContext context) {
    final DisguiseController disguise = Get.find<DisguiseController>();

    // The disguise is decided before anything else: while the platform answer is in flight
    // nothing is shown (so a disguised launch never flashes the clone grid), and a locked
    // calculator stands in for the whole app until the Private space PIN is entered.
    return Obx(() {
      final AppDisguiseMode? mode = disguise.mode.value;
      if (mode == null) {
        return const SizedBox.shrink();
      }
      if (mode == AppDisguiseMode.calculator && disguise.locked.value) {
        return CalculatorView(controller: disguise);
      }
      return DuplikaAppRoot(settings: Get.find<SettingsController>());
    });
  }
}

/// The configured app.
///
/// Split from [DuplikaApp] so that the theme and locale wiring can be mounted in a test
/// without standing up the whole dependency graph first — the alternative was a test
/// that rebuilt this configuration by hand and therefore proved nothing about it.
@visibleForTesting
class DuplikaAppRoot extends StatelessWidget {
  const DuplikaAppRoot({
    required this.settings,
    this.initialRoute = AppRoutes.home,
    super.key,
  });

  final SettingsController settings;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    // ScreenUtil is initialised exactly once, at the root of the widget tree.
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (BuildContext context, Widget? child) {
        // Observing the two preferences here is what makes them take effect: setting
        // `themeMode` or `language` on the controller rebuilds the app with them.
        // Nothing has to reassemble the tree or reach for a global.
        return Obx(
          () => GetMaterialApp(
            title: AppConstants.appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode.value,
            // Null means follow the device, which is what the Language screen calls
            // 'System default'.
            locale: settings.language.value?.locale,
            fallbackLocale: const Locale('en'),
            supportedLocales: AppLanguages.locales,
            // Duplika's own strings plus the framework's, which brings the Material and
            // Cupertino translations and each locale's date and number formats with it.
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            initialRoute: initialRoute,
            getPages: AppRoutes.pages(),
          ),
        );
      },
    );
  }
}
