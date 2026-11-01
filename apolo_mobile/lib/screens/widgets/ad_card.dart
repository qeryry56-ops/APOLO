import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/state/app_state.dart';
import '../ad_detail_screen.dart';
import 'app_image.dart';

class AdCard extends StatelessWidget {
  final Map<String, dynamic> ad;
  final bool horizontal;

  const AdCard({super.key, required this.ad, this.horizontal = false});

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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFeatured ? AppConfig.vipGold.withValues(alpha: 0.65) : const Color(0xFFF1F5F9),
            width: isFeatured ? 1.6 : 1,
          ),
          boxShadow: AppConfig.softShadow,
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
          color: const Color(0xFFF1F5F9),
          child: AppImage(url: url, fit: BoxFit.cover),
        ),
        // Subtle bottom gradient for editorial depth
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
                    Colors.black.withValues(alpha: 0.38),
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
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 11, color: Colors.white),
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
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFF6B4A)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppConfig.vipGold.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('VIP', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        Positioned(
          top: 8,
          left: 8,
          child: InkWell(
            onTap: () => state.toggleFavorite(id),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6),
                ],
              ),
              child: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 17,
                color: isFav ? const Color(0xFFFF5F7E) : AppConfig.textPrimary,
              ),
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
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
                  color: AppConfig.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppConfig.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 15.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        condition != null && condition.isNotEmpty ? condition : category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppConfig.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (isNegotiable) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppConfig.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        state.s.tr('تفاوض', 'Négo'),
                        style: const TextStyle(color: AppConfig.success, fontSize: 10, fontWeight: FontWeight.w700),
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
      height: 124,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildImage(image, isFeatured, isFav, id, city, state, width: 132, height: 112),
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
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppConfig.textPrimary),
                  ),
                  Text(
                    price,
                    style: const TextStyle(color: AppConfig.primary, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppConfig.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
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
    );
  }
}
