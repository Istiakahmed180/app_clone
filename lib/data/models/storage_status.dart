import 'package:flutter/foundation.dart';

import 'app_details.dart';

/// Free and total space on the volume clone containers are written to.
///
/// A snapshot, not a reservation: the number was true when it was read, and another
/// app can claim the space a moment later. Good enough to refuse a batch that plainly
/// cannot fit; not good enough to promise one that barely does.
@immutable
class StorageStatus {
  const StorageStatus({required this.freeBytes, required this.totalBytes});

  factory StorageStatus.fromMap(Map<String, dynamic> map) => StorageStatus(
    freeBytes: (map['freeBytes'] as num?)?.toInt() ?? 0,
    totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
  );

  final int freeBytes;
  final int totalBytes;

  /// True when the device did not answer with usable numbers. Callers treat this as
  /// "do not know" and carry on, rather than as "no space".
  bool get isUnknown => totalBytes <= 0 || freeBytes < 0;

  String get freeLabel => AppDetails.formatBytes(freeBytes);
  String get totalLabel => AppDetails.formatBytes(totalBytes);
}
