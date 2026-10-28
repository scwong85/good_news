import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Brand: a quiet sunrise. Fresh green for "constructive", warm cream surfaces, amber for the sun.
// All colours and type live here; widgets use the theme, not literals (docs/ui-overhaul.md).
const _seed = Color(0xFF2E7D5B);
const _lightSurface = Color(0xFFFFFBF3); // warm cream
const _lightCard = Color(0xFFFFFFFF);
const _darkSurface = Color(0xFF15191A); // warm charcoal
const _darkCard = Color(0xFF1E2423);

const headlineFamily = 'SourceSerif4';
const bodyFamily = 'NunitoSans';

/// A variable-font weight (falls back to the regular weight if the platform ignores variations).
TextStyle _w(TextStyle? s, double weight, {String? family}) => (s ?? const TextStyle()).copyWith(
      fontFamily: family,
      fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
      fontVariations: [FontVariation('wght', weight)],
    );

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: brightness,
    surface: dark ? _darkSurface : _lightSurface,
  ).copyWith(
    // The sun: used for warmth and highlights, with dark-on-light text pairs for contrast.
    tertiary: dark ? const Color(0xFFFFB454) : const Color(0xFF8A5100),
    onTertiary: dark ? const Color(0xFF3A2400) : Colors.white,
    tertiaryContainer: dark ? const Color(0xFF4A3000) : const Color(0xFFFFE7BF),
    onTertiaryContainer: dark ? const Color(0xFFFFDDA8) : const Color(0xFF3A2400),
    secondaryContainer: dark ? const Color(0xFF2B3A33) : const Color(0xFFE3F1E7),
    onSecondaryContainer: dark ? const Color(0xFFD5EBDD) : const Color(0xFF16352A),
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: brightness, fontFamily: bodyFamily);
  final t = base.textTheme;
  final textTheme = t.copyWith(
    displaySmall: _w(t.displaySmall, 600, family: headlineFamily),
    headlineLarge: _w(t.headlineLarge, 650, family: headlineFamily),
    headlineMedium: _w(t.headlineMedium, 650, family: headlineFamily),
    headlineSmall: _w(t.headlineSmall, 650, family: headlineFamily),
    titleLarge: _w(t.titleLarge, 650, family: headlineFamily),
    titleMedium: _w(t.titleMedium, 700),
    titleSmall: _w(t.titleSmall, 700),
    labelLarge: _w(t.labelLarge, 700),
    labelMedium: _w(t.labelMedium, 650),
  );
  final overlay = (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: scheme.surface,
  );
  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: overlay,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: dark ? _darkCard : _lightCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: dark ? 0.6 : 0.8)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.tertiaryContainer,
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: scheme.onSurface)),
    ),
    navigationRailTheme: NavigationRailThemeData(backgroundColor: scheme.surface, indicatorColor: scheme.tertiaryContainer),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    ),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
  );
}

extension StoryText on TextTheme {
  TextStyle get storyTitle => _w(titleMedium, 650, family: headlineFamily).copyWith(fontSize: 18, height: 1.28);
  TextStyle get leadTitle => _w(titleLarge, 700, family: headlineFamily).copyWith(fontSize: 24, height: 1.22);
  TextStyle get storyHeadline => _w(headlineSmall, 700, family: headlineFamily).copyWith(fontSize: 28, height: 1.2);
  TextStyle get pageTitle => _w(headlineMedium, 700, family: headlineFamily).copyWith(fontSize: 34, height: 1.1);
}
