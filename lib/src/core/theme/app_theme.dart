import 'package:flutter/material.dart';

/// Warm accent choices. "Ember" is the default DailyAL-"Fall"-like look.
enum AppAccent { ember, honey, rosewood }

extension AppAccentX on AppAccent {
  String get label => switch (this) {
        AppAccent.ember => 'Ember',
        AppAccent.honey => 'Honey',
        AppAccent.rosewood => 'Rosewood',
      };

  /// Primary color per brightness.
  Color primary(Brightness b) => switch ((this, b)) {
        (AppAccent.ember, Brightness.dark) => const Color(0xFFE8B48F),
        (AppAccent.ember, Brightness.light) => const Color(0xFF9C5B38),
        (AppAccent.honey, Brightness.dark) => const Color(0xFFF0C063),
        (AppAccent.honey, Brightness.light) => const Color(0xFF8A5E14),
        (AppAccent.rosewood, Brightness.dark) => const Color(0xFFE3A6A6),
        (AppAccent.rosewood, Brightness.light) => const Color(0xFF93484C),
      };

  Color primaryContainer(Brightness b) => switch ((this, b)) {
        (AppAccent.ember, Brightness.dark) => const Color(0xFF6B3F24),
        (AppAccent.ember, Brightness.light) => const Color(0xFFFFDBCA),
        (AppAccent.honey, Brightness.dark) => const Color(0xFF5F430D),
        (AppAccent.honey, Brightness.light) => const Color(0xFFFFDF9E),
        (AppAccent.rosewood, Brightness.dark) => const Color(0xFF653336),
        (AppAccent.rosewood, Brightness.light) => const Color(0xFFFFDAD9),
      };
}

ColorScheme _darkScheme(AppAccent accent) {
  final primary = accent.primary(Brightness.dark);
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
    surface: const Color(0xFF141110),
    onSurface: const Color(0xFFEDE4DA),
    surfaceContainerLowest: const Color(0xFF0E0C0A),
    surfaceContainerLow: const Color(0xFF1B1713),
    surfaceContainer: const Color(0xFF1F1A15),
    surfaceContainerHigh: const Color(0xFF2A231C),
    surfaceContainerHighest: const Color(0xFF352C24),
    onSurfaceVariant: const Color(0xFFCBB9A6),
    outline: const Color(0xFF52453A),
    outlineVariant: const Color(0xFF3A3129),
  );
}

ColorScheme _lightScheme(AppAccent accent) {
  final primary = accent.primary(Brightness.light);
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
    surface: const Color(0xFFFAF5EF),
    onSurface: const Color(0xFF201A14),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF3EDE4),
    surfaceContainer: const Color(0xFFEDE6DA),
    surfaceContainerHigh: const Color(0xFFE7DFD2),
    surfaceContainerHighest: const Color(0xFFE1D8C8),
    onSurfaceVariant: const Color(0xFF5C4F42),
    outline: const Color(0xFF8A7A68),
    outlineVariant: const Color(0xFFD8CBB8),
  );
}

/// Builds the app [ThemeData]: Material 3 with a custom warm [ColorScheme].
/// M3 components (NavigationBar, FilterChip, Card, SearchBar, FAB,
/// SegmentedButton, Switch, BottomSheet...) are skinned by the scheme.
ThemeData buildAppTheme(Brightness brightness, AppAccent accent) {
  final scheme =
      brightness == Brightness.dark ? _darkScheme(accent) : _lightScheme(accent);
  return ThemeData(
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
}
