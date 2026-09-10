import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/support_constants.dart';
import '../controllers/settings_controller.dart';
import '../widgets/settings_row.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Contact us')),
      body: Obx(() {
        _reportStatus(context, controller);

        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
          children: <Widget>[
            _hero(context),
            SizedBox(height: 22.h),
            SettingsSection(
              title: 'Contact options',
              children: <Widget>[
                SettingsRow(
                  icon: Icons.chat,
                  iconColor: _whatsAppGreen,
                  title: 'WhatsApp',
                  subtitle: 'Chat with our support team',
                  trailingIcon: Icons.open_in_new,
                  enabled: controller.hasWhatsApp,
                  value: controller.hasWhatsApp ? null : 'Not set up yet',
                  onTap: controller.openWhatsApp,
                ),
                SettingsRow(
                  icon: Icons.send,
                  iconColor: _telegramBlue,
                  title: 'Telegram',
                  subtitle: 'Message us on Telegram',
                  trailingIcon: Icons.open_in_new,
                  enabled: controller.hasTelegram,
                  value: controller.hasTelegram ? null : 'Not set up yet',
                  onTap: controller.openTelegram,
                ),
                SettingsRow(
                  icon: Icons.mail_outline,
                  title: 'Email',
                  subtitle: 'Send us an email',
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
                  title: 'Response time',
                  subtitle: SupportConstants.responseTime,
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
                  'How can we help?',
                  style: theme.textTheme.titleLarge?.copyWith(color: onAccent),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Choose your preferred way to contact the '
                  '${AppConstants.appTitle} team.',
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
      'We\'ll only use your message to provide support.',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Failures are reported once, as a snack bar: "WhatsApp is not installed" is news
  /// about a tap, not a property of the screen.
  void _reportStatus(BuildContext context, SettingsController controller) {
    final String? message = controller.statusMessage.value;
    if (message == null) {
      return;
    }
    controller.statusMessage.value = null;
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
