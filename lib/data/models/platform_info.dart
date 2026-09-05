import 'package:flutter/foundation.dart';

/// Minimal device description used for diagnostics on the home screen.
@immutable
class PlatformInfo {
  const PlatformInfo({
    required this.androidVersion,
    required this.sdkInt,
    required this.manufacturer,
    required this.model,
  });

  factory PlatformInfo.fromMap(Map<String, dynamic> map) {
    return PlatformInfo(
      androidVersion: map['androidVersion'] as String? ?? 'unknown',
      sdkInt: map['sdkInt'] as int? ?? 0,
      manufacturer: map['manufacturer'] as String? ?? 'unknown',
      model: map['model'] as String? ?? 'unknown',
    );
  }

  final String androidVersion;
  final int sdkInt;
  final String manufacturer;
  final String model;

  String get summary => '$manufacturer $model · Android $androidVersion (API $sdkInt)';
}
