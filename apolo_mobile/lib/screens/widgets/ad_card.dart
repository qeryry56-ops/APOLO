import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/state/app_state.dart';
import '../../theme/app_typography.dart';
import '../ad_detail_screen.dart';
import '../auth_screen.dart';
import 'app_image.dart';
import 'kinetic_widgets.dart';
import 'price_text.dart';

/// Dynamic Layer v5.1 Compact Product/Listing Card (`AdCard`):
/// - Flat `#F6F6F6` / `#FFFFFF` card with `1px` `#EEEEEE` border and zero drop shadows
/// - `#000000` bold `PriceText`, `#EEEEEE` `Negotiable` capsule, `#000000` `VIP` pill,
///   and `#FFFFFF` circular favorite heart (`#FF3B30` active / `#000000` inactive).
class AdCard extends StatelessWidget {
  final Map<String, dynamic> ad;
  final bool horizontal;

  const AdCard({super.key, required this.ad, this.horizontal = false});

  static const Color _dlBg = Color(0xFFFFFFFF);
  static const Color _dlSurface = Color(0xFFF6F6F6);
  static const Color _dlPill = Color(0xFFEEEEEE);
  static const Color _dlSeparator = Color(0xFFEEEEEE);
  static const Color _dlInk = Color(0xFF000000);
  static const Color _dlMuted = Color(0xFF757575);
  static const Color _dlHeartRed = Color(0xFFFF3B30);

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final int id = int.tryParse(ad['id'].toString()) ?? 0;
    final String title = (ad['title'] ?? '').toString();
    final String priceFormatted = (ad['price_formatted'] ??
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
                : (state.s.isEn
                    ? (ad['city']['name_en'] ??
                        ad['city']['name_fr'] ??
                        ad['city']['name'])
                    : (ad['city']['name_fr'] ?? ad['city']['name'])))
            .toString()
        : (state.s.isAr
                ? (ad['city_ar'] ?? ad['city_name'] ?? '')
                : (state.s.isEn
                    ? (ad['city_en'] ?? ad['city_fr'] ?? ad['city_name'] ?? '')
                    : (ad['city_fr'] ?? ad['city_name'] ?? '')))
            .toString();

    final Map<String, dynamic> catMap = ad['category'] is Map
        ? Map<String, dynamic>.from(ad['category'])
        : {'name': ad['category_name'] ?? ad['category_ar'] ?? ''};
    final String categoryName = state.formatCategoryLabel(catMap);
    final String categoryAsset = state.assetForCategory(catMap, categoryName);
    final bool isFav = state.favoriteAdIds.contains(id);

    return PressableScale(
      onTap: () {
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
          color: _dlSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFeatured ? _dlInk : _dlSeparator,
            width: 1.0,
          ),
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
          color: _dlPill,
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
        if (cityName.isNotEmpty)
          PositionedDirectional(
            bottom: 8,
            start: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: _dlBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.location_solid,
                    size: 10,
                    color: _dlInk,
                  ),
                  const SizedBox(width: 3),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 92),
                    child: Text(
                      cityName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _dlInk,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (isFeatured)
          PositionedDirectional(
            top: 8,
            start: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _dlInk,
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
                    state.s.tr('مميز', 'VIP', 'VIP'),
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
        PositionedDirectional(
          top: 2,
          end: 2,
          child: AnimatedBuilder(
            animation: state,
            builder: (context, __) {
              final bool currentFav = state.favoriteAdIds.contains(id);
              return PressableScale(
                onTap: () async {
                  if (!state.isLoggedIn) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                    return;
                  }
                  HapticFeedback.selectionClick();
                  await state.toggleFavorite(
                    id,
                    categoryId: state.extractAdCategoryId(ad),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: _dlBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      currentFav
                          ? CupertinoIcons.heart_fill
                          : CupertinoIcons.heart,
                      size: 15,
                      color: currentFav ? _dlHeartRed : _dlInk,
                    ),
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
              borderRadius: BorderRadius.circular(15),
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
              Row(
                children: [
                  Expanded(
                    child: PriceText(
                      price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _dlInk,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        letterSpacing:
                            AppTypography.trackingForContext(context, -0.3),
                        fontFeatures: const [FontFeature.tabularFigures()],
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
                        color: _dlBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        state.s.tr('تفاوض', 'Négo', 'Negotiable'),
                        style: const TextStyle(
                          color: _dlInk,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _dlInk,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  letterSpacing:
                      AppTypography.trackingForContext(context, -0.2),
                ),
              ),
              const SizedBox(height: 6),
              if (category.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _dlBg,
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
                            color: _dlMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
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
              borderRadius: BorderRadius.circular(15),
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
              padding: const EdgeInsetsDirectional.fromSTEB(8, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PriceText(
                    price,
                    style: TextStyle(
                      color: _dlInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.5,
                      letterSpacing:
                          AppTypography.trackingForContext(context, -0.3),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _dlInk,
                      letterSpacing:
                          AppTypography.trackingForContext(context, -0.2),
                    ),
                  ),
                  Row(
                    children: [
                      if (category.isNotEmpty)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _dlBg,
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
                                      color: _dlMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const Spacer(),
                      Icon(
                        state.s.isAr
                            ? CupertinoIcons.chevron_left
                            : CupertinoIcons.chevron_right,
                        size: 15,
                        color: _dlMuted,
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
