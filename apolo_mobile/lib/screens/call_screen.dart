import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/services/firebase_chat_service.dart';
import '../core/services/media_rtc_bridge.dart';
import '../core/state/app_state.dart';
import '../widgets/apolo_badges_kit.dart';
import '../widgets/dl_settings_kit.dart';
import 'widgets/app_image.dart';
import '../l10n/l10n.dart';

/// Real-time WebRTC Audio & Video Call screen using Firestore signaling.
class CallScreen extends StatefulWidget {
  final String peerName;
  final String? peerAvatar;
  final String? peerPhone;
  final int? peerId;
  final String? conversationDocId;
  final bool isVideo;
  final String? incomingCallId;
  final String? incomingOfferJson;

  const CallScreen({
    super.key,
    required this.peerName,
    this.peerAvatar,
    this.peerPhone,
    this.peerId,
    this.conversationDocId,
    this.isVideo = false,
    this.incomingCallId,
    this.incomingOfferJson,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final AppState _state = AppState();

  String? _callId;
  String _status = 'connecting'; // connecting | ringing | connected | ended | error
  bool _muted = false;
  bool _cameraEnabled = true;
  bool _acceptedIncoming = false;
  bool _answerApplied = false;
  int _elapsedSec = 0;

  Timer? _durationTimer;
  StreamSubscription<Map<String, dynamic>?>? _callSub;
  StreamSubscription<String>? _candSub;

  bool get _isIncoming =>
      widget.incomingCallId != null && widget.incomingCallId!.isNotEmpty;

  bool get _rtcAvailable =>
      MediaRtcBridge.isRtcSupported && FirebaseChatService.instance.isReady;

  @override
  void initState() {
    super.initState();
    _cameraEnabled = widget.isVideo;
    if (_rtcAvailable) {
      if (_isIncoming) {
        _callId = widget.incomingCallId;
        _status = 'ringing';
        MediaRtcBridge.startRingtone();
        _watchCallDoc(_callId!, isCaller: false);
      } else {
        _startOutgoingCall();
      }
    }
  }

  @override
  void dispose() {
    MediaRtcBridge.stopRingtone();
    _durationTimer?.cancel();
    _callSub?.cancel();
    _candSub?.cancel();
    MediaRtcBridge.rtcEndCall();
    if (_callId != null && _status != 'ended') {
      FirebaseChatService.instance.updateCallStatus(
        callId: _callId!,
        status: 'ended',
      );
    }
    super.dispose();
  }

  Future<void> _startOutgoingCall() async {
    final myUserId = int.tryParse('${_state.currentUser?['id'] ?? ''}') ?? 0;
    final myName = (_state.currentUser?['name'] ??
            _state.currentUser?['full_name'] ??
            'Apolo User')
        .toString();
    final myAvatar = (_state.currentUser?['avatar_url'] ??
            _state.currentUser?['avatar'] ??
            '')
        .toString();

    final pendingLocalCandidates = <String>[];

    final offerJson = await MediaRtcBridge.rtcStartCaller(
      isVideo: widget.isVideo,
      onIceCandidate: (cand) {
        if (_callId != null) {
          FirebaseChatService.instance.addCallCandidate(
            callId: _callId!,
            isCaller: true,
            candidateJson: cand,
          );
        } else {
          pendingLocalCandidates.add(cand);
        }
      },
      onConnectionState: (rtcState) {
        if (!mounted) return;
        if (rtcState == 'connected') {
          _onConnected();
        } else if (rtcState == 'disconnected' ||
            rtcState == 'failed' ||
            rtcState == 'closed') {
          _endAndPop();
        }
      },
    );

    if (!mounted) return;
    if (offerJson == null || offerJson.isEmpty) {
      setState(() => _status = 'error');
      return;
    }

    try {
      final callId = await FirebaseChatService.instance.createCall(
        conversationDocId: widget.conversationDocId ?? '',
        callerId: myUserId,
        callerName: myName,
        callerAvatar: myAvatar,
        calleeId: widget.peerId ?? 0,
        calleeName: widget.peerName,
        calleeAvatar: widget.peerAvatar ?? '',
        isVideo: widget.isVideo,
        offerJson: offerJson,
      );
      if (!mounted) return;
      _callId = callId;
      setState(() => _status = 'ringing');

      for (final c in pendingLocalCandidates) {
        unawaited(FirebaseChatService.instance.addCallCandidate(
          callId: callId,
          isCaller: true,
          candidateJson: c,
        ));
      }
      pendingLocalCandidates.clear();

      _watchCallDoc(callId, isCaller: true);
      _candSub = FirebaseChatService.instance
          .watchCallCandidates(callId, watchCallerCandidates: false)
          .listen((cand) {
        MediaRtcBridge.rtcAddIceCandidate(cand);
      });
    } catch (_) {
      if (mounted) setState(() => _status = 'error');
    }
  }

  Future<void> _acceptIncomingCall() async {
    if (_acceptedIncoming || _callId == null) return;
    MediaRtcBridge.stopRingtone();
    final offerJson = widget.incomingOfferJson ?? '';
    if (offerJson.isEmpty) return;

    setState(() {
      _acceptedIncoming = true;
      _status = 'connecting';
    });

    final answerJson = await MediaRtcBridge.rtcAnswerCallee(
      offerJson: offerJson,
      isVideo: widget.isVideo,
      onIceCandidate: (cand) {
        if (_callId != null) {
          FirebaseChatService.instance.addCallCandidate(
            callId: _callId!,
            isCaller: false,
            candidateJson: cand,
          );
        }
      },
      onConnectionState: (rtcState) {
        if (!mounted) return;
        if (rtcState == 'connected') {
          _onConnected();
        } else if (rtcState == 'disconnected' ||
            rtcState == 'failed' ||
            rtcState == 'closed') {
          _endAndPop();
        }
      },
    );

    if (!mounted) return;
    if (answerJson == null || answerJson.isEmpty) {
      setState(() => _status = 'error');
      return;
    }

    await FirebaseChatService.instance.answerCall(
      callId: _callId!,
      answerJson: answerJson,
    );

    _candSub = FirebaseChatService.instance
        .watchCallCandidates(_callId!, watchCallerCandidates: true)
        .listen((cand) {
      MediaRtcBridge.rtcAddIceCandidate(cand);
    });
    _onConnected();
  }

  void _watchCallDoc(String callId, {required bool isCaller}) {
    _callSub?.cancel();
    _callSub = FirebaseChatService.instance.watchCall(callId).listen((data) {
      if (!mounted || data == null) return;
      final remoteStatus = (data['status'] ?? '').toString();
      if (remoteStatus == 'ended' || remoteStatus == 'declined') {
        _endAndPop(notifyServer: false);
        return;
      }
      if (isCaller && !_answerApplied) {
        final ans = (data['answer'] ?? '').toString();
        if (ans.isNotEmpty) {
          _answerApplied = true;
          MediaRtcBridge.rtcApplyRemoteAnswer(ans);
          _onConnected();
        }
      }
    });
  }

  void _onConnected() {
    MediaRtcBridge.stopRingtone();
    if (!mounted) return;
    if (_status != 'connected') {
      setState(() => _status = 'connected');
    }
    _durationTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSec++);
    });
  }

  Future<void> _endAndPop({bool notifyServer = true}) async {
    if (_status == 'ended') return;
    _status = 'ended';
    MediaRtcBridge.stopRingtone();
    _durationTimer?.cancel();
    _callSub?.cancel();
    _candSub?.cancel();
    MediaRtcBridge.rtcEndCall();

    if (notifyServer && _callId != null) {
      await FirebaseChatService.instance.updateCallStatus(
        callId: _callId!,
        status: _isIncoming && !_acceptedIncoming ? 'declined' : 'ended',
      );
    }
    if (mounted) {
      Navigator.maybePop(context);
    }
  }

  String _formatDuration(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _statusLabel() {
    final s = _state.s;
    switch (_status) {
      case 'ringing':
        return _isIncoming
            ? (widget.isVideo
                ? s.tr('مكالمة فيديو واردة...', 'Appel vidéo entrant...',
                    appL10n.callIncomingVideoCall)
                : s.tr('مكالمة صوتية واردة...', 'Appel vocal entrant...',
                    appL10n.callIncomingVoiceCall))
            : s.tr('جاري الرنين...', 'Sonnerie...', appL10n.callRinging);
      case 'connected':
        return _formatDuration(_elapsedSec);
      case 'error':
        return s.tr('يرجى السماح بالوصول للميكروفون/الكاميرا',
            'Veuillez autoriser le micro/caméra', appL10n.callAllowMicCameraAccess);
      default:
        return s.tr('جاري الاتصال...', 'Connexion...', appL10n.callConnecting);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    if (!_rtcAvailable) {
      return Directionality(
        textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                ApoloDlTopNav(
                  title: s.tr('المكالمات', 'Appels', appL10n.callCalls),
                  onBack: () => Navigator.maybePop(context),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F6F6),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  CupertinoIcons.phone_fill,
                                  size: 24,
                                  color: Color(0xFF000000),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                s.tr(
                                  'المكالمات غير متاحة على هذا الجهاز حالياً',
                                  'Appels indisponibles sur cet appareil',
                                  appL10n.callCallsAreUnavailableThisDevice,
                                ),
                                key: const Key('calls-unavailable'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF000000),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ApoloDlButton(
                                label: s.tr(
                                  'العودة للمحادثة',
                                  'Revenir à la conversation',
                                  appL10n.callBackChat,
                                ),
                                variant: ApoloDlButtonVariant.primary,
                                borderRadius: 999,
                                height: 48,
                                fullWidth: true,
                                onPressed: () => Navigator.maybePop(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            // Dynamic Layer Dark Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isVideo
                              ? CupertinoIcons.videocam_fill
                              : CupertinoIcons.phone_fill,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isVideo
                              ? s.tr(
                                  'مكالمة فيديو', 'Appel vidéo', appL10n.callVideoCall)
                              : s.tr(
                                  'مكالمة صوتية', 'Appel vocal', appL10n.callVoiceCall),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        _statusLabel(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection:
                            _status == 'connected' ? TextDirection.ltr : null,
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Center Peer Info
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1C1C1E),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: widget.peerAvatar != null &&
                              widget.peerAvatar!.isNotEmpty
                          ? AppImage(
                              url: widget.peerAvatar!,
                              fit: BoxFit.cover,
                              width: 104,
                              height: 104,
                            )
                          : Center(
                              child: Text(
                                widget.peerName.isNotEmpty
                                    ? widget.peerName[0].toUpperCase()
                                    : 'A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            widget.peerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const ApoloVerifiedBadge(size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _statusLabel(),
                      textAlign: TextAlign.center,
                      textDirection:
                          _status == 'connected' ? TextDirection.ltr : null,
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: _isIncoming && !_acceptedIncoming
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCallActionButton(
                          icon: CupertinoIcons.phone_down_fill,
                          label: s.tr('رفض', 'Refuser', appL10n.callDecline),
                          bgColor: const Color(0xFFE31B23),
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            _endAndPop();
                          },
                        ),
                        _buildCallActionButton(
                          icon: CupertinoIcons.phone_fill,
                          label: s.tr('قبول', 'Accepter', appL10n.callAccept),
                          bgColor: const Color(0xFF16A34A),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _acceptIncomingCall();
                          },
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCallActionButton(
                          icon: _muted
                              ? CupertinoIcons.mic_slash_fill
                              : CupertinoIcons.mic_fill,
                          label: _muted
                              ? s.tr('صامت', 'Muet', appL10n.meetingMuted)
                              : s.tr('الميكرو', 'Micro', appL10n.callMic),
                          bgColor: _muted
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.16),
                          iconColor: _muted ? const Color(0xFF0A0A0A) : Colors.white,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _muted = !_muted);
                            MediaRtcBridge.rtcSetMuted(_muted);
                          },
                        ),
                        if (widget.isVideo)
                          _buildCallActionButton(
                            icon: _cameraEnabled
                                ? CupertinoIcons.videocam_fill
                                : CupertinoIcons.video_camera,
                            label: s.tr('الكاميرا', 'Caméra', appL10n.callCamera),
                            bgColor: !_cameraEnabled
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.16),
                            iconColor: !_cameraEnabled
                                ? const Color(0xFF0A0A0A)
                                : Colors.white,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _cameraEnabled = !_cameraEnabled);
                              MediaRtcBridge.rtcSetCameraEnabled(_cameraEnabled);
                            },
                          ),
                        _buildCallActionButton(
                          icon: CupertinoIcons.phone_down_fill,
                          label: s.tr('إنهاء', 'Terminer', appL10n.callEnd),
                          bgColor: const Color(0xFFE31B23),
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            _endAndPop();
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallActionButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    Color iconColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
