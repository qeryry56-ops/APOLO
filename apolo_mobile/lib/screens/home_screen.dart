import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'ad_detail_screen.dart';
import 'notifications_screen.dart';
import 'post_ad_screen.dart';
import 'privacy_compliance_screen.dart';
import 'search_screen.dart';
import 'stores_screen.dart';
import 'widgets/ad_card.dart';
import 'widgets/app_image.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/skeleton_loader.dart';

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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final AppState _state = AppState();
  final PageController _trendingController = PageController(viewportFraction: 0.88);
  final ScrollController _scrollController = ScrollController();

  late final AnimationController _carFloatController;

  List<Map<String, dynamic>> _ads = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  bool _networkError = false;
  int _activeTrendingPage = 0;
  int? _selectedFeedCategoryId;
  double _scrollOffset = 0.0;
  Timer? _autoSlideTimer;

  static const Color _primary = Color(0xFFE31B23);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);

  static const List<Map<String, dynamic>> _fallbackAdsData = [
    {
      'id': 9001,
      'title': 'Porsche Macan GTS 2025 — Pack Sport Chrono',
      'description': 'État neuf, entretien maison Porsche Casablanca, garantie constructeur.',
      'price': 980000,
      'price_formatted': '980 000 DH',
      'city': {'id': 1, 'name': 'Casablanca', 'name_ar': 'الدار البيضاء', 'name_fr': 'Casablanca'},
      'category': {'id': 1, 'name': 'Véhicules', 'name_ar': 'سيارات ومركبات', 'name_fr': 'Véhicules'},
      'main_image': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=900&q=80',
      'is_featured': true,
      'is_vip': true,
      'views_count': 1420,
      'created_at': '2026-03-29T10:00:00Z',
    },
    {
      'id': 9002,
      'title': 'iPhone 16 Pro Max 256Go Titane Naturel — Scellé',
      'description': 'Neuf sous emballage Apple officiel avec garantie 12 mois.',
      'price': 14200,
      'price_formatted': '14 200 DH',
      'city': {'id': 2, 'name': 'Rabat', 'name_ar': 'الرباط', 'name_fr': 'Rabat'},
      'category': {'id': 4, 'name': 'Téléphones', 'name_ar': 'هواتف ذكية', 'name_fr': 'Téléphones'},
      'main_image': 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=900&q=80',
      'is_featured': true,
      'is_vip': false,
      'views_count': 980,
      'created_at': '2026-03-29T11:30:00Z',
    },
    {
      'id': 9003,
      'title': 'Villa Contemporaine avec Piscine — Californie',
      'description': '4 suites, jardin arboré, domotique complète, finition marbre.',
      'price': 6500000,
      'price_formatted': '6 500 000 DH',
      'city': {'id': 1, 'name': 'Casablanca', 'name_ar': 'الدار البيضاء', 'name_fr': 'Casablanca'},
      'category': {'id': 2, 'name': 'Immobilier', 'name_ar': 'عقارات', 'name_fr': 'Immobilier'},
      'main_image': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=900&q=80',
      'is_featured': true,
      'is_vip': true,
      'views_count': 2150,
      'created_at': '2026-03-28T16:15:00Z',
    },
    {
      'id': 9004,
      'title': 'MacBook Pro M4 Max 16" 64Go / 2To SSD',
      'description': 'Clavier AZERTY, 4 cycles de batterie, avec facture.',
      'price': 36500,
      'price_formatted': '36 500 DH',
      'city': {'id': 3, 'name': 'Marrakech', 'name_ar': 'مراكش', 'name_fr': 'Marrakech'},
      'category': {'id': 3, 'name': 'Informatique', 'name_ar': 'معلوميات', 'name_fr': 'Informatique'},
      'main_image': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=900&q=80',
      'is_featured': false,
      'is_vip': false,
      'views_count': 640,
      'created_at': '2026-03-29T09:20:00Z',
    },
  ];

  @override
  void initState() {
    super.initState();
    _carFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _scrollController.addListener(_onScroll);
    _loadData();
    _startAutoSlide();
  }

  void _onScroll() {
    if (!mounted) return;
    final nextOffset = _scrollController.offset.clamp(0.0, 500.0);
    if ((nextOffset - _scrollOffset).abs() > 1.5) {
      setState(() => _scrollOffset = nextOffset);
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _carFloatController.dispose();
    _trendingController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final trending = _trendingAds;
      if (!mounted || trending.length <= 1 || !_trendingController.hasClients) return;
      final next = (_activeTrendingPage + 1) % trending.length;
      _trendingController.animateToPage(
        next,
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
        final data = res.data['data'] ?? res.data;
        if (data is Map) {
          rawAds = [
            ...(data['vip_ads'] as List? ?? []),
            ...(data['featured_ads'] as List? ?? []),
            ...(data['latest_ads'] as List? ?? []),
          ];
        } else if (data is List) {
          rawAds = data;
        }
      }
      if (rawAds.isEmpty) {
        final adsRes = await _state.api.dio.get('/ads', queryParameters: {'per_page': 32});
        if (adsRes.data is Map) {
          rawAds = (adsRes.data['data'] as List?) ?? [];
        }
      }

      if (_state.categories.isEmpty) {
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
          _ads = parsedAds.isNotEmpty
              ? parsedAds
              : _fallbackAdsData.map((e) => Map<String, dynamic>.from(e)).toList();
          _categories = parsedCats.isNotEmpty ? parsedCats : _buildFallbackCategories();
          _networkError = false;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ads = _fallbackAdsData.map((e) => Map<String, dynamic>.from(e)).toList();
          _categories = _state.categories.isNotEmpty
              ? _state.categories.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
              : _buildFallbackCategories();
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _buildFallbackCategories() {
    return [
      {'id': 1, 'name': 'Véhicules', 'name_fr': 'Véhicules', 'name_ar': 'سيارات ومركبات'},
      {'id': 2, 'name': 'Immobilier', 'name_fr': 'Immobilier', 'name_ar': 'عقارات'},
      {'id': 3, 'name': 'Informatique', 'name_fr': 'Informatique', 'name_ar': 'معلوميات'},
      {'id': 4, 'name': 'Téléphones', 'name_fr': 'Téléphones', 'name_ar': 'هواتف ذكية'},
      {'id': 5, 'name': 'Maison & Déco', 'name_fr': 'Maison & Déco', 'name_ar': 'منزل وديكور'},
      {'id': 6, 'name': 'Mode & Beauté', 'name_fr': 'Mode & Beauté', 'name_ar': 'موضة وأزياء'},
      {'id': 7, 'name': 'Emploi & Pro', 'name_fr': 'Emploi & Pro', 'name_ar': 'وظائف وخدمات'},
      {'id': 8, 'name': 'Voyage', 'name_fr': 'Voyage', 'name_ar': 'أدوات السفر'},
    ];
  }

  List<Map<String, dynamic>> get _trendingAds {
    final sorted = List<Map<String, dynamic>>.from(_ads);
    sorted.sort((a, b) {
      final viewsA = int.tryParse((a['views_count'] ?? a['views'] ?? 0).toString()) ?? 0;
      final viewsB = int.tryParse((b['views_count'] ?? b['views'] ?? 0).toString()) ?? 0;
      final scoreA = (a['is_vip'] == true ? 500 : 0) + (a['is_featured'] == true ? 300 : 0) + viewsA;
      final scoreB = (b['is_vip'] == true ? 500 : 0) + (b['is_featured'] == true ? 300 : 0) + viewsB;
      return scoreB.compareTo(scoreA);
    });
    return sorted.take(6).toList();
  }

  List<Map<String, dynamic>> get _personalizedFeedAds {
    var pool = _state.rankAdsForUser(_ads);
    if (_selectedFeedCategoryId != null) {
      pool = pool
          .where((ad) => _state.adMatchesCategory(ad, _selectedFeedCategoryId))
          .toList();
    }
    return pool;
  }

  String get _userName {
    final full = _state.currentUser?['name']?.toString().trim();
    if (full != null && full.isNotEmpty) {
      return full.split(' ').first;
    }
    return _state.s.isAr ? 'أمين' : 'Amine';
  }

  void _openSearchScreen([int? categoryId]) {
    if (widget.onOpenSearch != null) {
      widget.onOpenSearch!(categoryId);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SearchScreen(initialCategoryId: categoryId)),
      );
    }
  }

  void _openPostAdScreen() {
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
    final feedAds = _personalizedFeedAds;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const HomeFeedSkeleton()
            : _networkError
                ? IllustratedStateView(
                    assetPath: 'assets/images/state_no_internet.png',
                    imageSize: 184,
                    title: isAr
                        ? 'انقطع الاتصال بالإنترنت'
                        : 'Connexion Internet interrompue',
                    subtitle: isAr
                        ? 'تحقق من الشبكة وحاول مرة أخرى لعرض أحدث العروض والإعلانات في المغرب.'
                        : 'Vérifiez votre connexion réseau et réessayez pour charger les dernières annonces.',
                    actionLabel: isAr ? 'إعادة المحاولة' : 'Réessayer',
                    onAction: () {
                      setState(() => _loading = true);
                      _loadData();
                    },
                  )
                : RefreshIndicator(
                    color: _primary,
                    backgroundColor: Colors.white,
                    onRefresh: _loadData,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        // 1. Original Top Header Row (Greeting + Notification Bell)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    isAr
                                        ? 'مرحباً، $_userName 👋'
                                        : 'Hi, $_userName 👋',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                      color: _ink,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Clean Notification Bell Button (opens NotificationsScreen, no halo circle)
                                PressableScale(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const NotificationsScreen(),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      clipBehavior: Clip.none,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.bell,
                                          size: 23,
                                          color: _ink,
                                        ),
                                        Positioned(
                                          top: 1,
                                          right: 1,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: _primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 2. Original Hero Card with Live Red + White Distribution & Giant 3D Pop-Out Car
                        SliverToBoxAdapter(
                          child: _buildHeroStage(isAr),
                        ),

                        // 3. Categories Bento Section with Staggered Scroll Reveal
                        SliverToBoxAdapter(
                          child: _buildCategoriesBento(s, isAr),
                        ),

                        // 4. Stage 1: Trending Now Carousel
                        if (trending.isNotEmpty)
                          SliverToBoxAdapter(
                            child: _buildTrendingSection(trending, isAr),
                          ),

                        // 5. Verified Pro Boutiques Strip
                        SliverToBoxAdapter(
                          child: _buildStoresBanner(isAr),
                        ),

                        // 6. Stage 2: Smart Personalized Feed Header + Category Chips
                        SliverToBoxAdapter(
                          child: _buildSmartFeedHeader(isAr),
                        ),

                        // 7. Smart Feed Grid with ScrollReveal Physics
                        if (feedAds.isEmpty)
                          SliverToBoxAdapter(
                            child: IllustratedStateView(
                              assetPath: 'assets/images/state_empty_ads.png',
                              fallbackIcon: CupertinoIcons.square_grid_2x2,
                              imageSize: 156,
                              title: isAr
                                  ? 'لا توجد إعلانات في هذا التصنيف حالياً'
                                  : 'Aucune annonce dans cette catégorie',
                              subtitle: isAr
                                  ? 'جرب اختيار تصنيف آخر أو اعرض جميع الإعلانات المقترحة لك.'
                                  : 'Essayez une autre catégorie ou affichez toutes les annonces recommandées.',
                              actionLabel: isAr ? 'عرض جميع الإعلانات' : 'Voir toutes les annonces',
                              onAction: () => setState(() => _selectedFeedCategoryId = null),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.67,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final ad = feedAds[index];
                                  final id = int.tryParse((ad['id'] ?? index).toString()) ?? index;
                                  return ScrollReveal(
                                    key: ValueKey('feed_ad_${id}_${_selectedFeedCategoryId ?? 0}'),
                                    delay: Duration(milliseconds: (index % 6) * 55),
                                    beginOffset: const Offset(0, 26),
                                    beginScale: 0.95,
                                    child: AdCard(ad: ad),
                                  );
                                },
                                childCount: feedAds.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  /// Original Hero Card with Live Red + White Color Distribution & Giant 3D Pop-Out Car
  Widget _buildHeroStage(bool isAr) {
    final s = _state.s;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Vibrant Red + Luminous White Mesh Hero Container
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFC80E16),
                  Color(0xFFE31B23),
                  Color(0xFFF42B34),
                ],
                stops: [0.0, 0.58, 1.0],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Top-End Soft Ambient Glow (above the car, NOT under the wheels!)
                PositionedDirectional(
                  end: -10,
                  top: -55,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.34),
                          Colors.white.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Subtle White Shimmer Ribbon at Top-Start
                PositionedDirectional(
                  start: -30,
                  top: -35,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 152, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.38),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      s.tr('مساعد أبولو الذكي • LIVE', 'AI Deal Planner • LIVE'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => showAiContentReportSheet(
                              context,
                              featureContext: s.tr(
                                'مساعد أبولو الذكي (AI Deal Planner)',
                                'AI Deal Planner',
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.32),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.flag_fill,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    s.tr('إبلاغ AI', 'Report AI'),
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          s.tr('بيع ولا شري فـ 30 ثانية', 'Plan your next deal'),
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.tr(
                          'قول لينا شنو باغي تبيع ولا تشري — غادي نقادو ليك كلشي.',
                          'Tell us what you want to buy or sell — we\'ll build the listing.',
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.38,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _openPostAdScreen,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                s.tr('ابدا دابا', 'Get started'),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: _primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                CupertinoIcons.arrow_right,
                                size: 14,
                                color: _primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3D Ground Contact Shadow under the Car (extending outside the card!)
          PositionedDirectional(
            end: -10,
            bottom: -16,
            width: 205,
            height: 30,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: _ink.withValues(alpha: 0.28),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Giant Photorealistic 3D SUV Coupé bursting OUTSIDE the Hero Card!
          PositionedDirectional(
            end: -22,
            bottom: -24,
            width: 232,
            height: 168,
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

  /// Categories Bento Strip with Staggered Reveal & Tactile Press
  Widget _buildCategoriesBento(AppStrings s, bool isAr) {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return ScrollReveal(
      delay: const Duration(milliseconds: 90),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'التصنيفات' : 'Catégories',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openSearchScreen(),
                    child: Row(
                      children: [
                        Text(
                          isAr ? 'عرض الكل' : 'Tout voir',
                          style: const TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          isAr ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right,
                          size: 13,
                          color: _primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 108,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final catId = int.tryParse((cat['id'] ?? 0).toString()) ?? 0;
                  final assetPath = _state.assetForCategory(cat);
                  final label = _state.formatCategoryLabel(cat);
                  final isSelected = _selectedFeedCategoryId == catId;

                  return ScrollReveal(
                    delay: Duration(milliseconds: 45 * (idx % 6)),
                    beginOffset: const Offset(18, 0),
                    child: PressableScale(
                      onTap: () {
                        _state.recordCategoryInterest(catId, weight: 3);
                        _openSearchScreen(catId);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 126,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? _primary.withValues(alpha: 0.45)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _ink.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            children: [
                              PositionedDirectional(
                                top: 10,
                                start: 12,
                                end: 10,
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                    height: 1.2,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              PositionedDirectional(
                                end: 6,
                                bottom: 4,
                                child: SizedBox(
                                  width: 68,
                                  height: 62,
                                  child: Image.asset(
                                    assetPath,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      CupertinoIcons.cube_box_fill,
                                      size: 30,
                                      color: _primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  /// Stage 1: Trending Now in Morocco
  Widget _buildTrendingSection(List<Map<String, dynamic>> trending, bool isAr) {
    return ScrollReveal(
      delay: const Duration(milliseconds: 140),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          CupertinoIcons.flame_fill,
                          size: 14,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAr ? 'الرائج الآن في المغرب' : 'Tendances au Maroc',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _openSearchScreen(),
                    child: Text(
                      isAr ? 'عرض الكل' : 'Tout voir',
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _trendingController,
                itemCount: trending.length,
                onPageChanged: (idx) => setState(() => _activeTrendingPage = idx),
                itemBuilder: (context, idx) {
                  final ad = trending[idx];
                  final adId = int.tryParse((ad['id'] ?? idx).toString()) ?? idx;
                  final title = (ad['title'] ?? '').toString();
                  final imgUrl = (ad['main_image'] ?? ad['primary_image'] ?? '').toString();
                  final cityMap = ad['city'] is Map ? ad['city'] as Map : const {};
                  final cityName = (isAr
                          ? (cityMap['name_ar'] ?? cityMap['name'] ?? 'المغرب')
                          : (cityMap['name_fr'] ?? cityMap['name'] ?? 'Maroc'))
                      .toString();
                  final priceStr = (ad['price_formatted'] ??
                          (ad['price'] != null
                              ? '${ad['price']} ${isAr ? 'د.م' : 'DH'}'
                              : ''))
                      .toString();

                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: PressableScale(
                      onTap: () {
                        final catId = _state.extractAdCategoryId(ad);
                        if (catId != null) {
                          _state.recordCategoryInterest(catId, weight: 3);
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdDetailScreen(adId: adId, initialAd: ad),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: _ink,
                          boxShadow: [
                            BoxShadow(
                              color: _ink.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AppImage(url: imgUrl, fit: BoxFit.cover),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.10),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.84),
                                    ],
                                    stops: const [0.0, 0.42, 1.0],
                                  ),
                                ),
                              ),
                              PositionedDirectional(
                                top: 12,
                                start: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        CupertinoIcons.graph_square_fill,
                                        color: Colors.white,
                                        size: 11,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isAr ? 'الأكثر طلباً' : 'Populaire',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 14,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              CupertinoIcons.location_solid,
                                              color: Colors.white70,
                                              size: 13,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              cityName,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (priceStr.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              priceStr,
                                              style: const TextStyle(
                                                color: _ink,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12.5,
                                                fontFeatures: [FontFeature.tabularFigures()],
                                              ),
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

  Widget _buildStoresBanner(bool isAr) {
    return ScrollReveal(
      delay: const Duration(milliseconds: 180),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: PressableScale(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StoresScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    CupertinoIcons.bag_fill,
                    color: _ink,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isAr ? 'المتاجر الرسمية الموثقة' : 'Boutiques Pro Vérifiées',
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            color: _primary,
                            size: 15,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAr
                            ? 'تصفح عروض الوكالات والمتاجر المضمونة في المغرب'
                            : 'Découvrez les offres des professionnels certifiés au Maroc',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isAr ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right,
                  color: _muted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Stage 2: Smart Personalized Feed Header + Quick Category Filter Pills
  Widget _buildSmartFeedHeader(bool isAr) {
    final hasInterests = _state.categoryInterestWeights.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasInterests
                          ? (isAr ? 'مقترح لك حسب اهتماماتك' : 'Recommandé pour vous')
                          : (isAr ? 'أحدث الإعلانات المختارة' : 'Sélection pour vous'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAr
                          ? 'مرتبة ذكياً حسب التصنيفات والمدن التي تهمك'
                          : 'Triées selon vos catégories et recherches récentes',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (_selectedFeedCategoryId != null)
                  TextButton(
                    onPressed: () => setState(() => _selectedFeedCategoryId = null),
                    child: Text(
                      isAr ? 'الكل' : 'Tout',
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                if (idx == 0) {
                  final selected = _selectedFeedCategoryId == null;
                  return _buildFeedChip(
                    label: isAr ? 'الكل' : 'Pour vous',
                    selected: selected,
                    onTap: () => setState(() => _selectedFeedCategoryId = null),
                  );
                }
                final cat = _categories[idx - 1];
                final catId = int.tryParse((cat['id'] ?? 0).toString()) ?? 0;
                final selected = _selectedFeedCategoryId == catId;
                return _buildFeedChip(
                  label: _state.formatCategoryLabel(cat),
                  selected: selected,
                  onTap: () {
                    _state.recordCategoryInterest(catId, weight: 2);
                    setState(() {
                      _selectedFeedCategoryId = selected ? null : catId;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _ink : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _ink : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
