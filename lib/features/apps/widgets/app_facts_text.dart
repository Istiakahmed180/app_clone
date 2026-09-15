import '../../../data/models/app_details.dart';
import '../../../data/models/installed_app_model.dart';
import '../../../l10n/app_localizations.dart';

/// The chips and rows that describe a package, in the user's language.
///
/// These read like one string but are a translated word wrapped around untranslated
/// tokens: `ARM64 + ARMv7 · 32 + 64` is an ABI list the platform named and a bit width
/// that is the same in every language, while "No native code" and "Split APK" are
/// sentences. Keeping the assembly here rather than on the models is what lets the
/// sentences move and the tokens stay put.

/// `ARM64 + ARMv7 · 32 + 64`, or the honest answer for pure bytecode.
String installedArchitectureLabel(
  AppLocalizations l10n,
  InstalledAppModel app,
) {
  if (app.abis.isEmpty) {
    return l10n.factsNoNativeCode;
  }
  return _withBits(l10n, app.abiNames.join(' + '), app.supports32Bit, app.supports64Bit);
}

/// The same line for an app the details screen read in full.
String detailsArchitectureLabel(AppLocalizations l10n, AppDetails details) {
  if (details.abis.isEmpty) {
    return l10n.factsNoNativeCode;
  }
  return _withBits(
    l10n,
    AppDetails.abiLabel(details.abis),
    details.supports32Bit,
    details.supports64Bit,
  );
}

/// `64-bit`, `32-bit`, `32 + 64`, or the honest answer for pure bytecode.
String bitnessLabel(
  AppLocalizations l10n, {
  required bool supports32Bit,
  required bool supports64Bit,
}) =>
    _bits(l10n, supports32Bit, supports64Bit) ?? l10n.factsAnyNoNativeCode;

/// `1.0.7 (8)`, or just one half when the other is missing.
String versionLabel(AppLocalizations l10n, AppDetails details) {
  final String? name = details.versionName;
  final int? code = details.versionCode;
  if (name == null && code == null) {
    return l10n.factsVersionUnknown;
  }
  if (code == null) {
    return name!;
  }
  if (name == null) {
    return '($code)';
  }
  return '$name ($code)';
}

/// `Single APK` or `Split APK · 4 files`.
String packageTypeLabel(AppLocalizations l10n, int apkCount) =>
    apkCount > 1 ? l10n.factsSplitApk(apkCount) : l10n.factsSingleApk;

/// One APK in the package: `Base APK · No native libraries · 25 MB`, or
/// `Split APK · config.arm64_v8a · arm64-v8a · 32 MB`.
///
/// The split name and the ABI list are the platform's own identifiers and stay as they
/// are; only the two nouns around them are sentences.
String apkComponentSummary(AppLocalizations l10n, ApkComponent component) =>
    <String>[
      component.isBase ? l10n.componentBaseApk : l10n.componentSplitApk,
      if (component.splitName != null && component.splitName!.isNotEmpty)
        component.splitName!,
      if (component.abis.isEmpty)
        l10n.componentNoNativeLibraries
      else
        component.abis.join(', '),
      AppDetails.formatBytes(component.sizeBytes),
    ].join(' · ');

/// An APK size, or the honest answer when the platform reported none.
String totalSizeLabel(AppLocalizations l10n, int bytes) =>
    bytes <= 0 ? l10n.factsVersionUnknown : AppDetails.formatBytes(bytes);

/// The ABI names followed by the bit widths, when there are any to add.
String _withBits(
  AppLocalizations l10n,
  String names,
  bool supports32Bit,
  bool supports64Bit,
) {
  final String? bits = _bits(l10n, supports32Bit, supports64Bit);
  return bits == null ? names : '$names · $bits';
}

/// Null when the package has no native code at all, which the callers word for
/// themselves — a chip says nothing and a dedicated row says "Any".
String? _bits(AppLocalizations l10n, bool supports32Bit, bool supports64Bit) =>
    switch ((supports32Bit, supports64Bit)) {
      (true, true) => l10n.factsBits32And64,
      (false, true) => l10n.settingsBits64,
      (true, false) => l10n.settingsBits32,
      (false, false) => null,
    };
