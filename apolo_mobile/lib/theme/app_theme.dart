import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import 'app_typography.dart';

/// Centralized theme builder for Apolo.ma with dynamic typography integration
class AppTheme {
  AppTheme._();

  static ThemeData light(
    Locale locale, {
    TargetPlatform? platform,
  }) {
    final family = AppTypography.resolveFontFamily(locale, platform: platform);
    final fallback =
        AppTypography.resolveFontFamilyFallback(locale, platform: platform);
    final textTheme = AppTypography.buildTextTheme(
      locale,
      platform: platform,
      bodyColor: AppConfig.textPrimary,
      displayColor: AppConfig.textPrimary,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppConfig.primary,
      primary: AppConfig.primary,
      secondary: AppConfig.accent,
      surface: AppConfig.cardBg,
      brightness: Brightness.light,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      platform: platform,
      fontFamily: family,
      fontFamilyFallback: fallback,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppConfig.bgLight,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
    );

    final isArabic = locale.languageCode == 'ar';

    return baseTheme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppConfig.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppConfig.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: isArabic ? 0.0 : -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppConfig.borderGray),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConfig.surfaceGray,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppConfig.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppConfig.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppConfig.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppConfig.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppConfig.primary, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConfig.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: isArabic ? 0.0 : -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConfig.primary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          side: const BorderSide(color: AppConfig.borderGray, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: isArabic ? 0.0 : -0.2,
          ),
        ),
      ),
    );
  }

  static ThemeData dark(
    Locale locale, {
    TargetPlatform? platform,
  }) {
    final family = AppTypography.resolveFontFamily(locale, platform: platform);
    final fallback =
        AppTypography.resolveFontFamilyFallback(locale, platform: platform);
    const darkBg = Color(0xFF0F172A);
    const darkSurface = Color(0xFF1E293B);
    const darkBorder = Color(0xFF334155);
    const darkTextPrimary = Colors.white;
    const darkTextSecondary = Color(0xFF94A3B8);

    final textTheme = AppTypography.buildTextTheme(
      locale,
      platform: platform,
      bodyColor: darkTextPrimary,
      displayColor: darkTextPrimary,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppConfig.primary,
      primary: AppConfig.primary,
      secondary: AppConfig.accent,
      surface: darkSurface,
      brightness: Brightness.dark,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      platform: platform,
      fontFamily: family,
      fontFamilyFallback: fallback,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBg,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
    );

    final isArabic = locale.languageCode == 'ar';

    return baseTheme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: darkTextPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: isArabic ? 0.0 : -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF162032),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: darkTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: darkTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppConfig.primary, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConfig.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: isArabic ? 0.0 : -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          side: const BorderSide(color: darkBorder, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: isArabic ? 0.0 : -0.2,
          ),
        ),
      ),
    );
  }
}
