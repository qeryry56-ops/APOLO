import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/apolo_badges_kit.dart';
import '../widgets/dl_settings_kit.dart';
import 'business_switch_screen.dart';
import 'store_detail_screen.dart';
import 'widgets/app_image.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/skeleton_loader.dart';

/// Dynamic Layer v5.1 Verified Official Stores Directory:
/// - Pure `#FFFFFF` canvas + `#EEEEEE` `40×40` circular back button
/// - `46px` `#EEEEEE` stadium search bar (`1.5px` `#000000` active border)
/// - `#000000` / `#EEEEEE` capsule filter pills (`All` / `Most products` / `Top rated`)
/// - Flat `#F6F6F6` rounded `22px` store cards with `ApoloVerifiedBadge` + `ApoloRankBadge`
class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  final AppState _state = AppState();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  List<dynamic> _stores = [];
  bool _loading = true;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalStores = 0;
  bool _loadingMore = false;
  int _filterIndex = 0; // 0: All, 1: Most products, 2: Top rated

  // Strict Dynamic Layer v5.1 Palette Tokens
  Color get _dlBg => ApoloDlPalette.of(context).bg;
  Color get _dlSurface => ApoloDlPalette.of(context).surfaceSubtle;
  Color get _dlPill => ApoloDlPalette.of(context).pill;
  Color get _dlSeparator => ApoloDlPalette.of(context).separator;
  Color get _dlInk => ApoloDlPalette.of(context).ink;
  Color get _dlOnInk => ApoloDlPalette.of(context).onInk;
  Color get _dlMuted => ApoloDlPalette.of(context).muted;
  static const Color _dlStarAmber = Color(0xFFFFB800);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _searchFocus.addListener(_onFocusChange);
    _searchCtrl.addListener(_onFocusChange);
    _fetchStores();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchFocus.removeListener(_onFocusChange);
    _searchFocus.dispose();
    _searchCtrl.removeListener(_onFocusChange);
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
              (a['active_products_count'] ?? a['ads_count'] ?? 0).toString(),
            ) ??
            0;
        final cb = int.tryParse(
              (b['active_products_count'] ?? b['ads_count'] ?? 0).toString(),
            ) ??
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
    final searchFocused = _searchFocus.hasFocus;

    return Directionality(
      textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _dlBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dynamic Layer v5.1 Top Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    if (canPop) ...[
                      ApoloDlIconCircleButton(
                        key: const Key('stores-back-button'),
                        icon: s.isAr
                            ? CupertinoIcons.chevron_right
                            : CupertinoIcons.chevron_left,
                        backgroundColor: _dlPill,
                        iconColor: _dlInk,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.stores,
                            key: const Key('stores-header-title'),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _dlInk,
                              letterSpacing: AppTypography.trackingForContext(
                                context,
                                -0.4,
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
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _dlMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _dlInk,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ApoloVerifiedBadge(size: 14),
                          SizedBox(width: 5),
                          Text(
                            'PRO',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              color: _dlOnInk,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Dynamic Layer v5.1 Stadium Search Pill
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  height: 46,
                  decoration: BoxDecoration(
                    color: _dlPill,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: searchFocused ? _dlInk : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.search,
                        color: searchFocused ? _dlInk : _dlMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          key: const Key('stores-search-field'),
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          cursorColor: _dlInk,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _fetchStores(),
                          style: TextStyle(
                            color: _dlInk,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: s.tr(
                              'ابحث عن متجر احترافي معتمد...',
                              'Rechercher une boutique officielle...',
                              'Search official stores...',
                            ),
                            hintStyle: TextStyle(
                              color: _dlMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            fillColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _searchCtrl.clear();
                            _fetchStores();
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              CupertinoIcons.xmark,
                              color: _dlMuted,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Capsule Filter Pills
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterPill(0, s.tr('الكل', 'Toutes', 'All')),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        1,
                        s.tr(
                          'الأكثر منتجات',
                          'Plus de produits',
                          'Most products',
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        2,
                        s.tr('الأعلى تقييماً', 'Mieux notées', 'Top rated'),
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
                        ? ApoloDlEmptyState(
                            icon: Icons.storefront_rounded,
                            headline: s.tr(
                              'لا توجد متاجر مطابقة حالياً',
                              'Aucune boutique trouvée',
                              'No matching stores',
                            ),
                            description: s.tr(
                              'جرب البحث بكلمة أخرى أو إعادة تحميل قائمة المتاجر المعتمدة.',
                              'Essayez un autre mot-clé ou actualisez la liste des boutiques.',
                              'Try another keyword or reload the verified stores list.',
                            ),
                            actionLabel: s.tr(
                              'إعادة المحاولة',
                              'Réessayer',
                              'Try again',
                            ),
                            onAction: () {
                              _searchCtrl.clear();
                              _fetchStores();
                            },
                          )
                        : RefreshIndicator(
                            color: _dlInk,
                            backgroundColor: _dlBg,
                            onRefresh: _fetchStores,
                            child: ListView.separated(
                              controller: _scrollCtrl,
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 120),
                              itemCount:
                                  visible.length + (_loadingMore ? 1 : 0),
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
                                          .toString(),
                                    ) ??
                                    0;
                                final isProPlus = store['is_pro_plus'] == true;
                                final isVerified =
                                    store['is_verified'] == true ||
                                        store['verified'] == true ||
                                        isProPlus;
                                final rank = ApoloSellerRank.resolve(
                                  user: store,
                                  listingsCount: count,
                                  isProPlus: isProPlus,
                                  isBusiness: true,
                                  isVerified: isVerified,
                                );

                                return PressableScale(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StoreDetailScreen(
                                          subdomain:
                                              store['subdomain'].toString(),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _dlSurface,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(color: _dlSeparator),
                                    ),
                                    child: Row(
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: _dlBg,
                                                shape: BoxShape.circle,
                                              ),
                                              child: AppAvatar(
                                                url: logo?.toString(),
                                                radius: 30,
                                                fallbackIcon:
                                                    Icons.storefront_rounded,
                                              ),
                                            ),
                                            PositionedDirectional(
                                              bottom: -1,
                                              end: -1,
                                              child: ApoloVerifiedBadge(
                                                size: 19,
                                                rank: rank,
                                                isProPlus: isProPlus,
                                                isBusiness: true,
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
                                                            FontWeight.w700,
                                                        fontSize: 16,
                                                        color: _dlInk,
                                                        letterSpacing:
                                                            AppTypography
                                                                .trackingForContext(
                                                          context,
                                                          -0.3,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  ApoloRankBadge(
                                                    rank: rank,
                                                    size: 18,
                                                    interactive: true,
                                                    isVerified: isVerified,
                                                    isProPlus: isProPlus,
                                                    isBusiness: true,
                                                  ),
                                                  if (isProPlus) ...[
                                                    const SizedBox(width: 5),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 7,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _dlInk,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(999),
                                                      ),
                                                      child: Text(
                                                        'PRO+',
                                                        textDirection:
                                                            TextDirection.ltr,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: _dlOnInk,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                  const SizedBox(width: 6),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        CupertinoIcons
                                                            .star_fill,
                                                        size: 12,
                                                        color: _dlStarAmber,
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        rating,
                                                        textDirection:
                                                            TextDirection.ltr,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: _dlInk,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              if ((store['business_category'] ??
                                                      '')
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  ApoloBusinessCategories
                                                      .labelFor(
                                                    store['business_category']
                                                        ?.toString(),
                                                    s,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: _dlMuted,
                                                  ),
                                                ),
                                              ],
                                              if (location.isNotEmpty) ...[
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      CupertinoIcons
                                                          .location_solid,
                                                      size: 11.5,
                                                      color: _dlMuted,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Expanded(
                                                      child: Text(
                                                        location,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 11.5,
                                                          color: _dlMuted,
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: _dlMuted,
                                                    fontSize: 12.5,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Flexible(
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _dlBg,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(999),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            CupertinoIcons
                                                                .cube_box,
                                                            size: 12.5,
                                                            color: _dlInk,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Flexible(
                                                            child: Text(
                                                              '$count ${s.tr('منتج', 'produits', 'items')}',
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  TextStyle(
                                                                color: _dlInk,
                                                                fontSize: 11.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _dlInk,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        999,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          s.tr(
                                                            'زيارة المتجر',
                                                            'Visiter',
                                                            'Visit',
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              TextStyle(
                                                            color: _dlOnInk,
                                                            fontSize: 11.5,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 3,
                                                        ),
                                                        Icon(
                                                          s.isAr
                                                              ? CupertinoIcons
                                                                  .chevron_left
                                                              : CupertinoIcons
                                                                  .chevron_right,
                                                          size: 11.5,
                                                          color: _dlOnInk,
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
      ),
    );
  }

  Widget _buildFilterPill(int index, String label) {
    final active = _filterIndex == index;
    return Material(
      color: active ? _dlInk : _dlPill,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filterIndex = index);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? _dlBg : _dlInk,
            ),
          ),
        ),
      ),
    );
  }
}
