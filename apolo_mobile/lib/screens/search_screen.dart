import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import 'widgets/explore_listing_card.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/skeleton_loader.dart';

class SearchScreen extends StatefulWidget {
  final int? initialCategoryId;
  final ValueChanged<bool>? onChromeVisibilityChanged;

  const SearchScreen({
    super.key,
    this.initialCategoryId,
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
  final String _sortBy = 'smart';

  List<Map<String, dynamic>> _ads = [];
  bool _loading = true;
  bool _chromeVisible = true;
  double _accumulatedScrollDelta = 0.0;

  int _currentPage = 1;
  int _lastPage = 1;
  bool _loadingMore = false;

  // Apple Whitespace & Brand Tokens
  static const Color _ink = Color(0xFF0F172A);
  static const Color _red = Color(0xFFE31B23);
  static const Color _redSoft = Color(0xFFFEECEE);
  static const Color _surface = Color(0xFFF5F6F8);
  static const Color _emerald = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    if (_categoryId != null) {
      _state.recordCategoryInterest(_categoryId, weight: 3);
    }
    _scrollCtrl.addListener(_onScroll);
    _state.tabReselectCounter.addListener(_scrollToTop);
    _searchAds();
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
    _state.tabReselectCounter.removeListener(_scrollToTop);
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchFocus.dispose();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 240) {
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
          final rawData = res.data['data'] ?? [];
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
      setState(() {
        _ads = _filterAndSortAds(
          _hasActiveQueryOrFilters ? const [] : _fallbackExploreListings,
        );
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
        final List<Map<String, dynamic>> newItems =
            _filterAndSortAds(res.data['data'] ?? []);
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

  Map<String, dynamic>? _activeCategoryObj() {
    if (_categoryId == null) return null;
    for (final c in _effectiveCategories) {
      if (int.tryParse((c['id'] ?? '').toString()) == _categoryId) {
        return c;
      }
    }
    return null;
  }

  String? _activeCityName(AppStrings s) {
    if (_cityId == null) return null;
    for (final c in _effectiveCities) {
      if (int.tryParse((c['id'] ?? '').toString()) == _cityId) {
        return (s.isAr
                ? (c['name_ar'] ?? c['name'])
                : (c['name_fr'] ?? c['name']))
            .toString();
      }
    }
    return null;
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  14,
                  24,
                  MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.tr('تصفية وترتيب الإعلانات', 'Filtrer les annonces',
                              'Filter & Sort Ads'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            letterSpacing:
                                AppTypography.trackingForContext(context, -0.4),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempCatId = null;
                              tempCityId = null;
                              tempNeg = false;
                              minCtrl.clear();
                              maxCtrl.clear();
                            });
                          },
                          child: Text(
                            s.tr('إعادة ضبط', 'Réinitialiser'),
                            style: const TextStyle(
                              color: _red,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 1. City Chips
                    Text(
                      s.tr('المدينة', 'Ville'),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ModalFilterChip(
                          label: s.tr('كل المغرب 🌍', 'Tout le Maroc 🌍'),
                          active: tempCityId == null,
                          onTap: () => setModalState(() => tempCityId = null),
                        ),
                        ..._effectiveCities.map((c) {
                          final id = int.tryParse(c['id'].toString());
                          final lbl = (s.isAr
                                  ? (c['name_ar'] ?? c['name'])
                                  : (c['name_fr'] ?? c['name']))
                              .toString();
                          return _ModalFilterChip(
                            label: lbl,
                            active: tempCityId == id,
                            onTap: () => setModalState(() => tempCityId = id),
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 2. Category Chips
                    Text(
                      s.tr('القسم', 'Catégorie'),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ModalFilterChip(
                          label: s.tr('جميع الأقسام', 'Toutes'),
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

                    const SizedBox(height: 20),

                    // 3. Price Range Soft Inputs
                    Text(
                      s.tr('نطاق الثمن (بالدرهم)', 'Fourchette de prix (DH)'),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textDirection: TextDirection.ltr,
                            textAlign:
                                s.isAr ? TextAlign.right : TextAlign.left,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                            decoration: InputDecoration(
                              hintText: s.tr('أقل ثمن', 'Prix min'),
                              filled: true,
                              fillColor: _surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                            decoration: InputDecoration(
                              hintText: s.tr('أقصى ثمن', 'Prix max'),
                              filled: true,
                              fillColor: _surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 4. Negotiable Toggle Row
                    GestureDetector(
                      onTap: () => setModalState(() => tempNeg = !tempNeg),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.checkmark_seal_fill,
                                  color: _emerald,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  s.tr(
                                    'إظهار الإعلانات القابلة للتفاوض فقط',
                                    'Annonces négociables uniquement',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                ),
                              ],
                            ),
                            CupertinoSwitch(
                              value: tempNeg,
                              activeTrackColor: _red,
                              onChanged: (v) =>
                                  setModalState(() => tempNeg = v),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Apply Button
                    PressableScale(
                      onTap: () {
                        setState(() {
                          _categoryId = tempCatId;
                          _cityId = tempCityId;
                          _onlyNegotiable = tempNeg;
                          _minPrice = double.tryParse(minCtrl.text.trim());
                          _maxPrice = double.tryParse(maxCtrl.text.trim());
                        });
                        if (_categoryId != null) {
                          _state.recordCategoryInterest(_categoryId, weight: 3);
                        }
                        Navigator.pop(ctx);
                        _searchAds();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          s.tr('تطبيق الفلتر', 'Appliquer les filtres'),
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
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
    required Map<String, dynamic>? activeCat,
    required String? activeCity,
    required int filterCount,
  }) {
    final double titleHeight = activeCity != null ? 54.0 : 42.0;

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Minimal Title Header (no bookmark or grid/list toggle)
          SizedBox(
            height: titleHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
              child: Row(
                children: [
                  if (canPop) ...[
                    _SoftIconBtn(
                      icon: s.isAr
                          ? CupertinoIcons.chevron_right
                          : CupertinoIcons.chevron_left,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeCat != null
                              ? _state.formatCategoryLabel(activeCat)
                              : s.tr('استكشف الإعلانات',
                                  'Explorer les annonces', 'Explore Ads'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing:
                                AppTypography.trackingForContext(context, -0.5),
                            color: _ink,
                          ),
                        ),
                        if (activeCity != null)
                          Text(
                            '📍 $activeCity',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _red,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Pill Search Bar matching attached design (coral search + mic)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6F5),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFFFADBD8),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _red.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.search,
                    size: 20,
                    color: Color(0xFFD94A38),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _queryCtrl,
                      focusNode: _searchFocus,
                      cursorColor: const Color(0xFFD94A38),
                      onChanged: (_) {
                        setState(() {
                          _ads = _filterAndSortAds(_ads);
                        });
                      },
                      onSubmitted: (_) => _searchAds(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: _ink,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: s.tr('بحث...', 'Rechercher...', 'Search'),
                        hintStyle: TextStyle(
                          color: const Color(0xFFD94A38).withValues(alpha: 0.78),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
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
                            color: Color(0xFF94A3B8),
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
                          color: Color(0xFFD94A38),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Icon-Only Category Strip (no text pills, no sort/count strip)
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
                      onTap: _openFilterModal,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: filterCount > 0 ? _red : _surface,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              CupertinoIcons.slider_horizontal_3,
                              size: 19,
                              color: filterCount > 0 ? Colors.white : _ink,
                            ),
                          ),
                          if (filterCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: _ink,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$filterCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
                      message: s.tr('جميع الأقسام', 'Toutes'),
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
                            color: active ? _ink : _surface,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            CupertinoIcons.square_grid_2x2_fill,
                            size: 20,
                            color: active ? Colors.white : _ink,
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
                          color: active ? _redSoft : _surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: active ? _red : Colors.transparent,
                            width: 1.5,
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
    final activeCat = _activeCategoryObj();
    final activeCity = _activeCityName(s);
    final filterCount = _activeFilterCount;
    final double headerExtent = (activeCity != null ? 54.0 : 42.0) + 62.0 + 54.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleVerticalScrollNotification,
          child: RefreshIndicator(
            color: _red,
            backgroundColor: Colors.white,
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
                          activeCity,
                          filterCount,
                          _queryCtrl.text,
                          _effectiveCategories.length,
                        ),
                        child: _buildHeaderContent(
                          context,
                          s: s,
                          canPop: canPop,
                          activeCat: activeCat,
                          activeCity: activeCity,
                          filterCount: filterCount,
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
                          subtitle: s.tr(
                            'جرب تبدل القسم أو توسع نطاق البحث والمدينة.',
                            'Essayez une autre catégorie ou élargissez vos filtres.',
                          ),
                          actionLabel: s.tr(
                            'إعادة ضبط الفلاتر',
                            'Réinitialiser les filtres',
                          ),
                          onAction: () {
                            _setChromeVisible(true);
                            setState(() {
                              _categoryId = null;
                              _cityId = null;
                              _minPrice = null;
                              _maxPrice = null;
                              _onlyNegotiable = false;
                              _queryCtrl.clear();
                            });
                            _searchAds();
                          },
                        ),
                      )
                    else if (isWide)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
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
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: _red,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              );
                            }
                            final ad = _ads[idx];
                            return RepaintBoundary(
                              key: ValueKey('search_wide_${ad['id']}_$_sortBy'),
                              child: ExploreListingCard(ad: ad),
                            );
                          },
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                        sliver: SliverList.separated(
                          itemCount: _ads.length + (_loadingMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, idx) {
                            if (idx >= _ads.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: _red,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              );
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

class _SoftIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SoftIconBtn({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6F8),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
      ),
    );
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
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFE31B23) : const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
