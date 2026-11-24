import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

/// Flutter Web JS-interop bridge to `window.ApoloQr` defined in `web/index.html`.
abstract final class QrWebBridge {
  static JSObject? get _qr =>
      globalContext.getProperty<JSObject?>('ApoloQr'.toJS);

  static Future<String?> decodeImageBytes(Uint8List bytes) async {
    if (bytes.isEmpty) return null;
    try {
      final b64 = base64Encode(bytes);
      final promise =
          _qr?.callMethod<JSPromise<JSString?>?>('decodeBase64'.toJS, b64.toJS);
      if (promise == null) return null;
      final res = await promise.toDart;
      final text = res?.toDart.trim() ?? '';
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> captureLiveVideoQr() async {
    try {
      final promise =
          _qr?.callMethod<JSPromise<JSString?>?>('captureVideoFrame'.toJS);
      if (promise == null) return null;
      final res = await promise.toDart;
      final text = res?.toDart.trim() ?? '';
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  static Future<bool?> toggleWebTorch(bool currentState) async {
    try {
      final promise = _qr?.callMethod<JSPromise<JSString?>?>(
        'toggleTorch'.toJS,
        currentState.toJS,
      );
      if (promise == null) return null;
      final res = (await promise.toDart)?.toDart ?? '';
      if (res == 'on') return true;
      if (res == 'off') return false;
      return null;
    } catch (_) {
      return null;
    }
  }

  static void clearDeepLinkPathFromAddressBar() {
    try {
      _qr?.callMethod<JSAny?>('clearDeepLinkPath'.toJS);
    } catch (_) {}
  }
}
