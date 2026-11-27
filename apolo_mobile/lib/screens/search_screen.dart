import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../widgets/apolo_badges_kit.dart';
import '../widgets/apolo_infeed_upgrade_card.dart';
import '../widgets/apolo_search_suggestions_view.dart';
import '../widgets/dl_settings_kit.dart';
import 'ad_detail_screen.dart';
import 'widgets/ad_card.dart';
import 'widgets/app_image.dart';
import 'widgets/explore_listing_card.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/marketplace_zone_sheet.dart';
import 'widgets/price_text.dart';
import 'widgets/skeleton_loader.dart';

class SearchScreen extends StatefulWidget {
  final int? initialCategoryId;
  final String? initialQuery;
  final bool initialSearchActive;
  final List<ApoloSuggestedAccount>? initialSuggestedAccounts;
  final ValueChanged<bool>? onChromeVisibilityChanged;

  const SearchScreen({
    super.key,
    this.initialCategoryId,
    this.initialQuery,
    this.initialSearchActive = false,
    this.initialSuggestedAccounts,
    this.onChromeVisibilityChanged,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final AppState _state = AppState();
  final TextEditingController _queryCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  int? _categoryId;
  int? _cityId;
  double? _minPrice;
  double? _maxPrice;
  bool _onlyNegotiable = false;
  String _sellerType = 'all'; // 'all' | 'personal' | 'business'
  String _sortBy = 'smart';

  static const String _recentSearchesPrefsKey = 'apolo_recent_searches_v1';

  List<dynamic> _rawAds = [];
  List<Map<String, dynamic>> _ads = [];
  List<dynamic> _suggestedStores = [];
  List<String> _recentSearches = [];
  bool _loading = true;
  bool _isSearchModeActive = false;
  bool _compactGrid = false;
  bool _chromeVisible = true;
  double _accumulatedScrollDelta = 0.0;
  String? _lastZoneSignature;

  int _currentPage = 1;
  int _lastPage = 1;
  bool _loadingMore = false;

  // Dynamic Layer v5.1 Palette Tokens
  Color get _dlBg => ApoloDlPalette.of(context).bg;
  Color get _dlSurface => ApoloDlPalette.of(context).surfaceSubtle;
  Color get _dlPill => ApoloDlPalette.of(context).pill;
  Color get _dlInk => ApoloDlPalette.of(context).ink;
  Color get _dlOnInk => ApoloDlPalette.of(context).onInk;
  Color get _dlMuted => ApoloDlPalette.of(context).muted;
  Color get _dlSubtle => ApoloDlPalette.of(context).subtle;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _queryCtrl.text = widget.initialQuery!.trim();
    }
    _isSearchModeActive = widget.initialSearchActive;
    if (_categoryId != null) {
      _state.recordCategoryInterest(_categoryId, weight: 3);
    }
    _searchFocus.addListener(_onSearchFocusChanged);
    _scrollCtrl.addListener(_onScroll);
    _state.addListener(_onAppStateChanged);
    _state.tabReselectCounter.addListener(_scrollToTop);
    _lastZoneSignature =
        '${_state.zoneFilterEnabled}_${_state.userLat}_${_state.userLng}_${_state.zoneRadiusKm}';
    _loadRecentSearches();
    _searchAds();
    _loadSuggestedStores();
    if (_isSearchModeActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _setChromeVisible(false);
          _searchFocus.requestFocus();
        }
      });
    }
  }

  void _onSearchFocusChanged() {
    if (!mounted) return;
    if (_searchFocus.hasFocus && !_isSearchModeActive) {
      _enterSearchMode();
    }
  }

  void _enterSearchMode() {
    if (_isSearchModeActive) return;
    setState(() => _isSearchModeActive = true);
    _setChromeVisible(false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isSearchModeActive && !_searchFocus.hasFocus) {
        _searchFocus.requestFocus();
      }
    });
  }

  void _exitSearchMode() {
    FocusScope.of(context).unfocus();
    if (_isSearchModeActive) {
      setState(() => _isSearchModeActive = false);
    }
    _setChromeVisible(true);
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_recentSearchesPrefsKey) ?? const [];
      if (!mounted) return;
      setState(() {
        _recentSearches = saved
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .take(6)
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _recordRecentSearch(String raw) async {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return;
    final updated = <String>[
      cleaned,
      ..._recentSearches.where(
        (item) => item.toLowerCase() != cleaned.toLowerCase(),
      ),
    ].take(6).toList();
    setState(() => _recentSearches = updated);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesPrefsKey, updated);
    } catch (_) {}
  }

  Future<void> _removeRecentSearch(String query) async {
    final updated = _recentSearches.where((item) => item != query).toList();
    setState(() => _recentSearches = updated);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesPrefsKey, updated);
    } catch (_) {}
  }

  Future<void> _clearRecentSearches() async {
    setState(() => _recentSearches = const []);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesPrefsKey);
    } catch (_) {}
  }

  Future<void> _loadSuggestedStores() async {
    try {
      final res = await _state.api.dio.get(
        '/stores',
        queryParameters: const <String, dynamic>{'page': 1},
      );
      if (!mounted) return;
      if (res.data is Map && res.data['status'] == 'success') {
        final list = (res.data['data'] as List?) ?? const <dynamic>[];
        setState(() => _suggestedStores = list);
      }
    } catch (_) {}
  }

  List<ApoloSuggestedAccount> get _effectiveSuggestedAccounts {
    if (widget.initialSuggestedAccounts != null &&
        widget.initialSuggestedAccounts!.isNotEmpty) {
      return widget.initialSuggestedAccounts!;
    }
    final myId = int.tryParse('${_state.currentUser?['id'] ?? 0}');
    return ApoloSuggestedAccount.extractFromSources(
      stores: _suggestedStores,
      ads: _rawAds,
      excludeUserId: myId != null && myId > 0 ? myId : null,
    );
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    final sig =
        '${_state.zoneFilterEnabled}_${_state.userLat}_${_state.userLng}_${_state.zoneRadiusKm}';
    if (sig != _lastZoneSignature) {
      _lastZoneSignature = sig;
      setState(() {
        _ads = _filterAndSortAds(_rawAds);
      });
    } else {
      setState(() {});
    }
  }

  void _setChromeVisible(bool visible) {
    _accumulatedScrollDelta = 0.0;
    if (_chromeVisible == visible) return;
    _chromeVisible = visible;
    widget.onChromeVisibilityChanged?.call(visible);
  }

  bool _handleVerticalScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final metrics = notification.metrics;
    final pixels = metrics.pixels;
    final maxExtent = metrics.maxScrollExtent;

    if (pixels <= 8 || maxExtent <= 80) {
      if (!_chromeVisible) _setChromeVisible(true);
      _accumulatedScrollDelta = 0.0;
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0.0;
      if (delta == 0.0) return false;

      if (delta > 0) {
        if (_accumulatedScrollDelta < 0) _accumulatedScrollDelta = 0.0;
        _accumulatedScrollDelta += delta;
        if (_chromeVisible &&
            pixels > 24 &&
            pixels < maxExtent - 12 &&
            _accumulatedScrollDelta >= 14) {
          _setChromeVisible(false);
        }
      } else {
        if (pixels < maxExtent - 4) {
          if (_accumulatedScrollDelta > 0) _accumulatedScrollDelta = 0.0;
          _accumulatedScrollDelta += delta;
          if (!_chromeVisible && _accumulatedScrollDelta <= -10) {
            _setChromeVisible(true);
          }
        }
      }
    }
    return false;
  }

  void _scrollToTop() {
    _setChromeVisible(true);
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 340),
        curve: const Cubic(0.22, 1.0, 0.36, 1.0),
      );
    }
  }

  @override
  void dispose() {
    _state.removeListener(_onAppStateChanged);
    _state.tabReselectCounter.removeListener(_scrollToTop);
    _scrollCtrl.removeListener(_onScroll);
    _searchFocus.removeListener(_onSearchFocusChanged);
    _scrollCtrl.dispose();
    _searchFocus.dispose();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 650) {
      if (!_loading && !_loadingMore && _currentPage < _lastPage) {
        _loadMoreAds();
      }
    }
  }

  List<Map<String, dynamic>> get _effectiveCategories {
    if (_state.categories.isNotEmpty) {
      return _state.categories
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [
      {'id': 1, 'name_ar': 'وسائل النقل', 'name_fr': 'Véhicules'},
      {'id': 2, 'name_ar': 'عقارات', 'name_fr': 'Immobilier'},
      {'id': 3, 'name_ar': 'إعلاميات وتقنية', 'name_fr': 'Informatique'},
      {'id': 4, 'name_ar': 'هواتف وتقنية', 'name_fr': 'Téléphones'},
      {'id': 5, 'name_ar': 'أثاث وديكور', 'name_fr': 'Maison & Déco'},
      {'id': 6, 'name_ar': 'أزياء وجمال', 'name_fr': 'Mode & Beauté'},
    ];
  }

  List<Map<String, dynamic>> get _effectiveCities {
    if (_state.cities.isNotEmpty) {
      return _state.cities
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [
      {'id': 1, 'name_ar': 'الدار البيضاء', 'name_fr': 'Casablanca'},
      {'id': 2, 'name_ar': 'الرباط', 'name_fr': 'Rabat'},
      {'id': 3, 'name_ar': 'مراكش', 'name_fr': 'Marrakech'},
      {'id': 4, 'name_ar': 'طنجة', 'name_fr': 'Tanger'},
      {'id': 5, 'name_ar': 'أكادير', 'name_fr': 'Agadir'},
      {'id': 6, 'name_ar': 'فاس', 'name_fr': 'Fès'},
    ];
  }

  int get _activeFilterCount {
    int count = 0;
    if (_cityId != null) count++;
    if (_minPrice != null || _maxPrice != null) count++;
    if (_onlyNegotiable) count++;
    if (_sellerType != 'all') count++;
    if (_sortBy != 'smart') count++;
    return count;
  }

  List<Map<String, dynamic>> _filterAndSortAds(List<dynamic> rawList) {
    final mapped = rawList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final query = _queryCtrl.text.trim().toLowerCase();

    var filtered = mapped.where((ad) {
      if (_categoryId != null && !_state.adMatchesCategory(ad, _categoryId)) {
        return false;
      }
      if (_cityId != null) {
        final adCityId = int.tryParse(
          (ad['city_id'] ?? (ad['city'] is Map ? ad['city']['id'] : ''))
              .toString(),
        );
        if (adCityId != _cityId) return false;
      }
      final priceVal = double.tryParse((ad['price'] ?? 0).toString()) ?? 0.0;
      if (_minPrice != null && priceVal < _minPrice!) return false;
      if (_maxPrice != null && priceVal > _maxPrice!) return false;
      if (_onlyNegotiable) {
        final neg = ad['negotiable'] == true || ad['is_negotiable'] == true;
        if (!neg) return false;
      }
      if (_sellerType != 'all') {
        final isBiz = ApoloAccountTypeBadge.isAdFromBusiness(ad);
        if (_sellerType == 'business' && !isBiz) return false;
        if (_sellerType == 'personal' && isBiz) return false;
      }
      if (query.isNotEmpty) {
        final title = (ad['title'] ?? '').toString().toLowerCase();
        final desc = (ad['description'] ?? '').toString().toLowerCase();
        if (!title.contains(query) && !desc.contains(query)) return false;
      }
      return true;
    }).toList();

    switch (_sortBy) {
      case 'price_asc':
        filtered.sort((a, b) {
          final pa = double.tryParse((a['price'] ?? 0).toString()) ?? 0;
          final pb = double.tryParse((b['price'] ?? 0).toString()) ?? 0;
          return pa.compareTo(pb);
        });
        break;
      case 'price_desc':
        filtered.sort((a, b) {
          final pa = double.tryParse((a['price'] ?? 0).toString()) ?? 0;
          final pb = double.tryParse((b['price'] ?? 0).toString()) ?? 0;
          return pb.compareTo(pa);
        });
        break;
      case 'popular':
        filtered.sort((a, b) {
          final va =
              int.tryParse((a['views_count'] ?? a['views'] ?? 0).toString()) ??
                  0;
          final vb =
              int.tryParse((b['views_count'] ?? b['views'] ?? 0).toString()) ??
                  0;
          return vb.compareTo(va);
        });
        break;
      case 'newest':
        filtered.sort((a, b) {
          final ia = int.tryParse((a['id'] ?? 0).toString()) ?? 0;
          final ib = int.tryParse((b['id'] ?? 0).toString()) ?? 0;
          return ib.compareTo(ia);
        });
        break;
      default:
        filtered = _state.rankAdsForUser(filtered);
        break;
    }

    if (_cityId == null) {
      filtered = _state.applyZoneToAds(
        filtered,
        enforceRadiusFilter: _state.hasActiveZone,
      );
    }

    return filtered;
  }

  static const List<Map<String, dynamic>> _fallbackExploreListings = [
    {
      'id': 9101,
      'title': 'Casa Oliva Villa',
      'category_id': 2,
      'city_id': 3,
      'category': {'id': 2, 'name_ar': 'عقارات', 'name_fr': 'Immobilier'},
      'city': {'id': 3, 'name_ar': 'مراكش', 'name_fr': 'Marrakech'},
      'is_vip': true,
      'negotiable': true,
      'rating': '4.9',
      'reviews_count': 126,
      'views_count': 340,
      'seller_name': 'Youssef Alami',
      'seller_verified': false,
      'is_business': false,
      'description': 'Villa contemporaine 4 chambres avec piscine chauffée à Marrakech Palmeraie.',
      'price': 2450000,
      'price_formatted': '2 450 000 DH',
      'main_image':
          'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1000&q=80',
      'images': [
        'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1000&q=80',
      ],
    },
    {
      'id': 9102,
      'title': 'Mercedes-Benz Classe C 220d AMG',
      'category_id': 1,
      'city_id': 1,
      'category': {'id': 1, 'name_ar': 'وسائل النقل', 'name_fr': 'Véhicules'},
      'city': {'id': 1, 'name_ar': 'الدار البيضاء', 'name_fr': 'Casablanca'},
      'is_vip': true,
      'negotiable': true,
      'rating': '4.9',
      'reviews_count': 94,
      'views_count': 512,
      'seller_name': 'Mehdi Bennani',
      'seller_verified': false,
      'is_business': false,
      'description': 'Modèle 2023 · Boîte auto · Toit panoramique · 1ère main Maroc.',
      'price': 385000,
      'price_formatted': '385 000 DH',
      'main_image':
          'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?auto=format&fit=crop&w=1000&q=80',
      'images': [
        'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1617531653332-bd46c24f2068?auto=format&fit=crop&w=1000&q=80',
      ],
    },
    {
      'id': 9103,
      'title': 'iPhone 16 Pro Max 256GB Natural Titanium',
      'category_id': 4,
      'city_id': 2,
      'category': {'id': 4, 'name_ar': 'هواتف وتقنية', 'name_fr': 'Téléphones'},
      'city': {'id': 2, 'name_ar': 'الرباط', 'name_fr': 'Rabat'},
      'is_featured': true,
      'negotiable': false,
      'rating': '4.8',
      'reviews_count': 78,
      'views_count': 289,
      'seller_name': 'Amine Idrissi',
      'seller_verified': false,
      'is_business': false,
      'description': 'Neuf scellé avec garantie officielle 12 mois · Batterie 100%.',
      'price': 13900,
      'price_formatted': '13 900 DH',
      'main_image':
          'https://images.unsplash.com/photo-1695048133142-1a20484d2569?auto=format&fit=crop&w=1000&q=80',
      'images': [
        'https://images.unsplash.com/photo-1695048133142-1a20484d2569?auto=format&fit=crop&w=1000&q=80',
      ],
    },
    {
      'id': 9104,
      'title': 'MacBook Pro 14" M3 Pro · 18GB / 512GB SSD',
      'category_id': 3,
      'city_id': 4,
      'category': {'id': 3, 'name_ar': 'إعلاميات وتقنية', 'name_fr': 'Informatique'},
      'city': {'id': 4, 'name_ar': 'طنجة', 'name_fr': 'Tanger'},
      'negotiable': true,
      'rating': '4.9',
      'reviews_count': 53,
      'views_count': 198,
      'seller_name': 'Yassine Tazi',
      'seller_verified': false,
      'is_business': false,
      'description': 'État neuf · 14 cycles batterie · Chargeur MagSafe 70W original.',
      'price': 21500,
      'price_formatted': '21 500 DH',
      'main_image':
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=1000&q=80',
      'images': [
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=1000&q=80',
      ],
    },
    {
      'id': 9105,
      'title': 'Salon Marocain Moderne Bois Hêtre',
      'category_id': 5,
      'city_id': 5,
      'category': {'id': 5, 'name_ar': 'أثاث وديكور', 'name_fr': 'Maison & Déco'},
      'city': {'id': 5, 'name_ar': 'أكادير', 'name_fr': 'Agadir'},
      'negotiable': true,
      'rating': '4.7',
      'reviews_count': 41,
      'views_count': 142,
      'seller_name': 'Salma Chraibi',
      'seller_verified': false,
      'is_business': false,
      'description': 'Salon complet sur mesure avec table centrale et coussins anti-taches.',
      'price': 9800,
      'price_formatted': '9 800 DH',
      'main_image':
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=1000&q=80',
      'images': [
        'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=1000&q=80',
      ],
    },
    {
      'id': 9106,
      'title': 'Montre Tissot PRX Powermatic 80',
      'category_id': 6,
      'city_id': 6,
      'category': {'id': 6, 'name_ar': 'أزياء وجمال', 'name_fr': 'Mode & Beauté'},
      'city': {'id': 6, 'name_ar': 'فاس', 'name_fr': 'Fès'},
      'negotiable': false,
      'rating': '4.8',
      'reviews_count': 62,
      'views_count': 176,
      'seller_name': 'Karim Fassi',
      'seller_verified': false,
      'is_business': false,
      'description': 'Authentique avec coffret et carte de garantie internationale.',
      'price': 6400,
      'price_formatted': '6 400 DH',
      'main_image':
          'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?auto=format&fit=crop&w=1000&q=80',
      'images': [
        'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?auto=format&fit=crop&w=1000&q=80',
      ],
    },
  ];

  Future<void> _searchAds() async {
    setState(() {
      _loading = true;
      _currentPage = 1;
    });
    try {
      final params = <String, dynamic>{
        if (_queryCtrl.text.trim().isNotEmpty) 'query': _queryCtrl.text.trim(),
        if (_categoryId != null) 'category_id': _categoryId,
        if (_cityId != null) 'city_id': _cityId,
        if (_minPrice != null) 'price_min': _minPrice,
        if (_maxPrice != null) 'price_max': _maxPrice,
        'page': 1,
      };
      final res = await _state.api.dio.get('/ads', queryParameters: params);
      if (res.data is Map && res.data['status'] == 'success') {
        if (mounted) {
          final meta = res.data['meta'];
          final rawData = (res.data['data'] as List?) ?? [];
          _rawAds = rawData;
          setState(() {
            _ads = _filterAndSortAds(rawData);
            _currentPage =
                int.tryParse((meta?['current_page'] ?? 1).toString()) ?? 1;
            _lastPage = int.tryParse((meta?['last_page'] ?? 1).toString()) ?? 1;
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      final fallbackSource =
          _rawAds.isNotEmpty ? _rawAds : _fallbackExploreListings;
      _rawAds = fallbackSource;
      setState(() {
        _ads = _filterAndSortAds(fallbackSource);
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreAds() async {
    if (_loadingMore || _currentPage >= _lastPage) return;
    setState(() => _loadingMore = true);
    final nextPage = _currentPage + 1;
    try {
      final params = <String, dynamic>{
        if (_queryCtrl.text.trim().isNotEmpty) 'query': _queryCtrl.text.trim(),
        if (_categoryId != null) 'category_id': _categoryId,
        if (_cityId != null) 'city_id': _cityId,
        if (_minPrice != null) 'price_min': _minPrice,
        if (_maxPrice != null) 'price_max': _maxPrice,
        'page': nextPage,
      };
      final res = await _state.api.dio.get('/ads', queryParameters: params);
      if (res.data is Map && res.data['status'] == 'success') {
        final List<dynamic> incomingRaw = (res.data['data'] as List?) ?? [];
        final existingRawIds = _rawAds
            .whereType<Map>()
            .map((e) => e['id']?.toString())
            .toSet();
        for (final it in incomingRaw) {
          if (it is Map && !existingRawIds.contains(it['id']?.toString())) {
            _rawAds.add(it);
          }
        }
        final List<Map<String, dynamic>> newItems =
            _filterAndSortAds(incomingRaw);
        final meta = res.data['meta'];
        if (mounted) {
          setState(() {
            final existingIds = _ads.map((e) => e['id']?.toString()).toSet();
            for (final it in newItems) {
              if (!existingIds.contains(it['id']?.toString())) {
                _ads.add(it);
              }
            }
            _currentPage =
                int.tryParse((meta?['current_page'] ?? nextPage).toString()) ??
                    nextPage;
            _lastPage =
                int.tryParse((meta?['last_page'] ?? _lastPage).toString()) ??
                    _lastPage;
            _loadingMore = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingMore = false);
  }

  void _openFilterModal() {
    HapticFeedback.selectionClick();
    final s = _state.s;
    final minCtrl =
        TextEditingController(text: _minPrice?.toInt().toString() ?? '');
    final maxCtrl =
        TextEditingController(text: _maxPrice?.toInt().toString() ?? '');

    int? tempCatId = _categoryId;
    int? tempCityId = _cityId;
    bool tempNeg = _onlyNegotiable;
    String tempSort = _sortBy;

    final sortOptions = <({String key, String label})>[
      (
        key: 'smart',
        label: s.tr('مقترح لك', 'Recommandé', 'Recommended'),
      ),
      (
        key: 'newest',
        label: s.tr('الأحدث', 'Plus récents', 'Newest'),
      ),
      (
        key: 'price_asc',
        label: s.tr('الأقل ثمناً', 'Prix croissant', 'Lowest price'),
      ),
      (
        key: 'price_desc',
        label: s.tr('الأعلى ثمناً', 'Prix décroissant', 'Highest price'),
      ),
      (
        key: 'popular',
        label: s.tr('الأكثر مشاهدة', 'Populaires', 'Most viewed'),
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _dlBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Directionality(
              textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _dlPill,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.tr(
                                'تصفية وترتيب الإعلانات',
                                'Filtrer et trier',
                                'Filter & Sort',
                              ),
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: _dlInk,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModalState(() {
                                tempCatId = null;
                                tempCityId = null;
                                tempNeg = false;
                                tempSort = 'smart';
                                minCtrl.clear();
                                maxCtrl.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _dlPill,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                s.tr('إعادة ضبط', 'Réinitialiser', 'Reset'),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: _dlInk,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ApoloDlIconCircleButton(
                            icon: CupertinoIcons.xmark,
                            iconSize: 16,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 1. Sort By Pills
                      Text(
                        s.tr('الترتيب حسب', 'Trier par', 'Sort by'),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _dlMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sortOptions.map((opt) {
                          return _ModalFilterChip(
                            label: opt.label,
                            active: tempSort == opt.key,
                            onTap: () =>
                                setModalState(() => tempSort = opt.key),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // 2. City Pills
                      Text(
                        s.tr('المدينة', 'Ville', 'City'),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _dlMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ModalFilterChip(
                            label: s.tr(
                              'كل المغرب',
                              'Tout le Maroc',
                              'All Morocco',
                            ),
                            active: tempCityId == null,
                            onTap: () => setModalState(() => tempCityId = null),
                          ),
                          ..._effectiveCities.map((c) {
                            final id = int.tryParse(c['id'].toString());
                            final lbl = (s.isAr
                                    ? (c['name_ar'] ?? c['name'])
                                    : (s.isEn
                                        ? (c['name_en'] ??
                                            c['name_fr'] ??
                                            c['name'])
                                        : (c['name_fr'] ?? c['name'])))
                                .toString();
                            return _ModalFilterChip(
                              label: lbl,
                              active: tempCityId == id,
                              onTap: () => setModalState(() => tempCityId = id),
                            );
                          }),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 3. Category Pills
                      Text(
                        s.tr('القسم', 'Catégorie', 'Category'),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _dlMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ModalFilterChip(
                            label: s.tr('جميع الأقسام', 'Toutes', 'All'),
                            active: tempCatId == null,
                            onTap: () => setModalState(() => tempCatId = null),
                          ),
                          ..._effectiveCategories.map((c) {
                            final id = int.tryParse(c['id'].toString());
                            final lbl = _state.formatCategoryLabel(c);
                            return _ModalFilterChip(
                              label: lbl,
                              active: tempCatId == id,
                              onTap: () => setModalState(() => tempCatId = id),
                            );
                          }),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 4. Price Range Inputs (`#F6F6F6` flat rounded `16px`)
                      Text(
                        s.tr(
                          'نطاق الثمن (بالدرهم)',
                          'Fourchette de prix (DH)',
                          'Price range (MAD)',
                        ),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _dlMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: _dlSurface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              child: TextField(
                                controller: minCtrl,
                                cursorColor: _dlInk,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                textDirection: TextDirection.ltr,
                                textAlign:
                                    s.isAr ? TextAlign.end : TextAlign.start,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _dlInk,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      s.tr('أقل ثمن', 'Prix min', 'Min price'),
                                  hintStyle: TextStyle(
                                    color: _dlSubtle,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  hintTextDirection: s.isAr
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: _dlSurface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              child: TextField(
                                controller: maxCtrl,
                                cursorColor: _dlInk,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                textDirection: TextDirection.ltr,
                                textAlign:
                                    s.isAr ? TextAlign.end : TextAlign.start,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _dlInk,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      s.tr('أقصى ثمن', 'Prix max', 'Max price'),
                                  hintStyle: TextStyle(
                                    color: _dlSubtle,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  hintTextDirection: s.isAr
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // 5. Negotiable Toggle Row with ApoloDlSwitch
                      GestureDetector(
                        onTap: () => setModalState(() => tempNeg = !tempNeg),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _dlSurface,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _dlBg,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  CupertinoIcons.tag_fill,
                                  color: _dlInk,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  s.tr(
                                    'إظهار الإعلانات القابلة للتفاوض فقط',
                                    'Annonces négociables uniquement',
                                    'Negotiable listings only',
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _dlInk,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ApoloDlSwitch(
                                value: tempNeg,
                                activeColor: _dlInk,
                                onChanged: (v) =>
                                    setModalState(() => tempNeg = v),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 6. Primary Capsule Apply Button
                      ApoloDlButton(
                        label: s.tr(
                          'تطبيق الفلتر',
                          'Appliquer les filtres',
                          'Apply filters',
                        ),
                        variant: ApoloDlButtonVariant.primary,
                        borderRadius: 999,
                        height: 52,
                        fullWidth: true,
                        onPressed: () {
                          setState(() {
                            _categoryId = tempCatId;
                            _cityId = tempCityId;
                            _onlyNegotiable = tempNeg;
                            _sortBy = tempSort;
                            _minPrice = double.tryParse(minCtrl.text.trim());
                            _maxPrice = double.tryParse(maxCtrl.text.trim());
                          });
                          if (_categoryId != null) {
                            _state.recordCategoryInterest(
                              _categoryId,
                              weight: 3,
                            );
                          }
                          Navigator.pop(ctx);
                          _searchAds();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveCurrentSearch(AppStrings s) async {
    if (!_state.api.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _dlInk,
          content: Text(
            s.tr(
              'سجّل الدخول لحفظ البحث والإعلانات',
              'Connectez-vous pour enregistrer',
              'Sign in to save searches & listings',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final res = await _state.api.dio.post(
        '/saved-searches',
        data: {
          'query': _queryCtrl.text.trim(),
          if (_categoryId != null) 'category_id': _categoryId,
          if (_cityId != null) 'city_id': _cityId,
          if (_minPrice != null) 'price_min': _minPrice,
          if (_maxPrice != null) 'price_max': _maxPrice,
        },
      );
      if (!mounted) return;
      final ok = res.data is Map && res.data['status'] == 'success';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _dlInk,
          content: Text(
            ok
                ? s.tr(
                    'تم حفظ البحث بنجاح',
                    'Recherche enregistrée',
                    'Search saved',
                  )
                : s.tr(
                    'تعذر حفظ البحث حالياً',
                    'Impossible d’enregistrer pour le moment',
                    'Unable to save search right now',
                  ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _dlInk,
          content: Text(
            s.tr(
              'تعذر حفظ البحث حالياً',
              'Impossible d’enregistrer pour le moment',
              'Unable to save search right now',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openSavedSheet(AppStrings s) async {
    HapticFeedback.selectionClick();
    final List<Map<String, dynamic>> cachedFavs = _ads
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((ad) {
      final id = int.tryParse(ad['id']?.toString() ?? '') ?? -1;
      return id > 0 && _state.favoriteAdIds.contains(id);
    }).toList();

    List<Map<String, dynamic>> remoteFavs = cachedFavs;
    bool loadingRemote = _state.api.isAuthenticated;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        bool started = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            if (!started && loadingRemote) {
              started = true;
              _state.api.dio.get('/favorites').then((res) {
                if (!ctx.mounted) return;
                if (res.data is Map && res.data['status'] == 'success') {
                  final list = (res.data['data'] as List? ?? [])
                      .whereType<Map>()
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();
                  setSheetState(() {
                    remoteFavs = list;
                    loadingRemote = false;
                  });
                } else {
                  setSheetState(() => loadingRemote = false);
                }
              }).catchError((_) {
                if (ctx.mounted) {
                  setSheetState(() => loadingRemote = false);
                }
              });
            }

            final hasActiveQuery = _queryCtrl.text.trim().isNotEmpty ||
                _categoryId != null ||
                _cityId != null ||
                _minPrice != null ||
                _maxPrice != null;

            return Directionality(
              textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.72,
                ),
                decoration: BoxDecoration(
                  color: _dlBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(ctx).padding.bottom + 18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _dlPill,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _dlPill,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            CupertinoIcons.bookmark_fill,
                            size: 16,
                            color: _dlInk,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.tr('الإعلانات المحفوظة', 'Enregistrés', 'Saved'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _dlInk,
                            ),
                          ),
                        ),
                        if (hasActiveQuery) ...[
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              _saveCurrentSearch(s);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _dlPill,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                s.tr(
                                  'حفظ البحث',
                                  'Sauver recherche',
                                  'Save search',
                                ),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _dlInk,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        ApoloDlIconCircleButton(
                          icon: CupertinoIcons.xmark,
                          iconSize: 16,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (loadingRemote)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: SavedFavoritesSkeleton(),
                      )
                    else if (remoteFavs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: _dlSurface,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  CupertinoIcons.bookmark,
                                  size: 26,
                                  color: _dlMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                s.tr(
                                  'لا توجد إعلانات محفوظة بعد',
                                  'Aucune annonce enregistrée',
                                  'No saved listings yet',
                                ),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _dlInk,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.tr(
                                  'اضغط على القلب في أي إعلان لحفظه هنا',
                                  'Appuyez sur le cœur d’une annonce pour la sauvegarder',
                                  'Tap the heart on any listing to save it here',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _dlMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: remoteFavs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final ad = remoteFavs[i];
                            final id =
                                int.tryParse(ad['id']?.toString() ?? '') ?? 0;
                            final title = (ad['title'] ?? '').toString();
                            final city = (ad['city'] is Map
                                    ? (ad['city']['name'] ??
                                        ad['city']['name_fr'] ??
                                        ad['city']['name_ar'])
                                    : ad['city'] ?? '')
                                .toString();
                            final priceRaw = double.tryParse(
                              ad['price']?.toString() ?? '',
                            );
                            final formatted =
                                (ad['price_formatted'] ?? '').toString().trim();
                            final priceLabel = formatted.isNotEmpty
                                ? formatted
                                : (priceRaw != null
                                    ? '${priceRaw.toInt()} ${s.tr('د.م', 'MAD', 'MAD')}'
                                    : '');
                            String imgUrl = '';
                            if (ad['images'] is List &&
                                (ad['images'] as List).isNotEmpty) {
                              final first = (ad['images'] as List).first;
                              imgUrl = first is Map
                                  ? (first['url'] ?? first['image_path'] ?? '')
                                      .toString()
                                  : first.toString();
                            } else {
                              imgUrl = (ad['primary_image'] ??
                                      ad['main_image'] ??
                                      ad['image'] ??
                                      ad['thumbnail'] ??
                                      '')
                                  .toString();
                            }
                            return PressableScale(
                              onTap: id > 0
                                  ? () {
                                      Navigator.pop(ctx);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AdDetailScreen(
                                            adId: id,
                                            initialAd: ad,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _dlSurface,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 54,
                                        height: 54,
                                        child: imgUrl.isNotEmpty
                                            ? AppImage(
                                                url: imgUrl,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                color: _dlPill,
                                                child: Icon(
                                                  CupertinoIcons.photo,
                                                  color: _dlMuted,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: _dlInk,
                                            ),
                                          ),
                                          if (city.isNotEmpty)
                                            Text(
                                              city,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _dlMuted,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (priceLabel.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      PriceText(
                                        priceLabel,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: _dlInk,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderContent(
    BuildContext context, {
    required AppStrings s,
    required bool canPop,
    required int filterCount,
  }) {
    return Container(
      key: const Key('dl-explore-header'),
      color: _dlBg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dynamic Layer v5.1 `#EEEEEE` Pill Search Bar + bare Saved Bookmark on same row
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 16, 8),
            child: Row(
              children: [
                if (canPop) ...[
                  ApoloDlIconCircleButton(
                    icon: s.isAr
                        ? CupertinoIcons.chevron_forward
                        : CupertinoIcons.chevron_back,
                    iconSize: 19,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: _dlPill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.search,
                          size: 20,
                          color: _dlMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            key: const Key('explore-search-bar-field'),
                            controller: _queryCtrl,
                            focusNode: _searchFocus,
                            cursorColor: _dlInk,
                            onTap: _enterSearchMode,
                            onChanged: (_) {
                              setState(() {
                                _ads = _filterAndSortAds(_rawAds);
                              });
                            },
                            onSubmitted: (val) {
                              _recordRecentSearch(val);
                              _exitSearchMode();
                              _searchAds();
                            },
                            style: TextStyle(
                              fontSize: 15,
                              color: _dlInk,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: InputDecoration(
                              hintText: s.tr('بحث...', 'Rechercher...', 'Search'),
                              hintStyle: TextStyle(
                                color: _dlSubtle,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_queryCtrl.text.isNotEmpty) ...[
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _queryCtrl.clear();
                              _searchAds();
                            },
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: Center(
                                child: Icon(
                                  CupertinoIcons.clear_circled_solid,
                                  size: 18,
                                  color: _dlSubtle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _searchFocus.requestFocus();
                          },
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: Center(
                              child: Icon(
                                CupertinoIcons.mic_fill,
                                size: 19,
                                color: _dlMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _openSavedSheet(s),
                  behavior: HitTestBehavior.opaque,
                  child: Semantics(
                    button: true,
                    label: s.tr('المحفوظات', 'Enregistrés', 'Saved'),
                    child: SizedBox(
                      width: 38,
                      height: 44,
                      child: Center(
                        child: Icon(
                          CupertinoIcons.bookmark,
                          size: 21,
                          color: _dlInk,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Dynamic Layer v5.1 Icon-Only Category Strip (`#000000` active / `#EEEEEE` idle)
          SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _effectiveCategories.length + 2,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Semantics(
                    button: true,
                    label: s.tr('تصفية', 'Filtrer', 'Filter'),
                    child: PressableScale(
                      key: const Key('dl-explore-filter-btn'),
                      onTap: _openFilterModal,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 46,
                        constraints: const BoxConstraints(minWidth: 46),
                        padding: EdgeInsets.symmetric(
                          horizontal: filterCount > 0 ? 14 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: filterCount > 0 ? _dlInk : _dlPill,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.slider_horizontal_3,
                              size: 19,
                              color: filterCount > 0 ? _dlOnInk : _dlInk,
                            ),
                            if (filterCount > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                '$filterCount',
                                style: TextStyle(
                                  color: _dlOnInk,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (index == 1) {
                  final active = _categoryId == null;
                  return Semantics(
                    button: true,
                    selected: active,
                    label: s.tr('جميع الأقسام', 'Toutes', 'All categories'),
                    child: Tooltip(
                      message: s.tr('جميع الأقسام', 'Toutes', 'All categories'),
                      child: PressableScale(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _categoryId = null);
                          _searchAds();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: active ? _dlInk : _dlPill,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            CupertinoIcons.square_grid_2x2_fill,
                            size: 20,
                            color: active ? _dlOnInk : _dlInk,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final cat = _effectiveCategories[index - 2];
                final int? id = int.tryParse(cat['id']?.toString() ?? '');
                final active = _categoryId == id;
                final label = _state.formatCategoryLabel(cat);
                final asset = _state.assetForCategory(cat, label);

                return Semantics(
                  button: true,
                  selected: active,
                  label: label,
                  child: Tooltip(
                    message: label,
                    child: PressableScale(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (id != null) {
                          _state.recordCategoryInterest(id, weight: 3);
                        }
                        setState(() => _categoryId = active ? null : id);
                        _searchAds();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 46,
                        height: 46,
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: active ? _dlPill : _dlSurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: active ? _dlInk : Colors.transparent,
                            width: 1.75,
                          ),
                        ),
                        child: Image.asset(asset, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _sortShortLabel(AppStrings s) {
    switch (_sortBy) {
      case 'newest':
        return s.tr('الأحدث', 'Plus récents', 'Newest');
      case 'price_asc':
        return s.tr('الأقل ثمناً', 'Prix croissant', 'Lowest price');
      case 'price_desc':
        return s.tr('الأعلى ثمناً', 'Prix décroissant', 'Highest price');
      case 'popular':
        return s.tr('الأكثر مشاهدة', 'Populaires', 'Most viewed');
      default:
        return s.tr('مقترح لك', 'Recommandé', 'Recommended');
    }
  }

  String? _selectedCityLabel(AppStrings s) {
    if (_cityId == null) return null;
    for (final c in _effectiveCities) {
      if (int.tryParse('${c['id']}') == _cityId) {
        return (s.isAr
                ? (c['name_ar'] ?? c['name'])
                : (s.isEn
                    ? (c['name_en'] ?? c['name_fr'] ?? c['name'])
                    : (c['name_fr'] ?? c['name'])))
            .toString();
      }
    }
    return null;
  }

  Widget _buildSellerTypePill({
    required Key pillKey,
    required String value,
    required String label,
    IconData? icon,
  }) {
    final active = _sellerType == value;
    return GestureDetector(
      key: pillKey,
      onTap: () {
        if (_sellerType == value) return;
        HapticFeedback.selectionClick();
        setState(() {
          _sellerType = value;
          _ads = _filterAndSortAds(_rawAds);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: active ? _dlInk : _dlPill,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: active ? _dlOnInk : _dlInk,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? _dlOnInk : _dlInk,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required Key chipKey,
    required String label,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      key: chipKey,
      onTap: () {
        HapticFeedback.selectionClick();
        onRemove();
      },
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: _dlPill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _dlInk,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              CupertinoIcons.xmark,
              size: 11,
              color: _dlMuted,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final canPop = Navigator.of(context).canPop();
    final filterCount = _activeFilterCount;
    final cityChipLabel = _selectedCityLabel(s);
    final hasPriceRange = _minPrice != null || _maxPrice != null;
    final activeChips = <Widget>[
      if (_queryCtrl.text.trim().isNotEmpty)
        _buildActiveFilterChip(
          chipKey: const Key('explore-chip-query'),
          label: '"${_queryCtrl.text.trim()}"',
          onRemove: () {
            _queryCtrl.clear();
            _searchAds();
          },
        ),
      if (cityChipLabel != null)
        _buildActiveFilterChip(
          chipKey: const Key('explore-chip-city'),
          label: cityChipLabel,
          onRemove: () {
            setState(() => _cityId = null);
            _searchAds();
          },
        ),
      if (hasPriceRange)
        _buildActiveFilterChip(
          chipKey: const Key('explore-chip-price'),
          label: _minPrice != null && _maxPrice != null
              ? '${_minPrice!.toInt()}–${_maxPrice!.toInt()} DH'
              : (_minPrice != null
                  ? '≥ ${_minPrice!.toInt()} DH'
                  : '≤ ${_maxPrice!.toInt()} DH'),
          onRemove: () {
            setState(() {
              _minPrice = null;
              _maxPrice = null;
            });
            _searchAds();
          },
        ),
      if (_onlyNegotiable)
        _buildActiveFilterChip(
          chipKey: const Key('explore-chip-negotiable'),
          label: s.tr('قابل للتفاوض', 'Négociable', 'Negotiable'),
          onRemove: () {
            setState(() => _onlyNegotiable = false);
            _searchAds();
          },
        ),
      if (_sortBy != 'smart')
        _buildActiveFilterChip(
          chipKey: const Key('explore-chip-sort'),
          label: _sortShortLabel(s),
          onRemove: () {
            setState(() => _sortBy = 'smart');
            _searchAds();
          },
        ),
    ];
    const double headerExtent = 64.0 + 54.0;

    return Scaffold(
      key: const Key('dl-explore-screen'),
      backgroundColor: _dlBg,
      body: SafeArea(
        bottom: false,
        child: _isSearchModeActive
            ? ApoloSearchSuggestionsView(
                controller: _queryCtrl,
                focusNode: _searchFocus,
                accounts: _effectiveSuggestedAccounts,
                matchingAds: _ads,
                recentSearches: _recentSearches,
                onRemoveRecentSearch: _removeRecentSearch,
                onClearRecentSearches: _clearRecentSearches,
                onBack: _exitSearchMode,
                onChanged: (_) {
                  setState(() {
                    _ads = _filterAndSortAds(_rawAds);
                  });
                },
                onSubmitQuery: (val) {
                  _recordRecentSearch(val);
                  _exitSearchMode();
                  _searchAds();
                },
              )
            : NotificationListener<ScrollNotification>(
                onNotification: _handleVerticalScrollNotification,
                child: RefreshIndicator(
                  color: _dlInk,
                  backgroundColor: _dlBg,
                  onRefresh: _searchAds,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 680;
                      return CustomScrollView(
                        controller: _scrollCtrl,
                        scrollCacheExtent: const ScrollCacheExtent.pixels(700),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          SliverPersistentHeader(
                            floating: true,
                            pinned: false,
                            delegate: _ExploreFloatingHeaderDelegate(
                              extent: headerExtent,
                              vsyncProvider: this,
                              rebuildKey: Object.hash(
                                s.lang,
                                canPop,
                                _categoryId,
                                filterCount,
                                _queryCtrl.text,
                                _effectiveCategories.length,
                                Theme.of(context).brightness,
                              ),
                              child: _buildHeaderContent(
                                context,
                                s: s,
                                canPop: canPop,
                                filterCount: filterCount,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: MarketplaceZonePill(
                                          state: _state,
                                          compact: true,
                                          onTap: () =>
                                              showMarketplaceZoneSheet(context),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (_state.hasActiveZone)
                                        GestureDetector(
                                          onTap: () => _state.clearZoneFilter(),
                                          child: Text(
                                            s.tr(
                                              'كل المغرب',
                                              'Tout voir',
                                              'All areas',
                                            ),
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: _dlInk,
                                            ),
                                          ),
                                        )
                                      else
                                        GestureDetector(
                                          onTap: () =>
                                              showMarketplaceZoneSheet(context),
                                          child: Text(
                                            s.tr(
                                              'حدد منطقتك',
                                              'Choisir zone',
                                              'Set area',
                                            ),
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: _dlMuted,
                                            ),
                                          ),
                                        ),
                                      if (!isWide) ...[
                                        const SizedBox(width: 10),
                                        Semantics(
                                          button: true,
                                          label: _compactGrid
                                              ? s.tr(
                                                  'عرض البطاقات الكبيرة',
                                                  'Vue détaillée',
                                                  'Feed view',
                                                )
                                              : s.tr(
                                                  'عرض الشبكة',
                                                  'Vue grille',
                                                  'Grid view',
                                                ),
                                          child: PressableScale(
                                            key: const Key(
                                              'dl-explore-view-toggle',
                                            ),
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              setState(
                                                () =>
                                                    _compactGrid = !_compactGrid,
                                              );
                                            },
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: _compactGrid
                                                    ? _dlInk
                                                    : _dlPill,
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                _compactGrid
                                                    ? CupertinoIcons
                                                        .rectangle_grid_1x2
                                                    : CupertinoIcons
                                                        .rectangle_grid_2x2,
                                                size: 15.5,
                                                color: _compactGrid
                                                    ? _dlOnInk
                                                    : _dlInk,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (AppConfig
                                      .enablePremiumAndBusinessTiers) ...[
                                    const SizedBox(height: 8),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      child: Row(
                                        children: [
                                          _buildSellerTypePill(
                                            pillKey: const Key(
                                              'explore-seller-type-all',
                                            ),
                                            value: 'all',
                                            label: s.tr('الكل', 'Tous', 'All'),
                                          ),
                                          const SizedBox(width: 6),
                                          _buildSellerTypePill(
                                            pillKey: const Key(
                                              'explore-seller-type-personal',
                                            ),
                                            value: 'personal',
                                            icon: CupertinoIcons.person_fill,
                                            label: s.tr(
                                              'أفراد',
                                              'Particuliers',
                                              'Personal',
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          _buildSellerTypePill(
                                            pillKey: const Key(
                                              'explore-seller-type-business',
                                            ),
                                            value: 'business',
                                            icon: Icons.storefront_rounded,
                                            label: s.tr(
                                              'متاجر Business',
                                              'Boutiques',
                                              'Business',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (activeChips.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      key: const Key(
                                        'dl-explore-active-filters-row',
                                      ),
                                      height: 30,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: activeChips.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 8),
                                        itemBuilder: (_, idx) =>
                                            activeChips[idx],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (_loading)
                            SliverFillRemaining(
                              hasScrollBody: true,
                              child: SearchGridSkeleton(isGrid: _compactGrid),
                            )
                          else if (_ads.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: ApoloDlEmptyState(
                                icon: CupertinoIcons.search,
                                headline: s.noAdsFound,
                                description: _state.hasActiveZone
                                    ? s.tr(
                                        'لا توجد إعلانات في نطاق ${_state.zoneRadiusKm.round()} كم من ${_state.activeZoneCityLabel(s)}. يمكنك توسيع النطاق أو عرض كل المغرب.',
                                        'Aucune annonce dans un rayon de ${_state.zoneRadiusKm.round()} km.',
                                        'No listings within ${_state.zoneRadiusKm.round()} km of ${_state.activeZoneCityLabel(s)}.',
                                      )
                                    : s.tr(
                                        'جرب تبدل القسم أو توسع نطاق البحث والمدينة.',
                                        'Essayez une autre catégorie ou élargissez vos filtres.',
                                        'Try another category or broaden your filters.',
                                      ),
                                actionLabel: _state.hasActiveZone
                                    ? s.tr(
                                        'عرض كل المغرب',
                                        'Voir tout le Maroc',
                                        'Show all Morocco',
                                      )
                                    : s.tr(
                                        'إعادة ضبط الفلاتر',
                                        'Réinitialiser les filtres',
                                        'Reset filters',
                                      ),
                                onAction: () async {
                                  _setChromeVisible(true);
                                  if (_state.hasActiveZone) {
                                    await _state.clearZoneFilter();
                                  }
                                  setState(() {
                                    _categoryId = null;
                                    _cityId = null;
                                    _minPrice = null;
                                    _maxPrice = null;
                                    _onlyNegotiable = false;
                                    _sellerType = 'all';
                                    _sortBy = 'smart';
                                    _queryCtrl.clear();
                                  });
                                  _searchAds();
                                },
                              ),
                            )
                          else if (isWide)
                            SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 8, 20, 132),
                              sliver: SliverGrid.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 400,
                                  mainAxisExtent: 374,
                                  mainAxisSpacing: 18,
                                  crossAxisSpacing: 18,
                                ),
                                itemCount: _ads.length + (_loadingMore ? 2 : 0),
                                itemBuilder: (context, idx) {
                                  if (idx >= _ads.length) {
                                    return const AdGridCardSkeleton();
                                  }
                                  final ad = _ads[idx];
                                  return RepaintBoundary(
                                    key: ValueKey(
                                      'search_wide_${ad['id']}_$_sortBy',
                                    ),
                                    child: ExploreListingCard(ad: ad),
                                  );
                                },
                              ),
                            )
                          else if (_compactGrid) ...[
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                20,
                                8,
                                20,
                                _state.shouldShowInFeedUpgradePromo &&
                                        _queryCtrl.text.trim().isEmpty
                                    ? 16
                                    : 132,
                              ),
                              sliver: SliverGrid.builder(
                                key: const Key('dl-explore-compact-grid'),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.72,
                                ),
                                itemCount: _ads.length + (_loadingMore ? 2 : 0),
                                itemBuilder: (context, idx) {
                                  if (idx >= _ads.length) {
                                    return const AdGridCardSkeleton();
                                  }
                                  final ad = _ads[idx];
                                  return RepaintBoundary(
                                    key: ValueKey(
                                      'search_compact_${ad['id']}_$_sortBy',
                                    ),
                                    child: AdCard(ad: ad),
                                  );
                                },
                              ),
                            ),
                            if (_state.shouldShowInFeedUpgradePromo &&
                                _queryCtrl.text.trim().isEmpty)
                              const SliverToBoxAdapter(
                                child: ApoloInFeedUpgradePromoCard(
                                  margin: EdgeInsets.fromLTRB(20, 0, 20, 132),
                                ),
                              ),
                          ] else
                            SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 8, 20, 132),
                              sliver: Builder(
                                builder: (context) {
                                  final showPromo =
                                      _state.shouldShowInFeedUpgradePromo &&
                                          _queryCtrl.text.trim().isEmpty &&
                                          _ads.isNotEmpty;
                                  final promoIndex =
                                      _ads.length >= 2 ? 2 : _ads.length;
                                  final baseCount = _ads.length +
                                      (showPromo ? 1 : 0);
                                  return SliverList.separated(
                                    itemCount:
                                        baseCount + (_loadingMore ? 1 : 0),
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 16),
                                    itemBuilder: (context, idx) {
                                      if (idx >= baseCount) {
                                        return const SearchListCardSkeleton();
                                      }
                                      if (showPromo && idx == promoIndex) {
                                        return const RepaintBoundary(
                                          key: ValueKey(
                                            'explore_infeed_upgrade_promo',
                                          ),
                                          child: ApoloInFeedUpgradePromoCard(),
                                        );
                                      }
                                      final adIdx =
                                          showPromo && idx > promoIndex
                                              ? idx - 1
                                              : idx;
                                      final ad = _ads[adIdx];
                                      return RepaintBoundary(
                                        key: ValueKey(
                                          'search_explore_${ad['id']}_$_sortBy',
                                        ),
                                        child: ExploreListingCard(ad: ad),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

class _ExploreFloatingHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final TickerProvider vsyncProvider;
  final int rebuildKey;
  final Widget child;

  const _ExploreFloatingHeaderDelegate({
    required this.extent,
    required this.vsyncProvider,
    required this.rebuildKey,
    required this.child,
  });

  @override
  double get maxExtent => extent;

  @override
  double get minExtent => 0.0;

  @override
  TickerProvider? get vsync => vsyncProvider;

  @override
  FloatingHeaderSnapConfiguration? get snapConfiguration =>
      FloatingHeaderSnapConfiguration(
        curve: const Cubic(0.22, 1.0, 0.36, 1.0),
        duration: const Duration(milliseconds: 240),
      );

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final visibleFraction =
        ((extent - shrinkOffset) / extent).clamp(0.0, 1.0);
    return Material(
      color: ApoloDlPalette.of(context).bg,
      child: ClipRect(
        child: OverflowBox(
          minHeight: extent,
          maxHeight: extent,
          alignment: Alignment.bottomCenter,
          child: Opacity(
            opacity: Curves.easeOut.transform(visibleFraction),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ExploreFloatingHeaderDelegate oldDelegate) {
    return oldDelegate.extent != extent ||
        oldDelegate.rebuildKey != rebuildKey;
  }
}

class _ModalFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModalFilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    return PressableScale(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40, minWidth: 44),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: active ? palette.ink : palette.pill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? palette.onInk : palette.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
