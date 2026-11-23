import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import 'store_detail_screen.dart';
import 'widgets/app_image.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/skeleton_loader.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  final AppState _state = AppState();
  List<dynamic> _stores = [];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  final ScrollController _scrollCtrl = ScrollController();
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalStores = 0;
  bool _loadingMore = false;
  int _filterIndex = 0; // 0: All, 1: Most products, 2: Top rated

  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetchStores();
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 240) {
      if (!_loading && !_loadingMore && _currentPage < _lastPage) {
        _loadMoreStores();
      }
    }
  }

  Future<void> _fetchStores() async {
    setState(() {
      _loading = true;
      _currentPage = 1;
    });
    try {
      final res = await _state.api.dio.get('/stores', queryParameters: {
        if (_searchCtrl.text.trim().isNotEmpty)
          'search': _searchCtrl.text.trim(),
        'page': 1,
      });
      if (res.data is Map && res.data['status'] == 'success') {
        if (mounted) {
          final meta = res.data['meta'];
          setState(() {
            _stores = res.data['data'] ?? [];
            _currentPage =
                int.tryParse((meta?['current_page'] ?? 1).toString()) ?? 1;
            _lastPage = int.tryParse((meta?['last_page'] ?? 1).toString()) ?? 1;
            _totalStores =
                int.tryParse((meta?['total'] ?? _stores.length).toString()) ??
                    _stores.length;
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMoreStores() async {
    if (_loadingMore || _currentPage >= _lastPage) return;
    setState(() => _loadingMore = true);
    final nextPage = _currentPage + 1;
    try {
      final res = await _state.api.dio.get('/stores', queryParameters: {
        if (_searchCtrl.text.trim().isNotEmpty)
          'search': _searchCtrl.text.trim(),
        'page': nextPage,
      });
      if (res.data is Map && res.data['status'] == 'success') {
        final List newItems = res.data['data'] ?? [];
        final meta = res.data['meta'];
        if (mounted) {
          setState(() {
            final existingIds = _stores.map((e) => e['id']?.toString()).toSet();
            for (final it in newItems) {
              if (!existingIds.contains(it['id']?.toString())) {
                _stores.add(it);
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

  List<dynamic> get _visibleStores {
    final list = List<dynamic>.from(_stores);
    if (_filterIndex == 1) {
      list.sort((a, b) {
        final ca = int.tryParse(
                (a['active_products_count'] ?? a['ads_count'] ?? 0)
                    .toString()) ??
            0;
        final cb = int.tryParse(
                (b['active_products_count'] ?? b['ads_count'] ?? 0)
                    .toString()) ??
            0;
        return cb.compareTo(ca);
      });
    } else if (_filterIndex == 2) {
      list.sort((a, b) {
        final ra =
            double.tryParse((a['average_rating'] ?? 5).toString()) ?? 5.0;
        final rb =
            double.tryParse((b['average_rating'] ?? 5).toString()) ?? 5.0;
        return rb.compareTo(ra);
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final canPop = Navigator.canPop(context);
    final visible = _visibleStores;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clean Centered-Style Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  if (canPop) ...[
                    PressableScale(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          s.isAr
                              ? CupertinoIcons.chevron_right
                              : CupertinoIcons.chevron_left,
                          size: 20,
                          color: _ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.stores,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            letterSpacing:
                                AppTypography.trackingForContext(context, -0.4),
                            height: AppTypography.lineHeightForContext(
                              context,
                              1.15,
                              arabicMin: 1.32,
                            ),
                          ),
                        ),
                        if (_totalStores > 0)
                          Text(
                            s.tr(
                              '$_totalStores متجر رسمي موثق في المغرب',
                              '$_totalStores boutiques officielles vérifiées',
                              '$_totalStores verified official stores',
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _ink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.checkmark_seal_fill,
                            size: 13.5, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                            letterSpacing:
                                AppTypography.trackingForContext(context, 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Clean White Pill Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.only(left: 14, right: 6),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.search, color: _muted, size: 19),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onSubmitted: (_) => _fetchStores(),
                        style: const TextStyle(
                            color: _ink,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: s.tr('ابحث عن متجر احترافي معتمد...',
                              'Rechercher une boutique officielle...'),
                          hintStyle: const TextStyle(
                              color: _muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          _fetchStores();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            CupertinoIcons.clear_circled_solid,
                            color: _muted,
                            size: 18,
                          ),
                        ),
                      ),
                    PressableScale(
                      onTap: _fetchStores,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: _ink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.arrow_left_right,
                            size: 15, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filter Pills Strip
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterPill(0, s.tr('الكل', 'Toutes', 'All')),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      1,
                      s.tr('الأكثر منتجات', 'Plus de produits', 'Most products'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      2,
                      s.tr('الأعلى تقييماً ⭐', 'Mieux notées ⭐', 'Top rated ⭐'),
                    ),
                  ],
                ),
              ),
            ),

            // Store Cards List
            Expanded(
              child: _loading
                  ? const StoresListSkeleton()
                  : visible.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.storefront_rounded,
                                    size: 32, color: _ink),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                s.tr('لا توجد متاجر مطابقة حالياً',
                                    'Aucune boutique trouvée'),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _ink),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: _ink,
                          backgroundColor: Colors.white,
                          onRefresh: _fetchStores,
                          child: ListView.separated(
                            controller: _scrollCtrl,
                            physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                            itemCount: visible.length + (_loadingMore ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              if (idx >= visible.length) {
                                return const StoreCardSkeleton();
                              }
                              final store = visible[idx];
                              final logo = store['logo_url'] ?? store['logo'];
                              final location =
                                  (store['location'] ?? '').toString().trim();
                              final rating =
                                  (store['average_rating'] ?? 5).toString();
                              final int count = int.tryParse(
                                      (store['active_products_count'] ??
                                              store['ads_count'] ??
                                              0)
                                          .toString()) ??
                                  0;
                              return PressableScale(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StoreDetailScreen(
                                          subdomain:
                                              store['subdomain'].toString()),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Row(
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(2.5),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: _border, width: 1.2),
                                            ),
                                            child: AppAvatar(
                                              url: logo?.toString(),
                                              radius: 30,
                                              fallbackIcon:
                                                  Icons.storefront_rounded,
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: _ink,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 2),
                                              ),
                                              child: const Icon(
                                                  Icons.check_rounded,
                                                  size: 12,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    (store['name'] ?? '')
                                                        .toString(),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 16,
                                                      color: _ink,
                                                      letterSpacing: AppTypography
                                                          .trackingForContext(
                                                              context, -0.3),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      CupertinoIcons.star_fill,
                                                      size: 12,
                                                      color: Color(0xFFF59E0B),
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      rating,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: _ink,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            if (location.isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    CupertinoIcons
                                                        .location_solid,
                                                    size: 11.5,
                                                    color: _muted,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Expanded(
                                                    child: Text(
                                                      location,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 11.5,
                                                        color: _muted,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            if ((store['description'] ?? '')
                                                .toString()
                                                .trim()
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                (store['description'] ?? '')
                                                    .toString(),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: _muted,
                                                    fontSize: 12.5,
                                                    height: 1.35),
                                              ),
                                            ],
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFF2F3F7),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                          CupertinoIcons
                                                              .cube_box,
                                                          size: 12.5,
                                                          color: _ink),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '$count ${s.tr('منتج', 'produits')}',
                                                        style: const TextStyle(
                                                            color: _ink,
                                                            fontSize: 11.5,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: _ink,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        s.tr('زيارة المتجر',
                                                            'Visiter'),
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11.5,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700),
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Icon(
                                                        s.isAr
                                                            ? CupertinoIcons
                                                                .chevron_left
                                                            : CupertinoIcons
                                                                .chevron_right,
                                                        size: 11.5,
                                                        color: Colors.white,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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

  Widget _buildFilterPill(int index, String label) {
    final active = _filterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _filterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _ink : Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : _ink,
          ),
        ),
      ),
    );
  }
}
