import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../private_space/controllers/private_space_controller.dart';
import '../../private_space/views/private_space_settings_view.dart';
import '../controllers/settings_controller.dart';
import '../../../l10n/l10n_context.dart';
import '../widgets/appearance_labels.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_status.dart';
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
    final PrivateSpaceController privateSpace =
        Get.find<PrivateSpaceController>();
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: Obx(() {
        reportSettingsStatus(context, controller);

        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
          children: <Widget>[
            SettingsSection(
              children: <Widget>[
                SettingsRow(
                  icon: Icons.language,
                  title: l10n.settingsLanguage,
                  value: controller.language.value?.nativeName ?? l10n.languageSystem,
                  onTap: () => Get.toNamed<void>(AppRoutes.language),
                ),
                SettingsRow(
                  icon: Icons.contrast_outlined,
                  title: l10n.settingsAppearance,
                  value: appearanceLabel(l10n, controller.themeMode.value),
                  onTap: () => Get.toNamed<void>(AppRoutes.appearance),
                ),
              ],
            ),
            SizedBox(height: 22.h),
            SettingsSection(
              title: 'Privacy',
              children: <Widget>[
                SettingsRow(
                  icon: Icons.lock_outline,
                  title: 'Private space',
                  subtitle: 'Hide apps behind a PIN',
                  value: privateSpace.enabled ? 'On' : 'Off',
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          PrivateSpaceSettingsView(privateSpace: privateSpace),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 22.h),
            SettingsSection(
              title: l10n.settingsSectionSupport,
              children: <Widget>[
                SettingsRow(
                  icon: Icons.mail_outline,
                  title: l10n.settingsContact,
                  subtitle: l10n.settingsContactSubtitle,
                  onTap: () => Get.toNamed<void>(AppRoutes.contact),
                ),
                SettingsRow(
                  icon: Icons.star_border,
                  title: l10n.settingsRate,
                  subtitle: l10n.settingsRateSubtitle(AppConstants.appTitle),
                  enabled: controller.reviewLinkIsPublished,
                  value: controller.reviewLinkIsPublished ? null : l10n.settingsNotListedYet,
                  onTap: controller.openReview,
                ),
              ],
            ),
            SizedBox(height: 22.h),
            SettingsSection(
              title: l10n.settingsSectionLegal,
              children: <Widget>[
                SettingsRow(
                  icon: Icons.shield_outlined,
                  title: l10n.settingsPrivacyPolicy,
                  enabled: controller.legalLinksArePublished,
                  value: controller.legalLinksArePublished
                      ? null
                      : l10n.settingsNotPublishedYet,
                  onTap: controller.openPrivacyPolicy,
                ),
                SettingsRow(
                  icon: Icons.description_outlined,
                  title: l10n.settingsTermsOfService,
                  enabled: controller.legalLinksArePublished,
                  value: controller.legalLinksArePublished
                      ? null
                      : l10n.settingsNotPublishedYet,
                  onTap: controller.openTermsOfService,
                ),
              ],
            ),
            SizedBox(height: 22.h),
            SettingsSection(
              title: l10n.settingsSectionAbout,
              children: <Widget>[
                SettingsRow(
                  icon: Icons.info_outline,
                  title: l10n.settingsVersion,
                  value: controller.versionLabel ?? l10n.commonUnavailable,
                ),
                SettingsRow(
                  icon: Icons.memory_outlined,
                  title: l10n.settingsArchitecture,
                  subtitle: l10n.settingsArchitectureSubtitle,
                  value: _architecture(l10n, controller) ?? l10n.commonUnavailable,
                ),
                SettingsRow(
                  icon: Icons.code,
                  title: l10n.settingsSupportedAbis,
                  value: controller.supportedAbisLabel ?? l10n.commonUnavailable,
                ),
              ],
            ),
            SizedBox(height: 24.h),
            _copyright(context, l10n, controller),
          ],
        );
      }),
    );
  }

  /// `64-bit · arm64-v8a`, said in the user's language.
  String? _architecture(AppLocalizations l10n, SettingsController controller) {
    final ({String abi, bool is64Bit})? architecture = controller.architecture;
    if (architecture == null) {
      return null;
    }
    return l10n.settingsArchitectureValue(
      architecture.is64Bit ? l10n.settingsBits64 : l10n.settingsBits32,
      architecture.abi,
    );
  }

  Widget _copyright(
    BuildContext context,
    AppLocalizations l10n,
    SettingsController controller,
  ) {
    final ThemeData theme = Theme.of(context);

    return Text(
      l10n.settingsCopyright(controller.copyrightYear, AppConstants.appTitle),
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
