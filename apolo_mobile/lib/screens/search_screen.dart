import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../widgets/apolo_search_suggestions_view.dart';
import '../widgets/dl_settings_kit.dart';
import 'ad_detail_screen.dart';
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
  String _sortBy = 'smart';

  List<dynamic> _rawAds = [];
  List<Map<String, dynamic>> _ads = [];
  List<dynamic> _suggestedStores = [];
  bool _loading = true;
  bool _isSearchModeActive = false;
  bool _chromeVisible = true;
  double _accumulatedScrollDelta = 0.0;
  String? _lastZoneSignature;

  int _currentPage = 1;
  int _lastPage = 1;
  bool _loadingMore = false;

  // Dynamic Layer v5.1 Palette Tokens
  static const Color _dlBg = Color(0xFFFFFFFF);
  static const Color _dlSurface = Color(0xFFF6F6F6);
  static const Color _dlPill = Color(0xFFEEEEEE);
  static const Color _dlInk = Color(0xFF000000);
  static const Color _dlMuted = Color(0xFF757575);
  static const Color _dlSubtle = Color(0xFF9E9E9E);

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
      'badge_label': 'Villa',
      'highlight_label': 'Guest favorite',
      'is_guest_favorite': true,
      'rating': '4.8',
      'reviews_count': 126,
      'specs_display': 'Cascais, 14 km · 3 bedrooms · Pool',
      'free_cancellation': true,
      'price': 233,
      'total_price_display': '\$933',
      'total_unit_label': 'total',
      'nightly_price_display': '\$233 / night · taxes incl.',
      'main_image':
          'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1000&q=80',
      'images': [
        'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1000&q=80',
      ],
    },
    {
      'id': 9102,
      'title': 'Dar Sol Palmeraie',
      'badge_label': 'Riad',
      'highlight_label': 'Guest favorite',
      'is_guest_favorite': true,
      'rating': '4.9',
      'reviews_count': 84,
      'specs_display': 'Marrakech, 8 km · 4 bedrooms · Heated pool',
      'free_cancellation': true,
      'price': 195,
      'total_price_display': '\$780',
      'total_unit_label': 'total',
      'nightly_price_display': '\$195 / night · taxes incl.',
      'main_image':
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1000&q=80',
      'images': [
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1000&q=80',
      ],
    },
    {
      'id': 9103,
      'title': 'Oceanview Cedar Villa',
      'badge_label': 'Villa',
      'highlight_label': 'Guest favorite',
      'is_guest_favorite': true,
      'rating': '4.7',
      'reviews_count': 92,
      'specs_display': 'Taghazout, 3 km · 2 bedrooms · Terrace',
      'free_cancellation': true,
      'price': 168,
      'total_price_display': '\$672',
      'total_unit_label': 'total',
      'nightly_price_display': '\$168 / night · taxes incl.',
      'main_image':
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1000&q=80',
      'images': [
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1000&q=80',
        'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1000&q=80',
      ],
    },
  ];

  bool get _hasActiveQueryOrFilters =>
      _categoryId != null ||
      _cityId != null ||
      _minPrice != null ||
      _maxPrice != null ||
      _onlyNegotiable ||
      _queryCtrl.text.trim().isNotEmpty;

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
          _hasActiveQueryOrFilters ? const [] : _fallbackExploreListings;
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
                              style: const TextStyle(
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
                                style: const TextStyle(
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
                        style: const TextStyle(
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
                        style: const TextStyle(
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
                        style: const TextStyle(
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
                        style: const TextStyle(
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _dlInk,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      s.tr('أقل ثمن', 'Prix min', 'Min price'),
                                  hintStyle: const TextStyle(
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _dlInk,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      s.tr('أقصى ثمن', 'Prix max', 'Max price'),
                                  hintStyle: const TextStyle(
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
                                decoration: const BoxDecoration(
                                  color: _dlBg,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
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
                                  style: const TextStyle(
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
                decoration: const BoxDecoration(
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
                          decoration: const BoxDecoration(
                            color: _dlPill,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            CupertinoIcons.bookmark_fill,
                            size: 16,
                            color: _dlInk,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.tr('الإعلانات المحفوظة', 'Enregistrés', 'Saved'),
                            style: const TextStyle(
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
                                style: const TextStyle(
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
                                decoration: const BoxDecoration(
                                  color: _dlSurface,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
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
                                style: const TextStyle(
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
                                style: const TextStyle(
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
                                                child: const Icon(
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
                                            style: const TextStyle(
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
                                              style: const TextStyle(
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
                                        style: const TextStyle(
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
                        const Icon(
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
                            onSubmitted: (_) {
                              _exitSearchMode();
                              _searchAds();
                            },
                            style: const TextStyle(
                              fontSize: 15,
                              color: _dlInk,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: InputDecoration(
                              hintText: s.tr('بحث...', 'Rechercher...', 'Search'),
                              hintStyle: const TextStyle(
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
                            child: const SizedBox(
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
                          child: const SizedBox(
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
                    child: const SizedBox(
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
                              color: filterCount > 0 ? Colors.white : _dlInk,
                            ),
                            if (filterCount > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                '$filterCount',
                                style: const TextStyle(
                                  color: Colors.white,
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
                            color: active ? Colors.white : _dlInk,
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

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final canPop = Navigator.of(context).canPop();
    final filterCount = _activeFilterCount;
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
                onBack: _exitSearchMode,
                onChanged: (_) {
                  setState(() {
                    _ads = _filterAndSortAds(_rawAds);
                  });
                },
                onSubmitQuery: (_) {
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
                              child: Row(
                                children: [
                                  MarketplaceZonePill(
                                    state: _state,
                                    compact: true,
                                    onTap: () =>
                                        showMarketplaceZoneSheet(context),
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
                                        style: const TextStyle(
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
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: _dlMuted,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (_loading)
                            const SliverFillRemaining(
                              hasScrollBody: true,
                              child: SearchGridSkeleton(isGrid: false),
                            )
                          else if (_ads.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: IllustratedStateView(
                                assetPath: 'assets/images/state_empty_ads.png',
                                imageSize: 156,
                                title: s.noAdsFound,
                                subtitle: _state.hasActiveZone
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
                          else
                            SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 8, 20, 132),
                              sliver: SliverList.separated(
                                itemCount: _ads.length + (_loadingMore ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, idx) {
                                  if (idx >= _ads.length) {
                                    return const SearchListCardSkeleton();
                                  }
                                  final ad = _ads[idx];
                                  return RepaintBoundary(
                                    key: ValueKey(
                                      'search_explore_${ad['id']}_$_sortBy',
                                    ),
                                    child: ExploreListingCard(ad: ad),
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
      color: Colors.white,
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
              color: active ? Colors.black : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
