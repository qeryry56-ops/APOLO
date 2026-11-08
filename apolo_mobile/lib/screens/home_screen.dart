import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'ad_detail_screen.dart';
import 'notifications_screen.dart';
import 'post_ad_screen.dart';
import 'search_screen.dart';
import 'stores_screen.dart';
import 'widgets/app_image.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/skeleton_loader.dart';

/// 2026 Apple Whitespace Home Screen:
/// - Concise Gateway & Overview of Apolo ("نبذة عن التطبيق")
/// - Search Bar removed from Home (users are guided directly to the dedicated Search screen)
/// - Static & elegantly-scaled 3D Hero Car (no float/wobble motion)
/// - Categories Bento: 1-tap deep link to the dedicated Search/Annonces screen
/// - Featured & Trending Deals Carousel with "عرض جميع الإعلانات" CTA
/// - "علاش تختار Apolo؟" Trust & Overview highlights (0% عمولة، شات مباشر، حسابات موثقة)
/// - 1-tap Seller CTA Banner to Post Ads
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
  final PageController _trendingController =
      PageController(viewportFraction: 0.89);
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _ads = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  bool _networkError = false;
  int _activeTrendingPage = 0;
  Timer? _autoSlideTimer;

  static const Color _primary = Color(0xFFE31B23);
  static const Color _primarySoft = Color(0xFFFEECEE);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _surface = Color(0xFFF5F6F8);

  static const List<Map<String, dynamic>> _fallbackAdsData = [
    {
      'id': 9001,
      'title': 'Porsche Macan GTS 2025 — Pack Sport Chrono',
      'description':
          'État neuf, entretien maison Porsche Casablanca, garantie constructeur.',
      'price': 980000,
      'price_formatted': '980 000 DH',
      'negotiable': true,
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
      'created_at': '2026-03-29T10:00:00Z',
    },
    {
      'id': 9002,
      'title': 'iPhone 16 Pro Max 256Go Titane Naturel — Scellé',
      'description':
          'Neuf sous emballage Apple officiel avec garantie 12 mois.',
      'price': 14200,
      'price_formatted': '14 200 DH',
      'negotiable': true,
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
      'id': 9003,
      'title': 'Villa Contemporaine avec Piscine — Californie',
      'description':
          '4 suites, jardin arboré, domotique complète, finition marbre.',
      'price': 6500000,
      'price_formatted': '6 500 000 DH',
      'negotiable': false,
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
      'id': 9004,
      'title': 'Montre Rolex Submariner Date — Full Set 2024',
      'description':
          'Acier Oystersteel, lunette Cerachrom noire, boîte et papiers d\'origine.',
      'price': 138000,
      'price_formatted': '138 000 DH',
      'negotiable': true,
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
    _loadData();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _scrollController.dispose();
    _trendingController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final trending = _trendingAds;
      if (!mounted ||
          trending.length <= 1 ||
          !_trendingController.hasClients) {
        return;
      }
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
        final adsRes = await _state.api.dio
            .get('/ads', queryParameters: {'per_page': 32});
        if (adsRes.data is Map) {
          rawAds = (adsRes.data['data'] as List?) ?? [];
        }
      }

      if (_state.categories.isEmpty || _state.cities.isEmpty) {
        await _state.fetchTaxonomy();
      }

      final parsedAds = rawAds
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (parsedAds.length < 6) {
        final existingIds =
            parsedAds.map((a) => a['id']?.toString()).toSet();
        for (final fb in _fallbackAdsData) {
          if (!existingIds.contains(fb['id'].toString())) {
            parsedAds.add(Map<String, dynamic>.from(fb));
          }
        }
      }

      final parsedCats = _state.categories
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (mounted) {
        setState(() {
          _ads = parsedAds.isNotEmpty
              ? parsedAds
              : _fallbackAdsData
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
          _categories =
              parsedCats.isNotEmpty ? parsedCats : _buildFallbackCategories();
          _networkError = false;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ads = _fallbackAdsData
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _categories = _state.categories.isNotEmpty
              ? _state.categories
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : _buildFallbackCategories();
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _buildFallbackCategories() {
    return [
      {
        'id': 1,
        'name': 'Véhicules',
        'name_fr': 'Véhicules',
        'name_ar': 'وسائل النقل',
      },
      {
        'id': 2,
        'name': 'Immobilier',
        'name_fr': 'Immobilier',
        'name_ar': 'عقارات',
      },
      {
        'id': 3,
        'name': 'Informatique',
        'name_fr': 'Informatique',
        'name_ar': 'إعلاميات وتقنية',
      },
      {
        'id': 4,
        'name': 'Téléphones',
        'name_fr': 'Téléphones',
        'name_ar': 'هواتف وتقنية',
      },
      {
        'id': 5,
        'name': 'Maison & Déco',
        'name_fr': 'Maison & Déco',
        'name_ar': 'أثاث وديكور',
      },
      {
        'id': 6,
        'name': 'Mode & Beauté',
        'name_fr': 'Mode & Beauté',
        'name_ar': 'أزياء وجمال',
      },
      {
        'id': 7,
        'name': 'Emploi & Pro',
        'name_fr': 'Emploi & Pro',
        'name_ar': 'وظائف وخدمات',
      },
      {
        'id': 8,
        'name': 'Voyage',
        'name_fr': 'Voyage',
        'name_ar': 'أدوات السفر',
      },
    ];
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

  String get _userName {
    final full = _state.currentUser?['name']?.toString().trim();
    if (full != null && full.isNotEmpty) {
      return full.split(' ').first;
    }
    return _state.s.isAr ? 'أمين' : 'Amine';
  }

  void _openSearchScreen([int? categoryId]) {
    HapticFeedback.selectionClick();
    if (widget.onOpenSearch != null) {
      widget.onOpenSearch!(categoryId);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchScreen(initialCategoryId: categoryId),
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
                        : 'Vérifiez votre connexion réseau et réessayez pour charger les annonces.',
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
                        // 1. Top Header Row (Greeting + Notification Bell)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
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
                                      fontSize: 27,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.6,
                                      color: _ink,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                PressableScale(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationsScreen(),
                                    ),
                                  ),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                        width: 1.0,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      clipBehavior: Clip.none,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.bell,
                                          size: 21,
                                          color: _ink,
                                        ),
                                        if (_state.unreadNotificationsCount > 0)
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

                        // 2. Hero Card with Static 3D Car & Clear Gateway CTA
                        SliverToBoxAdapter(
                          child: _buildHeroStage(isAr),
                        ),

                        // 3. Clean Categories Bento Strip (Direct Deep Link to Search Screen)
                        SliverToBoxAdapter(
                          child: _buildCategoriesBento(s, isAr),
                        ),

                        // 4. Featured / Exclusive Deals Showcase Carousel
                        if (trending.isNotEmpty)
                          SliverToBoxAdapter(
                            child: _buildTrendingSection(trending, isAr),
                          ),

                        // 5. Explore All Ads Button Bar (Gateway to Search/Annonces Screen)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            child: PressableScale(
                              onTap: () => _openSearchScreen(null),
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: _ink,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _ink.withValues(alpha: 0.16),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.search,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isAr
                                          ? 'تصفح جميع الإعلانات في المغرب (3,400+)'
                                          : 'Explorer toutes les annonces au Maroc',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      isAr
                                          ? CupertinoIcons.arrow_left
                                          : CupertinoIcons.arrow_right,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 6. Nobda / Overview Section: "علاش تختار Apolo؟"
                        SliverToBoxAdapter(
                          child: _buildAppOverview(isAr),
                        ),

                        // 7. Seller Call-To-Action Banner: "عندك ما تبيع؟"
                        SliverToBoxAdapter(
                          child: _buildSellerBanner(isAr),
                        ),

                        // 8. Verified Pro Boutiques Strip
                        SliverToBoxAdapter(
                          child: _buildStoresBanner(isAr),
                        ),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 110),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  /// Clean Hero Showcase Card:
  /// - Scaled, non-overlapping static 3D car (`hero_car.png`)
  /// - Zero movement/float animation (`MATKOCH KATHARK`)
  /// - Clear CTA directing to the dedicated Search screen
  Widget _buildHeroStage(bool isAr) {
    final s = _state.s;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Vibrant Red Gradient Container
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFC80E16),
                  Color(0xFFE31B23),
                  Color(0xFFEA2E37),
                ],
                stops: [0.0, 0.58, 1.0],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.30),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                PositionedDirectional(
                  end: -10,
                  top: -55,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.30),
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(20, 18, 140, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAr
                                  ? 'سوقك الأول فالمغرب 🇲🇦'
                                  : 'Marketplace #1 au Maroc 🇲🇦',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isAr
                            ? 'بيع واشري بأمان وبلا وسيط'
                            : 'Achetez et vendez en toute sécurité',
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAr
                            ? 'طوموبيلات، هواتف، عقارات وأكثر من 3,000 إعلان بين يديك.'
                            : 'Voitures, smartphones, immobilier et plus de 3 000 annonces.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                      const SizedBox(height: 14),
                      PressableScale(
                        onTap: () => _openSearchScreen(null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
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
                                isAr ? 'استكشف الإعلانات' : 'Explorer les annonces',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: _primary,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(
                                isAr
                                    ? CupertinoIcons.arrow_left
                                    : CupertinoIcons.arrow_right,
                                size: 13,
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

          // Ground Contact Shadow under the 3D Car
          PositionedDirectional(
            end: 4,
            bottom: -6,
            width: 156,
            height: 20,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: _ink.withValues(alpha: 0.24),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scaled Static 3D Car (Crisp, Stable, No Continuous Motion)
          PositionedDirectional(
            end: -6,
            bottom: -8,
            width: 178,
            height: 126,
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

  /// Categories Bento Strip: 1-Tap Deep Link to Dedicated Search/Annonces Screen
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
                  Text(
                    isAr ? 'تصفح حسب الفئات' : 'Catégories',
                    style: const TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openSearchScreen(null),
                    child: Row(
                      children: [
                        Text(
                          isAr ? 'عرض الكل' : 'Tout voir',
                          style: const TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          isAr
                              ? CupertinoIcons.chevron_left
                              : CupertinoIcons.chevron_right,
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
              height: 110,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final catId =
                      int.tryParse((cat['id'] ?? 0).toString()) ?? 0;
                  final assetPath = _state.assetForCategory(cat);
                  final label = _state.formatCategoryLabel(cat);

                  return ScrollReveal(
                    delay: Duration(milliseconds: 35 * (idx % 6)),
                    beginOffset: const Offset(16, 0),
                    child: PressableScale(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _state.recordCategoryInterest(catId, weight: 3);
                        _openSearchScreen(catId);
                      },
                      child: Container(
                        width: 86,
                        padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: Image.asset(
                                assetPath,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => const Icon(
                                  CupertinoIcons.cube_box,
                                  size: 26,
                                  color: _muted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                                height: 1.15,
                              ),
                            ),
                          ],
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

  /// Featured & Trending Deals Carousel
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
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.flame_fill,
                        color: _primary,
                        size: 19,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAr ? 'عروض حصرية مميزة' : 'Offres exclusives',
                        style: const TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: List.generate(trending.length, (i) {
                      final active = i == _activeTrendingPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: active ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? _primary : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 216,
              child: PageView.builder(
                controller: _trendingController,
                itemCount: trending.length,
                onPageChanged: (idx) =>
                    setState(() => _activeTrendingPage = idx),
                itemBuilder: (context, idx) {
                  final ad = trending[idx];
                  final adId =
                      int.tryParse((ad['id'] ?? idx).toString()) ?? idx;
                  final title = (ad['title'] ?? '').toString();
                  final imgUrl =
                      (ad['main_image'] ?? ad['primary_image'] ?? '').toString();
                  final cityMap =
                      ad['city'] is Map ? ad['city'] as Map : const {};
                  final cityName = (isAr
                          ? (cityMap['name_ar'] ??
                              cityMap['name'] ??
                              'المغرب')
                          : (cityMap['name_fr'] ??
                              cityMap['name'] ??
                              'Maroc'))
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
                            builder: (_) =>
                                AdDetailScreen(adId: adId, initialAd: ad),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
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
                          borderRadius: BorderRadius.circular(24),
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
                                      Colors.black.withValues(alpha: 0.12),
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
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        CupertinoIcons.checkmark_seal_fill,
                                        color: Colors.white,
                                        size: 11,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isAr ? 'مميز VIP' : 'VIP',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                                fontSize: 12.5,
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
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              priceStr,
                                              style: const TextStyle(
                                                color: _primary,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12.5,
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

  /// Overview Section: "علاش تختار Apolo؟"
  Widget _buildAppOverview(bool isAr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'علاش تختار Apolo؟' : 'Pourquoi choisir Apolo ?',
            style: const TextStyle(
              fontSize: 18.5,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: Column(
              children: [
                _buildOverviewRow(
                  icon: CupertinoIcons.tag_fill,
                  iconColor: _primary,
                  title: isAr ? '0% عمولة وبالمجان' : '0% Commission',
                  subtitle: isAr
                      ? 'بيع وشري فابور بدون أي اقتطاعات أو وسطاء.'
                      : 'Vendez et achetez gratuitement sans aucun intermédiaire.',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                ),
                _buildOverviewRow(
                  icon: CupertinoIcons.chat_bubble_2_fill,
                  iconColor: const Color(0xFF2563EB),
                  title: isAr ? 'شات واتصال مباشر' : 'Discussion directe',
                  subtitle: isAr
                      ? 'تواصل فالحين مع البائع وقدم عرض سعر بضغطة وحدة.'
                      : 'Discutez en direct avec le vendeur et négociez le prix.',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                ),
                _buildOverviewRow(
                  icon: CupertinoIcons.checkmark_shield_fill,
                  iconColor: const Color(0xFF10B981),
                  title: isAr ? 'إعلانات مفحوصة وموثقة' : 'Annonces vérifiées',
                  subtitle: isAr
                      ? 'فحص مستمر للإعلانات لحماية جميع المعاملات.'
                      : 'Contrôle continu pour des transactions en toute sécurité.',
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
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: _muted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Seller Banner: "عندك ما تبيع؟"
  Widget _buildSellerBanner(bool isAr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: PressableScale(
        onTap: _openPostAdScreen,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  CupertinoIcons.plus_circle_fill,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'عندك ما تبيع؟ انشر إعلانك دابا'
                          : 'Un article à vendre ? Publiez maintenant',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAr
                          ? 'انشر فـ 30 ثانية بالمجان وتوصل باتصالات المشترين'
                          : 'Publiez gratuitement et recevez des offres rapidement',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isAr ? 'نشر +' : 'Publier +',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Official Boutiques / Stores Banner
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
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: _primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.bag_fill,
                  color: _primary,
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
                            isAr
                                ? 'المتاجر الرسمية الموثقة'
                                : 'Boutiques Pro Vérifiées',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: _primary,
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAr
                          ? 'تصفح عروض الوكالات والمتاجر المعتمدة في المغرب'
                          : 'Découvrez les offres des professionnels certifiés',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isAr
                    ? CupertinoIcons.chevron_left
                    : CupertinoIcons.chevron_right,
                color: _muted,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
