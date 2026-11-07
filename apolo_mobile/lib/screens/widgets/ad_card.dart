import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/state/app_state.dart';
import '../ad_detail_screen.dart';
import 'app_image.dart';

class AdCard extends StatelessWidget {
  final Map<String, dynamic> ad;
  final bool horizontal;

  const AdCard({super.key, required this.ad, this.horizontal = false});

  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _red = Color(0xFFE31B23);
  static const Color _pillBg = Color(0xFFF1F3F7);
  static const Color _border = Color(0xFFEDEFF3);

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final int id = int.tryParse(ad['id'].toString()) ?? 0;
    final String title = (ad['title'] ?? '').toString();
    final String priceFormatted = (ad['price_formatted'] ?? '').toString();
    final String? primaryImage = (ad['main_image'] ?? ad['primary_image'])?.toString();
    final bool isFeatured = ad['is_vip'] == true || ad['is_highlighted'] == true || ad['is_featured'] == true;
    final bool isNegotiable = ad['is_negotiable'] == true;
    final String? condition = ad['condition']?.toString();
    final String cityName = ad['city'] != null
        ? (state.s.isAr ? (ad['city']['name_ar'] ?? ad['city']['name']) : (ad['city']['name_fr'] ?? ad['city']['name'])).toString()
        : '';
    final String categoryName = ad['category'] != null
        ? (state.s.isAr ? (ad['category']['name_ar'] ?? ad['category']['name']) : (ad['category']['name_fr'] ?? ad['category']['name'])).toString()
        : '';
    final bool isFav = state.favoriteAdIds.contains(id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdDetailScreen(adId: id, initialAd: ad)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isFeatured ? AppConfig.vipGold.withValues(alpha: 0.65) : _border,
            width: isFeatured ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F1B2D).withValues(alpha: 0.045),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: horizontal
            ? _buildHorizontal(context, state, id, title, priceFormatted, primaryImage, isFeatured, isNegotiable, condition, cityName, categoryName, isFav)
            : _buildVertical(context, state, id, title, priceFormatted, primaryImage, isFeatured, isNegotiable, condition, cityName, categoryName, isFav),
      ),
    );
  }

  Widget _buildImage(String? url, bool isFeatured, bool isFav, int id, String cityName, AppState state, {double? height, double? width}) {
    return Stack(
      children: [
        Container(
          height: height ?? double.infinity,
          width: width ?? double.infinity,
          color: _pillBg,
          child: AppImage(
            url: url,
            fit: BoxFit.cover,
            memCacheWidth: width != null && width.isFinite ? (width * 2).round() : 400,
            memCacheHeight: height != null && height.isFinite ? (height * 2).round() : 360,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 52,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.48),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (cityName.isNotEmpty)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.location_solid, size: 10.5, color: Colors.white),
                  const SizedBox(width: 3),
                  Text(
                    cityName,
                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        if (isFeatured)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _red,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(color: _red.withValues(alpha: 0.32), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.bolt_fill, size: 11, color: Colors.white),
                  SizedBox(width: 2),
                  Text('VIP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                ],
              ),
            ),
          ),
        Positioned(
          top: 8,
          left: 8,
          child: AnimatedBuilder(
            animation: state,
            builder: (_, __) {
              final bool currentFav = state.favoriteAdIds.contains(id);
              return GestureDetector(
                onTap: () => state.toggleFavorite(id),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6),
                    ],
                  ),
                  child: Icon(
                    currentFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    size: 16,
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
    String? condition,
    String city,
    String category,
    bool isFav,
  ) {
    final String tagLabel = (condition != null && condition.isNotEmpty) ? condition : category;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildImage(image, isFeatured, isFav, id, city, state),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _red,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (tagLabel.isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: _pillBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tagLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  if (isNegotiable) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEECEE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        state.s.tr('تفاوض', 'Négo'),
                        style: const TextStyle(color: _red, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
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
    String? condition,
    String city,
    String category,
    bool isFav,
  ) {
    return SizedBox(
      height: 128,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildImage(image, isFeatured, isFav, id, city, state, width: 132, height: 116),
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
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: _ink, letterSpacing: -0.2),
                  ),
                  Text(
                    price,
                    style: const TextStyle(color: _red, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3),
                  ),
                  Row(
                    children: [
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: _pillBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            state.s.tr('عرض', 'Voir'),
                            style: const TextStyle(color: _red, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: _red),
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
    );
  }
}
