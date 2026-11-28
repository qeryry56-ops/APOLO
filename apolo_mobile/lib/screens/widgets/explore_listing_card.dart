import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../../core/state/app_state.dart';
import '../../widgets/apolo_badges_kit.dart';
import '../../widgets/perceived_performance.dart';
import '../ad_detail_screen.dart';
import 'app_image.dart';
import 'kinetic_widgets.dart';
import '../../widgets/dl_settings_kit.dart';
import '../../l10n/l10n.dart';

/// Dynamic Layer v5.1 Explore Screen full-width listing card:
/// - Full width inside 20px screen margins (~350px on 390px mobile), ~370px height
/// - Crisp #FFFFFF surface with 1px #EEEEEE border (zero muddy drop shadow), 24px radius
/// - 218px rounded (18px) swipeable photo carousel with #F6F6F6 placeholder & pill dots
/// - Top-start frosted category badge & #FFFFFF highlight pill
/// - Top-end 34x34 circular favorite button (#FF3B30 heart bounce) inside 44x44 target
/// - Clean details panel:
///   - Row 1: Bold #000000 title + #FFB800 star rating + #757575 count
///   - Row 2: #757575 specs line
///   - 1px #EEEEEE hairline divider
///   - Bottom row: 34x34 #EEEEEE seller avatar + #000000 name + ApoloVerifiedBadge + ApoloRankBadge
///     on start, bold #000000 tabular price + #757575 subtitle on end
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

  // Dynamic Layer v5.1 Palette
  Color get _dlBg => ApoloDlPalette.of(context).bg;
  Color get _dlSurface => ApoloDlPalette.of(context).surfaceSubtle;
  Color get _dlPill => ApoloDlPalette.of(context).pill;
  Color get _dlSeparator => ApoloDlPalette.of(context).separator;
  Color get _dlInk => ApoloDlPalette.of(context).ink;
  Color get _dlMuted => ApoloDlPalette.of(context).muted;
  static const Color _dlHeartRed = Color(0xFFFF3B30);
  static const Color _dlStarAmber = Color(0xFFFFB800);

  @override
  void initState() {
    super.initState();
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
      return _state.s.tr('موصى به', 'Coup de cœur', appL10n.guestFavoriteBadge);
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
          (widget.ad['views_count'] ?? widget.ad['views'] ?? '').toString(),
        ) ??
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
              : (_state.s.isFr
                  ? (city['name_fr'] ?? city['name'] ?? city['name_ar'])
                  : (city['name_en'] ??
                      city['name_fr'] ??
                      city['name'] ??
                      city['name_ar'])))
          .toString()
          .trim();
      if (name.isNotEmpty) return name;
    }

    final flat = (_state.s.isAr
            ? (ad['city_ar'] ?? ad['city_name'] ?? ad['city_fr'])
            : (_state.s.isFr
                ? (ad['city_fr'] ?? ad['city_name'] ?? ad['city_ar'])
                : (ad['city_en'] ??
                    ad['city_fr'] ??
                    ad['city_name'] ??
                    ad['city_ar'])))
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
      parts.add(appL10n.listingBedroomsCount(bedrooms));
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

    return _state.s.tr('معلن', 'Vendeur', appL10n.adDetailSeller);
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
    if (!AppConfig.enablePremiumAndBusinessTiers) return false;
    final ad = widget.ad;
    final userMap = ad['user'] is Map ? ad['user'] as Map : null;
    final sellerMap = ad['seller'] is Map ? ad['seller'] as Map : null;
    final storeMap = ad['store'] is Map ? ad['store'] as Map : null;
    return ad['is_pro_plus'] == true ||
        ad['seller_is_pro_plus'] == true ||
        userMap?['is_pro_plus'] == true ||
        sellerMap?['is_pro_plus'] == true ||
        storeMap?['is_pro_plus'] == true;
  }

  Widget _buildSellerAvatar(String avatarUrl, String sellerName) {
    final initial = sellerName.trim().isNotEmpty
        ? sellerName.trim().substring(0, 1).toUpperCase()
        : 'A';

    Widget fallbackAvatar() {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _dlPill,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            color: _dlInk,
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
        color: _dlPill,
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
            : appL10n.listingTaxesIncluded,
      );
    }

    final priceFormatted = (ad['price_formatted'] ?? '').toString().trim();
    final isNeg = ad['negotiable'] == true || ad['is_negotiable'] == true;
    final defaultSub = explicitNightly.isNotEmpty
        ? explicitNightly
        : (isNeg
            ? _state.s.tr('قابل للتفاوض', 'Négociable', appL10n.negotiableBadge)
            : _state.s.tr('السعر المعلن', 'Prix affiché', appL10n.fixedPriceBadge));

    if (priceFormatted.isNotEmpty) {
      return (
        mainAmount: priceFormatted,
        unitSuffix: '',
        subLine: defaultSub,
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
        subLine: defaultSub,
      );
    }

    return (
      mainAmount: _state.s.tr('عند الطلب', 'Sur demande', appL10n.adDetailOnRequest),
      unitSuffix: '',
      subLine: _state.s.tr(
        'تواصل مع المعلن',
        'Contacter le vendeur',
        appL10n.exploreListingCardContactSeller,
      ),
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
      color: _dlSurface,
      alignment: Alignment.center,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        width: 132,
        height: 132,
        errorBuilder: (_, __, ___) => Icon(
          CupertinoIcons.photo,
          color: _dlMuted,
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
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
      decoration: BoxDecoration(
        color: _dlBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _dlInk,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.15,
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
    final isBusinessSeller = ApoloAccountTypeBadge.isAdFromBusiness(widget.ad);
    final pricing = _resolvePricing();
    final isFav = _isFavorited;
    final int dotCount = images.length > 1 ? images.length.clamp(2, 6) : 5;
    final int activeDotIndex = _activePage.clamp(0, dotCount - 1);

    return PressableScale(
      onTap: _handleCardTap,
      child: Container(
        key: Key('dl-explore-card-$_adId'),
        decoration: BoxDecoration(
          color: _dlBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _dlSeparator, width: 1),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Media Carousel (218px height, 18px rounded corners)
            SizedBox(
              height: 218,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
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
                            const SizedBox(width: 6),
                            Flexible(
                              child: _buildHighlightPill(highlightBadge),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Top-end 34x34 Favorite Button inside 44x44 touch target
                    PositionedDirectional(
                      top: 6,
                      end: 6,
                      child: Semantics(
                        button: true,
                        label: context.l10n.listingFavoriteTooltip,
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
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: isFav
                                          ? _dlBg
                                          : Colors.black.withValues(alpha: 0.36),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: ScaleTransition(
                                      scale: _heartBounceScale,
                                      child: Icon(
                                        isFav
                                            ? CupertinoIcons.heart_fill
                                            : CupertinoIcons.heart,
                                        size: 17,
                                        color: isFav
                                            ? _dlHeartRed
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
                                      ? Colors.white
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
              padding: const EdgeInsets.fromLTRB(6, 15, 6, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Title + Star Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _dlInk,
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
                            color: _dlStarAmber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: TextStyle(
                              color: _dlInk,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            reviewsCount,
                            style: TextStyle(
                              color: _dlMuted,
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
                    style: TextStyle(
                      color: _dlMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),

                  // 1px Dynamic Layer Hairline Separator
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: _dlSeparator,
                  ),
                  const SizedBox(height: 12),

                  // Bottom Row: Seller Profile (Avatar + Name + ApoloVerifiedBadge + ApoloRankBadge) + Pricing
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
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              sellerName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: _dlInk,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: -0.1,
                                                height: 1.15,
                                              ),
                                            ),
                                          ),
                                          if (isSellerVerified) ...[
                                            const SizedBox(width: 4),
                                            const ApoloVerifiedBadge(size: 14),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      ApoloAccountTypeBadge(
                                        isBusiness: isBusinessSeller,
                                        compact: true,
                                      ),
                                    ],
                                  ),
                                ),
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
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: RichText(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: pricing.mainAmount,
                                            style: TextStyle(
                                              color: _dlInk,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.2,
                                              fontFeatures: [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                          if (pricing.unitSuffix.isNotEmpty)
                                            TextSpan(
                                              text: ' ${pricing.unitSuffix}',
                                              style: TextStyle(
                                                color: _dlMuted,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pricing.subLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _dlMuted,
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
