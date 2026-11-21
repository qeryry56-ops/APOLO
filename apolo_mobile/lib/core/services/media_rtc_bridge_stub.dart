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

/// Non-web fallback stub for Voice Notes & WebRTC Calls.
class MediaRtcBridge {
  static bool get isVoiceSupported => false;

  static Future<bool> startVoiceRecording() async => false;

  static Future<VoiceRecordResult?> stopVoiceRecording() async => null;

  static Future<void> cancelVoiceRecording() async {}

  static Future<void> playVoiceMessage(
    String id,
    String base64,
    String mime, {
    void Function(double progress)? onProgress,
    void Function()? onEnded,
  }) async {
    onEnded?.call();
  }

  static void pauseVoiceMessage() {}

  static bool get isRtcSupported => false;

  static Future<String?> rtcStartCaller({
    required bool isVideo,
    required void Function(String candidateJson) onIceCandidate,
    required void Function(String state) onConnectionState,
  }) async =>
      null;

  static Future<void> rtcApplyRemoteAnswer(String answerJson) async {}

  static Future<String?> rtcAnswerCallee({
    required String offerJson,
    required bool isVideo,
    required void Function(String candidateJson) onIceCandidate,
    required void Function(String state) onConnectionState,
  }) async =>
      null;

  static Future<void> rtcAddIceCandidate(String candidateJson) async {}

  static void rtcSetMuted(bool muted) {}

  static void rtcSetCameraEnabled(bool enabled) {}

  static void rtcEndCall() {}

  static void playMessageSound() {}

  static void playNotificationSound() {}

  static void startRingtone() {}

  static void stopRingtone() {}

  static void requestBrowserNotificationPermission() {}

  static void showBrowserNotification(String title, String body) {}
}
