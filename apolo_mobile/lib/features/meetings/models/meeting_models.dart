/// Domain models for Apolo.ma's SFU Group Meeting Module (LiveKit SFU).
/// Supports 8 to 25+ participants with SVC/Simulcast, STUN/TURN/TURNS, and E2EE.
library;

enum MeetingConnectionPhase {
  idle,
  preparingLobby,
  fetchingToken,
  connectingSfu,
  connected,
  reconnecting,
  ended,
  failed,
}

enum MeetingNetworkTier {
  excellent,
  good,
  poor,
  lost,
  unknown,
}

class IceServerDescriptor {
  final List<String> urls;
  final String? username;
  final String? credential;

  const IceServerDescriptor({
    required this.urls,
    this.username,
    this.credential,
  });

  factory IceServerDescriptor.fromJson(Map<String, dynamic> json) {
    final rawUrls = json['urls'];
    final urls = <String>[];
    if (rawUrls is List) {
      for (final u in rawUrls) {
        final s = u?.toString().trim() ?? '';
        if (s.isNotEmpty) urls.add(s);
      }
    } else if (rawUrls is String && rawUrls.trim().isNotEmpty) {
      urls.add(rawUrls.trim());
    }
    return IceServerDescriptor(
      urls: urls,
      username: json['username']?.toString(),
      credential: json['credential']?.toString(),
    );
  }
}

class MeetingMediaPolicy {
  final String preferredVideoCodec;
  final String svcScalabilityMode;
  final bool simulcastEnabled;
  final bool dynacastEnabled;
  final bool adaptiveStreamEnabled;
  final int maxVisibleVideoTilesPerPage;

  const MeetingMediaPolicy({
    this.preferredVideoCodec = 'vp9',
    this.svcScalabilityMode = 'L3T3_KEY',
    this.simulcastEnabled = true,
    this.dynacastEnabled = true,
    this.adaptiveStreamEnabled = true,
    this.maxVisibleVideoTilesPerPage = 6,
  });

  factory MeetingMediaPolicy.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MeetingMediaPolicy();
    return MeetingMediaPolicy(
      preferredVideoCodec:
          (json['preferred_video_codec'] ?? 'vp9').toString().toLowerCase(),
      svcScalabilityMode: (json['svc_scalability_mode'] ?? 'L3T3_KEY').toString(),
      simulcastEnabled: json['simulcast_enabled'] != false,
      dynacastEnabled: json['dynacast_enabled'] != false,
      adaptiveStreamEnabled: json['adaptive_stream_enabled'] != false,
      maxVisibleVideoTilesPerPage: int.tryParse(
              '${json['max_visible_video_tiles_per_page'] ?? 6}')
          ?.clamp(2, 12) ??
          6,
    );
  }
}

class MeetingRoomSummary {
  final String roomCode;
  final String title;
  final int hostUserId;
  final int? channelId;
  final int? adId;
  final int maxParticipants;
  final int activeParticipantsCount;
  final bool e2eeEnabled;
  final String? e2eeKeyHint;
  final bool isLocked;
  final bool muteOnEntry;
  final String region;
  final String status;
  final String myRole;

  const MeetingRoomSummary({
    required this.roomCode,
    required this.title,
    required this.hostUserId,
    this.channelId,
    this.adId,
    required this.maxParticipants,
    required this.activeParticipantsCount,
    required this.e2eeEnabled,
    this.e2eeKeyHint,
    required this.isLocked,
    required this.muteOnEntry,
    required this.region,
    required this.status,
    required this.myRole,
  });

  bool get isHostOrCohost => myRole == 'host' || myRole == 'cohost';
  bool get isPrimaryHost => myRole == 'host';

  MeetingRoomSummary copyWith({
    bool? isLocked,
    int? activeParticipantsCount,
    String? status,
  }) {
    return MeetingRoomSummary(
      roomCode: roomCode,
      title: title,
      hostUserId: hostUserId,
      channelId: channelId,
      adId: adId,
      maxParticipants: maxParticipants,
      activeParticipantsCount:
          activeParticipantsCount ?? this.activeParticipantsCount,
      e2eeEnabled: e2eeEnabled,
      e2eeKeyHint: e2eeKeyHint,
      isLocked: isLocked ?? this.isLocked,
      muteOnEntry: muteOnEntry,
      region: region,
      status: status ?? this.status,
      myRole: myRole,
    );
  }

  factory MeetingRoomSummary.fromJson(Map<String, dynamic> json) {
    return MeetingRoomSummary(
      roomCode: (json['room_code'] ?? '').toString(),
      title: (json['title'] ?? 'اجتماع Apolo').toString(),
      hostUserId: int.tryParse('${json['host_user_id'] ?? 0}') ?? 0,
      channelId: int.tryParse('${json['channel_id'] ?? ''}'),
      adId: int.tryParse('${json['ad_id'] ?? ''}'),
      maxParticipants: int.tryParse('${json['max_participants'] ?? 25}') ?? 25,
      activeParticipantsCount:
          int.tryParse('${json['active_participants_count'] ?? 0}') ?? 0,
      e2eeEnabled: json['e2ee_enabled'] == true,
      e2eeKeyHint: json['e2ee_key_hint']?.toString(),
      isLocked: json['is_locked'] == true,
      muteOnEntry: json['mute_on_entry'] == true,
      region: (json['region'] ?? 'ma-casablanca').toString(),
      status: (json['status'] ?? 'active').toString(),
      myRole: (json['my_role'] ?? 'participant').toString(),
    );
  }
}

class JoinMeetingCredentials {
  final MeetingRoomSummary room;
  final String wsUrl;
  final String accessToken;
  final int expiresAtEpochSeconds;
  final int ttlSeconds;
  final String participantIdentity;
  final String iceTransportPolicy;
  final List<IceServerDescriptor> iceServers;
  final MeetingMediaPolicy mediaPolicy;

  const JoinMeetingCredentials({
    required this.room,
    required this.wsUrl,
    required this.accessToken,
    required this.expiresAtEpochSeconds,
    required this.ttlSeconds,
    required this.participantIdentity,
    required this.iceTransportPolicy,
    required this.iceServers,
    required this.mediaPolicy,
  });

  factory JoinMeetingCredentials.fromJson(Map<String, dynamic> json) {
    final roomMap = Map<String, dynamic>.from(json['room'] as Map? ?? const {});
    final sfuMap = Map<String, dynamic>.from(json['sfu'] as Map? ?? const {});
    final rawIce = sfuMap['ice_servers'];
    final iceList = <IceServerDescriptor>[];
    if (rawIce is List) {
      for (final item in rawIce) {
        if (item is Map) {
          final parsed =
              IceServerDescriptor.fromJson(Map<String, dynamic>.from(item));
          if (parsed.urls.isNotEmpty) {
            iceList.add(parsed);
          }
        }
      }
    }

    final rawPolicy = sfuMap['media_policy'];
    return JoinMeetingCredentials(
      room: MeetingRoomSummary.fromJson(roomMap),
      wsUrl: (sfuMap['ws_url'] ?? '').toString(),
      accessToken: (sfuMap['access_token'] ?? '').toString(),
      expiresAtEpochSeconds:
          int.tryParse('${sfuMap['expires_at'] ?? 0}') ?? 0,
      ttlSeconds: int.tryParse('${sfuMap['ttl_seconds'] ?? 900}') ?? 900,
      participantIdentity:
          (sfuMap['participant_identity'] ?? '').toString(),
      iceTransportPolicy:
          (sfuMap['ice_transport_policy'] ?? 'all').toString(),
      iceServers: iceList,
      mediaPolicy: MeetingMediaPolicy.fromJson(
        rawPolicy is Map ? Map<String, dynamic>.from(rawPolicy) : null,
      ),
    );
  }
}
