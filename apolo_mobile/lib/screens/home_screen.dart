import 'package:flutter/cupertino.dart';
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

  // Exact Triply-AI + Apolo Official Brand Red (#E31B23) color tokens
  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _blue = Color(0xFFE31B23);
  static const Color _gold = Color(0xFFF5B942);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _border = Color(0xFFEDEFF3);
  static const Color _pillBg = Color(0xFFF1F3F7);

  static const List<Map<String, dynamic>> _defaultCategories = [
    {
      'id': 3,
      'name_ar': 'وسائل النقل',
      'name_fr': 'Véhicules & Auto',
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
      'name_ar': 'المعلوماتية والوسائط',
      'name_fr': 'Informatique & Tech',
      'asset': 'assets/images/cat_computers.png',
    },
    {
      'id': 4,
      'name_ar': 'ملابس ـ صحة وجمال',
      'name_fr': 'Habillement & Mode',
      'asset': 'assets/images/cat_fashion.png',
    },
    {
      'id': 5,
      'name_ar': 'أدوات السفر',
      'name_fr': 'Outils de voyage',
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
      'name_fr': 'Machines industrielles',
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
      'name_ar': 'منتجات عتيقة',
      'name_fr': 'Antique',
      'asset': 'assets/images/cat_antique.png',
    },
    {
      'id': 12,
      'name_ar': 'آخر...',
      'name_fr': 'Autre...',
      'asset': 'assets/images/cat_other.png',
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

  String _assetForCategory(String name, int idx, [Map<dynamic, dynamic>? cat]) {
    final combined = '${name.toLowerCase()} ${(cat?['name_ar'] ?? '').toString().toLowerCase()} ${(cat?['name_fr'] ?? '').toString().toLowerCase()} ${(cat?['slug'] ?? '').toString().toLowerCase()}';
    if (combined.contains('voiture') ||
        combined.contains('auto') ||
        combined.contains('moto') ||
        combined.contains('vehicule') ||
        combined.contains('véhicule') ||
        combined.contains('نقل') ||
        combined.contains('سيار') ||
        combined.contains('مركبات')) {
      return 'assets/images/hero_car.png';
    }
    if (combined.contains('immo') ||
        combined.contains('appart') ||
        combined.contains('villa') ||
        combined.contains('عقار') ||
        combined.contains('شقق')) {
      return 'assets/images/cat_realestate.png';
    }
    if (combined.contains('voyage') || combined.contains('سفر')) {
      return 'assets/images/cat_travel.png';
    }
    if (combined.contains('parapharmacie') || combined.contains('بارافارماسي')) {
      return 'assets/images/cat_parapharmacy.png';
    }
    if (combined.contains('enfant') ||
        combined.contains('اطفال') ||
        combined.contains('أطفال')) {
      return 'assets/images/cat_kids.png';
    }
    if (combined.contains('bricolage') || combined.contains('بريكولاج')) {
      return 'assets/images/cat_bricolage.png';
    }
    if (combined.contains('industriel') ||
        combined.contains('machine') ||
        combined.contains('صناعية') ||
        combined.contains('ألات') ||
        combined.contains('آلات')) {
      return 'assets/images/cat_industrial.png';
    }
    if (combined.contains('bijou') || combined.contains('مجوهرات')) {
      return 'assets/images/cat_jewelry.png';
    }
    if (combined.contains('antique') || combined.contains('عتيقة')) {
      return 'assets/images/cat_antique.png';
    }
    if (combined.contains('autre') || combined.contains('آخر')) {
      return 'assets/images/cat_other.png';
    }
    if (combined.contains('télé') ||
        combined.contains('phone') ||
        combined.contains('هواتف')) {
      return 'assets/images/cat_phones.png';
    }
    if (combined.contains('info') ||
        combined.contains('multimedia') ||
        combined.contains('pc') ||
        combined.contains('معلوماتية') ||
        combined.contains('وسائط') ||
        combined.contains('حواسيب') ||
        combined.contains('إلكترون')) {
      return 'assets/images/cat_computers.png';
    }
    if (combined.contains('maison') ||
        combined.contains('meuble') ||
        combined.contains('أثاث') ||
        combined.contains('منزل')) {
      return 'assets/images/cat_home.png';
    }
    if (combined.contains('mode') ||
        combined.contains('habillement') ||
        combined.contains('vêt') ||
        combined.contains('أزياء') ||
        combined.contains('ملابس')) {
      return 'assets/images/cat_fashion.png';
    }
    if (combined.contains('emploi') ||
        combined.contains('service') ||
        combined.contains('وظائف') ||
        combined.contains('خدمات')) {
      return 'assets/images/cat_jobs.png';
    }
    return 'assets/images/cat_other.png';
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
                  child: const Icon(CupertinoIcons.bell_fill, color: _blue, size: 19),
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
                    child: Image.asset('assets/images/hero_car.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.tr('مرحباً بك فـ النسخة الجديدة ديال Apolo.ma 🎉', 'Bienvenue sur le nouveau Apolo.ma 🎉'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          s.tr(
                            'اكتشف أحدث عروض السيارات والعقارات أو ضيف إعلانك مجاناً فـ 30 ثانية.',
                            'Découvrez les dernières offres ou publiez votre annonce en 30 secondes.',
                          ),
                          style: const TextStyle(fontSize: 12.5, color: _muted, height: 1.35),
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
          padding: EdgeInsets.only(top: topPadding + 12, bottom: 115),
          children: [
            // Top Greeting Row + Notifications Bell Button (Balanced 28px Title, 20px Padding)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: _ink,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Notifications Bell Button (Replaced language icon as requested!)
                  GestureDetector(
                    onTap: _openNotificationsSheet,
                    child: Container(
                      width: 42,
                      height: 42,
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
                            size: 20,
                            color: _ink,
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
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

            // Hero Card with Live Red + White Color Distribution & Giant 3D Pop-Out Car!
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
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
                          color: _blue.withValues(alpha: 0.28),
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
                              Container(
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
                                    Text(
                                      s.tr('مساعد أبولو الذكي • LIVE', 'AI Deal Planner • LIVE'),
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
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
                                onTap: () {
                                  if (widget.onOpenPostAd != null) {
                                    widget.onOpenPostAd!();
                                  } else {
                                    widget.onOpenSearch(null);
                                  }
                                },
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
                                          color: _blue,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        CupertinoIcons.arrow_right,
                                        size: 14,
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
            ),

            // Categories Section with 3D Clay / Memoji Icons!
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.categories,
                    style: const TextStyle(
                      fontSize: 18.5,
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
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _blue,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          CupertinoIcons.chevron_forward,
                          size: 15,
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: displayCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, idx) {
                  final cat = displayCategories[idx];
                  final int? catId = int.tryParse(cat['id']?.toString() ?? '');
                  final String name = (s.isAr
                          ? (cat['name_ar'] ?? cat['name'] ?? '')
                          : (cat['name_fr'] ?? cat['name'] ?? ''))
                      .toString();
                  final String assetPath = cat['asset'] is String
                      ? cat['asset'] as String
                      : _assetForCategory(name, idx, cat is Map ? cat : null);

                  return GestureDetector(
                    onTap: () => widget.onOpenSearch(catId),
                    child: Container(
                      width: 132,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFF6F7FA),
                            Color(0xFFEDF0F5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: idx == 0
                              ? _blue.withValues(alpha: 0.22)
                              : const Color(0xFFE6E9F0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _ink.withValues(alpha: 0.035),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          PositionedDirectional(
                            top: 12,
                            start: 13,
                            end: 42,
                            child: Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                                height: 1.18,
                                letterSpacing: -0.25,
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            bottom: 4,
                            end: 6,
                            width: 68,
                            height: 68,
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

            // Section 1: "Featured listings"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.tr('إعلانات مميزة', 'Featured listings'),
                    style: const TextStyle(
                      fontSize: 18.5,
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
                          s.tr('عرض الكل', 'See all'),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _blue,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          CupertinoIcons.chevron_forward,
                          size: 15,
                          color: _blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: _blue)),
              )
            else if (heroAd != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _TriplyShowcaseCard(ad: heroAd),
              ),

            // Section 2: "Popular categories"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.tr('الأكثر طلباً في المغرب', 'Popular categories'),
                    style: const TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
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
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _blue,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          CupertinoIcons.chevron_forward,
                          size: 15,
                          color: _blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 214,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                scrollDirection: Axis.horizontal,
                itemCount: _fallbackPopular.length + (_categories.length > 3 ? 2 : 0),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, idx) {
                  final item = _fallbackPopular[idx % _fallbackPopular.length];
                  final int? catId = int.tryParse(item['id'] ?? '');
                  final title = s.isAr ? item['name_ar']! : item['name_fr']!;
                  final subtitle = s.isAr ? item['sub_ar']! : item['sub_fr']!;
                  return GestureDetector(
                    onTap: () => widget.onOpenSearch(catId),
                    child: Container(
                      width: 156,
                      height: 202,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
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
                            height: 105,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.68),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.star_fill,
                                    size: 12,
                                    color: _gold,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    item['rating'] ?? '4.9',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
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

            // Section 3: More Recent Listings in balanced Showcase Card format
            if (moreAds.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.tr('أحدث الإعلانات', 'Recent listings'),
                      style: const TextStyle(
                        fontSize: 18.5,
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
                            s.tr('الكل', 'See all'),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _blue,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 17,
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
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEDEFF3)),
          boxShadow: [
            BoxShadow(
              color: _ink.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 186,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(url: imageUrl, fit: BoxFit.cover),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 105,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.64),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                            CupertinoIcons.tag,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.location_solid,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.tag,
                        size: 16,
                        color: _muted,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        priceFormatted,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _blue,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        s.tr('عرض', 'Voir'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _blue,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
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
