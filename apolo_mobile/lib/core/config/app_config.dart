import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

class AppConfig {
  static const String appName = 'Apolo.ma';
  static const String appVersion = '1.0.0';
  static const String stagingBaseUrl = 'https://staging.apolo.ma/api/v1';
  static const String prodBaseUrl = 'https://apolo.ma/api/v1';

  // Official Apolo.ma Google OAuth Configuration (extracted from apolo.ma/auth/google)
  static const String googleClientId =
      '130661413276-vbif91ct12ojofmo2kejhjl71it1j4gd.apps.googleusercontent.com';
  static const String googleAuthUrl = 'https://apolo.ma/auth/google';
  static const String googleOAuthRedirectUri =
      'https://apolo.ma/auth/google/callback';

  // Default to production API; switchable to staging in Profile Settings
  static String currentBaseUrl = prodBaseUrl;

  // Typography Constants
  static const String fontTajawal = AppTypography.fontTajawal;
  static const String fontInter = AppTypography.fontInter;
  static const String fontPrimary = 'PlusJakartaSans';
  static const List<String> fontFallback = [
    'IBMPlexSansArabic',
    'PlusJakartaSans',
    'Inter',
    'Tajawal',
  ];

  // Apolo.ma Official Brand Identity + 2026 Unslop / Triply Neutral Ramp
  static const Color primary =
      Color(0xFFE31B23); // Official Brand Primary Red RGB(227, 27, 35)
  static const Color primaryDark = Color(0xFFC81018); // Deep Brand Red
  static const Color accent = Color(0xFFE31B23); // Primary Red CTA
  static const Color badgeBg =
      Color(0xFFFEECEE); // Soft Rose Tint for Icon Badges
  static const Color vipGold = Color(0xFFF59E0B); // Luxury Amber Gold for VIP
  static const Color success = Color(0xFF10B981); // Emerald Verified Green
  static const Color danger = Color(0xFFE31B23);
  static const Color bgLight = Colors.white; // Pure White #FFFFFF
  static const Color cardBg = Colors.white; // Pure White #FFFFFF
  static const Color surfaceGray =
      Color(0xFFF1F3F7); // Calm Neutral Pill/Input Fill
  static const Color borderGray =
      Color(0xFFE7EAF0); // Hairline Card/Input Border
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

  static ThemeData buildTheme(Locale locale, {TargetPlatform? platform}) {
    return AppTheme.light(locale, platform: platform);
  }
}

class AppStrings {
  final String lang;
  AppStrings(this.lang);

  bool get isAr => lang == 'ar';
  bool get isEn => lang == 'en';
  bool get isFr => lang == 'fr';

  String tr(String ar, String fr, [String? en]) {
    if (isAr) return ar;
    if (isEn && en != null) return en;
    return fr;
  }

  String get home => tr('الرئيسية', 'Accueil', 'Home');
  String get search => tr('استكشف', 'Explorer', 'Explore');
  String get postAd => tr('أضف إعلان', 'Publier', 'Post Ad');
  String get stores => tr('المتاجر', 'Boutiques', 'Stores');
  String get messages => tr('الرسائل', 'Messages', 'Messages');
  String get profile => tr('حسابي', 'Profil', 'Profile');
  String get categories => tr('تصفح الأقسام', 'Catégories', 'Categories');
  String get featuredAds =>
      tr('إعلانات VIP المميزة', 'Sélection VIP', 'VIP Ads');
  String get latestAds =>
      tr('أحدث العروض المختارة', 'Dernières annonces', 'Latest Ads');
  String get allCities =>
      tr('كل مدن المغرب', 'Toutes les villes', 'All Cities');
  String get allCategories =>
      tr('جميع الأقسام', 'Toutes les catégories', 'All Categories');
  String get login => tr('تسجيل الدخول', 'Se connecter', 'Login');
  String get register =>
      tr('إنشاء حساب جديد', 'Créer un compte', 'Create Account');
  String get logout => tr('تسجيل الخروج', 'Déconnexion', 'Logout');
  String get callSeller => tr('اتصال', 'Appeler', 'Call');
  String get whatsapp => tr('واتساب', 'WhatsApp', 'WhatsApp');
  String get chatInApp => tr('دردشة فورية', 'Discuter', 'Chat');
  String get boostAd => tr('تمييز الإعلان VIP', 'Booster VIP', 'Boost Ad');
  String get deleteAccount =>
      tr('حذف الحساب نهائياً', 'Supprimer le compte', 'Delete Account');
  String get reportAd =>
      tr('التبليغ عن الإعلان', 'Signaler l\'annonce', 'Report Ad');
  String get blockUser =>
      tr('حظر المستخدم', 'Bloquer l\'utilisateur', 'Block User');
  String get searchHint => tr(
        'ابحث عن سيارة، شقة، هاتف...',
        'Rechercher une voiture, appartement, téléphone...',
        'Search for a car, apartment, phone...',
      );
  String get noAdsFound => tr(
        'لا توجد إعلانات مطابقة لبحثك',
        'Aucune annonce trouvée',
        'No ads found matching your search',
      );
}
