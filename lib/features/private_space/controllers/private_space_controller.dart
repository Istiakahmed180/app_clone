import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/services/biometric_authenticator.dart';
import '../../../core/services/private_space_store.dart';
import '../../../data/models/private_space_state.dart';
import '../../../data/repositories/virtual_profile_repository.dart';

/// The Private space lock, and the clones kept behind it.
///
/// Registered permanently so the lock state survives navigation: unlocking to look at
/// the hidden grid and then opening one of its clones must not land the next screen on a
/// locked state.
///
/// Two responsibilities live here because they are the same feature:
///
/// * the lock itself — PIN, biometric preference, and whether the current session is
///   unlocked;
/// * which clones are hidden — the `hidden` flag on the profile, read and written
///   through [VirtualProfileRepository].
///
/// Anything that changes what [HomeController] should show bumps [revision], which is
/// how the grid learns to reload without the two controllers reaching into each other.
class PrivateSpaceController extends GetxController with WidgetsBindingObserver {
  PrivateSpaceController({
    required this._repository,
    PrivateSpaceStore? store,
    BiometricAuthenticator? biometric,
  })  : _store = store ?? const PrivateSpaceStore(),
        _biometric = biometric ?? BiometricAuthenticator();

  final VirtualProfileRepository _repository;
  final PrivateSpaceStore _store;
  final BiometricAuthenticator _biometric;

  final Rx<PrivateSpaceState> state = PrivateSpaceState.initial.obs;

  /// Whether this session has passed the lock. Never persisted: a restart locks again.
  final RxBool unlocked = false.obs;

  /// Whether the device can show a biometric prompt at all right now.
  final RxBool biometricAvailable = false.obs;

  /// Incremented whenever the set of hidden clones changes, so the grid can reload.
  final RxInt revision = 0.obs;

  bool get enabled => state.value.enabled;

  bool get hasPin => state.value.hasPin;

  bool get biometricEnabled => state.value.biometricEnabled;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    reload();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Leaving the app closes the space. A phone handed to someone else comes back to a
  /// locked grid rather than to whatever was on screen when it went away.
  ///
  /// Only `paused`, not `inactive`: the biometric prompt makes the app inactive, and
  /// locking there would cancel the very unlock in progress.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      lock();
    }
  }

  Future<void> reload() async {
    state.value = await _store.load();
    biometricAvailable.value = await _biometric.isAvailable();
  }

  /// Creates the space: sets its PIN, turns the lock on, and unlocks this session.
  ///
  /// The biometric is only recorded when the caller asked for it *and* the device can
  /// actually offer one, so a stored preference can never describe a prompt the device
  /// cannot show.
  Future<void> create(String pin, {bool useBiometric = false}) async {
    // Asked here rather than trusted from a previous [reload]: the device's answer can
    // change, and recording a biometric the device cannot show would strand the user.
    final bool canUseBiometric = await _biometric.isAvailable();
    biometricAvailable.value = canUseBiometric;
    await _store.setPin(pin);
    await _store.setBiometricEnabled(useBiometric && canUseBiometric);
    await _store.setEnabled(true);
    await reload();
    unlocked.value = true;
  }

  Future<bool> unlockWithPin(String pin) async {
    final bool ok = await _store.verifyPin(pin);
    if (ok) {
      unlocked.value = true;
    }
    return ok;
  }

  Future<BiometricResult> unlockWithBiometric() async {
    final BiometricResult result = await _biometric.authenticate(
      reason: 'Unlock your private space',
    );
    if (result == BiometricResult.success) {
      unlocked.value = true;
    }
    return result;
  }

  /// Confirms a PIN without unlocking — for changing or removing the lock.
  Future<bool> verifyPin(String pin) => _store.verifyPin(pin);

  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (!await _store.verifyPin(currentPin)) {
      return false;
    }
    await _store.setPin(newPin);
    return true;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _store.setBiometricEnabled(enabled);
    await reload();
  }

  void lock() => unlocked.value = false;

  /// Forgets the lock and brings every hidden clone back. The containers are untouched.
  Future<void> disable() async {
    await _store.disable();
    await _repository.unhideAll();
    unlocked.value = false;
    revision.value++;
    await reload();
  }

  /// Moves one clone in or out of the space.
  Future<void> setHidden(String profileId, bool hidden) async {
    await _repository.setHidden(profileId, hidden);
    revision.value++;
  }

  Future<void> unhideAll() async {
    await _repository.unhideAll();
    revision.value++;
  }
}
