import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/l10n.dart';
import '../models/meeting_models.dart';

/// Stateless HTTP Control Plane client for Apolo.ma Group Meetings (`/api/v1/meetings`).
/// Uses the shared Sanctum-authenticated [ApiClient] and never handles raw SFU API secrets.
class MeetingApiService {
  final ApiClient _api;

  MeetingApiService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<MeetingRoomSummary> createMeeting({
    String? title,
    int? channelId,
    int? adId,
    int maxParticipants = 25,
    bool e2eeEnabled = false,
    String? e2eeKeyHint,
    bool muteOnEntry = false,
    String region = 'ma-casablanca',
  }) async {
    final response = await _api.dio.post(
      '/meetings',
      data: <String, dynamic>{
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (channelId != null) 'channel_id': channelId,
        if (adId != null) 'ad_id': adId,
        'max_participants': maxParticipants,
        'e2ee_enabled': e2eeEnabled,
        if (e2eeEnabled && e2eeKeyHint != null) 'e2ee_key_hint': e2eeKeyHint,
        'mute_on_entry': muteOnEntry,
        'region': region,
      },
    );

    final body = _unwrapMap(response.data);
    final data = Map<String, dynamic>.from(body['data'] as Map? ?? const {});
    return MeetingRoomSummary.fromJson(data);
  }

  Future<MeetingRoomSummary> getMeeting(String roomCode) async {
    final normalized = roomCode.trim().toLowerCase();
    final response = await _api.dio.get('/meetings/$normalized');
    final body = _unwrapMap(response.data);
    final data = Map<String, dynamic>.from(body['data'] as Map? ?? const {});
    return MeetingRoomSummary.fromJson(data);
  }

  Future<JoinMeetingCredentials> joinMeeting(
    String roomCode, {
    String? displayName,
    String? region,
  }) async {
    final normalized = roomCode.trim().toLowerCase();
    final response = await _api.dio.post(
      '/meetings/$normalized/join',
      data: <String, dynamic>{
        if (displayName != null && displayName.trim().isNotEmpty)
          'display_name': displayName.trim(),
        if (region != null && region.isNotEmpty) 'region': region,
      },
    );

    final body = _unwrapMap(response.data);
    final data = Map<String, dynamic>.from(body['data'] as Map? ?? const {});
    return JoinMeetingCredentials.fromJson(data);
  }

  Future<JoinMeetingCredentials> refreshToken(String roomCode) async {
    final normalized = roomCode.trim().toLowerCase();
    final response = await _api.dio.post('/meetings/$normalized/token/refresh');
    final body = _unwrapMap(response.data);
    final data = Map<String, dynamic>.from(body['data'] as Map? ?? const {});
    return JoinMeetingCredentials.fromJson(data);
  }

  Future<void> leaveMeeting(String roomCode) async {
    final normalized = roomCode.trim().toLowerCase();
    try {
      await _api.dio.post('/meetings/$normalized/leave');
    } on DioException {
      // Best-effort leave notification; SFU webhook also cleans up participant state.
    }
  }

  Future<Map<String, dynamic>> moderate({
    required String roomCode,
    required String action,
    int? targetUserId,
    String? trackSid,
  }) async {
    final normalized = roomCode.trim().toLowerCase();
    final response = await _api.dio.post(
      '/meetings/$normalized/moderate',
      data: <String, dynamic>{
        'action': action,
        if (targetUserId != null) 'target_user_id': targetUserId,
        if (trackSid != null && trackSid.isNotEmpty) 'track_sid': trackSid,
      },
    );

    return _unwrapMap(response.data);
  }

  Future<void> endMeetingForAll(String roomCode) async {
    final normalized = roomCode.trim().toLowerCase();
    await _api.dio.post('/meetings/$normalized/end');
  }

  static String extractReadableError(Object error, MeetingStringsFallback fb) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        final msg = (data['message'] as String).trim();
        if (msg.isNotEmpty) return msg;
      }
      if (status == 401) return fb.unauthorized;
      if (status == 403) return fb.forbidden;
      if (status == 410) return fb.ended;
      if (status == 423) return fb.locked;
      if (status == 429) return fb.full;
    }
    return fb.generic;
  }

  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const <String, dynamic>{};
  }
}

class MeetingStringsFallback {
  final String unauthorized;
  final String forbidden;
  final String ended;
  final String locked;
  final String full;
  final String generic;

  const MeetingStringsFallback({
    required this.unauthorized,
    required this.forbidden,
    required this.ended,
    required this.locked,
    required this.full,
    required this.generic,
  });

  factory MeetingStringsFallback.forLang(String lang) {
    if (lang == 'ar') {
      return const MeetingStringsFallback(
        unauthorized: 'يرجى تسجيل الدخول للانضمام إلى الاجتماع.',
        forbidden: 'ليست لديك صلاحية لدخول هذه الغرفة.',
        ended: 'انتهى هذا الاجتماع بالفعل.',
        locked: 'الغرفة مقفلة حالياً من طرف المضيف.',
        full: 'اكتمل العدد الأقصى للمشاركين في الغرفة.',
        generic: 'تعذر الاتصال بخدمة الاجتماعات، تحقق من الإنترنت.',
      );
    }
    if (lang == 'en') {
      return MeetingStringsFallback(
        unauthorized: appL10n.meetingSignInRequiredError,
        forbidden: appL10n.meetingPermissionDeniedError,
        ended: appL10n.meetingAlreadyEndedError,
        locked: appL10n.meetingRoomLockedError,
        full: appL10n.meetingMaxCapacityError,
        generic: appL10n.meetingServiceUnreachableError,
      );
    }
    return const MeetingStringsFallback(
      unauthorized: 'Veuillez vous connecter pour rejoindre la réunion.',
      forbidden: 'Accès refusé à cette réunion.',
      ended: 'Cette réunion est déjà terminée.',
      locked: 'Cette salle est verrouillée par l\'hôte.',
      full: 'La capacité maximale de la réunion est atteinte.',
      generic: 'Impossible de joindre le service de réunion.',
    );
  }
}
