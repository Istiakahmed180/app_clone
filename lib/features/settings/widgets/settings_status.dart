import 'package:flutter/material.dart';

import '../../../core/constants/support_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../controllers/settings_controller.dart';

/// Says a [SettingsStatus] in the user's language.
String settingsStatusMessage(AppLocalizations l10n, SettingsStatus status) {
  switch (status) {
    case SettingsStatus.mailAppMissing:
      return l10n.contactNoMailApp(SupportConstants.supportEmail);
    case SettingsStatus.whatsAppFailed:
      return l10n.contactWhatsAppFailed;
    case SettingsStatus.telegramFailed:
      return l10n.contactTelegramFailed;
    case SettingsStatus.playStoreFailed:
      return l10n.contactPlayStoreFailed;
    case SettingsStatus.privacyPolicyFailed:
      return l10n.contactLegalOpenFailed(l10n.settingsPrivacyPolicy);
    case SettingsStatus.termsOfServiceFailed:
      return l10n.contactLegalOpenFailed(l10n.settingsTermsOfService);
  }
}

/// Reports a failed action once, as a snack bar, then clears it.
///
/// A failure like "no mail app" is news about a tap rather than a property of the
/// screen, so it is not parked in the layout. Called from inside a build, hence the
/// post-frame callback: showing a snack bar during build is what trips the
/// "setState during build" assertion.
void reportSettingsStatus(BuildContext context, SettingsController controller) {
  final SettingsStatus? status = controller.status.value;
  if (status == null) {
    return;
  }
  controller.status.value = null;
  final String message = settingsStatusMessage(AppLocalizations.of(context), status);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  });
}
