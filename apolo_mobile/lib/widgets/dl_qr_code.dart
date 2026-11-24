import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// Encoded destination types supported by Apolo profile & listing QR codes.
enum ApoloQrTargetType { user, handle, ad, external, unknown }

/// Parsed destination payload extracted from an Apolo QR code or manual link.
@immutable
class ApoloQrTarget {
  const ApoloQrTarget({
    required this.type,
    required this.rawValue,
    this.id,
    this.handle,
  });

  final ApoloQrTargetType type;
  final String rawValue;
  final int? id;
  final String? handle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApoloQrTarget &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          rawValue == other.rawValue &&
          id == other.id &&
          handle == other.handle;

  @override
  int get hashCode => Object.hash(type, rawValue, id, handle);
}

/// Parses scanned QR payloads and manual links into [ApoloQrTarget] values.
abstract final class ApoloProfileQrParser {
  static final RegExp _handlePattern = RegExp(r'^@([A-Za-z0-9._-]+)$');
  static final RegExp _handleCharsPattern = RegExp(r'^[A-Za-z0-9._-]+$');

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

      if (scheme == 'apolo') {
        if (host == 'users' && segments.isNotEmpty) {
          final id = int.tryParse(segments.first);
          if (id != null && id > 0) {
            return ApoloQrTarget(
              type: ApoloQrTargetType.user,
              rawValue: trimmed,
              id: id,
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
        if (host.startsWith('@') && host.length > 1) {
          final h = host.substring(1);
          if (_handleCharsPattern.hasMatch(h)) {
            return ApoloQrTarget(
              type: ApoloQrTargetType.handle,
              rawValue: trimmed,
              handle: h,
            );
          }
        }
      }

      if ((scheme == 'http' || scheme == 'https') && host.isNotEmpty) {
        if (host == 'apolo.ma' || host == 'www.apolo.ma') {
          if (segments.length >= 2 && segments[0].toLowerCase() == 'users') {
            final id = int.tryParse(segments[1]);
            if (id != null && id > 0) {
              return ApoloQrTarget(
                type: ApoloQrTargetType.user,
                rawValue: trimmed,
                id: id,
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
          if (segments.length == 1 && segments[0].startsWith('@')) {
            final h = segments[0].substring(1);
            if (h.isNotEmpty && _handleCharsPattern.hasMatch(h)) {
              return ApoloQrTarget(
                type: ApoloQrTargetType.handle,
                rawValue: trimmed,
                handle: h,
              );
            }
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
