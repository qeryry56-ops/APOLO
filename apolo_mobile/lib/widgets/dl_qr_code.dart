import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// Encoded destination types supported by Apolo profile, store & listing QR codes.
enum ApoloQrTargetType { user, handle, store, ad, external, unknown }

/// Parsed destination payload extracted from an Apolo QR code or deep link.
@immutable
class ApoloQrTarget {
  const ApoloQrTarget({
    required this.type,
    required this.rawValue,
    this.id,
    this.handle,
    this.displayName,
  });

  final ApoloQrTargetType type;
  final String rawValue;
  final int? id;
  final String? handle;
  final String? displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApoloQrTarget &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          rawValue == other.rawValue &&
          id == other.id &&
          handle == other.handle &&
          displayName == other.displayName;

  @override
  int get hashCode => Object.hash(type, rawValue, id, handle, displayName);
}

/// Builds and parses shareable Apolo QR payloads and incoming browser deep links.
abstract final class ApoloProfileQrParser {
  static final RegExp _handlePattern = RegExp(r'^@([A-Za-z0-9._-]+)$');
  static final RegExp _handleCharsPattern = RegExp(r'^[A-Za-z0-9._-]+$');

  static String _cleanHandle(String? raw) {
    if (raw == null) return '';
    return raw.trim().replaceFirst(RegExp(r'^@+'), '').trim();
  }

  static String? _nonEmpty(String? raw) {
    final trimmed = raw?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Builds a real, shareable profile URL that opens directly in the deployed
  /// Web/PWA app (when scanned by a phone's native Camera app or tapped in chat)
  /// as well as inside [ScanProfileCodeScreen].
  static String buildProfileShareUrl({
    int? userId,
    required String displayName,
    required String handle,
    String? baseOrigin,
  }) {
    String origin = (baseOrigin ?? '').trim();
    if (origin.isEmpty) {
      if (kIsWeb &&
          (Uri.base.scheme == 'http' || Uri.base.scheme == 'https') &&
          Uri.base.host.isNotEmpty) {
        origin = Uri.base.origin;
      } else {
        origin = 'https://apolo.ma';
      }
    }
    if (origin.endsWith('/')) {
      origin = origin.substring(0, origin.length - 1);
    }

    final cleanName = displayName.trim();
    final cleanHandle = _cleanHandle(handle);
    final query = <String, String>{
      if (cleanName.isNotEmpty) 'n': cleanName,
      if (cleanHandle.isNotEmpty && (userId != null && userId > 0))
        'h': cleanHandle,
    };

    final path = (userId != null && userId > 0)
        ? '/users/$userId'
        : '/@${cleanHandle.isNotEmpty ? cleanHandle : 'apolo_user'}';

    final parsedOrigin = Uri.parse(origin);
    return parsedOrigin
        .replace(
          path: path,
          queryParameters: query.isEmpty ? null : query,
        )
        .toString();
  }

  static bool isApoloAppHost(String rawHost) {
    final host = rawHost.toLowerCase();
    if (host.isEmpty) return false;
    if (host == 'apolo.ma' ||
        host == 'www.apolo.ma' ||
        host == 'staging.apolo.ma' ||
        host.endsWith('.apolo.ma') ||
        host.endsWith('.vercel.app') ||
        host == 'localhost' ||
        host == '127.0.0.1') {
      return true;
    }
    if (kIsWeb && Uri.base.host.isNotEmpty) {
      return host == Uri.base.host.toLowerCase();
    }
    return false;
  }

  /// Extracts an actionable initial deep-link target when the web app is opened
  /// directly via a QR code scan or shared profile/ad/store link.
  static ApoloQrTarget? parseInitialDeepLink(Uri uri) {
    if (uri.queryParameters.containsKey('google_auth_code')) {
      return null;
    }
    final segments = uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
    final hasDeepQuery = uri.queryParameters.containsKey('user') ||
        uri.queryParameters.containsKey('ad') ||
        uri.queryParameters.containsKey('store') ||
        uri.queryParameters.containsKey('handle');
    if (segments.isEmpty && !hasDeepQuery) {
      return null;
    }
    final target = parse(uri.toString());
    switch (target.type) {
      case ApoloQrTargetType.user:
      case ApoloQrTargetType.handle:
      case ApoloQrTargetType.store:
      case ApoloQrTargetType.ad:
        return target;
      case ApoloQrTargetType.external:
      case ApoloQrTargetType.unknown:
        return null;
    }
  }

  static ApoloQrTarget parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const ApoloQrTarget(type: ApoloQrTargetType.unknown, rawValue: '');
    }

    final handleMatch = _handlePattern.firstMatch(trimmed);
    if (handleMatch != null) {
      return ApoloQrTarget(
        type: ApoloQrTargetType.handle,
        rawValue: trimmed,
        handle: handleMatch.group(1),
      );
    }

    final normalizedInput = (!trimmed.contains('://') &&
            (trimmed.toLowerCase().startsWith('apolo.ma/') ||
                trimmed.toLowerCase().startsWith('www.apolo.ma/')))
        ? 'https://$trimmed'
        : trimmed;

    final uri = Uri.tryParse(normalizedInput);
    if (uri != null && uri.hasScheme) {
      final scheme = uri.scheme.toLowerCase();
      final host = uri.host.toLowerCase();
      final segments =
          uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
      final qp = uri.queryParameters;
      final metaName = _nonEmpty(qp['n'] ?? qp['name']);
      final metaHandle = _nonEmpty(_cleanHandle(qp['h'] ?? qp['handle']));

      if (scheme == 'apolo') {
        if ((host == 'users' || host == 'u') && segments.isNotEmpty) {
          final id = int.tryParse(segments.first);
          if (id != null && id > 0) {
            return ApoloQrTarget(
              type: ApoloQrTargetType.user,
              rawValue: trimmed,
              id: id,
              handle: metaHandle,
              displayName: metaName,
            );
          }
        }
        if (host == 'ads' && segments.isNotEmpty) {
          final id = int.tryParse(segments.first);
          if (id != null && id > 0) {
            return ApoloQrTarget(
              type: ApoloQrTargetType.ad,
              rawValue: trimmed,
              id: id,
            );
          }
        }
        if (host == 'stores' && segments.isNotEmpty) {
          final slug = segments.first.trim();
          if (slug.isNotEmpty) {
            return ApoloQrTarget(
              type: ApoloQrTargetType.store,
              rawValue: trimmed,
              handle: slug,
              displayName: metaName,
            );
          }
        }
        if (host.startsWith('@') && host.length > 1) {
          final h = host.substring(1);
          if (_handleCharsPattern.hasMatch(h)) {
            return ApoloQrTarget(
              type: ApoloQrTargetType.handle,
              rawValue: trimmed,
              handle: h,
              displayName: metaName,
            );
          }
        }
      }

      if ((scheme == 'http' || scheme == 'https') && host.isNotEmpty) {
        if (isApoloAppHost(host)) {
          if (segments.length >= 2 &&
              (segments[0].toLowerCase() == 'users' ||
                  segments[0].toLowerCase() == 'u')) {
            final id = int.tryParse(segments[1]);
            if (id != null && id > 0) {
              return ApoloQrTarget(
                type: ApoloQrTargetType.user,
                rawValue: trimmed,
                id: id,
                handle: metaHandle,
                displayName: metaName,
              );
            }
          }
          if (segments.length >= 2 && segments[0].toLowerCase() == 'ads') {
            final id = int.tryParse(segments[1]);
            if (id != null && id > 0) {
              return ApoloQrTarget(
                type: ApoloQrTargetType.ad,
                rawValue: trimmed,
                id: id,
              );
            }
          }
          if (segments.length >= 2 && segments[0].toLowerCase() == 'stores') {
            final slug = segments[1].trim();
            if (slug.isNotEmpty) {
              return ApoloQrTarget(
                type: ApoloQrTargetType.store,
                rawValue: trimmed,
                handle: slug,
                displayName: metaName,
              );
            }
          }
          if (segments.length == 1 && segments[0].startsWith('@')) {
            final h = segments[0].substring(1);
            if (h.isNotEmpty && _handleCharsPattern.hasMatch(h)) {
              return ApoloQrTarget(
                type: ApoloQrTargetType.handle,
                rawValue: trimmed,
                handle: h,
                displayName: metaName,
              );
            }
          }

          // Query-parameter deep links (/?user=77, /?ad=501, /?store=slug, /?handle=h)
          final qUser = int.tryParse(qp['user'] ?? '');
          if (qUser != null && qUser > 0) {
            return ApoloQrTarget(
              type: ApoloQrTargetType.user,
              rawValue: trimmed,
              id: qUser,
              handle: metaHandle,
              displayName: metaName,
            );
          }
          final qAd = int.tryParse(qp['ad'] ?? '');
          if (qAd != null && qAd > 0) {
            return ApoloQrTarget(
              type: ApoloQrTargetType.ad,
              rawValue: trimmed,
              id: qAd,
            );
          }
          final qStore = _nonEmpty(qp['store']);
          if (qStore != null) {
            return ApoloQrTarget(
              type: ApoloQrTargetType.store,
              rawValue: trimmed,
              handle: qStore,
              displayName: metaName,
            );
          }
          if (metaHandle != null && _handleCharsPattern.hasMatch(metaHandle)) {
            return ApoloQrTarget(
              type: ApoloQrTargetType.handle,
              rawValue: trimmed,
              handle: metaHandle,
              displayName: metaName,
            );
          }
        }
        return ApoloQrTarget(
          type: ApoloQrTargetType.external,
          rawValue: trimmed,
        );
      }
    }

    return ApoloQrTarget(
      type: ApoloQrTargetType.unknown,
      rawValue: trimmed,
    );
  }
}

/// High-contrast ISO/IEC 18004 QR code renderer with zero external assets.
class ApoloDlQrCode extends StatelessWidget {
  const ApoloDlQrCode({
    required this.data,
    super.key,
    this.foregroundColor = const Color(0xFF0A0A0A),
    this.backgroundColor = Colors.white,
    this.errorCorrectLevel = QrErrorCorrectLevel.M,
  });

  final String data;
  final Color foregroundColor;
  final Color backgroundColor;
  final int errorCorrectLevel;

  static QrImage buildQrImage(
    String data, {
    int errorCorrectLevel = QrErrorCorrectLevel.M,
  }) {
    final normalized = data.trim().isEmpty ? 'https://apolo.ma' : data.trim();
    try {
      final qrCode = QrCode.fromData(
        data: normalized,
        errorCorrectLevel: errorCorrectLevel,
      );
      return QrImage(qrCode);
    } on InputTooLongException {
      final truncated =
          normalized.length > 200 ? normalized.substring(0, 200) : 'https://apolo.ma';
      final qrCode = QrCode.fromData(
        data: truncated,
        errorCorrectLevel: QrErrorCorrectLevel.L,
      );
      return QrImage(qrCode);
    }
  }

  static int moduleCountFor(
    String data, {
    int errorCorrectLevel = QrErrorCorrectLevel.M,
  }) {
    return buildQrImage(data, errorCorrectLevel: errorCorrectLevel).moduleCount;
  }

  @override
  Widget build(BuildContext context) {
    final normalized = data.trim().isEmpty ? 'https://apolo.ma' : data.trim();
    final qrImage = buildQrImage(
      normalized,
      errorCorrectLevel: errorCorrectLevel,
    );

    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _ApoloQrPainter(
          dataKey: normalized,
          qrImage: qrImage,
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

class _ApoloQrPainter extends CustomPainter {
  const _ApoloQrPainter({
    required this.dataKey,
    required this.qrImage,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String dataKey;
  final QrImage qrImage;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    if (side <= 0) return;

    final offsetX = (size.width - side) / 2;
    final offsetY = (size.height - side) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..isAntiAlias = false;
    canvas.drawRect(Rect.fromLTWH(offsetX, offsetY, side, side), bgPaint);

    final fgPaint = Paint()
      ..color = foregroundColor
      ..isAntiAlias = false;

    final count = qrImage.moduleCount;
    final cellSize = side / count;

    for (var row = 0; row < count; row++) {
      for (var col = 0; col < count; col++) {
        if (!qrImage.isDark(row, col)) continue;
        final left = offsetX + col * cellSize;
        final top = offsetY + row * cellSize;
        // Slight fractional overlap prevents subpixel seams on high-DPI displays.
        final right = offsetX + ((col + 1) * cellSize + 0.25).clamp(0.0, side);
        final bottom = offsetY + ((row + 1) * cellSize + 0.25).clamp(0.0, side);
        canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), fgPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ApoloQrPainter oldDelegate) {
    return oldDelegate.dataKey != dataKey ||
        oldDelegate.qrImage.moduleCount != qrImage.moduleCount ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
