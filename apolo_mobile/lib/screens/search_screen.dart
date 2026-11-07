import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'widgets/ad_card.dart';
import 'widgets/skeleton_loader.dart';

class SearchScreen extends StatefulWidget {
  final int? initialCategoryId;
  const SearchScreen({super.key, this.initialCategoryId});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final AppState _state = AppState();
  final TextEditingController _queryCtrl = TextEditingController();
  int? _categoryId;
  int? _cityId;
  double? _minPrice;
  double? _maxPrice;
  List<dynamic> _ads = [];
  bool _loading = true;
  bool _gridView = true;

  final ScrollController _scrollCtrl = ScrollController();
  int _currentPage = 1;
  int _lastPage = 1;
  bool _loadingMore = false;

  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _red = Color(0xFFE31B23);
  static const Color _pillBg = Color(0xFFF1F3F7);
  static const Color _border = Color(0xFFE7EAF0);

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    if (_categoryId != null) {
      _state.recordCategoryInterest(_categoryId, weight: 3);
    }
    _scrollCtrl.addListener(_onScroll);
    _searchAds();
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
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

  List<Map<String, dynamic>> _filterAndRankAds(List<dynamic> rawList) {
    final mapped = rawList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // Strict client-side verification so entering a category ONLY shows ads belonging to that category
    final filtered = _categoryId == null
        ? mapped
        : mapped
            .where((ad) => _state.adMatchesCategory(ad, _categoryId))
            .toList();

    if (_categoryId == null && _queryCtrl.text.trim().isEmpty) {
      return _state.rankAdsForUser(filtered);
    }
    return filtered;
  }

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
            _ads = _filterAndRankAds(rawData);
            _currentPage =
                int.tryParse((meta?['current_page'] ?? 1).toString()) ?? 1;
            _lastPage = int.tryParse((meta?['last_page'] ?? 1).toString()) ?? 1;
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
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
        final List newItems = _filterAndRankAds(res.data['data'] ?? []);
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

  Future<void> _saveCurrentSearch() async {
    if (!_state.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _state.s.tr(
              'يرجى تسجيل الدخول لحفظ البحث',
              'Connectez-vous pour sauvegarder la recherche',
            ),
          ),
        ),
      );
      return;
    }
    try {
      final res = await _state.api.dio.post('/saved-searches', data: {
        'title': _queryCtrl.text.trim().isNotEmpty
            ? _queryCtrl.text.trim()
            : _state.s.tr('بحث محفوظ', 'Recherche sauvegardée'),
        'query': _queryCtrl.text.trim(),
        'category_id': _categoryId,
        'city_id': _cityId,
        'price_min': _minPrice,
        'price_max': _maxPrice,
      });
      if (mounted && res.data is Map && res.data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppConfig.success,
            content: Text(
              _state.s.tr(
                'تم حفظ البحث! ستصلك إشعارات عند توفر إعلانات جديدة',
                'Recherche sauvegardée avec alertes !',
              ),
            ),
          ),
        );
      }
    } catch (_) {}
  }

  Map<String, dynamic>? _activeCategoryObj() {
    if (_categoryId == null) return null;
    for (final c in _state.categories) {
      if (c is Map &&
          int.tryParse((c['id'] ?? '').toString()) == _categoryId) {
        return Map<String, dynamic>.from(c);
      }
    }
    return null;
  }

  void _openFilterModal() {
    final s = _state.s;
    final minCtrl =
        TextEditingController(text: _minPrice?.toInt().toString() ?? '');
    final maxCtrl =
        TextEditingController(text: _maxPrice?.toInt().toString() ?? '');

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
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.tr('تصفية النتائج', 'Filtrer les résultats'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -0.4,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _categoryId = null;
                            _cityId = null;
                            minCtrl.clear();
                            maxCtrl.clear();
                          });
                        },
                        child: Text(
                          s.tr('إعادة تعيين', 'Réinitialiser'),
                          style: const TextStyle(
                            color: _red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: _categoryId,
                    decoration: InputDecoration(
                      labelText: s.categories,
                      prefixIcon: const Icon(CupertinoIcons.square_grid_2x2, size: 18),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(s.allCategories)),
                      ..._state.categories.whereType<Map>().map(
                            (c) => DropdownMenuItem<int?>(
                              value: int.tryParse(c['id'].toString()),
                              child: Text(_state.formatCategoryLabel(c)),
                            ),
                          ),
                    ],
                    onChanged: (v) => setModalState(() => _categoryId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: _cityId,
                    decoration: InputDecoration(
                      labelText: s.allCities,
                      prefixIcon: const Icon(CupertinoIcons.location, size: 18),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(s.allCities)),
                      ..._state.cities.whereType<Map>().map(
                            (c) => DropdownMenuItem<int?>(
                              value: int.tryParse(c['id'].toString()),
                              child: Text(
                                (s.isAr
                                        ? (c['name_ar'] ?? c['name'])
                                        : (c['name_fr'] ?? c['name']))
                                    .toString(),
                              ),
                            ),
                          ),
                    ],
                    onChanged: (v) => setModalState(() => _cityId = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: s.tr('أقل ثمن (درهم)', 'Prix min (MAD)'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: s.tr('أقصى ثمن (درهم)', 'Prix max (MAD)'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _minPrice = double.tryParse(minCtrl.text.trim());
                          _maxPrice = double.tryParse(maxCtrl.text.trim());
                        });
                        if (_categoryId != null) {
                          _state.recordCategoryInterest(_categoryId, weight: 3);
                        }
                        Navigator.pop(ctx);
                        _searchAds();
                      },
                      child: Text(
                        s.tr('تطبيق التصفية', 'Appliquer les filtres'),
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final topPadding = MediaQuery.of(context).padding.top;
    final activeCat = _activeCategoryObj();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header + View Mode Switcher
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    activeCat != null
                        ? _state.formatCategoryLabel(activeCat)
                        : s.tr('استكشف الإعلانات', 'Explorer les annonces'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: _ink,
                    ),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _saveCurrentSearch,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _pillBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: _border),
                        ),
                        child: const Icon(
                          CupertinoIcons.bell_solid,
                          size: 17,
                          color: _red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _gridView = !_gridView),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _pillBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: _border),
                        ),
                        child: Icon(
                          _gridView
                              ? CupertinoIcons.list_bullet
                              : CupertinoIcons.square_grid_2x2,
                          size: 18,
                          color: _ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Active Category Showcase Banner when a category is selected
          if (activeCat != null)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFDF2F3), Color(0xFFF6F8FC)],
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _red.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Image.asset(
                      _state.assetForCategory(activeCat),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _state.formatCategoryLabel(activeCat),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        Text(
                          s.tr(
                            'كاع الإعلانات المعروضة هنا خاصة بهاد القسم فقط',
                            'Toutes les annonces affichées appartiennent à cette catégorie',
                          ),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: _muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _categoryId = null);
                      _searchAds();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _border),
                      ),
                      child: Text(
                        s.tr('إلغاء ×', 'Tout ×'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Search Bar + Filter Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: _pillBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.search,
                          size: 18,
                          color: _muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _queryCtrl,
                            onSubmitted: (_) => _searchAds(),
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: _ink,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: s.searchHint,
                              hintStyle: const TextStyle(
                                color: _muted,
                                fontSize: 14,
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
                        if (_queryCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _queryCtrl.clear();
                              _searchAds();
                            },
                            child: const Icon(
                              CupertinoIcons.clear_circled_solid,
                              size: 17,
                              color: _muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _openFilterModal,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: (_cityId != null ||
                              _minPrice != null ||
                              _maxPrice != null)
                          ? _red
                          : _ink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.slider_horizontal_3,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Category Pills with Product Icons
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _state.categories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final active = _categoryId == null;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _categoryId = null);
                      _searchAds();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? _red : _pillBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        s.tr('جميع الأقسام', 'Toutes'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : _ink,
                        ),
                      ),
                    ),
                  );
                }
                final rawCat = _state.categories[index - 1];
                final cat = rawCat is Map
                    ? Map<String, dynamic>.from(rawCat)
                    : <String, dynamic>{};
                final int? id = int.tryParse(cat['id']?.toString() ?? '');
                final active = _categoryId == id;
                final label = _state.formatCategoryLabel(cat);
                final asset = _state.assetForCategory(cat, label);

                return GestureDetector(
                  onTap: () {
                    if (id != null) {
                      _state.recordCategoryInterest(id, weight: 3);
                    }
                    setState(() => _categoryId = id);
                    _searchAds();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: active ? _red : _pillBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: active ? _red : _border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Image.asset(asset, fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Results Area with 2026 Shimmer Skeleton
          Expanded(
            child: _loading
                ? SearchGridSkeleton(isGrid: _gridView)
                : _ads.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEECEE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.search,
                                  size: 30,
                                  color: _red,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                s.noAdsFound,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.tr(
                                  'جرب تبدل القسم أو تبحث بكلمات أخرى',
                                  'Essayez une autre catégorie ou d\'autres mots-clés',
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 13.5,
                                ),
                              ),
                              if (_categoryId != null) ...[
                                const SizedBox(height: 14),
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() => _categoryId = null);
                                    _searchAds();
                                  },
                                  child: Text(
                                    s.tr('عرض جميع الأقسام', 'Voir toutes les catégories'),
                                    style: const TextStyle(
                                      color: _red,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: _red,
                        onRefresh: _searchAds,
                        child: _gridView
                            ? GridView.builder(
                                controller: _scrollCtrl,
                                padding:
                                    const EdgeInsets.fromLTRB(20, 4, 20, 120),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 0.72,
                                ),
                                itemCount: _ads.length + (_loadingMore ? 2 : 0),
                                itemBuilder: (context, idx) {
                                  if (idx >= _ads.length) {
                                    return const AdGridCardSkeleton();
                                  }
                                  return AdCard(
                                    ad: Map<String, dynamic>.from(_ads[idx]),
                                  );
                                },
                              )
                            : ListView.separated(
                                controller: _scrollCtrl,
                                padding:
                                    const EdgeInsets.fromLTRB(20, 4, 20, 120),
                                itemCount: _ads.length + (_loadingMore ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, idx) {
                                  if (idx >= _ads.length) {
                                    return const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: _red,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    );
                                  }
                                  return AdCard(
                                    ad: Map<String, dynamic>.from(_ads[idx]),
                                    horizontal: true,
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
