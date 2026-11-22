import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/state/app_state.dart';
import '../../widgets/perceived_performance.dart';
import '../ad_detail_screen.dart';
import 'app_image.dart';
import 'kinetic_widgets.dart';

/// Explore Screen full-width listing card matching the exact reference layout:
/// - Full width inside 16-20px screen margins (~342-350px on mobile), ~364-374px height
/// - Solid #FFFFFF surface, 24px border radius, soft dual drop shadow, 12px outer padding
/// - 214px rounded (18px) swipeable photo carousel with bottom-center dots indicator
/// - Top-left frosted glass category badge ("Villa") & highlight badge ("Guest favorite")
/// - Top-right 32x32 circular translucent favorite button (inside 44x44 touch target)
/// - Details panel:
///   - Row 1: Bold title ("Casa Oliva Villa") + gold star #F59E0B rating ("4.8 (126)")
///   - Row 2: Compact specs line ("Cascais, 14 km · 3 bedrooms · Pool")
///   - Subtle 1px divider
///   - Bottom row: Seller circular avatar + name (+ verified badge) on left +
///     Bold total price ("$933 total") & nightly subtitle ("$233 / night · taxes incl.") on right
class ExploreListingCard extends StatefulWidget {
  final Map<String, dynamic> ad;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onFavoriteChanged;

  const ExploreListingCard({
    super.key,
    required this.ad,
    this.onTap,
    this.onFavoriteChanged,
  });

  @override
  State<ExploreListingCard> createState() => _ExploreListingCardState();
}

class _ExploreListingCardState extends State<ExploreListingCard>
    with SingleTickerProviderStateMixin {
  final AppState _state = AppState();
  final PageController _pageController = PageController();
  int _activePage = 0;
  bool? _localFavoriteOverride;
  bool _isFavPressed = false;
  late final AnimationController _heartBounceCtrl;
  late final Animation<double> _heartBounceScale;

  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _verifiedBlue = Color(0xFF1D9BF0);
  static const Color _starAmber = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    // Rule 3: 260ms ease-out heart bounce (cubic-bezier(0.22, 1, 0.36, 1))
    _heartBounceCtrl = AnimationController(
      vsync: this,
      duration: ApoloMotion.bounceDuration,
    );
    _heartBounceScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.26)
            .chain(CurveTween(curve: ApoloMotion.easeOutCurve)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.26, end: 1.0)
            .chain(CurveTween(curve: ApoloMotion.easeOutCurve)),
        weight: 45,
      ),
    ]).animate(_heartBounceCtrl);
  }

  @override
  void dispose() {
    _heartBounceCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  int get _adId {
    final raw = widget.ad['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  bool get _isFavorited {
    if (_localFavoriteOverride != null) {
      return _localFavoriteOverride!;
    }
    if (_adId > 0 && _state.favoriteAdIds.contains(_adId)) {
      return true;
    }
    return widget.ad['is_favorite'] == true || widget.ad['isFavorite'] == true;
  }

  Future<void> _handleFavoriteTap() async {
    // Rule 2 (Show Result First) & Rule 3 (Move with Ease):
    // Optimistically fill heart & trigger ease-out bounce immediately before background sync.
    final nextState = !_isFavorited;
    setState(() {
      _localFavoriteOverride = nextState;
    });
    _heartBounceCtrl.forward(from: 0.0);
    widget.onFavoriteChanged?.call(nextState);

    if (_adId > 0 && _state.isLoggedIn) {
      final result = await _state.toggleFavorite(
        _adId,
        categoryId: _state.extractAdCategoryId(widget.ad),
      );
      if (mounted) {
        setState(() {
          _localFavoriteOverride = result;
        });
      }
    }
  }

  void _handleCardTap() {
    HapticFeedback.selectionClick();
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    final catId = _state.extractAdCategoryId(widget.ad);
    if (catId != null) {
      _state.recordCategoryInterest(catId, weight: 2);
    }
    // Rule 3: Use 450ms spring/ease-out transition instead of linear slide
    Navigator.push(
      context,
      SpringPageRoute(
        page: AdDetailScreen(
          adId: _adId,
          initialAd: widget.ad,
        ),
      ),
    );
  }

  List<String> _resolveImages() {
    final ad = widget.ad;
    final urls = <String>[];

    void addUrl(dynamic candidate) {
      final s = (candidate ?? '').toString().trim();
      if (s.isNotEmpty && !urls.contains(s)) {
        urls.add(s);
      }
    }

    addUrl(ad['main_image']);
    addUrl(ad['primary_image']);
    addUrl(ad['image_url']);
    addUrl(ad['image']);

    for (final key in ['gallery', 'images']) {
      final list = ad[key];
      if (list is List) {
        for (final item in list) {
          if (item is String) {
            addUrl(item);
          } else if (item is Map) {
            addUrl(item['image_url'] ?? item['url'] ?? item['path']);
          }
        }
      }
    }

    return urls;
  }

  String _resolveCategoryAsset() {
    final ad = widget.ad;
    final catMap = ad['category'] is Map
        ? Map<String, dynamic>.from(ad['category'] as Map)
        : null;
    final catLabel = (ad['category_name'] ??
            ad['category_ar'] ??
            ad['badge_label'] ??
            catMap?['name_fr'] ??
            catMap?['name'] ??
            catMap?['name_ar'] ??
            '')
        .toString();
    return _state.assetForCategory(catMap, catLabel);
  }

  String _resolveTypeBadge() {
    final ad = widget.ad;
    final explicit =
        (ad['badge_label'] ?? ad['property_type'] ?? ad['type_label'] ?? '')
            .toString()
            .trim();
    if (explicit.isNotEmpty) return explicit;

    if (ad['category'] is Map) {
      final catMap = Map<String, dynamic>.from(ad['category'] as Map);
      final formatted = _state.formatCategoryLabel(catMap).trim();
      if (formatted.isNotEmpty) return formatted;
      final rawName =
          (catMap['name'] ?? catMap['name_fr'] ?? catMap['name_ar'] ?? '')
              .toString()
              .trim();
      if (rawName.isNotEmpty) return rawName;
    }

    final catName =
        (ad['category_name'] ?? ad['category_ar'] ?? '').toString().trim();
    if (catName.isNotEmpty) return catName;

    return 'Villa';
  }

  String? _resolveHighlightBadge() {
    final ad = widget.ad;
    if (ad['is_guest_favorite'] == false || ad['hide_guest_favorite'] == true) {
      return null;
    }
    final explicit =
        (ad['highlight_label'] ?? ad['guest_favorite_label'] ?? '')
            .toString()
            .trim();
    if (explicit.isNotEmpty) return explicit;

    final isFeatured = ad['is_guest_favorite'] == true ||
        ad['is_vip'] == true ||
        ad['is_featured'] == true ||
        ad['is_highlighted'] == true;
    final views =
        int.tryParse((ad['views_count'] ?? ad['views'] ?? 0).toString()) ?? 0;

    if (isFeatured || views >= 100) {
      return _state.s.tr('موصى به', 'Coup de cœur', 'Guest favorite');
    }
    return null;
  }

  String _resolveTitle() {
    final title = (widget.ad['title'] ?? widget.ad['name'] ?? '')
        .toString()
        .trim();
    return title.isNotEmpty ? title : 'Casa Oliva Villa';
  }

  String _resolveRating() {
    final raw = widget.ad['rating'] ?? widget.ad['stars'] ?? widget.ad['score'];
    if (raw != null && raw.toString().trim().isNotEmpty) {
      return raw.toString().trim();
    }
    return '4.8';
  }

  String _resolveReviewsCount() {
    final raw = widget.ad['reviews_count'] ?? widget.ad['review_count'];
    if (raw != null && raw.toString().trim().isNotEmpty) {
      final cleaned = raw.toString().trim().replaceAll(RegExp(r'[()]'), '');
      return '($cleaned)';
    }
    final views = int.tryParse(
            (widget.ad['views_count'] ?? widget.ad['views'] ?? '').toString()) ??
        0;
    if (views > 0) return '($views)';
    return '(126)';
  }

  String _resolveCity() {
    final ad = widget.ad;
    final explicit = (ad['location_display'] ?? ad['location'] ?? '')
        .toString()
        .trim();
    if (explicit.isNotEmpty) return explicit;

    if (ad['city'] is Map) {
      final city = ad['city'] as Map;
      final name = (_state.s.isAr
              ? (city['name_ar'] ?? city['name'] ?? city['name_fr'])
              : (city['name_fr'] ?? city['name'] ?? city['name_ar']))
          .toString()
          .trim();
      if (name.isNotEmpty) return name;
    }

    final flat = (_state.s.isAr
            ? (ad['city_ar'] ?? ad['city_name'] ?? ad['city_fr'])
            : (ad['city_fr'] ?? ad['city_name'] ?? ad['city_ar']))
        .toString()
        .trim();
    return flat;
  }

  String _resolveSpecsLine(String typeBadge) {
    final ad = widget.ad;
    final explicit = (ad['specs_display'] ?? ad['specs'] ?? '')
        .toString()
        .trim();
    if (explicit.isNotEmpty) return explicit;

    final parts = <String>[];
    final city = _resolveCity();
    final distance = (ad['distance_km'] ?? '').toString().trim();
    if (city.isNotEmpty) {
      parts.add(distance.isNotEmpty ? '$city, $distance km' : city);
    }

    final bedrooms = (ad['bedrooms'] ?? '').toString().trim();
    if (bedrooms.isNotEmpty) {
      parts.add('$bedrooms bedrooms');
    } else if (ad['surface'] != null &&
        ad['surface'].toString().trim().isNotEmpty) {
      parts.add('${ad['surface']} m²');
    } else if (typeBadge.isNotEmpty) {
      parts.add(typeBadge);
    }

    final amenity = (ad['amenity'] ?? ad['amenities_summary'] ?? '')
        .toString()
        .trim();
    if (amenity.isNotEmpty) {
      parts.add(amenity);
    } else {
      final desc = (ad['description'] ?? '').toString().trim();
      if (desc.isNotEmpty && parts.length < 3) {
        final compactDesc = desc.replaceAll(RegExp(r'\s+'), ' ');
        parts.add(
          compactDesc.length > 26
              ? '${compactDesc.substring(0, 26)}...'
              : compactDesc,
        );
      }
    }

    if (parts.isEmpty) {
      return 'Cascais, 14 km · 3 bedrooms · Pool';
    }
    return parts.join(' · ');
  }

  String _resolveSellerName() {
    final ad = widget.ad;
    final userMap = ad['user'] is Map
        ? Map<String, dynamic>.from(ad['user'] as Map)
        : null;
    final sellerMap = ad['seller'] is Map
        ? Map<String, dynamic>.from(ad['seller'] as Map)
        : null;
    final storeMap = ad['store'] is Map
        ? Map<String, dynamic>.from(ad['store'] as Map)
        : null;

    final candidates = [
      ad['seller_name'],
      ad['host_name'],
      userMap?['name'],
      userMap?['full_name'],
      sellerMap?['name'],
      storeMap?['name'],
    ];

    for (final c in candidates) {
      final s = (c ?? '').toString().trim();
      if (s.isNotEmpty) return s;
    }

    return _state.s.tr('معلن', 'Vendeur', 'Seller');
  }

  String _resolveSellerAvatar() {
    final ad = widget.ad;
    final userMap = ad['user'] is Map
        ? Map<String, dynamic>.from(ad['user'] as Map)
        : null;
    final sellerMap = ad['seller'] is Map
        ? Map<String, dynamic>.from(ad['seller'] as Map)
        : null;
    final storeMap = ad['store'] is Map
        ? Map<String, dynamic>.from(ad['store'] as Map)
        : null;

    final candidates = [
      ad['seller_avatar'],
      ad['host_avatar'],
      userMap?['avatar'],
      userMap?['avatar_url'],
      sellerMap?['avatar'],
      sellerMap?['avatar_url'],
      storeMap?['logo_url'],
      storeMap?['logo'],
    ];

    for (final c in candidates) {
      final s = (c ?? '').toString().trim();
      if (s.isNotEmpty) return s;
    }

    return '';
  }

  bool _isSellerVerified() {
    final ad = widget.ad;
    final userMap = ad['user'] is Map ? ad['user'] as Map : null;
    final sellerMap = ad['seller'] is Map ? ad['seller'] as Map : null;
    return ad['seller_verified'] == true ||
        ad['is_verified'] == true ||
        ad['verified'] == true ||
        userMap?['is_verified'] == true ||
        sellerMap?['is_verified'] == true;
  }

  Widget _buildSellerAvatar(String avatarUrl, String sellerName) {
    final initial = sellerName.trim().isNotEmpty
        ? sellerName.trim().substring(0, 1).toUpperCase()
        : 'A';

    Widget fallbackAvatar() {
      return Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (avatarUrl.isEmpty) {
      return fallbackAvatar();
    }

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF1F5F9),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl.startsWith('assets/')
          ? Image.asset(
              avatarUrl,
              fit: BoxFit.cover,
              width: 34,
              height: 34,
              errorBuilder: (_, __, ___) => fallbackAvatar(),
            )
          : AppImage(
              url: avatarUrl,
              fit: BoxFit.cover,
              width: 34,
              height: 34,
              fallback: fallbackAvatar(),
            ),
    );
  }

  ({String mainAmount, String unitSuffix, String subLine}) _resolvePricing() {
    final ad = widget.ad;
    final explicitTotal = (ad['total_price_display'] ?? '').toString().trim();
    final explicitNightly = (ad['nightly_price_display'] ?? '')
        .toString()
        .trim();

    if (explicitTotal.isNotEmpty) {
      final unit = (ad['total_unit_label'] ?? 'total').toString().trim();
      return (
        mainAmount: explicitTotal,
        unitSuffix: unit,
        subLine: explicitNightly.isNotEmpty
            ? explicitNightly
            : 'taxes incl.',
      );
    }

    final priceFormatted = (ad['price_formatted'] ?? '').toString().trim();
    if (priceFormatted.isNotEmpty) {
      return (
        mainAmount: priceFormatted,
        unitSuffix: '',
        subLine: explicitNightly.isNotEmpty
            ? explicitNightly
            : _state.s.tr('شامل الضرائب', 'Taxes & frais inclus',
                'Taxes incl.'),
      );
    }

    final rawPrice = ad['price'];
    final numericPrice = double.tryParse((rawPrice ?? '').toString());
    if (numericPrice != null && numericPrice > 0) {
      final intVal = numericPrice.round();
      final currency = (ad['currency_symbol'] ?? 'DH').toString().trim();
      final formatted = currency == '\$' ? '\$$intVal' : '$intVal $currency';
      return (
        mainAmount: formatted,
        unitSuffix: '',
        subLine: explicitNightly.isNotEmpty
            ? explicitNightly
            : _state.s.tr('شامل الضرائب', 'Taxes & frais inclus',
                'Taxes incl.'),
      );
    }

    return (
      mainAmount: _state.s.tr('عند الطلب', 'Sur demande', 'On request'),
      unitSuffix: '',
      subLine: _state.s.tr('تواصل مع المعلن', 'Contacter le vendeur',
          'Contact host'),
    );
  }

  Widget _buildMediaSlide(String src) {
    if (src.startsWith('assets/')) {
      final isCategoryCutout = src.contains('/cat_');
      if (isCategoryCutout) {
        return _buildFallbackBackdrop(assetOverride: src);
      }
      return Image.asset(
        src,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildFallbackBackdrop(),
      );
    }
    return AppImage(
      url: src,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      fallback: _buildFallbackBackdrop(),
    );
  }

  Widget _buildFallbackBackdrop({String? assetOverride}) {
    final assetPath = assetOverride ?? _resolveCategoryAsset();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF1F5F9),
            Color(0xFFE2E8F0),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        width: 132,
        height: 132,
        errorBuilder: (_, __, ___) => const Icon(
          CupertinoIcons.photo,
          color: Color(0xFF94A3B8),
          size: 42,
        ),
      ),
    );
  }

  Widget _buildTypePill(String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightPill(String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.90),
              width: 0.6,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _resolveImages();
    final typeBadge = _resolveTypeBadge();
    final highlightBadge = _resolveHighlightBadge();
    final title = _resolveTitle();
    final rating = _resolveRating();
    final reviewsCount = _resolveReviewsCount();
    final specsLine = _resolveSpecsLine(typeBadge);
    final sellerName = _resolveSellerName();
    final sellerAvatar = _resolveSellerAvatar();
    final isSellerVerified = _isSellerVerified();
    final pricing = _resolvePricing();
    final isFav = _isFavorited;
    final int dotCount = images.length > 1 ? images.length.clamp(2, 6) : 5;
    final int activeDotIndex = _activePage.clamp(0, dotCount - 1);

    return PressableScale(
      onTap: _handleCardTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Media Section (218px height, 18px rounded corners)
            SizedBox(
              height: 218,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Swipeable Image Carousel
                    if (images.length > 1)
                      PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: images.length,
                        onPageChanged: (idx) =>
                            setState(() => _activePage = idx),
                        itemBuilder: (_, idx) => _buildMediaSlide(images[idx]),
                      )
                    else if (images.length == 1)
                      _buildMediaSlide(images.first)
                    else
                      _buildFallbackBackdrop(),

                    // Subtle bottom gradient for crisp dot contrast over water/bright photos
                    if (images.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 44,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Top-start Floating Pill Badges
                    PositionedDirectional(
                      top: 12,
                      start: 12,
                      end: 56,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: _buildTypePill(typeBadge)),
                          if (highlightBadge != null) ...[
                            const SizedBox(width: 7),
                            Flexible(
                              child: _buildHighlightPill(highlightBadge),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Top-end 32x32 Favorite Button inside 44x44 HIG touch target
                    // Rule 1 (React at Once): 95% scale + 0.82 opacity + haptic on touch down (<16ms)
                    // Rule 2 & 3: Instant heart fill + 260ms ease-out bounce animation
                    PositionedDirectional(
                      top: 6,
                      end: 6,
                      child: Semantics(
                        button: true,
                        label: 'Favorite listing',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (_) {
                            HapticFeedback.lightImpact();
                            setState(() => _isFavPressed = true);
                          },
                          onTapUp: (_) {
                            setState(() => _isFavPressed = false);
                            _handleFavoriteTap();
                          },
                          onTapCancel: () {
                            if (_isFavPressed) {
                              setState(() => _isFavPressed = false);
                            }
                          },
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: AnimatedScale(
                                scale: _isFavPressed
                                    ? ApoloMotion.pressedScale
                                    : 1.0,
                                duration: ApoloMotion.microDuration,
                                curve: ApoloMotion.easeOutCurve,
                                child: AnimatedOpacity(
                                  opacity: _isFavPressed
                                      ? ApoloMotion.pressedOpacity
                                      : 1.0,
                                  duration: ApoloMotion.microDuration,
                                  curve: ApoloMotion.easeOutCurve,
                                  child: ClipOval(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 8,
                                        sigmaY: 8,
                                      ),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.25),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.25),
                                            width: 0.7,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: ScaleTransition(
                                          scale: _heartBounceScale,
                                          child: Icon(
                                            isFav
                                                ? CupertinoIcons.heart_fill
                                                : CupertinoIcons.heart,
                                            size: 16.5,
                                            color: isFav
                                                ? const Color(0xFFFF3B5C)
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom-center Carousel Dots Indicator
                    if (images.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 12,
                        child: IgnorePointer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(dotCount, (idx) {
                              final active = idx == activeDotIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2.5),
                                width: active ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: active
                                      ? Colors.white.withValues(alpha: 0.90)
                                      : Colors.white.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 2. Content & Details Section
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 16, 6, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Property Title + Rating (★ 4.8 (126))
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.25,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: _starAmber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            reviewsCount,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Row 2: Specs Line
                  Text(
                    specsLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),

                  // Subtle Separator
                  const SizedBox(height: 12),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                  const SizedBox(height: 12),

                  // Bottom Row: Seller Profile (Avatar + Name + Verified) on Start + Pricing on End
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final maxRightWidth =
                          (constraints.maxWidth * 0.56).clamp(110.0, 220.0);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _buildSellerAvatar(sellerAvatar, sellerName),
                                const SizedBox(width: 9),
                                Flexible(
                                  child: Text(
                                    sellerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _ink,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ),
                                if (isSellerVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: _verifiedBlue,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: maxRightWidth),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: RichText(
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: pricing.mainAmount,
                                          style: const TextStyle(
                                            color: _ink,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.2,
                                            fontFeatures: [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                        if (pricing.unitSuffix.isNotEmpty)
                                          TextSpan(
                                            text: ' ${pricing.unitSuffix}',
                                            style: const TextStyle(
                                              color: _ink,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pricing.subLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
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
