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

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    _searchAds();
  }

  Future<void> _searchAds() async {
    setState(() => _loading = true);
    try {
      final params = <String, dynamic>{
        if (_queryCtrl.text.trim().isNotEmpty) 'query': _queryCtrl.text.trim(),
        if (_categoryId != null) 'category_id': _categoryId,
        if (_cityId != null) 'city_id': _cityId,
        if (_minPrice != null) 'price_min': _minPrice,
        if (_maxPrice != null) 'price_max': _maxPrice,
      };
      final res = await _state.api.dio.get('/ads', queryParameters: params);
      if (res.data is Map && res.data['status'] == 'success') {
        if (mounted) {
          setState(() {
            _ads = res.data['data'] ?? [];
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.tr('تصفية النتائج', 'Filtrer les résultats'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _categoryId = null;
                            _cityId = null;
                            minCtrl.clear();
                            maxCtrl.clear();
                          });
                        },
                        child: Text(s.tr('إعادة تعيين', 'Réinitialiser')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _minPrice = double.tryParse(minCtrl.text.trim());
                          _maxPrice = double.tryParse(maxCtrl.text.trim());
                        });
                        Navigator.pop(ctx);
                        _searchAds();
                      },
                      child: Text(s.tr('تطبيق الفلتر', 'Appliquer')),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(s.search),
        actions: [
          IconButton(
            tooltip: s.tr('حفظ البحث وتفعيل التنبيهات', 'Sauvegarder la recherche'),
            onPressed: _saveCurrentSearch,
            icon: const Icon(Icons.notifications_active_outlined),
          ),
          IconButton(
            onPressed: () => setState(() => _gridView = !_gridView),
            icon: Icon(_gridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryCtrl,
                    onSubmitted: (_) => _searchAds(),
                    decoration: InputDecoration(
                      hintText: s.tr('ابحث عن أي منتج أو خدمة...', 'Rechercher un produit ou service...'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _queryCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _queryCtrl.clear();
                                _searchAds();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _openFilterModal,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppConfig.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _ads.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(s.tr('لا توجد إعلانات مطابقة لبحثك', 'Aucune annonce trouvée')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _searchAds,
                        child: _gridView
                            ? GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.76,
                                ),
                                itemCount: _ads.length,
                                itemBuilder: (_, idx) => AdCard(ad: Map<String, dynamic>.from(_ads[idx])),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _ads.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (_, idx) => AdCard(
                                  ad: Map<String, dynamic>.from(_ads[idx]),
                                  horizontal: true,
                                ),
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
