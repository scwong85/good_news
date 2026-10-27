import 'package:flutter/material.dart';

const _seed = Color(0xFF2F6B4F);
const _lightBackground = Color(0xFFFAF8F4);
const _darkBackground = Color(0xFF161A17);

/// Serif used for headlines, to give the app an editorial, unhurried feel.
const headlineFamily = 'serif';

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: brightness,
    surface: dark ? _darkBackground : _lightBackground,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: brightness);
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: dark ? const Color(0xFF1E2420) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
    ),
    chipTheme: base.chipTheme.copyWith(side: BorderSide(color: scheme.outlineVariant)),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

extension StoryText on TextTheme {
  TextStyle get storyTitle => titleMedium!.copyWith(fontFamily: headlineFamily, fontWeight: FontWeight.w700, height: 1.25);
  TextStyle get storyHeadline => headlineSmall!.copyWith(fontFamily: headlineFamily, fontWeight: FontWeight.w700, height: 1.25);
  TextStyle get pageTitle => headlineMedium!.copyWith(fontFamily: headlineFamily, fontWeight: FontWeight.w700);
}
