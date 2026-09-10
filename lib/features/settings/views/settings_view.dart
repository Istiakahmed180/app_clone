import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../controllers/settings_controller.dart';
import '../widgets/appearance_labels.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';

/// App-level settings.
///
/// Grouped by who the row is for: what the user can change, how they reach us, what
/// they agreed to, and what build they are running.
///
/// Rows the app cannot honour yet are rendered inert with the reason in place of the
/// value, rather than left out. The Legal rows follow the same rule the terms dialog
/// does — an unpublished policy is not presented as a policy — and Rate us waits on a
/// real Play listing.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Obx(() {
        _reportStatus(context, controller);

        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
          children: <Widget>[
            SettingsSection(
              children: <Widget>[
                SettingsRow(
                  icon: Icons.contrast_outlined,
                  title: 'Appearance',
                  value: appearanceLabel(controller.themeMode.value),
                  onTap: () => Get.toNamed<void>(AppRoutes.appearance),
                ),
              ],
            ),
            SizedBox(height: 22.h),
            SettingsSection(
              title: 'Support',
              children: <Widget>[
                SettingsRow(
                  icon: Icons.mail_outline,
                  title: 'Contact us',
                  subtitle: 'Questions or feedback',
                  onTap: controller.contactSupport,
                ),
                SettingsRow(
                  icon: Icons.star_border,
                  title: 'Rate us',
                  subtitle: 'Enjoying ${AppConstants.appTitle}? Leave a review',
                  enabled: controller.reviewLinkIsPublished,
                  value: controller.reviewLinkIsPublished ? null : 'Not listed yet',
                  onTap: controller.openReview,
                ),
              ],
            ),
            SizedBox(height: 22.h),
            SettingsSection(
              title: 'Legal',
              children: <Widget>[
                SettingsRow(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Policy',
                  enabled: controller.legalLinksArePublished,
                  value:
                      controller.legalLinksArePublished ? null : 'Not published yet',
                  onTap: controller.openPrivacyPolicy,
                ),
                SettingsRow(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  enabled: controller.legalLinksArePublished,
                  value:
                      controller.legalLinksArePublished ? null : 'Not published yet',
                  onTap: controller.openTermsOfService,
                ),
              ],
            ),
            SizedBox(height: 22.h),
            SettingsSection(
              title: 'About',
              children: <Widget>[
                SettingsRow(
                  icon: Icons.info_outline,
                  title: 'Version',
                  value: controller.versionLabel ?? 'unavailable',
                ),
                SettingsRow(
                  icon: Icons.memory_outlined,
                  title: 'Device architecture',
                  subtitle: 'App compatibility',
                  value: controller.architectureLabel ?? 'unavailable',
                ),
                SettingsRow(
                  icon: Icons.code,
                  title: 'Supported ABIs',
                  value: controller.supportedAbisLabel ?? 'unavailable',
                ),
              ],
            ),
            SizedBox(height: 24.h),
            _copyright(context, controller),
          ],
        );
      }),
    );
  }

  Widget _copyright(BuildContext context, SettingsController controller) {
    final ThemeData theme = Theme.of(context);

    return Text(
      '© ${controller.copyrightYear} ${AppConstants.appTitle}',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Failures are reported once, as a snack bar, rather than parked in the list: "no
  /// mail app" is news about a tap, not a property of the screen.
  void _reportStatus(BuildContext context, SettingsController controller) {
    final String? message = controller.statusMessage.value;
    if (message == null) {
      return;
    }
    controller.statusMessage.value = null;
    // After this frame: showing a snack bar from inside a build is what triggers the
    // "setState during build" assertion.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });
  }
}
