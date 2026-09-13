import 'package:flutter/foundation.dart';

import 'app_details.dart';

/// What the device has room for: space to keep containers in, memory to run them in.
///
/// A snapshot, not a reservation. The numbers were true when they were read, and another
/// app can claim the space or the memory a moment later. Good enough to refuse what
/// plainly will not fit; not good enough to promise what barely does.
@immutable
class DeviceCapacity {
  const DeviceCapacity({
    required this.freeBytes,
    required this.totalBytes,
    this.totalMemBytes,
    this.availMemBytes,
    this.isLowRamDevice,
  });

  factory DeviceCapacity.fromMap(Map<String, dynamic> map) => DeviceCapacity(
    freeBytes: (map['freeBytes'] as num?)?.toInt() ?? -1,
    totalBytes: (map['totalBytes'] as num?)?.toInt() ?? -1,
    totalMemBytes: (map['totalMemBytes'] as num?)?.toInt(),
    availMemBytes: (map['availMemBytes'] as num?)?.toInt(),
    isLowRamDevice: map['isLowRamDevice'] as bool?,
  );

  final int freeBytes;
  final int totalBytes;

  /// Null on a device that did not answer. Absent is not the same as zero, and a
  /// caller that treated it as zero would report a phone with no memory at all.
  final int? totalMemBytes;
  final int? availMemBytes;
  final bool? isLowRamDevice;

  /// False when the volume did not answer with usable numbers. Callers read this as
  /// "do not know" and stand aside, rather than as "no space".
  bool get knowsStorage => totalBytes > 0 && freeBytes >= 0;

  bool get knowsMemory => (totalMemBytes ?? 0) > 0;

  String get freeLabel => AppDetails.formatBytes(freeBytes);
  String get totalMemLabel =>
      knowsMemory ? AppDetails.formatBytes(totalMemBytes!) : 'unknown';
}
