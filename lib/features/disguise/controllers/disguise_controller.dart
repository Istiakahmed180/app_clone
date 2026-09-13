import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/app_disguise_mode.dart';
import '../../../native/native_bridge.dart';
import '../../private_space/controllers/private_space_controller.dart';

/// Owns the launcher disguise: which icon/name the app presents, and whether a disguised
/// launch has been let back in yet.
///
/// The platform's enabled `activity-alias` is the source of truth ([mode] is read from it,
/// not stored in Dart), and the Private space PIN is the key back in — so the disguise adds
/// no second secret. It is only offered once a PIN exists.
class DisguiseController extends GetxController {
  DisguiseController({
    required this._bridge,
    required this._privateSpace,
  });

  final NativeBridge _bridge;
  final PrivateSpaceController _privateSpace;
  final AppLogger _logger = const AppLogger('DisguiseController');

  /// Null until the platform answers. The app must not show its real UI while this is
  /// unknown, or a disguised launch would flash the clone grid before the calculator.
  final Rxn<AppDisguiseMode> mode = Rxn<AppDisguiseMode>();

  /// Whether a disguised launch still has to enter the PIN. Reset on every cold start.
  final RxBool locked = false.obs;

  bool get disguised => mode.value == AppDisguiseMode.calculator;

  /// True while the calculator should stand in for the app.
  bool get shouldHideApp => disguised && locked.value;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    final AppDisguiseMode current = await _bridge.getAppDisguise();
    mode.value = current;
    // A disguised app re-locks on every launch: the calculator is the only door, so it
    // must not stay open from a previous session.
    locked.value = current == AppDisguiseMode.calculator;
  }

  /// Applies [next] and returns what the platform reports, or null on failure.
  Future<AppDisguiseMode?> setMode(AppDisguiseMode next) async {
    try {
      final AppDisguiseMode applied = await _bridge.setAppDisguise(next);
      mode.value = applied;
      // Enabling from inside an authenticated session keeps it open — the user just chose
      // this, and dropping them straight onto a calculator would read as a bug. Turning it
      // off can never stay locked.
      locked.value = applied == AppDisguiseMode.calculator && locked.value;
      return applied;
    } on AppException catch (error) {
      _logger.error('Could not change the launcher disguise: ${error.message}');
      return null;
    }
  }

  /// The calculator calls this with the number the user entered before "=". True unlocks.
  Future<bool> unlock(String code) async {
    if (!disguised || code.isEmpty) {
      return false;
    }
    final bool ok = await _privateSpace.verifyPin(code);
    if (ok) {
      locked.value = false;
    }
    return ok;
  }
}
