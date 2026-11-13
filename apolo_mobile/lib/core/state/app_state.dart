import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../config/app_config.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final ApiClient api = ApiClient();

  Locale _locale = const Locale('ar');
  Map<String, dynamic>? currentUser;
  List<dynamic> categories = [];
  List<dynamic> cities = [];
  Set<int> favoriteAdIds = {};
  int unreadNotificationsCount = 0;
  bool isInitialized = false;

  // Smart Personalization & Recommendation State (2026 Feed Engine)
  Map<int, int> categoryInterestWeights = {};
  int? preferredCityId;
  String accountType = 'individual'; // 'individual' | 'pro'

  Locale get locale => _locale;
  AppStrings get s => AppStrings(_locale.languageCode);
  bool get isLoggedIn => currentUser != null && api.isAuthenticated;

  bool get hasPersonalizedInterests => categoryInterestWeights.isNotEmpty;

  static const Set<String> supportedLanguageCodes = {'ar', 'fr', 'en'};

  static String _normalizeLanguageCode(String code) =>
      supportedLanguageCodes.contains(code) ? code : 'ar';

  Future<void> initialize({bool loadRemote = true}) async {
    await api.init();
    _locale = Locale(_normalizeLanguageCode(api.locale));
    await _loadPersonalizationPrefs();
    if (loadRemote) await refreshRemote();
    isInitialized = true;
    notifyListeners();
  }

  Future<void> refreshRemote() async {
    await Future.wait([fetchTaxonomy(), if (api.isAuthenticated) fetchMe()]);
  }

  int _sessionRevision = 0;

  Future<void> _loadPersonalizationPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      preferredCityId = prefs.getInt('apolo_preferred_city_id');
      accountType = prefs.getString('apolo_account_type') ?? 'individual';
      final rawWeights = prefs.getString('apolo_interest_weights');
      if (rawWeights != null && rawWeights.isNotEmpty) {
        final decoded = jsonDecode(rawWeights);
        if (decoded is Map) {
          categoryInterestWeights = {};
          decoded.forEach((k, v) {
            final id = int.tryParse(k.toString());
            final w = int.tryParse(v.toString());
            if (id != null && w != null && w > 0) {
              categoryInterestWeights[id] = w;
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _savePersonalizationPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (preferredCityId != null) {
        await prefs.setInt('apolo_preferred_city_id', preferredCityId!);
      }
      await prefs.setString('apolo_account_type', accountType);
      final encoded = jsonEncode(
        categoryInterestWeights.map((k, v) => MapEntry(k.toString(), v)),
      );
      await prefs.setString('apolo_interest_weights', encoded);
    } catch (_) {}
  }

  /// Records user interaction with a category (view = +2, search/filter = +3, favorite = +5, onboarding = +12)
  Future<void> recordCategoryInterest(int? categoryId, {int weight = 2}) async {
    if (categoryId == null || categoryId <= 0) return;
    categoryInterestWeights[categoryId] =
        (categoryInterestWeights[categoryId] ?? 0) + weight;
    await _savePersonalizationPrefs();
    notifyListeners();
  }

  Future<void> saveOnboardingPreferences({
    required String accType,
    int? cityId,
    required Set<int> selectedCategories,
  }) async {
    accountType = accType;
    if (cityId != null) preferredCityId = cityId;
    for (final catId in selectedCategories) {
      categoryInterestWeights[catId] =
          (categoryInterestWeights[catId] ?? 0) + 12;
    }
    await _savePersonalizationPrefs();
    notifyListeners();
  }

  /// Smart Feed Algorithm: Sorts ads based on user interest weights, preferred city, and engagement.
  List<Map<String, dynamic>> rankAdsForUser(List<dynamic> rawAds) {
    final list = rawAds
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (list.length <= 1) return list;

    int scoreForAd(Map<String, dynamic> ad) {
      int score = 0;
      final int? catId = extractAdCategoryId(ad);
      if (catId != null && categoryInterestWeights.containsKey(catId)) {
        score += (categoryInterestWeights[catId]! * 15);
      }
      final int? adCityId = int.tryParse(
        (ad['city_id'] ?? (ad['city'] is Map ? ad['city']['id'] : ''))
            .toString(),
      );
      if (preferredCityId != null && adCityId == preferredCityId) {
        score += 25;
      }
      if (ad['is_vip'] == true || ad['is_featured'] == true) {
        score += 18;
      }
      final views =
          int.tryParse((ad['views'] ?? ad['views_count'] ?? 0).toString()) ?? 0;
      score += (views > 100 ? 10 : views ~/ 10);
      return score;
    }

    list.sort((a, b) => scoreForAd(b).compareTo(scoreForAd(a)));
    return list;
  }

  /// Extracts normalized category ID from an ad object
  int? extractAdCategoryId(Map<dynamic, dynamic> ad) {
    final direct = int.tryParse((ad['category_id'] ?? '').toString());
    if (direct != null && direct > 0) return direct;
    if (ad['category'] is Map) {
      final nested = int.tryParse((ad['category']['id'] ?? '').toString());
      if (nested != null && nested > 0) return nested;
    }
    // Fallback: match by category name or slug against known categories
    final catName = (ad['category_name'] ??
            (ad['category'] is Map
                ? (ad['category']['name'] ??
                    ad['category']['name_ar'] ??
                    ad['category']['name_fr'])
                : ad['category']) ??
            '')
        .toString()
        .toLowerCase()
        .trim();
    if (catName.isNotEmpty) {
      for (final c in categories) {
        if (c is Map) {
          final id = int.tryParse((c['id'] ?? '').toString());
          final ar = (c['name_ar'] ?? '').toString().toLowerCase();
          final fr = (c['name_fr'] ?? '').toString().toLowerCase();
          final nm = (c['name'] ?? '').toString().toLowerCase();
          if (id != null &&
              (catName == ar ||
                  catName == fr ||
                  catName == nm ||
                  (ar.isNotEmpty && catName.contains(ar)) ||
                  (fr.isNotEmpty && catName.contains(fr)))) {
            return id;
          }
        }
      }
    }
    return null;
  }

  /// Strict & smart check whether an ad belongs to the selected category
  bool adMatchesCategory(Map<dynamic, dynamic> ad, int? targetCategoryId) {
    if (targetCategoryId == null) return true;
    final adCatId = extractAdCategoryId(ad);
    if (adCatId != null && adCatId == targetCategoryId) return true;

    // Also check by category asset family if IDs differ between environments
    final targetCat = categories.whereType<Map>().firstWhere(
          (c) => int.tryParse((c['id'] ?? '').toString()) == targetCategoryId,
          orElse: () => const {},
        );
    if (targetCat.isNotEmpty) {
      final targetAsset = assetForCategory(targetCat);
      final adCatMap = ad['category'] is Map
          ? ad['category'] as Map
          : {'name': ad['category_name'] ?? ad['category'] ?? ''};
      final adAsset = assetForCategory(
        adCatMap,
        (ad['category_name'] ?? '').toString(),
      );
      if (adAsset == targetAsset && adAsset != 'assets/images/cat_other.png') {
        return true;
      }
    }
    return false;
  }

  /// Returns a clean, balanced, non-overflowing category label in Arabic, French, or English
  String formatCategoryLabel(Map<dynamic, dynamic> cat) {
    final lang = _locale.languageCode;
    final isAr = lang == 'ar';
    final isEn = lang == 'en';
    final raw = (isAr
            ? (cat['name_ar'] ?? cat['name'] ?? '')
            : (isEn
                ? (cat['name_en'] ?? cat['name'] ?? cat['name_fr'] ?? '')
                : (cat['name_fr'] ?? cat['name'] ?? '')))
        .toString()
        .trim();
    final combined =
        '${raw.toLowerCase()} ${(cat['slug'] ?? '').toString().toLowerCase()} ${(cat['name_fr'] ?? '').toString().toLowerCase()} ${(cat['name_ar'] ?? '').toString().toLowerCase()}';

    if (combined.contains('voiture') ||
        combined.contains('vehicule') ||
        combined.contains('véhicule') ||
        combined.contains('auto') ||
        combined.contains('نقل') ||
        combined.contains('سيار')) {
      return isAr ? 'وسائل النقل' : (isEn ? 'Vehicles' : 'Véhicules');
    }
    if (combined.contains('immo') || combined.contains('عقار')) {
      return isAr ? 'عقارات' : (isEn ? 'Real Estate' : 'Immobilier');
    }
    if (combined.contains('télé') ||
        combined.contains('phone') ||
        combined.contains('هواتف')) {
      return isAr ? 'هواتف وتقنية' : (isEn ? 'Phones' : 'Téléphones');
    }
    if (combined.contains('info') ||
        combined.contains('multimedia') ||
        combined.contains('معلوماتية') ||
        combined.contains('حواسيب')) {
      return isAr ? 'إعلاميات وتقنية' : (isEn ? 'Computers' : 'Informatique');
    }
    if (combined.contains('habillement') ||
        combined.contains('mode') ||
        combined.contains('ملابس') ||
        combined.contains('أزياء')) {
      return isAr
          ? 'أزياء وجمال'
          : (isEn ? 'Fashion & Beauty' : 'Mode & Beauté');
    }
    if (combined.contains('voyage') || combined.contains('سفر')) {
      return isAr ? 'أدوات السفر' : (isEn ? 'Travel' : 'Voyage');
    }
    if (combined.contains('parapharmacie') ||
        combined.contains('بارافارماسي')) {
      return isAr ? 'بارافارماسي' : (isEn ? 'Parapharmacy' : 'Parapharmacie');
    }
    if (combined.contains('enfant') ||
        combined.contains('اطفال') ||
        combined.contains('أطفال')) {
      return isAr ? 'الأطفال' : (isEn ? 'Kids & Baby' : 'Enfants');
    }
    if (combined.contains('bricolage') || combined.contains('بريكولاج')) {
      return isAr ? 'بريكولاج' : (isEn ? 'DIY & Tools' : 'Bricolage');
    }
    if (combined.contains('industriel') ||
        combined.contains('machine') ||
        combined.contains('صناعية') ||
        combined.contains('ألات') ||
        combined.contains('آلات')) {
      return isAr
          ? 'آلات صناعية'
          : (isEn ? 'Industrial & Pro' : 'Industrie & Pro');
    }
    if (combined.contains('bijou') || combined.contains('مجوهرات')) {
      return isAr ? 'المجوهرات' : (isEn ? 'Jewelry' : 'Bijoux');
    }
    if (combined.contains('antique') || combined.contains('عتيقة')) {
      return isAr ? 'تحف وأنتيك' : (isEn ? 'Antiques' : 'Antiquités');
    }
    if (combined.contains('maison') ||
        combined.contains('meuble') ||
        combined.contains('أثاث')) {
      return isAr
          ? 'أثاث وديكور'
          : (isEn ? 'Home & Furniture' : 'Maison & Déco');
    }
    if (combined.contains('emploi') ||
        combined.contains('service') ||
        combined.contains('وظائف')) {
      return isAr
          ? 'وظائف وخدمات'
          : (isEn ? 'Jobs & Services' : 'Emploi & Pro');
    }
    if (combined.contains('autre') || combined.contains('آخر')) {
      return isAr ? 'أقسام أخرى' : (isEn ? 'Other' : 'Autres');
    }
    return raw;
  }

  /// Centralized 12+ category global-brand cutout asset resolver
  String assetForCategory(Map<dynamic, dynamic>? cat,
      [String fallbackName = '']) {
    if (cat != null &&
        cat['asset'] is String &&
        (cat['asset'] as String).isNotEmpty) {
      return cat['asset'] as String;
    }
    final combined =
        '${fallbackName.toLowerCase()} ${(cat?['name_ar'] ?? '').toString().toLowerCase()} ${(cat?['name_fr'] ?? '').toString().toLowerCase()} ${(cat?['name'] ?? '').toString().toLowerCase()} ${(cat?['slug'] ?? '').toString().toLowerCase()}';

    if (combined.contains('voiture') ||
        combined.contains('auto') ||
        combined.contains('moto') ||
        combined.contains('vehicule') ||
        combined.contains('véhicule') ||
        combined.contains('نقل') ||
        combined.contains('سيار') ||
        combined.contains('مركبات')) {
      return 'assets/images/cat_vehicles.png';
    }
    if (combined.contains('immo') ||
        combined.contains('appart') ||
        combined.contains('villa') ||
        combined.contains('عقار') ||
        combined.contains('شقق')) {
      return 'assets/images/cat_realestate.png';
    }
    if (combined.contains('voyage') || combined.contains('سفر')) {
      return 'assets/images/cat_travel.png';
    }
    if (combined.contains('parapharmacie') ||
        combined.contains('بارافارماسي')) {
      return 'assets/images/cat_parapharmacy.png';
    }
    if (combined.contains('enfant') ||
        combined.contains('اطفال') ||
        combined.contains('أطفال')) {
      return 'assets/images/cat_kids.png';
    }
    if (combined.contains('bricolage') || combined.contains('بريكولاج')) {
      return 'assets/images/cat_bricolage.png';
    }
    if (combined.contains('industriel') ||
        combined.contains('machine') ||
        combined.contains('صناعية') ||
        combined.contains('ألات') ||
        combined.contains('آلات')) {
      return 'assets/images/cat_industrial.png';
    }
    if (combined.contains('bijou') || combined.contains('مجوهرات')) {
      return 'assets/images/cat_jewelry.png';
    }
    if (combined.contains('antique') || combined.contains('عتيقة')) {
      return 'assets/images/cat_antique.png';
    }
    if (combined.contains('autre') || combined.contains('آخر')) {
      return 'assets/images/cat_other.png';
    }
    if (combined.contains('télé') ||
        combined.contains('phone') ||
        combined.contains('هواتف')) {
      return 'assets/images/cat_phones.png';
    }
    if (combined.contains('info') ||
        combined.contains('multimedia') ||
        combined.contains('pc') ||
        combined.contains('معلوماتية') ||
        combined.contains('وسائط') ||
        combined.contains('حواسيب') ||
        combined.contains('إلكترون')) {
      return 'assets/images/cat_computers.png';
    }
    if (combined.contains('maison') ||
        combined.contains('meuble') ||
        combined.contains('أثاث') ||
        combined.contains('منزل')) {
      return 'assets/images/cat_home.png';
    }
    if (combined.contains('mode') ||
        combined.contains('habillement') ||
        combined.contains('vêt') ||
        combined.contains('أزياء') ||
        combined.contains('ملابس')) {
      return 'assets/images/cat_fashion.png';
    }
    if (combined.contains('emploi') ||
        combined.contains('service') ||
        combined.contains('وظائف') ||
        combined.contains('خدمات')) {
      return 'assets/images/cat_jobs.png';
    }
    return 'assets/images/cat_other.png';
  }

  Future<void> setLocale(Locale newLocale) async {
    final normalized = _normalizeLanguageCode(newLocale.languageCode);
    _locale = Locale(normalized);
    await api.setLocale(normalized);
    notifyListeners();
    await fetchTaxonomy();
  }

  Future<void> toggleLanguage() async {
    final nextLang = _locale.languageCode == 'ar'
        ? 'fr'
        : (_locale.languageCode == 'fr' ? 'en' : 'ar');
    await setLocale(Locale(nextLang));
  }

  Future<void> switchEnvironment(String url) async {
    await api.setBaseUrl(url);
    notifyListeners();
    await fetchTaxonomy();
  }

  Future<void> fetchTaxonomy() async {
    try {
      final res = await api.dio.get('/taxonomy');
      if (res.data is Map && res.data['status'] == 'success') {
        categories = res.data['categories'] ?? [];
        cities = res.data['cities'] ?? [];
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchMe() async {
    if (!api.isAuthenticated) return;
    final revision = _sessionRevision;
    try {
      final response = await api.dio.get('/auth/profile');
      if (revision != _sessionRevision) return;
      final body = response.data;
      if (body is Map && body['status'] == 'success' && body['user'] is Map) {
        currentUser = Map<String, dynamic>.from(body['user'] as Map);
        notifyListeners();
        await Future.wait([
          fetchFavoritesIds(),
          fetchUnreadNotificationsCount(),
        ]);
      }
    } on DioException catch (error) {
      // Network errors and a failing favorites service must never log users out.
      if (revision == _sessionRevision && error.response?.statusCode == 401) {
        _sessionRevision++;
        currentUser = null;
        favoriteAdIds.clear();
        unreadNotificationsCount = 0;
        await api.setToken(null);
        notifyListeners();
      }
    } catch (_) {
      // Leave the last verified session intact for retry.
    }
  }

  Future<void> fetchUnreadNotificationsCount() async {
    if (!api.isAuthenticated) return;
    final revision = _sessionRevision;
    try {
      final res = await api.dio.get('/notifications');
      if (revision != _sessionRevision) return;
      final body = res.data;
      if (body is Map && body['status'] == 'success') {
        int count;
        final rawUnread = body['unread_count'];
        if (rawUnread is int) {
          count = rawUnread;
        } else if (rawUnread != null &&
            int.tryParse(rawUnread.toString()) != null) {
          count = int.parse(rawUnread.toString());
        } else {
          final List items =
              (body['notifications'] ?? body['data'] ?? []) as List;
          count = items.where((item) {
            if (item is! Map) return false;
            if (item.containsKey('is_read')) return item['is_read'] != true;
            return item['read_at'] == null;
          }).length;
        }
        if (unreadNotificationsCount != count) {
          unreadNotificationsCount = count;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> fetchFavoritesIds() async {
    if (!api.isAuthenticated) return;
    final revision = _sessionRevision;
    try {
      final res = await api.dio.get('/favorites');
      if (revision != _sessionRevision) return;
      if (res.data is Map && res.data['status'] == 'success') {
        final List items = res.data['data'] ?? [];
        favoriteAdIds = items
            .map<int>((e) => int.tryParse(e['id'].toString()) ?? 0)
            .toSet();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> toggleFavorite(int adId, {int? categoryId}) async {
    if (!isLoggedIn) return false;
    final bool previouslyFav = favoriteAdIds.contains(adId);
    if (previouslyFav) {
      favoriteAdIds.remove(adId);
    } else {
      favoriteAdIds.add(adId);
      if (categoryId != null) {
        recordCategoryInterest(categoryId, weight: 5);
      }
    }
    notifyListeners();

    try {
      final res = await api.dio.post('/favorites/$adId/toggle');
      if (res.data is Map && res.data['status'] == 'success') {
        final fav = res.data['is_favorite'] == true;
        if (fav) {
          favoriteAdIds.add(adId);
        } else {
          favoriteAdIds.remove(adId);
        }
        notifyListeners();
        return fav;
      } else {
        if (previouslyFav) {
          favoriteAdIds.add(adId);
        } else {
          favoriteAdIds.remove(adId);
        }
        notifyListeners();
      }
    } catch (_) {
      if (previouslyFav) {
        favoriteAdIds.add(adId);
      } else {
        favoriteAdIds.remove(adId);
      }
      notifyListeners();
    }
    return favoriteAdIds.contains(adId);
  }

  Future<void> setAuthSession(String token, Map<String, dynamic> user) async {
    _sessionRevision++;
    favoriteAdIds.clear();
    await api.setToken(token);
    currentUser = Map<String, dynamic>.from(user);
    await fetchFavoritesIds();
    notifyListeners();
  }

  Future<void> logout() async {
    _sessionRevision++;
    try {
      await api.dio.post('/auth/logout');
    } catch (_) {}
    await api.setToken(null);
    currentUser = null;
    favoriteAdIds.clear();
    notifyListeners();
  }
}
