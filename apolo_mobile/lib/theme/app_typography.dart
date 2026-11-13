import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized, production-ready typography system for Apolo.ma
///
/// Multi-platform & multilingual font strategy:
/// - iOS (iPhone / iPad / macOS):
///     Uses the native Apple System Font (.SF Pro / .SF Arabic) via [fontFamily: null].
///     Never bundles SF Pro or SF Arabic font files, and avoids hardcoded Apple font family names
///     so that the OS dynamically handles glyph shaping, diacritics, and native fallback.
/// - Android (and other non-Apple platforms):
///     - Arabic ('ar'): Google Fonts Tajawal (bundled locally for 100% offline reliability).
///     - English ('en') & French ('fr'): Google Fonts Inter (bundled locally for offline reliability).
class AppTypography {
  AppTypography._();

  // Bundled font family constants for Android / non-Apple targets
  static const String fontTajawal = 'Tajawal';
  static const String fontInter = 'Inter';

  // Fallbacks if any glyph is missing
  static const List<String> androidArabicFallbacks = [
    'Tajawal',
    'IBMPlexSansArabic',
    'Inter',
    'PlusJakartaSans',
  ];

  static const List<String> androidLatinFallbacks = [
    'Inter',
    'PlusJakartaSans',
    'Tajawal',
    'IBMPlexSansArabic',
  ];

  /// Resolves the font family for the given [locale] and [platform].
  ///
  /// Returns `null` on iOS/macOS to ensure native Apple System Font is selected by the OS.
  /// On Android and other platforms, returns 'Tajawal' for Arabic and 'Inter' for Latin scripts.
  static String? resolveFontFamily(
    Locale locale, {
    TargetPlatform? platform,
  }) {
    final effectivePlatform = platform ?? defaultTargetPlatform;
    final isApplePlatform = effectivePlatform == TargetPlatform.iOS ||
        effectivePlatform == TargetPlatform.macOS;

    if (isApplePlatform) {
      // Let iOS automatically pick the native Apple System Font (.SF Pro / .SF Arabic)
      return null;
    }

    final isArabic = locale.languageCode == 'ar';
    return isArabic ? fontTajawal : fontInter;
  }

  /// Resolves font fallback list depending on platform and locale
  static List<String>? resolveFontFamilyFallback(
    Locale locale, {
    TargetPlatform? platform,
  }) {
    final effectivePlatform = platform ?? defaultTargetPlatform;
    final isApplePlatform = effectivePlatform == TargetPlatform.iOS ||
        effectivePlatform == TargetPlatform.macOS;

    if (isApplePlatform) {
      return null;
    }

    return locale.languageCode == 'ar'
        ? androidArabicFallbacks
        : androidLatinFallbacks;
  }

  /// Builds a complete Material 3 [TextTheme] strictly conforming to the
  /// typography design specifications.
  static TextTheme buildTextTheme(
    Locale locale, {
    TargetPlatform? platform,
    Color? bodyColor,
    Color? displayColor,
  }) {
    final family = resolveFontFamily(locale, platform: platform);
    final fallback = resolveFontFamilyFallback(locale, platform: platform);
    final isArabic = locale.languageCode == 'ar';

    // Metrics tuning:
    // Arabic requires comfortable line-height (1.45–1.6) and NEVER negative letter spacing.
    // English/French use tighter metrics (1.2–1.35) and slight negative letter spacing on headings.
    final double bodyLineHeight = isArabic ? 1.50 : 1.35;
    final double headingLineHeight = isArabic ? 1.35 : 1.20;
    final double titleLineHeight = isArabic ? 1.40 : 1.25;

    final double displaySpacing = isArabic ? 0.0 : -0.5;
    final double headingSpacing = isArabic ? 0.0 : -0.3;
    final double titleSpacing = isArabic ? 0.0 : -0.2;
    const double bodySpacing = 0.0;
    final double labelSpacing = isArabic ? 0.0 : 0.1;

    TextStyle createStyle({
      required double fontSize,
      required FontWeight fontWeight,
      required double height,
      required double letterSpacing,
      Color? color,
      List<FontFeature>? fontFeatures,
    }) {
      return TextStyle(
        fontFamily: family,
        fontFamilyFallback: fallback,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        color: color ?? bodyColor,
        fontFeatures: fontFeatures,
      );
    }

    return TextTheme(
      // Main display / Prominent amount (68–72, w700)
      displayLarge: createStyle(
        fontSize: 68,
        fontWeight: FontWeight.w700,
        height: headingLineHeight,
        letterSpacing: displaySpacing,
        color: displayColor,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      displayMedium: createStyle(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        height: headingLineHeight,
        letterSpacing: displaySpacing,
        color: displayColor,
      ),
      displaySmall: createStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        height: headingLineHeight,
        letterSpacing: headingSpacing,
        color: displayColor,
      ),

      // Large screen heading (30, w600–700)
      headlineLarge: createStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: headingLineHeight,
        letterSpacing: headingSpacing,
        color: displayColor,
      ),
      // Section heading (24, w600)
      headlineMedium: createStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: headingLineHeight,
        letterSpacing: headingSpacing,
        color: displayColor,
      ),
      headlineSmall: createStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: headingLineHeight,
        letterSpacing: headingSpacing,
        color: displayColor,
      ),

      // Medium title (20, w600)
      titleLarge: createStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: titleLineHeight,
        letterSpacing: titleSpacing,
        color: displayColor,
      ),
      // Buttons / Medium Subtitles (17–18, w600)
      titleMedium: createStyle(
        fontSize: 17.5,
        fontWeight: FontWeight.w600,
        height: titleLineHeight,
        letterSpacing: titleSpacing,
        color: displayColor,
      ),
      titleSmall: createStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: titleLineHeight,
        letterSpacing: titleSpacing,
        color: displayColor,
      ),

      // Primary body text (17, w400)
      bodyLarge: createStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: bodyLineHeight,
        letterSpacing: bodySpacing,
        color: bodyColor,
      ),
      // Secondary body text (15, w400)
      bodyMedium: createStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: bodyLineHeight,
        letterSpacing: bodySpacing,
        color: bodyColor,
      ),
      bodySmall: createStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: bodyLineHeight,
        letterSpacing: bodySpacing,
        color: bodyColor,
      ),

      // Buttons (17–18, w600) & Labels
      labelLarge: createStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: labelSpacing,
        color: displayColor,
      ),
      // Small labels (13–14, w400–500)
      labelMedium: createStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        height: 1.25,
        letterSpacing: labelSpacing,
        color: bodyColor,
      ),
      labelSmall: createStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.20,
        letterSpacing: labelSpacing,
        color: bodyColor,
      ),
    );
  }

  /// Specialized style for prominent financial / numerical amount figures (68–72, w700)
  /// with Tabular Figures enabled to prevent jitter when updating dynamic values.
  static TextStyle amountStyle({
    Locale? locale,
    TargetPlatform? platform,
    double size = 68,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) {
    final effectiveLocale = locale ?? const Locale('ar');
    final family = resolveFontFamily(effectiveLocale, platform: platform);
    final fallback =
        resolveFontFamilyFallback(effectiveLocale, platform: platform);
    final isArabic = effectiveLocale.languageCode == 'ar';

    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: fallback,
      fontSize: size,
      fontWeight: weight,
      height: isArabic ? 1.25 : 1.10,
      letterSpacing: isArabic ? 0.0 : -0.5,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Returns `true` when [locale] uses Arabic script.
  static bool isArabicLocale(Locale? locale) => locale?.languageCode == 'ar';

  /// Returns zero letter-spacing for Arabic to preserve connected glyphs,
  /// otherwise returns [latinValue].
  static double tracking(Locale? locale, double latinValue) =>
      isArabicLocale(locale) ? 0.0 : latinValue;

  /// Context-aware wrapper around [tracking].
  static double trackingForContext(BuildContext context, double latinValue) =>
      tracking(Localizations.maybeLocaleOf(context), latinValue);
}
