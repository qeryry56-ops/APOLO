import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Non-web stub for browser QR camera view, image decoding, torch, and URL cleanup.
abstract final class QrWebBridge {
  static Widget? buildWebScannerView({
    required int sessionKey,
    required void Function(String code) onDetect,
    required void Function(String status) onStatus,
  }) =>
      null;

  static void stopWebScanner() {}

  static Future<String?> decodeImageBytes(Uint8List bytes) async => null;

  static Future<String?> captureLiveVideoQr() async => null;

  static Future<bool?> toggleWebTorch(bool currentState) async => null;

  static void clearDeepLinkPathFromAddressBar() {}
}
