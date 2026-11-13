import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import 'app_typography.dart';

/// Centralized theme builder for Apolo.ma with dynamic typography integration
class AppTheme {
  AppTheme._();

  static ThemeData light(
    Locale locale, {
    TargetPlatform? platform,
  }) =>
      _buildTheme(
        locale,
        platform: platform,
        brightness: Brightness.light,
        scaffoldBg: AppConfig.bgLight,
        surfaceBg: AppConfig.cardBg,
        appBarBg: Colors.white,
        inputFillBg: AppConfig.surfaceGray,
        borderColor: AppConfig.borderGray,
        textPrimary: AppConfig.textPrimary,
        textSecondary: AppConfig.textSecondary,
        outlinedForeground: AppConfig.primary,
      );

  static ThemeData dark(
    Locale locale, {
    TargetPlatform? platform,
  }) =>
      _buildTheme(
        locale,
        platform: platform,
        brightness: Brightness.dark,
        scaffoldBg: const Color(0xFF0F172A),
        surfaceBg: const Color(0xFF1E293B),
        appBarBg: const Color(0xFF1E293B),
        inputFillBg: const Color(0xFF162032),
        borderColor: const Color(0xFF334155),
        textPrimary: Colors.white,
        textSecondary: const Color(0xFF94A3B8),
        outlinedForeground: Colors.white,
      );

  static ThemeData _buildTheme(
    Locale locale, {
    required TargetPlatform? platform,
    required Brightness brightness,
    required Color scaffoldBg,
    required Color surfaceBg,
    required Color appBarBg,
    required Color inputFillBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color outlinedForeground,
  }) {
    final family = AppTypography.resolveFontFamily(locale, platform: platform);
    final fallback =
        AppTypography.resolveFontFamilyFallback(locale, platform: platform);
    final textTheme = AppTypography.buildTextTheme(
      locale,
      platform: platform,
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppConfig.primary,
      primary: AppConfig.primary,
      secondary: AppConfig.accent,
      surface: surfaceBg,
      brightness: brightness,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      platform: platform,
      fontFamily: family,
      fontFamilyFallback: fallback,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
    );

    final isArabic = locale.languageCode == 'ar';
    final buttonTracking = isArabic ? 0.0 : -0.2;
    final primaryButtonText = textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 15,
      letterSpacing: buttonTracking,
    );

    return baseTheme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: isArabic ? 0.0 : -0.4,
        ),
        toolbarTextStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaceBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillBg,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: textSecondary,
          fontWeight: FontWeight.w600,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(color: textSecondary),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: AppConfig.danger,
          fontWeight: FontWeight.w500,
        ),
        prefixStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
        suffixStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
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
          textStyle: primaryButtonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppConfig.primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: primaryButtonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: outlinedForeground,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          side: BorderSide(color: borderColor, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: buttonTracking,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: buttonTracking,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppConfig.primary : textSecondary,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceBg,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceBg,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: textSecondary,
          fontSize: 13.5,
        ),
        leadingAndTrailingTextStyle: textTheme.labelMedium?.copyWith(
          color: textSecondary,
        ),
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        labelStyle: textTheme.labelMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceBg,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
      ),
    );
  }
}
