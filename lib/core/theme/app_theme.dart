import 'package:flutter/material.dart';

class AppTheme {
  // Centralized TextStyles for Quran and UI text
  static TextStyle get quranTextStyle {
    return const TextStyle(
      fontFamily: 'QuranUthmani',
      fontSize: 26,
      height: 2.0,
      locale: Locale('ar'),
    );
  }

  static TextStyle get uiTextStyle {
    return const TextStyle(fontFamily: 'Noto Sans Arabic');
  }

  // ── FIX: Corrected color palette ─────────────────────────────────────────
  // Primary: Deep Emerald Teal
  static const Color primaryEmerald = Color(0xFF00695C);
  // FIX: accentGold was Color.fromARGB(255,0,0,0) — pure black! Now real gold.
  static const Color accentGold = Color(0xFFFFB300); // Amber Gold

  static const Color darkBackground = Color.fromARGB(255, 27, 31, 30);
  static const Color darkSurface = Color(0xFF182221);
  static const Color darkCard = Color(0xFF1E2B2A);

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'Noto Sans Arabic'),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryEmerald,
        primary: primaryEmerald,
        // FIX: secondary was Color.fromARGB(255,0,0,0) — pure black! Now gold.
        secondary: accentGold,
        brightness: Brightness.light,
        surfaceTint: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: Color(0xFFF4F7F6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 2,
        backgroundColor: Colors.white,
        // FIX: indicatorColor was Color.fromARGB(255,105,0,0) — dark red!
        // Now uses the correct emerald primary color.
        indicatorColor: primaryEmerald.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: primaryEmerald,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryEmerald,
        inactiveTrackColor: primaryEmerald.withValues(alpha: 0.2),
        thumbColor: primaryEmerald,
        overlayColor: primaryEmerald.withValues(alpha: 0.12),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'Noto Sans Arabic'),
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryEmerald,
        primary: const Color(0xFF26A69A),
        // FIX: secondary was Color.fromARGB(255,0,0,0) — pure black! Now gold.
        secondary: accentGold,
        surface: darkSurface,
        brightness: Brightness.dark,
        surfaceTint: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: darkCard,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 2,
        backgroundColor: darkSurface,
        indicatorColor: const Color(0xFF26A69A).withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Color(0xFFE0F2F1),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Color(0xFFE0F2F1)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF26A69A),
        inactiveTrackColor: const Color(0xFF26A69A).withValues(alpha: 0.2),
        thumbColor: const Color(0xFF26A69A),
        overlayColor: const Color(0xFF26A69A).withValues(alpha: 0.12),
      ),
    );
  }
}
