import 'package:flutter/material.dart';

/// Accent color choices. "Ember" is the default DailyAL-"Fall"-like look.
enum AppAccent {
  ember,
  honey,
  rosewood,
  crimson,
  violet,
  indigo,
  azure,
  teal,
  jade,
  lime,
  amber,
  slate,
}

extension AppAccentX on AppAccent {
  String get label => switch (this) {
        AppAccent.ember => 'Ember',
        AppAccent.honey => 'Honey',
        AppAccent.rosewood => 'Rosewood',
        AppAccent.crimson => 'Crimson',
        AppAccent.violet => 'Violet',
        AppAccent.indigo => 'Indigo',
        AppAccent.azure => 'Azure',
        AppAccent.teal => 'Teal',
        AppAccent.jade => 'Jade',
        AppAccent.lime => 'Lime',
        AppAccent.amber => 'Amber',
        AppAccent.slate => 'Slate',
      };

  /// Primary color per brightness.
  Color primary(Brightness b) => switch ((this, b)) {
        (AppAccent.ember, Brightness.dark) => const Color(0xFFE8B48F),
        (AppAccent.ember, Brightness.light) => const Color(0xFF9C5B38),
        (AppAccent.honey, Brightness.dark) => const Color(0xFFF0C063),
        (AppAccent.honey, Brightness.light) => const Color(0xFF8A5E14),
        (AppAccent.rosewood, Brightness.dark) => const Color(0xFFE3A6A6),
        (AppAccent.rosewood, Brightness.light) => const Color(0xFF93484C),
        (AppAccent.crimson, Brightness.dark) => const Color(0xFFFFA9B7),
        (AppAccent.crimson, Brightness.light) => const Color(0xFFB4234E),
        (AppAccent.violet, Brightness.dark) => const Color(0xFFD4BBFF),
        (AppAccent.violet, Brightness.light) => const Color(0xFF6B4FC4),
        (AppAccent.indigo, Brightness.dark) => const Color(0xFFB9C6FF),
        (AppAccent.indigo, Brightness.light) => const Color(0xFF3F5BB5),
        (AppAccent.azure, Brightness.dark) => const Color(0xFF8FD4FF),
        (AppAccent.azure, Brightness.light) => const Color(0xFF1F6FB5),
        (AppAccent.teal, Brightness.dark) => const Color(0xFF6FDFD2),
        (AppAccent.teal, Brightness.light) => const Color(0xFF0F766E),
        (AppAccent.jade, Brightness.dark) => const Color(0xFF7FE3A8),
        (AppAccent.jade, Brightness.light) => const Color(0xFF1E7A44),
        (AppAccent.lime, Brightness.dark) => const Color(0xFFC6F16B),
        (AppAccent.lime, Brightness.light) => const Color(0xFF5A7A12),
        (AppAccent.amber, Brightness.dark) => const Color(0xFFFFC95C),
        (AppAccent.amber, Brightness.light) => const Color(0xFF9A6206),
        (AppAccent.slate, Brightness.dark) => const Color(0xFFB8C4D4),
        (AppAccent.slate, Brightness.light) => const Color(0xFF4A5A6E),
      };

  Color primaryContainer(Brightness b) => switch ((this, b)) {
        (AppAccent.ember, Brightness.dark) => const Color(0xFF6B3F24),
        (AppAccent.ember, Brightness.light) => const Color(0xFFFFDBCA),
        (AppAccent.honey, Brightness.dark) => const Color(0xFF5F430D),
        (AppAccent.honey, Brightness.light) => const Color(0xFFFFDF9E),
        (AppAccent.rosewood, Brightness.dark) => const Color(0xFF653336),
        (AppAccent.rosewood, Brightness.light) => const Color(0xFFFFDAD9),
        (AppAccent.crimson, Brightness.dark) => const Color(0xFF6E2337),
        (AppAccent.crimson, Brightness.light) => const Color(0xFFFFD9E0),
        (AppAccent.violet, Brightness.dark) => const Color(0xFF4A3A86),
        (AppAccent.violet, Brightness.light) => const Color(0xFFE6DEFF),
        (AppAccent.indigo, Brightness.dark) => const Color(0xFF2E3D7A),
        (AppAccent.indigo, Brightness.light) => const Color(0xFFDEE3FF),
        (AppAccent.azure, Brightness.dark) => const Color(0xFF174A75),
        (AppAccent.azure, Brightness.light) => const Color(0xFFD6EBFF),
        (AppAccent.teal, Brightness.dark) => const Color(0xFF0D4F4A),
        (AppAccent.teal, Brightness.light) => const Color(0xFFC8F5EE),
        (AppAccent.jade, Brightness.dark) => const Color(0xFF14532D),
        (AppAccent.jade, Brightness.light) => const Color(0xFFC9F2DA),
        (AppAccent.lime, Brightness.dark) => const Color(0xFF3D5210),
        (AppAccent.lime, Brightness.light) => const Color(0xFFE4F7BE),
        (AppAccent.amber, Brightness.dark) => const Color(0xFF6B4408),
        (AppAccent.amber, Brightness.light) => const Color(0xFFFFE7B8),
        (AppAccent.slate, Brightness.dark) => const Color(0xFF333E4D),
        (AppAccent.slate, Brightness.light) => const Color(0xFFDCE4EE),
      };
}

ColorScheme _darkScheme(AppAccent accent, {bool amoled = false}) {
  final primary = accent.primary(Brightness.dark);
  // Surfaces take a whisper of the accent color so the background matches
  // the chosen theme instead of staying warm-brown for every accent.
  // AMOLED black keeps pure-black surfaces: that's the point of the mode.
  Color tint(Color base) => Color.lerp(base, primary, 0.08)!;
  const surface = Color(0xFF141110);
  const surfaceLowest = Color(0xFF0E0C0A);
  const surfaceLow = Color(0xFF1B1713);
  const surfaceContainer = Color(0xFF1F1A15);
  const surfaceHigh = Color(0xFF2A231C);
  const surfaceHighest = Color(0xFF352C24);
  return ColorScheme.dark(
    primary: primary,
    onPrimary: const Color(0xFF3A2317),
    primaryContainer: accent.primaryContainer(Brightness.dark),
    onPrimaryContainer: const Color(0xFFFFE9D9),
    secondary: const Color(0xFFD7BEA4),
    onSecondary: const Color(0xFF3A2D20),
    secondaryContainer: const Color(0xFF4E4032),
    onSecondaryContainer: const Color(0xFFF5E6D3),
    tertiary: const Color(0xFFB9C8A9),
    onTertiary: const Color(0xFF25301F),
    tertiaryContainer: const Color(0xFF3C4634),
    onTertiaryContainer: const Color(0xFFDCE8CF),
    error: const Color(0xFFFFB4AB),
    surface: amoled ? Colors.black : tint(surface),
    onSurface: const Color(0xFFEDE4DA),
    surfaceContainerLowest: amoled ? Colors.black : tint(surfaceLowest),
    surfaceContainerLow: amoled ? const Color(0xFF0A0A0A) : tint(surfaceLow),
    surfaceContainer: amoled ? const Color(0xFF111111) : tint(surfaceContainer),
    surfaceContainerHigh: amoled ? const Color(0xFF181818) : tint(surfaceHigh),
    surfaceContainerHighest:
        amoled ? const Color(0xFF1F1F1F) : tint(surfaceHighest),
    onSurfaceVariant: const Color(0xFFCBB9A6),
    outline: const Color(0xFF52453A),
    outlineVariant: const Color(0xFF3A3129),
  );
}

ColorScheme _lightScheme(AppAccent accent) {
  final primary = accent.primary(Brightness.light);
  // Same accent whisper as dark mode, so the background matches the theme.
  Color tint(Color base) => Color.lerp(base, primary, 0.07)!;
  return ColorScheme.light(
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: accent.primaryContainer(Brightness.light),
    onPrimaryContainer: const Color(0xFF3A2317),
    secondary: const Color(0xFF7A5F45),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFF0E2CF),
    onSecondaryContainer: const Color(0xFF3A2D20),
    tertiary: const Color(0xFF5D6B4F),
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFDCE8CF),
    onTertiaryContainer: const Color(0xFF25301F),
    surface: tint(const Color(0xFFFAF5EF)),
    onSurface: const Color(0xFF201A14),
    surfaceContainerLowest: tint(Colors.white),
    surfaceContainerLow: tint(const Color(0xFFF3EDE4)),
    surfaceContainer: tint(const Color(0xFFEDE6DA)),
    surfaceContainerHigh: tint(const Color(0xFFE7DFD2)),
    surfaceContainerHighest: tint(const Color(0xFFE1D8C8)),
    onSurfaceVariant: const Color(0xFF5C4F42),
    outline: const Color(0xFF8A7A68),
    outlineVariant: const Color(0xFFD8CBB8),
  );
}

/// Semantic list-status colors, tuned per brightness from the accent
/// family's own tones (jade/azure/honey/crimson/slate) so they sit well on
/// the warm palette instead of using raw Material primaries.
///
/// [status] is a MAL list status like 'watching', 'completed', 'on_hold',
/// 'dropped', 'plan_to_watch' (or the manga equivalents).
Color statusColorFor(Brightness brightness, String status) {
  final dark = brightness == Brightness.dark;
  return switch (status) {
    'watching' || 'reading' =>
      dark ? const Color(0xFF7FE3A8) : const Color(0xFF1E7A44),
    'completed' => dark ? const Color(0xFF8FD4FF) : const Color(0xFF1F6FB5),
    'on_hold' => dark ? const Color(0xFFF0C063) : const Color(0xFF8A5E14),
    'dropped' => dark ? const Color(0xFFFFA9B7) : const Color(0xFFB4234E),
    _ => dark ? const Color(0xFFB8C4D4) : const Color(0xFF4A5A6E),
  };
}

/// The app's background surface for an accent + brightness, using the same
/// accent tint as the scheme. Used for surfaces outside the Material theme,
/// like the system navigation bar.
Color appSurface(AppAccent accent, Brightness brightness,
    {bool amoled = false}) {
  if (brightness == Brightness.dark && amoled) return Colors.black;
  final primary = accent.primary(brightness);
  final base = brightness == Brightness.dark
      ? const Color(0xFF141110)
      : const Color(0xFFFAF5EF);
  return Color.lerp(base, primary, brightness == Brightness.dark ? 0.08 : 0.07)!;
}

/// Builds the app [ThemeData]: Material 3 with a custom warm [ColorScheme].
/// M3 components (NavigationBar, FilterChip, Card, SearchBar, FAB,
/// SegmentedButton, Switch, BottomSheet...) are skinned by the scheme.
///
/// [amoled] switches dark surfaces to pure black; [fontFamily] (a Google
/// Fonts family name, or null for the system font) restyles all text.
///
/// [dynamicScheme] is a Material You scheme from the OS (Android 12+). When
/// provided it replaces the warm custom scheme entirely; [amoled] still
/// forces pure-black surfaces on top of it.
ThemeData buildAppTheme(
  Brightness brightness,
  AppAccent accent, {
  bool amoled = false,
  String? fontFamily,
  ColorScheme? dynamicScheme,
}) {
  var scheme = brightness == Brightness.dark
      ? _darkScheme(accent, amoled: amoled)
      : _lightScheme(accent);
  if (dynamicScheme != null) {
    scheme = dynamicScheme;
    if (amoled && brightness == Brightness.dark) {
      scheme = scheme.copyWith(
        surface: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: const Color(0xFF0A0A0A),
        surfaceContainer: const Color(0xFF111111),
        surfaceContainerHigh: const Color(0xFF181818),
        surfaceContainerHighest: const Color(0xFF1F1F1F),
      );
    }
  }
  var theme = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        );
      }),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outline),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.zero,
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor:
          WidgetStatePropertyAll(scheme.surfaceContainerHighest),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      hintStyle: WidgetStatePropertyAll(
        TextStyle(color: scheme.onSurfaceVariant),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      scrolledUnderElevation: 0,
    ),
  );
  if (fontFamily != null) {
    theme = theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: fontFamily),
    );
  }
  return theme;
}
