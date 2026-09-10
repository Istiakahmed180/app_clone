import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/legal_constants.dart';
import '../../../core/constants/support_constants.dart';
import '../../../core/diagnostics/diagnostics_repository.dart';
import '../../../core/diagnostics/system_info.dart';
import '../../../core/services/settings_store.dart';
import '../../../core/utils/app_logger.dart';

/// App-level preferences, and the build facts the About section reports.
///
/// Registered permanently rather than with the Settings route: the stored appearance
/// has to be applied at launch, and a controller that only exists while its screen is
/// open would apply it the first time the user opened Settings and not before.
class SettingsController extends GetxController {
  SettingsController({
    required this._diagnostics,
    SettingsStore? store,
    Future<bool> Function(Uri url)? openUrl,
    void Function(ThemeMode mode)? applyThemeMode,
  })  : _store = store ?? const SettingsStore(),
        _openUrl = openUrl ?? _launch,
        // Injected so the theme can be applied without a GetMaterialApp in the tree.
        _applyThemeMode = applyThemeMode ?? Get.changeThemeMode;

  final DiagnosticsRepository _diagnostics;
  final SettingsStore _store;
  final Future<bool> Function(Uri url) _openUrl;
  final void Function(ThemeMode mode) _applyThemeMode;
  final AppLogger _logger = const AppLogger('SettingsController');

  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  /// The build and device facts behind the About section. Null until it arrives.
  final Rxn<SystemInfoSnapshot> systemInfo = Rxn<SystemInfoSnapshot>();

  /// Set when an action could not be carried out. The view reports and clears it.
  final Rxn<String> statusMessage = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    unawaited(restoreThemeMode());
    unawaited(loadSystemInfo());
  }

  /// Applies the stored appearance. Called at launch, before Settings is ever opened.
  Future<void> restoreThemeMode() async {
    final ThemeMode stored = await _store.themeMode();
    themeMode.value = stored;
    _applyThemeMode(stored);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == themeMode.value) {
      return;
    }
    // Applied before it is persisted: the user sees their choice immediately, and a
    // storage failure costs them the preference next launch rather than this tap.
    themeMode.value = mode;
    _applyThemeMode(mode);
    try {
      await _store.setThemeMode(mode);
    } on Object catch (error, stackTrace) {
      _logger.error('Could not store the appearance choice', error, stackTrace);
    }
  }

  Future<void> loadSystemInfo() async {
    try {
      systemInfo.value = await _diagnostics.systemInfo();
    } on Object catch (error, stackTrace) {
      // The About rows read 'unavailable' on their own, so this is logged and not
      // surfaced: a failed version lookup is not worth a snack bar over.
      _logger.error('Could not read system information', error, stackTrace);
    }
  }

  // --- About ---------------------------------------------------------------

  /// `1.0.0 (1)`, or null while the lookup has not landed.
  String? get versionLabel {
    final SystemInfoSnapshot? info = systemInfo.value;
    final String? name = info?.appVersion;
    if (name == null) {
      return null;
    }
    final String? code = info?.appVersionCode;
    return code == null ? name : '$name ($code)';
  }

  /// `64-bit · arm64-v8a`, or null until the ABI is known.
  String? get architectureLabel {
    final SystemInfoSnapshot? info = systemInfo.value;
    final String? abi = info?.primaryAbi;
    final bool? is64Bit = info?.is64Bit;
    if (abi == null || is64Bit == null) {
      return null;
    }
    return '${is64Bit ? '64-bit' : '32-bit'} · $abi';
  }

  String? get supportedAbisLabel {
    final List<String> abis = systemInfo.value?.supportedAbis ?? const <String>[];
    return abis.isEmpty ? null : abis.join(', ');
  }

  int get copyrightYear => DateTime.now().year;

  // --- Outbound links ------------------------------------------------------

  /// Whether the legal rows can be offered. False while the URLs are placeholders --
  /// the same rule the terms dialog follows.
  bool get legalLinksArePublished => !LegalConstants.policiesArePlaceholders;

  bool get reviewLinkIsPublished => SupportConstants.isListedOnPlayStore;

  Future<void> contactSupport() async {
    final Uri mail = Uri(
      scheme: 'mailto',
      path: SupportConstants.supportEmail,
      queryParameters: <String, String>{
        'subject': '${AppConstants.appTitle} ${versionLabel ?? ''}'.trim(),
      },
    );
    await _open(mail, 'No mail app could be opened. Write to '
        '${SupportConstants.supportEmail} instead.');
  }

  /// Opens the Play listing, falling back to the web URL when the Play app is absent.
  Future<void> openReview() async {
    if (!reviewLinkIsPublished) {
      return;
    }
    if (await _openUrl(Uri.parse(SupportConstants.playStoreUri))) {
      return;
    }
    await _open(
      Uri.parse(SupportConstants.playStoreWebUrl),
      'The Play Store could not be opened.',
    );
  }

  Future<void> openPrivacyPolicy() =>
      _openLegal(LegalConstants.privacyPolicyUrl, 'Privacy Policy');

  Future<void> openTermsOfService() =>
      _openLegal(LegalConstants.termsOfServiceUrl, 'Terms of Service');

  Future<void> _openLegal(String url, String what) async {
    if (!legalLinksArePublished) {
      return;
    }
    await _open(Uri.parse(url), 'The $what could not be opened.');
  }

  Future<void> _open(Uri url, String failureMessage) async {
    try {
      if (await _openUrl(url)) {
        return;
      }
    } on Object catch (error, stackTrace) {
      _logger.error('Could not open $url', error, stackTrace);
    }
    statusMessage.value = failureMessage;
  }

  static Future<bool> _launch(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);
}
