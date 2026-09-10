import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_context.dart';
import '../controllers/settings_controller.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_status.dart';
import '../widgets/settings_section.dart';

/// How to reach a human.
///
/// Every row leaves the app, so each is marked with an out-and-away glyph rather than a
/// chevron: the user should know before tapping that WhatsApp is about to open.
///
/// A channel with nothing configured behind it is rendered inert with the reason, not
/// dropped. A support screen that silently omits the channel someone was told to use is
/// worse than one that says it is not set up.
class ContactView extends StatelessWidget {
  const ContactView({super.key});

  /// WhatsApp's and Telegram's own colours. Not from [AppTheme]: these identify someone
  /// else's product, and recolouring them to our accent makes three identical rows.
  static const Color _whatsAppGreen = Color(0xFF25D366);
  static const Color _telegramBlue = Color(0xFF229ED9);

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = Get.find<SettingsController>();
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.contactTitle)),
      body: Obx(() {
        reportSettingsStatus(context, controller);

        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
          children: <Widget>[
            _hero(context),
            SizedBox(height: 22.h),
            SettingsSection(
              title: l10n.contactSectionOptions,
              children: <Widget>[
                SettingsRow(
                  icon: Icons.chat,
                  iconColor: _whatsAppGreen,
                  title: l10n.contactWhatsApp,
                  subtitle: l10n.contactWhatsAppSubtitle,
                  trailingIcon: Icons.open_in_new,
                  enabled: controller.hasWhatsApp,
                  value: controller.hasWhatsApp ? null : l10n.settingsNotSetUpYet,
                  onTap: controller.openWhatsApp,
                ),
                SettingsRow(
                  icon: Icons.send,
                  iconColor: _telegramBlue,
                  title: l10n.contactTelegram,
                  subtitle: l10n.contactTelegramSubtitle,
                  trailingIcon: Icons.open_in_new,
                  enabled: controller.hasTelegram,
                  value: controller.hasTelegram ? null : l10n.settingsNotSetUpYet,
                  onTap: controller.openTelegram,
                ),
                SettingsRow(
                  icon: Icons.mail_outline,
                  title: l10n.contactEmail,
                  subtitle: l10n.contactEmailSubtitle,
                  trailingIcon: Icons.open_in_new,
                  onTap: controller.emailSupport,
                ),
              ],
            ),
            SizedBox(height: 16.h),
            SettingsSection(
              children: <Widget>[
                SettingsRow(
                  icon: Icons.schedule,
                  title: l10n.contactResponseTime,
                  subtitle: l10n.contactResponseTimeValue,
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _privacyNote(context),
          ],
        );
      }),
    );
  }

  /// The accent panel. Says what the screen is for before the list of ways to do it,
  /// so three near-identical rows do not have to carry the explanation themselves.
  Widget _hero(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    final Color onAccent = theme.colorScheme.onPrimary;

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius.r),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: onAccent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Icon(Icons.support_agent, size: 32.r, color: onAccent),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.contactHeroTitle,
                  style: theme.textTheme.titleLarge?.copyWith(color: onAccent),
                ),
                SizedBox(height: 6.h),
                Text(
                  l10n.contactHeroSubtitle(AppConstants.appTitle),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onAccent.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// What happens to what they send. Short, and true: the app has no server, so a
  /// message goes straight to whichever app opened it.
  Widget _privacyNote(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Text(
      context.l10n.contactPrivacyNote,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
