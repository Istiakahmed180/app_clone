import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/profile_storage.dart';
import '../../core/utils/app_logger.dart';
import '../models/clone_icon_color.dart';
import '../models/virtual_profile_model.dart';

/// Owns all persistence of virtual profile metadata.
///
/// Duplicate policy: profiles may freely share a package **and** a name. A clone is
/// identified by its [VirtualProfileModel.id], never by what it is called, so names
/// carry no meaning the app depends on.
///
/// Names used to be forced unique, which meant the second clone of an app was called
/// "Camera 2". That is a worse answer than a duplicate: on a grid of icons the name is
/// the app's identity, and renaming it to something the user never chose makes the tile
/// look like a different app. Two clones of the same app are told apart by the instance
/// number on the tile and by "clone 1 of 2" in the action sheet; two clones of
/// *different* apps with the same label are told apart by their icons — which is exactly
/// how Android's own launcher handles it.
///
/// Empty and over-long names are still rejected.
class VirtualProfileRepository {
  VirtualProfileRepository({ProfileStorage? storage, Uuid? uuid})
    : _storage = storage ?? const SharedPreferencesProfileStorage(),
      _uuid = uuid ?? const Uuid();

  final ProfileStorage _storage;
  final Uuid _uuid;
  final AppLogger _logger = const AppLogger('VirtualProfileRepository');

  Future<List<VirtualProfileModel>> getProfiles() async {
    final String? raw = await _storage.read(AppConstants.profilesStorageKey);
    if (raw == null || raw.isEmpty) {
      return const <VirtualProfileModel>[];
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .cast<Map<String, dynamic>>()
          .map(VirtualProfileModel.fromJson)
          .toList(growable: false);
    } on Object catch (error, stackTrace) {
      _logger.error(
        'Stored profile data could not be decoded',
        error,
        stackTrace,
      );
      throw const StorageException(
        AppErrorCodes.profileStorageUnreadable,
        'Saved profiles could not be read.',
      );
    }
  }

  Future<VirtualProfileModel?> getProfile(String profileId) async {
    final List<VirtualProfileModel> profiles = await getProfiles();
    for (final VirtualProfileModel profile in profiles) {
      if (profile.id == profileId) {
        return profile;
      }
    }
    return null;
  }

  /// The name a new clone should get: the app's own name, every time.
  ///
  /// No numbering, and no consulting the existing profiles. A clone of Camera is called
  /// "Camera" whether it is the first or the fifth; the tile's instance badge is what
  /// distinguishes them. The user can still rename any clone afterwards.
  ///
  /// Async only because it once had to read the stored profiles to find a free name.
  /// Kept that way so callers — and their tests — do not all have to change for a
  /// detail of this method.
  Future<String> suggestProfileName({
    required String appName,
    required String packageName,
  }) async {
    final String base = appName.trim().isEmpty
        ? packageName.trim()
        : appName.trim();
    // Clamped here rather than left to fail in [createProfile]: an app whose own name is
    // longer than the limit would otherwise make cloning it impossible.
    if (base.length <= AppConstants.maxProfileNameLength) {
      return base;
    }
    return base.substring(0, _cutBefore(base)).trimRight();
  }

  /// Where to cut [text] so the result fits the limit without splitting a character.
  ///
  /// The limit counts UTF-16 code units, and a character outside the basic plane is two
  /// of them. Cutting at the bound alone can therefore land between the halves of a
  /// surrogate pair and leave the first half behind — which is not a character at all,
  /// and renders as a replacement glyph in the clone's name. Backing off by one costs a
  /// character nobody would miss and keeps the string well-formed.
  static int _cutBefore(String text) {
    const int limit = AppConstants.maxProfileNameLength;
    final int unit = text.codeUnitAt(limit - 1);
    final bool splitsAPair = unit >= 0xD800 && unit <= 0xDBFF;
    return splitsAPair ? limit - 1 : limit;
  }

  /// How many profiles already clone [packageName].
  Future<int> instanceCountFor(String packageName) async {
    final List<VirtualProfileModel> profiles = await getProfiles();
    return profiles
        .where((VirtualProfileModel p) => p.packageName == packageName)
        .length;
  }

  /// Every package that has at least one clone.
  ///
  /// One read for the whole picker, rather than [instanceCountFor] per row.
  Future<Set<String>> clonedPackageNames() async {
    final List<VirtualProfileModel> profiles = await getProfiles();
    return profiles.map((VirtualProfileModel p) => p.packageName).toSet();
  }

  Future<VirtualProfileModel> createProfile({
    required String packageName,
    required String appName,
    required String profileName,
  }) async {
    final String name = _validateName(profileName);
    final List<VirtualProfileModel> profiles = await getProfiles();

    final VirtualProfileModel profile = VirtualProfileModel(
      id: _uuid.v4(),
      packageName: packageName,
      appName: appName,
      profileName: name,
      createdAt: DateTime.now(),
    );

    await _persist(<VirtualProfileModel>[...profiles, profile]);
    return profile;
  }

  Future<VirtualProfileModel> updateProfile(
    String profileId, {
    String? profileName,
    bool? enabled,
    bool? hidden,
    CloneIconColor? iconColor,
    String? iconPath,
    bool clearIconPath = false,
  }) async {
    final List<VirtualProfileModel> profiles = await getProfiles();
    final int index = profiles.indexWhere(
      (VirtualProfileModel p) => p.id == profileId,
    );
    if (index == -1) {
      throw ProfileNotFoundException(profileId);
    }

    final String? name = profileName == null
        ? null
        : _validateName(profileName);

    final VirtualProfileModel updated = profiles[index].copyWith(
      profileName: name,
      enabled: enabled,
      hidden: hidden,
      iconColor: iconColor,
      iconPath: iconPath,
      clearIconPath: clearIconPath,
    );

    final List<VirtualProfileModel> next = List<VirtualProfileModel>.of(
      profiles,
    )..[index] = updated;
    await _persist(next);
    return updated;
  }

  /// Moves a profile in or out of the Private space. The container is untouched.
  Future<VirtualProfileModel> setHidden(String profileId, bool hidden) =>
      updateProfile(profileId, hidden: hidden);

  /// Brings every hidden clone back to the main grid, in one write.
  ///
  /// Used when the Private space is turned off: the lock is gone, so leaving clones
  /// hidden would strand them behind a door that no longer exists.
  Future<void> unhideAll() async {
    final List<VirtualProfileModel> profiles = await getProfiles();
    if (!profiles.any((VirtualProfileModel p) => p.hidden)) {
      return;
    }
    await _persist(
      profiles
          .map((VirtualProfileModel p) => p.copyWith(hidden: false))
          .toList(growable: false),
    );
  }

  Future<void> deleteProfile(String profileId) async {
    final List<VirtualProfileModel> profiles = await getProfiles();
    final List<VirtualProfileModel> next = profiles
        .where((VirtualProfileModel p) => p.id != profileId)
        .toList(growable: false);

    if (next.length == profiles.length) {
      throw ProfileNotFoundException(profileId);
    }

    await _persist(next);
  }

  Future<void> _persist(List<VirtualProfileModel> profiles) async {
    final String encoded = jsonEncode(
      profiles
          .map((VirtualProfileModel p) => p.toJson())
          .toList(growable: false),
    );
    await _storage.write(AppConstants.profilesStorageKey, encoded);
  }

  String _validateName(String value) {
    final String name = value.trim();
    if (name.isEmpty) {
      throw const ValidationException(
        AppErrorCodes.profileNameEmpty,
        'Profile name cannot be empty.',
      );
    }
    if (name.length > AppConstants.maxProfileNameLength) {
      throw const ValidationException(
        AppErrorCodes.profileNameTooLong,
        'Profile name must be ${AppConstants.maxProfileNameLength} characters or fewer.',
      );
    }
    return name;
  }
}
