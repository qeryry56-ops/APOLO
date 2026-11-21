import 'dart:convert';
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

  /// Rewrites Apolo storage image URLs on Vercel Web to the same-origin
  /// `/apolo-media/*` rewrite in `vercel.json` so CanvasKit avoids CORS blocks.
  static String resolveWebUrl(
    String rawUrl, {
    bool? isWebOverride,
    String? hostOverride,
  }) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty || trimmed.startsWith('assets/')) return trimmed;

    const apoloStoragePrefix = 'https://apolo.ma/storage/';
    const apoloAssetsPrefix = 'https://apolo.ma/assets/';
    var normalized = trimmed;
    if (normalized.startsWith('/storage/')) {
      normalized = 'https://apolo.ma$normalized';
    } else if (normalized.startsWith('storage/')) {
      normalized = 'https://apolo.ma/$normalized';
    } else if (normalized.startsWith('/assets/Memoji/')) {
      normalized = 'https://apolo.ma$normalized';
    } else if (normalized.startsWith('http://apolo.ma/storage/')) {
      normalized = normalized.replaceFirst('http://', 'https://');
    } else if (normalized.startsWith('http://apolo.ma/assets/')) {
      normalized = normalized.replaceFirst('http://', 'https://');
    } else if (normalized.startsWith('https://www.apolo.ma/storage/')) {
      normalized = normalized.replaceFirst(
        'https://www.apolo.ma/',
        'https://apolo.ma/',
      );
    } else if (normalized.startsWith('https://www.apolo.ma/assets/')) {
      normalized = normalized.replaceFirst(
        'https://www.apolo.ma/',
        'https://apolo.ma/',
      );
    } else if (normalized.startsWith('http://www.apolo.ma/storage/')) {
      normalized = normalized.replaceFirst(
        'http://www.apolo.ma/',
        'https://apolo.ma/',
      );
    }

    final useWeb = isWebOverride ?? kIsWeb;
    if (useWeb) {
      final host = (hostOverride ?? Uri.base.host).toLowerCase();
      if (host.endsWith('vercel.app')) {
        if (normalized.startsWith(apoloStoragePrefix)) {
          return '/apolo-media/${normalized.substring(apoloStoragePrefix.length)}';
        }
        if (normalized.startsWith(apoloAssetsPrefix)) {
          return '/apolo-assets/${normalized.substring(apoloAssetsPrefix.length)}';
        }
      }
    }
    return normalized;
  }

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

    // Base64 data URI (e.g. locally picked avatar photo)
    if (url!.startsWith('data:image/')) {
      final commaIdx = url!.indexOf(',');
      if (commaIdx != -1) {
        try {
          final bytes = base64Decode(url!.substring(commaIdx + 1));
          return Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => defaultFallback,
          );
        } catch (_) {
          return defaultFallback;
        }
      }
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

    final resolvedUrl = resolveWebUrl(url!);

    if (kIsWeb) {
      return Image.network(
        resolvedUrl,
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
                  strokeWidth: 2, color: Color(0xFF0A0A0A)),
            ),
          );
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: resolvedUrl,
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
              strokeWidth: 2, color: Color(0xFF0A0A0A)),
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
    this.iconColor = const Color(0xFF0A0A0A),
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
