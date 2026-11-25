import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/meeting_models.dart';
import '../services/meeting_api_service.dart';
import '../services/meeting_e2ee_manager.dart';

/// View representation of a participant tile inside the SFU call grid.
class MeetingParticipantTileData {
  final Participant participant;
  final String identity;
  final int? userId;
  final String displayName;
  final String? avatarUrl;
  final String role;
  final bool isLocal;
  final bool isSpeaking;
  final bool isMicEnabled;
  final bool isCameraEnabled;
  final bool isScreenSharing;
  final VideoTrack? primaryVideoTrack;
  final VideoTrack? screenShareTrack;
  final String? audioTrackSid;
  final MeetingNetworkTier networkTier;

  const MeetingParticipantTileData({
    required this.participant,
    required this.identity,
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.role,
    required this.isLocal,
    required this.isSpeaking,
    required this.isMicEnabled,
    required this.isCameraEnabled,
    required this.isScreenSharing,
    required this.primaryVideoTrack,
    required this.screenShareTrack,
    required this.audioTrackSid,
    required this.networkTier,
  });

  bool get isHostOrCohost => role == 'host' || role == 'cohost';
}

/// Production SFU Meeting Controller for Apolo.ma (8–25+ group participants).
///
/// Architectural guarantees:
/// - Connects to LiveKit SFU (single uplink per client, zero P2P mesh, zero MCU mixing)
/// - Enables SVC (`L3T3_KEY`) + 3-layer Simulcast + Dynacast (`dynacast: true`)
/// - Enables AdaptiveStream (`adaptiveStream: true`) + viewport pagination (max 6
///   decoded video tiles per mobile page; off-page video streams are paused at the
///   SFU while keeping Opus audio active to prevent thermal throttling & battery drain)
/// - Configures UDP-first ICE with STUN + TURN/UDP + TURNS/TLS 443 fallback
/// - Supports AES-GCM End-to-End Encryption (E2EE) with forward-secrecy ratcheting
class MeetingRoomController extends ChangeNotifier {
  final MeetingApiService _apiService;
  final MeetingE2eeManager _e2eeManager;
  final String languageCode;

  Room? _room;
  EventsListener<RoomEvent>? _roomListener;
  LocalVideoTrack? _lobbyPreviewTrack;
  Timer? _tokenRefreshTimer;
  Timer? _callDurationTimer;

  MeetingRoomSummary? _roomSummary;
  JoinMeetingCredentials? _credentials;
  MeetingConnectionPhase _phase = MeetingConnectionPhase.idle;
  MeetingNetworkTier _localNetworkTier = MeetingNetworkTier.unknown;
  String? _errorMessage;

  bool _initialMicEnabled = true;
  bool _initialCameraEnabled = true;
  bool _isMicEnabled = true;
  bool _isCameraEnabled = true;
  bool _isScreenShareEnabled = false;
  bool _isSpeakerOn = true;
  bool _isAudioOnlyMode = false;
  bool _lowBandwidthDetected = false;
  CameraPosition _cameraPosition = CameraPosition.front;

  String? _e2eeSecretKey;
  bool _e2eeActive = false;

  int _currentPageIndex = 0;
  String? _pinnedParticipantIdentity;
  Duration _elapsed = Duration.zero;
  int _consecutivePoorQualitySamples = 0;

  MeetingRoomController({
    MeetingApiService? apiService,
    MeetingE2eeManager? e2eeManager,
    this.languageCode = 'ar',
  })  : _apiService = apiService ?? MeetingApiService(),
        _e2eeManager = e2eeManager ?? MeetingE2eeManager();

  // ───────────────────────── Public Getters ─────────────────────────

  Room? get room => _room;
  MeetingRoomSummary? get roomSummary => _roomSummary;
  MeetingConnectionPhase get phase => _phase;
  MeetingNetworkTier get localNetworkTier => _localNetworkTier;
  String? get errorMessage => _errorMessage;
  LocalVideoTrack? get lobbyPreviewTrack => _lobbyPreviewTrack;

  bool get initialMicEnabled => _initialMicEnabled;
  bool get initialCameraEnabled => _initialCameraEnabled;
  bool get isMicEnabled => _isMicEnabled;
  bool get isCameraEnabled => _isCameraEnabled;
  bool get isScreenShareEnabled => _isScreenShareEnabled;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isAudioOnlyMode => _isAudioOnlyMode;
  bool get lowBandwidthDetected => _lowBandwidthDetected;
  bool get e2eeActive => _e2eeActive;
  int get e2eeRatchetGeneration => _e2eeManager.ratchetGeneration;
  String? get e2eeSecretKey => _e2eeSecretKey;
  CameraPosition get cameraPosition => _cameraPosition;
  Duration get elapsed => _elapsed;
  String? get pinnedParticipantIdentity => _pinnedParticipantIdentity;

  int get maxTilesPerPage =>
      _credentials?.mediaPolicy.maxVisibleVideoTilesPerPage ?? 6;

  List<MeetingParticipantTileData> get allParticipants =>
      _buildSortedParticipantList();

  int get totalParticipantCount => allParticipants.length;

  int get totalPages {
    final total = totalParticipantCount;
    if (total == 0) return 1;
    return ((total - 1) ~/ maxTilesPerPage) + 1;
  }

  int get currentPageIndex => _currentPageIndex.clamp(0, totalPages - 1);

  List<MeetingParticipantTileData> get visiblePageParticipants {
    final all = allParticipants;
    if (all.isEmpty) return const [];
    final safePage = currentPageIndex;
    final start = safePage * maxTilesPerPage;
    if (start >= all.length) return all.take(maxTilesPerPage).toList();
    final end = (start + maxTilesPerPage).clamp(0, all.length);
    return all.sublist(start, end);
  }

  MeetingParticipantTileData? get spotlightParticipant {
    final all = allParticipants;
    if (all.isEmpty) return null;
    if (_pinnedParticipantIdentity != null) {
      for (final p in all) {
        if (p.identity == _pinnedParticipantIdentity) return p;
      }
    }
    for (final p in all) {
      if (p.isScreenSharing) return p;
    }
    for (final p in all) {
      if (p.isSpeaking) return p;
    }
    return all.first;
  }

  // ───────────────────────── Pre-Join Lobby ─────────────────────────

  Future<void> initializeLobbyPreview({
    bool enableMic = true,
    bool enableCamera = true,
  }) async {
    _phase = MeetingConnectionPhase.preparingLobby;
    _initialMicEnabled = enableMic;
    _initialCameraEnabled = enableCamera;
    _errorMessage = null;
    notifyListeners();

    await _requestMediaPermissions(needCamera: enableCamera);

    if (enableCamera) {
      await _startLobbyCameraPreview();
    }
  }

  Future<void> toggleLobbyMic() async {
    _initialMicEnabled = !_initialMicEnabled;
    notifyListeners();
  }

  Future<void> toggleLobbyCamera() async {
    _initialCameraEnabled = !_initialCameraEnabled;
    if (_initialCameraEnabled) {
      await _requestMediaPermissions(needCamera: true);
      await _startLobbyCameraPreview();
    } else {
      await _stopLobbyCameraPreview();
    }
    notifyListeners();
  }

  Future<void> _startLobbyCameraPreview() async {
    await _stopLobbyCameraPreview();
    try {
      _lobbyPreviewTrack = await LocalVideoTrack.createCameraTrack(
        CameraCaptureOptions(
          cameraPosition: _cameraPosition,
          params: VideoParametersPresets.h720_169,
          maxFrameRate: 30,
        ),
      );
    } catch (_) {
      _initialCameraEnabled = false;
    }
  }

  Future<void> _stopLobbyCameraPreview() async {
    final preview = _lobbyPreviewTrack;
    _lobbyPreviewTrack = null;
    if (preview != null) {
      try {
        await preview.stop();
        await preview.dispose();
      } catch (_) {}
    }
  }

  Future<void> _requestMediaPermissions({required bool needCamera}) async {
    if (kIsWeb) return;
    try {
      final permissions = <Permission>[
        Permission.microphone,
        if (needCamera) Permission.camera,
        Permission.bluetoothConnect,
      ];
      await permissions.request();
    } catch (_) {}
  }

  // ───────────────────────── Create & Join SFU Room ─────────────────────────

  Future<MeetingRoomSummary?> createAndJoinMeeting({
    String? title,
    int? channelId,
    int? adId,
    int maxParticipants = 25,
    bool enableE2ee = false,
    String? customE2eeKey,
    bool muteOnEntry = false,
  }) async {
    _errorMessage = null;
    _phase = MeetingConnectionPhase.fetchingToken;
    notifyListeners();

    try {
      String? secretKey;
      String? keyHint;
      if (enableE2ee) {
        secretKey = (customE2eeKey != null && customE2eeKey.trim().isNotEmpty)
            ? customE2eeKey.trim()
            : MeetingE2eeManager.generateSecretKey();
        keyHint = MeetingE2eeManager.computePublicKeyHint(secretKey);
      }

      final created = await _apiService.createMeeting(
        title: title,
        channelId: channelId,
        adId: adId,
        maxParticipants: maxParticipants,
        e2eeEnabled: enableE2ee,
        e2eeKeyHint: keyHint,
        muteOnEntry: muteOnEntry,
      );

      _roomSummary = created;
      await joinExistingMeeting(
        roomCode: created.roomCode,
        e2eeSecretKey: secretKey,
      );
      return created;
    } catch (e) {
      _phase = MeetingConnectionPhase.failed;
      _errorMessage = MeetingApiService.extractReadableError(
        e,
        MeetingStringsFallback.forLang(languageCode),
      );
      notifyListeners();
      return null;
    }
  }

  Future<bool> joinExistingMeeting({
    required String roomCode,
    String? displayName,
    String? e2eeSecretKey,
  }) async {
    _errorMessage = null;
    _phase = MeetingConnectionPhase.fetchingToken;
    notifyListeners();

    // Release lobby preview camera before opening SFU session track
    await _stopLobbyCameraPreview();

    try {
      final creds = await _apiService.joinMeeting(
        roomCode,
        displayName: displayName,
      );
      _credentials = creds;
      _roomSummary = creds.room;

      if (creds.room.e2eeEnabled) {
        final candidateKey = (e2eeSecretKey ?? _e2eeSecretKey ?? '').trim();
        if (candidateKey.isEmpty) {
          _phase = MeetingConnectionPhase.failed;
          _errorMessage = languageCode == 'ar'
              ? 'هذه الغرفة محمية بتشفير E2EE. يرجى إدخال مفتاح الغرفة السري أو فتح رابط الدعوة الكامل.'
              : 'This room requires an E2EE encryption key.';
          notifyListeners();
          return false;
        }
        if (!MeetingE2eeManager.matchesKeyHint(
          candidateKey,
          creds.room.e2eeKeyHint,
        )) {
          _phase = MeetingConnectionPhase.failed;
          _errorMessage = languageCode == 'ar'
              ? 'مفتاح التشفير E2EE غير مطابق لهذه الغرفة.'
              : 'Invalid E2EE encryption key for this room.';
          notifyListeners();
          return false;
        }
        _e2eeSecretKey = candidateKey;
      }

      await _connectToLiveKitSfu(creds);
      return true;
    } catch (e) {
      _phase = MeetingConnectionPhase.failed;
      _errorMessage = MeetingApiService.extractReadableError(
        e,
        MeetingStringsFallback.forLang(languageCode),
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> _connectToLiveKitSfu(JoinMeetingCredentials creds) async {
    _phase = MeetingConnectionPhase.connectingSfu;
    notifyListeners();

    await _disposeRoomOnly();

    E2EEOptions? e2eeOptions;
    if (creds.room.e2eeEnabled && _e2eeSecretKey != null) {
      e2eeOptions = await _e2eeManager.createOptions(_e2eeSecretKey!);
      _e2eeActive = e2eeOptions != null;
    } else {
      _e2eeActive = false;
    }

    final policy = creds.mediaPolicy;

    // Explicit 3-layer simulcast ladder (180p / 360p / 720p) when falling back
    // from VP9/AV1 SVC to H.264/VP8 on older mobile hardware.
    final roomOptions = RoomOptions(
      adaptiveStream: policy.adaptiveStreamEnabled,
      dynacast: policy.dynacastEnabled,
      fastPublish: true,
      encryption: e2eeOptions,
      defaultCameraCaptureOptions: CameraCaptureOptions(
        cameraPosition: _cameraPosition,
        params: VideoParametersPresets.h720_169,
        maxFrameRate: 30,
      ),
      defaultAudioCaptureOptions: const AudioCaptureOptions(
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
      ),
      defaultAudioPublishOptions: AudioPublishOptions(
        encoding: AudioEncoding.presetSpeech,
        dtx: true,
        red: true,
      ),
      defaultVideoPublishOptions: VideoPublishOptions(
        videoCodec: policy.preferredVideoCodec,
        scalabilityMode: policy.svcScalabilityMode,
        simulcast: policy.simulcastEnabled,
        degradationPreference: DegradationPreference.balanced,
        videoSimulcastLayers: [
          VideoParametersPresets.h180_169,
          VideoParametersPresets.h360_169,
        ],
        backupVideoCodec: const BackupVideoCodec(
          enabled: true,
          codec: 'h264',
          simulcast: true,
        ),
      ),
    );

    final iceServers = creds.iceServers
        .map(
          (s) => RTCIceServer(
            urls: s.urls,
            username: s.username,
            credential: s.credential,
          ),
        )
        .toList();

    final connectOptions = ConnectOptions(
      autoSubscribe: true,
      rtcConfiguration: RTCConfiguration(
        iceServers: iceServers.isNotEmpty ? iceServers : null,
        iceTransportPolicy: creds.iceTransportPolicy == 'relay'
            ? RTCIceTransportPolicy.relay
            : RTCIceTransportPolicy.all,
        encodedInsertableStreams: _e2eeActive ? true : null,
        isDscpEnabled: !kIsWeb,
      ),
    );

    final room = Room(roomOptions: roomOptions);
    _room = room;
    _attachRoomListeners(room);

    // Pre-warm DNS + TLS handshake to regional SFU edge
    unawaited(room.prepareConnection(creds.wsUrl, creds.accessToken));

    await room.connect(
      creds.wsUrl,
      creds.accessToken,
      connectOptions: connectOptions,
    );

    if (AudioManager.instance.canSwitchSpeakerphone) {
      await AudioManager.instance.setSpeakerOutputPreferred(_isSpeakerOn);
    }

    final shouldEnableMic =
        _initialMicEnabled && !(creds.room.muteOnEntry && !creds.room.isHostOrCohost);
    final shouldEnableCam = _initialCameraEnabled && !_isAudioOnlyMode;

    _isMicEnabled = shouldEnableMic;
    _isCameraEnabled = shouldEnableCam;

    try {
      await room.localParticipant?.setMicrophoneEnabled(shouldEnableMic);
    } catch (_) {
      _isMicEnabled = false;
    }

    if (shouldEnableCam) {
      try {
        await room.localParticipant?.setCameraEnabled(true);
      } catch (_) {
        _isCameraEnabled = false;
      }
    }

    _phase = MeetingConnectionPhase.connected;
    _startCallTimers(creds.ttlSeconds);
    _enforceDownlinkViewportBudget();
    notifyListeners();
  }

  void _attachRoomListeners(Room room) {
    final listener = room.createListener();
    _roomListener = listener;

    listener
      ..on<RoomReconnectingEvent>((_) {
        _phase = MeetingConnectionPhase.reconnecting;
        notifyListeners();
      })
      ..on<RoomReconnectedEvent>((_) {
        _phase = MeetingConnectionPhase.connected;
        _enforceDownlinkViewportBudget();
        notifyListeners();
      })
      ..on<RoomDisconnectedEvent>((event) {
        _stopCallTimers();
        _phase = MeetingConnectionPhase.ended;
        if (event.reason == DisconnectReason.participantRemoved) {
          _errorMessage = languageCode == 'ar'
              ? 'قام المضيف بإخراجك من الاجتماع.'
              : 'You were removed from the meeting by the host.';
        } else if (event.reason == DisconnectReason.roomDeleted) {
          _errorMessage = languageCode == 'ar'
              ? 'أنهى المضيف الاجتماع للجميع.'
              : 'The host ended the meeting.';
        }
        notifyListeners();
      })
      ..on<ParticipantConnectedEvent>((_) {
        _enforceDownlinkViewportBudget();
        notifyListeners();
      })
      ..on<ParticipantDisconnectedEvent>((_) {
        if (_currentPageIndex >= totalPages) {
          _currentPageIndex = (totalPages - 1).clamp(0, 999);
        }
        _enforceDownlinkViewportBudget();
        notifyListeners();
      })
      ..on<TrackSubscribedEvent>((_) {
        _enforceDownlinkViewportBudget();
        notifyListeners();
      })
      ..on<TrackUnsubscribedEvent>((_) {
        notifyListeners();
      })
      ..on<TrackMutedEvent>((_) => notifyListeners())
      ..on<TrackUnmutedEvent>((_) => notifyListeners())
      ..on<LocalTrackPublishedEvent>((_) => notifyListeners())
      ..on<LocalTrackUnpublishedEvent>((_) => notifyListeners())
      ..on<ActiveSpeakersChangedEvent>((_) {
        _enforceDownlinkViewportBudget();
        notifyListeners();
      })
      ..on<ParticipantConnectionQualityUpdatedEvent>((event) {
        if (event.participant is LocalParticipant) {
          final quality = event.connectionQuality;
          _localNetworkTier = _mapConnectionQuality(quality);
          if (quality == ConnectionQuality.poor ||
              quality == ConnectionQuality.lost) {
            _consecutivePoorQualitySamples++;
            _lowBandwidthDetected = true;
            // After sustained severe packet loss, step down remote video layers automatically
            if (_consecutivePoorQualitySamples >= 3 && !_isAudioOnlyMode) {
              _enforceDownlinkViewportBudget();
            }
          } else {
            _consecutivePoorQualitySamples = 0;
            _lowBandwidthDetected = false;
          }
        }
        notifyListeners();
      })
      ..on<DataReceivedEvent>((event) {
        _handleControlChannelMessage(event.data);
      });
  }

  // ───────────────────────── Downlink & Thermal Protection ─────────────────────────

  /// Crucial mobile optimization for 8–25+ participant calls:
  /// - Only participants on the active viewport page (max 6 tiles) keep video enabled.
  /// - Spotlight / Active Speaker gets `HIGH` (or `MEDIUM` under poor network).
  /// - Non-spotlight grid tiles get `MEDIUM` (or `LOW` when >= 4 tiles or poor network).
  /// - Off-page participants (e.g. tiles 7..25) have video paused (`pub.disable()`) at
  ///   the SFU so zero video packets are downloaded or hardware-decoded, while their
  ///   Opus audio streams remain 100% active!
  void _enforceDownlinkViewportBudget() {
    final currentRoom = _room;
    if (currentRoom == null) return;

    final visibleIds = _isAudioOnlyMode
        ? const <String>{}
        : visiblePageParticipants.map((p) => p.identity).toSet();
    final spotlightId = spotlightParticipant?.identity;
    final visibleCount = visibleIds.length;

    for (final remote in currentRoom.remoteParticipants.values) {
      final isVisibleOnPage = visibleIds.contains(remote.identity);

      for (final pub in remote.videoTrackPublications) {
        if (_isAudioOnlyMode || !isVisibleOnPage) {
          unawaited(pub.disable());
          continue;
        }

        unawaited(pub.enable());

        if (_lowBandwidthDetected) {
          unawaited(pub.setVideoQuality(VideoQuality.LOW));
          unawaited(pub.setVideoFPS(15));
        } else if (remote.identity == spotlightId ||
            pub.source == TrackSource.screenShareVideo) {
          unawaited(pub.setVideoQuality(VideoQuality.HIGH));
          unawaited(pub.setVideoFPS(30));
        } else if (visibleCount >= 4) {
          unawaited(pub.setVideoQuality(VideoQuality.LOW));
          unawaited(pub.setVideoFPS(20));
        } else {
          unawaited(pub.setVideoQuality(VideoQuality.MEDIUM));
          unawaited(pub.setVideoFPS(24));
        }
      }
    }
  }

  void setPageIndex(int nextPage) {
    final clamped = nextPage.clamp(0, totalPages - 1);
    if (clamped == _currentPageIndex) return;
    _currentPageIndex = clamped;
    _enforceDownlinkViewportBudget();
    notifyListeners();
  }

  void togglePinParticipant(String identity) {
    if (_pinnedParticipantIdentity == identity) {
      _pinnedParticipantIdentity = null;
    } else {
      _pinnedParticipantIdentity = identity;
    }
    _enforceDownlinkViewportBudget();
    notifyListeners();
  }

  // ───────────────────────── In-Call Media Controls ─────────────────────────

  Future<void> toggleMicrophone() async {
    final local = _room?.localParticipant;
    if (local == null) return;
    final next = !_isMicEnabled;
    _isMicEnabled = next;
    notifyListeners();
    try {
      await local.setMicrophoneEnabled(next);
    } catch (_) {
      _isMicEnabled = !next;
    }
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    final local = _room?.localParticipant;
    if (local == null) return;
    final next = !_isCameraEnabled;
    if (next && _isAudioOnlyMode) {
      _isAudioOnlyMode = false;
    }
    _isCameraEnabled = next;
    notifyListeners();
    try {
      await local.setCameraEnabled(next);
    } catch (_) {
      _isCameraEnabled = !next;
    }
    _enforceDownlinkViewportBudget();
    notifyListeners();
  }

  Future<void> switchCameraFacing() async {
    final local = _room?.localParticipant;
    if (local == null) return;
    final nextPos = _cameraPosition.switched();
    for (final pub in local.videoTrackPublications) {
      final track = pub.track;
      if (pub.source == TrackSource.camera && track is LocalVideoTrack) {
        try {
          await track.setCameraPosition(nextPos);
          _cameraPosition = nextPos;
          notifyListeners();
        } catch (_) {}
        break;
      }
    }
  }

  Future<void> toggleSpeakerphone() async {
    final next = !_isSpeakerOn;
    _isSpeakerOn = next;
    if (AudioManager.instance.canSwitchSpeakerphone) {
      await AudioManager.instance.setSpeakerOutputPreferred(next);
    }
    notifyListeners();
  }

  Future<void> toggleScreenShare() async {
    final local = _room?.localParticipant;
    if (local == null) return;
    final next = !_isScreenShareEnabled;
    try {
      await local.setScreenShareEnabled(next);
      _isScreenShareEnabled = next;
    } catch (_) {
      _isScreenShareEnabled = false;
    }
    notifyListeners();
  }

  Future<void> setAudioOnlyMode(bool enabled) async {
    if (_isAudioOnlyMode == enabled) return;
    _isAudioOnlyMode = enabled;
    if (enabled && _isCameraEnabled) {
      _isCameraEnabled = false;
      try {
        await _room?.localParticipant?.setCameraEnabled(false);
      } catch (_) {}
    }
    _enforceDownlinkViewportBudget();
    notifyListeners();
  }

  // ───────────────────────── Host Moderation & E2EE Ratchet ─────────────────────────

  Future<void> toggleRoomLock() async {
    final summary = _roomSummary;
    if (summary == null || !summary.isHostOrCohost) return;
    final nextLocked = !summary.isLocked;
    await _apiService.moderate(
      roomCode: summary.roomCode,
      action: nextLocked ? 'lock_room' : 'unlock_room',
    );
    _roomSummary = summary.copyWith(isLocked: nextLocked);
    notifyListeners();
  }

  Future<void> muteRemoteParticipant(MeetingParticipantTileData target) async {
    final summary = _roomSummary;
    if (summary == null ||
        !summary.isHostOrCohost ||
        target.userId == null ||
        target.audioTrackSid == null) {
      return;
    }
    await _apiService.moderate(
      roomCode: summary.roomCode,
      action: 'mute_track',
      targetUserId: target.userId,
      trackSid: target.audioTrackSid,
    );
  }

  Future<void> removeRemoteParticipant(MeetingParticipantTileData target) async {
    final summary = _roomSummary;
    if (summary == null || !summary.isHostOrCohost || target.userId == null) {
      return;
    }
    final res = await _apiService.moderate(
      roomCode: summary.roomCode,
      action: 'kick',
      targetUserId: target.userId,
    );

    // Forward secrecy: ratchet the E2EE room key whenever someone is kicked
    if (res['e2ee_ratchet_required'] == true && _e2eeActive) {
      await _e2eeManager.ratchetRoomKey();
      await _broadcastControlPacket({
        'type': 'apolo_e2ee_ratchet',
        'generation': _e2eeManager.ratchetGeneration,
      });
      notifyListeners();
    }
  }

  Future<void> leaveCall() async {
    final code = _roomSummary?.roomCode;
    _stopCallTimers();
    await _disposeRoomOnly();
    _phase = MeetingConnectionPhase.ended;
    notifyListeners();
    if (code != null && code.isNotEmpty) {
      await _apiService.leaveMeeting(code);
    }
  }

  Future<void> endMeetingForAll() async {
    final summary = _roomSummary;
    _stopCallTimers();
    if (summary != null && summary.isPrimaryHost) {
      try {
        await _apiService.endMeetingForAll(summary.roomCode);
      } catch (_) {}
    }
    await _disposeRoomOnly();
    _phase = MeetingConnectionPhase.ended;
    notifyListeners();
  }

  // ───────────────────────── Helpers & Cleanup ─────────────────────────

  Future<void> _broadcastControlPacket(Map<String, dynamic> payload) async {
    final local = _room?.localParticipant;
    if (local == null) return;
    try {
      final bytes = utf8.encode(jsonEncode(payload));
      await local.publishData(bytes, reliable: true, topic: 'apolo_control');
    } catch (_) {}
  }

  void _handleControlChannelMessage(List<int> rawBytes) {
    try {
      final decoded = jsonDecode(utf8.decode(rawBytes));
      if (decoded is Map && decoded['type'] == 'apolo_e2ee_ratchet') {
        final targetGen = int.tryParse('${decoded['generation'] ?? 0}') ?? 0;
        if (_e2eeActive && targetGen > _e2eeManager.ratchetGeneration) {
          unawaited(_e2eeManager.ratchetRoomKey().then((_) => notifyListeners()));
        }
      }
    } catch (_) {}
  }

  void _startCallTimers(int ttlSeconds) {
    _stopCallTimers();
    _elapsed = Duration.zero;
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
    });

    final refreshAfterSec = (ttlSeconds * 0.75).round().clamp(60, 2700);
    _tokenRefreshTimer = Timer.periodic(
      Duration(seconds: refreshAfterSec),
      (_) async {
        final code = _roomSummary?.roomCode;
        if (code == null) return;
        try {
          final refreshed = await _apiService.refreshToken(code);
          _credentials = refreshed;
          _roomSummary = refreshed.room;
        } catch (_) {}
      },
    );
  }

  void _stopCallTimers() {
    _callDurationTimer?.cancel();
    _callDurationTimer = null;
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  List<MeetingParticipantTileData> _buildSortedParticipantList() {
    final currentRoom = _room;
    if (currentRoom == null) return const [];

    final items = <MeetingParticipantTileData>[];
    final local = currentRoom.localParticipant;
    if (local != null) {
      items.add(_toTileData(local, isLocal: true));
    }

    for (final remote in currentRoom.remoteParticipants.values) {
      items.add(_toTileData(remote, isLocal: false));
    }

    items.sort((a, b) {
      if (_pinnedParticipantIdentity != null) {
        if (a.identity == _pinnedParticipantIdentity) return -1;
        if (b.identity == _pinnedParticipantIdentity) return 1;
      }
      if (a.isScreenSharing != b.isScreenSharing) {
        return a.isScreenSharing ? -1 : 1;
      }
      if (a.isSpeaking != b.isSpeaking) {
        return a.isSpeaking ? -1 : 1;
      }
      if (a.isLocal != b.isLocal) {
        return a.isLocal ? -1 : 1;
      }
      if (a.isHostOrCohost != b.isHostOrCohost) {
        return a.isHostOrCohost ? -1 : 1;
      }
      return a.displayName.compareTo(b.displayName);
    });

    return items;
  }

  MeetingParticipantTileData _toTileData(
    Participant participant, {
    required bool isLocal,
  }) {
    Map<String, dynamic> meta = const {};
    final rawMeta = participant.metadata;
    if (rawMeta != null && rawMeta.isNotEmpty) {
      try {
        final parsed = jsonDecode(rawMeta);
        if (parsed is Map) {
          meta = Map<String, dynamic>.from(parsed);
        }
      } catch (_) {}
    }

    VideoTrack? cameraTrack;
    VideoTrack? screenTrack;
    String? audioSid;
    bool camOn = false;
    bool micOn = false;

    for (final pub in participant.videoTrackPublications) {
      final track = pub.track;
      if (pub.source == TrackSource.screenShareVideo &&
          track is VideoTrack &&
          !pub.muted) {
        screenTrack = track;
      } else if (pub.source == TrackSource.camera &&
          track is VideoTrack &&
          !pub.muted) {
        cameraTrack = track;
        camOn = true;
      }
    }

    for (final pub in participant.audioTrackPublications) {
      if (pub.source == TrackSource.microphone) {
        audioSid = pub.sid;
        if (!pub.muted) {
          micOn = true;
        }
      }
    }

    final parsedUserId = int.tryParse('${meta['user_id'] ?? ''}');
    final role = (meta['role'] ?? (isLocal ? (_roomSummary?.myRole ?? 'participant') : 'participant'))
        .toString();
    final avatarUrl = meta['avatar_url']?.toString();
    final name = participant.name.trim().isNotEmpty
        ? participant.name.trim()
        : participant.identity;

    return MeetingParticipantTileData(
      participant: participant,
      identity: participant.identity,
      userId: parsedUserId,
      displayName: name,
      avatarUrl: (avatarUrl != null && avatarUrl.isNotEmpty) ? avatarUrl : null,
      role: role,
      isLocal: isLocal,
      isSpeaking: participant.isSpeaking,
      isMicEnabled: micOn,
      isCameraEnabled: camOn && !_isAudioOnlyMode,
      isScreenSharing: screenTrack != null,
      primaryVideoTrack: screenTrack ?? cameraTrack,
      screenShareTrack: screenTrack,
      audioTrackSid: audioSid,
      networkTier: _mapConnectionQuality(participant.connectionQuality),
    );
  }

  static MeetingNetworkTier _mapConnectionQuality(ConnectionQuality q) {
    return switch (q) {
      ConnectionQuality.excellent => MeetingNetworkTier.excellent,
      ConnectionQuality.good => MeetingNetworkTier.good,
      ConnectionQuality.poor => MeetingNetworkTier.poor,
      ConnectionQuality.lost => MeetingNetworkTier.lost,
      ConnectionQuality.unknown => MeetingNetworkTier.unknown,
    };
  }

  Future<void> _disposeRoomOnly() async {
    final listener = _roomListener;
    _roomListener = null;
    if (listener != null) {
      try {
        await listener.dispose();
      } catch (_) {}
    }

    final activeRoom = _room;
    _room = null;
    if (activeRoom != null) {
      try {
        await activeRoom.disconnect();
      } catch (_) {}
      try {
        await activeRoom.dispose();
      } catch (_) {}
    }
    _e2eeManager.dispose();
  }

  @override
  void dispose() {
    _stopCallTimers();
    unawaited(_stopLobbyCameraPreview());
    unawaited(_disposeRoomOnly());
    super.dispose();
  }
}
