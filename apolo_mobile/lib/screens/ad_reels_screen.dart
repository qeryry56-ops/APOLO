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
import 'widgets/app_image.dart';
import 'widgets/kinetic_widgets.dart';

/// 2026 Next-Gen Apolo Reels (ريلز وسكرول الإعلانات الفاخر 🎬):
/// - Vertical Full-Screen Swipe between different Ads (TikTok / Reels Feed).
/// - Horizontal Multi-Photo Swipe Carousel inside each Ad ("بـ سكرول الصور بحال تيك توك").
/// - Natural Image Aspect Ratio ("حجم الصورة طبيعي كيف هي" بدون أي تمطيط أو اقتطاع)
///   مع خلفية سينمائية محيطية ضبابية Ambient Blur.
/// - Pinch-to-zoom interactive viewer على أي صورة.
/// - TikTok-style Photo Indicator Pill (مثلاً 1/4) ومؤشر النقاط المتفاعلة.
/// - Double-tap anywhere to trigger a bursting 3D heart animation and add to favorites.
/// - Right Action Dock: أفتار البائع مع النقطة الخضرا، زر الإعجاب، الشات، الاتصال المباشر، المشاركة.
/// - Bottom Glass Info Overlay: فئات الإعلان، الثمن بالأحمر الرسمي، شارة التفاوض، تيكر الموسيقى، وزر تفاصيل الإعلان.
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
  int _selectedFeedTab = 0; // 0: لك ✨, 1: الأحدث ⚡, 2: VIP 👑
  bool _isLoading = true;
  List<Map<String, dynamic>> _reelsAds = [];

  // Double-tap heart burst animation
  Offset? _heartBurstPosition;
  late final AnimationController _heartAnimController;

  static const Color _red = Color(0xFFE31B23);
  static const Color _ink = Color(0xFF0F172A);

  // Multi-photo rich fallback ads with high-res galleries for each item
  static const List<Map<String, dynamic>> _fallbackReelsData = [
    {
      'id': 9001,
      'title': 'Porsche Macan GTS 2025 — Pack Sport Chrono V6 Bi-Turbo',
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
      'is_vip': true,
      'images': [
        'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=1200&q=85',
        'https://images.unsplash.com/photo-1617814076367-b759c7d7e738?w=1200&q=85',
        'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?w=1200&q=85',
        'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=1200&q=85',
      ],
    },
    {
      'id': 9002,
      'title': 'iPhone 16 Pro Max 256Go Titane Naturel — Scellé avec Facture',
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
      'is_vip': false,
      'images': [
        'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=1200&q=85',
        'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=1200&q=85',
        'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=1200&q=85',
      ],
    },
    {
      'id': 9003,
      'title': 'Villa Contemporaine Neuve avec Piscine Débordante — Californie',
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
      'is_vip': true,
      'images': [
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1200&q=85',
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200&q=85',
        'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?w=1200&q=85',
        'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1200&q=85',
      ],
    },
    {
      'id': 9004,
      'title': 'Montre Rolex Submariner Date 41mm — Full Set Jamais Portée 2024',
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
      'is_vip': false,
      'images': [
        'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=1200&q=85',
        'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=1200&q=85',
        'https://images.unsplash.com/photo-1547996160-71dfabb1755a?w=1200&q=85',
      ],
    },
    {
      'id': 9005,
      'title': 'MacBook Pro 16" M3 Max 36GB / 1TB SSD — Noir Sidéral Comme Neuf',
      'price_formatted': '31 500 DH',
      'price': 31500,
      'negotiable': true,
      'category_name': 'إلكترونيات وأجهزة',
      'category_id': 5,
      'city_name': 'فاس • الأطلس',
      'views_count': 640,
      'likes_count': 142,
      'seller_name': 'أمين الفاسي',
      'seller_phone': '0665567890',
      'seller_verified': true,
      'seller_online': true,
      'is_vip': false,
      'images': [
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=1200&q=85',
        'https://images.unsplash.com/photo-1611186871348-b1ce696e52c9?w=1200&q=85',
        'https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=1200&q=85',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
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
    final int views =
        int.tryParse('${raw['views_count'] ?? raw['views'] ?? 120}') ?? 120;
    final int likes = (views * 0.16).round().clamp(12, 9999);

    // Multi-photo list normalization
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

    if (images.isEmpty) {
      images = [
        'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=1200&q=85'
      ];
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
      'main_image': images.first,
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
          content: Text(_state.s.isAr
              ? 'رقم الهاتف غير متوفر حالياً'
              : 'Numéro non disponible'),
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
            const Center(
              child: CircularProgressIndicator(color: _red, strokeWidth: 2.5),
            )
          else if (reels.isEmpty)
            Center(
              child: Text(
                isAr
                    ? 'لا توجد إعلانات في هذا القسم'
                    : 'Aucune annonce disponible',
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
                final int adId = reel['id'] as int;
                final bool isLiked = _state.favoriteAdIds.contains(adId);

                return _ReelAdItemView(
                  reel: reel,
                  isAr: isAr,
                  isLiked: isLiked,
                  onToggleFavorite: () {
                    HapticFeedback.lightImpact();
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
                );
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
                          color: Colors.black54,
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 3. Top Floating Glass Header (Back Button + Feed Filters + Reels Badge)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Back button
                    PressableScale(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ],
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

                    // Centered Feed Switcher Tabs (لك ✨ | الأحدث ⚡ | VIP 👑)
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.30),
                                blurRadius: 10,
                              ),
                            ],
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

                    // Reels 2026 glowing pill
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
}

/// Individual Reel Page View with:
/// 1. Natural Aspect Ratio Main Image ("حجم الصورة طبيعي كيف هي" بدون تقطاع).
/// 2. Ambient Blurred Background for immersive atmosphere.
/// 3. Horizontal Multi-Photo Swiping Carousel ("سكرول الصور بحال تيك توك").
/// 4. Interactive Zooming (`InteractiveViewer`).
/// 5. TikTok-Style Photo Counter Pill (`1/4`) and animated page dots.
/// 6. Floating Action Dock on the right (Avatar, Like, Chat, Phone, Share).
/// 7. Glass bottom information card + Music/Listing ticker + Full Ad CTA.
class _ReelAdItemView extends StatefulWidget {
  final Map<String, dynamic> reel;
  final bool isAr;
  final bool isLiked;
  final VoidCallback onToggleFavorite;
  final Function(Offset) onDoubleTap;
  final VoidCallback onOpenChat;
  final VoidCallback onCallSeller;
  final VoidCallback onShare;
  final VoidCallback onOpenFullAd;

  const _ReelAdItemView({
    required this.reel,
    required this.isAr,
    required this.isLiked,
    required this.onToggleFavorite,
    required this.onDoubleTap,
    required this.onOpenChat,
    required this.onCallSeller,
    required this.onShare,
    required this.onOpenFullAd,
  });

  @override
  State<_ReelAdItemView> createState() => _ReelAdItemViewState();
}

class _ReelAdItemViewState extends State<_ReelAdItemView>
    with SingleTickerProviderStateMixin {
  late final PageController _photoPageController;
  int _currentPhotoIndex = 0;
  late final AnimationController _tickerAnimController;

  static const Color _red = Color(0xFFE31B23);

  @override
  void initState() {
    super.initState();
    _photoPageController = PageController();
    _tickerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    _tickerAnimController.dispose();
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
      onDoubleTapDown: (details) => widget.onDoubleTap(details.localPosition),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Blurred Backdrop (يعطي عمق سينمائي فخم خلف الصورة الطبيعية)
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(
                  url: activePhotoUrl,
                  fit: BoxFit.cover,
                  fallback: Container(color: const Color(0xFF0F172A)),
                ),
                // Gaussian Blur Filter
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.62),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Central Multi-Photo Horizontal Carousel ("سكرول الصور بحال تيك توك")
          // مع الحفاظ على الحجم الطبيعي للصورة بنسبة 100% ("حجم الصورة طبيعي كيف هي")
          Positioned.fill(
            child: SafeArea(
              top: false,
              bottom: false,
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
                            maxHeight: MediaQuery.of(context).size.height * 0.76,
                            maxWidth: MediaQuery.of(context).size.width,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AppImage(
                              url: photoUrl,
                              // BoxFit.contain يضمن أن الصورة تبان كاملة بدون أي اقتطاع أو تمطيط!
                              fit: BoxFit.contain,
                              fallback: Container(
                                height: 320,
                                color: const Color(0xFF1E293B),
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
          ),

          // 3. Top Vignette & Subtle Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.70),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. TikTok-Style Floating Photo Counter Pill (مثلاً 1/4)
          if (images.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 54,
              right: isAr ? null : 16,
              left: isAr ? 16 : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.photo_on_rectangle,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_currentPhotoIndex + 1} / ${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. TikTok-Style Photo Pagination Dots (أسفل الصور)
          if (images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 236,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(images.length, (dotIdx) {
                      final bool active = dotIdx == _currentPhotoIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: active ? 16 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

          // 6. Right Action Dock (TikTok 2026 Style)
          PositionedDirectional(
            end: 14,
            bottom: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seller Avatar with Online Indicator & Verified Badge
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 8,
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
                const SizedBox(height: 18),

                // Favorite / Like Button
                _buildActionBtn(
                  icon: widget.isLiked
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                  iconColor:
                      widget.isLiked ? const Color(0xFFFF2A42) : Colors.white,
                  label: '${likes + (widget.isLiked ? 1 : 0)}',
                  onTap: widget.onToggleFavorite,
                ),
                const SizedBox(height: 16),

                // In-App Direct Chat Button
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

          // 7. Bottom Information Card & Quick Action Deck (2026 High UI/UX)
          PositionedDirectional(
            start: 14,
            end: 80,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category & VIP & Negotiable Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3.5,
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
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isVip)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
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
                              isAr ? 'VIP' : 'VIP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (negotiable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.50),
                          ),
                        ),
                        child: Text(
                          isAr ? 'قابل للتفاوض 🤝' : 'Négociable 🤝',
                          style: const TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 7),

                // Seller Name with Verified Blue Shield
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '@$sellerName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          BoxShadow(color: Colors.black, blurRadius: 6),
                        ],
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        color: Color(0xFF38BDF8),
                        size: 15,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),

                // Ad Title (Max 2 lines)
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    shadows: [
                      BoxShadow(color: Colors.black, blurRadius: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Price Tag + City
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    // Price Pill in Apolo Crimson
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_red, Color(0xFFC80E16)],
                        ),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: _red.withValues(alpha: 0.40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
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

                    // City Tag
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
                const SizedBox(height: 8),

                // TikTok-Style Verified Listing Sound / Audio Marquee Ticker
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _tickerAnimController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _tickerAnimController.value * 2 * math.pi,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          CupertinoIcons.music_note,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAr
                          ? 'إعلان موثوق فـ Apolo.ma ⚡ تصفح الصور بالسحب'
                          : 'Annonce vérifiée sur Apolo.ma ⚡ Balayez pour voir',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // "عرض الإعلان الكامل" Glass Button
                PressableScale(
                  onTap: widget.onOpenFullAd,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.32),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAr
                                  ? 'عرض الإعلان الكامل'
                                  : 'Voir l\'annonce complète',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              isAr
                                  ? CupertinoIcons.arrow_left
                                  : CupertinoIcons.arrow_right,
                              color: Colors.white,
                              size: 12,
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
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
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
