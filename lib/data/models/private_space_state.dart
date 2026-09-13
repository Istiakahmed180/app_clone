import 'package:flutter/foundation.dart';

/// What the app knows about the Private space lock, without any secret in it.
///
/// [pinHash] and its salt deliberately never leave the store: the controller asks the
/// store to verify a PIN rather than reading the hash and comparing it itself.
@immutable
class PrivateSpaceState {
  const PrivateSpaceState({
    required this.enabled,
    required this.hasPin,
    required this.biometricEnabled,
  });

  /// Where a space with no PIN set yet begins.
  static const PrivateSpaceState initial = PrivateSpaceState(
    enabled: false,
    hasPin: false,
    biometricEnabled: false,
  );

  /// True once the user has created the space. Hidden clones stay hidden only while
  /// this is true; see `HomeController`.
  final bool enabled;

  final bool hasPin;

  /// The user's preference to unlock with their device biometric. Whether the device
  /// can actually do it is a separate, live question asked of the platform.
  final bool biometricEnabled;

  PrivateSpaceState copyWith({
    bool? enabled,
    bool? hasPin,
    bool? biometricEnabled,
  }) {
    return PrivateSpaceState(
      enabled: enabled ?? this.enabled,
      hasPin: hasPin ?? this.hasPin,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivateSpaceState &&
          other.enabled == enabled &&
          other.hasPin == hasPin &&
          other.biometricEnabled == biometricEnabled;

  @override
  int get hashCode => Object.hash(enabled, hasPin, biometricEnabled);
}
