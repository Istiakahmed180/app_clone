import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/profile_storage.dart';
import '../../core/utils/app_logger.dart';
import '../models/virtual_profile_model.dart';

/// Owns all persistence of virtual profile metadata.
///
/// Duplicate policy: several profiles may reference the same package, but profile
/// names must be unique (trimmed, case-insensitive). A duplicate name is rejected
/// with a [ValidationException] rather than silently overwriting the existing
/// profile.
class VirtualProfileRepository {
  VirtualProfileRepository({
    ProfileStorage? storage,
    Uuid? uuid,
  })  : _storage = storage ?? const SharedPreferencesProfileStorage(),
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
      _logger.error('Stored profile data could not be decoded', error, stackTrace);
      throw const StorageException('Saved profiles could not be read.');
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

  Future<VirtualProfileModel> createProfile({
    required String packageName,
    required String appName,
    required String profileName,
  }) async {
    final String name = _validateName(profileName);
    final List<VirtualProfileModel> profiles = await getProfiles();
    _requireUniqueName(profiles, name, excludingId: null);

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
  }) async {
    final List<VirtualProfileModel> profiles = await getProfiles();
    final int index = profiles.indexWhere((VirtualProfileModel p) => p.id == profileId);
    if (index == -1) {
      throw ProfileNotFoundException(profileId);
    }

    final String? name = profileName == null ? null : _validateName(profileName);
    if (name != null) {
      _requireUniqueName(profiles, name, excludingId: profileId);
    }

    final VirtualProfileModel updated =
        profiles[index].copyWith(profileName: name, enabled: enabled);

    final List<VirtualProfileModel> next = List<VirtualProfileModel>.of(profiles)
      ..[index] = updated;
    await _persist(next);
    return updated;
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
      profiles.map((VirtualProfileModel p) => p.toJson()).toList(growable: false),
    );
    await _storage.write(AppConstants.profilesStorageKey, encoded);
  }

  String _validateName(String value) {
    final String name = value.trim();
    if (name.isEmpty) {
      throw const ValidationException('Profile name cannot be empty.');
    }
    if (name.length > AppConstants.maxProfileNameLength) {
      throw const ValidationException(
        'Profile name must be ${AppConstants.maxProfileNameLength} characters or fewer.',
      );
    }
    return name;
  }

  void _requireUniqueName(
    List<VirtualProfileModel> profiles,
    String name, {
    required String? excludingId,
  }) {
    final String needle = name.toLowerCase();
    final bool taken = profiles.any((VirtualProfileModel p) =>
        p.id != excludingId && p.profileName.toLowerCase() == needle);
    if (taken) {
      throw ValidationException('A profile named "$name" already exists.');
    }
  }
}
