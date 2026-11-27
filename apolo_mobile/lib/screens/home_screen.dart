import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/apolo_badges_kit.dart';
import '../widgets/dl_settings_kit.dart';
import '../widgets/notification_badge.dart';
import 'notifications_screen.dart';
import 'post_ad_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'stores_screen.dart';
import 'widgets/accommodation_card.dart';
import 'widgets/app_image.dart';
import 'widgets/explore_listing_card.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/marketplace_zone_sheet.dart';
import 'widgets/skeleton_loader.dart';

/// Dynamic Layer v5.1 Home Screen:
/// - Pure #FFFFFF canvas + #F6F6F6 flat cards + #EEEEEE pills + #000000 primary CTAs
/// - 44x44 #EEEEEE profile avatar + Name (+ Verified/Rank badges when logged in) + Location + 40x40 #EEEEEE Bell
/// - 1-tap #EEEEEE Quick Search trigger pill opening Dynamic Layer Search Suggestions
/// - Monochrome #F6F6F6 Hero Showcase Stage with static 3D car & #000000 capsule CTA
/// - Flat #F6F6F6 Categories Bento with #FFFFFF 3D icon circles
/// - Exclusive Deals Carousel (AccommodationCard) + Latest Listings Feed (ExploreListingCard)
/// - Why Choose Apolo (#F6F6F6 grouped list) + #000000 Post Ad CTA + Verified Official Stores card
class HomeScreen extends StatefulWidget {
  final void Function(int? categoryId)? onOpenSearch;
  final VoidCallback? onOpenPostAd;

  const HomeScreen({
    super.key,
    this.onOpenSearch,
    this.onOpenPostAd,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppState _state = AppState();
  final ScrollController _trendingScrollController = ScrollController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _ads = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  bool _networkError = false;
  int _activeTrendingPage = 0;
  double _trendingStride = 318.0;
  Timer? _autoSlideTimer;

  // Dynamic Layer v5.1 Strict Palette Tokens
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
    _state.addListener(_onStateChanged);
    _state.tabReselectCounter.addListener(_scrollToTop);
    _loadData();
    _startAutoSlide();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _state.tabReselectCounter.removeListener(_scrollToTop);
    _autoSlideTimer?.cancel();
    _scrollController.dispose();
    _trendingScrollController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final trending = _trendingAds;
      if (!mounted ||
          trending.length <= 1 ||
          !_trendingScrollController.hasClients) {
        return;
      }
      final next = (_activeTrendingPage + 1) % trending.length;
      final targetOffset = (next * _trendingStride).clamp(
        0.0,
        _trendingScrollController.position.maxScrollExtent,
      );
      _trendingScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 650),
        curve: const Cubic(0.22, 1.0, 0.36, 1.0),
      );
    });
  }

  Future<void> _loadData() async {
    try {
      final res = await _state.api.dio.get('/home');
      List<dynamic> rawAds = [];
      if (res.data is Map) {
        final data = res.data;
        rawAds = [
          ...(data['vip_ads'] as List? ?? []),
          ...(data['featured_ads'] as List? ?? []),
          ...(data['latest_ads'] as List? ?? []),
        ];
      }

      if (rawAds.length < 24) {
        try {
          final adsRes = await _state.api.dio
              .get('/ads', queryParameters: {'per_page': 36});
          if (adsRes.data is Map) {
            final more = (adsRes.data['data'] as List?) ?? [];
            final existingIds =
                rawAds.whereType<Map>().map((a) => a['id']?.toString()).toSet();
            for (final item in more) {
              if (item is Map &&
                  !existingIds.contains(item['id']?.toString())) {
                rawAds.add(item);
              }
            }
          }
        } catch (_) {}
      }

      if (_state.categories.isEmpty || _state.cities.isEmpty) {
        await _state.fetchTaxonomy();
      }

      final parsedAds = rawAds
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final parsedCats = _state.categories
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (mounted) {
        setState(() {
          _ads = parsedAds;
          _categories = parsedCats;
          _networkError = false;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _networkError = _ads.isEmpty;
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _trendingAds {
    final sorted = List<Map<String, dynamic>>.from(_ads);
    sorted.sort((a, b) {
      final viewsA =
          int.tryParse((a['views_count'] ?? a['views'] ?? 0).toString()) ?? 0;
      final viewsB =
          int.tryParse((b['views_count'] ?? b['views'] ?? 0).toString()) ?? 0;
      final scoreA = (a['is_vip'] == true ? 500 : 0) +
          (a['is_featured'] == true ? 300 : 0) +
          viewsA;
      final scoreB = (b['is_vip'] == true ? 500 : 0) +
          (b['is_featured'] == true ? 300 : 0) +
          viewsB;
      return scoreB.compareTo(scoreA);
    });
    return sorted.take(6).toList();
  }

  List<Map<String, dynamic>> get _feedAds {
    final ranked = _state.rankAdsForUser(_ads);
    if (ranked.isEmpty) return const [];
    final trendingIds =
        _trendingAds.map((e) => (e['id'] ?? '').toString()).toSet();
    final fresh = ranked
        .where((ad) => !trendingIds.contains((ad['id'] ?? '').toString()))
        .toList();
    final pool = fresh.isNotEmpty ? fresh : ranked;
    return _state.applyZoneToAds(pool, enforceRadiusFilter: true);
  }

  String get _userName {
    final full = _state.currentUser?['name']?.toString().trim();
    if (full != null && full.isNotEmpty) {
      return full.split(' ').first;
    }
    return '';
  }

  String get _userFullName {
    final full = _state.currentUser?['name']?.toString().trim();
    if (full != null && full.isNotEmpty) {
      return full;
    }
    return '';
  }

  String get _userAvatarUrl {
    final user = _state.currentUser;
    if (user == null) return '';
    return (user['avatar'] ??
            user['photo'] ??
            user['profile_photo_url'] ??
            user['avatar_url'] ??
            '')
        .toString()
        .trim();
  }

  String get _userInitials {
    final full = _userFullName;
    if (full.isEmpty) return 'AP';
    final parts =
        full.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first.characters.take(2).toString().toUpperCase();
  }

  void _openSearchScreen([int? categoryId, bool startActive = false]) {
    HapticFeedback.selectionClick();
    if (widget.onOpenSearch != null && !startActive) {
      widget.onOpenSearch!(categoryId);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchScreen(
            initialCategoryId: categoryId,
            initialSearchActive: startActive,
          ),
        ),
      );
    }
  }

  void _openPostAdScreen() {
    HapticFeedback.lightImpact();
    if (widget.onOpenPostAd != null) {
      widget.onOpenPostAd!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostAdScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final trending = _trendingAds;
    final feedAds = _feedAds;
    final user = _state.currentUser;
    final isVerifiedUser = user != null &&
        (user['is_verified'] == true ||
            user['verified'] == true ||
            _state.isProPlusAccount ||
            _state.isBusinessAccount);

    return Scaffold(
      key: const Key('dl-home-screen'),
      backgroundColor: _dlBg,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const HomeFeedSkeleton()
            : _networkError
                ? IllustratedStateView(
                    assetPath: 'assets/images/state_no_internet.png',
                    imageSize: 184,
                    title: _state.s.tr(
                      'انقطع الاتصال بالإنترنت',
                      'Connexion Internet interrompue',
                      'Internet connection lost',
                    ),
                    subtitle: _state.s.tr(
                      'تحقق من الشبكة وحاول مرة أخرى لعرض أحدث العروض والإعلانات في المغرب.',
                      'Vérifiez votre connexion réseau et réessayez pour charger les annonces.',
                      'Check your network connection and try again to load listings.',
                    ),
                    actionLabel:
                        _state.s.tr('إعادة المحاولة', 'Réessayer', 'Try again'),
                    onAction: () {
                      setState(() => _loading = true);
                      _loadData();
                    },
                  )
                : RefreshIndicator(
                    color: _dlInk,
                    backgroundColor: _dlBg,
                    onRefresh: _loadData,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 680;
                        return CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            // 1. Dynamic Layer v5.1 Top Header Row (44x44 #EEEEEE Avatar + Name + Location + 40x40 #EEEEEE Bell)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    PressableScale(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ProfileScreen(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _dlPill,
                                          shape: BoxShape.circle,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        alignment: Alignment.center,
                                        child: _userAvatarUrl.isNotEmpty
                                            ? AppImage(
                                                url: _userAvatarUrl,
                                                width: 44,
                                                height: 44,
                                                fit: BoxFit.cover,
                                              )
                                            : (_userName.isNotEmpty
                                                ? Text(
                                                    _userInitials,
                                                    style: TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: _dlInk,
                                                    ),
                                                  )
                                                : Icon(
                                                    CupertinoIcons.person_fill,
                                                    size: 20,
                                                    color: _dlInk,
                                                  )),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  _userFullName.isEmpty
                                                      ? s.tr(
                                                          'مرحباً بك في Apolo',
                                                          'Bienvenue sur Apolo',
                                                          'Welcome to Apolo',
                                                        )
                                                      : _userFullName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: AppTypography
                                                        .trackingForContext(
                                                      context,
                                                      -0.25,
                                                    ),
                                                    color: _dlInk,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ),
                                              if (isVerifiedUser) ...[
                                                const SizedBox(width: 5),
                                                const ApoloVerifiedBadge(
                                                  size: 16,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          GestureDetector(
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              showMarketplaceZoneSheet(context);
                                            },
                                            behavior: HitTestBehavior.opaque,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  CupertinoIcons.location_solid,
                                                  size: 12.5,
                                                  color: _dlInk,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    _state.hasActiveZone
                                                        ? _state
                                                            .activeZoneBadgeLabel(
                                                            s,
                                                          )
                                                        : _state
                                                            .activeZoneCityLabel(
                                                            s,
                                                          ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: _dlMuted,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 3),
                                                Icon(
                                                  CupertinoIcons.chevron_down,
                                                  size: 11,
                                                  color: _dlMuted,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // 40x40 #EEEEEE Dynamic Layer Notification Bell Circle
                                    PressableScale(
                                      key: const Key('home-notifications-bell'),
                                      onTap: () {
                                        _state
                                            .clearUnreadNotificationsOptimistically(
                                          syncRemote: false,
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const NotificationsScreen(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _dlPill,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: NotificationBadge(
                                          count:
                                              _state.unreadNotificationsCount,
                                          type: NotificationBadgeType.number,
                                          variant: NotificationBadgeVariant.red,
                                          top: -7,
                                          right: -9,
                                          child: Icon(
                                            CupertinoIcons.bell_fill,
                                            size: 19,
                                            color: _dlInk,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 2. Dynamic Layer v5.1 Quick Search Trigger Pill (`46px`, `#EEEEEE`)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 10, 20, 2),
                                child: PressableScale(
                                  key: const Key('dl-home-search-pill'),
                                  onTap: () => _openSearchScreen(null, true),
                                  child: Container(
                                    height: 46,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _dlPill,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.search,
                                          size: 19,
                                          color: _dlMuted,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            s.tr(
                                              'ابحث عن سيارات، عقارات، هواتف أو حسابات...',
                                              'Rechercher voitures, immo, téléphones...',
                                              'Search cars, homes, phones, or accounts...',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w400,
                                              color: _dlSubtle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 3. Dynamic Layer v5.1 Hero Stage (`#F6F6F6` flat card + `#000000` CTA + static 3D car)
                            SliverToBoxAdapter(
                              child: _buildHeroStage(isAr),
                            ),

                            // 4. Clean `#F6F6F6` Categories Bento Strip
                            SliverToBoxAdapter(
                              child: _buildCategoriesBento(s, isAr),
                            ),

                            // 5. Exclusive Deals Showcase Carousel
                            if (trending.isNotEmpty)
                              SliverToBoxAdapter(
                                child: _buildTrendingSection(trending, isAr),
                              ),

                            // 6. Explore-Style Listings Feed directly beneath Exclusive Deals
                            if (feedAds.isNotEmpty || _ads.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 4, 20, 12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            Text(
                                              s.tr(
                                                'أحدث الإعلانات',
                                                'Dernières annonces',
                                                'Latest listings',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 18.5,
                                                fontWeight: FontWeight.w800,
                                                color: _dlInk,
                                                letterSpacing: AppTypography
                                                    .trackingForContext(
                                                  context,
                                                  -0.35,
                                                ),
                                              ),
                                            ),
                                            MarketplaceZonePill(
                                              state: _state,
                                              compact: true,
                                              onTap: () =>
                                                  showMarketplaceZoneSheet(
                                                context,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _openSearchScreen(null),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _dlPill,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            s.tr(
                                              'عرض الكل',
                                              'Tout voir',
                                              'See all',
                                            ),
                                            style: TextStyle(
                                              color: _dlInk,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (feedAds.isEmpty)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      0,
                                      20,
                                      20,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: _dlSurface,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.tr(
                                              'لا توجد إعلانات في نطاق ${_state.zoneRadiusKm.round()} كم من ${_state.activeZoneCityLabel(s)} حالياً',
                                              'Aucune annonce dans un rayon de ${_state.zoneRadiusKm.round()} km autour de ${_state.activeZoneCityLabel(s)}',
                                              'No listings within ${_state.zoneRadiusKm.round()} km of ${_state.activeZoneCityLabel(s)} yet',
                                            ),
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: _dlInk,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              PressableScale(
                                                onTap: () =>
                                                    _state.clearZoneFilter(),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 14,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _dlInk,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      999,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    s.tr(
                                                      'عرض كل المغرب',
                                                      'Tout le Maroc',
                                                      'Show all Morocco',
                                                    ),
                                                    style: TextStyle(
                                                      color: _dlOnInk,
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              PressableScale(
                                                onTap: () =>
                                                    showMarketplaceZoneSheet(
                                                  context,
                                                ),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 14,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _dlBg,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      999,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    s.tr(
                                                      'تغيير المنطقة',
                                                      'Changer de zone',
                                                      'Change zone',
                                                    ),
                                                    style: TextStyle(
                                                      color: _dlInk,
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              else if (isWide)
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    20,
                                  ),
                                  sliver: SliverGrid.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 400,
                                      mainAxisExtent: 374,
                                      mainAxisSpacing: 18,
                                      crossAxisSpacing: 18,
                                    ),
                                    itemCount: feedAds.length,
                                    itemBuilder: (context, idx) {
                                      final ad = feedAds[idx];
                                      return RepaintBoundary(
                                        key: ValueKey('home_wide_${ad['id']}'),
                                        child: ExploreListingCard(ad: ad),
                                      );
                                    },
                                  ),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    20,
                                  ),
                                  sliver: SliverList.separated(
                                    itemCount: feedAds.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 16),
                                    itemBuilder: (context, idx) {
                                      final ad = feedAds[idx];
                                      return RepaintBoundary(
                                        key: ValueKey(
                                          'home_explore_${ad['id']}',
                                        ),
                                        child: ExploreListingCard(ad: ad),
                                      );
                                    },
                                  ),
                                ),
                            ],

                            // 7. Browse All Listings Capsule CTA (`#000000`)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 4, 20, 22),
                                child: ApoloDlButton(
                                  label: _state.s.tr(
                                    'تصفح الإعلانات في المغرب',
                                    'Explorer toutes les annonces au Maroc',
                                    'Browse all listings in Morocco',
                                  ),
                                  leadingIcon: CupertinoIcons.search,
                                  variant: ApoloDlButtonVariant.primary,
                                  borderRadius: 999,
                                  height: 52,
                                  fullWidth: true,
                                  onPressed: () => _openSearchScreen(null),
                                ),
                              ),
                            ),

                            // 8. Why Choose Apolo (`#F6F6F6` grouped list)
                            SliverToBoxAdapter(
                              child: _buildAppOverview(isAr),
                            ),

                            // 9. Seller Call-To-Action Card (`#000000` capsule card)
                            SliverToBoxAdapter(
                              child: _buildSellerBanner(isAr),
                            ),

                            // 10. Verified Official Stores Card (`#F6F6F6` + ApoloVerifiedBadge)
                            SliverToBoxAdapter(
                              child: _buildStoresBanner(isAr),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 132),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  /// Dynamic Layer v5.1 Hero Showcase Card (`#F6F6F6` flat card, `#000000` CTA, static 3D car)
  Widget _buildHeroStage(bool isAr) {
    final s = _state.s;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            key: const Key('dl-home-hero-card'),
            width: double.infinity,
            decoration: BoxDecoration(
              color: _dlSurface,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 138, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tagline pill (pure Text child — no Row sibling dot)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _dlBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _state.s.tr(
                      'سوقك الأول فالمغرب 🇲🇦',
                      'Marketplace #1 au Maroc 🇲🇦',
                      '#1 Marketplace in Morocco 🇲🇦',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _dlInk,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _state.s.tr(
                    'بيع واشري بأمان وبلا وسيط',
                    'Achetez et vendez en toute sécurité',
                    'Buy and sell safely without middlemen',
                  ),
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing:
                        AppTypography.trackingForContext(context, -0.4),
                    color: _dlInk,
                    height: 1.24,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _state.s.tr(
                    'طوموبيلات، هواتف وعقارات. اكتشف الإعلانات القريبة منك.',
                    'Voitures, smartphones, immobilier près de chez vous.',
                    'Cars, phones, real estate. Discover listings near you.',
                  ),
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.38,
                    fontWeight: FontWeight.w400,
                    color: _dlMuted,
                  ),
                ),
                const SizedBox(height: 14),
                PressableScale(
                  onTap: () => _openSearchScreen(null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9.5,
                    ),
                    decoration: BoxDecoration(
                      color: _dlInk,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _state.s.tr(
                              'استكشف الإعلانات',
                              'Explorer les annonces',
                              'Explore listings',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _dlOnInk,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          isAr
                              ? CupertinoIcons.arrow_left
                              : CupertinoIcons.arrow_right,
                          size: 13,
                          color: _dlOnInk,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Crisp Static 3D Car
          PositionedDirectional(
            end: -4,
            bottom: -6,
            width: 172,
            height: 122,
            child: IgnorePointer(
              child: Transform.flip(
                flipX: s.isAr,
                child: Image.asset(
                  'assets/images/hero_car.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dynamic Layer v5.1 Categories Bento Strip (`#F6F6F6` cards with `#FFFFFF` icon circles)
  Widget _buildCategoriesBento(AppStrings s, bool isAr) {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return ScrollReveal(
      delay: const Duration(milliseconds: 90),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _state.s.tr(
                        'تصفح حسب الفئات',
                        'Catégories',
                        'Categories',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: _dlInk,
                        letterSpacing:
                            AppTypography.trackingForContext(context, -0.35),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _openSearchScreen(null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _dlPill,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _state.s.tr('عرض الكل', 'Tout voir', 'See all'),
                        style: TextStyle(
                          color: _dlInk,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 108,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final catId = int.tryParse((cat['id'] ?? 0).toString()) ?? 0;
                  final assetPath = _state.assetForCategory(cat);
                  final label = _state.formatCategoryLabel(cat);

                  return PressableScale(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _state.recordCategoryInterest(catId, weight: 3);
                      _openSearchScreen(catId);
                    },
                    child: Container(
                      width: 88,
                      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                      decoration: BoxDecoration(
                        color: _dlSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _dlBg,
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              assetPath,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) => Icon(
                                CupertinoIcons.cube_box,
                                size: 22,
                                color: _dlMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _dlInk,
                              height: AppTypography.lineHeightForContext(
                                context,
                                1.15,
                                arabicMin: 1.25,
                              ),
                            ),
                          ),
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
  }

  /// Exclusive Deals Horizontal Carousel using AccommodationCard
  Widget _buildTrendingSection(
    List<Map<String, dynamic>> trending,
    bool isAr,
  ) {
    return ScrollReveal(
      delay: const Duration(milliseconds: 110),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _state.s.tr(
                        'عروض حصرية مميزة',
                        'Offres exclusives',
                        'Exclusive Deals',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: _dlInk,
                        letterSpacing:
                            AppTypography.trackingForContext(context, -0.35),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: List.generate(trending.length, (i) {
                      final active = i == _activeTrendingPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: active ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? _dlInk : _dlPill,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth.isFinite &&
                        constraints.maxWidth > 0
                    ? constraints.maxWidth
                    : MediaQuery.sizeOf(context).width;
                final cardWidth = (availableWidth * 0.78).clamp(240.0, 360.0);
                final cardHeight = cardWidth / 0.84;
                const gap = 14.0;
                _trendingStride = cardWidth + gap;

                return SizedBox(
                  height: cardHeight,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification &&
                          _trendingStride > 0 &&
                          _trendingScrollController.hasClients) {
                        final nextPage = (_trendingScrollController.offset /
                                _trendingStride)
                            .round()
                            .clamp(0, trending.length - 1);
                        if (nextPage != _activeTrendingPage && mounted) {
                          setState(() => _activeTrendingPage = nextPage);
                        }
                      }
                      return false;
                    },
                    child: ListView.separated(
                      controller: _trendingScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: trending.length,
                      separatorBuilder: (_, __) => const SizedBox(width: gap),
                      itemBuilder: (context, idx) {
                        return SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: AccommodationCard(ad: trending[idx]),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Dynamic Layer v5.1 Overview Section (`#F6F6F6` grouped card)
  Widget _buildAppOverview(bool isAr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _state.s.tr(
              'علاش تختار Apolo؟',
              'Pourquoi choisir Apolo ?',
              'Why choose Apolo?',
            ),
            style: TextStyle(
              fontSize: 18.5,
              fontWeight: FontWeight.w800,
              color: _dlInk,
              letterSpacing: AppTypography.trackingForContext(context, -0.35),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _dlSurface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                _buildOverviewRow(
                  icon: CupertinoIcons.tag_fill,
                  title: _state.s.tr(
                    '\u20660%\u2069 عمولة وبالمجان',
                    '0% Commission',
                    '0% Commission & Free',
                  ),
                  subtitle: _state.s.tr(
                    'بيع وشري فابور بدون أي اقتطاعات أو وسطاء.',
                    'Vendez et achetez gratuitement sans aucun intermédiaire.',
                    'Buy and sell for free with zero middlemen.',
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: ApoloDlSeparator(),
                ),
                _buildOverviewRow(
                  icon: CupertinoIcons.chat_bubble_2_fill,
                  title: _state.s.tr(
                    'شات واتصال مباشر',
                    'Discussion directe',
                    'Direct Chat & Call',
                  ),
                  subtitle: _state.s.tr(
                    'تواصل فالحين مع البائع وقدم عرض سعر بضغطة وحدة.',
                    'Discutez en direct avec le vendeur et négociez le prix.',
                    'Message the seller directly and make an offer in one tap.',
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: ApoloDlSeparator(),
                ),
                _buildOverviewRow(
                  icon: CupertinoIcons.checkmark_shield_fill,
                  title: _state.s.tr(
                    'إعلانات مفحوصة وموثقة',
                    'Annonces vérifiées',
                    'Verified Listings',
                  ),
                  subtitle: _state.s.tr(
                    'فحص مستمر للإعلانات لحماية جميع المعاملات.',
                    'Contrôle continu pour des transactions en toute sécurité.',
                    'Continuous review to keep all transactions safe.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _dlBg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: _dlInk, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _dlInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: _dlMuted,
                  height: 1.38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Dynamic Layer v5.1 Seller Post Card (Pure `#000000` card + `#FFFFFF` CTA pill)
  Widget _buildSellerBanner(bool isAr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: PressableScale(
        onTap: _openPostAdScreen,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _dlInk,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _dlOnInk.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  CupertinoIcons.plus,
                  color: _dlOnInk,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _state.s.tr(
                        'عندك ما تبيع؟ انشر إعلانك دابا',
                        'Un article à vendre ? Publiez maintenant',
                        'Got something to sell? Post now',
                      ),
                      style: TextStyle(
                        color: _dlOnInk,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _state.s.tr(
                        'انشر فـ 30 ثانية بالمجان وتوصل باتصالات المشترين',
                        'Publiez gratuitement et recevez des offres rapidement',
                        'Publish free in 30 seconds and get buyer inquiries fast',
                      ),
                      style: TextStyle(
                        color: _dlOnInk.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _dlBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _state.s.tr('نشر +', 'Publier +', 'Post +'),
                  style: TextStyle(
                    color: _dlInk,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dynamic Layer v5.1 Verified Official Stores Card (`#F6F6F6` + `ApoloVerifiedBadge`)
  Widget _buildStoresBanner(bool isAr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: PressableScale(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StoresScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _dlSurface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _dlBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  CupertinoIcons.bag_fill,
                  color: _dlInk,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _state.s.tr(
                              'المتاجر الرسمية الموثقة',
                              'Boutiques Pro Vérifiées',
                              'Verified Official Stores',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _dlInk,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              letterSpacing: AppTypography.trackingForContext(
                                context,
                                -0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const ApoloVerifiedBadge(size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _state.s.tr(
                        'تصفح عروض الوكالات والمتاجر المعتمدة في المغرب',
                        'Découvrez les offres des professionnels certifiés',
                        'Browse deals from certified stores and agencies',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _dlMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _dlBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  isAr
                      ? CupertinoIcons.chevron_left
                      : CupertinoIcons.chevron_right,
                  color: _dlInk,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
