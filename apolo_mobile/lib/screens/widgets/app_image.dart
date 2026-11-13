import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;
  final bool isPriority;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
    this.isPriority = false,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final defaultFallback = fallback ??
        Container(
          width: width,
          height: height,
          color: const Color(0xFFF1F5F9),
          alignment: Alignment.center,
          child: const Icon(Icons.image_outlined,
              size: 28, color: Color(0xFF94A3B8)),
        );

    if (url == null || url!.trim().isEmpty) {
      return defaultFallback;
    }

    // Local bundled assets (e.g. 3D category cutouts used in demo content)
    if (url!.startsWith('assets/')) {
      return Image.asset(
        url!,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => defaultFallback,
      );
    }

    // Auto-calculate memory cache dimensions to cap raster footprint
    final int? targetMemWidth = memCacheWidth ??
        (width != null && width!.isFinite && width! > 0
            ? (width! * 2).round()
            : null);
    final int? targetMemHeight = memCacheHeight ??
        (height != null && height!.isFinite && height! > 0
            ? (height! * 2).round()
            : null);

    if (kIsWeb) {
      return Image.network(
        url!,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: targetMemWidth,
        cacheHeight: targetMemHeight,
        errorBuilder: (_, __, ___) => defaultFallback,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          if (isPriority) return child;
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFF8FAFC),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFE31B23)),
            ),
          );
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: targetMemWidth,
      memCacheHeight: targetMemHeight,
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: const Color(0xFFF8FAFC),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFFE31B23)),
        ),
      ),
      errorWidget: (_, __, ___) => defaultFallback,
    );
  }
}

class AppAvatar extends StatelessWidget {
  final String? url;
  final double radius;
  final IconData fallbackIcon;
  final Color iconColor;

  const AppAvatar({
    super.key,
    required this.url,
    this.radius = 26,
    this.fallbackIcon = Icons.person_rounded,
    this.iconColor = const Color(0xFFE31B23),
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.trim().isNotEmpty
          ? AppImage(
              url: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              memCacheWidth: (size * 2).round(),
              memCacheHeight: (size * 2).round(),
              fallback:
                  Icon(fallbackIcon, color: iconColor, size: radius * 0.95),
            )
          : Icon(fallbackIcon, color: iconColor, size: radius * 0.95),
    );
  }
}
