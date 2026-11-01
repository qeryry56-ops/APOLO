import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final defaultFallback = fallback ??
        Container(
          width: width,
          height: height,
          color: const Color(0xFFF1F5F9),
          alignment: Alignment.center,
          child: const Icon(Icons.image_outlined, size: 32, color: Color(0xFF94A3B8)),
        );

    if (url == null || url!.trim().isEmpty) {
      return defaultFallback;
    }

    if (kIsWeb) {
      return Image.network(
        url!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => defaultFallback,
      );
    }

    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: const Color(0xFFF8FAFC),
        alignment: Alignment.center,
        child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
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
    this.iconColor = const Color(0xFF2563EB),
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
              fallback: Icon(fallbackIcon, color: iconColor, size: radius * 0.95),
            )
          : Icon(fallbackIcon, color: iconColor, size: radius * 0.95),
    );
  }
}
