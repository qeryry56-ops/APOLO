import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../location/marketplace_location.dart';
import '../network/api_client.dart';
import '../config/app_config.dart';
import '../services/push_notification_service.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final ApiClient api = ApiClient();

  Locale _locale = const Locale('en');
  Map<String, dynamic>? currentUser;
  List<dynamic> categories = [];
  List<dynamic> cities = [];
  Set<int> favoriteAdIds = {};
  Set<int> followedSellerIds = {};
  int unreadNotificationsCount = 0;
  int _notificationsClearEpoch = 0;
  int _rawUnreadChatCount = 0;
  int _dismissedChatUnreadBaseline = 0;
  bool _chatTabDismissed = false;
  bool isInitialized = false;
  final ValueNotifier<int> tabReselectCounter = ValueNotifier<int>(0);

  void notifyTabReselected() {
    tabReselectCounter.value++;
  }

  int get unreadChatCount {
    if (!_chatTabDismissed) return _rawUnreadChatCount;
    return (_rawUnreadChatCount - _dismissedChatUnreadBaseline).clamp(0, 999999);
  }

  // Smart Personalization & Recommendation State (2026 Feed Engine)
  Map<int, int> categoryInterestWeights = {};
  int? preferredCityId;
  String accountType = 'individual'; // 'individual' | 'business' | 'pro_plus'

  String get effectiveAccountType {
    final raw = (currentUser?['account_type'] ?? accountType)
        .toString()
        .toLowerCase()
        .trim();
    if (raw == 'pro_plus' || currentUser?['is_pro_plus'] == true) {
      return 'pro_plus';
    }
    if (raw == 'business' ||
        raw == 'pro' ||
        raw == 'boutique' ||
        currentUser?['is_business'] == true) {
      return 'business';
    }
    return 'individual';
  }

  bool get isBusinessAccount =>
      effectiveAccountType == 'business' || effectiveAccountType == 'pro_plus';

  bool get isProPlusAccount => effectiveAccountType == 'pro_plus';

  int get vipBoostCredits =>
      int.tryParse('${currentUser?['vip_boost_credits'] ?? 0}') ?? 0;

  Map<String, dynamic>? get activeStore => currentUser?['store'] is Map
      ? Map<String, dynamic>.from(currentUser!['store'] as Map)
      : null;

  Map<String, dynamic>? get pausedStore => currentUser?['paused_store'] is Map
      ? Map<String, dynamic>.from(currentUser!['paused_store'] as Map)
      : null;

  String get autoGreeting =>
      (currentUser?['auto_greeting'] ?? '').toString().trim();

  List<Map<String, dynamic>> get quickReplies {
    final raw = currentUser?['quick_replies'];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => (e['text'] ?? '').toString().trim().isNotEmpty)
          .toList();
    }
    if (!isBusinessAccount) return const [];
    final lang = _locale.languageCode;
    return [
      {
        'id': 'avail',
        'shortcut': lang == 'en'
            ? 'Available'
            : (lang == 'fr' ? 'Disponible' : 'متوفر'),
        'text': lang == 'en'
            ? 'Hello! Yes, this item is still available.'
            : (lang == 'fr'
                  ? 'Bonjour ! Oui, cet article est toujours disponible.'
                  : 'السلام عليكم! نعم المنتج مازال متوفراً، مرحباً بك.'),
      },
      {
        'id': 'delivery',
        'shortcut': lang == 'en'
            ? 'Delivery'
            : (lang == 'fr' ? 'Livraison' : 'التوصيل'),
        'text': lang == 'en'
            ? 'Fast nationwide delivery with cash on delivery.'
            : (lang == 'fr'
                  ? 'Livraison rapide partout au Maroc avec paiement à la livraison.'
                  : 'يتوفر لدينا التوصيل السريع لجميع المدن المغربية والدفع عند الاستلام.'),
      },
      {
        'id': 'location',
        'shortcut': lang == 'en'
            ? 'Location'
            : (lang == 'fr' ? 'Adresse' : 'المحل'),
        'text': lang == 'en'
            ? 'Find our store address and opening hours on our store page.'
            : (lang == 'fr'
                  ? 'Retrouvez notre adresse et nos horaires sur la page de notre boutique.'
                  : 'تفضل بزيارة محلنا، تجد الموقع وأوقات العمل في صفحة المتجر.'),
      },
    ];
  }

  // Facebook Marketplace Geographic Zone Strategy
  double? userLat;
  double? userLng;
  String? zoneCityNameAr;
  String? zoneCityNameFr;
  double zoneRadiusKm = MarketplaceLocation.defaultZoneRadiusKm;
  bool zoneFilterEnabled = false;
  bool _zoneDetecting = false;
  bool _zoneAutoDetected = false;

  bool get isDetectingZone => _zoneDetecting;
  bool get hasActiveZone =>
      zoneFilterEnabled &&
      userLat != null &&
      userLng != null &&
      zoneRadiusKm > 0;

  Locale get locale => _locale;
  AppStrings get s => AppStrings(_locale.languageCode);
  bool get isLoggedIn => currentUser != null && api.isAuthenticated;

  bool get hasPersonalizedInterests => categoryInterestWeights.isNotEmpty;

  static const Set<String> supportedLanguageCodes = {'ar', 'fr', 'en'};

  static String _normalizeLanguageCode(String code) =>
      supportedLanguageCodes.contains(code) ? code : 'en';

  static const String _cachedUserPrefsKey = 'apolo_cached_user_v1';
  static const String _followedSellersPrefsKey = 'apolo_followed_sellers_v1';
  static const String _sellerReviewsPrefsKey = 'apolo_seller_reviews_v1';
  static const String _userIntentsPrefsKey = 'apolo_user_intents_v1';
  static const String _intentOnboardingDoneKey =
      'apolo_intent_onboarding_done_v1';

  Map<int, List<Map<String, dynamic>>> sellerUserReviews = {};

  Set<String> userIntents = <String>{};
  bool hasCompletedIntentOnboarding = false;

  /// Persists selected user usage intents (`buying`, `selling`, `pro_store`, `auto_immo`)
  /// and boosts matching category weights in Apolo's smart feed ranking engine.
  Future<void> saveUserIntents(Set<String> intents) async {
    userIntents = Set<String>.from(intents);
    hasCompletedIntentOnboarding = true;

    final mappedCategories = <int>{};
    if (intents.contains('buying')) {
      mappedCategories.addAll(const [1, 3, 4]); // Phones/Tech, Fashion, Home
    }
    if (intents.contains('selling')) {
      mappedCategories.addAll(const [1, 2, 3]);
    }
    if (intents.contains('pro_store')) {
      mappedCategories.addAll(const [1, 8]); // Tech & Services/Business
    }
    if (intents.contains('auto_immo')) {
      mappedCategories.addAll(const [2, 5]); // Vehicles & Real Estate
    }

    for (final catId in mappedCategories) {
      final current = categoryInterestWeights[catId] ?? 0;
      if (current < 10) {
        categoryInterestWeights[catId] = 10;
      }
    }

    await _savePersonalizationPrefs();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_userIntentsPrefsKey, userIntents.toList());
      await prefs.setBool(_intentOnboardingDoneKey, true);
    } catch (_) {}
    notifyListeners();
  }

  bool isFollowingSeller(int sellerId) =>
      sellerId > 0 && followedSellerIds.contains(sellerId);

  Future<void> toggleFollowSeller(int sellerId) async {
    if (sellerId <= 0) return;
    if (followedSellerIds.contains(sellerId)) {
      followedSellerIds.remove(sellerId);
    } else {
      followedSellerIds.add(sellerId);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _followedSellersPrefsKey,
        followedSellerIds.map((e) => e.toString()).toList(),
      );
    } catch (_) {}
  }

  List<Map<String, dynamic>> getUserReviewsForSeller(int sellerId) {
    if (sellerId <= 0) return const [];
    final list = sellerUserReviews[sellerId];
    if (list == null || list.isEmpty) return const [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic>? getMyReviewForSeller(int sellerId) {
    if (sellerId <= 0) return null;
    final list = sellerUserReviews[sellerId];
    if (list == null || list.isEmpty) return null;
    final myId = currentUser?['id']?.toString();
    for (final r in list) {
      if (r['is_mine'] == true) return Map<String, dynamic>.from(r);
      if (myId != null && r['user_id']?.toString() == myId) {
        return Map<String, dynamic>.from(r);
      }
    }
    return null;
  }

  ({double average, int count}) computeSellerRatingStats({
    required int sellerId,
    double? baseRating,
    int? baseCount,
    List<dynamic>? rawReviews,
  }) {
    final parsedRaw =
        (rawReviews ?? const []).whereType<Map>().toList(growable: false);
    final int initialCount = (baseCount != null && baseCount > 0)
        ? baseCount
        : parsedRaw.length;
    double initialAvg = (baseRating != null && baseRating > 0) ? baseRating : 0;
    if (initialAvg <= 0 && parsedRaw.isNotEmpty) {
      final sum = parsedRaw.fold<double>(
        0,
        (acc, r) => acc + (double.tryParse('${r['rating'] ?? 0}') ?? 0),
      );
      initialAvg = sum / parsedRaw.length;
    }

    final userList = getUserReviewsForSeller(sellerId);
    if (userList.isEmpty) {
      return (average: initialAvg, count: initialCount);
    }

    final double userSum = userList.fold<double>(
      0,
      (acc, r) => acc + (double.tryParse('${r['rating'] ?? 5}') ?? 5),
    );
    final int totalCount = initialCount + userList.length;
    final double totalAvg = totalCount > 0
        ? ((initialAvg * initialCount) + userSum) / totalCount
        : 0;
    return (average: totalAvg, count: totalCount);
  }

  Future<Map<String, dynamic>> submitSellerReview({
    required int sellerId,
    required int rating,
    required String comment,
    int? adId,
    String? adTitle,
    List<String> tags = const [],
  }) async {
    final int effSellerId = sellerId > 0
        ? sellerId
        : (adId != null && adId > 0 ? 1000000 + adId : 1);
    final int clampedRating = rating.clamp(1, 5);
    final String rawName =
        (currentUser?['name'] ?? currentUser?['full_name'] ?? '')
            .toString()
            .trim();
    final String authorName = rawName.isNotEmpty
        ? rawName
        : s.tr('عضو Apolo', 'Membre Apolo', 'Apolo Member');

    final entry = <String, dynamic>{
      'id': 'rev_${DateTime.now().millisecondsSinceEpoch}',
      'seller_id': effSellerId,
      if (adId != null) 'ad_id': adId,
      'author': authorName,
      'name': authorName,
      'user_id': currentUser?['id'],
      'rating': clampedRating,
      'comment': comment.trim(),
      'tags': tags,
      'item': (adTitle ?? '').trim(),
      'date': s.tr('الآن', 'À l’instant', 'Just now'),
      'verified': isLoggedIn,
      'is_mine': true,
      'created_at': DateTime.now().toIso8601String(),
    };

    final existing = List<Map<String, dynamic>>.from(
      sellerUserReviews[effSellerId] ?? const [],
    );
    final myId = currentUser?['id']?.toString();
    existing.removeWhere(
      (r) =>
          r['is_mine'] == true ||
          (myId != null && r['user_id']?.toString() == myId),
    );
    existing.insert(0, entry);
    sellerUserReviews[effSellerId] = existing;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        sellerUserReviews.map((k, v) => MapEntry(k.toString(), v)),
      );
      await prefs.setString(_sellerReviewsPrefsKey, encoded);
    } catch (_) {}

    if (api.isAuthenticated && sellerId > 0) {
      unawaited(
        api.dio
            .post(
              '/sellers/$sellerId/reviews',
              data: {
                'rating': clampedRating,
                'comment': comment.trim(),
                if (adId != null) 'ad_id': adId,
                if (tags.isNotEmpty) 'tags': tags,
              },
            )
            .then<void>((_) {}, onError: (_) {}),
      );
    }
    return entry;
  }

  Future<void> initialize({bool loadRemote = true}) async {
    await api.init();
    _locale = Locale(_normalizeLanguageCode(api.locale));
    await _loadPersonalizationPrefs();
    if (api.isAuthenticated) {
      await _loadCachedUser();
    }
    if (loadRemote) await refreshRemote();
    isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachedUserPrefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map && decoded['id'] != null) {
          currentUser = Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {}
  }

  Future<void> _persistCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (currentUser == null) {
        await prefs.remove(_cachedUserPrefsKey);
      } else {
        await prefs.setString(_cachedUserPrefsKey, jsonEncode(currentUser));
      }
    } catch (_) {}
  }

  Future<void> updateCurrentUser(Map<String, dynamic> user) async {
    currentUser = Map<String, dynamic>.from(user);
    accountType = effectiveAccountType;
    await _persistCurrentUser();
    await _savePersonalizationPrefs();
    notifyListeners();
  }

  Future<Map<String, dynamic>> switchToBusiness({
    required String storeName,
    String? subdomain,
    required String businessCategory,
    String? description,
    String? location,
    String? mapsUrl,
    String? workingHours,
    String? phone,
    bool directOrderEnabled = true,
    String? autoGreetingText,
    List<Map<String, dynamic>>? initialQuickReplies,
  }) async {
    final res = await api.dio.post('/account/switch-business', data: {
      'store_name': storeName.trim(),
      if (subdomain != null && subdomain.trim().isNotEmpty)
        'subdomain': subdomain.trim(),
      'business_category': businessCategory,
      if (description != null) 'description': description.trim(),
      if (location != null) 'location': location.trim(),
      if (mapsUrl != null) 'maps_url': mapsUrl.trim(),
      if (workingHours != null) 'working_hours': workingHours.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      'direct_order_enabled': directOrderEnabled,
      if (autoGreetingText != null) 'auto_greeting': autoGreetingText.trim(),
      if (initialQuickReplies != null) 'quick_replies': initialQuickReplies,
    });
    if (res.data is Map && res.data['status'] == 'success') {
      if (res.data['user'] is Map) {
        await updateCurrentUser(Map<String, dynamic>.from(res.data['user']));
      }
      return Map<String, dynamic>.from(res.data as Map);
    }
    throw StateError(
      (res.data is Map ? res.data['message'] : null)?.toString() ??
          'Failed to switch account',
    );
  }

  Future<void> switchToPersonal() async {
    final res = await api.dio.post('/account/switch-personal');
    if (res.data is Map &&
        res.data['status'] == 'success' &&
        res.data['user'] is Map) {
      await updateCurrentUser(Map<String, dynamic>.from(res.data['user']));
      return;
    }
    throw StateError('Failed to switch to personal account');
  }

  Future<void> saveBusinessQuickReplies({
    required List<Map<String, dynamic>> replies,
    String? autoGreetingText,
  }) async {
    final res = await api.dio.post('/account/quick-replies', data: {
      'quick_replies': replies,
      if (autoGreetingText != null) 'auto_greeting': autoGreetingText.trim(),
    });
    if (res.data is Map &&
        res.data['status'] == 'success' &&
        res.data['user'] is Map) {
      await updateCurrentUser(Map<String, dynamic>.from(res.data['user']));
      return;
    }
    throw StateError('Failed to save quick replies');
  }

  Future<Map<String, dynamic>> subscribeToProPlus({
    required String plan,
    required String platform,
    required String transactionId,
    String? receiptData,
  }) async {
    final res = await api.dio.post('/pro-plus/subscribe', data: {
      'plan': plan,
      'platform': platform,
      'transaction_id': transactionId,
      if (receiptData != null) 'receipt_data': receiptData,
    });
    if (res.data is Map && res.data['status'] == 'success') {
      if (res.data['user'] is Map) {
        await updateCurrentUser(Map<String, dynamic>.from(res.data['user']));
      }
      return Map<String, dynamic>.from(res.data as Map);
    }
    throw StateError(
      (res.data is Map ? res.data['message'] : null)?.toString() ??
          'Failed to activate Pro Plus',
    );
  }

  Future<void> cancelProPlusSubscription() async {
    try {
      final res = await api.dio.post('/pro-plus/cancel');
      if (res.data is Map &&
          res.data['status'] == 'success' &&
          res.data['user'] is Map) {
        await updateCurrentUser(Map<String, dynamic>.from(res.data['user']));
        return;
      }
    } catch (_) {}
    if (currentUser != null) {
      final updated = Map<String, dynamic>.from(currentUser!);
      updated['is_pro_plus'] = false;
      if ((updated['account_type'] ?? '').toString().toLowerCase() ==
          'pro_plus') {
        updated['account_type'] =
            updated['is_business'] == true ? 'business' : 'individual';
      }
      if (updated['store'] is Map) {
        final storeMap = Map<String, dynamic>.from(updated['store'] as Map);
        storeMap['is_pro_plus'] = false;
        updated['store'] = storeMap;
      }
      await updateCurrentUser(updated);
    }
  }

  Future<void> refreshRemote() async {
    await Future.wait([fetchTaxonomy(), if (api.isAuthenticated) fetchMe()]);
    syncZoneFromPreferredCity();
    // Ask-at-the-Tap UX: never prompt for GPS permission on app launch;
    // only use silent IP/city fallback here. GPS is requested when user taps "Detect my location".
    unawaited(detectUserZoneAutomatically(tryGps: false, silent: true));
  }

  int _sessionRevision = 0;

  Future<void> _loadPersonalizationPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      preferredCityId = prefs.getInt('apolo_preferred_city_id');
      accountType = prefs.getString('apolo_account_type') ?? 'individual';
      userLat = prefs.getDouble('apolo_zone_lat');
      userLng = prefs.getDouble('apolo_zone_lng');
      zoneCityNameAr = prefs.getString('apolo_zone_city_ar');
      zoneCityNameFr = prefs.getString('apolo_zone_city_fr');
      zoneRadiusKm = prefs.getDouble('apolo_zone_radius_km') ??
          MarketplaceLocation.defaultZoneRadiusKm;
      zoneFilterEnabled = prefs.getBool('apolo_zone_enabled') ?? false;
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
      final rawFollowed = prefs.getStringList(_followedSellersPrefsKey);
      if (rawFollowed != null) {
        followedSellerIds = rawFollowed
            .map((e) => int.tryParse(e))
            .whereType<int>()
            .where((id) => id > 0)
            .toSet();
      }
      sellerUserReviews = {};
      final rawReviews = prefs.getString(_sellerReviewsPrefsKey);
      if (rawReviews != null && rawReviews.isNotEmpty) {
        final decodedReviews = jsonDecode(rawReviews);
        if (decodedReviews is Map) {
          decodedReviews.forEach((k, v) {
            final sId = int.tryParse(k.toString());
            if (sId != null && sId > 0 && v is List) {
              sellerUserReviews[sId] = v
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
            }
          });
        }
      }
      final rawIntents = prefs.getStringList(_userIntentsPrefsKey);
      if (rawIntents != null) {
        userIntents = rawIntents.where((e) => e.trim().isNotEmpty).toSet();
      }
      hasCompletedIntentOnboarding =
          prefs.getBool(_intentOnboardingDoneKey) ?? false;
    } catch (_) {}
  }

  Future<void> _savePersonalizationPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (preferredCityId != null) {
        await prefs.setInt('apolo_preferred_city_id', preferredCityId!);
      }
      await prefs.setString('apolo_account_type', accountType);
      if (userLat != null && userLng != null) {
        await prefs.setDouble('apolo_zone_lat', userLat!);
        await prefs.setDouble('apolo_zone_lng', userLng!);
      }
      if (zoneCityNameAr != null) {
        await prefs.setString('apolo_zone_city_ar', zoneCityNameAr!);
      }
      if (zoneCityNameFr != null) {
        await prefs.setString('apolo_zone_city_fr', zoneCityNameFr!);
      }
      await prefs.setDouble('apolo_zone_radius_km', zoneRadiusKm);
      await prefs.setBool('apolo_zone_enabled', zoneFilterEnabled);
      final encoded = jsonEncode(
        categoryInterestWeights.map((k, v) => MapEntry(k.toString(), v)),
      );
      await prefs.setString('apolo_interest_weights', encoded);
    } catch (_) {}
  }

  String activeZoneCityLabel(AppStrings s) {
    final stored = s.isAr ? zoneCityNameAr : zoneCityNameFr;
    if (preferredCityId != null) {
      final taxCity =
          MarketplaceLocation.resolveTaxonomyCity(preferredCityId, cities);
      if (taxCity != null) return taxCity.labelForLang(s.lang);
    }
    if (stored != null && stored.trim().isNotEmpty) return stored.trim();
    return s.allCities;
  }

  String activeZoneBadgeLabel(AppStrings s) {
    if (!hasActiveZone) return s.allCities;
    final city = activeZoneCityLabel(s);
    final unit = s.tr('كم', 'km', 'km');
    return '$city · ${zoneRadiusKm.round()} $unit';
  }

  Future<void> setUserZone({
    required double lat,
    required double lng,
    required String nameAr,
    required String nameFr,
    int? cityId,
    double radiusKm = MarketplaceLocation.defaultZoneRadiusKm,
    bool enabled = true,
  }) async {
    userLat = lat;
    userLng = lng;
    zoneCityNameAr = nameAr;
    zoneCityNameFr = nameFr;
    zoneRadiusKm = radiusKm;
    zoneFilterEnabled = enabled && radiusKm > 0;
    _zoneAutoDetected = true;
    if (cityId != null) {
      preferredCityId = cityId;
    } else {
      final match = MarketplaceLocation.matchCityByName('$nameFr $nameAr');
      if (match != null) {
        preferredCityId =
            MarketplaceLocation.findTaxonomyCityId(match, cities) ??
                preferredCityId;
      }
    }
    await _savePersonalizationPrefs();
    notifyListeners();
  }

  Future<void> clearZoneFilter() async {
    zoneFilterEnabled = false;
    _zoneAutoDetected = true;
    await _savePersonalizationPrefs();
    notifyListeners();
  }

  void syncZoneFromPreferredCity() {
    if (preferredCityId == null) return;
    if (userLat != null && userLng != null && zoneFilterEnabled) return;
    final matched =
        MarketplaceLocation.resolveTaxonomyCity(preferredCityId, cities);
    if (matched != null) {
      userLat = matched.lat;
      userLng = matched.lng;
      zoneCityNameAr = matched.nameAr;
      zoneCityNameFr = matched.nameFr;
      zoneFilterEnabled = true;
      _zoneAutoDetected = true;
      notifyListeners();
    }
  }

  Future<bool> detectUserZoneAutomatically({
    bool tryGps = false,
    bool silent = true,
  }) async {
    if (_zoneDetecting) return false;
    if (silent && (_zoneAutoDetected || (zoneFilterEnabled && userLat != null))) {
      return true;
    }

    _zoneDetecting = true;
    if (!silent) notifyListeners();
    try {
      final detected =
          await MarketplaceLocation.detectLocation(tryGps: tryGps);
      if (detected != null) {
        final taxId =
            MarketplaceLocation.findTaxonomyCityId(detected.city, cities);
        await setUserZone(
          lat: detected.lat,
          lng: detected.lng,
          nameAr: detected.city.nameAr,
          nameFr: detected.city.nameFr,
          cityId: taxId,
          radiusKm: zoneRadiusKm > 0
              ? zoneRadiusKm
              : MarketplaceLocation.defaultZoneRadiusKm,
          enabled: true,
        );
        return true;
      }

      // Fallback to authenticated user's city preference if IP/GPS unavailable
      final profileCityId = int.tryParse(
        (preferredCityId ??
                currentUser?['preferred_city_id'] ??
                currentUser?['city_id'] ??
                '')
            .toString(),
      );
      if (profileCityId != null) {
        preferredCityId = profileCityId;
        syncZoneFromPreferredCity();
        if (userLat != null) {
          await _savePersonalizationPrefs();
          return true;
        }
      }
      return false;
    } finally {
      _zoneDetecting = false;
      _zoneAutoDetected = true;
      notifyListeners();
    }
  }

  /// Applies Marketplace Zone filtering + Haversine distance annotation to an ad list.
  List<Map<String, dynamic>> applyZoneToAds(
    List<Map<String, dynamic>> ads, {
    bool enforceRadiusFilter = true,
  }) {
    if (ads.isEmpty || userLat == null || userLng == null) return ads;
    final cityLabel = zoneCityNameFr ?? zoneCityNameAr ?? '';
    return MarketplaceLocation.filterAndAnnotateByZone(
      ads,
      zoneLat: userLat,
      zoneLng: userLng,
      zoneCityId: preferredCityId,
      zoneCityName: cityLabel,
      radiusKm: zoneRadiusKm,
      enabled: enforceRadiusFilter && hasActiveZone,
    );
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
    if (cityId != null) {
      preferredCityId = cityId;
      syncZoneFromPreferredCity();
    }
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
      if (ad['seller_is_pro_plus'] == true) {
        score += 22;
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
    final nextLang = _locale.languageCode == 'en'
        ? 'fr'
        : (_locale.languageCode == 'fr' ? 'ar' : 'en');
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
      final response = await api.dio.get(
        '/auth/profile',
        queryParameters: {'_t': DateTime.now().millisecondsSinceEpoch},
        options: Options(headers: {'Cache-Control': 'no-cache'}),
      );
      if (revision != _sessionRevision) return;
      final body = response.data;
      if (body is Map && body['status'] == 'success' && body['user'] is Map) {
        currentUser = Map<String, dynamic>.from(body['user'] as Map);
        accountType = effectiveAccountType;
        await _persistCurrentUser();
        if (preferredCityId == null) {
          final userCityId = int.tryParse(
            (currentUser?['preferred_city_id'] ?? currentUser?['city_id'] ?? '')
                .toString(),
          );
          if (userCityId != null) {
            preferredCityId = userCityId;
            syncZoneFromPreferredCity();
          }
        }
        notifyListeners();
        unawaited(ApoloPushNotificationService.instance.syncTokenWithBackend());
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
        await _persistCurrentUser();
        favoriteAdIds.clear();
        unreadNotificationsCount = 0;
        _notificationsClearEpoch++;
        _rawUnreadChatCount = 0;
        _dismissedChatUnreadBaseline = 0;
        _chatTabDismissed = false;
        await api.setToken(null);
        notifyListeners();
      }
    } catch (_) {
      // Leave the last verified session intact for retry.
    }
  }

  static bool _hasPositiveId(dynamic raw) => (int.tryParse('$raw') ?? 0) > 0;

  /// Rule 7: Only badge items requiring user action/decision; ignore marketing or informational alerts.
  static bool isActionableNotification(Map<dynamic, dynamic> item) {
    if (item['requires_action'] == true || item['actionable'] == true) {
      return true;
    }
    if (item['requires_action'] == false ||
        item['actionable'] == false ||
        item['is_marketing'] == true ||
        item['is_promotional'] == true ||
        item['is_informational'] == true) {
      return false;
    }

    final type = (item['type'] ?? item['category'] ?? item['kind'] ?? '')
        .toString()
        .toLowerCase()
        .trim();

    const rejectedTokens = <String>[
      'marketing',
      'promo',
      'promotion',
      'newsletter',
      'announcement',
      'broadcast',
      'news',
      'info',
      'informational',
      'tip',
      'digest',
      'welcome',
      'update',
      'campaign',
      'milestone',
      'views',
      'system_info',
    ];
    for (final token in rejectedTokens) {
      if (type.contains(token)) return false;
    }

    const actionableTokens = <String>[
      'chat',
      'message',
      'offer',
      'bid',
      'order',
      'inquiry',
      'reply',
      'call',
      'missed_call',
      'approval',
      'action',
      'review',
      'moderation',
      'verification',
      'payment',
      'رسال',
      'عرض',
      'طلب',
      'محادث',
      'مكالم',
    ];
    for (final token in actionableTokens) {
      if (type.contains(token)) return true;
    }

    final data = item['data'] is Map ? item['data'] as Map : null;
    if (_hasPositiveId(item['conversation_id'] ?? data?['conversation_id']) ||
        _hasPositiveId(item['offer_id'] ?? data?['offer_id']) ||
        _hasPositiveId(item['order_id'] ?? data?['order_id'])) {
      return true;
    }

    if ((type.isEmpty || type == 'unknown') &&
        _hasPositiveId(item['ad_id'] ?? data?['ad_id'])) {
      return true;
    }

    return false;
  }

  static int countActionableUnreadNotifications(List<dynamic> items) {
    int count = 0;
    for (final item in items) {
      if (item is! Map) continue;
      final bool isUnread = item.containsKey('is_read')
          ? item['is_read'] != true
          : item['read_at'] == null;
      if (isUnread && isActionableNotification(item)) {
        count++;
      }
    }
    return count;
  }

  void setUnreadNotificationsCount(int count) {
    final clamped = count < 0 ? 0 : count;
    if (unreadNotificationsCount != clamped) {
      unreadNotificationsCount = clamped;
      notifyListeners();
    }
  }

  /// Rule 5: Clear notification badge optimistically on open without waiting for API.
  void clearUnreadNotificationsOptimistically({bool syncRemote = true}) {
    _notificationsClearEpoch++;
    final changed = unreadNotificationsCount != 0;
    unreadNotificationsCount = 0;
    if (changed) {
      notifyListeners();
    }
    if (syncRemote && api.isAuthenticated) {
      unawaited(
        api.dio
            .post('/notifications/read-all')
            .then<void>((_) {}, onError: (_) {}),
      );
    }
  }

  void syncUnreadChatCount(
    int totalUnread, {
    bool isMessagesTabActive = false,
    bool notify = true,
  }) {
    final normalized = totalUnread < 0 ? 0 : totalUnread;
    final prev = unreadChatCount;
    _rawUnreadChatCount = normalized;
    if (isMessagesTabActive) {
      _dismissedChatUnreadBaseline = normalized;
      _chatTabDismissed = true;
    } else if (_chatTabDismissed) {
      if (normalized <= _dismissedChatUnreadBaseline) {
        _dismissedChatUnreadBaseline = normalized;
      }
      if (_dismissedChatUnreadBaseline == 0 && normalized > 0) {
        _chatTabDismissed = false;
      }
    }
    if (notify && unreadChatCount != prev) {
      notifyListeners();
    }
  }

  /// Rule 5: Clear Messages tab badge optimistically when the user opens the tab.
  void clearUnreadChatTabOptimistically() {
    final prev = unreadChatCount;
    _dismissedChatUnreadBaseline = _rawUnreadChatCount;
    _chatTabDismissed = true;
    if (unreadChatCount != prev) {
      notifyListeners();
    }
  }

  void decrementUnreadChatCountOptimistically(int amount) {
    if (amount <= 0) return;
    final prev = unreadChatCount;
    _rawUnreadChatCount = (_rawUnreadChatCount - amount).clamp(0, 999999);
    _dismissedChatUnreadBaseline =
        (_dismissedChatUnreadBaseline - amount).clamp(0, _rawUnreadChatCount);
    if (unreadChatCount != prev) {
      notifyListeners();
    }
  }

  Future<void> fetchUnreadNotificationsCount() async {
    if (!api.isAuthenticated) return;
    final revision = _sessionRevision;
    final epoch = _notificationsClearEpoch;
    try {
      final res = await api.dio.get('/notifications');
      if (revision != _sessionRevision || epoch != _notificationsClearEpoch) {
        return;
      }
      final body = res.data;
      if (body is Map && body['status'] == 'success') {
        final dynamic rawList = body['notifications'] ?? body['data'];
        final List items = rawList is List ? rawList : const [];
        int count;
        if (items.isNotEmpty) {
          count = countActionableUnreadNotifications(items);
        } else {
          final rawUnread =
              body['actionable_unread_count'] ?? body['unread_count'];
          count = rawUnread is int
              ? rawUnread
              : (int.tryParse('${rawUnread ?? 0}') ?? 0);
        }
        setUnreadNotificationsCount(count);
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

  Future<void> _clearUserScopedPrefsAndState() async {
    preferredCityId = null;
    accountType = 'individual';
    userLat = null;
    userLng = null;
    zoneCityNameAr = null;
    zoneCityNameFr = null;
    zoneRadiusKm = MarketplaceLocation.defaultZoneRadiusKm;
    zoneFilterEnabled = false;
    categoryInterestWeights = {};
    followedSellerIds.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      const keys = <String>[
        'apolo_preferred_city_id',
        'apolo_account_type',
        'apolo_zone_lat',
        'apolo_zone_lng',
        'apolo_zone_city_ar',
        'apolo_zone_city_fr',
        'apolo_zone_radius_km',
        'apolo_zone_enabled',
        'apolo_interest_weights',
        'apolo_post_ad_draft_v1',
        _followedSellersPrefsKey,
      ];
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }

  Future<void> setAuthSession(String token, Map<String, dynamic> user) async {
    final prevUserId = currentUser?['id']?.toString();
    final nextUserId = user['id']?.toString();
    if (prevUserId != null && prevUserId != nextUserId) {
      await _clearUserScopedPrefsAndState();
    }
    _sessionRevision++;
    favoriteAdIds.clear();
    followedSellerIds.clear();
    unreadNotificationsCount = 0;
    _notificationsClearEpoch++;
    _rawUnreadChatCount = 0;
    _dismissedChatUnreadBaseline = 0;
    _chatTabDismissed = false;
    await api.setToken(token);
    currentUser = Map<String, dynamic>.from(user);
    accountType = effectiveAccountType;
    await _persistCurrentUser();
    await fetchFavoritesIds();
    unawaited(ApoloPushNotificationService.instance.syncTokenWithBackend());
    notifyListeners();
  }

  Future<void> logout() async {
    _sessionRevision++;
    await ApoloPushNotificationService.instance.unregisterTokenFromBackend();
    try {
      await api.dio.post('/auth/logout');
    } catch (_) {}
    await api.setToken(null);
    await _clearUserScopedPrefsAndState();
    currentUser = null;
    await _persistCurrentUser();
    favoriteAdIds.clear();
    followedSellerIds.clear();
    unreadNotificationsCount = 0;
    _notificationsClearEpoch++;
    _rawUnreadChatCount = 0;
    _dismissedChatUnreadBaseline = 0;
    _chatTabDismissed = false;
    notifyListeners();
  }
}
