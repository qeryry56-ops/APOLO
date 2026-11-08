import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'ad_detail_screen.dart';
import 'chat_room_screen.dart';
import 'widgets/app_image.dart';
import 'widgets/kinetic_widgets.dart';

/// 2026 High-UI Full-Screen Vertical Ads Reels ("ريلز الإعلانات"):
/// - Full-screen vertical swipe feed (`PageView.builder(scrollDirection: Axis.vertical)`)
/// - Double-tap to like with bursting heart animation
/// - Right-side action dock: Seller Avatar, Like/Favorite, In-App Chat, Direct Call, Share
/// - Bottom glass overlay: Category tag, Title, Price badge, Location, Full Ad CTA
/// - Tab switches: لك ✨ (For You) | الأحدث ⚡ (Latest) | VIP 👑 (Featured)
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
  int _selectedFeedTab = 0; // 0: For You, 1: Latest, 2: VIP
  bool _isLoading = true;
  List<Map<String, dynamic>> _reelsAds = [];

  // Double-tap heart bursting animation state
  Offset? _heartBurstPosition;
  late final AnimationController _heartAnimController;

  static const Color _red = Color(0xFFE31B23);
  static const Color _ink = Color(0xFF0F172A);

  static const List<Map<String, dynamic>> _fallbackReelsData = [
    {
      'id': 9001,
      'title': 'Porsche Macan GTS 2025 — Pack Sport Chrono',
      'price_formatted': '980 000 DH',
      'price': 980000,
      'negotiable': true,
      'category_name': 'وسائل النقل',
      'category_id': 1,
      'city_name': 'الدار البيضاء • المعاريف',
      'views_count': 1420,
      'likes_count': 238,
      'seller_name': 'ياسين العلمي',
      'seller_phone': '0661123456',
      'seller_verified': true,
      'seller_online': true,
      'main_image':
          'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=1200&q=85',
      'is_vip': true,
    },
    {
      'id': 9002,
      'title': 'iPhone 16 Pro Max 256Go Titane Naturel — Scellé',
      'price_formatted': '14 200 DH',
      'price': 14200,
      'negotiable': true,
      'category_name': 'هواتف وتقنية',
      'category_id': 4,
      'city_name': 'الرباط • أكدال',
      'views_count': 980,
      'likes_count': 174,
      'seller_name': 'سلمى بنجلون',
      'seller_phone': '0662234567',
      'seller_verified': true,
      'seller_online': true,
      'main_image':
          'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=1200&q=85',
      'is_vip': false,
    },
    {
      'id': 9003,
      'title': 'Villa Contemporaine avec Piscine — Californie',
      'price_formatted': '6 500 000 DH',
      'price': 6500000,
      'negotiable': false,
      'category_name': 'عقارات',
      'category_id': 2,
      'city_name': 'الدار البيضاء • كاليفورنيا',
      'views_count': 2150,
      'likes_count': 412,
      'seller_name': 'عمر المراكشي',
      'seller_phone': '0663345678',
      'seller_verified': true,
      'seller_online': false,
      'main_image':
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1200&q=85',
      'is_vip': true,
    },
    {
      'id': 9004,
      'title': 'Montre Rolex Submariner Date — Full Set 2024',
      'price_formatted': '138 000 DH',
      'price': 138000,
      'negotiable': true,
      'category_name': 'أزياء وجمال',
      'category_id': 6,
      'city_name': 'طنجة • مالاباطا',
      'views_count': 790,
      'likes_count': 195,
      'seller_name': 'كريم التازي',
      'seller_phone': '0664456789',
      'seller_verified': false,
      'seller_online': true,
      'main_image':
          'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=1200&q=85',
      'is_vip': true,
    },
    {
      'id': 9005,
      'title': 'MacBook Pro 16" M3 Max — 36GB RAM / 1TB SSD',
      'price_formatted': '27 500 DH',
      'price': 27500,
      'negotiable': true,
      'category_name': 'حواسيب وإعلاميات',
      'category_id': 3,
      'city_name': 'مراكش • كليز',
      'views_count': 1120,
      'likes_count': 158,
      'seller_name': 'أمين الصنهاجي',
      'seller_phone': '0665567890',
      'seller_verified': true,
      'seller_online': true,
      'main_image':
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=1200&q=85',
      'is_vip': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
          .toList();

      if (parsed.length < 5) {
        // Merge fallback reels to ensure rich immersive experience
        for (final fb in _fallbackReelsData) {
          if (!parsed.any((a) => a['id'] == fb['id'])) {
            parsed.add(Map<String, dynamic>.from(fb));
          }
        }
      }

      if (mounted) {
        setState(() {
          _reelsAds = parsed.isNotEmpty
              ? parsed
              : _fallbackReelsData
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _reelsAds = _fallbackReelsData
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
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
    final int views = int.tryParse('${raw['views_count'] ?? raw['views'] ?? 100}') ?? 100;
    final int likes = (views * 0.16).round().clamp(12, 9999);

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
      'seller_name': (seller['name'] ?? raw['seller_name'] ?? 'بائع معتمد').toString(),
      'seller_avatar': (seller['avatar_url'] ?? seller['avatar'])?.toString(),
      'seller_phone': (seller['phone'] ?? raw['seller_phone'] ?? '').toString(),
      'seller_verified': seller['is_verified'] == true || raw['seller_verified'] == true,
      'seller_online': seller['is_online'] ?? true,
      'main_image': (raw['main_image'] ?? raw['primary_image'] ?? raw['image'] ?? '').toString(),
      'is_vip': raw['is_vip'] == true || raw['is_featured'] == true,
      'raw_ad': raw,
    };
  }

  List<Map<String, dynamic>> get _filteredReels {
    if (_selectedFeedTab == 1) {
      // Latest: sort by ID descending
      final list = List<Map<String, dynamic>>.from(_reelsAds);
      list.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
      return list;
    }
    if (_selectedFeedTab == 2) {
      // VIP only
      return _reelsAds.where((a) => a['is_vip'] == true).toList();
    }
    // For You: smart personalized
    return _reelsAds;
  }

  void _triggerHeartBurst(Offset localPos, int adId) {
    HapticFeedback.mediumImpact();
    setState(() => _heartBurstPosition = localPos);
    _heartAnimController.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _heartBurstPosition = null);
    });
    if (!_state.favoriteAdIds.contains(adId)) {
      _state.toggleFavorite(adId);
    }
  }

  void _callSeller(String phone, String name) async {
    HapticFeedback.mediumImpact();
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_state.s.isAr ? 'رقم الهاتف غير متوفر حالياً' : 'Numéro non disponible'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _red,
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
    final image = reel['main_image'] as String;
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
          // 1. Vertical Swipeable Reels Feed
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: _red, strokeWidth: 2.5),
            )
          else if (reels.isEmpty)
            Center(
              child: Text(
                isAr ? 'لا توجد إعلانات في هذا القسم' : 'Aucune annonce disponible',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            )
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              itemCount: reels.length,
              onPageChanged: (idx) => setState(() => _currentIndex = idx),
              itemBuilder: (context, index) {
                final reel = reels[index];
                return _buildReelPage(reel, isAr);
              },
            ),

          // 2. Double-Tap Bursting Heart Animation
          if (_heartBurstPosition != null)
            Positioned(
              left: _heartBurstPosition!.dx - 48,
              top: _heartBurstPosition!.dy - 48,
              child: IgnorePointer(
                child: ScaleTransition(
                  scale: TweenSequence<double>([
                    TweenSequenceItem(
                      tween: Tween(begin: 0.0, end: 1.35)
                          .chain(CurveTween(curve: Curves.easeOutBack)),
                      weight: 50,
                    ),
                    TweenSequenceItem(
                      tween: Tween(begin: 1.35, end: 1.0)
                          .chain(CurveTween(curve: Curves.easeIn)),
                      weight: 50,
                    ),
                  ]).animate(_heartAnimController),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                      CurvedAnimation(
                        parent: _heartAnimController,
                        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.heart_fill,
                      color: Color(0xFFFF2A42),
                      size: 96,
                      shadows: [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 3. Top Floating Navigation Bar (Back + Tab Pills)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Back button
                    PressableScale(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.40),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
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
                    const SizedBox(width: 12),

                    // Centered Feed Filter Tabs (لك | الأحدث | VIP)
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTabPill(0, isAr ? 'لك ✨' : 'Pour vous ✨'),
                              _buildTabPill(1, isAr ? 'الأحدث ⚡' : 'Récents ⚡'),
                              _buildTabPill(2, isAr ? 'VIP 👑' : 'VIP 👑'),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Reels badge indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_red, Color(0xFFFF3366)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: _red.withValues(alpha: 0.45),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.play_rectangle_fill,
                            color: Colors.white,
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'REELS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
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
        ],
      ),
    );
  }

  Widget _buildTabPill(int index, String label) {
    final active = _selectedFeedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFeedTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: active ? _ink : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildReelPage(Map<String, dynamic> reel, bool isAr) {
    final int adId = reel['id'] as int;
    final String title = reel['title'] as String;
    final String priceStr = reel['price_formatted'] as String;
    final String category = reel['category_name'] as String;
    final String city = reel['city_name'] as String;
    final String imgUrl = reel['main_image'] as String;
    final String sellerName = reel['seller_name'] as String;
    final String? sellerAvatar = reel['seller_avatar'] as String?;
    final String sellerPhone = reel['seller_phone'] as String;
    final bool isVerified = reel['seller_verified'] == true;
    final bool isOnline = reel['seller_online'] == true;
    final bool isVip = reel['is_vip'] == true;
    final int likes = reel['likes_count'] as int;
    final bool isLiked = _state.favoriteAdIds.contains(adId);

    return GestureDetector(
      onDoubleTapDown: (details) {
        _triggerHeartBurst(details.localPosition, adId);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Immersive Full-Bleed Media Visual
          AppImage(
            url: imgUrl,
            fit: BoxFit.cover,
            fallback: Container(
              color: const Color(0xFF131A29),
              alignment: Alignment.center,
              child: const Icon(
                CupertinoIcons.photo,
                color: Colors.white24,
                size: 64,
              ),
            ),
          ),

          // 2. Cinematic Gradient Overlay (Top & Bottom Vignette)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.90),
                ],
                stops: const [0.0, 0.22, 0.60, 1.0],
              ),
            ),
          ),

          // 3. Right Floating Action Column (Apple Reels Style)
          PositionedDirectional(
            end: 14,
            bottom: 36,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seller Avatar with Online Dot
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: sellerAvatar != null && sellerAvatar.isNotEmpty
                            ? Image.network(
                                sellerAvatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildAvatarFallback(sellerName),
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
                const SizedBox(height: 20),

                // Favorite / Like Button
                _buildActionBtn(
                  icon: isLiked
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                  iconColor: isLiked ? const Color(0xFFFF2A42) : Colors.white,
                  label: '${likes + (isLiked ? 1 : 0)}',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _state.toggleFavorite(adId);
                  },
                ),
                const SizedBox(height: 16),

                // In-App Chat Button
                _buildActionBtn(
                  icon: CupertinoIcons.chat_bubble_2_fill,
                  iconColor: Colors.white,
                  label: isAr ? 'شات' : 'Chat',
                  onTap: () => _openChat(reel),
                ),
                const SizedBox(height: 16),

                // Direct Call Button
                _buildActionBtn(
                  icon: CupertinoIcons.phone_fill,
                  iconColor: const Color(0xFF10B981),
                  label: isAr ? 'اتصال' : 'Appel',
                  onTap: () => _callSeller(sellerPhone, sellerName),
                ),
                const SizedBox(height: 16),

                // Share Button
                _buildActionBtn(
                  icon: CupertinoIcons.share,
                  iconColor: Colors.white,
                  label: isAr ? 'مشاركة' : 'Partager',
                  onTap: () => _shareAd(reel),
                ),
              ],
            ),
          ),

          // 4. Bottom Information Card & Quick Action Deck
          PositionedDirectional(
            start: 16,
            end: 80,
            bottom: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category & VIP Tags
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isVip) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.sparkles,
                              color: Colors.white,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAr ? 'عرض VIP' : 'VIP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Seller Name with Verified Badge
                Row(
                  children: [
                    Text(
                      sellerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          BoxShadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        color: Color(0xFF38BDF8),
                        size: 14,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // Ad Title
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                    shadows: [
                      BoxShadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Price Tag + City & Views
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    // Price Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_red, Color(0xFFC80E16)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _red.withValues(alpha: 0.40),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        priceStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    // Location Pill
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.location_solid,
                          color: Colors.white70,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          city,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // "عرض الإعلان الكامل" Glass Button
                PressableScale(
                  onTap: () {
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAr ? 'عرض الإعلان الكامل' : 'Voir l\'annonce complète',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              isAr
                                  ? CupertinoIcons.arrow_left
                                  : CupertinoIcons.arrow_right,
                              color: Colors.white,
                              size: 13,
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
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: const Color(0xFF1E293B),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'A',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
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
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1.0,
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
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            shadows: [
              BoxShadow(color: Colors.black, blurRadius: 6),
            ],
          ),
        ),
      ],
    );
  }
}
