import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import 'ad_detail_screen.dart';
import 'ad_reels_screen.dart';
import 'auth_screen.dart';
import 'post_ad_screen.dart';
import 'settings_screen.dart';
import 'widgets/app_image.dart';
import 'widgets/price_text.dart';
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

  List<Map<String, dynamic>> _myAds = [];
  bool _loadingAds = false;
  int _activeTab = 0; // 0: My Ads (Default clean grid), 1: Insights & Boost
  String? _adsError;
  final Set<int> _deletingAds = {};
  String? _profileIdentity;
  String? get _identity =>
      _state.isLoggedIn && _state.currentUser?['id'] != null
          ? '${_state.api.dio.options.baseUrl}:${_state.currentUser!['id']}'
          : null;

  static const Color _primary = Color(0xFFE31B23);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _surface = Color(0xFFF5F6F8);
  static const Color _hairline = Color(0xFFECEEF2);

  @override
  void initState() {
    super.initState();
    _profileIdentity = _identity;
    _state.addListener(_onAccountChanged);
    _loadProfileData();
  }

  @override
  void dispose() {
    _state.removeListener(_onAccountChanged);
    super.dispose();
  }

  void _onAccountChanged() {
    if (!mounted) return;
    if (_profileIdentity != _identity) {
      _profileIdentity = _identity;
      _myAds = [];
      _adsError = null;
      _loadProfileData();
    }
    setState(() {});
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    final identity = _identity;
    if (identity == null) {
      setState(() {
        _myAds = [];
        _loadingAds = false;
      });
      return;
    }
    setState(() {
      _loadingAds = true;
      _adsError = null;
    });
    try {
      await _state.fetchMe();
      if (!mounted || identity != _identity) return;
      final res = await _state.api.dio.get('/my-ads');
      if (res.data is! Map ||
          res.data['data'] is! List ||
          (res.data['status'] != null && res.data['status'] != 'success')) {
        throw StateError('Invalid ads response');
      }
      final parsed = (res.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted || identity != _identity) return;
      setState(() {
        _myAds = parsed;
        _loadingAds = false;
      });
    } catch (_) {
      if (!mounted || identity != _identity) return;
      setState(() {
        _loadingAds = false;
        _adsError = _state.s.tr('تعذر تحميل الإعلانات. اسحب للمحاولة مجدداً.',
            'Impossible de charger les annonces. Réessayez en actualisant.');
      });
    }
  }

  int? get _baseViews {
    if (_loadingAds || _adsError != null) return null;
    var total = 0;
    for (final ad in _myAds) {
      final views =
          int.tryParse((ad['views_count'] ?? ad['views'] ?? '').toString());
      if (views == null || views < 0) return null;
      total += views;
    }
    return total;
  }

  String _displayName(bool isAr) =>
      _state.currentUser?['name']?.toString().trim() ??
      (isAr ? 'حسابي' : 'Mon compte');
  String get _displayHandle =>
      _state.currentUser?['username']?.toString() ?? 'profil';
  String _displayBio(bool isAr) => _state.currentUser?['bio']?.toString() ?? '';
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    if (!_state.isLoggedIn) {
      return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(title: Text(s.profile), actions: [
            IconButton(
                key: const Key('guest-settings'),
                tooltip: s.tr('الإعدادات والدعم', 'Paramètres et assistance'),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
                icon: const Icon(Icons.settings_outlined)),
          ]),
          body: Center(
              child: ElevatedButton(
            key: const Key('profile-sign-in'),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()));
              if (mounted) {
                _profileIdentity = _identity;
                await _loadProfileData();
              }
            },
            child: Text(s.tr('سجّل الدخول لعرض حسابك',
                'Connectez-vous pour voir votre profil')),
          )));
    }
    final name = _displayName(isAr);
    final handle = _displayHandle;
    final bio = _displayBio(isAr);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _primary,
          backgroundColor: Colors.white,
          onRefresh: _loadProfileData,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // 1. Balanced Apple Top Bar: [+] on start, [profile] in center, [Settings] on end
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // + Add Ad Button
                      PressableScale(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PostAdScreen()),
                        ).then((_) => _loadProfileData()),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: _surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.add,
                            color: _ink,
                            size: 21,
                          ),
                        ),
                      ),

                      // Centered @username
                      Expanded(
                        child: Text(
                          '@$handle',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            letterSpacing:
                                AppTypography.trackingForContext(context, -0.3),
                          ),
                        ),
                      ),

                      // Apolo Reels Video Feed Button
                      PressableScale(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdReelsScreen(),
                          ),
                        ),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE31B23), Color(0xFFFF3366)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE31B23)
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.play_rectangle_fill,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Standalone Settings Page Button
                      PressableScale(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              onOpenEditProfile: () =>
                                  _openEditProfileSheet(isAr),
                            ),
                          ),
                        ).then((_) {
                          if (mounted) setState(() {});
                        }),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: _surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.gear,
                            color: _ink,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Generous Whitespace Identity Block with Edit Profile Icon
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                  child: Column(
                    children: [
                      // Avatar + Edit Photo/Profile Badge
                      GestureDetector(
                        onTap: () => _openEditProfileSheet(isAr),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: _surface,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: _hairline, width: 1.5),
                              ),
                              clipBehavior: Clip.antiAlias,
                              alignment: Alignment.center,
                              child: _buildAvatarContent(name),
                            ),
                            PositionedDirectional(
                              bottom: 0,
                              end: -2,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: _ink,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2.5),
                                ),
                                child: const Icon(
                                  CupertinoIcons.pencil,
                                  color: Colors.white,
                                  size: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Name + Verified Check + Subtle Edit Icon
                      GestureDetector(
                        onTap: () => _openEditProfileSheet(isAr),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                  letterSpacing:
                                      AppTypography.trackingForContext(
                                          context, -0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Clean 1-line Bio
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 290),
                        child: Text(
                          bio,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _muted,
                            height: 1.4,
                          ),
                        ),
                      ),

                      if (!_state.isLoggedIn) ...[
                        const SizedBox(height: 12),
                        PressableScale(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AuthScreen()),
                          ).then((_) => _loadProfileData()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isAr
                                  ? 'تسجيل الدخول أو إنشاء حساب'
                                  : 'Se connecter',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 26),

                      // 3 Airy Tabular Metrics with generous negative space
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMinimalStat(
                            value: '${_myAds.length}',
                            label: isAr ? 'إعلاناتي' : 'Annonces',
                            onTap: () => setState(() => _activeTab = 0),
                          ),
                          Container(width: 1, height: 24, color: _hairline),
                          _buildMinimalStat(
                            value: _baseViews?.toString() ?? '—',
                            label: isAr ? 'مشاهدة' : 'Vues',
                            onTap: () => setState(() => _activeTab = 1),
                          ),
                          Container(width: 1, height: 24, color: _hairline),
                          _buildMinimalStat(
                            value: '—',
                            label: isAr ? 'النمو' : 'Croissance',
                            valueColor: _muted,
                            onTap: () => setState(() => _activeTab = 1),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Apolo Reels 2026 Visual Discovery Banner
                      PressableScale(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdReelsScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: _ink.withValues(alpha: 0.14),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE31B23),
                                      Color(0xFFFF3366)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  CupertinoIcons.play_rectangle_fill,
                                  color: Colors.white,
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
                                        Text(
                                          isAr
                                              ? 'ريلز وسكرول الإعلانات 🎬'
                                              : 'Apolo Reels 2026 🎬',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE31B23),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'NEW',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isAr
                                          ? 'تصفح العروض بالفيديو والصور بـ سكرول عمودي سريع'
                                          : 'Scrollez les annonces en plein écran façon Reels',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.72),
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
                                color: Colors.white70,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Minimal Apple Segmented Control
                      Container(
                        height: 44,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _buildSegmentButton(
                              index: 0,
                              label: isAr ? 'إعلاناتي' : 'Mes annonces',
                              icon: CupertinoIcons.square_grid_2x2,
                            ),
                            _buildSegmentButton(
                              index: 1,
                              label: isAr
                                  ? 'الإحصائيات و Boost'
                                  : 'Statistiques & Boost',
                              icon: CupertinoIcons.chart_bar,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Content Area with Generous Padding
              if (_loadingAds)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const AdGridCardSkeleton(),
                      childCount: 4,
                    ),
                  ),
                )
              else if (_activeTab == 0)
                _buildCleanAdsGrid(isAr)
              else
                SliverToBoxAdapter(
                  child: _buildUpgradedInsightsStudio(isAr),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(String name) {
    final avatarUrl = _state.currentUser?['avatar']?.toString();
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return AppImage(url: avatarUrl, width: 88, height: 88, fit: BoxFit.cover);
    }
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'A',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: _ink,
        letterSpacing: AppTypography.trackingForContext(context, -0.5),
      ),
    );
  }

  Widget _buildMinimalStat({
    required String value,
    required String label,
    required VoidCallback onTap,
    Color valueColor = _ink,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: valueColor,
                letterSpacing: AppTypography.trackingForContext(context, -0.5),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final selected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? _ink : _muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? _ink : _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab 0: Clean, Airy Instagram/Apple Grid of User's Ads
  Widget _buildCleanAdsGrid(bool isAr) {
    if (_adsError != null) {
      return SliverToBoxAdapter(
          child: Padding(
              padding: const EdgeInsets.all(24), child: Text(_adsError!)));
    }
    if (_myAds.isEmpty) {
      return SliverToBoxAdapter(
        child: IllustratedStateView(
          assetPath: 'assets/images/state_empty_ads.png',
          imageSize: 160,
          title: isAr ? 'لا توجد إعلانات منشورة' : 'Aucune annonce publiée',
          subtitle: isAr
              ? 'انشر إعلانك الأول ليظهر هنا في معرضك الخاص.'
              : 'Publiez votre première annonce pour l’afficher ici.',
          actionLabel: isAr ? 'إضافة إعلان' : 'Publier une annonce',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostAdScreen()),
          ).then((_) => _loadProfileData()),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 16,
          childAspectRatio: 0.76,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ad = _myAds[index];
            final adId = int.tryParse((ad['id'] ?? index).toString()) ?? index;
            final title = (ad['title'] ?? '').toString();
            final imgUrl =
                (ad['main_image'] ?? ad['primary_image'] ?? '').toString();
            final priceStr = (ad['price_formatted'] ??
                    (ad['price'] != null
                        ? '${ad['price']} ${isAr ? 'د.م' : 'DH'}'
                        : ''))
                .toString();

            return ScrollReveal(
              key: ValueKey('clean_ad_$adId'),
              delay: Duration(milliseconds: 50 * (index % 6)),
              child: PressableScale(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdDetailScreen(adId: adId, initialAd: ad),
                  ),
                ),
                onLongPress: () => _showAdQuickActions(ad, isAr),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              color: _surface,
                              child: AppImage(url: imgUrl, fit: BoxFit.cover),
                            ),
                            PositionedDirectional(
                              bottom: 10,
                              end: 10,
                              child: GestureDetector(
                                onTap: () =>
                                    _openBoostModal(adId: adId, adTitle: title),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.94),
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.bolt_fill,
                                        color: _primary,
                                        size: 11,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Boost',
                                        style: TextStyle(
                                          color: _ink,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                        letterSpacing:
                            AppTypography.trackingForContext(context, -0.2),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (priceStr.isNotEmpty)
                      PriceText(
                        priceStr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _muted,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          childCount: _myAds.length,
        ),
      ),
    );
  }

  /// Tab 1: Upgraded Apple-Style Insights & Boost Studio (Period Switcher, Funnel, Cities, Ad Ranking)
  Widget _buildUpgradedInsightsStudio(bool isAr) {
    return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                isAr
                    ? 'مشاهدات الإعلانات الحالية'
                    : 'Vues des annonces actuelles',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(_baseViews?.toString() ??
                (isAr
                    ? 'عدد المشاهدات غير متاح.'
                    : 'Nombre de vues indisponible.')),
            const SizedBox(height: 12),
            Text(
                isAr
                    ? 'إحصائيات النمو والرسائل والمناطق والفترات الزمنية غير متاحة حالياً.'
                    : 'Les statistiques de croissance, contacts, régions et périodes ne sont pas disponibles.',
                style: const TextStyle(color: _muted)),
          ],
        ));
  }

  void _openBoostModal({required int adId, required String adTitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BoostSheet(adId: adId, adTitle: adTitle),
    );
  }

  // Profile identity is server-backed. Never read legacy unscoped preferences.
  Future<void> _openEditProfileSheet(bool isAr) async {
    final identity = _identity;
    if (identity == null) return;
    final nameCtrl = TextEditingController(text: _displayName(isAr));
    final bioCtrl = TextEditingController(text: _displayBio(isAr));
    final phoneCtrl = TextEditingController(
        text: _state.currentUser?['phone']?.toString() ?? '');
    bool saving = false;
    String? error;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, update) => PopScope(
                canPop: !saving,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
                  child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(isAr ? 'تعديل البروفايل' : 'Modifier le profil',
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 20),
                    IgnorePointer(
                        ignoring: saving,
                        child: Column(children: [
                          _buildEditField(
                              label: isAr ? 'الاسم الكامل' : 'Nom complet',
                              controller: nameCtrl,
                              icon: CupertinoIcons.person),
                          const SizedBox(height: 12),
                          _buildEditField(
                              label: isAr ? 'النبذة التعريفية' : 'Biographie',
                              controller: bioCtrl,
                              icon: CupertinoIcons.text_alignleft,
                              maxLines: 2),
                          const SizedBox(height: 12),
                          _buildEditField(
                              label: isAr ? 'رقم الهاتف' : 'Téléphone',
                              controller: phoneCtrl,
                              icon: CupertinoIcons.phone,
                              keyboardType: TextInputType.phone),
                        ])),
                    if (error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(error!,
                              style: const TextStyle(color: _primary))),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        key: const Key('profile-save'),
                        onPressed: saving
                            ? null
                            : () async {
                                if (identity != _identity) return;
                                if (nameCtrl.text.trim().isEmpty) {
                                  update(() => error = isAr
                                      ? 'الاسم مطلوب.'
                                      : 'Le nom est requis.');
                                  return;
                                }
                                final values = {
                                  'name': nameCtrl.text.trim(),
                                  'bio': bioCtrl.text.trim(),
                                  'phone': phoneCtrl.text.trim()
                                };
                                update(() {
                                  saving = true;
                                  error = null;
                                });
                                try {
                                  final response = await _state.api.dio
                                      .put('/auth/profile', data: values);
                                  if (response.data is! Map ||
                                      response.data['status'] != 'success') {
                                    throw StateError(
                                        'Profile update not confirmed');
                                  }
                                  if (!mounted || identity != _identity) return;
                                  final user = response.data['user'];
                                  _state.currentUser = {
                                    ...?_state.currentUser,
                                    ...values,
                                    if (user is Map)
                                      ...Map<String, dynamic>.from(user)
                                  };
                                  setState(() {});
                                  if (ctx.mounted) {
                                    update(() => saving = false);
                                    Navigator.pop(ctx);
                                  }
                                } catch (_) {
                                  if (ctx.mounted) {
                                    update(() => error = isAr
                                        ? 'تعذر حفظ التغييرات. حاول مجدداً.'
                                        : 'Enregistrement impossible. Réessayez.');
                                  }
                                } finally {
                                  if (ctx.mounted) update(() => saving = false);
                                }
                              },
                        child: Text(saving
                            ? (isAr ? 'جارٍ الحفظ...' : 'Enregistrement...')
                            : (isAr ? 'حفظ التغييرات' : 'Enregistrer'))),
                  ])),
                ),
              )),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    nameCtrl.dispose();
    bioCtrl.dispose();
    phoneCtrl.dispose();
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _muted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: _muted),
            filled: true,
            fillColor: _surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _ink, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  void _showAdQuickActions(Map<String, dynamic> ad, bool isAr) {
    final adId = int.tryParse((ad['id'] ?? '').toString());
    if (!_state.isLoggedIn || adId == null || adId <= 0) return;
    final title = (ad['title'] ?? '').toString();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(CupertinoIcons.bolt_fill, color: _primary),
                title: Text(
                    isAr ? 'تمويل الإعلان (Boost)' : 'Booster cette annonce'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openBoostModal(adId: adId, adTitle: title);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.trash, color: _primary),
                title: Text(
                  isAr ? 'حذف الإعلان' : 'Supprimer l’annonce',
                  style: const TextStyle(color: _primary),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _deleteAd(adId, isAr);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAd(int adId, bool isAr) async {
    if (!_state.isLoggedIn || _deletingAds.contains(adId)) return;
    final identity = _identity;
    _deletingAds.add(adId);
    try {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                title:
                    Text(isAr ? 'حذف الإعلان؟' : 'Supprimer cette annonce ?'),
                content: Text(isAr
                    ? 'لا يمكن التراجع عن الحذف.'
                    : 'Cette action est irréversible.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(isAr ? 'إلغاء' : 'Annuler')),
                  TextButton(
                      key: const Key('profile-confirm-delete'),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(isAr ? 'حذف' : 'Supprimer')),
                ],
              ));
      if (confirmed != true || !mounted || identity != _identity) return;
      final response = await _state.api.dio.delete('/ads/$adId');
      if (response.statusCode != 204 &&
          (response.data is! Map || response.data['status'] != 'success')) {
        throw StateError('Deletion not confirmed');
      }
      if (!mounted || identity != _identity) return;
      setState(() =>
          _myAds.removeWhere((ad) => ad['id'].toString() == adId.toString()));
    } catch (_) {
      if (identity == _identity) {
        _showError(isAr
            ? 'تعذر حذف الإعلان. حاول مجدداً.'
            : 'Suppression impossible. Réessayez.');
      }
    } finally {
      _deletingAds.remove(adId);
    }
  }
}
