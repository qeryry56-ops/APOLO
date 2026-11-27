import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/apolo_badges_kit.dart';
import '../widgets/dl_qr_code.dart';
import '../widgets/dl_settings_kit.dart';
import 'ad_detail_screen.dart';
import 'auth_screen.dart';
import 'business_switch_screen.dart';
import 'edit_profile_screen.dart';
import 'post_ad_screen.dart';
import 'pro_plus_screen.dart';
import 'settings/settings_saved_ads_screen.dart';
import 'settings_screen.dart';
import 'share_profile_screen.dart';
import 'store_detail_screen.dart';
import 'widgets/app_image.dart';
import 'widgets/boost_sheet.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/price_text.dart';
import 'widgets/quick_replies_sheet.dart';
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
  Map<String, dynamic>? _businessInsights;
  bool _loadingAds = false;
  int _activeTab = 0; // 0: My Ads, 1: Pro Insights & Boost
  String? _adsError;
  final Set<int> _deletingAds = {};
  String? _profileIdentity;

  String? get _identity =>
      _state.isLoggedIn && _state.currentUser?['id'] != null
          ? '${_state.api.dio.options.baseUrl}:${_state.currentUser!['id']}'
          : null;

  // Dynamic Layer v5.1 Strict Palette Tokens
  Color get _dlBg => ApoloDlPalette.of(context).bg;
  Color get _dlSurface => ApoloDlPalette.of(context).surfaceSubtle;
  Color get _dlPill => ApoloDlPalette.of(context).pill;
  Color get _dlSeparator => ApoloDlPalette.of(context).separator;
  Color get _dlInk => ApoloDlPalette.of(context).ink;
  Color get _dlOnInk => ApoloDlPalette.of(context).onInk;
  Color get _dlMuted => ApoloDlPalette.of(context).muted;
  static const Color _dlDanger = Color(0xFFE31B23);

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
      Map<String, dynamic>? fetchedInsights;
      if (_state.isBusinessAccount) {
        try {
          final insRes = await _state.api.dio.get('/account/business-insights');
          if (insRes.data is Map && insRes.data['insights'] is Map) {
            fetchedInsights =
                Map<String, dynamic>.from(insRes.data['insights'] as Map);
          }
        } catch (_) {}
      }
      if (!mounted || identity != _identity) return;
      setState(() {
        _myAds = parsed;
        _businessInsights = fetchedInsights;
        if (!_state.isBusinessAccount) {
          _activeTab = 0;
        }
        _loadingAds = false;
      });
    } catch (_) {
      if (!mounted || identity != _identity) return;
      setState(() {
        _loadingAds = false;
        _adsError = _state.s.tr(
          'تعذر تحميل الإعلانات. اسحب للمحاولة مجدداً.',
          'Impossible de charger les annonces. Réessayez en actualisant.',
          'Could not load listings. Pull to retry.',
        );
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
      _state.s.tr('حسابي', 'Mon compte', 'My account');
  String get _displayHandle =>
      _state.currentUser?['username']?.toString() ?? 'profil';
  String _displayBio(bool isAr) => _state.currentUser?['bio']?.toString() ?? '';

  Future<void> _shareOwnProfile(
    AppStrings s,
    String name,
    String handle,
  ) async {
    final userId = _state.currentUser?['id']?.toString().trim() ?? '';
    final parsedId = int.tryParse(userId);
    final url = ApoloProfileQrParser.buildProfileShareUrl(
      userId: parsedId,
      displayName: name,
      handle: handle,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShareProfileScreen(
          userId: parsedId,
          displayName: name,
          handle: handle,
          profileUrl: url,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final palette = ApoloDlPalette.of(context);
    if (!_state.isLoggedIn) {
      return Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          key: const Key('dl-profile-guest-screen'),
          backgroundColor: palette.bg,
          body: SafeArea(
            child: Column(
              children: [
                ApoloDlTopNav(
                  title: s.profile,
                  size: ApoloDlTopNavSize.md,
                  showBack: false,
                  showSeparator: false,
                  trailing: ApoloDlIconCircleButton(
                    key: const Key('guest-settings'),
                    tooltip: s.tr(
                      'الإعدادات والدعم',
                      'Paramètres et assistance',
                      'Settings & support',
                    ),
                    icon: CupertinoIcons.gear,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: palette.groupCard,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                CupertinoIcons.person_fill,
                                size: 32,
                                color: palette.ink,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              s.tr(
                                'مرحباً بك في Apolo',
                                'Bienvenue sur Apolo',
                                'Welcome to Apolo',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: palette.ink,
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
                              style: TextStyle(
                                fontSize: 13.5,
                                color: palette.muted,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 22),
                            ApoloDlButton(
                              key: const Key('profile-sign-in'),
                              label: s.tr(
                                'سجّل الدخول لعرض حسابك',
                                'Connectez-vous pour voir votre profil',
                                'Sign in to view your profile',
                              ),
                              variant: ApoloDlButtonVariant.primary,
                              borderRadius: 999,
                              fullWidth: true,
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AuthScreen(),
                                  ),
                                );
                                if (mounted) {
                                  _profileIdentity = _identity;
                                  await _loadProfileData();
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            ApoloDlButton(
                              key: const Key('profile-sign-up'),
                              label: s.tr(
                                'إنشاء حساب جديد',
                                'Créer un compte',
                                'Create an account',
                              ),
                              variant: ApoloDlButtonVariant.secondary,
                              borderRadius: 999,
                              fullWidth: true,
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AuthScreen(
                                      initialRegisterMode: true,
                                    ),
                                  ),
                                );
                                if (mounted) {
                                  _profileIdentity = _identity;
                                  await _loadProfileData();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final name = _displayName(isAr);
    final handle = _displayHandle;
    final bio = _displayBio(isAr);
    final userMap = _state.currentUser;
    final isProPlus = _state.isProPlusAccount;
    final isBusiness = _state.isBusinessAccount;
    final isVerified = isProPlus;
    final totalViews = _baseViews ?? 0;
    final sellerRank = ApoloSellerRank.resolve(
      user: userMap,
      listingsCount: _myAds.length,
      totalViews: totalViews,
      isProPlus: isProPlus,
      isBusiness: isBusiness,
      isVerified: isVerified,
    );

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        key: const Key('dl-profile-screen'),
        backgroundColor: palette.bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Fixed Dynamic Layer v5.1 Top Navigation (`56px`, `40×40` `#EEEEEE` buttons)
              SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ApoloDlIconCircleButton(
                        key: const Key('profile-add-ad'),
                        icon: CupertinoIcons.add,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PostAdScreen(),
                          ),
                        ).then((_) => _loadProfileData()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '@$handle',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ApoloDlIconCircleButton(
                        key: const Key('profile-theme-toggle-btn'),
                        tooltip: Theme.of(context).brightness == Brightness.dark
                            ? s.tr('الوضع الفاتح', 'Mode clair', 'Light mode')
                            : s.tr('الوضع الداكن', 'Mode sombre', 'Dark mode'),
                        icon: Theme.of(context).brightness == Brightness.dark
                            ? CupertinoIcons.sun_max_fill
                            : CupertinoIcons.moon_fill,
                        onPressed: () => _state.toggleDarkMode(context),
                      ),
                      const SizedBox(width: 8),
                      ApoloDlIconCircleButton(
                        key: const Key('profile-settings-btn'),
                        icon: CupertinoIcons.gear,
                        onPressed: () => Navigator.push(
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
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: _dlInk,
                  backgroundColor: palette.bg,
                  onRefresh: _loadProfileData,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      // Dynamic Layer v5.1 Account Header + Rank Progress + Business Bar
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              child: Column(
                                children: [
                                  ApoloDlAccountHeader(
                                    avatar: _buildAvatarContent(palette, name),
                                    onAvatarTap: () =>
                                        _openEditProfileSheet(isAr),
                                    displayName: name,
                                    nameTrailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isVerified) ...[
                                          ApoloVerifiedBadge(
                                            size: 17,
                                            rank: sellerRank,
                                            isProPlus: isProPlus,
                                            isBusiness: isBusiness,
                                          ),
                                          const SizedBox(width: 5),
                                        ],
                                        ApoloAccountTypeBadge(
                                          isBusiness: isBusiness,
                                        ),
                                      ],
                                    ),
                                    onNameTap: () =>
                                        _openEditProfileSheet(isAr),
                                    handle: '@$handle',
                                    stats: [
                                      ApoloDlAccountStat(
                                        value:
                                            '${_state.followedSellerIds.length}',
                                        label: s.tr(
                                          'متابَعة',
                                          'Abonnements',
                                          'Following',
                                        ),
                                      ),
                                      ApoloDlAccountStat(
                                        value: '${_myAds.length}',
                                        label: s.tr(
                                          'إعلاناتي',
                                          'Annonces',
                                          'Listings',
                                        ),
                                        onTap: () =>
                                            setState(() => _activeTab = 0),
                                      ),
                                      ApoloDlAccountStat(
                                        value: _state.isBusinessAccount ||
                                                _baseViews != null
                                            ? '${_baseViews ?? _state.favoriteAdIds.length}'
                                            : '${_state.favoriteAdIds.length}',
                                        label: _state.isBusinessAccount
                                            ? (_baseViews != null
                                                ? s.tr('مشاهدة', 'Vues', 'Views')
                                                : s.tr(
                                                    'المفضلة',
                                                    'Favoris',
                                                    'Likes',
                                                  ))
                                            : (_baseViews != null
                                                ? s.tr('مشاهدة', 'Vues', 'Views')
                                                : s.tr(
                                                    'المحفوظات',
                                                    'Enregistrés',
                                                    'Saved',
                                                  )),
                                        onTap: () {
                                          if (_state.isBusinessAccount) {
                                            setState(() => _activeTab = 1);
                                          } else {
                                            Navigator.of(context)
                                                .push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        const SettingsSavedAdsScreen(),
                                                  ),
                                                )
                                                .then((_) {
                                                  if (mounted) setState(() {});
                                                });
                                          }
                                        },
                                      ),
                                    ],
                                    primaryAction: ApoloDlButton(
                                      key: const Key('profile-edit-btn'),
                                      label: s.tr(
                                        'تعديل الملف الشخصي',
                                        'Modifier le profil',
                                        'Edit profile',
                                      ),
                                      variant: ApoloDlButtonVariant.secondary,
                                      size: ApoloDlButtonSize.sm,
                                      height: 42,
                                      borderRadius: 999,
                                      fullWidth: true,
                                      onPressed: () =>
                                          _openEditProfileSheet(isAr),
                                    ),
                                    secondaryAction: ApoloDlButton(
                                      key: const Key('profile-share-btn'),
                                      label: s.tr(
                                        'مشاركة الملف',
                                        'Partager le profil',
                                        'Share profile',
                                      ),
                                      variant: ApoloDlButtonVariant.secondary,
                                      size: ApoloDlButtonSize.sm,
                                      height: 42,
                                      borderRadius: 999,
                                      fullWidth: true,
                                      onPressed: () =>
                                          _shareOwnProfile(s, name, handle),
                                    ),
                                    bio: bio.isNotEmpty ? bio : null,
                                  ),

                                  if (AppConfig.enablePremiumAndBusinessTiers) ...[
                                    const SizedBox(height: 14),
                                    if (!_state.isProPlusAccount)
                                      _buildPersonalSwitchBanner(s, palette)
                                    else ...[
                                      _buildBusinessIdentityHeader(s, palette),
                                      const SizedBox(height: 14),
                                      // Dynamic Layer v5.1 Pill Segmented Control (`#EEEEEE` outer, `#000000` active)
                                      Container(
                                        height: 44,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: _dlPill,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          children: [
                                            _buildSegmentButton(
                                              index: 0,
                                              label: _state.s.tr(
                                                'إعلاناتي',
                                                'Mes annonces',
                                                'My Listings',
                                              ),
                                              icon:
                                                  CupertinoIcons.square_grid_2x2,
                                            ),
                                            const SizedBox(width: 4),
                                            _buildSegmentButton(
                                              index: 1,
                                              label: _state.s.tr(
                                                'لوحة الأعمال والإحصائيات',
                                                'Tableau Pro & Boost',
                                                'Pro Insights & Boost',
                                              ),
                                              icon: CupertinoIcons.chart_bar,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Content Area
                      if (_loadingAds)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.78,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (_, __) => const AdGridCardSkeleton(),
                              childCount: 4,
                            ),
                          ),
                        )
                      else if (!_state.isBusinessAccount || _activeTab == 0)
                        _buildCleanAdsGrid(isAr)
                      else
                        SliverToBoxAdapter(
                          child: _buildUpgradedInsightsStudio(isAr),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 136)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(ApoloDlPalette palette, String name) {
    final avatarUrl = (_state.currentUser?['avatar_url'] ??
            _state.currentUser?['avatar'] ??
            '')
        .toString()
        .trim();
    if (avatarUrl.isNotEmpty) {
      return AppImage(url: avatarUrl, width: 72, height: 72, fit: BoxFit.cover);
    }
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      return Center(
        child: Text(
          trimmed.characters.first.toUpperCase(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
      );
    }
    return Icon(
      CupertinoIcons.person_fill,
      size: 32,
      color: palette.iconMuted,
    );
  }

  Widget _buildPersonalSwitchBanner(AppStrings s, ApoloDlPalette palette) {
    return PressableScale(
      key: const Key('profile-switch-to-business-card'),
      onTap: () async {
        final activated = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => const ProPlusScreen(initialPlanId: 'monthly'),
          ),
        );
        if (activated == true && mounted) {
          await _loadProfileData();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _dlSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _dlInk,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.checkmark_seal_fill,
                size: 17,
                color: _dlOnInk,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.tr(
                      'ترقية إلى Apolo Premium · ${AppConfig.monthlyPremiumPriceMad} د.م/شهر',
                      'Passer à Apolo Premium · ${AppConfig.monthlyPremiumPriceMad} DH/mois',
                      'Upgrade to Apolo Premium · ${AppConfig.monthlyPremiumPriceMad} MAD/mo',
                    ),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _dlInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.tr(
                      'متجر Business + شارة Verified الزرقاء + نشر غير محدود عبر Google Pay.',
                      'Boutique Business + badge Verified + annonces illimitées via Google Pay.',
                      'Business store + Verified badge + unlimited daily ads via Google Pay.',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: _dlMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _dlBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                s.isAr
                    ? CupertinoIcons.chevron_left
                    : CupertinoIcons.chevron_right,
                size: 13,
                color: _dlInk,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessIdentityHeader(AppStrings s, ApoloDlPalette palette) {
    final store = _state.activeStore;
    final isProPlus = _state.isProPlusAccount;
    final categoryLabel = ApoloBusinessCategories.labelFor(
      store?['business_category']?.toString(),
      s,
    );
    final hours = (store?['working_hours'] ?? '').toString().trim();
    final isOpenNow = store?['is_open_now'];
    final subdomain = (store?['subdomain'] ?? '').toString().trim();

    return Container(
      key: const Key('profile-business-identity-bar'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _dlSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: _dlInk,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isProPlus)
                      const ApoloVerifiedBadge(size: 13)
                    else
                      Icon(
                        CupertinoIcons.briefcase_fill,
                        size: 12,
                        color: _dlOnInk,
                      ),
                    const SizedBox(width: 5),
                    Text(
                      isProPlus ? 'PRO+' : 'Business',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _dlOnInk,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  categoryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _dlInk,
                  ),
                ),
              ),
              if (hours.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _dlBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOpenNow is bool) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isOpenNow
                                ? const Color(0xFF15803D)
                                : _dlDanger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        hours,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _dlInk,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 11),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                if (subdomain.isNotEmpty) ...[
                  _buildBusinessActionChip(
                    key: const Key('profile-open-my-store-btn'),
                    icon: Icons.storefront_rounded,
                    label: s.tr('عرض متجري', 'Voir boutique', 'View store'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StoreDetailScreen(subdomain: subdomain),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                _buildBusinessActionChip(
                  key: const Key('profile-edit-business-btn'),
                  icon: CupertinoIcons.slider_horizontal_3,
                  label: s.tr('إعدادات المتجر', 'Gérer boutique', 'Edit store'),
                  onTap: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) =>
                            const BusinessSwitchScreen(isEditing: true),
                      ),
                    );
                    if (updated == true && mounted) {
                      await _loadProfileData();
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildBusinessActionChip(
                  key: const Key('profile-quick-replies-btn'),
                  icon: CupertinoIcons.bolt_fill,
                  label: s.tr(
                    'الردود السريعة',
                    'Réponses rapides',
                    'Quick replies',
                  ),
                  onTap: () => QuickRepliesManagerSheet.show(context),
                ),
                if (!isProPlus) ...[
                  const SizedBox(width: 8),
                  _buildBusinessActionChip(
                    key: const Key('profile-pro-plus-chip'),
                    icon: CupertinoIcons.sparkles,
                    label: 'Pro Plus',
                    highlighted: true,
                    onTap: () async {
                      final ok = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const SubscriptionScreen(),
                        ),
                      );
                      if (ok == true && mounted) {
                        await _loadProfileData();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessActionChip({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: highlighted ? _dlInk : _dlBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13.5,
              color: highlighted ? _dlOnInk : _dlInk,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: highlighted ? _dlOnInk : _dlInk,
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
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _dlInk : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14.5,
                color: selected ? _dlOnInk : _dlInk,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? _dlOnInk : _dlInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab 0: Dynamic Layer v5.1 Clean 2-Column Grid of User's Ads
  Widget _buildCleanAdsGrid(bool isAr) {
    if (_adsError != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _dlSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  _adsError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _dlMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                ApoloDlButton(
                  label: _state.s.tr('إعادة المحاولة', 'Réessayer', 'Retry'),
                  variant: ApoloDlButtonVariant.primary,
                  size: ApoloDlButtonSize.sm,
                  borderRadius: 999,
                  onPressed: _loadProfileData,
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_myAds.isEmpty) {
      return SliverToBoxAdapter(
        child: IllustratedStateView(
          assetPath: 'assets/images/state_empty_ads.png',
          imageSize: 160,
          title: _state.s.tr(
            'لا توجد إعلانات منشورة',
            'Aucune annonce publiée',
            'No listings yet',
          ),
          subtitle: _state.s.tr(
            'انشر إعلانك الأول ليظهر هنا في معرضك الخاص.',
            'Publiez votre première annonce pour l’afficher ici.',
            'Publish your first listing to showcase it here.',
          ),
          actionLabel: _state.s.tr(
            'إضافة إعلان',
            'Publier une annonce',
            'Post a listing',
          ),
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostAdScreen()),
          ).then((_) => _loadProfileData()),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 18,
          crossAxisSpacing: 14,
          childAspectRatio: 0.75,
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
                        ? '${ad['price']} ${_state.s.tr('د.م', 'DH', 'MAD')}'
                        : ''))
                .toString();

            return PressableScale(
              key: ValueKey('clean_ad_$adId'),
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: _dlSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _dlSeparator, width: 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppImage(
                            url: imgUrl,
                            fit: BoxFit.cover,
                            fallback: Container(
                              color: _dlSurface,
                              alignment: Alignment.center,
                              child: Icon(
                                CupertinoIcons.photo,
                                color: _dlMuted,
                                size: 30,
                              ),
                            ),
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
                                  color: _dlBg,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  CupertinoIcons.ellipsis,
                                  color: _dlInk,
                                  size: 15,
                                ),
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            bottom: 9,
                            end: 9,
                            child: GestureDetector(
                              onTap: () =>
                                  _openBoostModal(adId: adId, adTitle: title),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _dlInk,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.bolt_fill,
                                      color: _dlOnInk,
                                      size: 11,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Boost',
                                      style: TextStyle(
                                        color: _dlOnInk,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
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
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _dlInk,
                      letterSpacing:
                          AppTypography.trackingForContext(context, -0.2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (priceStr.isNotEmpty)
                    PriceText(
                      priceStr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _dlMuted,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            );
          },
          childCount: _myAds.length,
        ),
      ),
    );
  }

  /// Tab 1: Dynamic Layer v5.1 Seller Analytics & Boost Studio (`#F6F6F6` cards)
  Widget _buildUpgradedInsightsStudio(bool isAr) {
    final totalAds = _myAds.length;
    final totalViews = _baseViews ?? 0;
    final avgViews = totalAds > 0 ? (totalViews / totalAds).round() : 0;
    final boostedCount = _myAds
        .where(
          (ad) =>
              ad['is_vip'] == true ||
              ad['is_featured'] == true ||
              ad['is_highlighted'] == true,
        )
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 2x2 `#F6F6F6` KPI Bento Grid
              Row(
                children: [
                  Expanded(
                    child: _buildAnalyticsKpiCard(
                      icon: CupertinoIcons.eye_fill,
                      label: _state.s.tr(
                        'إجمالي المشاهدات',
                        'Vues totales',
                        'Total views',
                      ),
                      value: _baseViews?.toString() ?? '0',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAnalyticsKpiCard(
                      icon: CupertinoIcons.square_grid_2x2_fill,
                      label: _state.s.tr(
                        'الإعلانات النشطة',
                        'Annonces actives',
                        'Active listings',
                      ),
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
                      label: _state.s.tr(
                        'متوسط المشاهدات',
                        'Moy. / annonce',
                        'Avg. / listing',
                      ),
                      value: '$avgViews',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAnalyticsKpiCard(
                      icon: CupertinoIcons.bolt_fill,
                      label: _state.s.tr(
                        'إعلانات ممولة',
                        'Annonces Boost',
                        'Boosted listings',
                      ),
                      value: '$boostedCount',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Pro Plus Conversion Analytics OR Upgrade Card
              if (_state.isProPlusAccount) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsKpiCard(
                        icon: CupertinoIcons.phone_fill,
                        label: _state.s.tr(
                          'نقرات الاتصال',
                          'Appels reçus',
                          'Call taps',
                        ),
                        value: '${_businessInsights?['phone_clicks'] ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildAnalyticsKpiCard(
                        icon: CupertinoIcons.chat_bubble_2_fill,
                        label: _state.s.tr(
                          'محادثات الزبناء',
                          'Conversations',
                          'Customer chats',
                        ),
                        value:
                            '${_businessInsights?['chat_conversations_count'] ?? 0}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsKpiCard(
                        icon: CupertinoIcons.bag_fill,
                        label: _state.s.tr(
                          'طلبيات المتجر',
                          'Commandes directes',
                          'Direct orders',
                        ),
                        value:
                            '${_businessInsights?['direct_orders_count'] ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildAnalyticsKpiCard(
                        icon: CupertinoIcons.sparkles,
                        label: _state.s.tr(
                          'رصيد VIP المجاني',
                          'Crédits VIP offerts',
                          'Free VIP credits',
                        ),
                        value: '${_state.vipBoostCredits}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else ...[
                PressableScale(
                  key: const Key('profile-upgrade-pro-plus-card'),
                  onTap: () async {
                    final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    );
                    if (ok == true && mounted) {
                      await _loadProfileData();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _dlInk,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _dlBg,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const ApoloVerifiedBadge(size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _state.s.tr(
                                  'افتح إحصائيات النقرات والطلبيات + شارة PRO+',
                                  'Débloquez les stats d’appels & commandes + PRO+',
                                  'Unlock call & order stats + PRO+ Badge',
                                ),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: _dlOnInk,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _state.s.tr(
                                  'احصل على 3 تمويلات VIP مجانية شهرياً وتصدر المتاجر.',
                                  '3 Boosts VIP gratuits/mois et priorité d’affichage.',
                                  'Get 3 free VIP boosts/month and priority visibility.',
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _dlOnInk.withValues(alpha: 0.76),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 2. `#F6F6F6` Views Breakdown Chart Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _dlSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _state.s.tr(
                            'توزيع المشاهدات',
                            'Répartition des vues',
                            'Views breakdown',
                          ),
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: _dlInk,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _dlBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _state.s.tr('مباشر', 'En direct', 'Live'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _dlInk,
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
                            _state.s.tr(
                              'انشر إعلانك الأول لتبدأ متابعة المشاهدات والأداء هنا.',
                              'Publiez votre première annonce pour suivre vos vues ici.',
                              'Publish your first listing to track views and performance here.',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: _dlMuted,
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
                                      .toString(),
                                ) ??
                                0;
                            final ratio = (v / maxViews).clamp(0.12, 1.0);
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$v',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _dlInk,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 320),
                                      height: 82 * ratio,
                                      decoration: BoxDecoration(
                                        color: i == 0
                                            ? _dlInk
                                            : const Color(0xFFDCDCDC),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '#${i + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _dlMuted,
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

              const SizedBox(height: 12),

              // 3. `#F6F6F6` Top Performing Listings Card
              if (sortedAds.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _dlSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _state.s.tr(
                          'أفضل إعلاناتك أداءً',
                          'Vos meilleures annonces',
                          'Top performing listings',
                        ),
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: _dlInk,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...sortedAds.take(5).map((ad) {
                        final adId =
                            int.tryParse((ad['id'] ?? 0).toString()) ?? 0;
                        final title = (ad['title'] ?? '').toString();
                        final imgUrl =
                            (ad['main_image'] ?? ad['primary_image'] ?? '')
                                .toString();
                        final views = int.tryParse(
                              (ad['views_count'] ?? ad['views'] ?? 0)
                                  .toString(),
                            ) ??
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
                                  color: _dlPill,
                                  child:
                                      AppImage(url: imgUrl, fit: BoxFit.cover),
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
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: _dlInk,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.eye_fill,
                                          size: 12,
                                          color: _dlMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$views ${_state.s.tr('مشاهدة', 'vues', 'views')}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: _dlMuted,
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
                                  decoration: BoxDecoration(
                                    color: _dlBg,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    CupertinoIcons.pencil,
                                    size: 15,
                                    color: _dlInk,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () =>
                                    _openBoostModal(adId: adId, adTitle: title),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _dlInk,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Boost',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: _dlOnInk,
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
                const SizedBox(height: 12),
              ],

              // 4. Smart Actionable Tip Card (`#F6F6F6`)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _dlSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _dlInk,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        CupertinoIcons.sparkles,
                        color: _dlOnInk,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _state.s.tr(
                              'نصيحة لزيادة المبيعات',
                              'Conseil de vente',
                              'Sales tip',
                            ),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _dlInk,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            sortedAds.isEmpty
                                ? _state.s.tr(
                                    'أضف صوراً واضحة وثمناً مناسباً في إعلانك الأول لجذب المشترين بسرعة.',
                                    'Ajoutez des photos nettes et un prix clair pour attirer plus d’acheteurs.',
                                    'Add clear photos and a fair price on your first listing to attract buyers fast.',
                                  )
                                : _state.s.tr(
                                    'تحديث الصور والوصف أو تمويل إعلانك الأكثر مشاهدة يضاعف فرص البيع.',
                                    'Mettre à jour vos photos ou booster votre meilleure annonce accélère la vente.',
                                    'Refreshing photos or boosting your top listing helps it sell faster.',
                                  ),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: _dlMuted,
                              height: 1.38,
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
        color: _dlSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _dlBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: _dlInk),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _dlInk,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _dlMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _openBoostModal({required int adId, required String adTitle}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BoostSheet(adId: adId, adTitle: adTitle),
    );
  }

  Future<void> _openEditProfileSheet(bool isAr) async {
    if (_identity == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const EditProfileScreen(),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _showAdQuickActions(Map<String, dynamic> ad, bool isAr) {
    final adId = int.tryParse((ad['id'] ?? '').toString());
    if (!_state.isLoggedIn || adId == null || adId <= 0) return;
    final title = (ad['title'] ?? '').toString();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _dlBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _dlPill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                _buildSheetActionTile(
                  icon: CupertinoIcons.pencil,
                  iconColor: _dlInk,
                  title: _state.s.tr(
                    'تعديل الإعلان',
                    'Modifier l’annonce',
                    'Edit listing',
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
                const SizedBox(height: 8),
                _buildSheetActionTile(
                  icon: CupertinoIcons.bolt_fill,
                  iconColor: _dlInk,
                  title: _state.s.tr(
                    'تمويل الإعلان (Boost)',
                    'Booster cette annonce',
                    'Boost this listing',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openBoostModal(adId: adId, adTitle: title);
                  },
                ),
                const SizedBox(height: 8),
                _buildSheetActionTile(
                  icon: CupertinoIcons.trash,
                  iconColor: _dlDanger,
                  titleColor: _dlDanger,
                  title: _state.s.tr(
                    'حذف الإعلان',
                    'Supprimer l’annonce',
                    'Delete listing',
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
      ),
    );
  }

  Widget _buildSheetActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _dlSurface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _dlBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: titleColor ?? _dlInk,
                ),
              ),
            ),
          ],
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
        barrierLabel: _state.s.tr('إغلاق', 'Fermer', 'Close'),
        barrierColor: Colors.black.withValues(alpha: 0.48),
        transitionDuration: const Duration(milliseconds: 220),
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
                } catch (_) {
                  HapticFeedback.vibrate();
                  if (ctx.mounted) {
                    setDialogState(() {
                      deleting = false;
                      dialogError = _state.s.tr(
                        'تعذر حذف الإعلان حالياً. حاول مرة أخرى.',
                        'Impossible de supprimer l’annonce. Réessayez.',
                        'Could not delete listing. Please try again.',
                      );
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
                          color: _dlBg,
                          elevation: 0,
                          borderRadius: BorderRadius.circular(28),
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: _dlPill,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    CupertinoIcons.trash_fill,
                                    color: _dlDanger,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _state.s.tr(
                                    'حذف هذا الإعلان؟',
                                    'Supprimer cette annonce ?',
                                    'Delete this listing?',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: _dlInk,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _state.s.tr(
                                    'سيتم حذف الإعلان نهائياً من حسابك ومن نتائج البحث ولا يمكن التراجع عن هذه العملية.',
                                    'Cette annonce sera définitivement retirée de votre profil et des résultats.',
                                    'This listing will be permanently removed from your profile and search results.',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    color: _dlMuted,
                                    height: 1.45,
                                  ),
                                ),
                                if (adTitle.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _dlSurface,
                                      borderRadius: BorderRadius.circular(16),
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
                                                  color: _dlPill,
                                                  child: Icon(
                                                    CupertinoIcons.photo,
                                                    size: 18,
                                                    color: _dlMuted,
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
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: _dlInk,
                                                ),
                                              ),
                                              if (adPrice.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                PriceText(
                                                  adPrice,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: _dlMuted,
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
                                if (dialogError != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    dialogError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: _dlDanger,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    key: const Key('profile-confirm-delete'),
                                    onPressed: deleting ? null : confirmDelete,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _dlDanger,
                                      disabledBackgroundColor:
                                          _dlDanger.withValues(alpha: 0.65),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: const StadiumBorder(),
                                    ),
                                    child: deleting
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: _dlOnInk,
                                            ),
                                          )
                                        : Text(
                                            _state.s.tr(
                                              'نعم، احذف الإعلان',
                                              'Supprimer définitivement',
                                              'Delete permanently',
                                            ),
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: TextButton(
                                    onPressed: deleting
                                        ? null
                                        : () => Navigator.of(ctx).pop(false),
                                    style: TextButton.styleFrom(
                                      backgroundColor: _dlPill,
                                      foregroundColor: _dlInk,
                                      shape: const StadiumBorder(),
                                    ),
                                    child: Text(
                                      _state.s.tr('إلغاء', 'Annuler', 'Cancel'),
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
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      );

      if (deleted == true && mounted && identity == _identity) {
        setState(() {
          _myAds
              .removeWhere((item) => item['id'].toString() == adId.toString());
        });
        _state.favoriteAdIds.remove(adId);
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: _dlInk,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: Text(
              _state.s.tr(
                'تم حذف الإعلان بنجاح',
                'Annonce supprimée avec succès',
                'Listing deleted successfully',
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
    } finally {
      _deletingAds.remove(adId);
    }
  }
}
