import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

@JS('jsQR')
external JSObject? _jsQr(
  JSUint8ClampedArray data,
  int width,
  int height, [
  JSObject? options,
]);

/// Browser helper powering gallery QR decoding, live shutter capture,
/// hardware camera torch on supported mobile browsers, and clean deep-link URLs.
abstract final class QrWebBridge {
  static Completer<bool>? _jsQrLoadCompleter;

  static bool get _hasNativeBarcodeDetector =>
      globalContext.has('BarcodeDetector');

  static Future<bool> _ensureJsQrLoaded() async {
    if (globalContext.has('jsQR')) return true;
    if (_jsQrLoadCompleter != null) return _jsQrLoadCompleter!.future;

    final completer = Completer<bool>();
    _jsQrLoadCompleter = completer;

    try {
      final existing = web.document.getElementById('apolo-jsqr-script');
      if (existing != null) {
        completer.complete(globalContext.has('jsQR'));
        return completer.future;
      }

      final script = web.HTMLScriptElement()
        ..id = 'apolo-jsqr-script'
        ..src = 'https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.min.js'
        ..async = true;

      script.onload = ((JSAny _) {
        if (!completer.isCompleted) {
          completer.complete(globalContext.has('jsQR'));
        }
      }).toJS;

      script.onerror = ((JSAny _) {
        _jsQrLoadCompleter = null;
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }).toJS;

      web.document.head?.appendChild(script);
    } catch (_) {
      _jsQrLoadCompleter = null;
      if (!completer.isCompleted) completer.complete(false);
    }

    return completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () {
        _jsQrLoadCompleter = null;
        return globalContext.has('jsQR');
      },
    );
  }

  static Future<String?> _detectWithNativeDetector(JSAny source) async {
    if (!_hasNativeBarcodeDetector) return null;
    try {
      final ctor = globalContext['BarcodeDetector'];
      if (ctor == null || !ctor.isA<JSFunction>()) return null;

      final opts = JSObject();
      opts['formats'] = <JSString>['qr_code'.toJS].toJS;
      final detector = (ctor as JSFunction).callAsConstructor<JSObject>(opts);
      final promise =
          detector.callMethod<JSPromise<JSArray<JSObject>>>('detect'.toJS, source);
      final results = (await promise.toDart).toDart;
      for (final item in results) {
        final rawProp = item['rawValue'];
        if (rawProp != null && rawProp.isA<JSString>()) {
          final raw = (rawProp as JSString).toDart.trim();
          if (raw.isNotEmpty) return raw;
        }
      }
    } catch (_) {}
    return null;
  }

  static String? _decodeCanvasWithJsQr(
    web.HTMLCanvasElement canvas,
    web.CanvasRenderingContext2D ctx,
    int width,
    int height,
  ) {
    if (!globalContext.has('jsQR') || width <= 0 || height <= 0) return null;
    try {
      final imageData = ctx.getImageData(0, 0, width, height);
      final opts = JSObject();
      opts['inversionAttempts'] = 'attemptBoth'.toJS;
      final res = _jsQr(imageData.data, width, height, opts);
      if (res != null) {
        final dataProp = res['data'];
        if (dataProp != null && dataProp.isA<JSString>()) {
          final text = (dataProp as JSString).toDart.trim();
          if (text.isNotEmpty) return text;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Decodes a QR code from raw picked image bytes (PNG/JPEG/WebP/HEIC).
  static Future<String?> decodeImageBytes(Uint8List bytes) async {
    if (bytes.isEmpty) return null;
    String? objectUrl;
    try {
      final blob = web.Blob(<JSAny>[bytes.toJS].toJS);
      objectUrl = web.URL.createObjectURL(blob);

      final img = web.HTMLImageElement();
      final loadCompleter = Completer<bool>();
      img.onload = ((JSAny _) {
        if (!loadCompleter.isCompleted) loadCompleter.complete(true);
      }).toJS;
      img.onerror = ((JSAny _) {
        if (!loadCompleter.isCompleted) loadCompleter.complete(false);
      }).toJS;
      img.src = objectUrl;

      final loaded = await loadCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
      if (!loaded || img.naturalWidth <= 0 || img.naturalHeight <= 0) {
        return null;
      }

      final nativeHit = await _detectWithNativeDetector(img);
      if (nativeHit != null && nativeHit.isNotEmpty) {
        return nativeHit;
      }

      if (!await _ensureJsQrLoaded()) return null;

      final srcW = img.naturalWidth;
      final srcH = img.naturalHeight;
      for (final maxDim in <int>[1200, 720, 1800]) {
        final scale = (srcW > maxDim || srcH > maxDim)
            ? (maxDim / (srcW > srcH ? srcW : srcH))
            : 1.0;
        final w = (srcW * scale).round().clamp(1, 2400);
        final h = (srcH * scale).round().clamp(1, 2400);

        final canvas = web.HTMLCanvasElement()
          ..width = w
          ..height = h;
        final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
        if (ctx == null) continue;
        ctx.drawImage(img, 0, 0, w, h);

        final decoded = _decodeCanvasWithJsQr(canvas, ctx, w, h);
        if (decoded != null && decoded.isNotEmpty) {
          return decoded;
        }
      }
    } catch (_) {
    } finally {
      if (objectUrl != null) {
        try {
          web.URL.revokeObjectURL(objectUrl);
        } catch (_) {}
      }
    }
    return null;
  }

  static web.HTMLVideoElement? _findActiveScannerVideo() {
    try {
      final videos = web.document.querySelectorAll('video');
      for (var i = videos.length - 1; i >= 0; i--) {
        final node = videos.item(i);
        if (node != null && node.isA<web.HTMLVideoElement>()) {
          final video = node as web.HTMLVideoElement;
          if (video.videoWidth > 0 && video.videoHeight > 0) {
            return video;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Captures the active `<video>` frame immediately when the user presses Shutter.
  static Future<String?> captureLiveVideoQr() async {
    final video = _findActiveScannerVideo();
    if (video == null) return null;

    final nativeHit = await _detectWithNativeDetector(video);
    if (nativeHit != null && nativeHit.isNotEmpty) {
      return nativeHit;
    }

    if (!await _ensureJsQrLoaded()) return null;
    try {
      final vw = video.videoWidth;
      final vh = video.videoHeight;
      if (vw <= 0 || vh <= 0) return null;

      final canvas = web.HTMLCanvasElement()
        ..width = vw
        ..height = vh;
      final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
      if (ctx == null) return null;
      ctx.drawImage(video, 0, 0, vw, vh);
      return _decodeCanvasWithJsQr(canvas, ctx, vw, vh);
    } catch (_) {
      return null;
    }
  }

  /// Toggles hardware LED torch on mobile browsers supporting ImageCapture torch
  /// constraints (Android Chrome & iOS Safari 17.4+). Returns the new state, or
  /// `null` if hardware torch is unsupported on this device/browser.
  static Future<bool?> toggleWebTorch(bool currentState) async {
    try {
      final video = _findActiveScannerVideo();
      final mediaObj = video?.srcObject;
      if (mediaObj == null || !mediaObj.isA<web.MediaStream>()) return null;

      final stream = mediaObj as web.MediaStream;
      final tracks = stream.getVideoTracks().toDart;
      if (tracks.isEmpty) return null;
      final track = tracks.first;

      final caps = track.callMethod<JSObject>('getCapabilities'.toJS);
      final torchCap = caps['torch'];
      final supported = torchCap != null &&
          torchCap.isA<JSBoolean>() &&
          (torchCap as JSBoolean).toDart;
      if (!supported) return null;

      final nextState = !currentState;
      final torchEntry = JSObject();
      torchEntry['torch'] = nextState.toJS;
      final constraints = JSObject();
      constraints['advanced'] = <JSObject>[torchEntry].toJS;

      final promise = track.callMethod<JSPromise<JSAny?>>(
        'applyConstraints'.toJS,
        constraints,
      );
      await promise.toDart;
      return nextState;
    } catch (_) {
      return null;
    }
  }

  /// Resets deep-link paths (`/users/77`, `/@handle`) back to `/` once consumed
  /// so refreshing or navigating back stays clean inside the SPA.
  static void clearDeepLinkPathFromAddressBar() {
    try {
      final path = web.window.location.pathname;
      final search = web.window.location.search;
      if ((path.isNotEmpty && path != '/') || search.isNotEmpty) {
        web.window.history.replaceState(null, '', '/');
      }
    } catch (_) {}
  }
}
