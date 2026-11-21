import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

class VoiceRecordResult {
  final String base64;
  final String mime;
  final int durationSec;

  const VoiceRecordResult({
    required this.base64,
    required this.mime,
    required this.durationSec,
  });
}

/// Flutter Web JS-interop bridge to `window.ApoloVoice` and `window.ApoloRTC`.
class MediaRtcBridge {
  static JSObject? get _voice =>
      globalContext.getProperty<JSObject?>('ApoloVoice'.toJS);

  static JSObject? get _rtc =>
      globalContext.getProperty<JSObject?>('ApoloRTC'.toJS);

  static JSObject? get _alerts =>
      globalContext.getProperty<JSObject?>('ApoloAlerts'.toJS);

  // ───────────────────────── Voice Notes ─────────────────────────

  static bool get isVoiceSupported {
    try {
      final res = _voice?.callMethod<JSBoolean?>('isSupported'.toJS);
      return res?.toDart ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> startVoiceRecording() async {
    try {
      final promise =
          _voice?.callMethod<JSPromise<JSBoolean>?>('startRecording'.toJS);
      if (promise == null) return false;
      final ok = await promise.toDart;
      return ok.toDart;
    } catch (_) {
      return false;
    }
  }

  static Future<VoiceRecordResult?> stopVoiceRecording() async {
    try {
      final promise =
          _voice?.callMethod<JSPromise<JSString>?>('stopRecording'.toJS);
      if (promise == null) return null;
      final jsonStr = (await promise.toDart).toDart;
      if (jsonStr.isEmpty) return null;
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) return null;
      final b64 = (decoded['base64'] ?? '').toString();
      if (b64.isEmpty) return null;
      return VoiceRecordResult(
        base64: b64,
        mime: (decoded['mime'] ?? 'audio/webm').toString(),
        durationSec: int.tryParse('${decoded['durationSec'] ?? 1}') ?? 1,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> cancelVoiceRecording() async {
    try {
      _voice?.callMethod<JSAny?>('cancelRecording'.toJS);
    } catch (_) {}
  }

  static Future<void> playVoiceMessage(
    String id,
    String base64,
    String mime, {
    void Function(double progress)? onProgress,
    void Function()? onEnded,
  }) async {
    try {
      void progressCb(JSNumber p) => onProgress?.call(p.toDartDouble);
      void endedCb() => onEnded?.call();
      _voice?.callMethodVarArgs<JSAny?>(
        'play'.toJS,
        <JSAny?>[
          id.toJS,
          base64.toJS,
          mime.toJS,
          progressCb.toJS,
          endedCb.toJS,
        ],
      );
    } catch (_) {
      onEnded?.call();
    }
  }

  static void pauseVoiceMessage() {
    try {
      _voice?.callMethod<JSAny?>('pause'.toJS);
    } catch (_) {}
  }

  // ───────────────────────── WebRTC Calls ─────────────────────────

  static bool get isRtcSupported {
    try {
      final res = _rtc?.callMethod<JSBoolean?>('isSupported'.toJS);
      return res?.toDart ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> rtcStartCaller({
    required bool isVideo,
    required void Function(String candidateJson) onIceCandidate,
    required void Function(String state) onConnectionState,
  }) async {
    try {
      void iceCb(JSString c) => onIceCandidate(c.toDart);
      void stateCb(JSString s) => onConnectionState(s.toDart);
      final promise = _rtc?.callMethodVarArgs<JSPromise<JSString>?>(
        'startCaller'.toJS,
        <JSAny?>[isVideo.toJS, iceCb.toJS, stateCb.toJS],
      );
      if (promise == null) return null;
      final sdp = (await promise.toDart).toDart;
      return sdp.isNotEmpty ? sdp : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> rtcApplyRemoteAnswer(String answerJson) async {
    try {
      final promise = _rtc?.callMethodVarArgs<JSPromise<JSAny?>?>(
        'applyRemoteAnswer'.toJS,
        <JSAny?>[answerJson.toJS],
      );
      if (promise != null) await promise.toDart;
    } catch (_) {}
  }

  static Future<String?> rtcAnswerCallee({
    required String offerJson,
    required bool isVideo,
    required void Function(String candidateJson) onIceCandidate,
    required void Function(String state) onConnectionState,
  }) async {
    try {
      void iceCb(JSString c) => onIceCandidate(c.toDart);
      void stateCb(JSString s) => onConnectionState(s.toDart);
      final promise = _rtc?.callMethodVarArgs<JSPromise<JSString>?>(
        'answerCallee'.toJS,
        <JSAny?>[offerJson.toJS, isVideo.toJS, iceCb.toJS, stateCb.toJS],
      );
      if (promise == null) return null;
      final sdp = (await promise.toDart).toDart;
      return sdp.isNotEmpty ? sdp : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> rtcAddIceCandidate(String candidateJson) async {
    try {
      final promise = _rtc?.callMethodVarArgs<JSPromise<JSAny?>?>(
        'addIceCandidate'.toJS,
        <JSAny?>[candidateJson.toJS],
      );
      if (promise != null) await promise.toDart;
    } catch (_) {}
  }

  static void rtcSetMuted(bool muted) {
    try {
      _rtc?.callMethodVarArgs<JSAny?>('setMuted'.toJS, <JSAny?>[muted.toJS]);
    } catch (_) {}
  }

  static void rtcSetCameraEnabled(bool enabled) {
    try {
      _rtc?.callMethodVarArgs<JSAny?>(
          'setCameraEnabled'.toJS, <JSAny?>[enabled.toJS]);
    } catch (_) {}
  }

  static void rtcEndCall() {
    try {
      _rtc?.callMethod<JSAny?>('endCall'.toJS);
    } catch (_) {}
  }

  // ───────────────────────── Sounds, Ringtone & Browser Notifications ─────────────────────────

  static void playMessageSound() {
    try {
      _alerts?.callMethod<JSAny?>('playMessageSound'.toJS);
    } catch (_) {}
  }

  static void playNotificationSound() {
    try {
      _alerts?.callMethod<JSAny?>('playNotificationSound'.toJS);
    } catch (_) {}
  }

  static void startRingtone() {
    try {
      _alerts?.callMethod<JSAny?>('startRingtone'.toJS);
    } catch (_) {}
  }

  static void stopRingtone() {
    try {
      _alerts?.callMethod<JSAny?>('stopRingtone'.toJS);
    } catch (_) {}
  }

  static void requestBrowserNotificationPermission() {
    try {
      _alerts?.callMethod<JSAny?>('requestPermission'.toJS);
    } catch (_) {}
  }

  static void showBrowserNotification(String title, String body) {
    try {
      _alerts?.callMethodVarArgs<JSAny?>(
        'showBrowserNotification'.toJS,
        <JSAny?>[title.toJS, body.toJS],
      );
    } catch (_) {}
  }
}
