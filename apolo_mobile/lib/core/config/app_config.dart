import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'Apolo.ma';
  static const String stagingBaseUrl = 'https://staging.apolo.ma/api/v1';
  static const String prodBaseUrl = 'https://apolo.ma/api/v1';

  // Default to production API; switchable to staging in Profile Settings
  static String currentBaseUrl = prodBaseUrl;

  // Ultra-Modern 2026 Startup Aesthetic Palette (Inspired by Roamly / Plately / Luma / DentaCare)
  static const Color primary = Color(0xFF2563EB); // Vibrant Ocean Royal Blue
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color accent = Color(0xFFFF6B4A); // Warm Coral-Orange CTA
  static const Color vipGold = Color(0xFFF59E0B); // Luxury Amber Gold
  static const Color success = Color(0xFF10B981); // Emerald Verified Green
  static const Color danger = Color(0xFFEF4444);
  static const Color bgLight = Color(0xFFFAFAF8); // Airy Editorial Off-White
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1F1F1F); // Deep Charcoal
  static const Color textSecondary = Color(0xFF8A8A8A); // Soft Editorial Gray

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
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: cardBg,
      ),
      scaffoldBackgroundColor: bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
