import 'package:flutter/foundation.dart';

/// The per-clone permission policy for one clone.
///
/// [permissions] are the dangerous permissions the cloned app declares; [denied] is the
/// subset the user has turned off for this clone. An untouched clone denies nothing, so it
/// behaves exactly as before.
@immutable
class ClonePermissions {
  const ClonePermissions({
    required this.virtualUserId,
    required this.permissions,
    required this.denied,
  });

  factory ClonePermissions.fromMap(Map<String, dynamic> map) {
    final Object? rawPermissions = map['permissions'];
    final Object? rawDenied = map['denied'];
    return ClonePermissions(
      virtualUserId: map['virtualUserId'] as int? ?? -1,
      permissions: rawPermissions is List
          ? rawPermissions.map((Object? p) => '$p').toList(growable: false)
          : const <String>[],
      denied: rawDenied is List
          ? rawDenied.map((Object? p) => '$p').toSet()
          : const <String>{},
    );
  }

  final int virtualUserId;
  final List<String> permissions;
  final Set<String> denied;

  bool allowed(String permission) => !denied.contains(permission);

  /// A permission's short name for the row: the last segment after the final dot, spaced.
  static String label(String permission) {
    final String tail = permission.split('.').last.replaceAll('_', ' ');
    if (tail.isEmpty) {
      return permission;
    }
    return tail[0].toUpperCase() + tail.substring(1).toLowerCase();
  }
}
