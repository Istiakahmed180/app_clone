import '../../l10n/app_localizations.dart';
import '../constants/app_constants.dart';
import 'app_exception.dart';

/// Says an [AppException] in the user's language.
///
/// Translates by [AppException.code] and falls back to [AppException.message], the same
/// contract `compatibilityFindingMessage` uses. Two kinds of failure deliberately keep
/// the fallback:
///
///  * a code this table has not caught up with — better a true English sentence than a
///    wrong translated one;
///  * a code whose message is assembled by the engine around detail it did not send
///    separately (an install refusal quoting the system's reason, for instance). Wording
///    those from the code alone would throw the detail away, which is the part worth
///    reading.
String appErrorMessage(AppLocalizations l10n, AppException error) {
  const String app = AppConstants.appTitle;
  switch (error.code) {
    // ── this app's own ────────────────────────────────────────────────────
    case AppErrorCodes.profileNameEmpty:
      return l10n.errorProfileNameEmpty;
    case AppErrorCodes.profileNameTooLong:
      return l10n.errorProfileNameTooLong(AppConstants.maxProfileNameLength);
    case AppErrorCodes.profileStorageUnreadable:
      return l10n.errorProfileStorageUnreadable;
    case AppErrorCodes.profileNotFound:
      return l10n.errorProfileNotFound;
    case AppErrorCodes.bridgeNoData:
    case AppErrorCodes.bridgeCallFailed:
      return l10n.errorBridgeFailed;
    case AppErrorCodes.bridgeUnsupportedPlatform:
      return l10n.errorBridgeUnsupportedPlatform;
    case AppErrorCodes.testAppCheckFailed:
      return l10n.errorTestAppCheckFailed;
    case AppErrorCodes.cloneIconFailed:
      return l10n.errorCloneIconFailed;

    // ── the engine's, shared with the clone refusal message ───────────────
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

    // ── the engine's own ──────────────────────────────────────────────────
    case 'VIRTUALIZATION_NOT_AVAILABLE':
      return l10n.homeEngineUnavailable;
    case 'ENGINE_INITIALIZATION_FAILED':
      return l10n.errorEngineInitFailed;
    case 'ENGINE_UNSUPPORTED_ANDROID_VERSION':
      return l10n.errorEngineAndroidTooOld;
    case 'ENGINE_NO_RESPONSE':
      return l10n.errorEngineNoResponse;
    case 'VIRTUAL_APP_NOT_INSTALLED':
      return l10n.errorNoContainer;
    case 'VIRTUAL_APP_LAUNCH_FAILED':
      return l10n.errorLaunchRefused;
    case 'APP_ALREADY_CLONED':
      return l10n.errorAlreadyCloned;
    case 'CLEAR_CACHE_FAILED':
      return l10n.errorClearCacheFailed;
    case 'CLEAR_DATA_FAILED':
      return l10n.errorClearDataFailed;
    case 'SHORTCUTS_UNSUPPORTED':
      return l10n.errorShortcutsUnsupported;
    case 'SHORTCUT_REQUEST_FAILED':
      return l10n.errorShortcutRefused;
    case 'APK_NOT_AVAILABLE':
      return l10n.errorApkGone;
    case 'SHARE_FAILED':
      return l10n.errorShareFailed;

    // ── APK import ────────────────────────────────────────────────────────
    case 'APK_UNREADABLE':
      return l10n.errorApkUnreadable;
    case 'APK_PACKAGE_MISMATCH':
      return l10n.errorApkPackageMismatch;
    case 'APK_VERSION_MISMATCH':
      return l10n.errorApkVersionMismatch;
    case 'APK_BASE_REQUIRED':
      return l10n.errorApkBaseRequired;
    case 'APK_DUPLICATE_SPLIT':
      return l10n.errorApkDuplicateSplit;

    // APK_INVALID covers several distinct manifest faults that share one code, and
    // APP_INSTALL_FAILED, GMS_INSTALL_FAILED, PROFILE_CREATE_FAILED and
    // PROFILE_DELETE_FAILED all quote the engine's own reason. Those keep their message.
    default:
      return error.message;
  }
}
