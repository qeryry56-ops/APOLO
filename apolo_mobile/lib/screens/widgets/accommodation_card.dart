import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/state/app_state.dart';
import '../ad_detail_screen.dart';
import 'app_image.dart';
import 'kinetic_widgets.dart';

/// Exact UI reproduction of the Accommodation Listing Card for the Home Screen
/// "Nearby stays" horizontal carousel.
///
/// Proportions & visual hierarchy:
/// - 0.84:1 portrait aspect ratio (width : height)
/// - 24px rounded corners with edge-to-edge BoxFit.cover image
/// - Top-left translucent glass pills: Category badge (e.g. "Cabin") + Rating badge ("★ 4.9")
/// - Top-right circular translucent favorite button (44x44pt hit target) with white heart toggle
/// - Overlapping bottom off-white rounded info panel:
///   - Row 1: Property name on left ("Lakeside Cabin") + Price on right ("$148 /night")
///   - Row 2: Location pin + Location text ("Sintra, Portugal") + "|" separator + "$651 total · 4 nights"
class AccommodationCard extends StatefulWidget {
  final Map<String, dynamic> ad;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onFavoriteChanged;

  const AccommodationCard({
    super.key,
    required this.ad,
    this.onTap,
    this.onFavoriteChanged,
  });

  @override
  State<AccommodationCard> createState() => _AccommodationCardState();
}

class _AccommodationCardState extends State<AccommodationCard> {
  final AppState _state = AppState();
  bool? _localFavoriteOverride;

  int get _adId {
    final raw = widget.ad['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  bool get _isFavorited {
    if (_localFavoriteOverride != null) {
      return _localFavoriteOverride!;
    }
    if (_adId != 0 && _state.favoriteAdIds.contains(_adId)) {
      return true;
    }
    return widget.ad['is_favorite'] == true || widget.ad['isFavorite'] == true;
  }

  Future<void> _handleFavoriteTap() async {
    HapticFeedback.lightImpact();
    final nextState = !_isFavorited;
    setState(() {
      _localFavoriteOverride = nextState;
    });
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
      MaterialPageRoute(
        builder: (_) => AdDetailScreen(
          adId: _adId,
          initialAd: widget.ad,
        ),
      ),
    );
  }

  String _resolveImageUrl() {
    final ad = widget.ad;
    final direct = (ad['main_image'] ??
            ad['primary_image'] ??
            ad['image_url'] ??
            ad['image'] ??
            '')
        .toString()
        .trim();
    if (direct.isNotEmpty) return direct;

    final imgs = ad['images'];
    if (imgs is List && imgs.isNotEmpty) {
      final first = imgs.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
      if (first is Map) {
        final url = (first['image_url'] ?? first['url'] ?? first['path'] ?? '')
            .toString()
            .trim();
        if (url.isNotEmpty) return url;
      }
    }
    return _resolveCategoryAsset();
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

  String _resolveBadgeLabel() {
    final ad = widget.ad;
    final explicitBadge =
        (ad['badge_label'] ?? ad['property_type'] ?? ad['type_label'] ?? '')
            .toString()
            .trim();
    if (explicitBadge.isNotEmpty) return explicitBadge;

    if (ad['category'] is Map) {
      final catMap = Map<String, dynamic>.from(ad['category'] as Map);
      final formatted = _state.formatCategoryLabel(catMap).trim();
      if (formatted.isNotEmpty) return formatted;
      final name = (catMap['name'] ??
              catMap['name_en'] ??
              catMap['name_fr'] ??
              catMap['name_ar'] ??
              '')
          .toString()
          .trim();
      if (name.isNotEmpty) return name;
    }

    final catStr = (ad['category_name'] ?? '').toString().trim();
    if (catStr.isNotEmpty) return catStr;

    return 'Cabin';
  }

  String _resolveRating() {
    final ad = widget.ad;
    final raw = ad['rating'] ?? ad['stars'] ?? ad['score'];
    if (raw != null && raw.toString().trim().isNotEmpty) {
      return raw.toString().trim();
    }
    return '4.9';
  }

  String _resolveTitle() {
    final ad = widget.ad;
    final title = (ad['title'] ?? ad['name'] ?? '').toString().trim();
    if (title.isNotEmpty) return title;
    return 'Lakeside Cabin';
  }

  bool get _hasStayMetadata {
    final ad = widget.ad;
    return ad.containsKey('nightly_price_display') ||
        ad.containsKey('price_display') ||
        ad.containsKey('price_unit') ||
        ad.containsKey('nights') ||
        ad.containsKey('total_summary') ||
        ad.containsKey('stay_summary');
  }

  String _resolveNightlyPrice() {
    final ad = widget.ad;
    final explicitNightly =
        (ad['nightly_price_display'] ?? ad['price_display'] ?? '')
            .toString()
            .trim();
    if (explicitNightly.isNotEmpty) return explicitNightly;

    final priceFormatted = (ad['price_formatted'] ?? '').toString().trim();
    if (priceFormatted.isNotEmpty) return priceFormatted;

    if (ad['is_free'] == true) {
      return _state.s.tr('مجاني', 'Gratuit', 'Free');
    }

    final rawPrice = ad['price'];
    if (rawPrice != null) {
      final numVal = double.tryParse(rawPrice.toString());
      if (numVal != null && numVal > 0) {
        final intVal = numVal.round();
        final currency =
            (ad['currency_symbol'] ?? (_hasStayMetadata ? '\$' : 'DH'))
                .toString()
                .trim();
        return currency == '\$' ? '\$$intVal' : '$intVal $currency';
      }
    }
    return _hasStayMetadata
        ? '\$148'
        : _state.s.tr('عند الطلب', 'Sur demande', 'On request');
  }

  String _resolvePriceUnit() {
    final ad = widget.ad;
    final unit = (ad['price_unit'] ?? '').toString().trim();
    if (unit.isNotEmpty) return unit;
    return _hasStayMetadata ? '/night' : '';
  }

  String _resolveLocation() {
    final ad = widget.ad;
    final explicitLoc = (ad['location_display'] ?? ad['location'] ?? '')
        .toString()
        .trim();
    if (explicitLoc.isNotEmpty) return explicitLoc;

    if (ad['city'] is Map) {
      final cityMap = ad['city'] as Map;
      final cityName = (_state.s.isAr
              ? (cityMap['name_ar'] ?? cityMap['name'] ?? cityMap['name_fr'])
              : (cityMap['name_fr'] ?? cityMap['name'] ?? cityMap['name_ar']))
          .toString()
          .trim();
      if (cityName.isNotEmpty) return cityName;
    }

    final cityStr = (_state.s.isAr
            ? (ad['city_ar'] ?? ad['city_name'] ?? ad['city_fr'])
            : (ad['city_fr'] ?? ad['city_name'] ?? ad['city_ar']))
        .toString()
        .trim();
    if (cityStr.isNotEmpty) return cityStr;

    return _state.s.tr('المغرب', 'Maroc', 'Sintra, Portugal');
  }

  String _resolveTotalSummary() {
    final ad = widget.ad;
    final explicitSummary =
        (ad['total_summary'] ?? ad['stay_summary'] ?? '').toString().trim();
    if (explicitSummary.isNotEmpty) return explicitSummary;

    if (_hasStayMetadata) {
      final rawPrice = ad['price'];
      if (rawPrice != null) {
        final numVal = double.tryParse(rawPrice.toString());
        if (numVal != null && numVal > 0) {
          final nights = int.tryParse((ad['nights'] ?? 4).toString()) ?? 4;
          final total = (numVal * nights).round();
          final currency = (ad['currency_symbol'] ?? '\$').toString();
          final formattedTotal =
              currency == '\$' ? '\$$total' : '$total $currency';
          return '$formattedTotal total · $nights nights';
        }
      }
      return '\$651 total · 4 nights';
    }

    if (ad['is_negotiable'] == true || ad['negotiable'] == true) {
      return _state.s.tr('قابل للتفاوض', 'Négociable', 'Negotiable');
    }
    final views =
        int.tryParse((ad['views_count'] ?? ad['views'] ?? '').toString()) ?? 0;
    if (views > 0) {
      return '$views ${_state.s.tr('مشاهدة', 'vues', 'views')}';
    }
    return _state.s.tr('عرض حصري', 'Offre exclusive', 'Exclusive deal');
  }

  Widget _buildBackgroundImage(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      if (imageUrl.contains('/cat_')) {
        return _buildFallbackPhoto(assetOverride: imageUrl);
      }
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildFallbackPhoto(),
      );
    }
    return AppImage(
      url: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      fallback: _buildFallbackPhoto(),
    );
  }

  Widget _buildFallbackPhoto({String? assetOverride}) {
    final assetPath = assetOverride ?? _resolveCategoryAsset();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF1F5F9),
            Color(0xFFE2E8F0),
          ],
        ),
      ),
      alignment: const Alignment(0, -0.25),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        width: 156,
        height: 156,
        errorBuilder: (_, __, ___) => const Icon(
          CupertinoIcons.photo,
          color: Color(0xFF94A3B8),
          size: 48,
        ),
      ),
    );
  }

  Widget _buildGlassPill({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 0.8,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl();
    final badgeLabel = _resolveBadgeLabel();
    final rating = _resolveRating();
    final title = _resolveTitle();
    final nightlyPrice = _resolveNightlyPrice();
    final priceUnit = _resolvePriceUnit();
    final location = _resolveLocation();
    final totalSummary = _resolveTotalSummary();
    final isFav = _isFavorited;

    return AspectRatio(
      aspectRatio: 0.84,
      child: PressableScale(
        onTap: _handleCardTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Main Edge-to-Edge Accommodation Photo (object-fit: cover)
                Positioned.fill(
                  child: _buildBackgroundImage(imageUrl),
                ),

                // Subtle top vignette for badge legibility over bright skies
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 84,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.16),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Top Overlay Elements (Category badge + Rating badge on start, Heart button on end)
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top-start badges
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: _buildGlassPill(
                                child: Text(
                                  badgeLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildGlassPill(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.1,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Top-end circular translucent favorite button (44x44pt touch target)
                      Semantics(
                        button: true,
                        label: 'Favorite accommodation',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _handleFavoriteTap,
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.24),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    width: 0.8,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  isFav
                                      ? CupertinoIcons.heart_fill
                                      : CupertinoIcons.heart,
                                  color: isFav
                                      ? const Color(0xFFFF3B5C)
                                      : Colors.white,
                                  size: 21,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Bottom Overlapping Off-White Information Panel
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F4).withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First Row: Property name on start, Price on end
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF18181B),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: nightlyPrice,
                                      style: const TextStyle(
                                        color: Color(0xFF18181B),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    if (priceUnit.isNotEmpty)
                                      TextSpan(
                                        text: ' $priceUnit',
                                        style: const TextStyle(
                                          color: Color(0xFF71717A),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Second Row: Location pin + location text | secondary summary
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: Color(0xFF71717A),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF71717A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Container(
                                width: 1,
                                height: 12,
                                color: const Color(0xFFD4D4D8),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                totalSummary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF71717A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
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
        ),
      ),
    );
  }
}
