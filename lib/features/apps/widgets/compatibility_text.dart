import '../../../core/constants/app_constants.dart';
import '../../../data/models/compatibility_report.dart';
import '../../../l10n/app_localizations.dart';

/// Says a [CompatibilityFinding] in the user's language.
///
/// The finding arrives from the native analyzer as a code *and* a finished English
/// sentence. The code is what this translates; the sentence is the fallback, so a
/// finding this table has not caught up with still says something true rather than
/// nothing at all. That is why the native layer keeps sending the message.
String compatibilityFindingMessage(
  AppLocalizations l10n,
  CompatibilityFinding finding,
) {
  const String app = AppConstants.appTitle;
  switch (finding.code) {
    case 'APP_NOT_FOUND':
      return l10n.findingAppNotFound;
    case 'SECURE_ENV_REQUIRED':
      return l10n.findingSecureEnvRequired;
    case 'SELF_CLONE_UNSUPPORTED':
      return l10n.findingSelfClone(app);
    case 'SYSTEM_COMPONENT_UNSUPPORTED':
      return l10n.findingSystemComponent;
    case 'ABI_NOT_SUPPORTED':
      return l10n.findingAbiNotSupported;
    case 'APP_ARCHIVE_UNAVAILABLE':
      return l10n.findingAppArchiveUnavailable;
    case 'STORAGE_UNAVAILABLE':
      return l10n.findingStorageUnavailable(app);
    default:
      return finding.message;
  }
}
