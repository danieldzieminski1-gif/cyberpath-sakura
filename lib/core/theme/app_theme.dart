import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Twilight Sakura design tokens.
class Sakura {
  static const Color midnight = Color(0xFF161528);
  static const Color midnightHi = Color(0xFF221F3F);
  static const Color pink = Color(0xFFFFB7C5);
  static const Color peach = Color(0xFFFFDAC1);
  static const Color cream = Color(0xFFFFF5F6);
  static const Color lavender = Color(0xFFD8B4FE);

  static const double radius = 22;

  /// Dusk sky: midnight into lavender haze into a sakura horizon glow.
  static const LinearGradient duskGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF161528), Color(0xFF2A2152), Color(0xFF4A2C5E), Color(0xFF7A3F66)],
    stops: [0.0, 0.45, 0.78, 1.0],
  );

  /// Golden hour for light mode.
  static const LinearGradient goldenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF5F6), Color(0xFFFFE6EC), Color(0xFFFFDAC1)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient glowGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [pink, lavender],
  );
}

class AppTheme {
  /// Kept for backwards compatibility with older code.
  static const Color accent = Sakura.pink;

  /// Web fonts are skipped under `flutter test` (no network, avoids font-load noise).
  static bool get _useWebFonts {
    try {
      return !Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return true;
    }
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: Sakura.pink, brightness: Brightness.dark).copyWith(
      primary: Sakura.pink,
      onPrimary: Sakura.midnight,
      secondary: Sakura.lavender,
      onSecondary: Sakura.midnight,
      tertiary: Sakura.peach,
      surface: Sakura.midnight,
      onSurface: Sakura.cream,
      surfaceContainerHigh: Sakura.midnightHi,
      outlineVariant: Sakura.pink.withAlpha(90),
    );
    return _build(scheme);
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: Sakura.pink, brightness: Brightness.light).copyWith(
      primary: const Color(0xFFD6537A),
      onPrimary: Colors.white,
      secondary: const Color(0xFF8E5BD0),
      tertiary: const Color(0xFFE59A6B),
      surface: Sakura.cream,
      onSurface: const Color(0xFF2B2140),
      surfaceContainerHigh: Colors.white,
      outlineVariant: Sakura.pink,
    );
    return _build(scheme);
  }

  static TextTheme _text(TextTheme base, Color color) {
    final themed = base.apply(bodyColor: color, displayColor: color);
    if (!_useWebFonts) return themed;
    try {
      final body = GoogleFonts.poppinsTextTheme(themed);
      TextStyle? head(TextStyle? s) => s == null ? null : GoogleFonts.quicksand(textStyle: s, fontWeight: FontWeight.w700);
      return body.copyWith(
        displayLarge: head(body.displayLarge),
        displayMedium: head(body.displayMedium),
        displaySmall: head(body.displaySmall),
        headlineLarge: head(body.headlineLarge),
        headlineMedium: head(body.headlineMedium),
        headlineSmall: head(body.headlineSmall),
        titleLarge: head(body.titleLarge),
        titleMedium: head(body.titleMedium),
        titleSmall: head(body.titleSmall),
      );
    } catch (_) {
      return themed;
    }
  }

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: scheme.brightness);
    final text = _text(base.textTheme, scheme.onSurface);
    final r = BorderRadius.circular(Sakura.radius);
    final dark = scheme.brightness == Brightness.dark;
    return base.copyWith(
      textTheme: text,
      // Transparent so the gradient backdrop (see AnimeBackdrop) shows through every screen.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primary.withAlpha(60),
        height: 70,
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? Sakura.midnightHi : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: r, side: BorderSide(color: scheme.primary.withAlpha(120))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? Sakura.midnightHi : const Color(0xFF2B2140),
        contentTextStyle: text.bodyMedium?.copyWith(color: Sakura.cream),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withAlpha(40),
        linearMinHeight: 8,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withAlpha(150)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.primary.withAlpha(20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: scheme.primary.withAlpha(120))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: scheme.primary.withAlpha(90))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: scheme.primary, width: 1.6)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: scheme.primary.withAlpha(110)),
      ),
    );
  }
}
