import 'dart:math' as math;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/location/marketplace_location.dart';
import 'kinetic_widgets.dart';
import '../../l10n/l10n.dart';

/// Real interactive Web-Mercator Slippy Map backed by CARTO Voyager / OSM tiles
/// with mathematical circle scaling, pan/zoom gestures, and silent offline fallback.
class RealMarketplaceMap extends StatefulWidget {
  final double lat;
  final double lng;
  final String cityLabel;
  final double circleRadiusKm;
  final double? userLat;
  final double? userLng;
  final double height;
  final double borderRadius;
  final bool interactive;
  final int? initialZoom;
  final Widget? topOverlay;
  final VoidCallback? onExpandTap;
  final ValueChanged<({double lat, double lng})>? onCenterChanged;
  final ValueChanged<({double lat, double lng})>? onPanEnd;

  const RealMarketplaceMap({
    super.key,
    required this.lat,
    required this.lng,
    required this.cityLabel,
    this.circleRadiusKm = 3.2,
    this.userLat,
    this.userLng,
    this.height = 196,
    this.borderRadius = 18,
    this.interactive = true,
    this.initialZoom,
    this.topOverlay,
    this.onExpandTap,
    this.onCenterChanged,
    this.onPanEnd,
  });

  static int recommendedZoomForRadius(double radiusKm) {
    if (radiusKm <= 4.5) return 12;
    if (radiusKm <= 12) return 11;
    if (radiusKm <= 28) return 10;
    if (radiusKm <= 55) return 9;
    if (radiusKm <= 105) return 8;
    return 7;
  }

  @override
  State<RealMarketplaceMap> createState() => _RealMarketplaceMapState();
}

class _RealMarketplaceMapState extends State<RealMarketplaceMap> {
  static const double _tileSize = 256.0;
  static const Color _fbBlue = Color(0xFF0A0A0A);
  static const List<String> _subdomains = ['a', 'b', 'c', 'd'];

  late double _centerLat;
  late double _centerLng;
  late int _zoom;

  @override
  void initState() {
    super.initState();
    _centerLat = widget.lat;
    _centerLng = widget.lng;
    _zoom = widget.initialZoom ??
        RealMarketplaceMap.recommendedZoomForRadius(widget.circleRadiusKm);
  }

  @override
  void didUpdateWidget(covariant RealMarketplaceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.lat - widget.lat).abs() > 0.0001 ||
        (oldWidget.lng - widget.lng).abs() > 0.0001) {
      _centerLat = widget.lat;
      _centerLng = widget.lng;
    }
    if (oldWidget.circleRadiusKm != widget.circleRadiusKm &&
        widget.initialZoom == null) {
      _zoom = RealMarketplaceMap.recommendedZoomForRadius(widget.circleRadiusKm);
    }
  }

  Offset _latLngToWorld(double lat, double lng, int zoom) {
    final clampedLat = lat.clamp(-85.0, 85.0);
    final n = (1 << zoom).toDouble();
    final x = ((lng + 180.0) / 360.0) * n * _tileSize;
    final latRad = clampedLat * math.pi / 180.0;
    final mercY =
        math.log(math.tan(latRad) + 1.0 / math.cos(latRad));
    final y = (1.0 - mercY / math.pi) / 2.0 * n * _tileSize;
    return Offset(x, y);
  }

  ({double lat, double lng}) _worldToLatLng(Offset world, int zoom) {
    final n = (1 << zoom).toDouble();
    final totalPx = n * _tileSize;
    final lng = ((world.dx / totalPx) * 360.0 - 180.0).clamp(-180.0, 180.0);
    final nLat = math.pi - 2.0 * math.pi * (world.dy.clamp(0.0, totalPx) / totalPx);
    final sinh = 0.5 * (math.exp(nLat) - math.exp(-nLat));
    final lat = (180.0 / math.pi * math.atan(sinh)).clamp(-85.0, 85.0);
    return (lat: lat, lng: lng);
  }

  double _metersPerPixel(double lat, int zoom) {
    return 156543.03392 *
        math.cos(lat * math.pi / 180.0) /
        math.pow(2.0, zoom);
  }

  void _changeZoom(int delta) {
    final next = (_zoom + delta).clamp(5, 16);
    if (next == _zoom) return;
    HapticFeedback.selectionClick();
    setState(() => _zoom = next);
  }

  void _recenter() {
    HapticFeedback.selectionClick();
    setState(() {
      _centerLat = widget.lat;
      _centerLng = widget.lng;
      _zoom = widget.initialZoom ??
          RealMarketplaceMap.recommendedZoomForRadius(widget.circleRadiusKm);
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.interactive) return;
    final centerWorld = _latLngToWorld(_centerLat, _centerLng, _zoom);
    final moved = centerWorld - details.delta;
    final next = _worldToLatLng(moved, _zoom);
    setState(() {
      _centerLat = next.lat;
      _centerLng = next.lng;
    });
    widget.onCenterChanged?.call(next);
  }

  Widget _buildPositionedTile({
    required int tx,
    required int ty,
    required int nTiles,
    required Offset topLeftWorld,
  }) {
    final wrappedTx = ((tx % nTiles) + nTiles) % nTiles;
    final hostIdx = (tx + ty).abs() % 4;
    return Positioned(
      left: tx * _tileSize - topLeftWorld.dx,
      top: ty * _tileSize - topLeftWorld.dy,
      width: _tileSize,
      height: _tileSize,
      child: _MapTileImage(
        url: 'https://mt$hostIdx.google.com/vt/lyrs=m&x=$wrappedTx&y=$ty&z=$_zoom',
        fallbackUrl:
            'https://${_subdomains[hostIdx]}.basemaps.cartocdn.com/rastertiles/voyager/$_zoom/$wrappedTx/$ty.png',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF1F8),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: const Color(0xFFDDE3EC),
            width: 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final vw = constraints.maxWidth;
            final vh = constraints.maxHeight;

            final centerWorld = _latLngToWorld(_centerLat, _centerLng, _zoom);
            final topLeftWorld = Offset(
              centerWorld.dx - vw / 2,
              centerWorld.dy - vh / 2,
            );

            final nTiles = 1 << _zoom;
            final minTx = (topLeftWorld.dx / _tileSize).floor();
            final maxTx = ((topLeftWorld.dx + vw) / _tileSize).floor();
            final minTy = (topLeftWorld.dy / _tileSize).floor().clamp(0, nTiles - 1);
            final maxTy = ((topLeftWorld.dy + vh) / _tileSize).floor().clamp(0, nTiles - 1);

            final bool pinTracksCenter =
                widget.onCenterChanged != null || widget.onPanEnd != null;
            final double pinLat = pinTracksCenter ? _centerLat : widget.lat;
            final double pinLng = pinTracksCenter ? _centerLng : widget.lng;
            final markerWorld = _latLngToWorld(pinLat, pinLng, _zoom);
            final markerScreen = markerWorld - topLeftWorld;

            Offset? userScreen;
            if (widget.userLat != null && widget.userLng != null) {
              userScreen =
                  _latLngToWorld(widget.userLat!, widget.userLng!, _zoom) -
                      topLeftWorld;
            }

            final mpp = _metersPerPixel(pinLat, _zoom);
            final rawCirclePx = (widget.circleRadiusKm * 1000.0) / mpp;
            final double radiusPx = rawCirclePx.clamp(
              32.0,
              math.min(vw, vh) * 0.44,
            );

            return GestureDetector(
              onPanUpdate: widget.interactive ? _handlePanUpdate : null,
              onPanEnd: widget.interactive
                  ? (_) => widget.onPanEnd
                      ?.call((lat: _centerLat, lng: _centerLng))
                  : null,
              onTap: widget.onExpandTap,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 0. Crisp cartographic coordinate backdrop while tiles stream / offline
                  CustomPaint(
                    painter: _CartographicGridPainter(
                      lat: _centerLat,
                      lng: _centerLng,
                    ),
                  ),

                  // 1. Real Google Maps Slippy Map Tiles (with CARTO Voyager fallback)
                  for (int ty = minTy; ty <= maxTy; ty++)
                    for (int tx = minTx; tx <= maxTx; tx++)
                      _buildPositionedTile(
                        tx: tx,
                        ty: ty,
                        nTiles: nTiles,
                        topLeftWorld: topLeftWorld,
                      ),

                  // 2. Approximate Zone Circle scaled to Mercator radius
                  Positioned(
                    left: markerScreen.dx - radiusPx,
                    top: markerScreen.dy - radiusPx,
                    width: radiusPx * 2,
                    height: radiusPx * 2,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _fbBlue.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _fbBlue.withValues(alpha: 0.55),
                            width: 1.8,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.90),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.cityLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. User's own detected GPS/Zone dot when inside viewport
                  if (userScreen != null &&
                      userScreen.dx >= -20 &&
                      userScreen.dx <= vw + 20 &&
                      userScreen.dy >= -20 &&
                      userScreen.dy <= vh + 20 &&
                      (userScreen - markerScreen).distance > 18)
                    Positioned(
                      left: userScreen.dx - 9,
                      top: userScreen.dy - 9,
                      child: IgnorePointer(
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _fbBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.8),
                            boxShadow: [
                              BoxShadow(
                                color: _fbBlue.withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 4. Optional top badge overlay (Distance / Zone status)
                  if (widget.topOverlay != null)
                    PositionedDirectional(
                      top: 10,
                      start: 10,
                      child: widget.topOverlay!,
                    ),

                  // 5. Interactive Zoom + / - & Recenter Controls
                  if (widget.interactive)
                    PositionedDirectional(
                      top: 10,
                      end: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _MapMiniControlBtn(
                                      icon: CupertinoIcons.plus,
                                      onTap: () => _changeZoom(1),
                                    ),
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Color(0xFFE2E8F0),
                                    ),
                                    _MapMiniControlBtn(
                                      icon: CupertinoIcons.minus,
                                      onTap: () => _changeZoom(-1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (widget.onExpandTap != null) ...[
                            const SizedBox(height: 6),
                            _MapMiniControlPill(
                              icon: CupertinoIcons.fullscreen,
                              onTap: widget.onExpandTap!,
                            ),
                          ] else ...[
                            const SizedBox(height: 6),
                            _MapMiniControlPill(
                              icon: CupertinoIcons.location_fill,
                              onTap: _recenter,
                            ),
                          ],
                        ],
                      ),
                    ),

                  // 6. Clean Attribution badge (Google Maps)
                  PositionedDirectional(
                    bottom: 8,
                    end: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Google Maps',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MapTileImage extends StatelessWidget {
  final String url;
  final String? fallbackUrl;

  const _MapTileImage({
    required this.url,
    this.fallbackUrl,
  });

  Widget _buildFallback() {
    if (fallbackUrl == null) return const SizedBox.shrink();
    return Image.network(
      fallbackUrl!,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      httpHeaders: const {'User-Agent': 'ApoloMobile/1.0 (+https://apolo.ma)'},
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) => _buildFallback(),
    );
  }
}

class _MapMiniControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapMiniControlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 30,
        height: 28,
        child: Icon(icon, size: 14, color: const Color(0xFF0F172A)),
      ),
    );
  }
}

class _MapMiniControlPill extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapMiniControlPill({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 30,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, size: 13.5, color: const Color(0xFF0F172A)),
          ),
        ),
      ),
    );
  }
}

/// Subtle geographic coordinate grid rendered cleanly beneath real OSM/CARTO tiles.
class _CartographicGridPainter extends CustomPainter {
  final double lat;
  final double lng;

  const _CartographicGridPainter({required this.lat, required this.lng});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEDF2F7),
    );
    final gridPaint = Paint()
      ..color = const Color(0xFFDCE5F0)
      ..strokeWidth = 0.8;

    const double step = 32.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Subtle arterial guide lines to anchor visual space until tiles arrive
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final p1 = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.50,
        size.width,
        size.height * 0.16,
      );
    canvas.drawPath(p1, roadPaint);
  }

  @override
  bool shouldRepaint(covariant _CartographicGridPainter oldDelegate) =>
      oldDelegate.lat != lat || oldDelegate.lng != lng;
}

/// Full-screen interactive Map modal allowing pan, zoom, external Google Maps launch,
/// and switching Marketplace active zone directly to the listing's area.
Future<void> showFullMarketplaceMapDialog({
  required BuildContext context,
  required AppStrings s,
  required double lat,
  required double lng,
  required String cityLabel,
  required String locationSubtitle,
  double? userLat,
  double? userLng,
  VoidCallback? onFilterToListingZone,
}) async {
  HapticFeedback.selectionClick();
  await Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullMarketplaceMapPage(
        s: s,
        lat: lat,
        lng: lng,
        cityLabel: cityLabel,
        locationSubtitle: locationSubtitle,
        userLat: userLat,
        userLng: userLng,
        onFilterToListingZone: onFilterToListingZone,
      ),
    ),
  );
}

class _FullMarketplaceMapPage extends StatelessWidget {
  final AppStrings s;
  final double lat;
  final double lng;
  final String cityLabel;
  final String locationSubtitle;
  final double? userLat;
  final double? userLng;
  final VoidCallback? onFilterToListingZone;

  const _FullMarketplaceMapPage({
    required this.s,
    required this.lat,
    required this.lng,
    required this.cityLabel,
    required this.locationSubtitle,
    this.userLat,
    this.userLng,
    this.onFilterToListingZone,
  });

  @override
  Widget build(BuildContext context) {
    final distKm = (userLat != null && userLng != null)
        ? MarketplaceLocation.haversineKm(userLat!, userLng!, lat, lng)
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(CupertinoIcons.xmark, color: Color(0xFF0F172A)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cityLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              s.tr(
                'الموقع التقريبي على الخريطة',
                'Localisation approximative',
                appL10n.realMarketplaceMapApproximateMapArea,
              ),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: RealMarketplaceMap(
                lat: lat,
                lng: lng,
                cityLabel: cityLabel,
                circleRadiusKm: 4.0,
                userLat: userLat,
                userLng: userLng,
                height: double.infinity,
                borderRadius: 22,
                interactive: true,
                initialZoom: 12,
                topOverlay: distKm == null
                    ? null
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          s.tr(
                            'على بعد ${distKm.round()} كم من موقعك',
                            'À ${distKm.round()} km de votre zone',
                            appL10n.realMarketplaceMapDistkmKmFromYou(distKm.round()),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  if (onFilterToListingZone != null) ...[
                    Expanded(
                      child: PressableScale(
                        onTap: () {
                          Navigator.pop(context);
                          onFilterToListingZone!();
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F3F7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            s.tr(
                              'اعتماده كمنطقتي',
                              'Définir comme ma zone',
                              appL10n.realMarketplaceMapSetAsMyZone,
                            ),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: PressableScale(
                      onTap: () async {
                        final q = Uri.encodeComponent('$locationSubtitle, Morocco');
                        final uri = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$q',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          s.tr(
                            'فتح في Google Maps',
                            'Ouvrir dans Maps',
                            appL10n.storeDetailOpenGoogleMaps,
                          ),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
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
