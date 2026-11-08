import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/state/app_state.dart';
import '../ad_detail_screen.dart';
import 'app_image.dart';

class AdCard extends StatelessWidget {
  final Map<String, dynamic> ad;
  final bool horizontal;

  const AdCard({super.key, required this.ad, this.horizontal = false});

  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _red = Color(0xFFE31B23);
  static const Color _surface = Color(0xFFF5F6F8);
  static const Color _emerald = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final int id = int.tryParse(ad['id'].toString()) ?? 0;
    final String title = (ad['title'] ?? '').toString();
    final String priceFormatted =
        (ad['price_formatted'] ??
                (ad['price'] != null ? '${ad['price']} DH' : ''))
            .toString();
    final String? primaryImage =
        (ad['main_image'] ?? ad['primary_image'])?.toString();
    final bool isFeatured = ad['is_vip'] == true ||
        ad['is_highlighted'] == true ||
        ad['is_featured'] == true;
    final bool isNegotiable =
        ad['is_negotiable'] == true || ad['negotiable'] == true;

    final String cityName = ad['city'] is Map
        ? (state.s.isAr
                ? (ad['city']['name_ar'] ?? ad['city']['name'])
                : (ad['city']['name_fr'] ?? ad['city']['name']))
            .toString()
        : (state.s.isAr
                ? (ad['city_ar'] ?? ad['city_name'] ?? '')
                : (ad['city_fr'] ?? ad['city_name'] ?? ''))
            .toString();

    final Map<String, dynamic> catMap = ad['category'] is Map
        ? Map<String, dynamic>.from(ad['category'])
        : {'name': ad['category_name'] ?? ad['category_ar'] ?? ''};
    final String categoryName = state.formatCategoryLabel(catMap);
    final String categoryAsset = state.assetForCategory(catMap, categoryName);
    final bool isFav = state.favoriteAdIds.contains(id);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        final catId = state.extractAdCategoryId(ad);
        if (catId != null) {
          state.recordCategoryInterest(catId, weight: 2);
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdDetailScreen(adId: id, initialAd: ad),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isFeatured
                ? _red.withValues(alpha: 0.28)
                : const Color(0xFFEEF1F6),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: _ink.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: horizontal
            ? _buildHorizontal(
                context,
                state,
                id,
                title,
                priceFormatted,
                primaryImage,
                isFeatured,
                isNegotiable,
                cityName,
                categoryName,
                categoryAsset,
                isFav,
              )
            : _buildVertical(
                context,
                state,
                id,
                title,
                priceFormatted,
                primaryImage,
                isFeatured,
                isNegotiable,
                cityName,
                categoryName,
                categoryAsset,
                isFav,
              ),
      ),
    );
  }

  Widget _buildImage(
    String? url,
    bool isFeatured,
    bool isFav,
    int id,
    String cityName,
    String categoryAsset,
    AppState state, {
    double? height,
    double? width,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          height: height ?? double.infinity,
          width: width ?? double.infinity,
          color: _surface,
          child: url != null && url.isNotEmpty
              ? AppImage(
                  url: url,
                  fit: BoxFit.cover,
                  memCacheWidth: width != null && width.isFinite
                      ? (width * 2).round()
                      : 400,
                  memCacheHeight: height != null && height.isFinite
                      ? (height * 2).round()
                      : 360,
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Image.asset(
                      categoryAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
        ),
        // Subtle bottom gradient for city pill legibility
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 46,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.42),
                  ],
                ),
              ),
            ),
          ),
        ),
        // City Pill at bottom-start (never overlaps image center)
        if (cityName.isNotEmpty)
          PositionedDirectional(
            bottom: 8,
            start: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.location_solid,
                    size: 10,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 3),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 92),
                    child: Text(
                      cityName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
        // Featured / VIP badge at top-start
        if (isFeatured)
          PositionedDirectional(
            top: 8,
            start: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _red,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.bolt_fill,
                    size: 10,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    state.s.tr('مميز', 'VIP'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Favorite Heart at top-end
        PositionedDirectional(
          top: 8,
          end: 8,
          child: AnimatedBuilder(
            animation: state,
            builder: (_, __) {
              final bool currentFav = state.favoriteAdIds.contains(id);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  state.toggleFavorite(
                    id,
                    categoryId: state.extractAdCategoryId(ad),
                  );
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    currentFav
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    size: 15,
                    color: currentFav ? _red : _ink,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVertical(
    BuildContext context,
    AppState state,
    int id,
    String title,
    String price,
    String? image,
    bool isFeatured,
    bool isNegotiable,
    String city,
    String category,
    String categoryAsset,
    bool isFav,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: _buildImage(
                image,
                isFeatured,
                isFav,
                id,
                city,
                categoryAsset,
                state,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Price + Negotiable dot (Easy instant scan)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _red,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                        letterSpacing: -0.3,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  if (isNegotiable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        state.s.tr('تفاوض', 'Négo'),
                        style: const TextStyle(
                          color: _emerald,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // 2. Clean Title
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              // 3. Harmonious Mini Category Pill (Icon + Name, never overlaps)
              if (category.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: Image.asset(
                          categoryAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontal(
    BuildContext context,
    AppState state,
    int id,
    String title,
    String price,
    String? image,
    bool isFeatured,
    bool isNegotiable,
    String city,
    String category,
    String categoryAsset,
    bool isFav,
  ) {
    return SizedBox(
      height: 126,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: SizedBox(
                width: 128,
                height: 114,
                child: _buildImage(
                  image,
                  isFeatured,
                  isFav,
                  id,
                  city,
                  categoryAsset,
                  state,
                  width: 128,
                  height: 114,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      color: _red,
                      fontWeight: FontWeight.w900,
                      fontSize: 16.5,
                      letterSpacing: -0.3,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Row(
                    children: [
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: Image.asset(
                                  categoryAsset,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      Icon(
                        state.s.isAr
                            ? CupertinoIcons.chevron_left
                            : CupertinoIcons.chevron_right,
                        size: 15,
                        color: _muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
