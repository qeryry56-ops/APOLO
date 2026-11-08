import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'widgets/ad_card.dart';
import 'widgets/kinetic_widgets.dart';
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
  final ScrollController _scrollCtrl = ScrollController();

  int? _categoryId;
  int? _cityId;
  double? _minPrice;
  double? _maxPrice;
  bool _onlyNegotiable = false;
  String _sortBy = 'smart'; // 'smart' | 'newest' | 'price_asc' | 'popular'

  List<Map<String, dynamic>> _ads = [];
  bool _loading = true;
  bool _gridView = true;

  int _currentPage = 1;
  int _lastPage = 1;
  bool _loadingMore = false;

  // Apple Whitespace & Brand Tokens
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _red = Color(0xFFE31B23);
  static const Color _redSoft = Color(0xFFFEECEE);
  static const Color _surface = Color(0xFFF5F6F8);
  static const Color _emerald = Color(0xFF10B981);

  static const List<Map<String, dynamic>> _fallbackShowcaseAds = [
    {
      'id': 9001,
      'title': 'Porsche Macan GTS 2025 — Pack Sport Chrono',
      'description':
          'État neuf, entretien maison Porsche Casablanca, garantie constructeur.',
      'price': 980000,
      'price_formatted': '980 000 DH',
      'negotiable': true,
      'city_id': 1,
      'category_id': 1,
      'city': {
        'id': 1,
        'name': 'Casablanca',
        'name_ar': 'الدار البيضاء',
        'name_fr': 'Casablanca',
      },
      'category': {
        'id': 1,
        'name': 'Véhicules',
        'name_ar': 'وسائل النقل',
        'name_fr': 'Véhicules',
      },
      'main_image':
          'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=900&q=80',
      'is_featured': true,
      'is_vip': true,
      'views_count': 1420,
      'created_at': '2026-03-29T12:00:00Z',
    },
    {
      'id': 9007,
      'title': 'Volkswagen Golf 8 R-Line TDI Automatique — 2024',
      'description':
          'Première main, toit ouvrant panoramique, caméra 360, état irréprochable.',
      'price': 345000,
      'price_formatted': '345 000 DH',
      'negotiable': true,
      'city_id': 2,
      'category_id': 1,
      'city': {
        'id': 2,
        'name': 'Rabat',
        'name_ar': 'الرباط',
        'name_fr': 'Rabat',
      },
      'category': {
        'id': 1,
        'name': 'Véhicules',
        'name_ar': 'وسائل النقل',
        'name_fr': 'Véhicules',
      },
      'main_image':
          'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=900&q=80',
      'is_featured': false,
      'is_vip': false,
      'views_count': 870,
      'created_at': '2026-03-29T10:30:00Z',
    },
    {
      'id': 9003,
      'title': 'Villa Contemporaine avec Piscine — Californie',
      'description':
          '4 suites, jardin arboré, domotique complète, finition marbre.',
      'price': 6500000,
      'price_formatted': '6 500 000 DH',
      'negotiable': false,
      'city_id': 1,
      'category_id': 2,
      'city': {
        'id': 1,
        'name': 'Casablanca',
        'name_ar': 'الدار البيضاء',
        'name_fr': 'Casablanca',
      },
      'category': {
        'id': 2,
        'name': 'Immobilier',
        'name_ar': 'عقارات',
        'name_fr': 'Immobilier',
      },
      'main_image':
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=900&q=80',
      'is_featured': true,
      'is_vip': true,
      'views_count': 2150,
      'created_at': '2026-03-28T16:15:00Z',
    },
    {
      'id': 9008,
      'title': 'Appartement Haut Standing 135m² — Vue Mer Tanger',
      'description':
          '3 chambres, terrasse ensoleillée, parking sous-sol, résidence fermée.',
      'price': 1850000,
      'price_formatted': '1 850 000 DH',
      'negotiable': true,
      'city_id': 4,
      'category_id': 2,
      'city': {
        'id': 4,
        'name': 'Tanger',
        'name_ar': 'طنجة',
        'name_fr': 'Tanger',
      },
      'category': {
        'id': 2,
        'name': 'Immobilier',
        'name_ar': 'عقارات',
        'name_fr': 'Immobilier',
      },
      'main_image':
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=900&q=80',
      'is_featured': false,
      'is_vip': false,
      'views_count': 740,
      'created_at': '2026-03-28T14:00:00Z',
    },
    {
      'id': 9002,
      'title': 'iPhone 16 Pro Max 256Go Titane Naturel — Scellé',
      'description':
          'Neuf sous emballage Apple officiel avec garantie 12 mois.',
      'price': 14200,
      'price_formatted': '14 200 DH',
      'negotiable': true,
      'city_id': 2,
      'category_id': 4,
      'city': {
        'id': 2,
        'name': 'Rabat',
        'name_ar': 'الرباط',
        'name_fr': 'Rabat',
      },
      'category': {
        'id': 4,
        'name': 'Téléphones',
        'name_ar': 'هواتف وتقنية',
        'name_fr': 'Téléphones',
      },
      'main_image':
          'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=900&q=80',
      'is_featured': true,
      'is_vip': false,
      'views_count': 980,
      'created_at': '2026-03-29T11:30:00Z',
    },
    {
      'id': 9004,
      'title': 'MacBook Pro M4 Max 16" 64Go / 2To SSD',
      'description': 'Clavier AZERTY, 4 cycles de batterie, avec facture.',
      'price': 36500,
      'price_formatted': '36 500 DH',
      'negotiable': true,
      'city_id': 3,
      'category_id': 3,
      'city': {
        'id': 3,
        'name': 'Marrakech',
        'name_ar': 'مراكش',
        'name_fr': 'Marrakech',
      },
      'category': {
        'id': 3,
        'name': 'Informatique',
        'name_ar': 'إعلاميات وتقنية',
        'name_fr': 'Informatique',
      },
      'main_image':
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=900&q=80',
      'is_featured': false,
      'is_vip': false,
      'views_count': 640,
      'created_at': '2026-03-29T09:20:00Z',
    },
    {
      'id': 9005,
      'title': 'Salon Marocain Moderne en Velours Royal — 3 Pièces',
      'description':
          'Bois de hêtre massif, mousse HR haute densité, état neuf.',
      'price': 18500,
      'price_formatted': '18 500 DH',
      'negotiable': true,
      'city_id': 1,
      'category_id': 5,
      'city': {
        'id': 1,
        'name': 'Casablanca',
        'name_ar': 'الدار البيضاء',
        'name_fr': 'Casablanca',
      },
      'category': {
        'id': 5,
        'name': 'Maison & Déco',
        'name_ar': 'أثاث وديكور',
        'name_fr': 'Maison & Déco',
      },
      'main_image':
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=900&q=80',
      'is_featured': false,
      'is_vip': false,
      'views_count': 510,
      'created_at': '2026-03-29T08:00:00Z',
    },
    {
      'id': 9006,
      'title': 'Montre Automatique Chronographe Acier — Édition Limitée',
      'description':
          'Boîte et certificats d\'origine inclus, jamais portée.',
      'price': 9400,
      'price_formatted': '9 400 DH',
      'negotiable': true,
      'city_id': 4,
      'category_id': 6,
      'city': {
        'id': 4,
        'name': 'Tanger',
        'name_ar': 'طنجة',
        'name_fr': 'Tanger',
      },
      'category': {
        'id': 6,
        'name': 'Mode & Beauté',
        'name_ar': 'أزياء وجمال',
        'name_fr': 'Mode & Beauté',
      },
      'main_image':
          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=900&q=80',
      'is_featured': false,
      'is_vip': true,
      'views_count': 790,
      'created_at': '2026-03-29T07:30:00Z',
    },
  ];

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

    // Merge fallback showcase ads so categories always have rich listings
    final existingIds = mapped.map((e) => e['id']?.toString()).toSet();
    for (final fb in _fallbackShowcaseAds) {
      if (!existingIds.contains(fb['id'].toString())) {
        mapped.add(Map<String, dynamic>.from(fb));
      }
    }

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
      final priceVal =
          double.tryParse((ad['price'] ?? 0).toString()) ?? 0.0;
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
        _ads = _filterAndSortAds(const []);
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

  Future<void> _saveCurrentSearch() async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(
              CupertinoIcons.bell_solid,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _state.s.tr(
                  'تم تفعيل التنبيه! غادي نعلموك غير يتحط إعلان جديد فهاد البحث 🔔',
                  'Alerte activée ! Vous serez notifié des nouvelles annonces 🔔',
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (!_state.isLoggedIn) return;
    try {
      await _state.api.dio.post('/saved-searches', data: {
        'title': _queryCtrl.text.trim().isNotEmpty
            ? _queryCtrl.text.trim()
            : _state.s.tr('بحث محفوظ', 'Recherche sauvegardée'),
        'query': _queryCtrl.text.trim(),
        'category_id': _categoryId,
        'city_id': _cityId,
        'price_min': _minPrice,
        'price_max': _maxPrice,
      });
    } catch (_) {}
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
                          s.tr('تصفية وترتيب الإعلانات', 'Filtrer les annonces'),
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
                            keyboardType: TextInputType.number,
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

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final canPop = Navigator.of(context).canPop();
    final activeCat = _activeCategoryObj();
    final activeCity = _activeCityName(s);
    final filterCount = _activeFilterCount;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Minimalist Apple Top Header + Back + Alert Bell + Grid/List Toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeCat != null
                              ? _state.formatCategoryLabel(activeCat)
                              : s.tr('استكشف الإعلانات', 'Explorer les annonces'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: _ink,
                          ),
                        ),
                        if (activeCity != null)
                          Text(
                            '📍 $activeCity',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _red,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _SoftIconBtn(
                    icon: CupertinoIcons.bookmark,
                    iconColor: _red,
                    onTap: _saveCurrentSearch,
                  ),
                  const SizedBox(width: 8),
                  _SoftIconBtn(
                    icon: _gridView
                        ? CupertinoIcons.list_bullet
                        : CupertinoIcons.square_grid_2x2,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _gridView = !_gridView);
                    },
                  ),
                ],
              ),
            ),

            // 2. Soft Borderless Search Bar + Filter Button with Badge
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
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
                              onChanged: (_) {
                                setState(() {
                                  _ads = _filterAndSortAds(_ads);
                                });
                              },
                              onSubmitted: (_) => _searchAds(),
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: _ink,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: s.searchHint,
                                hintStyle: const TextStyle(
                                  color: _muted,
                                  fontSize: 13.5,
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
                  PressableScale(
                    onTap: _openFilterModal,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: filterCount > 0 ? _red : _ink,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            CupertinoIcons.slider_horizontal_3,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                        if (filterCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _ink,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$filterCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Harmonious Horizontal 3D Category Pills
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _effectiveCategories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final active = _categoryId == null;
                    return PressableScale(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _categoryId = null);
                        _searchAds();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active ? _ink : _surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          s.tr('جميع الأقسام', 'Toutes'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: active ? Colors.white : _ink,
                          ),
                        ),
                      ),
                    );
                  }
                  final cat = _effectiveCategories[index - 1];
                  final int? id = int.tryParse(cat['id']?.toString() ?? '');
                  final active = _categoryId == id;
                  final label = _state.formatCategoryLabel(cat);
                  final asset = _state.assetForCategory(cat, label);

                  return PressableScale(
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
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                        color: active ? _redSoft : _surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active ? _red : Colors.transparent,
                          width: 1.4,
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
                              fontWeight: FontWeight.w800,
                              color: active ? _red : _ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. Quick Sort Strip & Live Results Count
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_ads.length} ${s.tr('إعلان متوفر', 'annonces')}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: _muted,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Row(
                    children: [
                      _SortMiniPill(
                        label: s.tr('الذكي ✨', 'Pour vous ✨'),
                        active: _sortBy == 'smart',
                        onTap: () => setState(() {
                          _sortBy = 'smart';
                          _ads = _filterAndSortAds(_ads);
                        }),
                      ),
                      const SizedBox(width: 6),
                      _SortMiniPill(
                        label: s.tr('الأرخص', 'Prix ↑'),
                        active: _sortBy == 'price_asc',
                        onTap: () => setState(() {
                          _sortBy = 'price_asc';
                          _ads = _filterAndSortAds(_ads);
                        }),
                      ),
                      const SizedBox(width: 6),
                      _SortMiniPill(
                        label: s.tr('الأكثر طلباً', 'Populaire'),
                        active: _sortBy == 'popular',
                        onTap: () => setState(() {
                          _sortBy = 'popular';
                          _ads = _filterAndSortAds(_ads);
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 5. Results Grid / List with 3D Empty State
            Expanded(
              child: _loading
                  ? SearchGridSkeleton(isGrid: _gridView)
                  : _ads.isEmpty
                      ? IllustratedStateView(
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
                        )
                      : RefreshIndicator(
                          color: _red,
                          backgroundColor: Colors.white,
                          onRefresh: _searchAds,
                          child: _gridView
                              ? GridView.builder(
                                  controller: _scrollCtrl,
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    6,
                                    20,
                                    120,
                                  ),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
                                    childAspectRatio: 0.69,
                                  ),
                                  itemCount:
                                      _ads.length + (_loadingMore ? 2 : 0),
                                  itemBuilder: (context, idx) {
                                    if (idx >= _ads.length) {
                                      return const AdGridCardSkeleton();
                                    }
                                    final ad = _ads[idx];
                                    return ScrollReveal(
                                      key: ValueKey(
                                        'search_grid_${ad['id']}_$_sortBy',
                                      ),
                                      delay: Duration(
                                        milliseconds: (idx % 6) * 45,
                                      ),
                                      beginOffset: const Offset(0, 18),
                                      child: AdCard(ad: ad),
                                    );
                                  },
                                )
                              : ListView.separated(
                                  controller: _scrollCtrl,
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    6,
                                    20,
                                    120,
                                  ),
                                  itemCount:
                                      _ads.length + (_loadingMore ? 1 : 0),
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
                                      ad: _ads[idx],
                                      horizontal: true,
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftIconBtn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _SoftIconBtn({
    required this.icon,
    this.iconColor = const Color(0xFF0F172A),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6F8),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _SortMiniPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SortMiniPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F172A) : const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : const Color(0xFF64748B),
          ),
        ),
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
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
    );
  }
}
