import 'package:flutter/material.dart';
import '../core/state/app_state.dart';
import 'ad_detail_screen.dart';
import 'stores_screen.dart';
import 'widgets/app_image.dart';

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
  List<dynamic> _stores = [];

  // Exact Triply-AI + Apolo Official Brand Red (#E31B23) color tokens
  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _blue = Color(0xFFE31B23);
  static const Color _heroBlue = Color(0xFFC81018);
  static const Color _gold = Color(0xFFF5B942);
  static const Color _border = Color(0xFFEDEFF3);

  static const List<Map<String, dynamic>> _defaultCategories = [
    {
      'id': 3,
      'name_ar': 'سيارات ومركبات',
      'name_fr': 'Voitures & Auto',
      'icon': Icons.directions_car_filled_rounded,
      'bg': 0xFFFEECEE,
      'tint': 0xFFE31B23,
    },
    {
      'id': 2,
      'name_ar': 'عقارات وشقق',
      'name_fr': 'Immobilier',
      'icon': Icons.home_work_rounded,
      'bg': 0xFFEFF6FF,
      'tint': 0xFF2563EB,
    },
    {
      'id': 1,
      'name_ar': 'هواتف وإلكترونيات',
      'name_fr': 'Téléphones & Tech',
      'icon': Icons.smartphone_rounded,
      'bg': 0xFFF5F3FF,
      'tint': 0xFF7C3AED,
    },
    {
      'id': 4,
      'name_ar': 'حواسيب ومعدات',
      'name_fr': 'Informatique',
      'icon': Icons.laptop_mac_rounded,
      'bg': 0xFFECFDF5,
      'tint': 0xFF059669,
    },
    {
      'id': 5,
      'name_ar': 'أثاث وديكور',
      'name_fr': 'Maison & Déco',
      'icon': Icons.chair_rounded,
      'bg': 0xFFFFFBEB,
      'tint': 0xFFD97706,
    },
    {
      'id': 6,
      'name_ar': 'أزياء وموضة',
      'name_fr': 'Mode & Beauté',
      'icon': Icons.shopping_bag_rounded,
      'bg': 0xFFFDF2F8,
      'tint': 0xFFDB2777,
    },
    {
      'id': 7,
      'name_ar': 'وظائف وخدمات',
      'name_fr': 'Emploi & Services',
      'icon': Icons.work_rounded,
      'bg': 0xFFF0FDF4,
      'tint': 0xFF16A34A,
    },
  ];

  static const List<Map<String, String>> _fallbackPopular = [
    {
      'id': '3',
      'name_fr': 'Voitures & Auto',
      'name_ar': 'سيارات ومركبات',
      'sub_fr': 'Casablanca • Rabat',
      'sub_ar': 'الدار البيضاء • الرباط',
      'rating': '4.9',
      'image':
          'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=600&q=80&auto=format&fit=crop',
    },
    {
      'id': '2',
      'name_fr': 'Immobilier Prestige',
      'name_ar': 'عقارات وشقق',
      'sub_fr': 'Marrakech • Tanger',
      'sub_ar': 'مراكش • طنجة',
      'rating': '4.8',
      'image':
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=600&q=80&auto=format&fit=crop',
    },
    {
      'id': '1',
      'name_fr': 'High-Tech & Pro',
      'name_ar': 'إلكترونيات وهواتف',
      'sub_fr': 'Partout au Maroc',
      'sub_ar': 'جميع المدن',
      'rating': '4.8',
      'image':
          'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600&q=80&auto=format&fit=crop',
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
            _stores = data['featured_stores'] ?? [];
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _userFirstName() {
    final raw = (_state.currentUser?['name'] ?? _state.currentUser?['username'] ?? '').toString().trim();
    if (raw.isEmpty) return 'Amine';
    return raw.split(' ').first;
  }

  IconData _iconForCategory(String name, int idx) {
    final lower = name.toLowerCase();
    if (lower.contains('voiture') || lower.contains('auto') || lower.contains('moto') || lower.contains('سيار') || lower.contains('مركبات')) {
      return Icons.directions_car_filled_rounded;
    }
    if (lower.contains('immo') || lower.contains('appart') || lower.contains('villa') || lower.contains('عقار') || lower.contains('شقق')) {
      return Icons.home_work_rounded;
    }
    if (lower.contains('télé') || lower.contains('phone') || lower.contains('tech') || lower.contains('هواتف') || lower.contains('إلكترون')) {
      return Icons.smartphone_rounded;
    }
    if (lower.contains('info') || lower.contains('pc') || lower.contains('حواسيب')) {
      return Icons.laptop_mac_rounded;
    }
    if (lower.contains('maison') || lower.contains('meuble') || lower.contains('أثاث') || lower.contains('منزل')) {
      return Icons.chair_rounded;
    }
    if (lower.contains('mode') || lower.contains('vêt') || lower.contains('أزياء') || lower.contains('ملابس')) {
      return Icons.checkroom_rounded;
    }
    if (lower.contains('emploi') || lower.contains('service') || lower.contains('وظائف') || lower.contains('خدمات')) {
      return Icons.work_rounded;
    }
    final fallbackIcons = [
      Icons.directions_car_filled_rounded,
      Icons.home_work_rounded,
      Icons.smartphone_rounded,
      Icons.laptop_mac_rounded,
      Icons.chair_rounded,
      Icons.shopping_bag_rounded,
      Icons.work_rounded,
    ];
    return fallbackIcons[idx % fallbackIcons.length];
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final topPadding = MediaQuery.of(context).padding.top;
    final allAds = <Map<String, dynamic>>[
      ..._featuredAds.map((e) => Map<String, dynamic>.from(e as Map)),
      ..._latestAds.map((e) => Map<String, dynamic>.from(e as Map)),
    ];
    final heroAd = allAds.isNotEmpty ? allAds.first : null;
    final moreAds = allAds.length > 1 ? allAds.sublist(1) : <Map<String, dynamic>>[];

    final displayCategories = _categories.isNotEmpty ? _categories : _defaultCategories;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: _blue,
        onRefresh: _loadHome,
        child: ListView(
          padding: EdgeInsets.only(top: topPadding + 14, bottom: 120),
          children: [
            // Top Greeting Row (Exact Triply-AI style: "Hi, Name 👋")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      s.isAr
                          ? 'مرحباً، ${_userFirstName()} 👋'
                          : 'Hi, ${_userFirstName()} 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.9,
                        color: _ink,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      await _state.toggleLanguage();
                      await _loadHome();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        s.isAr ? 'FR' : 'عربي',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Hero Card (Apolo Brand Primary Red #E31B23 Card + 3D Memoji Car on the trailing side!)
            Container(
              margin: const EdgeInsets.fromLTRB(24, 22, 24, 0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE31B23), _heroBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _blue.withValues(alpha: 0.24),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Subtle radial glow behind the 3D Memoji car
                  PositionedDirectional(
                    end: -24,
                    top: -16,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.22),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 142, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.tr('مساعد أبولو الذكي', 'AI Deal Planner'),
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.tr(
                            'قول لينا شنو باغي تبيع ولا تشري — غادي نقادو ليك كلشي.',
                            'Tell us what you want to buy or sell — we\'ll build the listing.',
                          ),
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(height: 18),
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
                              horizontal: 20,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
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
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: _blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: _blue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 3D Memoji Car placed on top in the trailing slot (flipped in RTL so headlights face inward!)
                  PositionedDirectional(
                    end: -14,
                    bottom: 8,
                    width: 176,
                    height: 142,
                    child: IgnorePointer(
                      child: Transform.flip(
                        flipX: s.isAr,
                        child: Image.asset(
                          'assets/images/hero_car.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // NEW Section: Categories ("تصفح الأقسام" / "Catégories")
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.categories,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _blue,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: _blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 118,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
                scrollDirection: Axis.horizontal,
                itemCount: displayCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, idx) {
                  final cat = displayCategories[idx];
                  final int? catId = int.tryParse(cat['id']?.toString() ?? '');
                  final String name = (s.isAr
                          ? (cat['name_ar'] ?? cat['name'] ?? '')
                          : (cat['name_fr'] ?? cat['name'] ?? ''))
                      .toString();
                  final IconData icon = cat['icon'] is IconData
                      ? cat['icon'] as IconData
                      : _iconForCategory(name, idx);
                  final Color badgeBg = cat['bg'] is int
                      ? Color(cat['bg'] as int)
                      : (idx == 0 ? const Color(0xFFFEECEE) : const Color(0xFFF4F6F9));
                  final Color iconTint = cat['tint'] is int
                      ? Color(cat['tint'] as int)
                      : (idx == 0 ? _blue : _ink);

                  return GestureDetector(
                    onTap: () => widget.onOpenSearch(catId),
                    child: Container(
                      width: 106,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: idx == 0 ? _blue.withValues(alpha: 0.25) : _border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _ink.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: badgeBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 22, color: iconTint),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Section 1: "Your trips" -> "Annonces à la une"
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.tr('إعلانات مميزة', 'Featured listings'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: _ink,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => widget.onOpenSearch(null),
                    child: Row(
                      children: [
                        Text(
                          s.tr('عرض الكل', 'See all'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _blue,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: _blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Featured Showcase Card (Exact Triply-AI "3 Days in Osaka" card layout)
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator(color: _blue)),
              )
            else if (heroAd != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _TriplyShowcaseCard(ad: heroAd),
              ),

            // Section 2: "Popular destinations" -> Popular Categories / Pro Stores
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.tr('الأكثر طلباً في المغرب', 'Popular categories'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: _ink,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StoresScreen()),
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          s.tr('المتاجر', 'Boutiques'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _blue,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: _blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 246,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                scrollDirection: Axis.horizontal,
                itemCount: _fallbackPopular.length + (_categories.length > 3 ? 2 : 0),
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, idx) {
                  final item = _fallbackPopular[idx % _fallbackPopular.length];
                  final int? catId = int.tryParse(item['id'] ?? '');
                  final title = s.isAr ? item['name_ar']! : item['name_fr']!;
                  final subtitle = s.isAr ? item['sub_ar']! : item['sub_fr']!;
                  return GestureDetector(
                    onTap: () => widget.onOpenSearch(catId),
                    child: Container(
                      width: 168,
                      height: 230,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _ink.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppImage(
                            url: item['image'],
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 120,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.65),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Top-right Rating Badge
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: _gold,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['rating'] ?? '4.9',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Bottom-left Title & Subtitle
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
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

            // Section 3: More Recent Listings in Triply Showcase Card format
            if (moreAds.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.tr('أحدث الإعلانات', 'Recent listings'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: _ink,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => widget.onOpenSearch(null),
                      child: Row(
                        children: [
                          Text(
                            s.tr('الكل', 'See all'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _blue,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: _blue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ...moreAds.take(8).map(
                    (ad) => Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: _TriplyShowcaseCard(ad: ad),
                    ),
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

  const _TriplyShowcaseCard({required this.ad});

  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _blue = Color(0xFFE31B23);
  static const Color _muted = Color(0xFF8A94A6);

  @override
  Widget build(BuildContext context) {
    final s = AppState().s;
    final int id = int.tryParse(ad['id'].toString()) ?? 0;
    final String title = (ad['title'] ?? '').toString();
    final String priceFormatted =
        (ad['price_formatted'] ?? '${ad['price'] ?? ''} MAD').toString();
    final String city = (s.isAr
            ? (ad['city_ar'] ?? ad['city_name'] ?? 'المغرب')
            : (ad['city_fr'] ?? ad['city_name'] ?? 'Maroc'))
        .toString();
    final String category = (s.isAr
            ? (ad['category_ar'] ?? ad['category_name'] ?? 'إعلان مميز')
            : (ad['category_fr'] ?? ad['category_name'] ?? 'Featured'))
        .toString();
    final String imageUrl = (ad['primary_image'] ??
            (ad['images'] is List && (ad['images'] as List).isNotEmpty
                ? ad['images'][0]
                : ''))
        .toString();

    return GestureDetector(
      onTap: () {
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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEDEFF3)),
          boxShadow: [
            BoxShadow(
              color: _ink.withValues(alpha: 0.09),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 210,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(url: imageUrl, fit: BoxFit.cover),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 120,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.62),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Top-right translucent pill badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom-left Title + Location overlay
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.95),
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
            // White Footer Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                        color: _muted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        priceFormatted,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _blue,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        s.tr('عرض', 'View'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _blue,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: _blue,
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
