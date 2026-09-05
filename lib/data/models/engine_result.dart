import 'package:flutter/foundation.dart';

/// The structured envelope every Phase 2 native call returns.
///
/// Native code never throws across the channel, so a failure always arrives as data
/// with a stable [code] rather than as an opaque platform exception.
@immutable
class EngineResponse {
  const EngineResponse({
    required this.success,
    required this.code,
    required this.message,
    this.data = const <String, dynamic>{},
  });

  factory EngineResponse.fromMap(Map<String, dynamic> map) {
    final Object? rawData = map['data'];
    return EngineResponse(
      success: map['success'] as bool? ?? false,
      code: map['code'] as String? ?? 'UNKNOWN',
      message: map['message'] as String? ?? '',
      data: rawData is Map
          ? rawData.map((Object? k, Object? v) => MapEntry<String, dynamic>('$k', v))
          : const <String, dynamic>{},
    );
  }

  final bool success;
  final String code;
  final String message;
  final Map<String, dynamic> data;
}

/// Whether the native virtualization backend can run on this device.
@immutable
class VirtualizationAvailability {
  const VirtualizationAvailability({
    required this.available,
    required this.backend,
    this.code,
    this.message,
  });

  factory VirtualizationAvailability.fromMap(Map<String, dynamic> map) {
    return VirtualizationAvailability(
      available: map['available'] as bool? ?? false,
      backend: map['backend'] as String? ?? 'unknown',
      code: map['code'] as String?,
      message: map['message'] as String?,
    );
  }

  final bool available;
  final String backend;
  final String? code;
  final String? message;
}

/// Engine-observed state of one profile's virtual environment.
@immutable
class VirtualProfileState {
  const VirtualProfileState({
    required this.installed,
    required this.running,
    this.virtualUserId,
  });

  factory VirtualProfileState.fromMap(Map<String, dynamic> map) {
    return VirtualProfileState(
      installed: map['installed'] as bool? ?? false,
      running: map['running'] as bool? ?? false,
      virtualUserId: map['virtualUserId'] as int?,
    );
  }

  static const VirtualProfileState unknown = VirtualProfileState(
    installed: false,
    running: false,
  );

  final bool installed;
  final bool running;
  final int? virtualUserId;
}
