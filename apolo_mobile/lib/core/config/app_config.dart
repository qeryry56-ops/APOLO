import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

class AppConfig {
  static const String appName = 'Apolo.ma';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
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

  /// Controls whether Apolo Premium (`99 MAD/mo` via Google Pay) and its
  /// exclusive Business + Verified entitlements are active.
  static bool enablePremiumAndBusinessTiers = true;

  /// Maximum free listings a `Personal` (`individual`) user can publish per day.
  static const int maxDailyFreeAds = 5;

  /// Official monthly Apolo Premium subscription price in Moroccan Dirhams (MAD).
  static const int monthlyPremiumPriceMad = 99;

  /// Strict verification check: `Business` mode and the blue `Verified` seal
  /// are exclusive to active `Apolo Premium` (`is_pro_plus == true`) subscribers.
  static bool isVerifiedEntity(Map<dynamic, dynamic>? entity) {
    if (!enablePremiumAndBusinessTiers || entity == null) return false;
    return entity['is_pro_plus'] == true;
  }

  /// Resolves the active API base URL. On Vercel Web (`*.vercel.app`), routes
  /// through same-origin Vercel rewrites (`/api/v1/*`) to avoid browser CORS blocks.
  static String get effectiveBaseUrl => resolveBaseUrl(currentBaseUrl);

  static String resolveBaseUrl(String rawBaseUrl) {
    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      if (host.endsWith('vercel.app')) {
        if (rawBaseUrl == stagingBaseUrl) {
          return '${Uri.base.origin}/apolo-staging-api';
        }
        if (rawBaseUrl == prodBaseUrl) {
          return '${Uri.base.origin}/api/v1';
        }
      }
    }
    return rawBaseUrl;
  }

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

  // Monochrome Black, White & Neutral Gray System (with Crimson reserved for key accents)
  static const Color primary = Color(0xFF0A0A0A); // Obsidian Black Primary
  static const Color primaryDark = Color(0xFF000000); // Pure Black
  static const Color accent = Color(0xFF262626); // Charcoal Neutral Accent
  static const Color brandRed =
      Color(0xFFE31B23); // Reserved Brand Crimson (hearts, VIP, destructive)
  static const Color badgeBg =
      Color(0xFFF3F4F6); // Soft Neutral Gray Badge Tint
  static const Color vipGold = Color(0xFFF59E0B); // Luxury Amber Gold for VIP
  static const Color success = Color(0xFF10B981); // Emerald Verified Green
  static const Color danger = Color(0xFFE31B23);
  static const Color bgLight = Color(0xFFF2F3F7); // Clean iOS Neutral Gray Canvas
  static const Color cardBg = Colors.white; // Pure White #FFFFFF
  static const Color surfaceGray =
      Color(0xFFF3F4F6); // Calm Neutral Pill/Input Fill
  static const Color borderGray =
      Color(0xFFE5E7EB); // Hairline Card/Input Border
  static const Color textPrimary = Color(0xFF0A0A0A); // Crisp Obsidian Ink
  static const Color textSecondary = Color(0xFF6B7280); // Balanced Neutral Gray

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
