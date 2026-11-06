import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'Apolo.ma';
  static const String stagingBaseUrl = 'https://staging.apolo.ma/api/v1';
  static const String prodBaseUrl = 'https://apolo.ma/api/v1';

  // Official Apolo.ma Google OAuth Configuration (extracted from apolo.ma/auth/google)
  static const String googleClientId =
      '130661413276-vbif91ct12ojofmo2kejhjl71it1j4gd.apps.googleusercontent.com';
  static const String googleAuthUrl = 'https://apolo.ma/auth/google';
  static const String googleOAuthRedirectUri = 'https://apolo.ma/auth/google/callback';

  // Default to production API; switchable to staging in Profile Settings
  static String currentBaseUrl = prodBaseUrl;

  // 2026 UI/UX Typography Pairing:
  // Plus Jakarta Sans (Latin + Geometric Numerals) + IBM Plex Sans Arabic (Modern Arabic UI)
  static const String fontPrimary = 'PlusJakartaSans';
  static const List<String> fontFallback = ['IBMPlexSansArabic', 'PlusJakartaSans'];

  // Apolo.ma Official Brand Identity + 2026 Unslop / Triply Neutral Ramp
  static const Color primary = Color(0xFFE31B23); // Official Brand Primary Red RGB(227, 27, 35)
  static const Color primaryDark = Color(0xFFC81018); // Deep Brand Red
  static const Color accent = Color(0xFFE31B23); // Primary Red CTA
  static const Color badgeBg = Color(0xFFFEECEE); // Soft Rose Tint for Icon Badges
  static const Color vipGold = Color(0xFFF59E0B); // Luxury Amber Gold for VIP
  static const Color success = Color(0xFF10B981); // Emerald Verified Green
  static const Color danger = Color(0xFFE31B23);
  static const Color bgLight = Colors.white; // Pure White #FFFFFF
  static const Color cardBg = Colors.white; // Pure White #FFFFFF
  static const Color surfaceGray = Color(0xFFF1F3F7); // Calm Neutral Pill/Input Fill
  static const Color borderGray = Color(0xFFE7EAF0); // Hairline Card/Input Border
  static const Color textPrimary = Color(0xFF0F1B2D); // Deep Slate Ink
  static const Color textSecondary = Color(0xFF8A94A6); // Muted Neutral Gray

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.045),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static ThemeData buildTheme(Locale locale) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      fontFamily: fontPrimary,
      fontFamilyFallback: fontFallback,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: cardBg,
      ),
      scaffoldBackgroundColor: bgLight,
    );

    final textTheme = baseTheme.textTheme.apply(
      fontFamily: fontPrimary,
      fontFamilyFallback: fontFallback,
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return baseTheme.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontPrimary,
          fontFamilyFallback: fontFallback,
          color: textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderGray),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceGray,
        hintStyle: const TextStyle(
          fontFamily: fontPrimary,
          fontFamilyFallback: fontFallback,
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          fontFamily: fontPrimary,
          fontFamilyFallback: fontFallback,
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: fontPrimary,
            fontFamilyFallback: fontFallback,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          side: const BorderSide(color: borderGray, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: fontPrimary,
            fontFamilyFallback: fontFallback,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class AppStrings {
  final String lang;
  AppStrings(this.lang);

  bool get isAr => lang == 'ar';

  String tr(String ar, String fr) => isAr ? ar : fr;

  String get home => tr('الرئيسية', 'Accueil');
  String get search => tr('استكشف', 'Explorer');
  String get postAd => tr('أضف إعلان', 'Publier');
  String get stores => tr('المتاجر', 'Boutiques');
  String get messages => tr('الرسائل', 'Messages');
  String get profile => tr('حسابي', 'Profil');
  String get categories => tr('تصفح الأقسام', 'Catégories');
  String get featuredAds => tr('إعلانات VIP المميزة', 'Sélection VIP');
  String get latestAds => tr('أحدث العروض المختارة', 'Dernières annonces');
  String get allCities => tr('كل مدن المغرب', 'Toutes les villes');
  String get allCategories => tr('جميع الأقسام', 'Toutes les catégories');
  String get login => tr('تسجيل الدخول', 'Se connecter');
  String get register => tr('إنشاء حساب جديد', 'Créer un compte');
  String get logout => tr('تسجيل الخروج', 'Déconnexion');
  String get callSeller => tr('اتصال', 'Appeler');
  String get whatsapp => tr('واتساب', 'WhatsApp');
  String get chatInApp => tr('دردشة فورية', 'Discuter');
  String get boostAd => tr('تمييز الإعلان VIP', 'Booster VIP');
  String get deleteAccount => tr('حذف الحساب نهائياً', 'Supprimer le compte');
  String get reportAd => tr('التبليغ عن الإعلان', 'Signaler l\'annonce');
  String get blockUser => tr('حظر المستخدم', 'Bloquer l\'utilisateur');
}
