import 'package:flutter/material.dart';
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

  Locale get locale => _locale;
  AppStrings get s => AppStrings(_locale.languageCode);
  bool get isLoggedIn => currentUser != null && api.isAuthenticated;

  Future<void> initialize() async {
    await api.init();
    _locale = Locale(api.locale);
    await Future.wait([
      fetchTaxonomy(),
      if (api.isAuthenticated) fetchMe(),
    ]);
    isInitialized = true;
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    final nextLang = _locale.languageCode == 'ar' ? 'fr' : 'ar';
    _locale = Locale(nextLang);
    await api.setLocale(nextLang);
    notifyListeners();
    await fetchTaxonomy();
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
    try {
      final results = await Future.wait([
        api.dio.get('/auth/profile'),
        api.dio.get('/favorites'),
      ]);
      final profileRes = results[0];
      final favRes = results[1];

      if (profileRes.data is Map && profileRes.data['status'] == 'success') {
        currentUser = profileRes.data['user'];
      }
      if (favRes.data is Map && favRes.data['status'] == 'success') {
        final List items = favRes.data['data'] ?? [];
        favoriteAdIds = items.map<int>((e) => int.tryParse(e['id'].toString()) ?? 0).toSet();
      }
      notifyListeners();
    } catch (_) {
      currentUser = null;
      await api.setToken(null);
      notifyListeners();
    }
  }

  Future<void> fetchFavoritesIds() async {
    if (!api.isAuthenticated) return;
    try {
      final res = await api.dio.get('/favorites');
      if (res.data is Map && res.data['status'] == 'success') {
        final List items = res.data['data'] ?? [];
        favoriteAdIds = items.map<int>((e) => int.tryParse(e['id'].toString()) ?? 0).toSet();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> toggleFavorite(int adId) async {
    if (!isLoggedIn) return false;
    // Optimistic UI update with automatic rollback
    final bool previouslyFav = favoriteAdIds.contains(adId);
    if (previouslyFav) {
      favoriteAdIds.remove(adId);
    } else {
      favoriteAdIds.add(adId);
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
        // Rollback on non-success status
        if (previouslyFav) {
          favoriteAdIds.add(adId);
        } else {
          favoriteAdIds.remove(adId);
        }
        notifyListeners();
      }
    } catch (_) {
      // Rollback on network / server failure
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
    await api.setToken(token);
    currentUser = user;
    await fetchFavoritesIds();
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.dio.post('/auth/logout');
    } catch (_) {}
    await api.setToken(null);
    currentUser = null;
    favoriteAdIds.clear();
    notifyListeners();
  }
}
