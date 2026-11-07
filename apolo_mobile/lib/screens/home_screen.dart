import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/state/app_state.dart';
import 'ad_detail_screen.dart';
import 'privacy_compliance_screen.dart';
import 'stores_screen.dart';
import 'widgets/ad_card.dart';
import 'widgets/app_image.dart';
import 'widgets/skeleton_loader.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int? categoryId) onOpenSearch;
  final VoidCallback? onOpenPostAd;

  const HomeScreen({
    super.key,
    required this.onOpenSearch,
    this.onOpenPostAd,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppState _state = AppState();
  bool _loading = true;
  List<dynamic> _categories = [];
  List<dynamic> _featuredAds = [];
  List<dynamic> _latestAds = [];
  int? _selectedFeedCategoryId;

  // Official Apolo 2026 Design Tokens
  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _blue = Color(0xFFE31B23);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _border = Color(0xFFEDEFF3);
  static const Color _pillBg = Color(0xFFF1F3F7);

  static const List<Map<String, dynamic>> _defaultCategories = [
    {
      'id': 3,
      'name_ar': 'وسائل النقل',
      'name_fr': 'Véhicules',
      'asset': 'assets/images/hero_car.png',
    },
    {
      'id': 2,
      'name_ar': 'عقارات',
      'name_fr': 'Immobilier',
      'asset': 'assets/images/cat_realestate.png',
    },
    {
      'id': 1,
      'name_ar': 'إعلاميات وتقنية',
      'name_fr': 'Informatique',
      'asset': 'assets/images/cat_computers.png',
    },
    {
      'id': 4,
      'name_ar': 'أزياء وجمال',
      'name_fr': 'Mode & Beauté',
      'asset': 'assets/images/cat_fashion.png',
    },
    {
      'id': 5,
      'name_ar': 'أدوات السفر',
      'name_fr': 'Voyage',
      'asset': 'assets/images/cat_travel.png',
    },
    {
      'id': 6,
      'name_ar': 'بارافارماسي',
      'name_fr': 'Parapharmacie',
      'asset': 'assets/images/cat_parapharmacy.png',
    },
    {
      'id': 7,
      'name_ar': 'الأطفال',
      'name_fr': 'Enfants',
      'asset': 'assets/images/cat_kids.png',
    },
    {
      'id': 8,
      'name_ar': 'بريكولاج',
      'name_fr': 'Bricolage',
      'asset': 'assets/images/cat_bricolage.png',
    },
    {
      'id': 9,
      'name_ar': 'آلات صناعية',
      'name_fr': 'Industrie & Pro',
      'asset': 'assets/images/cat_industrial.png',
    },
    {
      'id': 10,
      'name_ar': 'المجوهرات',
      'name_fr': 'Bijoux',
      'asset': 'assets/images/cat_jewelry.png',
    },
    {
      'id': 11,
      'name_ar': 'تحف وأنتيك',
      'name_fr': 'Antiquités',
      'asset': 'assets/images/cat_antique.png',
    },
    {
      'id': 12,
      'name_ar': 'أقسام أخرى',
      'name_fr': 'Autres',
      'asset': 'assets/images/cat_other.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    setState(() => _loading = true);
    try {
      final res = await _state.api.dio.get('/home');
      if (res.data is Map && res.data['status'] == 'success') {
        final data = res.data;
        if (mounted) {
          setState(() {
            _categories = data['categories'] ?? _state.categories;
            _featuredAds = data['vip_ads'] ?? [];
            _latestAds = data['latest_ads'] ?? [];
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _userFirstName() {
    final raw = (_state.currentUser?['name'] ??
            _state.currentUser?['username'] ??
            '')
        .toString()
        .trim();
    if (raw.isEmpty) return 'Amine';
    return raw.split(' ').first;
  }

  void _openNotificationsSheet() {
    final s = _state.s;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEECEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.bell_fill,
                    color: _blue,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.tr('الإشعارات والتنبيهات', 'Notifications & Alertes'),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _pillBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/hero_car.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.tr(
                            'مرحباً بك فـ النسخة الجديدة ديال Apolo.ma 🎉',
                            'Bienvenue sur le nouveau Apolo.ma 🎉',
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          s.tr(
                            'الخوارزمية الذكية دابا كتقترح عليك العروض حسب الأقسام اللي كتفضلها.',
                            'Notre algorithme intelligent adapte désormais votre fil selon vos catégories préférées.',
                          ),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final topPadding = MediaQuery.of(context).padding.top;
    final displayCategories =
        _categories.isNotEmpty ? _categories : _defaultCategories;

    // Combine all ads & separate Trending vs Personalized Feed
    final allAds = <Map<String, dynamic>>[];
    final seenIds = <String>{};
    for (final item in [..._featuredAds, ..._latestAds]) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final idStr = (map['id'] ?? '').toString();
        if (idStr.isNotEmpty && !seenIds.contains(idStr)) {
          seenIds.add(idStr);
          allAds.add(map);
        }
      }
    }

    // 1. Trending ads (Featured / VIP / Top viewed first)
    final trendingAds = List<Map<String, dynamic>>.from(allAds);
    trendingAds.sort((a, b) {
      final aVip = (a['is_vip'] == true || a['is_featured'] == true) ? 1 : 0;
      final bVip = (b['is_vip'] == true || b['is_featured'] == true) ? 1 : 0;
      if (aVip != bVip) return bVip.compareTo(aVip);
      final aViews =
          int.tryParse((a['views'] ?? a['views_count'] ?? 0).toString()) ?? 0;
      final bViews =
          int.tryParse((b['views'] ?? b['views_count'] ?? 0).toString()) ?? 0;
      return bViews.compareTo(aViews);
    });
    final topTrending = trendingAds.take(5).toList();

    // 2. Smart Personalized Feed (Ranked by user interest weights & filtered if chip selected)
    final personalizedPool = _selectedFeedCategoryId == null
        ? allAds
        : allAds
            .where((ad) => _state.adMatchesCategory(ad, _selectedFeedCategoryId))
            .toList();
    final personalizedAds = _state.rankAdsForUser(personalizedPool);

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: _blue,
        onRefresh: _loadHome,
        child: ListView(
          padding: EdgeInsets.only(top: topPadding + 12, bottom: 118),
          children: [
            // Top Greeting Row + Language Toggle + Notifications Bell
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.isAr
                          ? 'مرحباً، ${_userFirstName()} 👋'
                          : 'Bonjour, ${_userFirstName()} 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: _ink,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Quick Language Switcher Pill (100% consistent AR / FR)
                  GestureDetector(
                    onTap: () async {
                      await _state.toggleLanguage();
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      decoration: BoxDecoration(
                        color: _pillBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.globe,
                            size: 15,
                            color: _ink,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            s.isAr ? 'FR' : 'عربي',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _openNotificationsSheet,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _pillBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: _border),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.bell,
                            size: 18,
                            color: _ink,
                          ),
                          Positioned(
                            top: 9,
                            right: 9,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _blue,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 1.4),
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

            // Balanced Hero Card: Text on start side, 3D Car on end side WITHOUT overlapping text or button!
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
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
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _blue.withValues(alpha: 0.24),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Soft ambient top glow
                        PositionedDirectional(
                          end: -15,
                          top: -50,
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.30),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Compact AI Report Flag Icon in the top-end corner of the Hero Card
                        PositionedDirectional(
                          top: 12,
                          end: 12,
                          child: GestureDetector(
                            onTap: () => showAiContentReportSheet(
                              context,
                              featureContext: s.tr(
                                'مساعد أبولو الذكي',
                                'Assistant IA Apolo',
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
                                  color: Colors.white.withValues(alpha: 0.28),
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
                                    s.tr('إبلاغ AI', 'Signaler IA'),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Reserved 156px on end side so the 3D car NEVER covers text or CTA button
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            18,
                            18,
                            156,
                            18,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.34),
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
                                    Flexible(
                                      child: Text(
                                        s.tr(
                                          'مساعد أبولو الذكي • LIVE',
                                          'Assistant Apolo IA • LIVE',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                s.tr(
                                  'بيع ولا شري فـ 30 ثانية',
                                  'Vendez ou achetez en 30s',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 19.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                s.tr(
                                  'حط إعلانك خطوة بخطوة وخلي الذكاء الاصطناعي يقاد ليك كلشي.',
                                  'Publiez étape par étape, notre assistant s\'occupe du reste.',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.94),
                                ),
                              ),
                              const SizedBox(height: 13),
                              GestureDetector(
                                onTap: () {
                                  if (widget.onOpenPostAd != null) {
                                    widget.onOpenPostAd!();
                                  } else {
                                    widget.onOpenSearch(null);
                                  }
                                },
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
                                        color:
                                            Colors.black.withValues(alpha: 0.14),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        s.tr('ابدا دابا', 'Commencer'),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: _blue,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Icon(
                                        s.isAr
                                            ? CupertinoIcons.arrow_left
                                            : CupertinoIcons.arrow_right,
                                        size: 13,
                                        color: _blue,
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

                  // 3D Ground Shadow under the Car
                  PositionedDirectional(
                    end: -4,
                    bottom: -10,
                    width: 158,
                    height: 22,
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

                  // 3D SUV Coupé positioned cleanly in the 156px stage (no overlap with button or text!)
                  PositionedDirectional(
                    end: -12,
                    bottom: -14,
                    width: 172,
                    height: 124,
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
            ),

            // Categories Section (2026 Bento Cards — Clean Short Labels, Zero Overlap!)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.categories,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: _ink,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => widget.onOpenSearch(null),
                    child: Row(
                      children: [
                        Text(
                          s.tr('عرض الكل', 'Tout voir'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _blue,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          s.isAr
                              ? CupertinoIcons.chevron_back
                              : CupertinoIcons.chevron_forward,
                          size: 14,
                          color: _blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 122,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: displayCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  final cat = displayCategories[idx] is Map
                      ? Map<String, dynamic>.from(displayCategories[idx] as Map)
                      : <String, dynamic>{};
                  final int? catId = int.tryParse(cat['id']?.toString() ?? '');
                  final String cleanName = _state.formatCategoryLabel(cat);
                  final String assetPath =
                      _state.assetForCategory(cat, cleanName);

                  return GestureDetector(
                    onTap: () => widget.onOpenSearch(catId),
                    child: Container(
                      width: 118,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFF7F8FB),
                            Color(0xFFEEF1F6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: idx == 0
                              ? _blue.withValues(alpha: 0.22)
                              : const Color(0xFFE5E8F0),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Full-width top label so words NEVER split mid-letter or collide with the product!
                          PositionedDirectional(
                            top: 10,
                            start: 11,
                            end: 10,
                            child: Text(
                              cleanName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          // Floating Global-Brand Product Cutout in bottom-end corner
                          PositionedDirectional(
                            bottom: 5,
                            end: 6,
                            width: 62,
                            height: 62,
                            child: Image.asset(
                              assetPath,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_loading) ...[
              const SizedBox(height: 18),
              const HomeFeedSkeleton(),
            ] else ...[
              // STAGE 1: Trending / الرائج الآن 🔥
              if (topTrending.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEECEE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.flame_fill,
                              size: 15,
                              color: _blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.tr('الرائج الآن في المغرب', 'Tendances au Maroc'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: _ink,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => widget.onOpenSearch(null),
                        child: Row(
                          children: [
                            Text(
                              s.tr('عرض الكل', 'Tout voir'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _blue,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              s.isAr
                                  ? CupertinoIcons.chevron_back
                                  : CupertinoIcons.chevron_forward,
                              size: 14,
                              color: _blue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 252,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: topTrending.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, idx) {
                      final ad = topTrending[idx];
                      return SizedBox(
                        width: 285,
                        child: _TriplyShowcaseCard(
                          ad: ad,
                          isTrendingBadge: true,
                          onVisited: () {
                            final catId = _state.extractAdCategoryId(ad);
                            _state.recordCategoryInterest(catId, weight: 2);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],

              // STAGE 2: Smart Personalized Feed (مقترح لك حسب اهتماماتك ✨)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEECEE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.sparkles,
                              size: 15,
                              color: _blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.tr(
                                    'مقترح لك حسب اهتماماتك',
                                    'Recommandé pour vous',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: _ink,
                                  ),
                                ),
                                Text(
                                  _state.hasPersonalizedInterests
                                      ? s.tr(
                                          'مرتب ذكياً حسب الأقسام اللي كتفضلها',
                                          'Trié selon vos catégories préférées',
                                        )
                                      : s.tr(
                                          'تصفح الأقسام باش يتخصص ليك الـ Feed تلقائياً',
                                          'Explorez les catégories pour personnaliser votre fil',
                                        ),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: _muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StoresScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _pillBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.bag_fill,
                              size: 13,
                              color: _blue,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              s.tr('المتاجر', 'Boutiques'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Category Filter Chips for the Smart Feed
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
                  scrollDirection: Axis.horizontal,
                  itemCount: displayCategories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    if (idx == 0) {
                      final active = _selectedFeedCategoryId == null;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedFeedCategoryId = null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? _ink : _pillBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            s.tr('الكل ✨', 'Tout ✨'),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: active ? Colors.white : _ink,
                            ),
                          ),
                        ),
                      );
                    }
                    final cat = displayCategories[idx - 1] is Map
                        ? Map<String, dynamic>.from(
                            displayCategories[idx - 1] as Map,
                          )
                        : <String, dynamic>{};
                    final int? catId =
                        int.tryParse(cat['id']?.toString() ?? '');
                    final bool active =
                        catId != null && _selectedFeedCategoryId == catId;
                    final String label = _state.formatCategoryLabel(cat);

                    return GestureDetector(
                      onTap: () {
                        if (catId != null) {
                          _state.recordCategoryInterest(catId, weight: 2);
                        }
                        setState(() {
                          _selectedFeedCategoryId = active ? null : catId;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active ? _blue : _pillBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: active ? _blue : _border,
                          ),
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
                  },
                ),
              ),

              if (personalizedAds.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          CupertinoIcons.sparkles,
                          size: 32,
                          color: _muted,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.tr(
                            'لا توجد إعلانات فـ هاد القسم حالياً',
                            'Aucune annonce dans cette catégorie pour le moment',
                          ),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedFeedCategoryId = null),
                          child: Text(
                            s.tr('عرض جميع الإعلانات', 'Afficher tout'),
                            style: const TextStyle(
                              color: _blue,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: personalizedAds.length,
                  itemBuilder: (context, index) {
                    return AdCard(ad: personalizedAds[index]);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TriplyShowcaseCard extends StatelessWidget {
  final Map<String, dynamic> ad;
  final bool isTrendingBadge;
  final VoidCallback? onVisited;

  const _TriplyShowcaseCard({
    required this.ad,
    this.isTrendingBadge = false,
    this.onVisited,
  });

  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _blue = Color(0xFFE31B23);

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final s = state.s;
    final int id = int.tryParse(ad['id'].toString()) ?? 0;
    final String title = (ad['title'] ?? '').toString();
    final String priceFormatted =
        (ad['price_formatted'] ?? '${ad['price'] ?? ''} MAD').toString();
    final String city = (s.isAr
            ? (ad['city_ar'] ?? ad['city_name'] ?? 'المغرب')
            : (ad['city_fr'] ?? ad['city_name'] ?? 'Maroc'))
        .toString();
    final String category = (s.isAr
            ? (ad['category_ar'] ?? ad['category_name'] ?? 'مميز')
            : (ad['category_fr'] ?? ad['category_name'] ?? 'À la une'))
        .toString();
    final String imageUrl = (ad['primary_image'] ??
            (ad['images'] is List && (ad['images'] as List).isNotEmpty
                ? ad['images'][0]
                : ''))
        .toString();

    return GestureDetector(
      onTap: () {
        onVisited?.call();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdDetailScreen(adId: id, initialData: ad),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEDEFF3)),
          boxShadow: [
            BoxShadow(
              color: _ink.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppImage(url: imageUrl, fit: BoxFit.cover),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 118,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.76),
                    ],
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 10,
              start: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isTrendingBadge
                      ? _blue
                      : Colors.black.withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTrendingBadge
                          ? CupertinoIcons.flame_fill
                          : CupertinoIcons.tag_fill,
                      size: 11,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isTrendingBadge
                          ? s.tr('رائج 🔥', 'Tendance 🔥')
                          : category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              bottom: 12,
              start: 14,
              end: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      priceFormatted,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: _blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.location_solid,
                        size: 12,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$city • $category',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
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
    );
  }
}
