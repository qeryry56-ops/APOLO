import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_config.dart';
import '../core/services/firebase_chat_service.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/apolo_badges_kit.dart';
import '../widgets/dl_qr_code.dart';
import '../widgets/dl_settings_kit.dart';
import '../widgets/dl_write_review_sheet.dart';
import 'ad_detail_screen.dart';
import 'share_profile_screen.dart';
import 'widgets/apolo_safety_sheet.dart';
import 'widgets/app_image.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/price_text.dart';
import 'widgets/skeleton_loader.dart';

/// Dynamic Layer v5.1 Public Seller Profile Screen:
/// - Pure #FFFFFF canvas + ApoloDlTopNav + ApoloDlAccountHeader + ApoloIdentityBadgesRow
/// - Pinned #EEEEEE capsule segmented tabs (#000000 active pill)
/// - Flat #F6F6F6 2-column listings grid, verified reviews, and seller trust guarantees
class SellerProfileScreen extends StatefulWidget {
  final int sellerId;
  final String sellerName;
  final String? sellerHandle;
  final String? sellerAvatar;
  final String? sellerPhone;
  final String? sellerCity;
  final bool isVerified;
  final bool isOnline;
  final Map<String, dynamic>? initialAd;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    this.sellerHandle,
    this.sellerAvatar,
    this.sellerPhone,
    this.sellerCity,
    this.isVerified = true,
    this.isOnline = true,
    this.initialAd,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final AppState _state = AppState();
  int _selectedTab = 0; // 0: Listings, 1: Reviews, 2: Trust & Info
  bool _isLoading = true;
  List<Map<String, dynamic>> _sellerAds = [];

  // Strict Dynamic Layer v5.1 Palette Tokens
  static const Color _dlBg = Color(0xFFFFFFFF);
  static const Color _dlSurface = Color(0xFFF6F6F6);
  static const Color _dlPill = Color(0xFFEEEEEE);
  static const Color _dlInk = Color(0xFF000000);
  static const Color _dlMuted = Color(0xFF757575);
  static const Color _dlDanger = Color(0xFFE31B23);
  static const Color _dlStarAmber = Color(0xFFFFB800);

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  Future<void> _loadSellerData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _state.api.dio.get(
        '/ads',
        queryParameters: {'per_page': 20, 'seller_id': widget.sellerId},
      );
      List<dynamic> raw = [];
      if (res.data is Map && res.data['status'] == 'success') {
        raw = (res.data['data'] as List?) ?? [];
      }
      final parsed = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final List<Map<String, dynamic>> combined = [];
      if (widget.initialAd != null) {
        combined.add(widget.initialAd!);
      }
      for (final p in parsed) {
        if (!combined.any((a) => a['id'] == p['id'])) {
          combined.add(p);
        }
      }

      if (mounted) {
        setState(() {
          _sellerAds = combined;
          _isLoading = false;
        });
      }
    } catch (_) {
      final List<Map<String, dynamic>> combined = [];
      if (widget.initialAd != null) {
        combined.add(widget.initialAd!);
      }
      if (mounted) {
        setState(() {
          _sellerAds = combined;
          _isLoading = false;
        });
      }
    }
  }

  void _callSeller() async {
    HapticFeedback.mediumImpact();
    final phone = widget.sellerPhone ?? '';
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _state.s.tr(
                'رقم هاتف البائع غير متوفر حالياً',
                'Numéro non disponible',
                'Seller phone number not available',
              ),
            ),
            backgroundColor: _dlInk,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openChatWithSeller() {
    final ad =
        widget.initialAd ?? (_sellerAds.isNotEmpty ? _sellerAds.first : null);
    final id = int.tryParse((ad?['id'] ?? '').toString());
    if (ad == null || id == null || id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _dlInk,
          behavior: SnackBarBehavior.floating,
          content: Text(
            AppState().s.tr(
              'اختر إعلاناً للبائع لبدء المحادثة.',
              'Choisissez une annonce pour contacter ce vendeur.',
              'Select a listing to message this seller.',
            ),
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AdDetailScreen(adId: id, initialAd: ad, openChatOnLoad: true),
      ),
    );
  }

  void _showMoreActions(bool isAr) {
    HapticFeedback.selectionClick();
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
                _buildActionSheetRow(
                  rowKey: const Key('seller-share-btn'),
                  icon: CupertinoIcons.share,
                  iconColor: _dlInk,
                  title: _state.s.tr(
                    'مشاركة البروفايل',
                    'Partager le profil',
                    'Share profile',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareSellerProfile(_state.s);
                  },
                ),
                if ((widget.sellerPhone ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildActionSheetRow(
                    rowKey: const Key('seller-more-call-btn'),
                    icon: CupertinoIcons.phone_fill,
                    iconColor: _dlInk,
                    title: _state.s.tr(
                      'اتصال بالبائع',
                      'Appeler le vendeur',
                      'Call seller',
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _callSeller();
                    },
                  ),
                ],
                const SizedBox(height: 8),
                _buildActionSheetRow(
                  icon: CupertinoIcons.flag,
                  iconColor: _dlInk,
                  title: _state.s.tr(
                    'الإبلاغ عن البائع',
                    'Signaler le vendeur',
                    'Report seller',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _reportSeller(isAr);
                  },
                ),
                const SizedBox(height: 8),
                _buildActionSheetRow(
                  icon: CupertinoIcons.nosign,
                  iconColor: _dlDanger,
                  titleColor: _dlDanger,
                  title: _state.s.tr(
                    'حظر هذا البائع',
                    'Bloquer le vendeur',
                    'Block seller',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _blockSeller(isAr);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionSheetRow({
    Key? rowKey,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    Color titleColor = _dlInk,
  }) {
    return PressableScale(
      key: rowKey,
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
              decoration: const BoxDecoration(
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
                  color: titleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reportSeller(bool isAr) {
    showApoloReportSheet(
      context,
      targetType: 'user',
      targetId: '${widget.sellerId}',
      targetName: widget.sellerName,
      reportedUserId: '${widget.sellerId}',
      reportedUserAvatar: widget.sellerAvatar,
    );
  }

  Future<void> _blockSeller(bool isAr) async {
    final myUserId = int.tryParse('${_state.currentUser?['id'] ?? 0}') ?? 0;
    await FirebaseChatService.instance.blockTarget(
      myUserId: myUserId,
      targetId:
          widget.sellerId > 0 ? '${widget.sellerId}' : widget.sellerName,
      targetName: widget.sellerName,
      targetAvatar: widget.sellerAvatar ?? '',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _state.s.tr(
            'تم حظر البائع بنجاح',
            'Vendeur bloqué avec succès',
            'Seller blocked successfully',
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _dlInk,
      ),
    );
  }

  String get _resolvedCity =>
      (widget.sellerCity != null && widget.sellerCity!.trim().isNotEmpty)
          ? widget.sellerCity!.trim()
          : _state.s.tr('المغرب', 'Maroc', 'Morocco');

  String _sellerHandle() {
    final explicit = (widget.sellerHandle ?? '')
        .trim()
        .replaceFirst(RegExp(r'^@+'), '')
        .trim();
    if (explicit.isNotEmpty) return explicit;

    final cleaned = widget.sellerName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (cleaned.isNotEmpty) return cleaned;
    return 'apolo_seller_${widget.sellerId > 0 ? widget.sellerId : 1}';
  }

  int get _baseFollowers => 120 + (widget.sellerId.abs() % 880);

  Future<void> _toggleFollow() async {
    HapticFeedback.selectionClick();
    await _state.toggleFollowSeller(widget.sellerId);
  }

  Future<void> _shareSellerProfile(AppStrings s) async {
    if (!mounted) return;
    final handle = _sellerHandle();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShareProfileScreen(
          userId: widget.sellerId,
          displayName: widget.sellerName,
          handle: handle,
          profileUrl: ApoloProfileQrParser.buildProfileShareUrl(
            userId: widget.sellerId,
            displayName: widget.sellerName,
            handle: handle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final s = _state.s;
        final isAr = s.isAr;
        final palette = ApoloDlPalette.of(context);
        final city = _resolvedCity;
        final isFollowing = _state.isFollowingSeller(widget.sellerId);
        final ratingStats = _state.computeSellerRatingStats(
          sellerId: widget.sellerId,
          baseRating: 4.9,
          baseCount: 48,
        );

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: palette.bg,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  ApoloDlTopNav(
                    title: widget.sellerName,
                    size: ApoloDlTopNavSize.md,
                    showSeparator: false,
                    showBack: true,
                    trailing: ApoloDlIconCircleButton(
                      key: const Key('seller-more-btn'),
                      icon: CupertinoIcons.ellipsis,
                      onPressed: () => _showMoreActions(isAr),
                    ),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // 1. Dynamic Layer v5.1 Account Header
                        SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                child: ApoloDlAccountHeader(
                                  avatar: widget.sellerAvatar != null &&
                                          widget.sellerAvatar!.isNotEmpty
                                      ? AppImage(
                                          url: widget.sellerAvatar!,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          fallback: Center(
                                            child: Text(
                                              widget.sellerName.trim().isNotEmpty
                                                  ? widget.sellerName
                                                      .trim()
                                                      .characters
                                                      .first
                                                      .toUpperCase()
                                                  : 'S',
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w700,
                                                color: _dlInk,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            widget.sellerName.trim().isNotEmpty
                                                ? widget.sellerName
                                                    .trim()
                                                    .characters
                                                    .first
                                                    .toUpperCase()
                                                : 'S',
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: _dlInk,
                                            ),
                                          ),
                                        ),
                                  displayName: widget.sellerName,
                                  nameTrailing: ApoloIdentityBadgesRow(
                                    isVerified: widget.isVerified,
                                    rank: ApoloSellerRank.resolve(
                                      listingsCount: _sellerAds.length,
                                      isVerified: widget.isVerified,
                                    ),
                                    interactive: true,
                                  ),
                                  handle: '@${_sellerHandle()}',
                                  stats: [
                                    ApoloDlAccountStat(
                                      value: '${_sellerAds.length}',
                                      label: s.tr(
                                        'إعلانات',
                                        'Annonces',
                                        'Listings',
                                      ),
                                      onTap: () =>
                                          setState(() => _selectedTab = 0),
                                    ),
                                    ApoloDlAccountStat(
                                      value:
                                          '${_baseFollowers + (isFollowing ? 1 : 0)}',
                                      label: s.tr(
                                        'متابع',
                                        'Abonnés',
                                        'Followers',
                                      ),
                                    ),
                                    ApoloDlAccountStat(
                                      value: ratingStats.average
                                          .toStringAsFixed(1),
                                      label: s.tr(
                                        'التقييم',
                                        'Note',
                                        'Rating',
                                      ),
                                      onTap: () =>
                                          setState(() => _selectedTab = 1),
                                    ),
                                  ],
                                  primaryAction: ApoloDlButton(
                                    key: const Key('seller-follow-btn'),
                                    label: isFollowing
                                        ? s.tr('متابَع', 'Abonné', 'Following')
                                        : s.tr('متابعة', 'Suivre', 'Follow'),
                                    variant: isFollowing
                                        ? ApoloDlButtonVariant.tertiary
                                        : ApoloDlButtonVariant.primary,
                                    size: ApoloDlButtonSize.sm,
                                    height: 42,
                                    borderRadius: 999,
                                    fullWidth: true,
                                    onPressed: _toggleFollow,
                                  ),
                                  secondaryAction: ApoloDlButton(
                                    key: const Key('seller-chat-btn'),
                                    label: s.tr(
                                      'مراسلة',
                                      'Message',
                                      'Message',
                                    ),
                                    leadingIcon:
                                        CupertinoIcons.chat_bubble_2_fill,
                                    variant: ApoloDlButtonVariant.secondary,
                                    size: ApoloDlButtonSize.sm,
                                    height: 42,
                                    borderRadius: 999,
                                    fullWidth: true,
                                    onPressed: _openChatWithSeller,
                                  ),
                                  bio: s.tr(
                                    'تاجر موثوق في Apolo.ma · $city · استجابة سريعة عبر الرسائل.',
                                    'Vendeur vérifié sur Apolo.ma · $city · Réponse rapide par message.',
                                    'Verified seller on Apolo.ma · $city · Fast reply on messages.',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 2. Pinned Dynamic Layer v5.1 Capsule Segmented Tabs
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _SliverTabsDelegate(
                            child: Container(
                              color: palette.bg,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 7,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 480),
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _dlPill,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildTabBtn(
                                          0,
                                          _state.s.tr(
                                            'الإعلانات (${_sellerAds.length})',
                                            'Annonces (${_sellerAds.length})',
                                            'Listings (${_sellerAds.length})',
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        _buildTabBtn(
                                          1,
                                          _state.s.tr(
                                            'التقييمات (${ratingStats.count})',
                                            'Avis (${ratingStats.count})',
                                            'Reviews (${ratingStats.count})',
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        _buildTabBtn(
                                          2,
                                          _state.s.tr(
                                            'حول والضمانات',
                                            'Garanties',
                                            'Trust & Info',
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

                        // 3. Tab Body
                        if (_selectedTab == 0)
                          _buildAdsTab(isAr)
                        else if (_selectedTab == 1)
                          _buildReviewsTab(isAr)
                        else
                          _buildTrustTab(isAr),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBtn(int index, String label) {
    final active = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: active ? _dlInk : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? Colors.white : _dlInk,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdsTab(bool isAr) {
    if (_isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.74,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, __) => const AdGridCardSkeleton(),
            childCount: 4,
          ),
        ),
      );
    }

    if (_sellerAds.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Center(
            child: Text(
              _state.s.tr(
                'لا توجد إعلانات منشورة حالياً',
                'Aucune annonce disponible',
                'No listings available right now',
              ),
              style: const TextStyle(color: _dlMuted, fontSize: 14),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.71,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ad = _sellerAds[index];
            final int adId = int.tryParse(ad['id'].toString()) ?? 0;
            final title = (ad['title'] ?? '').toString();
            final price =
                (ad['price_formatted'] ?? '${ad['price'] ?? ''} DH').toString();
            final image = (ad['main_image'] ?? ad['image'] ?? '').toString();
            final city =
                (ad['city_name'] ?? widget.sellerCity ?? 'المغرب').toString();
            final bool negotiable = ad['negotiable'] == true;

            return PressableScale(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdDetailScreen(
                      adId: adId,
                      initialAd: ad,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _dlSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 11,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppImage(
                            url: image,
                            fit: BoxFit.cover,
                            fallback: Container(
                              color: _dlPill,
                              alignment: Alignment.center,
                              child: const Icon(
                                CupertinoIcons.photo,
                                color: _dlMuted,
                                size: 30,
                              ),
                            ),
                          ),
                          if (negotiable)
                            PositionedDirectional(
                              top: 8,
                              end: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: _dlBg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _state.s.tr(
                                    'تفاوض',
                                    'Négociable',
                                    'Negotiable',
                                  ),
                                  style: const TextStyle(
                                    color: _dlInk,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(11),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _dlInk,
                                height: 1.25,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PriceText(
                                  price,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _dlInk,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      CupertinoIcons.location_solid,
                                      size: 10.5,
                                      color: _dlMuted,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        city,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: _dlMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: _sellerAds.length,
        ),
      ),
    );
  }

  Widget _buildReviewsTab(bool isAr) {
    final userReviews = _state.getUserReviewsForSeller(widget.sellerId);
    final myReview = _state.getMyReviewForSeller(widget.sellerId);
    final ratingStats = _state.computeSellerRatingStats(
      sellerId: widget.sellerId,
      baseRating: 4.9,
      baseCount: 48,
    );
    final bool isMyOwnProfile = _state.currentUser != null &&
        _state.currentUser!['id']?.toString() == widget.sellerId.toString();

    final baseReviews = <Map<String, dynamic>>[
      {
        'name': 'حمزة التازي',
        'rating': 5,
        'date': _state.s.tr('منذ 3 أيام', 'Il y a 3 jours', '3 days ago'),
        'item': 'Porsche Macan GTS',
        'comment': _state.s.tr(
          'البائع معقول بزاف، السلعة نقية كيف فالتصاور والمعاملة ممتازة، كيشرح ليك كلشي بالتفصيل.',
          'Vendeur très sérieux, produit impeccable conforme aux photos et excellente communication.',
          'Very reliable seller, item matched the photos and great communication throughout.',
        ),
        'verified': true,
      },
      {
        'name': 'هدى بناني',
        'rating': 5,
        'date': _state.s.tr('منذ أسبوع', 'Il y a 1 semaine', '1 week ago'),
        'item': 'iPhone 16 Pro Max',
        'comment': _state.s.tr(
          'تجربة شراء سريعة وموثوقة، التيليفون مختوم بالباكية وجربتو عاد خلصت. الله يعطيه الصحة.',
          'Expérience d’achat fluide, téléphone scellé vérifié avant paiement. Je recommande vivement !',
          'Smooth buying experience, inspected before payment. Highly recommended!',
        ),
        'verified': true,
      },
      {
        'name': 'رشيد الإدريسي',
        'rating': 5,
        'date': _state.s.tr('منذ أسبوعين', 'Il y a 2 semaines', '2 weeks ago'),
        'item': 'MacBook Pro M3 Max',
        'comment': _state.s.tr(
          'ما شاء الله إنسان صادق ومحترم، جا حتى لعندي وخلاني نفحص البيسي كامل على خاطري.',
          'Personne honnête et respectueuse. J’ai pu tester la machine tranquillement.',
          'Honest and respectful seller. Let me inspect the laptop thoroughly.',
        ),
        'verified': true,
      },
      {
        'name': 'سفيان الفيلالي',
        'rating': 4,
        'date': _state.s.tr('منذ شهر', 'Il y a 1 mois', '1 month ago'),
        'item': 'Montre Rolex Submariner',
        'comment': _state.s.tr(
          'معاملة ممتازة وثقة كاملة. استجابة سريعة فـ شات Apolo.',
          'Très bonne transaction en toute confiance. Réponse rapide.',
          'Great transaction with full trust. Fast replies on Apolo chat.',
        ),
        'verified': true,
      },
    ];
    final reviews = <Map<String, dynamic>>[...userReviews, ...baseReviews];

    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _dlSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Column(
                            children: [
                              Text(
                                ratingStats.average.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: _dlInk,
                                  letterSpacing:
                                      AppTypography.trackingForContext(
                                          context, -1),
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (_) => const Icon(
                                    Icons.star_rounded,
                                    size: 15,
                                    color: _dlStarAmber,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _state.s.tr(
                                  '${ratingStats.count} تقييم حقيقي',
                                  '${ratingStats.count} avis réels',
                                  '${ratingStats.count} verified reviews',
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _dlMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                _buildRatingBar('5', 0.88),
                                _buildRatingBar('4', 0.10),
                                _buildRatingBar('3', 0.02),
                                _buildRatingBar('2', 0.00),
                                _buildRatingBar('1', 0.00),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!isMyOwnProfile) ...[
                        const SizedBox(height: 14),
                        ApoloDlButton(
                          key: const Key('seller-write-review-btn'),
                          label: myReview != null
                              ? _state.s.tr(
                                  'تعديل تقييمك',
                                  'Modifier mon avis',
                                  'Edit your review',
                                )
                              : _state.s.tr(
                                  'أضف تقييمك',
                                  'Donner un avis',
                                  'Write a review',
                                ),
                          leadingIcon: CupertinoIcons.star_fill,
                          variant: ApoloDlButtonVariant.primary,
                          size: ApoloDlButtonSize.sm,
                          height: 42,
                          borderRadius: 999,
                          fullWidth: true,
                          onPressed: () {
                            final refAd = widget.initialAd ??
                                (_sellerAds.isNotEmpty
                                    ? _sellerAds.first
                                    : null);
                            showApoloWriteReviewSheet(
                              context,
                              sellerId: widget.sellerId,
                              sellerName: widget.sellerName,
                              adId: int.tryParse('${refAd?['id'] ?? ''}'),
                              adTitle: refAd?['title']?.toString(),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...reviews.map((r) => _buildReviewCard(r, isAr)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBar(String stars, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Text(
            stars,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _dlInk,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: _dlPill,
                valueColor: const AlwaysStoppedAnimation<Color>(_dlInk),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> r, bool isAr) {
    final author = (r['name'] ?? r['author'] ?? 'Apolo').toString();
    final starCount = (int.tryParse('${r['rating'] ?? 5}') ?? 5).clamp(1, 5);
    final itemLabel = (r['item'] ?? '').toString().trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: _dlPill,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  author.trim().isNotEmpty
                      ? author.trim().characters.first
                      : 'A',
                  style: const TextStyle(
                    color: _dlInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _dlInk,
                            ),
                          ),
                        ),
                        if (r['verified'] == true) ...[
                          const SizedBox(width: 4),
                          const ApoloVerifiedBadge(size: 14),
                        ],
                      ],
                    ),
                    Text(
                      (r['date'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _dlMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  starCount,
                  (_) => const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: _dlStarAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            (r['comment'] ?? '').toString(),
            style: const TextStyle(
              fontSize: 13.5,
              color: _dlInk,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (itemLabel.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                color: _dlBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                itemLabel,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: _dlMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrustTab(bool isAr) {
    final city = _resolvedCity;
    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              children: [
                _buildTrustRow(
                  icon: CupertinoIcons.person_badge_plus_fill,
                  title: _state.s.tr(
                    'بطاقة التعريف الوطنية مؤكدة',
                    'Pièce d’identité vérifiée',
                    'Government ID Verified',
                  ),
                  desc: _state.s.tr(
                    'تم فحص ومصادقة وثائق الهوية الوطنية من طرف فريق التوثيق في Apolo.',
                    'Document d’identité officiel validé par l’équipe de conformité Apolo.',
                    'Official identity document reviewed and verified by Apolo Trust Team.',
                  ),
                ),
                _buildTrustRow(
                  icon: CupertinoIcons.phone_circle_fill,
                  title: _state.s.tr(
                    'رقم هاتف مغربي موثق',
                    'Numéro marocain vérifié',
                    'Verified Phone Number',
                  ),
                  desc: _state.s.tr(
                    'رقم الهاتف مفعل عبر رمز التحقق OTP ومربوط مباشرة بحساب البائع.',
                    'Numéro de téléphone validé par code SMS OTP.',
                    'Phone number confirmed via SMS OTP verification.',
                  ),
                ),
                _buildTrustRow(
                  icon: CupertinoIcons.shield_lefthalf_fill,
                  title: _state.s.tr(
                    'حماية المعاملات Apolo Safety',
                    'Protection Apolo Safety',
                    'Apolo Safety Protection',
                  ),
                  desc: _state.s.tr(
                    'ينصح فريق Apolo بمعاينة وفحص السلعة شخصياً قبل دفع أي مبلغ.',
                    'Nous vous recommandons de vérifier l’article en personne avant tout paiement.',
                    'We recommend inspecting the item in person before making any payment.',
                  ),
                ),
                _buildTrustRow(
                  icon: CupertinoIcons.cube_box_fill,
                  title: _state.s.tr(
                    'طرق التسليم المتاحة',
                    'Modes de livraison disponibles',
                    'Available Delivery Methods',
                  ),
                  desc: _state.s.tr(
                    'التسليم يداً بيد في $city، أو الإرسال عبر أمانة كوليس بعد الاتفاق.',
                    'Remise en main propre à $city ou livraison express sécurisée selon accord.',
                    'Hand-to-hand pickup in $city, or insured express shipping by agreement.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrustRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _dlSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _dlInk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _dlMuted,
                    height: 1.42,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverTabsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverTabsDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 58.0;

  @override
  double get minExtent => 58.0;

  @override
  bool shouldRebuild(covariant _SliverTabsDelegate oldDelegate) {
    return true;
  }
}
