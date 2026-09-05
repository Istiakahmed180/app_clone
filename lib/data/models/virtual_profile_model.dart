import 'package:flutter/foundation.dart';

/// Metadata describing one virtual profile.
///
/// A profile is *only* metadata in Phase 1: it does not own an Android process,
/// UID, package installation or data directory.
@immutable
class VirtualProfileModel {
  const VirtualProfileModel({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.profileName,
    required this.createdAt,
    this.enabled = true,
  });

  factory VirtualProfileModel.fromJson(Map<String, dynamic> json) {
    return VirtualProfileModel(
      id: json['id'] as String,
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      profileName: json['profileName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  final String id;
  final String packageName;
  final String appName;
  final String profileName;
  final DateTime createdAt;
  final bool enabled;

  VirtualProfileModel copyWith({String? profileName, bool? enabled}) {
    return VirtualProfileModel(
      id: id,
      packageName: packageName,
      appName: appName,
      profileName: profileName ?? this.profileName,
      createdAt: createdAt,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'packageName': packageName,
        'appName': appName,
        'profileName': profileName,
        'createdAt': createdAt.toIso8601String(),
        'enabled': enabled,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VirtualProfileModel &&
          other.id == id &&
          other.packageName == packageName &&
          other.appName == appName &&
          other.profileName == profileName &&
          other.createdAt == createdAt &&
          other.enabled == enabled;

  @override
  int get hashCode =>
      Object.hash(id, packageName, appName, profileName, createdAt, enabled);
}
