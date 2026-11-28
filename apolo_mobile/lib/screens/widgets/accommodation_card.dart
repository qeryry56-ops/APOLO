import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/state/app_state.dart';
import '../ad_detail_screen.dart';
import 'app_image.dart';
import 'kinetic_widgets.dart';
import '../../widgets/dl_settings_kit.dart';
import '../../l10n/l10n.dart';

/// Dynamic Layer v5.1 Exclusive Deals / Accommodation Showcase Card:
/// - 0.84:1 portrait aspect ratio (width : height)
/// - Crisp 24px rounded corners with 1px #EEEEEE border (zero muddy drop shadow)
/// - Top-start translucent pills: Category badge + Star rating (#FFB800 ★)
/// - Top-end 40x40 circular favorite button (44x44pt hit target) with #FF3B30 heart
/// - Bottom pure #FFFFFF rounded (20px) floating info panel:
///   - Row 1: Bold #000000 title + #000000 tabular price
///   - Row 2: Pin + #757575 location + 1px #EEEEEE divider + #757575 summary
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

  Color get _dlBg => ApoloDlPalette.of(context).bg;
  Color get _dlSurface => ApoloDlPalette.of(context).surfaceSubtle;
  Color get _dlSeparator => ApoloDlPalette.of(context).separator;
  Color get _dlInk => ApoloDlPalette.of(context).ink;
  Color get _dlOnInk => ApoloDlPalette.of(context).onInk;
  Color get _dlMuted => ApoloDlPalette.of(context).muted;
  static const Color _dlHeartRed = Color(0xFFFF3B30);
  static const Color _dlStarAmber = Color(0xFFFFB800);

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
      return _state.s.tr('مجاني', 'Gratuit', appL10n.adDetailFree);
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
        : _state.s.tr('عند الطلب', 'Sur demande', appL10n.adDetailOnRequest);
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
              : (_state.s.isEn
                  ? (cityMap['name_en'] ??
                      cityMap['name_fr'] ??
                      cityMap['name'] ??
                      cityMap['name_ar'])
                  : (cityMap['name_fr'] ?? cityMap['name'] ?? cityMap['name_ar'])))
          .toString()
          .trim();
      if (cityName.isNotEmpty) return cityName;
    }

    final cityStr = (_state.s.isAr
            ? (ad['city_ar'] ?? ad['city_name'] ?? ad['city_fr'])
            : (_state.s.isEn
                ? (ad['city_en'] ??
                    ad['city_fr'] ??
                    ad['city_name'] ??
                    ad['city_ar'])
                : (ad['city_fr'] ?? ad['city_name'] ?? ad['city_ar'])))
        .toString()
        .trim();
    if (cityStr.isNotEmpty) return cityStr;

    return _state.s.tr('المغرب', 'Maroc', appL10n.accommodationCardSintraPortugal);
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
          return appL10n.accommodationTotalForNights(formattedTotal, nights);
        }
      }
      return appL10n.accommodationTotalForNights('\$651', 4);
    }

    if (ad['is_negotiable'] == true || ad['negotiable'] == true) {
      return _state.s.tr('قابل للتفاوض', 'Négociable', appL10n.negotiableBadge);
    }
    final views =
        int.tryParse((ad['views_count'] ?? ad['views'] ?? '').toString()) ?? 0;
    if (views > 0) {
      return '$views ${_state.s.tr('مشاهدة', 'vues', appL10n.profileViews)}';
    }
    return _state.s.tr('عرض حصري', 'Offre exclusive', appL10n.accommodationCardExclusiveDeal);
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
      color: _dlSurface,
      alignment: const Alignment(0, -0.22),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        width: 152,
        height: 152,
        errorBuilder: (_, __, ___) => Icon(
          CupertinoIcons.photo,
          color: _dlMuted,
          size: 46,
        ),
      ),
    );
  }

  Widget _buildGlassPill({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
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
            color: _dlSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _dlSeparator, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Main Edge-to-Edge Listing Photo
              Positioned.fill(
                child: _buildBackgroundImage(imageUrl),
              ),

              // Subtle top vignette for crisp pill contrast
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 76,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Top Overlay Elements
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                                style: TextStyle(
                                  color: _dlOnInk,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildGlassPill(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: _dlStarAmber,
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating,
                                  style: TextStyle(
                                    color: _dlOnInk,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: context.l10n.accommodationFavoriteTooltip,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _handleFavoriteTap,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isFav
                                    ? _dlBg
                                    : Colors.black.withValues(alpha: 0.38),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                isFav
                                    ? CupertinoIcons.heart_fill
                                    : CupertinoIcons.heart,
                                color: isFav ? _dlHeartRed : Colors.white,
                                size: 19,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Bottom Dynamic Layer Pure #FFFFFF Floating Info Panel
              PositionedDirectional(
                start: 10,
                end: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: _dlBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _dlSeparator, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _dlInk,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 132),
                            child: FittedBox(
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
                                        text: nightlyPrice,
                                        style: TextStyle(
                                          color: _dlInk,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                          fontFeatures: [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                      if (priceUnit.isNotEmpty)
                                        TextSpan(
                                          text: ' $priceUnit',
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14.5,
                            color: _dlMuted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _dlMuted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              width: 1,
                              height: 12,
                              color: _dlSeparator,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              totalSummary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _dlMuted,
                                fontSize: 12.5,
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
    );
  }
}
