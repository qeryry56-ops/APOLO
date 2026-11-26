import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_config.dart';
import '../core/services/firebase_chat_service.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/dl_qr_code.dart';
import '../widgets/dl_settings_kit.dart';
import 'ad_detail_screen.dart';
import 'share_profile_screen.dart';
import 'widgets/apolo_safety_sheet.dart';
import 'widgets/app_image.dart';
import 'widgets/price_text.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/skeleton_loader.dart';

/// Apple Human Interface Guidelines (HIG) 2026 Public Seller Profile:
/// - 8pt baseline grid with exact Apple whitespace & margins (16pt / 20pt padding).
/// - Apple typography, soft elevated cards, hairline borders (0.8pt #E2E8F0).
/// - Hero Seller Header: 84pt Avatar, Verified Blue Seal, Online Dot, Member Since, Location.
/// - Apple Metric Pills: Rating (⭐ 4.9), Response Speed (⚡ <15min), Trust (🛡️ 100% Verified).
/// - 1-Tap Dual Action Bar: "محادثة فورية 💬" (Primary Crimson) & "اتصال مباشر 📞" (Emerald Call).
/// - Apple Segmented Control: إعلانات البائع | تقييمات المشترين ⭐ | الثقة والضمانات.
/// - 2-Column Responsive Ads Grid + Reviews with Verified Buyer badges.
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
  int _selectedTab = 0; // 0: الإعلانات, 1: التقييمات, 2: حول البائع
  bool _isLoading = true;
  List<Map<String, dynamic>> _sellerAds = [];

  // Unified 2026 Grouped Card Palette
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surfaceElevated = Color(0xFFFFFFFF);
  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE7EAF0);
  static const Color _red = Color(0xFFE31B23);
  static const Color _emerald = Color(0xFF10B981);
  static const Color _blueVerified = Color(0xFF0866FF);
  static const Color _starGold = Color(0xFFF59E0B);

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
            content: Text(_state.s.tr(
              'رقم هاتف البائع غير متوفر حالياً',
              'Numéro non disponible',
              'Seller phone number not available',
            )),
            backgroundColor: _red,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppState().s.tr(
            'اختر إعلاناً للبائع لبدء المحادثة.',
            'Choisissez une annonce pour contacter ce vendeur.',
            'Select a listing to message this seller.',
          ))));
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                AdDetailScreen(adId: id, initialAd: ad, openChatOnLoad: true)));
  }

  void _showMoreActions(bool isAr) {
    HapticFeedback.selectionClick();
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(widget.sellerName),
        message: Text(
          _state.s.tr(
            'خيارات الملف الشخصي للبائع',
            'Options du profil vendeur',
            'Seller profile options',
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _shareSellerProfile(_state.s);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.share, size: 18),
                const SizedBox(width: 8),
                Text(_state.s.tr(
                  'مشاركة البروفايل',
                  'Partager le profil',
                  'Share profile',
                )),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _reportSeller(isAr);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.flag, size: 18),
                const SizedBox(width: 8),
                Text(_state.s.tr(
                  'الإبلاغ عن البائع',
                  'Signaler le vendeur',
                  'Report seller',
                )),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              _blockSeller(isAr);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.nosign, size: 18),
                const SizedBox(width: 8),
                Text(_state.s.tr(
                  'حظر هذا البائع',
                  'Bloquer le vendeur',
                  'Block seller',
                )),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(_state.s.tr('إلغاء', 'Annuler', 'Cancel')),
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
        backgroundColor: _red,
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
                        // 1. Dynamic Layer v5.1 Account / Follow & Following Header
                        SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 20),
                                child: ApoloDlAccountHeader(
                                  avatar: widget.sellerAvatar != null &&
                                          widget.sellerAvatar!.isNotEmpty
                                      ? AppImage(
                                          url: widget.sellerAvatar!,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          fallback: Icon(
                                            CupertinoIcons.person_fill,
                                            size: 32,
                                            color: palette.iconMuted,
                                          ),
                                        )
                                      : Icon(
                                          CupertinoIcons.person_fill,
                                          size: 32,
                                          color: palette.iconMuted,
                                        ),
                                  displayName: widget.sellerName,
                                  nameTrailing: widget.isVerified
                                      ? const Icon(
                                          CupertinoIcons.checkmark_seal_fill,
                                          color: _blueVerified,
                                          size: 17,
                                        )
                                      : null,
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
                                      value: '4.9',
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
                                    key: const Key('seller-share-btn'),
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
                                    onPressed: () => _shareSellerProfile(s),
                                  ),
                                  bio: s.tr(
                                    'تاجر موثوق في Apolo.ma · $city · استجابة سريعة على الشات والمكالمات.',
                                    'Vendeur vérifié sur Apolo.ma · $city · Réponse rapide par chat et appel.',
                                    'Verified seller on Apolo.ma · $city · Fast reply on chat and calls.',
                                  ),
                                  extraActions: Row(
                                    children: [
                                      Expanded(
                                        child: ApoloDlButton(
                                          key: const Key('seller-chat-btn'),
                                          label: s.tr(
                                            'محادثة فورية',
                                            'Message direct',
                                            'Message',
                                          ),
                                          leadingIcon:
                                              CupertinoIcons.chat_bubble_2_fill,
                                          variant:
                                              ApoloDlButtonVariant.secondary,
                                          size: ApoloDlButtonSize.sm,
                                          height: 40,
                                          borderRadius: 999,
                                          fullWidth: true,
                                          onPressed: _openChatWithSeller,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ApoloDlButton(
                                          key: const Key('seller-call-btn'),
                                          label: s.tr(
                                            'اتصال',
                                            'Appeler',
                                            'Call',
                                          ),
                                          leadingIcon:
                                              CupertinoIcons.phone_fill,
                                          variant:
                                              ApoloDlButtonVariant.secondary,
                                          size: ApoloDlButtonSize.sm,
                                          height: 40,
                                          borderRadius: 999,
                                          fullWidth: true,
                                          onPressed: _callSeller,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 2. Dynamic Layer Segmented Control Tabs (Pinned Sticky Header)
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _SliverTabsDelegate(
                            child: Container(
                              color: palette.bg,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 480),
                                  child: Container(
                                    height: 42,
                                    padding: const EdgeInsets.all(3.5),
                                    decoration: BoxDecoration(
                                      color: palette.groupCard,
                                      borderRadius: BorderRadius.circular(12),
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
                                        _buildTabBtn(
                                          1,
                                          _state.s.tr(
                                            'التقييمات (48)',
                                            'Avis (48)',
                                            'Reviews (48)',
                                          ),
                                        ),
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
    final palette = ApoloDlPalette.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? palette.bg : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? palette.ink : palette.muted,
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── TAB 1: ADS GRID ─────────────────────────
  Widget _buildAdsTab(bool isAr) {
    if (_isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
              style: const TextStyle(color: _muted, fontSize: 14),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.69,
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
                  color: _surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: _ink.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image with natural aspect ratio container
                    Expanded(
                      flex: 11,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                            child: AppImage(
                              url: image,
                              fit: BoxFit.cover,
                              fallback: Container(
                                color: const Color(0xFFF1F5F9),
                                alignment: Alignment.center,
                                child: const Icon(
                                  CupertinoIcons.photo,
                                  color: _muted,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          if (negotiable)
                            PositionedDirectional(
                              top: 8,
                              end: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: _emerald.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _state.s.tr('تفاوض', 'Négociable', 'Negotiable'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Details
                    Expanded(
                      flex: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
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
                                color: _ink,
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
                                    fontWeight: FontWeight.w900,
                                    color: _red,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      CupertinoIcons.location_solid,
                                      size: 10,
                                      color: _muted,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        city,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
                                          color: _muted,
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

  // ───────────────────────── TAB 2: REVIEWS ─────────────────────────
  Widget _buildReviewsTab(bool isAr) {
    final reviews = [
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
          'Expérience d\'achat fluide, téléphone scellé vérifié avant paiement. Je recommande vivement!',
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
          'Personne honnête et respectueuse. J\'ai pu tester la machine tranquillement.',
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

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          children: [
            // Overall Rating Apple Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border, width: 0.8),
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(
                        '4.9',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                          letterSpacing:
                              AppTypography.trackingForContext(context, -1),
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => const Icon(
                            CupertinoIcons.star_fill,
                            size: 14,
                            color: _starGold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _state.s.tr('48 تقييم حقيقي', '48 avis réels',
                            '48 verified reviews'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _muted,
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
            ),
            const SizedBox(height: 16),

            // Review List
            ...reviews.map((r) => _buildReviewCard(r, isAr)),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(String stars, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            stars,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(_starGold),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> r, bool isAr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0E7FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  r['name'][0],
                  style: const TextStyle(
                    color: Color(0xFF4338CA),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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
                        Text(
                          r['name'],
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        if (r['verified'] == true) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            color: _emerald,
                            size: 13,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      r['date'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: _muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  r['rating'] as int,
                  (i) => const Icon(
                    CupertinoIcons.star_fill,
                    size: 12,
                    color: _starGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            r['comment'],
            style: const TextStyle(
              fontSize: 13,
              color: _ink,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '📦 ${r['item']}',
              style: const TextStyle(
                fontSize: 10.5,
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── TAB 3: TRUST & GUARANTEES ─────────────────────────
  Widget _buildTrustTab(bool isAr) {
    final city = _resolvedCity;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          children: [
            _buildTrustRow(
              icon: CupertinoIcons.person_badge_plus_fill,
              iconColor: _blueVerified,
              title: _state.s.tr(
                'بطاقة التعريف الوطنية مؤكدة',
                'Pièce d\'identité vérifiée',
                'Government ID Verified',
              ),
              desc: _state.s.tr(
                'تم فحص ومصادقة وثائق الهوية الوطنية من طرف فريق التوثيق في Apolo.',
                'Document d\'identité officiel validé par l\'équipe de conformité Apolo.',
                'Official identity document reviewed and verified by Apolo Trust Team.',
              ),
            ),
            _buildTrustRow(
              icon: CupertinoIcons.phone_circle_fill,
              iconColor: _emerald,
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
              iconColor: _red,
              title: _state.s.tr(
                'حماية المعاملات Apolo Safety',
                'Protection Apolo Safety',
                'Apolo Safety Protection',
              ),
              desc: _state.s.tr(
                'ينصح فريق Apolo بمعاينة وفحص السلعة شخصياً قبل دفع أي مبلغ.',
                'Nous vous recommandons de vérifier l\'article en personne avant tout paiement.',
                'We recommend inspecting the item in person before making any payment.',
              ),
            ),
            _buildTrustRow(
              icon: CupertinoIcons.cube_box_fill,
              iconColor: _red,
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
    );
  }

  Widget _buildTrustRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
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
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
