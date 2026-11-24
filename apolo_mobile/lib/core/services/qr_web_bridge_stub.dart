import 'dart:typed_data';

/// Non-web stub for browser QR image decoding, frame capture, torch, and URL cleanup.
abstract final class QrWebBridge {
  static Future<String?> decodeImageBytes(Uint8List bytes) async => null;

  static Future<String?> captureLiveVideoQr() async => null;

  static Future<bool?> toggleWebTorch(bool currentState) async => null;

  static void clearDeepLinkPathFromAddressBar() {}
}
