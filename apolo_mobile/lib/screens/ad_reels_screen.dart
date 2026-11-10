import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/state/app_state.dart';
import 'ad_detail_screen.dart';
import 'chat_room_screen.dart';
import 'seller_profile_screen.dart';
import 'widgets/app_image.dart';
import 'widgets/kinetic_widgets.dart';

/// 2026 Next-Gen Apolo Reels (ريلز وسكرول الإعلانات الفاخر 🎬):
/// - Apple HIG & TikTok 2026 Design Language.
/// - Full-screen vertical swipe between ads.
/// - Horizontal multi-photo carousel with natural aspect ratio & ambient blur.
/// - Stories-style photo progress segments + counter pill.
/// - Zen Mode: Tap media to toggle UI overlays smoothly for clean inspection.
/// - Double-tap 3D spring heart burst with elastic bounce and haptics.
/// - Interactive right action dock (Seller Avatar, Like with spring scale, Chat, Call, Share).
/// - Frosted glass bottom card with category, price in Apolo red, location, and full ad CTA.
/// - Shimmering dark skeleton loading and elegant empty feedback states.
class AdReelsScreen extends StatefulWidget {
  final int initialIndex;
  const AdReelsScreen({super.key, this.initialIndex = 0});

  @override
  State<AdReelsScreen> createState() => _AdReelsScreenState();
}

class _AdReelsScreenState extends State<AdReelsScreen>
    with TickerProviderStateMixin {
  final AppState _state = AppState();
  late final PageController _pageController;

  int _currentIndex = 0;
  int _selectedFeedTab = 0; // 0: لك, 1: الأحدث, 2: VIP
  bool _isLoading = true;
  List<Map<String, dynamic>> _reelsAds = [];

  // Zen Mode (Hide/Show UI on single tap)
  bool _isUiVisible = true;

  // Double-tap heart burst animation
  Offset? _heartBurstPosition;
  late final AnimationController _heartAnimController;

  static const Color _red = Color(0xFFE31B23);
  static const Color _ink = Color(0xFF07111E);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _loadReels();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadReels() async {
    setState(() => _isLoading = true);
    try {
      final res = await _state.api.dio
          .get('/ads', queryParameters: {'per_page': 30});
      List<dynamic> raw = [];
      if (res.data is Map && res.data['status'] == 'success') {
        raw = (res.data['data'] as List?) ?? [];
      }
      final parsed = raw
          .whereType<Map>()
          .map((e) => _normalizeReel(Map<String, dynamic>.from(e)))
          .where((r) => (r['images'] as List).isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          _reelsAds = parsed;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _reelsAds = [];
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _normalizeReel(Map<String, dynamic> raw) {
    final city = raw['city'] is Map ? raw['city'] as Map : const {};
    final cat = raw['category'] is Map ? raw['category'] as Map : const {};
    final seller = raw['seller'] is Map ? raw['seller'] as Map : const {};

    final cityName = (_state.s.isAr
            ? (city['name_ar'] ?? city['name'])
            : (city['name_fr'] ?? city['name'])) ??
        'المغرب';
    final catName = (_state.s.isAr
            ? (cat['name_ar'] ?? cat['name'])
            : (cat['name_fr'] ?? cat['name'])) ??
        'إعلانات';

    final int adId = int.tryParse('${raw['id'] ?? 0}') ?? 0;
    final int views =
        int.tryParse('${raw['views_count'] ?? raw['views'] ?? 120}') ?? 120;
    final int likes = (views * 0.16).round().clamp(12, 9999);

    List<String> images = [];
    if (raw['images'] is List && (raw['images'] as List).isNotEmpty) {
      images = (raw['images'] as List).map((e) => e.toString()).toList();
    } else if (raw['photos'] is List && (raw['photos'] as List).isNotEmpty) {
      images = (raw['photos'] as List).map((e) => e.toString()).toList();
    } else if (raw['gallery'] is List && (raw['gallery'] as List).isNotEmpty) {
      images = (raw['gallery'] as List).map((e) => e.toString()).toList();
    } else {
      final mainImg = (raw['main_image'] ??
              raw['primary_image'] ??
              raw['image'] ??
              raw['image_url'] ??
              '')
          .toString();
      if (mainImg.isNotEmpty) images = [mainImg];
    }

    return {
      'id': adId,
      'title': (raw['title'] ?? '').toString(),
      'price_formatted': (raw['price_formatted'] ??
              (raw['price'] != null ? '${raw['price']} DH' : ''))
          .toString(),
      'price': int.tryParse('${raw['price'] ?? 0}') ?? 0,
      'negotiable': raw['negotiable'] == true,
      'category_name': catName,
      'category_id': int.tryParse('${raw['category_id'] ?? cat['id'] ?? 0}') ?? 0,
      'city_name': cityName,
      'views_count': views,
      'likes_count': likes,
      'seller_name':
          (seller['name'] ?? raw['seller_name'] ?? 'بائع معتمد').toString(),
      'seller_avatar': (seller['avatar_url'] ?? seller['avatar'])?.toString(),
      'seller_phone': (seller['phone'] ?? raw['seller_phone'] ?? '').toString(),
      'seller_verified':
          seller['is_verified'] == true || raw['seller_verified'] == true,
      'seller_online': seller['is_online'] ?? true,
      'images': images,
      'main_image': images.isNotEmpty ? images.first : '',
      'is_vip': raw['is_vip'] == true || raw['is_featured'] == true,
      'raw_ad': raw,
    };
  }

  List<Map<String, dynamic>> get _filteredReels {
    if (_selectedFeedTab == 1) {
      final list = List<Map<String, dynamic>>.from(_reelsAds);
      list.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
      return list;
    }
    if (_selectedFeedTab == 2) {
      return _reelsAds.where((a) => a['is_vip'] == true).toList();
    }
    return _reelsAds;
  }

  void _triggerHeartBurst(Offset localPos, int adId) {
    HapticFeedback.heavyImpact();
    setState(() => _heartBurstPosition = localPos);
    _heartAnimController.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _heartBurstPosition = null);
    });
    if (!_state.favoriteAdIds.contains(adId)) {
      _state.toggleFavorite(adId);
    }
  }

  void _toggleUiVisibility() {
    HapticFeedback.selectionClick();
    setState(() => _isUiVisible = !_isUiVisible);
  }

  void _callSeller(String phone, String name) async {
    HapticFeedback.mediumImpact();
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_state.s.isAr
              ? 'رقم الهاتف غير متوفر حالياً'
              : 'Numéro non disponible'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openChat(Map<String, dynamic> reel) {
    HapticFeedback.lightImpact();
    final int adId = reel['id'] as int;
    final title = reel['title'] as String;
    final price = reel['price_formatted'] as String;
    final images = reel['images'] as List<String>;
    final image = images.isNotEmpty ? images.first : '';
    final sellerName = reel['seller_name'] as String;
    final sellerAvatar = reel['seller_avatar'] as String?;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          conversationId: adId,
          peerName: sellerName,
          adTitle: title,
          peerAvatar: sellerAvatar,
          adImage: image,
          adPrice: price,
        ),
      ),
    );
  }

  void _shareAd(Map<String, dynamic> reel) {
    HapticFeedback.lightImpact();
    final title = reel['title'];
    final price = reel['price_formatted'];
    Share.share(
      'شوف هاد العرض فـ Apolo.ma:\n$title — $price\nhttps://apolo.ma/ads/${reel['id']}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final reels = _filteredReels;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Vertical TikTok-style Reels PageView
          if (_isLoading)
            const _ReelsSkeletonLoader()
          else if (reels.isEmpty)
            _buildEmptyState(isAr)
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              itemCount: reels.length,
              onPageChanged: (idx) {
                HapticFeedback.lightImpact();
                setState(() => _currentIndex = idx);
              },
              itemBuilder: (context, index) {
                final reel = reels[index];
                final int adId = reel['id'] as int;
                final bool isLiked = _state.favoriteAdIds.contains(adId);

                return _ReelAdItemView(
                  reel: reel,
                  isAr: isAr,
                  isLiked: isLiked,
                  isUiVisible: _isUiVisible,
                  onToggleUi: _toggleUiVisibility,
                  onToggleFavorite: () {
                    HapticFeedback.mediumImpact();
                    _state.toggleFavorite(adId);
                    setState(() {});
                  },
                  onDoubleTap: (pos) => _triggerHeartBurst(pos, adId),
                  onOpenChat: () => _openChat(reel),
                  onCallSeller: () => _callSeller(
                    reel['seller_phone'] as String,
                    reel['seller_name'] as String,
                  ),
                  onShare: () => _shareAd(reel),
                  onOpenFullAd: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdDetailScreen(
                          adId: adId,
                          initialAd: reel['raw_ad'],
                        ),
                      ),
                    );
                  },
                  onOpenSellerProfile: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellerProfileScreen(
                          sellerId: reel['seller_id'] ?? adId,
                          sellerName: reel['seller_name'] as String,
                          sellerAvatar: reel['seller_avatar'] as String?,
                          sellerPhone: reel['seller_phone'] as String?,
                          sellerCity: reel['city_name'] as String?,
                          isVerified: reel['seller_verified'] == true,
                          isOnline: reel['seller_online'] == true,
                          initialAd: reel['raw_ad'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

          // 2. Double-Tap Bursting Heart Animation
          if (_heartBurstPosition != null)
            Positioned(
              left: _heartBurstPosition!.dx - 54,
              top: _heartBurstPosition!.dy - 54,
              child: IgnorePointer(
                child: ScaleTransition(
                  scale: TweenSequence<double>([
                    TweenSequenceItem(
                      tween: Tween(begin: 0.0, end: 1.45)
                          .chain(CurveTween(curve: Curves.elasticOut)),
                      weight: 60,
                    ),
                    TweenSequenceItem(
                      tween: Tween(begin: 1.45, end: 1.0)
                          .chain(CurveTween(curve: Curves.easeInCubic)),
                      weight: 40,
                    ),
                  ]).animate(_heartAnimController),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                      CurvedAnimation(
                        parent: _heartAnimController,
                        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
                      ),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66FF2A42),
                            blurRadius: 32,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.heart_fill,
                        color: Color(0xFFFF2A42),
                        size: 108,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 3. Top Floating Glass Header (Animated Opacity for Zen Mode)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOutCubic,
              opacity: _isUiVisible ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_isUiVisible,
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        // Back button (Frosted Glass)
                        PressableScale(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.40),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.20),
                                    width: 0.8,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  isAr
                                      ? CupertinoIcons.chevron_right
                                      : CupertinoIcons.chevron_left,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Apple Segmented Filter Pill (لك | الأحدث | VIP)
                        Expanded(
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.40),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.18),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildSegmentPill(0, isAr ? 'لك' : 'Pour vous'),
                                      _buildSegmentPill(1, isAr ? 'الأحدث' : 'Récents'),
                                      _buildSegmentPill(2, isAr ? 'VIP' : 'VIP'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Live Pulse Reels Capsule
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.40),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: _red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _red,
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'REELS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentPill(int index, String label) {
    final active = _selectedFeedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFeedTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? _ink : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Icon(
                CupertinoIcons.play_rectangle,
                color: Colors.white54,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isAr ? 'لا توجد إعلانات في هذا التبويب' : 'Aucune annonce disponible',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAr
                  ? 'جرب اختيار قسم آخر أو السحب لتحديث المحتوى'
                  : 'Essayez une autre section ou tirez pour rafraîchir',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            PressableScale(
              onTap: _loadReels,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAr ? 'تحديث الإعلانات' : 'Actualiser',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual Reel Page View with:
/// - Natural Aspect Ratio Main Image.
/// - Ambient Blurred Backdrop.
/// - TikTok / Stories horizontal multi-photo carousel with top progress segments.
/// - InteractiveViewer for smooth zooming.
/// - Right Action Dock with Spring Like Animation.
/// - Apple Frosted Glass Bottom Card with rich listing telemetry.
class _ReelAdItemView extends StatefulWidget {
  final Map<String, dynamic> reel;
  final bool isAr;
  final bool isLiked;
  final bool isUiVisible;
  final VoidCallback onToggleUi;
  final VoidCallback onToggleFavorite;
  final Function(Offset) onDoubleTap;
  final VoidCallback onOpenChat;
  final VoidCallback onCallSeller;
  final VoidCallback onShare;
  final VoidCallback onOpenFullAd;
  final VoidCallback onOpenSellerProfile;

  const _ReelAdItemView({
    required this.reel,
    required this.isAr,
    required this.isLiked,
    required this.isUiVisible,
    required this.onToggleUi,
    required this.onToggleFavorite,
    required this.onDoubleTap,
    required this.onOpenChat,
    required this.onCallSeller,
    required this.onShare,
    required this.onOpenFullAd,
    required this.onOpenSellerProfile,
  });

  @override
  State<_ReelAdItemView> createState() => _ReelAdItemViewState();
}

class _ReelAdItemViewState extends State<_ReelAdItemView>
    with TickerProviderStateMixin {
  late final PageController _photoPageController;
  int _currentPhotoIndex = 0;
  late final AnimationController _likeBounceController;

  static const Color _red = Color(0xFFE31B23);

  @override
  void initState() {
    super.initState();
    _photoPageController = PageController();
    _likeBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void didUpdateWidget(covariant _ReelAdItemView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != oldWidget.isLiked && widget.isLiked) {
      _likeBounceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    _likeBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final isAr = widget.isAr;
    final List<String> images = (reel['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [reel['main_image'].toString()];

    final String title = reel['title'] as String;
    final String priceStr = reel['price_formatted'] as String;
    final String category = reel['category_name'] as String;
    final String city = reel['city_name'] as String;
    final String sellerName = reel['seller_name'] as String;
    final String? sellerAvatar = reel['seller_avatar'] as String?;
    final bool isVerified = reel['seller_verified'] == true;
    final bool isOnline = reel['seller_online'] == true;
    final bool isVip = reel['is_vip'] == true;
    final bool negotiable = reel['negotiable'] == true;
    final int likes = reel['likes_count'] as int;

    final String activePhotoUrl = images.isNotEmpty
        ? images[_currentPhotoIndex.clamp(0, images.length - 1)]
        : '';

    return GestureDetector(
      onTap: widget.onToggleUi,
      onDoubleTapDown: (details) => widget.onDoubleTap(details.localPosition),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Blurred Backdrop
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(
                  url: activePhotoUrl,
                  fit: BoxFit.cover,
                  fallback: Container(color: const Color(0xFF07111E)),
                ),
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Central Multi-Photo Horizontal Carousel (Clean Natural Ratio)
          Positioned.fill(
            child: Center(
              child: PageView.builder(
                controller: _photoPageController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: images.length,
                onPageChanged: (idx) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentPhotoIndex = idx);
                },
                itemBuilder: (context, pIdx) {
                  final photoUrl = images[pIdx];
                  return Center(
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 3.5,
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.78,
                          maxWidth: MediaQuery.of(context).size.width,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: AppImage(
                            url: photoUrl,
                            fit: BoxFit.contain,
                            fallback: Container(
                              height: 320,
                              color: const Color(0xFF0E1E32),
                              alignment: Alignment.center,
                              child: const Icon(
                                CupertinoIcons.photo,
                                color: Colors.white24,
                                size: 64,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Vignette Gradients for readability
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 240,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Stories-Style Top Micro Progress Segments & Counter Pill
          if (images.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 58,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: widget.isUiVisible ? 1.0 : 0.0,
                child: Row(
                  children: [
                    // Segments
                    Expanded(
                      child: Row(
                        children: List.generate(images.length, (sIdx) {
                          final bool active = sIdx == _currentPhotoIndex;
                          return Expanded(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Counter Tag
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.50),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '${_currentPhotoIndex + 1}/${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Right Action Dock (Interactive Floating Actions)
          PositionedDirectional(
            end: 14,
            bottom: 34,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOutCubic,
              opacity: widget.isUiVisible ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !widget.isUiVisible,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Seller Avatar
                    PressableScale(
                      onTap: widget.onOpenSellerProfile,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: sellerAvatar != null && sellerAvatar.isNotEmpty
                                  ? Image.network(
                                      sellerAvatar,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildAvatarFallback(sellerName),
                                    )
                                  : _buildAvatarFallback(sellerName),
                            ),
                          ),
                          if (isOnline)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Like Button with Spring Bounce Scale
                    ScaleTransition(
                      scale: TweenSequence<double>([
                        TweenSequenceItem(
                          tween: Tween(begin: 1.0, end: 1.35)
                              .chain(CurveTween(curve: Curves.easeOutBack)),
                          weight: 50,
                        ),
                        TweenSequenceItem(
                          tween: Tween(begin: 1.35, end: 1.0)
                              .chain(CurveTween(curve: Curves.easeIn)),
                          weight: 50,
                        ),
                      ]).animate(_likeBounceController),
                      child: _buildActionBtn(
                        icon: widget.isLiked
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        iconColor:
                            widget.isLiked ? const Color(0xFFFF2A42) : Colors.white,
                        label: '${likes + (widget.isLiked ? 1 : 0)}',
                        onTap: widget.onToggleFavorite,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // In-App Chat Button
                    _buildActionBtn(
                      icon: CupertinoIcons.chat_bubble_2_fill,
                      iconColor: Colors.white,
                      label: isAr ? 'شات' : 'Chat',
                      onTap: widget.onOpenChat,
                    ),
                    const SizedBox(height: 16),

                    // Direct Phone Call Button
                    _buildActionBtn(
                      icon: CupertinoIcons.phone_fill,
                      iconColor: const Color(0xFF10B981),
                      label: isAr ? 'اتصال' : 'Appel',
                      onTap: widget.onCallSeller,
                    ),
                    const SizedBox(height: 16),

                    // Share Button
                    _buildActionBtn(
                      icon: CupertinoIcons.share,
                      iconColor: Colors.white,
                      label: isAr ? 'مشاركة' : 'Partager',
                      onTap: widget.onShare,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 6. Bottom Information Card (Apple Glass 2026 Material)
          PositionedDirectional(
            start: 14,
            end: 80,
            bottom: 26,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOutCubic,
              opacity: widget.isUiVisible ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !widget.isUiVisible,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF07111E).withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badges Row (Category + VIP + Negotiable)
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    width: 0.6,
                                  ),
                                ),
                                child: Text(
                                  category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isVip)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.sparkles,
                                        color: Colors.white,
                                        size: 11,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'VIP',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (negotiable)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.40),
                                      width: 0.6,
                                    ),
                                  ),
                                  child: Text(
                                    isAr ? 'قابل للتفاوض' : 'Négociable',
                                    style: const TextStyle(
                                      color: Color(0xFF34D399),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Seller Row
                          PressableScale(
                            onTap: widget.onOpenSellerProfile,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '@$sellerName',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    CupertinoIcons.checkmark_seal_fill,
                                    color: Color(0xFF38BDF8),
                                    size: 14,
                                  ),
                                ],
                                const SizedBox(width: 4),
                                Icon(
                                  isAr
                                      ? CupertinoIcons.chevron_left
                                      : CupertinoIcons.chevron_right,
                                  color: Colors.white60,
                                  size: 11,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Ad Title
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Price & City Row
                          Row(
                            children: [
                              // Price Tag in Apolo Crimson
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  priceStr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // City
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.location_solid,
                                    color: Colors.white70,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    city,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),

                              // View Ad Button
                              PressableScale(
                                onTap: widget.onOpenFullAd,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 0.6,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isAr ? 'التفاصيل' : 'Détails',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        isAr
                                            ? CupertinoIcons.arrow_left
                                            : CupertinoIcons.arrow_right,
                                        color: Colors.white,
                                        size: 11,
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: const Color(0xFF0E1E32),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'A',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PressableScale(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.40),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.30),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            shadows: [
              BoxShadow(color: Colors.black, blurRadius: 6),
            ],
          ),
        ),
      ],
    );
  }
}

/// 2026 Dark Shimmer Skeleton Loader for Reels Loading State
class _ReelsSkeletonLoader extends StatelessWidget {
  const _ReelsSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF07111E),
      child: Stack(
        children: [
          // Center Placeholder Image Shimmer
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: MediaQuery.of(context).size.height * 0.70,
              decoration: BoxDecoration(
                color: const Color(0xFF0E1E32),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: const Center(
                child: CupertinoActivityIndicator(color: Colors.white54),
              ),
            ),
          ),
          // Bottom Card Shimmer
          Positioned(
            left: 14,
            right: 80,
            bottom: 26,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF0E1E32).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
            ),
          ),
          // Right Dock Shimmer
          Positioned(
            right: 14,
            bottom: 40,
            child: Column(
              children: List.generate(
                4,
                (_) => Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1E32).withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
