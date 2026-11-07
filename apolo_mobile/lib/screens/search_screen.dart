import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'widgets/ad_card.dart';

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
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 240) {
      if (!_loading && !_loadingMore && _currentPage < _lastPage) {
        _loadMoreAds();
      }
    }
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
          setState(() {
            _ads = res.data['data'] ?? [];
            _currentPage = int.tryParse((meta?['current_page'] ?? 1).toString()) ?? 1;
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
        final List newItems = res.data['data'] ?? [];
        final meta = res.data['meta'];
        if (mounted) {
          setState(() {
            // Deduplicate incoming items by ID
            final existingIds = _ads.map((e) => e['id']?.toString()).toSet();
            for (final it in newItems) {
              if (!existingIds.contains(it['id']?.toString())) {
                _ads.add(it);
              }
            }
            _currentPage = int.tryParse((meta?['current_page'] ?? nextPage).toString()) ?? nextPage;
            _lastPage = int.tryParse((meta?['last_page'] ?? _lastPage).toString()) ?? _lastPage;
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
        SnackBar(content: Text(_state.s.tr('يرجى تسجيل الدخول لحفظ البحث', 'Connectez-vous pour sauvegarder la recherche'))),
      );
      return;
    }
    try {
      final res = await _state.api.dio.post('/saved-searches', data: {
        'title': _queryCtrl.text.trim().isNotEmpty ? _queryCtrl.text.trim() : _state.s.tr('بحث محفوظ', 'Recherche sauvegardée'),
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
            content: Text(_state.s.tr('تم حفظ البحث! ستصلك إشعارات عند توفر إعلانات جديدة', 'Recherche sauvegardée avec alertes !')),
          ),
        );
      }
    } catch (_) {}
  }

  void _openFilterModal() {
    final s = _state.s;
    final minCtrl = TextEditingController(text: _minPrice?.toInt().toString() ?? '');
    final maxCtrl = TextEditingController(text: _maxPrice?.toInt().toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.tr('تصفية النتائج', 'Filtrer les résultats'),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.4),
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
                          style: const TextStyle(color: _red, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int?>(
                    value: _categoryId,
                    decoration: InputDecoration(labelText: s.categories),
                    items: [
                      DropdownMenuItem<int?>(value: null, child: Text(s.allCategories)),
                      ..._state.categories.map((c) => DropdownMenuItem<int?>(
                            value: int.tryParse(c['id'].toString()),
                            child: Text((s.isAr ? (c['name_ar'] ?? c['name']) : (c['name_fr'] ?? c['name'])).toString()),
                          )),
                    ],
                    onChanged: (v) => setModalState(() => _categoryId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: _cityId,
                    decoration: InputDecoration(labelText: s.tr('المدينة', 'Ville')),
                    items: [
                      DropdownMenuItem<int?>(value: null, child: Text(s.allCities)),
                      ..._state.cities.map((c) => DropdownMenuItem<int?>(
                            value: int.tryParse(c['id'].toString()),
                            child: Text((s.isAr ? (c['name_ar'] ?? c['name']) : (c['name_fr'] ?? c['name'])).toString()),
                          )),
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
                          decoration: InputDecoration(labelText: s.tr('أقل ثمن (DH)', 'Prix min (DH)')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: s.tr('أقصى ثمن (DH)', 'Prix max (DH)')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        setState(() {
                          _minPrice = double.tryParse(minCtrl.text.trim());
                          _maxPrice = double.tryParse(maxCtrl.text.trim());
                        });
                        Navigator.pop(ctx);
                        _searchAds();
                      },
                      child: Text(
                        s.tr('تطبيق الفلتر', 'Appliquer les filtres'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
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
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row (Triply oversized title + action circles)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Row(
                children: [
                  if (canPop) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _pillBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: _border),
                        ),
                        child: const Icon(CupertinoIcons.chevron_back, size: 18, color: _ink),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      s.search,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -0.6,
                        height: 1.1,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _saveCurrentSearch,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEECEE),
                        shape: BoxShape.circle,
                        border: Border.all(color: _red.withValues(alpha: 0.16)),
                      ),
                      child: const Icon(CupertinoIcons.bell, size: 19, color: _red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _gridView = !_gridView),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _pillBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: _border),
                      ),
                      child: Icon(
                        _gridView ? CupertinoIcons.list_bullet : CupertinoIcons.square_grid_2x2,
                        size: 19,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pill Search Input + Red Filter Circle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _pillBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.search, color: _muted, size: 19),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _queryCtrl,
                              onSubmitted: (_) => _searchAds(),
                              style: const TextStyle(color: _ink, fontSize: 14.5, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                hintText: s.tr('ابحث عن سيارة، عقار، هاتف...', 'Rechercher un véhicule, bien, téléphone...'),
                                hintStyle: const TextStyle(color: _muted, fontSize: 14, fontWeight: FontWeight.w500),
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
                              child: const Icon(CupertinoIcons.xmark_circle_fill, size: 18, color: _muted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _openFilterModal,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _red.withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(CupertinoIcons.slider_horizontal_3, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Category Filter Pills
            if (_state.categories.isNotEmpty)
              SizedBox(
                height: 40,
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? _red : _pillBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: active ? _red : _border),
                          ),
                          child: Text(
                            s.tr('الكل', 'Tout'),
                            style: TextStyle(
                              color: active ? Colors.white : _ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }
                    final cat = _state.categories[index - 1];
                    final id = int.tryParse(cat['id'].toString());
                    final active = _categoryId == id;
                    final label = (s.isAr ? (cat['name_ar'] ?? cat['name']) : (cat['name_fr'] ?? cat['name'])).toString();
                    return GestureDetector(
                      onTap: () {
                        setState(() => _categoryId = id);
                        _searchAds();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active ? _red : _pillBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: active ? _red : _border),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: active ? Colors.white : _ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 10),

            // Results area
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _red))
                  : _ads.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
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
                                  child: const Icon(Icons.search_off_rounded, size: 32, color: _red),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  s.tr('لا توجد إعلانات مطابقة لبحثك', 'Aucune annonce trouvée'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  s.tr('جرّب تغيير الفلتر أو البحث بكلمات أخرى', 'Essayez de modifier vos filtres de recherche'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, color: _muted),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: _red,
                          onRefresh: _searchAds,
                          child: CustomScrollView(
                            controller: _scrollCtrl,
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            slivers: [
                              if (_gridView)
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                                  sliver: SliverGrid(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 14,
                                      crossAxisSpacing: 14,
                                      childAspectRatio: 0.75,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (_, idx) => AdCard(ad: Map<String, dynamic>.from(_ads[idx])),
                                      childCount: _ads.length,
                                    ),
                                  ),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (_, idx) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: AdCard(
                                          ad: Map<String, dynamic>.from(_ads[idx]),
                                          horizontal: true,
                                        ),
                                      ),
                                      childCount: _ads.length,
                                    ),
                                  ),
                                ),
                              if (_loadingMore)
                                const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2.2, color: _red),
                                      ),
                                    ),
                                  ),
                                ),
                              const SliverToBoxAdapter(child: SizedBox(height: 100)),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
