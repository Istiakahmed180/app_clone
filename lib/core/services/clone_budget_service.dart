import '../../data/models/device_capacity.dart';
import '../../data/models/clone_budget.dart';
import '../../native/native_bridge.dart';
import '../errors/app_exception.dart';
import '../utils/app_logger.dart';

/// How many more clones this device should be offered, and why.
///
/// One answer for every route that makes a clone. It used to live on `HomeController`,
/// which meant only the route that starts from the grid — long-press a clone, ask for a
/// count — ever consulted it. The picker made clones without asking, so the same device
/// could refuse a batch of one with "there is no room, 210 MB free" on one screen and,
/// on the other, accept the tap, write the profile, call the engine, fail, roll back, and
/// hand the user whatever the engine said. Two doors, two answers, one device.
///
/// A device that will not answer gets the full offer. A capability check that failed must
/// not stand between the user and a clone that would have worked.
class CloneBudgetService {
  const CloneBudgetService({required this._nativeBridge});

  final NativeBridge _nativeBridge;
  static const AppLogger _logger = AppLogger('CloneBudgetService');

  /// The most clones the count dialog will ever offer, whatever the device could take.
  ///
  /// A stepper is for a small number. Past twenty the honest control is a text field,
  /// and nobody has asked for one.
  static const int absoluteMaximum = 20;

  /// Space the device keeps for itself, held back from the clone estimate.
  ///
  /// Android starts refusing writes and running its own cleanup well before a volume
  /// reaches zero, so a batch sized to the last free byte would fail anyway — and take
  /// the user's other apps down with it.
  static const int _storageHeadroomBytes = 512 * 1024 * 1024;

  /// What one more clone of an app that already has one actually costs on disk.
  ///
  /// Measured, not guessed: forty-five containers of a single app occupied 2.6 MB of the
  /// engine's store — about 40 KB each — because the package is installed once and every
  /// clone after it gets only its own empty data directories. Rounded up for the odd
  /// device with larger blocks.
  ///
  /// It is deliberately not the app's APK size. Charging a clone for a copy of the
  /// archive that is never made refuses batches the device would have taken easily.
  static const int _perCloneBytes = 64 * 1024;

  /// How many more clones this device should be offered, and what bound the figure.
  ///
  /// The count dialog takes its ceiling from here, the batch checks against the same
  /// figure, and the picker refuses a single clone on it — so the app can never offer a
  /// number it will then refuse, on any route.
  ///
  /// [existingClones] is how many the device already has. Only the memory bound uses it,
  /// and only to stop the offer being a number the device cannot live up to: the tier
  /// below is a judgement about how many containers can usefully run *at once*, and an
  /// offer that ignored the ones already there said "up to 6 at a time" to someone who
  /// had eight. Leave it at zero where the count is not to hand; the answer is then the
  /// old one, which is the right default for a caller that only wants to know whether
  /// there is room for one.
  Future<CloneBudget> cloneBudget({int existingClones = 0}) async {
    final DeviceCapacity capacity;
    try {
      capacity = await _nativeBridge.deviceCapacity();
    } on AppException catch (error) {
      _logger.warning(
        'Clone budget fell back to the default: ${error.message}',
      );
      return const CloneBudget(
        maximum: absoluteMaximum,
        limit: CloneBudgetLimit.appCeiling,
      );
    }

    final int usable = capacity.freeBytes - _storageHeadroomBytes;
    final int storageCap = capacity.knowsStorage
        ? (usable <= 0 ? 0 : usable ~/ _perCloneBytes)
        : absoluteMaximum;
    final int memoryCap = _memoryCap(capacity, existingClones);
    final int maximum = <int>[
      absoluteMaximum,
      storageCap,
      memoryCap,
    ].reduce((int a, int b) => a < b ? a : b);

    // Decided after the minimum, not before it: a volume with room for part of a clone
    // clears the headroom check and still lands on nothing, and 'Up to 0' is not a
    // sentence. Only storage can bring the figure this low, so it is what gets named.
    //
    // States the two figures and stops. Callers put this after a sentence that has
    // already said there is no room, so repeating the verdict here would say it twice.
    if (maximum <= 0) {
      return CloneBudget(
        maximum: 0,
        limit: CloneBudgetLimit.storageExhausted,
        freeLabel: capacity.freeLabel,
      );
    }

    if (maximum >= absoluteMaximum) {
      return const CloneBudget(
        maximum: absoluteMaximum,
        limit: CloneBudgetLimit.appCeiling,
      );
    }
    // Name the figure that actually bound the offer, so the number reads as this
    // device's answer rather than as an arbitrary cap.
    if (storageCap <= memoryCap) {
      return CloneBudget(
        maximum: maximum,
        limit: CloneBudgetLimit.storage,
        freeLabel: capacity.freeLabel,
      );
    }
    // "at a time", because that is all this bound is. Memory does not shrink as idle
    // containers pile up, so repeating the action reaches any total the storage floor
    // allows — and a reason that read as a device ceiling would be promising otherwise.
    // The storage wording above needs no such qualifier: free space really does fall
    // with every clone made, so that figure is a ceiling and corrects itself.
    return CloneBudget(
      maximum: maximum,
      limit: CloneBudgetLimit.memory,
      totalMemLabel: capacity.totalMemLabel,
    );
  }

  /// What this device should be encouraged to *run*, which is a different question from
  /// what it can hold.
  ///
  /// [existingClones] is subtracted from the tier, and it is worth being exact about why,
  /// because an idle container costs [_perCloneBytes] and no memory at all: the clones
  /// already made are not occupying RAM right now, and this is not pretending they are.
  /// What the tier expresses is how many containers are worth *having* on a device this
  /// size — the number someone who made twenty of them is about to try to use — and that
  /// is a claim about the total, not about the next batch. An offer that counted only the
  /// new ones said "up to 6 at a time" to someone who already had eight: a number that
  /// cannot be acted on and deliver what it says.
  ///
  /// Never below one. The tiers are a judgement and they are wrong on some device, so
  /// they are allowed to shrink an offer and never to refuse one — someone who wants a
  /// ninth clone on a small phone still gets it, one at a time. Locking them out of their
  /// own device on a guess would be worse than the friction. Only storage, which is
  /// measured rather than guessed, can bring the answer to zero.
  int _memoryCap(DeviceCapacity capacity, int existingClones) {
    final int remaining = _memoryTier(capacity) - existingClones;
    return remaining < 1 ? 1 : remaining;
  }

  /// How many containers this device is judged good for at once, before counting what it
  /// already has.
  ///
  /// These tiers are a judgement, not a measurement of anything: tune them, do not trust
  /// them.
  int _memoryTier(DeviceCapacity capacity) {
    if (capacity.isLowRamDevice ?? false) {
      return 4;
    }
    if (!capacity.knowsMemory) {
      return absoluteMaximum;
    }
    const int gb = 1024 * 1024 * 1024;
    final int total = capacity.totalMemBytes!;
    if (total < 3 * gb) {
      return 6;
    }
    if (total < 6 * gb) {
      return 12;
    }
    return absoluteMaximum;
  }
}
