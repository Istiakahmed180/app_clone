import 'package:flutter/foundation.dart';

import 'clone_icon_color.dart';

/// Metadata describing one virtual profile.
///
/// This model is the host's own record of a clone. The container it maps to — with its
/// own isolated application data — is owned by the native engine and keyed by [id]; see
/// `VirtualProfileManager` for the profile-to-virtual-user mapping.
///
/// A clone does *not* get its own Android UID: guests run under the host's identity and
/// inherit its permission grants.
@immutable
class VirtualProfileModel {
  const VirtualProfileModel({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.profileName,
    required this.createdAt,
    this.enabled = true,
    this.hidden = false,
    this.iconColor = CloneIconColor.none,
    this.iconPath,
  });

  factory VirtualProfileModel.fromJson(Map<String, dynamic> json) {
    return VirtualProfileModel(
      id: json['id'] as String,
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      profileName: json['profileName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      enabled: json['enabled'] as bool? ?? true,
      hidden: json['hidden'] as bool? ?? false,
      iconColor: CloneIconColor.parse(json['iconColor'] as String?),
      iconPath: json['iconPath'] as String?,
    );
  }

  final String id;
  final String packageName;
  final String appName;
  final String profileName;
  final DateTime createdAt;
  final bool enabled;

  /// True when this clone lives in the Private space rather than the main grid.
  ///
  /// Host-side metadata only: hiding never touches the container, so a clone keeps its
  /// data and keeps running. Absent from older stored profiles, hence the `false`
  /// default in [fromJson].
  final bool hidden;

  /// The mark the user put on this clone to tell it from its siblings, or
  /// [CloneIconColor.none] when they have not chosen one.
  ///
  /// Host-side metadata, like [hidden]: it changes how the clone is drawn and nothing
  /// about the container. Absent from older stored profiles, which [CloneIconColor.parse]
  /// reads as [CloneIconColor.none].
  final CloneIconColor iconColor;

  /// A picture the user chose for this clone, replacing its app's icon, or null when it
  /// still shows the app's own.
  ///
  /// A path rather than the bytes: profiles are rewritten whole on every change, and
  /// carrying a few hundred kilobytes of PNG in each row would make renaming one clone
  /// rewrite the icons of all of them. The file is owned by `CloneIconStore`.
  ///
  /// A path whose file has gone reads as no custom icon rather than as an error: losing
  /// the picture should cost the user their icon, not their clone.
  final String? iconPath;

  VirtualProfileModel copyWith({
    String? profileName,
    bool? enabled,
    bool? hidden,
    CloneIconColor? iconColor,
    String? iconPath,
    bool clearIconPath = false,
  }) {
    return VirtualProfileModel(
      id: id,
      packageName: packageName,
      appName: appName,
      profileName: profileName ?? this.profileName,
      createdAt: createdAt,
      enabled: enabled ?? this.enabled,
      hidden: hidden ?? this.hidden,
      iconColor: iconColor ?? this.iconColor,
      iconPath: clearIconPath ? null : (iconPath ?? this.iconPath),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'packageName': packageName,
        'appName': appName,
        'profileName': profileName,
        'createdAt': createdAt.toIso8601String(),
        'enabled': enabled,
        'hidden': hidden,
        'iconColor': iconColor.wire,
        'iconPath': iconPath,
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
          other.enabled == enabled &&
          other.hidden == hidden &&
          other.iconColor == iconColor &&
          other.iconPath == iconPath;

  @override
  int get hashCode =>
      Object.hash(id, packageName, appName, profileName, createdAt, enabled, hidden,
          iconColor, iconPath);
}
