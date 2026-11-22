import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import 'ad_detail_screen.dart';
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
  final ScrollController _scrollController = ScrollController();

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

  static const Color _primary = Color(0xFF0A0A0A);
  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _surface = Color(0xFFF2F3F7);
  static const Color _hairline = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _profileIdentity = _identity;
    _state.addListener(_onAccountChanged);
    _state.tabReselectCounter.addListener(_scrollToTop);
    _loadProfileData();
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
    _state.removeListener(_onAccountChanged);
    _state.tabReselectCounter.removeListener(_scrollToTop);
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    if (!_state.isLoggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F3F7),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF2F3F7),
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 48,
          centerTitle: true,
          title: Text(
            s.profile,
            style: const TextStyle(
              color: Color(0xFF0A0A0A),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              key: const Key('guest-settings'),
              tooltip: s.tr('الإعدادات والدعم', 'Paramètres et assistance'),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
              icon: const Icon(CupertinoIcons.gear, color: Color(0xFF0A0A0A)),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F3F7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.person_fill,
                        size: 34,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.tr('مرحباً بك في Apolo', 'Bienvenue sur Apolo',
                          'Welcome to Apolo'),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.tr(
                        'سجّل الدخول لإدارة إعلاناتك، المفضلة، والمحادثات الفورية مع المشترين.',
                        'Connectez-vous pour gérer vos annonces, vos favoris et vos messages.',
                        'Sign in to manage your listings, saved items, and instant chats.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF6B7280),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        key: const Key('profile-sign-in'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A0A0A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AuthScreen()));
                          if (mounted) {
                            _profileIdentity = _identity;
                            await _loadProfileData();
                          }
                        },
                        child: Text(
                          s.tr('سجّل الدخول لعرض حسابك',
                              'Connectez-vous pour voir votre profil'),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    final name = _displayName(isAr);
    final handle = _displayHandle;
    final bio = _displayBio(isAr);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
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
              // 1. Clean Top Bar: [+] on start, [@handle] in center, [Reels + Settings] on end
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
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
                            color: Colors.white,
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
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                            letterSpacing:
                                AppTypography.trackingForContext(context, -0.3),
                          ),
                        ),
                      ),

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
                            color: Colors.white,
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

              // 2. White Grouped Identity + Metrics Card (Instagram-style Profile + @username + Bio)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
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
                                      border: Border.all(
                                          color: _hairline, width: 1.5),
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
                                        CupertinoIcons.camera_fill,
                                        color: Colors.white,
                                        size: 13.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Name + Edit tap
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
                                        fontSize: 21,
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
                            const SizedBox(height: 3),
                            Text(
                              '@$handle',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _muted,
                              ),
                            ),
                            if (bio.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 300),
                                child: Text(
                                  bio,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: _ink,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),

                            // Instagram-style Edit Profile Pill Button
                            PressableScale(
                              onTap: () => _openEditProfileSheet(isAr),
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: _surface,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.pencil,
                                      size: 14,
                                      color: _ink,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      s.tr(
                                        'تعديل الملف الشخصي',
                                        'Modifier le profil',
                                        'Edit profile',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),
                            const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFF1F2F6)),
                            const SizedBox(height: 16),

                            // 3 Airy Tabular Metrics
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildMinimalStat(
                                  value: '${_myAds.length}',
                                  label: isAr ? 'إعلاناتي' : 'Annonces',
                                  onTap: () => setState(() => _activeTab = 0),
                                ),
                                Container(
                                    width: 1, height: 24, color: _hairline),
                                _buildMinimalStat(
                                  value: _baseViews?.toString() ?? '—',
                                  label: isAr ? 'مشاهدة' : 'Vues',
                                  onTap: () => setState(() => _activeTab = 1),
                                ),
                                Container(
                                    width: 1, height: 24, color: _hairline),
                                _buildMinimalStat(
                                  value: '—',
                                  label: isAr ? 'النمو' : 'Croissance',
                                  valueColor: _muted,
                                  onTap: () => setState(() => _activeTab = 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Clean White Segmented Control
                      Container(
                        height: 44,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                              top: 8,
                              end: 8,
                              child: GestureDetector(
                                onTap: () => _showAdQuickActions(ad, isAr),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.94),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    CupertinoIcons.ellipsis,
                                    color: _ink,
                                    size: 16,
                                  ),
                                ),
                              ),
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

  /// Tab 1: 2026 Monochrome Mobile Seller Analytics & Boost Dashboard
  Widget _buildUpgradedInsightsStudio(bool isAr) {
    final totalAds = _myAds.length;
    final totalViews = _baseViews ?? 0;
    final avgViews = totalAds > 0 ? (totalViews / totalAds).round() : 0;
    final boostedCount = _myAds
        .where((ad) =>
            ad['is_vip'] == true ||
            ad['is_featured'] == true ||
            ad['is_highlighted'] == true)
        .length;

    final sortedAds = List<Map<String, dynamic>>.from(_myAds)
      ..sort((a, b) {
        final va =
            int.tryParse((a['views_count'] ?? a['views'] ?? 0).toString()) ?? 0;
        final vb =
            int.tryParse((b['views_count'] ?? b['views'] ?? 0).toString()) ?? 0;
        return vb.compareTo(va);
      });
    final topChartAds = sortedAds.take(6).toList();
    final maxViews = topChartAds.fold<int>(
      1,
      (prev, ad) {
        final v =
            int.tryParse((ad['views_count'] ?? ad['views'] ?? 0).toString()) ??
                0;
        return v > prev ? v : prev;
      },
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 2x2 KPI Bento Grid
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsKpiCard(
                  icon: CupertinoIcons.eye_fill,
                  label: isAr ? 'إجمالي المشاهدات' : 'Vues totales',
                  value: _baseViews?.toString() ?? '0',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAnalyticsKpiCard(
                  icon: CupertinoIcons.square_grid_2x2_fill,
                  label: isAr ? 'الإعلانات النشطة' : 'Annonces actives',
                  value: '$totalAds',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsKpiCard(
                  icon: CupertinoIcons.chart_bar_fill,
                  label: isAr ? 'متوسط المشاهدات' : 'Moy. / annonce',
                  value: '$avgViews',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAnalyticsKpiCard(
                  icon: CupertinoIcons.bolt_fill,
                  label: isAr ? 'إعلانات ممولة' : 'Annonces Boost',
                  value: '$boostedCount',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Mobile Performance Bar Chart Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'توزيع المشاهدات' : 'Répartition des vues',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isAr ? 'مباشر' : 'En direct',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (topChartAds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        isAr
                            ? 'انشر إعلانك الأول لتبدأ متابعة المشاهدات والأداء هنا.'
                            : 'Publiez votre première annonce pour suivre vos vues ici.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _muted,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 132,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(topChartAds.length, (i) {
                        final ad = topChartAds[i];
                        final v = int.tryParse(
                                (ad['views_count'] ?? ad['views'] ?? 0)
                                    .toString()) ??
                            0;
                        final ratio = (v / maxViews).clamp(0.12, 1.0);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '$v',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 320),
                                  height: 82 * ratio,
                                  decoration: BoxDecoration(
                                    color: i == 0
                                        ? _ink
                                        : const Color(0xFFD1D5DB),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '#${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Top Performing Ads Ranking (with 1-tap Edit & Boost)
          if (sortedAds.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'أفضل إعلاناتك أداءً' : 'Vos meilleures annonces',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...sortedAds.take(5).map((ad) {
                    final adId = int.tryParse((ad['id'] ?? 0).toString()) ?? 0;
                    final title = (ad['title'] ?? '').toString();
                    final imgUrl =
                        (ad['main_image'] ?? ad['primary_image'] ?? '')
                            .toString();
                    final views = int.tryParse(
                            (ad['views_count'] ?? ad['views'] ?? 0)
                                .toString()) ??
                        0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 48,
                              height: 48,
                              color: _surface,
                              child: AppImage(url: imgUrl, fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      CupertinoIcons.eye_fill,
                                      size: 12,
                                      color: _muted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$views ${isAr ? 'مشاهدة' : 'vues'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PostAdScreen(initialAd: ad),
                              ),
                            ).then((_) => _loadProfileData()),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: _surface,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                CupertinoIcons.pencil,
                                size: 15,
                                color: _ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () =>
                                _openBoostModal(adId: adId, adTitle: title),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _ink,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Boost',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 4. Smart Actionable Tip Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.sparkles,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'نصيحة لزيادة المبيعات' : 'Conseil de vente',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        sortedAds.isEmpty
                            ? (isAr
                                ? 'أضف صوراً واضحة وثمناً مناسباً في إعلانك الأول لجذب المشترين بسرعة.'
                                : 'Ajoutez des photos nettes et un prix clair pour attirer plus d’acheteurs.')
                            : (isAr
                                ? 'تحديث الصور والوصف أو تمويل إعلانك الأكثر مشاهدة يضاعف فرص البيع.'
                                : 'Mettre à jour vos photos ou booster votre meilleure annonce accélère la vente.'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.78),
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
    );
  }

  Widget _buildAnalyticsKpiCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: _surface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: _ink),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _ink,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
        ],
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

  static const List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&w=400&q=80',
  ];

  // Full-screen Instagram-style Edit Profile Screen (Photo, Name, @username, Bio)
  Future<void> _openEditProfileSheet(bool isAr) async {
    final identity = _identity;
    if (identity == null) return;
    final nameCtrl = TextEditingController(text: _displayName(isAr));
    final initialHandle = _displayHandle.replaceAll('@', '').toLowerCase();
    final usernameCtrl = TextEditingController(text: initialHandle);
    final bioCtrl = TextEditingController(text: _displayBio(isAr));
    String selectedAvatar =
        (_state.currentUser?['avatar'] ?? '').toString().trim();
    bool saving = false;
    String? error;

    // Instagram-style live unique @username check state
    Timer? usernameDebounce;
    bool checkingUsername = false;
    bool? usernameAvailable; // null = unchanged, true = available, false = taken/invalid
    String? usernameStatusMsg;
    List<String> usernameSuggestions = [];
    int checkSeq = 0;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, update) {
            Future<void> pickFromGallery() async {
              try {
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 82,
                );
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  final b64 = base64Encode(bytes);
                  update(() {
                    selectedAvatar = 'data:image/jpeg;base64,$b64';
                  });
                }
              } catch (_) {}
            }

            void showAvatarPickerSheet() {
              HapticFeedback.selectionClick();
              showModalBottomSheet<void>(
                context: ctx,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (sheetCtx) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1D5DB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isAr
                              ? 'تغيير صورة الملف الشخصي'
                              : 'Changer la photo de profil',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: _surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.photo_on_rectangle,
                              color: _ink,
                              size: 19,
                            ),
                          ),
                          title: Text(
                            isAr
                                ? 'اختيار صورة من المعرض'
                                : 'Choisir depuis la galerie',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(sheetCtx);
                            pickFromGallery();
                          },
                        ),
                        if (selectedAvatar.isNotEmpty)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEF2F2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.trash,
                                color: Color(0xFFE31B23),
                                size: 19,
                              ),
                            ),
                            title: Text(
                              isAr
                                  ? 'إزالة الصورة الحالية'
                                  : 'Supprimer la photo actuelle',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE31B23),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              update(() => selectedAvatar = '');
                            },
                          ),
                        const SizedBox(height: 10),
                        Text(
                          isAr
                              ? 'أو اختر أفاتار جاهز'
                              : 'Ou choisir un avatar',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _muted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 58,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _presetAvatars.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (_, i) {
                              final url = _presetAvatars[i];
                              final isSel = selectedAvatar == url;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  update(() => selectedAvatar = url);
                                  Navigator.pop(sheetCtx);
                                },
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSel ? _ink : _hairline,
                                      width: isSel ? 2.5 : 1,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: ClipOval(
                                    child: AppImage(
                                      url: url,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
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
                ),
              );
            }

            return PopScope(
              canPop: !saving,
              child: Scaffold(
                backgroundColor: const Color(0xFFF2F3F7),
                appBar: AppBar(
                  backgroundColor: const Color(0xFFF2F3F7),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(CupertinoIcons.xmark,
                        color: _ink, size: 20),
                    onPressed: saving ? null : () => Navigator.pop(ctx),
                  ),
                  title: Text(
                    isAr ? 'تعديل الملف الشخصي' : 'Modifier le profil',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: IgnorePointer(
                      ignoring: saving,
                      child: Column(
                        children: [
                          // 1. Instagram-style Avatar Header Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 22,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              children: [
                                GestureDetector(
                                  key: const Key('profile-change-photo'),
                                  onTap: showAvatarPickerSheet,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 96,
                                        height: 96,
                                        decoration: BoxDecoration(
                                          color: _surface,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _hairline,
                                            width: 1.5,
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        alignment: Alignment.center,
                                        child: selectedAvatar.isNotEmpty
                                            ? AppImage(
                                                url: selectedAvatar,
                                                width: 96,
                                                height: 96,
                                                fit: BoxFit.cover,
                                              )
                                            : Text(
                                                nameCtrl.text.trim().isNotEmpty
                                                    ? nameCtrl.text
                                                        .trim()[0]
                                                        .toUpperCase()
                                                    : 'A',
                                                style: const TextStyle(
                                                  fontSize: 34,
                                                  fontWeight: FontWeight.w800,
                                                  color: _ink,
                                                ),
                                              ),
                                      ),
                                      PositionedDirectional(
                                        bottom: 0,
                                        end: -2,
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: _ink,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2.5,
                                            ),
                                          ),
                                          child: const Icon(
                                            CupertinoIcons.camera_fill,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: showAvatarPickerSheet,
                                  child: Text(
                                    isAr
                                        ? 'تغيير صورة الملف الشخصي'
                                        : 'Changer la photo de profil',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: _ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // 2. White Grouped Card: Name, @username, Bio (3 TextFields)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              children: [
                                _buildEditField(
                                  label:
                                      isAr ? 'الاسم الكامل' : 'Nom complet',
                                  controller: nameCtrl,
                                  icon: CupertinoIcons.person,
                                ),
                                const SizedBox(height: 14),
                                _buildEditField(
                                  label: isAr
                                      ? 'اسم المستخدم (@username)'
                                      : 'Nom d’utilisateur (@username)',
                                  controller: usernameCtrl,
                                  icon: CupertinoIcons.at,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9._]'),
                                    ),
                                    LengthLimitingTextInputFormatter(30),
                                  ],
                                  suffixIcon: checkingUsername
                                      ? const Padding(
                                          padding: EdgeInsets.all(13),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: _muted,
                                            ),
                                          ),
                                        )
                                      : (usernameAvailable == true
                                          ? const Icon(
                                              CupertinoIcons
                                                  .check_mark_circled_solid,
                                              color: Color(0xFF10B981),
                                              size: 20,
                                            )
                                          : (usernameAvailable == false
                                              ? const Icon(
                                                  CupertinoIcons
                                                      .xmark_circle_fill,
                                                  color: Color(0xFFE31B23),
                                                  size: 20,
                                                )
                                              : null)),
                                  onChanged: (raw) {
                                    usernameDebounce?.cancel();
                                    final clean = raw
                                        .trim()
                                        .replaceAll('@', '')
                                        .toLowerCase();
                                    if (clean == initialHandle &&
                                        clean.length >= 3) {
                                      update(() {
                                        checkingUsername = false;
                                        usernameAvailable = null;
                                        usernameStatusMsg = null;
                                        usernameSuggestions = [];
                                      });
                                      return;
                                    }
                                    if (clean.length < 3) {
                                      update(() {
                                        checkingUsername = false;
                                        usernameAvailable = false;
                                        usernameStatusMsg = isAr
                                            ? 'يجب أن يكون 3 أحرف على الأقل'
                                            : 'Minimum 3 caractères requis';
                                        usernameSuggestions = [];
                                      });
                                      return;
                                    }
                                    final seq = ++checkSeq;
                                    update(() {
                                      checkingUsername = true;
                                      usernameAvailable = null;
                                      usernameStatusMsg = null;
                                      usernameSuggestions = [];
                                      error = null;
                                    });
                                    usernameDebounce = Timer(
                                      const Duration(milliseconds: 420),
                                      () async {
                                        try {
                                          final res = await _state.api.dio.get(
                                            '/auth/username/check',
                                            queryParameters: {
                                              'username': clean
                                            },
                                          );
                                          if (!ctx.mounted || seq != checkSeq) {
                                            return;
                                          }
                                          final data = res.data is Map
                                              ? res.data as Map
                                              : const {};
                                          final avail =
                                              data['available'] == true;
                                          final msg =
                                              data['message']?.toString();
                                          final rawSugg = data['suggestions'];
                                          final sugg = rawSugg is List
                                              ? rawSugg
                                                  .map((e) => e.toString())
                                                  .where((e) => e.isNotEmpty)
                                                  .toList()
                                              : <String>[];
                                          update(() {
                                            checkingUsername = false;
                                            usernameAvailable = avail;
                                            usernameStatusMsg = avail
                                                ? (isAr
                                                    ? 'اسم المستخدم @$clean متاح!'
                                                    : '@$clean est disponible !')
                                                : (msg ??
                                                    (isAr
                                                        ? 'اسم المستخدم محجوز بالفعل.'
                                                        : 'Déjà utilisé.'));
                                            usernameSuggestions = sugg;
                                          });
                                        } catch (_) {
                                          if (!ctx.mounted || seq != checkSeq) {
                                            return;
                                          }
                                          update(() {
                                            checkingUsername = false;
                                          });
                                        }
                                      },
                                    );
                                  },
                                ),
                                if (usernameStatusMsg != null) ...[
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      usernameStatusMsg!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: usernameAvailable == true
                                            ? const Color(0xFF059669)
                                            : const Color(0xFFE31B23),
                                      ),
                                    ),
                                  ),
                                ],
                                if (usernameSuggestions.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: usernameSuggestions.map((sugg) {
                                        return GestureDetector(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            usernameDebounce?.cancel();
                                            usernameCtrl.text = sugg;
                                            usernameCtrl.selection =
                                                TextSelection.fromPosition(
                                              TextPosition(offset: sugg.length),
                                            );
                                            update(() {
                                              checkingUsername = false;
                                              usernameAvailable = true;
                                              usernameStatusMsg = isAr
                                                  ? 'اسم المستخدم @$sugg متاح!'
                                                  : '@$sugg est disponible !';
                                              usernameSuggestions = [];
                                              error = null;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F4F6),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: const Color(0xFFE5E7EB),
                                              ),
                                            ),
                                            child: Text(
                                              '@$sugg',
                                              textDirection: TextDirection.ltr,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: _ink,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                _buildEditField(
                                  label: isAr
                                      ? 'النبذة التعريفية (Bio)'
                                      : 'Biographie (Bio)',
                                  controller: bioCtrl,
                                  icon: CupertinoIcons.text_alignleft,
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),

                          if (error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text(
                                error!,
                                style: const TextStyle(
                                  color: Color(0xFFE31B23),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                          const SizedBox(height: 22),

                          // 3. Full-width Pill Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              key: const Key('profile-save'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _ink,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
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
                                      final cleanUsername = usernameCtrl.text
                                          .trim()
                                          .replaceAll('@', '')
                                          .toLowerCase();
                                      if (cleanUsername.length < 3) {
                                        update(() => error = isAr
                                            ? 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل.'
                                            : 'Le nom d’utilisateur doit contenir au moins 3 caractères.');
                                        return;
                                      }
                                      if (usernameAvailable == false) {
                                        update(() => error = usernameStatusMsg ??
                                            (isAr
                                                ? 'اسم المستخدم هذا محجوز بالفعل، اختر اسماً آخر.'
                                                : 'Ce nom d’utilisateur est déjà pris.'));
                                        return;
                                      }
                                      final values = <String, dynamic>{
                                        'name': nameCtrl.text.trim(),
                                        'username': cleanUsername,
                                        'bio': bioCtrl.text.trim(),
                                        'avatar': selectedAvatar,
                                      };
                                      update(() {
                                        saving = true;
                                        error = null;
                                      });
                                      try {
                                        final response = await _state.api.dio
                                            .put('/auth/profile', data: values);
                                        if (response.data is! Map ||
                                            response.data['status'] !=
                                                'success') {
                                          throw StateError(
                                              'Profile update not confirmed');
                                        }
                                        if (!mounted ||
                                            identity != _identity) {
                                          return;
                                        }
                                        final user = response.data['user'];
                                        final returnedAvatar = (user is Map
                                                ? (user['avatar_url'] ??
                                                    user['avatar'])
                                                : null)
                                            ?.toString();
                                        await _state.updateCurrentUser({
                                          ...?_state.currentUser,
                                          ...values,
                                          if (user is Map)
                                            ...Map<String, dynamic>.from(user),
                                          'name': nameCtrl.text.trim(),
                                          'username': cleanUsername,
                                          'bio': bioCtrl.text.trim(),
                                          'avatar': (returnedAvatar != null &&
                                                  returnedAvatar.isNotEmpty)
                                              ? returnedAvatar
                                              : selectedAvatar,
                                        });
                                        if (!mounted || identity != _identity) {
                                          return;
                                        }
                                        setState(() {});
                                        if (ctx.mounted) {
                                          update(() => saving = false);
                                          Navigator.pop(ctx);
                                        }
                                      } catch (e) {
                                        String errText = isAr
                                            ? 'تعذر حفظ التغييرات. حاول مجدداً.'
                                            : 'Enregistrement impossible. Réessayez.';
                                        if (e is DioException &&
                                            e.response?.data is Map) {
                                          final serverMsg = e.response!
                                              .data['message']
                                              ?.toString()
                                              .trim();
                                          if (serverMsg != null &&
                                              serverMsg.isNotEmpty) {
                                            errText = serverMsg;
                                          }
                                        }
                                        if (ctx.mounted) {
                                          update(() => error = errText);
                                        }
                                      } finally {
                                        if (ctx.mounted) {
                                          update(() => saving = false);
                                        }
                                      }
                                    },
                              child: Text(
                                saving
                                    ? (isAr
                                        ? 'جارٍ الحفظ...'
                                        : 'Enregistrement...')
                                    : (isAr ? 'حفظ التغييرات' : 'Enregistrer'),
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    usernameDebounce?.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    nameCtrl.dispose();
    usernameCtrl.dispose();
    bioCtrl.dispose();
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
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
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: _muted),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: _surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _ink, width: 1.4),
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
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.pencil, color: _ink),
                title: Text(
                  isAr ? 'تعديل الإعلان' : 'Modifier l’annonce',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostAdScreen(initialAd: ad),
                    ),
                  ).then((_) => _loadProfileData());
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.bolt_fill, color: _ink),
                title: Text(
                  isAr ? 'تمويل الإعلان (Boost)' : 'Booster cette annonce',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openBoostModal(adId: adId, adTitle: title);
                },
              ),
              ListTile(
                leading: const Icon(
                  CupertinoIcons.trash,
                  color: Color(0xFFE31B23),
                ),
                title: Text(
                  isAr ? 'حذف الإعلان' : 'Supprimer l’annonce',
                  style: const TextStyle(
                    color: Color(0xFFE31B23),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _deleteAd(ad, adId, isAr);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAd(
    Map<String, dynamic> ad,
    int adId,
    bool isAr,
  ) async {
    if (!_state.isLoggedIn || _deletingAds.contains(adId)) return;
    final identity = _identity;
    _deletingAds.add(adId);

    final adTitle = (ad['title'] ?? '').toString().trim();
    final adPrice = (ad['price_formatted'] ?? '').toString().trim();
    final adImage = (ad['main_image'] ??
            (ad['images'] is List && (ad['images'] as List).isNotEmpty
                ? (ad['images'] as List).first
                : ''))
        .toString()
        .trim();

    bool deleting = false;
    String? dialogError;

    try {
      final deleted = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierLabel: isAr ? 'إغلاق' : 'Fermer',
        barrierColor: Colors.black.withValues(alpha: 0.48),
        transitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (dialogCtx, animation, secondaryAnimation) {
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              Future<void> confirmDelete() async {
                if (deleting) return;
                HapticFeedback.mediumImpact();
                setDialogState(() {
                  deleting = true;
                  dialogError = null;
                });

                try {
                  final response = await _state.api.dio.delete('/ads/$adId');
                  final ok = response.statusCode == 204 ||
                      (response.statusCode != null &&
                          response.statusCode! >= 200 &&
                          response.statusCode! < 300 &&
                          (response.data is! Map ||
                              response.data['status'] == null ||
                              response.data['status'] == 'success'));
                  if (!ok) {
                    throw StateError('Deletion not confirmed');
                  }
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop(true);
                  }
                } catch (e) {
                  HapticFeedback.vibrate();
                  if (ctx.mounted) {
                    setDialogState(() {
                      deleting = false;
                      dialogError = isAr
                          ? 'تعذر حذف الإعلان حالياً. حاول مرة أخرى.'
                          : 'Impossible de supprimer l’annonce. Réessayez.';
                    });
                  }
                }
              }

              return PopScope(
                canPop: !deleting,
                child: Directionality(
                  textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Material(
                          color: Colors.white,
                          elevation: 0,
                          borderRadius: BorderRadius.circular(28),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 32,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Soft Crimson Icon Badge
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFECACA),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      CupertinoIcons.trash_fill,
                                      color: Color(0xFFE31B23),
                                      size: 26,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Headline
                                Text(
                                  isAr
                                      ? 'حذف هذا الإعلان؟'
                                      : 'Supprimer cette annonce ?',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                    height: 1.25,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Reassuring Warning Subtitle
                                Text(
                                  isAr
                                      ? 'سيتم حذف الإعلان نهائياً من حسابك ومن نتائج البحث ولا يمكن التراجع عن هذه العملية.'
                                      : 'Cette annonce sera définitivement retirée de votre profil et des résultats. Cette action est irréversible.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF6B7280),
                                    height: 1.45,
                                  ),
                                ),

                                // Compact Ad Preview Card
                                if (adTitle.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: adImage.isNotEmpty
                                              ? AppImage(
                                                  url: adImage,
                                                  width: 44,
                                                  height: 44,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  width: 44,
                                                  height: 44,
                                                  color:
                                                      const Color(0xFFE5E7EB),
                                                  child: const Icon(
                                                    CupertinoIcons.photo,
                                                    size: 18,
                                                    color: Color(0xFF9CA3AF),
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                adTitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: _ink,
                                                ),
                                              ),
                                              if (adPrice.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  adPrice,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFFE31B23),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Inline Error Banner (if server fails)
                                if (dialogError != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFFCA5A5),
                                      ),
                                    ),
                                    child: Text(
                                      dialogError!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 20),

                                // Primary Destructive Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    key: const Key('profile-confirm-delete'),
                                    onPressed: deleting ? null : confirmDelete,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE31B23),
                                      disabledBackgroundColor:
                                          const Color(0xFFE31B23)
                                              .withValues(alpha: 0.65),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: const StadiumBorder(),
                                    ),
                                    child: deleting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            isAr
                                                ? 'نعم، احذف الإعلان'
                                                : 'Supprimer définitivement',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Secondary Cancel Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: TextButton(
                                    onPressed: deleting
                                        ? null
                                        : () => Navigator.of(ctx).pop(false),
                                    style: TextButton.styleFrom(
                                      backgroundColor: const Color(0xFFF3F4F6),
                                      foregroundColor: _ink,
                                      shape: const StadiumBorder(),
                                    ),
                                    child: Text(
                                      isAr ? 'إلغاء' : 'Annuler',
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        transitionBuilder: (ctx, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      );

      if (deleted == true && mounted && identity == _identity) {
        setState(() {
          _myAds.removeWhere((item) => item['id'].toString() == adId.toString());
        });
        _state.favoriteAdIds.remove(adId);
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: Row(
              children: [
                const Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: Colors.white,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isAr
                        ? 'تم حذف الإعلان بنجاح'
                        : 'Annonce supprimée avec succès',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      _deletingAds.remove(adId);
    }
  }
}
