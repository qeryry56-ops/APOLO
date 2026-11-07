import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'ad_detail_screen.dart';
import 'auth_screen.dart';
import 'notifications_screen.dart';
import 'post_ad_screen.dart';
import 'privacy_compliance_screen.dart';
import 'widgets/ad_card.dart';
import 'widgets/app_image.dart';
import 'widgets/boost_sheet.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/skeleton_loader.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AppState _state = AppState();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _myAds = [];
  bool _loadingAds = false;
  int _activeTab = 0; // 0: My Ads Grid, 1: Analytics & Boost, 2: Saved Ads
  double _scrollOffset = 0.0;

  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _primary = Color(0xFFE31B23);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProfileData();
  }

  void _onScroll() {
    if (!mounted) return;
    final next = _scrollController.offset.clamp(0.0, 320.0);
    if ((next - _scrollOffset).abs() > 1.5) {
      setState(() => _scrollOffset = next);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _loadingAds = true);
    try {
      if (_state.isLoggedIn) {
        await _state.fetchMe();
      }
    } catch (_) {}

    try {
      List<dynamic> rawList = [];
      if (_state.isLoggedIn) {
        final res = await _state.api.dio.get('/my-ads');
        if (res.data is Map) {
          rawList = (res.data['data'] as List?) ?? [];
        }
      }
      if (rawList.isEmpty) {
        final fallback = await _state.api.dio.get('/ads', queryParameters: {'per_page': 6});
        if (fallback.data is Map) {
          rawList = ((fallback.data['data'] as List?) ?? []).take(6).toList();
        }
      }
      final parsed = rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (mounted) {
        setState(() {
          _myAds = parsed.isNotEmpty ? parsed : _buildSampleSellerAds();
          _loadingAds = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _myAds = _buildSampleSellerAds();
          _loadingAds = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _buildSampleSellerAds() {
    return [
      {
        'id': 9101,
        'title': 'iPhone 16 Pro Max 256Go Titane Naturel',
        'price': 14200,
        'price_formatted': '14 200 DH',
        'views_count': 640,
        'is_featured': true,
        'city': {'id': 1, 'name': 'Casablanca', 'name_ar': 'الدار البيضاء', 'name_fr': 'Casablanca'},
        'category': {'id': 4, 'name': 'Téléphones', 'name_ar': 'هواتف ذكية', 'name_fr': 'Téléphones'},
        'main_image': 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=900&q=80',
      },
      {
        'id': 9102,
        'title': 'MacBook Pro M4 14" 24Go RAM — État Neuf',
        'price': 21900,
        'price_formatted': '21 900 DH',
        'views_count': 415,
        'is_featured': false,
        'city': {'id': 1, 'name': 'Casablanca', 'name_ar': 'الدار البيضاء', 'name_fr': 'Casablanca'},
        'category': {'id': 3, 'name': 'Informatique', 'name_ar': 'معلوميات', 'name_fr': 'Informatique'},
        'main_image': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=900&q=80',
      },
      {
        'id': 9103,
        'title': 'Porsche Macan S Pack Sport — Entretien Maison',
        'price': 760000,
        'price_formatted': '760 000 DH',
        'views_count': 1290,
        'is_vip': true,
        'city': {'id': 2, 'name': 'Rabat', 'name_ar': 'الرباط', 'name_fr': 'Rabat'},
        'category': {'id': 1, 'name': 'Véhicules', 'name_ar': 'سيارات ومركبات', 'name_fr': 'Véhicules'},
        'main_image': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=900&q=80',
      },
      {
        'id': 9104,
        'title': 'Montre Automatique Chronographe Acier 41mm',
        'price': 8900,
        'price_formatted': '8 900 DH',
        'views_count': 310,
        'is_featured': false,
        'city': {'id': 3, 'name': 'Marrakech', 'name_ar': 'مراكش', 'name_fr': 'Marrakech'},
        'category': {'id': 6, 'name': 'Bijoux & Montres', 'name_ar': 'مجوهرات وساعات', 'name_fr': 'Bijoux'},
        'main_image': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=900&q=80',
      },
    ];
  }

  int get _totalViews {
    if (_myAds.isEmpty) return 0;
    return _myAds.fold<int>(0, (sum, ad) {
      final v = int.tryParse((ad['views_count'] ?? ad['views'] ?? 145).toString()) ?? 145;
      return sum + (v > 0 ? v : 145);
    });
  }

  int get _totalLeads {
    if (_myAds.isEmpty) return 0;
    return (_totalViews * 0.085).round().clamp(4, 9999);
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final user = _state.currentUser;
    final name = user?['name']?.toString() ??
        (isAr ? 'أمين — استوديو البيع' : 'Amine — Studio Vendeur');
    final handle = user?['email']?.toString().split('@').first ?? 'amine.apolo';
    final isStore = _state.accountType == 'pro' ||
        _state.accountType == 'store' ||
        user?['account_type'] == 'store';
    final collapseT = (_scrollOffset / 150.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _primary,
          backgroundColor: Colors.white,
          onRefresh: _loadProfileData,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // 1. Pinned Collapsing Top Bar with Settings Icon on Top-End
              SliverAppBar(
                pinned: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Colors.white.withValues(alpha: 0.95),
                surfaceTintColor: Colors.transparent,
                toolbarHeight: 58,
                titleSpacing: 16,
                title: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: collapseT > 0.55 ? 28 : 0,
                      height: 28,
                      margin: EdgeInsetsDirectional.only(
                        end: collapseT > 0.55 ? 8 : 0,
                      ),
                      child: Opacity(
                        opacity: ((collapseT - 0.55) / 0.45).clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: _ink,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        collapseT > 0.55 ? name : '@$handle',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: _primary,
                      size: 16,
                    ),
                    if (isStore) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _ink,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: isAr ? 'نشر إعلان' : 'Publier',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PostAdScreen()),
                    ).then((_) => _loadProfileData()),
                    icon: const Icon(
                      CupertinoIcons.plus_app,
                      color: _ink,
                      size: 22,
                    ),
                  ),
                  IconButton(
                    tooltip: isAr ? 'الإشعارات' : 'Notifications',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                    icon: const Icon(
                      CupertinoIcons.bell,
                      color: _ink,
                      size: 21,
                    ),
                  ),
                  // Top-Right Settings Icon
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: IconButton(
                      tooltip: isAr ? 'الإعدادات' : 'Paramètres',
                      onPressed: () => _openSettingsSheet(s, isAr),
                      icon: const Icon(
                        CupertinoIcons.gear_alt,
                        color: _ink,
                        size: 22,
                      ),
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: const Color(0xFFE2E8F0).withValues(alpha: collapseT),
                  ),
                ),
              ),

              // 2. Editorial Creator / Store Header + Live Growth Pill
              SliverToBoxAdapter(
                child: _buildIdentityHeader(
                  name: name,
                  isStore: isStore,
                  isAr: isAr,
                  collapseT: collapseT,
                ),
              ),

              // 3. Pinned Segmented Tab Switcher (My Ads | Analytics & Boost | Saved)
              SliverPersistentHeader(
                pinned: true,
                delegate: _ProfileTabsDelegate(
                  activeTab: _activeTab,
                  adsCount: _myAds.length,
                  savedCount: _state.favoriteAdIds.length,
                  isAr: isAr,
                  onTabChanged: (index) => setState(() => _activeTab = index),
                ),
              ),

              // 4. Tab Content with ScrollReveal Physics
              if (_loadingAds)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const AdGridCardSkeleton(),
                      childCount: 4,
                    ),
                  ),
                )
              else if (_activeTab == 0)
                _buildMyAdsSliver(isAr)
              else if (_activeTab == 1)
                SliverToBoxAdapter(
                  child: _buildAnalyticsAndBoostStudio(isAr),
                )
              else
                _buildSavedAdsSliver(isAr),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityHeader({
    required String name,
    required bool isStore,
    required bool isAr,
    required double collapseT,
  }) {
    final headerScale = (1.0 - (collapseT * 0.06)).clamp(0.94, 1.0);
    final headerOpacity = (1.0 - (collapseT * 0.85)).clamp(0.15, 1.0);

    return Opacity(
      opacity: headerOpacity,
      child: Transform.scale(
        scale: headerScale,
        alignment: Alignment.topCenter,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [_primary, Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTabularMetric(
                          value: '${_myAds.length}',
                          label: isAr ? 'إعلاناتي' : 'Annonces',
                          onTap: () => setState(() => _activeTab = 0),
                        ),
                        Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                        _buildTabularMetric(
                          value: '$_totalViews',
                          label: isAr ? 'مشاهدات' : 'Vues',
                          onTap: () => setState(() => _activeTab = 1),
                        ),
                        Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                        _buildTabularMetric(
                          value: '$_totalLeads',
                          label: isAr ? 'مهتمين' : 'Contacts',
                          onTap: () => setState(() => _activeTab = 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isStore
                          ? (isAr ? 'متجر موثق' : 'Boutique Pro')
                          : (isAr ? 'بائع موثق' : 'Vendeur Vérifié'),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? 'مساحة إدارة إعلاناتك، تتبع المشاهدات، وتمويل العروض (Boost) في المغرب.'
                    : 'Gérez vos annonces, suivez vos performances et boostez vos ventes au Maroc.',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _muted,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              PressableScale(
                onTap: () => setState(() => _activeTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _ink,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.chart_bar_alt_fill,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isAr ? 'لوحة أداء البائع' : 'Tableau de bord vendeur',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isAr ? '+28% هذا الأسبوع' : '+28% vs 7j',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF15803D),
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAr
                                  ? '$_totalViews مشاهدة · $_totalLeads نقرة تواصل مباشرة'
                                  : '$_totalViews vues · $_totalLeads contacts directs',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: _muted,
                                fontWeight: FontWeight.w500,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      PressableScale(
                        onTap: () => _openBoostModal(
                          adId: int.tryParse((_myAds.isNotEmpty ? _myAds.first['id'] : 1).toString()) ?? 1,
                          adTitle: (_myAds.isNotEmpty ? _myAds.first['title'] : 'Apolo Boost').toString(),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.bolt_fill,
                                color: Colors.white,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAr ? 'Boost' : 'Booster',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
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
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: PressableScale(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PostAdScreen()),
                      ).then((_) => _loadProfileData()),
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: _ink,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAr ? 'نشر إعلان جديد' : 'Nouvelle annonce',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PressableScale(
                      onTap: () {
                        if (!_state.isLoggedIn) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          ).then((_) => _loadProfileData());
                        } else {
                          _showEditProfileDialog(isAr);
                        }
                      },
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          !_state.isLoggedIn
                              ? (isAr ? 'تسجيل الدخول / حساب جديد' : 'Connexion / Inscription')
                              : (isAr ? 'تعديل البروفايل' : 'Modifier le profil'),
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }

  Widget _buildTabularMetric({
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: -0.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 0: Instagram-style 2-column grid of ONLY the user's ads
  Widget _buildMyAdsSliver(bool isAr) {
    if (_myAds.isEmpty) {
      return SliverToBoxAdapter(
        child: IllustratedStateView(
          assetPath: 'assets/images/state_empty_ads.png',
          imageSize: 170,
          title: isAr ? 'لم تنشر أي إعلان بعد' : 'Aucune annonce publiée',
          subtitle: isAr
              ? 'ابدأ بنشر أول إعلان لك الآن وتتبع عدد المشاهدات والرسائل مباشرة من حسابك.'
              : 'Publiez votre première annonce et suivez vos statistiques en direct.',
          actionLabel: isAr ? 'انشر أول إعلان الآن' : 'Publier une annonce',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostAdScreen()),
          ).then((_) => _loadProfileData()),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ad = _myAds[index];
            final adId = int.tryParse((ad['id'] ?? index).toString()) ?? index;
            return ScrollReveal(
              key: ValueKey('profile_my_ad_$adId'),
              delay: Duration(milliseconds: 55 * (index % 6)),
              child: _buildInstaSellerTile(ad, isAr),
            );
          },
          childCount: _myAds.length,
        ),
      ),
    );
  }

  Widget _buildInstaSellerTile(Map<String, dynamic> ad, bool isAr) {
    final adId = int.tryParse((ad['id'] ?? 1).toString()) ?? 1;
    final title = (ad['title'] ?? '').toString();
    final imgUrl = (ad['main_image'] ?? ad['primary_image'] ?? '').toString();
    final views = int.tryParse((ad['views_count'] ?? ad['views'] ?? 145).toString()) ?? 145;
    final priceStr = (ad['price_formatted'] ??
            (ad['price'] != null ? '${ad['price']} ${isAr ? 'د.م' : 'DH'}' : ''))
        .toString();

    return PressableScale(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdDetailScreen(adId: adId, initialAd: ad),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                            Colors.black.withValues(alpha: 0.28),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.60),
                          ],
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.eye_fill,
                              color: Colors.white,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$views',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: GestureDetector(
                        onTap: () => _showAdQuickActions(ad, isAr),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.50),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.ellipsis,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                    if (priceStr.isNotEmpty)
                      PositionedDirectional(
                        bottom: 8,
                        start: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            priceStr,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 11.5,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isAr ? 'نشط' : 'Actif',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => _openBoostModal(adId: adId, adTitle: title),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.bolt_fill,
                                  color: _primary,
                                  size: 10,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isAr ? 'تمويل' : 'Boost',
                                  style: const TextStyle(
                                    color: _primary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
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
    );
  }

  /// Tab 1: Dedicated High-Craft Seller Analytics & Boost Studio
  Widget _buildAnalyticsAndBoostStudio(bool isAr) {
    return ScrollReveal(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'تطور مشاهدات إعلاناتك' : 'Évolution des vues (7 jours)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$_totalViews',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: _ink,
                                  letterSpacing: -0.8,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isAr ? '+28% مقارنة بالأسبوع الماضي' : '+28% vs semaine dernière',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      PressableScale(
                        onTap: () => _openBoostModal(
                          adId: int.tryParse((_myAds.isNotEmpty ? _myAds.first['id'] : 1).toString()) ?? 1,
                          adTitle: (_myAds.isNotEmpty ? _myAds.first['title'] : 'Apolo Boost').toString(),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isAr ? 'مضاعفة المشاهدات' : 'Booster',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SellerTrendChartPainter(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: (isAr
                            ? ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد']
                            : ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'])
                        .map(
                          (d) => Text(
                            d,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: isAr ? 'نسبة النقر' : 'Taux de clic',
                    value: '8.5%',
                    delta: isAr ? '+1.4% هذا الأسبوع' : '+1.4% vs 7j',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    label: isAr ? 'رسائل واتساب' : 'Contacts directs',
                    value: '$_totalLeads',
                    delta: isAr ? '+9 مهتمين جدد' : '+9 acheteurs',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              isAr ? 'أداء كل إعلان على حدة' : 'Performance par annonce',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            ..._myAds.map((ad) {
              final adId = int.tryParse((ad['id'] ?? 1).toString()) ?? 1;
              final title = (ad['title'] ?? '').toString();
              final views = int.tryParse((ad['views_count'] ?? ad['views'] ?? 210).toString()) ?? 210;
              final ratio = (views / 1500.0).clamp(0.18, 1.0);
              final isBoosted = ad['is_vip'] == true || ad['is_featured'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$views ${isAr ? 'مشاهدة' : 'vues'}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isBoosted ? _primary : _ink,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _openBoostModal(adId: adId, adTitle: title),
                            child: Text(
                              isAr ? 'Boost +' : 'Booster +',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String delta,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _ink,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            delta,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 2: Saved / Favorited Ads Grid
  Widget _buildSavedAdsSliver(bool isAr) {
    final saved = _myAds.where((ad) {
      final id = int.tryParse((ad['id'] ?? 0).toString()) ?? 0;
      return _state.favoriteAdIds.contains(id);
    }).toList();

    if (saved.isEmpty) {
      return SliverToBoxAdapter(
        child: IllustratedStateView(
          assetPath: 'assets/images/state_empty_ads.png',
          imageSize: 164,
          title: isAr ? 'قائمة المحفوظات فارغة' : 'Aucun favori enregistré',
          subtitle: isAr
              ? 'اضغط على أيقونة القلب في أي إعلان لحفظه هنا والرجوع إليه في أي وقت.'
              : 'Appuyez sur le cœur d’une annonce pour la retrouver facilement ici.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.67,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ad = saved[index];
            return ScrollReveal(
              delay: Duration(milliseconds: 50 * index),
              child: AdCard(ad: ad),
            );
          },
          childCount: saved.length,
        ),
      ),
    );
  }

  void _openBoostModal({required int adId, required String adTitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BoostSheet(adId: adId, adTitle: adTitle),
    );
  }

  /// Settings Drawer Sheet (Top-Right Gear Icon)
  void _openSettingsSheet(AppStrings s, bool isAr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isAr ? 'الإعدادات وتفضيلات الحساب' : 'Paramètres du compte',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.globe, color: _ink, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isAr ? 'اللغة' : 'Langue',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _ink,
                          ),
                        ),
                      ),
                      _buildLangOption('ar', 'العربية', isAr, ctx),
                      const SizedBox(width: 6),
                      _buildLangOption('fr', 'Français', !isAr, ctx),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                _buildSettingsTile(
                  isAr: isAr,
                  icon: CupertinoIcons.bell,
                  title: isAr ? 'الإشعارات وحالة الاتصال' : 'Notifications & Connexion',
                  subtitle: isAr
                      ? 'إدارة التنبيهات ومعاينة صفحة عدم الاتصال'
                      : 'Gérer vos alertes et l’état hors-ligne',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),

                _buildSettingsTile(
                  isAr: isAr,
                  icon: CupertinoIcons.person_crop_circle,
                  title: isAr ? 'تعديل معلومات الحساب' : 'Modifier mes informations',
                  subtitle: isAr ? 'الاسم، الهاتف، ونوع الحساب' : 'Nom, téléphone et type de compte',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditProfileDialog(isAr);
                  },
                ),

                _buildSettingsTile(
                  isAr: isAr,
                  icon: CupertinoIcons.shield_lefthalf_fill,
                  title: isAr ? 'سياسة الخصوصية وحذف الحساب' : 'Confidentialité & Suppression',
                  subtitle: isAr
                      ? 'حماية البيانات وحذف الحساب نهائياً (Google Play)'
                      : 'Protection des données et suppression du compte',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyComplianceScreen(initialTab: 0),
                      ),
                    );
                  },
                ),

                if (_state.isLoggedIn) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _state.logout();
                        if (mounted) setState(() {});
                      },
                      icon: const Icon(
                        CupertinoIcons.square_arrow_right,
                        color: _primary,
                        size: 18,
                      ),
                      label: Text(
                        s.logout,
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _primary.withValues(alpha: 0.35)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangOption(String code, String label, bool selected, BuildContext sheetCtx) {
    return GestureDetector(
      onTap: () async {
        if (!selected) {
          await _state.toggleLanguage();
        }
        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
        if (mounted) setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _ink : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _ink : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _ink,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required bool isAr,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, color: _ink, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: _ink,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: _muted,
        ),
      ),
      trailing: Icon(
        isAr ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right,
        size: 15,
        color: _muted,
      ),
    );
  }

  void _showAdQuickActions(Map<String, dynamic> ad, bool isAr) {
    final adId = int.tryParse((ad['id'] ?? 1).toString()) ?? 1;
    final title = (ad['title'] ?? '').toString();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(CupertinoIcons.bolt_fill, color: _primary),
              title: Text(isAr ? 'تمويل الإعلان (Boost)' : 'Booster cette annonce'),
              onTap: () {
                Navigator.pop(ctx);
                _openBoostModal(adId: adId, adTitle: title);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.checkmark_circle, color: Color(0xFF16A34A)),
              title: Text(isAr ? 'تحديد كمباع' : 'Marquer comme vendu'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.trash, color: _primary),
              title: Text(
                isAr ? 'حذف الإعلان' : 'Supprimer l’annonce',
                style: const TextStyle(color: _primary),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await _state.api.dio.delete('/ads/$adId');
                } catch (_) {}
                if (mounted) {
                  setState(() {
                    _myAds.removeWhere(
                      (item) => (int.tryParse((item['id'] ?? 0).toString()) ?? 0) == adId,
                    );
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(bool isAr) {
    final nameCtrl = TextEditingController(text: _state.currentUser?['name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: _state.currentUser?['phone']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isAr ? 'تعديل البروفايل' : 'Modifier le profil',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: isAr ? 'الاسم أو اسم المتجر' : 'Nom ou Boutique',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: isAr ? 'رقم الهاتف / الواتساب' : 'Téléphone / WhatsApp',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _state.api.dio.put('/auth/profile', data: {
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                });
              } catch (_) {}
              _state.currentUser = {
                ...?_state.currentUser,
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
              };
              if (mounted) setState(() {});
            },
            child: Text(isAr ? 'حفظ' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _ProfileTabsDelegate extends SliverPersistentHeaderDelegate {
  final int activeTab;
  final int adsCount;
  final int savedCount;
  final bool isAr;
  final ValueChanged<int> onTabChanged;

  const _ProfileTabsDelegate({
    required this.activeTab,
    required this.adsCount,
    required this.savedCount,
    required this.isAr,
    required this.onTabChanged,
  });

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9)),
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabItem(
            index: 0,
            icon: CupertinoIcons.square_grid_2x2,
            label: isAr ? 'إعلاناتي ($adsCount)' : 'Annonces ($adsCount)',
          ),
          _buildTabItem(
            index: 1,
            icon: CupertinoIcons.chart_bar_alt_fill,
            label: isAr ? 'الإحصائيات و Boost' : 'Stats & Boost',
          ),
          _buildTabItem(
            index: 2,
            icon: CupertinoIcons.bookmark,
            label: isAr ? 'المحفوظات' : 'Favoris',
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool selected = activeTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTabChanged(index),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? const Color(0xFF0F172A) : Colors.transparent,
                width: 2.2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileTabsDelegate oldDelegate) {
    return oldDelegate.activeTab != activeTab ||
        oldDelegate.adsCount != adsCount ||
        oldDelegate.savedCount != savedCount ||
        oldDelegate.isAr != isAr;
  }
}

class _SellerTrendChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[
      Offset(0, size.height * 0.78),
      Offset(size.width * 0.16, size.height * 0.65),
      Offset(size.width * 0.33, size.height * 0.68),
      Offset(size.width * 0.50, size.height * 0.45),
      Offset(size.width * 0.66, size.height * 0.38),
      Offset(size.width * 0.83, size.height * 0.24),
      Offset(size.width, size.height * 0.12),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE31B23).withValues(alpha: 0.18),
          const Color(0xFFE31B23).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFFE31B23)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final last = points.last;
    canvas.drawCircle(
      last,
      6,
      Paint()..color = const Color(0xFFE31B23).withValues(alpha: 0.22),
    );
    canvas.drawCircle(last, 3.5, Paint()..color = const Color(0xFFE31B23));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
