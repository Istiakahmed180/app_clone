import 'package:flutter/material.dart';

import 'status_colors.dart';

/// The app's visual language.
///
/// The palette and shapes are sampled from the reference build rather than derived from
/// a seed colour: a generated scheme kept drifting the orange towards Material's own
/// harmonised hues, and the accent is the one thing that has to land exactly.
///
/// Everything downstream reads these through `Theme.of(context)`. Widgets should not
/// hard-code a colour from this file; if a widget needs a shade that is not here, the
/// shade belongs here first.
class AppTheme {
  const AppTheme._();

  // --- Palette -------------------------------------------------------------

  /// The single accent. Buttons, active states, section markers, focus rings.
  static const Color accent = Color(0xFFFF5A2E);

  /// A warm two-stop wash used only on raised accent surfaces (the pill buttons).
  /// Flat [accent] is the default; the gradient is decoration, never a state.
  static const Color accentGradientStart = Color(0xFFFF5C30);
  static const Color accentGradientEnd = Color(0xFFFF764D);

  /// The accent at ~6% over white. Fills tinted tiles and icon medallions.
  static const Color accentTint = Color(0xFFFFF0EB);

  static const Color ink = Color(0xFF171A22);
  static const Color inkMuted = Color(0xFF6F7480);

  /// Card and divider hairlines. Cards are defined by this border, not by elevation.
  static const Color hairline = Color(0xFFE7EAF0);

  /// Slightly warmer hairline used on input chrome.
  static const Color hairlineField = Color(0xFFE8E8E8);

  static const Color danger = Color(0xFFD92D20);

  /// Reserved for "settled, nothing to do" states, so status is not carried by the
  /// accent alone -- an orange "Ready" next to an orange "Running" reads as one thing.
  static const Color positive = Color(0xFF12A150);

  /// "Works, but read this." Distinct from both [positive] and [danger]; reached
  /// through [StatusColors], never by widgets naming this constant.
  static const Color warning = Color(0xFFB54708);

  // Dark counterparts. The reference build ships light only, so these are this app's
  // own: same accent, surfaces dropped to near-black, hairlines lifted rather than
  // inverted. Dark mode is not left to a generated scheme that would recolour the accent.
  static const Color darkSurface = Color(0xFF121317);
  static const Color darkSurfaceRaised = Color(0xFF1B1D23);
  static const Color darkInk = Color(0xFFF2F3F5);
  static const Color darkInkMuted = Color(0xFF9BA1AE);
  static const Color darkHairline = Color(0xFF2A2D35);
  static const Color darkAccentTint = Color(0xFF2A1A15);

  // --- Shape ---------------------------------------------------------------

  /// Cards, sheets, menus.
  static const double cardRadius = 16;

  /// The larger radius used by tappable tiles that stand on their own.
  static const double tileRadius = 20;

  static const LinearGradient accentGradient = LinearGradient(
    colors: <Color>[accentGradientStart, accentGradientEnd],
  );

  // --- Themes --------------------------------------------------------------

  static ThemeData light() => _build(_lightScheme);

  static ThemeData dark() => _build(_darkScheme);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: accent,
    onPrimary: Colors.white,
    primaryContainer: accentTint,
    onPrimaryContainer: accent,
    secondary: accent,
    onSecondary: Colors.white,
    secondaryContainer: accentTint,
    onSecondaryContainer: accent,
    tertiary: positive,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFE6F6EC),
    onTertiaryContainer: Color(0xFF0B6B35),
    error: danger,
    onError: Colors.white,
    errorContainer: Color(0xFFFDECEA),
    onErrorContainer: Color(0xFF8B1D14),
    surface: Colors.white,
    onSurface: ink,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Colors.white,
    surfaceContainer: Colors.white,
    surfaceContainerHigh: Colors.white,
    surfaceContainerHighest: Color(0xFFF7F8FA),
    onSurfaceVariant: inkMuted,
    outline: hairlineField,
    outlineVariant: hairline,
    inverseSurface: ink,
    onInverseSurface: Colors.white,
    shadow: Color(0x14000000),
    scrim: Color(0x66000000),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: accent,
    onPrimary: Colors.white,
    primaryContainer: darkAccentTint,
    onPrimaryContainer: Color(0xFFFF8A66),
    secondary: accent,
    onSecondary: Colors.white,
    secondaryContainer: darkAccentTint,
    onSecondaryContainer: Color(0xFFFF8A66),
    tertiary: Color(0xFF3DD68C),
    onTertiary: Color(0xFF06301A),
    tertiaryContainer: Color(0xFF14301F),
    onTertiaryContainer: Color(0xFF7FE7B0),
    error: Color(0xFFFF6B5E),
    onError: Color(0xFF4A0B06),
    errorContainer: Color(0xFF3A1512),
    onErrorContainer: Color(0xFFFFB4AA),
    surface: darkSurface,
    onSurface: darkInk,
    surfaceContainerLowest: Color(0xFF0D0E11),
    surfaceContainerLow: darkSurface,
    surfaceContainer: darkSurfaceRaised,
    surfaceContainerHigh: darkSurfaceRaised,
    surfaceContainerHighest: Color(0xFF23262E),
    onSurfaceVariant: darkInkMuted,
    outline: darkHairline,
    outlineVariant: darkHairline,
    inverseSurface: Color(0xFFE9EAEE),
    onInverseSurface: Color(0xFF1B1D23),
    shadow: Color(0x33000000),
    scrim: Color(0x99000000),
  );

  static ThemeData _build(ColorScheme scheme) {
    final TextTheme text = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
      ),

      // Flat, hairline-bordered cards. Elevation is what the reference build replaced
      // with a border, and mixing the two reads as two different card systems.
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      filledButtonTheme: FilledButtonThemeData(style: _pillButton(text)),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _pillButton(text)),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
          side: BorderSide(color: scheme.primary),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: _fieldBorder(scheme.outline),
        enabledBorder: _fieldBorder(scheme.outline),
        focusedBorder: _fieldBorder(scheme.primary, width: 1.5),
        errorBorder: _fieldBorder(scheme.error),
        focusedErrorBorder: _fieldBorder(scheme.error, width: 1.5),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        extendedTextStyle: text.labelLarge,
        shape: const StadiumBorder(),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        textStyle: text.bodyLarge,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: text.headlineSmall,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      ),

      listTileTheme: ListTileThemeData(
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        iconColor: scheme.onSurfaceVariant,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      splashFactory: InkSparkle.splashFactory,

      extensions: <ThemeExtension<dynamic>>[
        scheme.brightness == Brightness.light
            ? const StatusColors(positive: positive, warning: warning)
            : const StatusColors(
                positive: Color(0xFF3DD68C),
                warning: Color(0xFFF5A524),
              ),
      ],
    );
  }

  /// Shape and weight only. Colours are left to each button variant's own defaults, so
  /// `FilledButton` stays the accent and `FilledButton.tonal` stays the tint -- naming a
  /// background here would flatten both into the same solid pill.
  static ButtonStyle _pillButton(TextTheme text) => ButtonStyle(
        elevation: const WidgetStatePropertyAll<double>(0),
        textStyle: WidgetStatePropertyAll<TextStyle?>(text.labelLarge),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        ),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
      );

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: color, width: width),
      );

  /// Weights carry the hierarchy here; there is only one type family and one accent, so
  /// a heading that is merely larger does not read as a heading.
  static TextTheme _textTheme(ColorScheme scheme) {
    final Color on = scheme.onSurface;
    final Color muted = scheme.onSurfaceVariant;

    return TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: on),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: on),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: on),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: on),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: on),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: on),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: on),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: on),
      bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: muted),
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: on),
      labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: muted),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: muted),
    );
  }
}
