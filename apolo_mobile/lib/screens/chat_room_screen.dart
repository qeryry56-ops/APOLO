import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/services/chat_realtime_client.dart';
import '../core/services/firebase_chat_service.dart';
import '../core/services/media_rtc_bridge.dart';
import '../core/state/app_state.dart';
import '../features/chat/models/chat_ack_models.dart';
import '../features/chat/state/chat_ack_notifier_registry.dart';
import '../features/chat/theme/apolo_chat_dl_tokens.dart';
import '../theme/app_typography.dart';
import '../widgets/apolo_badges_kit.dart';
import '../widgets/apolo_emoji_reaction_bar.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_message.dart';
import '../widgets/ios26_imessage_drawer.dart';
import '../widgets/ios26_imessage_kit.dart';
import '../widgets/notification_badge.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/voice_recorder.dart';
import 'ad_detail_screen.dart';
import 'call_screen.dart';
import 'seller_profile_screen.dart';
import 'widgets/apolo_safety_sheet.dart';
import 'widgets/app_image.dart';
import 'widgets/chat_utils.dart';
import 'widgets/skeleton_loader.dart';

/// Clean, low-noise Real-time Chat Room powered by Firebase Firestore (with REST fallback),
/// implementing all 6 Chat UX rules:
/// 1. Message Grouping (2-min window, single avatar at top of group, 8px inter-sender spacing)
/// 2. Precision on Demand (timestamps only on desktop hover or mobile long-press; date divider only on date change)
/// 3. Optimistic UI (instant bubble on send, inline retry button on failure, no toast, no spinner)
/// 4. Scroll Anchoring (preserves scroll position when reading history, shows "X new messages · Jump to latest" pill)
/// 5. Typing Indicator in Flow (inline at bottom of message list attached to sender's avatar, multi-typer support)
/// 6. Composer Behavior (auto-expands 1..5 lines then scrolls, attachments above input, always-visible send button)
class ChatRoomScreen extends StatefulWidget {
  final int conversationId;
  final int? backendConversationId;
  final int? adId;
  final String? firestoreDocId;
  final String peerName;
  final int? peerId;
  final String adTitle;
  final String? peerAvatar;
  final String? adImage;
  final String? adPrice;
  final String? initialDraft;
  final bool autoSendInitialDraft;
  final List<String> initialTypingUsers;
  final List<ChatAttachment> initialAttachments;
  final List<Map<String, dynamic>>? initialMessages;
  final bool? showInlineAvatars;
  final bool isPeerVerified;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    this.backendConversationId,
    this.adId,
    this.firestoreDocId,
    required this.peerName,
    this.peerId,
    this.adTitle = '',
    this.peerAvatar,
    this.adImage,
    this.adPrice,
    this.initialDraft,
    this.autoSendInitialDraft = false,
    this.initialTypingUsers = const <String>[],
    this.initialAttachments = const <ChatAttachment>[],
    this.initialMessages,
    this.showInlineAvatars,
    this.isPeerVerified = true,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with WidgetsBindingObserver {
  final AppState _state = AppState();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focus = FocusNode();
  final GlobalKey<VoiceRecorderState> _voiceRecorderKey =
      GlobalKey<VoiceRecorderState>();

  List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _pending = [];
  final List<ChatAttachment> _stagedAttachments = [];
  final Set<String> _hiddenMessageKeys = {};
  final Set<String> _deletedForEveryoneKeys = {};
  final Map<String, String> _editedMessageBodies = {};
  final Map<String, Map<String, String>> _localReactions = {};
  final Set<String> _pinnedMessageKeys = {};
  final Set<String> _starredMessageKeys = {};
  Map<String, dynamic>? _editingMessage;
  String? _editingMessageKey;
  Map<String, dynamic>? _replyingToMessage;

  bool _loading = true;
  bool _showCallMenu = false;
  final bool _uploadingMedia = false;
  final bool _isRecordingVoice = false;
  final int _recordSeconds = 0;
  bool _loadingRequest = false;
  List<String> _typingUsers = [];
  String? _loadError;

  // Rule 4: Scroll Anchoring state
  bool _isUserReadingHistory = false;
  int _unreadIncomingCount = 0;
  int _optimisticSeq = 0;

  // Classic iOS iMessage horizontal swipe-to-reveal timestamps
  double _swipeRevealProgress = 0.0;

  // Official Apple iOS 26 Half-Height `+` Apps & Stickers Drawer (`0:99`)
  bool _isDrawerOpen = false;
  Ios26DrawerTab _drawerTab = Ios26DrawerTab.apps;

  // Granular per-message ACK ValueNotifier registry (zero-jitter tick updates)
  final ChatAckNotifierRegistry _ackRegistry = ChatAckNotifierRegistry();

  Timer? _focusScrollTimer;
  Timer? _typingTimer;
  Timer? _recordTimer;
  Timer? _restFallbackTimer;
  TypingIndicatorController? _typingController;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<Map<String, dynamic>?>? _convMetaSub;
  StreamSubscription<Map<String, dynamic>?>? _incomingCallSub;
  StreamSubscription<Map<String, dynamic>>? _wsMessageSub;
  StreamSubscription<Map<String, dynamic>>? _wsAckSub;
  StreamSubscription<Map<String, dynamic>>? _wsDeliveryReceiptSub;
  StreamSubscription<Map<String, dynamic>>? _wsReadReceiptSub;
  StreamSubscription<Map<String, dynamic>>? _wsSyncSub;
  StreamSubscription<PeerPresenceState>? _wsPresenceSub;
  StreamSubscription<bool>? _wsConnSub;
  PeerPresenceState? _peerPresence;
  String? _lastHandledCallId;
  Object? _accountId;
  String? _resolvedFirestoreDocId;
  int _resolvedBackendConvId = 0;
  int? _resolvedPeerId;
  int? _resolvedAdId;

  int get _myUserId => int.tryParse('${_state.currentUser?['id'] ?? ''}') ?? 0;

  int get _effectivePeerId => _resolvedPeerId ?? widget.peerId ?? 0;

  int get _effectiveAdId => _resolvedAdId ?? widget.adId ?? 0;

  String get _myDisplayName => (_state.currentUser?['name'] ??
          _state.currentUser?['full_name'] ??
          'Amine')
      .toString();

  String? get _myAvatarUrl => (_state.currentUser?['avatar_url'] ??
          _state.currentUser?['avatar'])
      ?.toString();

  String get _peerBlockKey {
    final pid = _effectivePeerId;
    return pid > 0 ? '$pid' : widget.peerName.trim();
  }

  bool get _isPeerBlocked =>
      FirebaseChatService.instance.isBlocked(_peerBlockKey);

  String? get _activeFirestoreDocId {
    final explicit =
        (_resolvedFirestoreDocId ?? widget.firestoreDocId)?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    if (FirebaseChatService.instance.isReady &&
        _myUserId > 0 &&
        _effectivePeerId > 0) {
      return FirebaseChatService.instance.buildConversationDocId(
        myUserId: _myUserId,
        peerUserId: _effectivePeerId,
        adId: _effectiveAdId,
      );
    }
    return null;
  }

  bool get _useFirestore =>
      FirebaseChatService.instance.isReady &&
      _state.isLoggedIn &&
      _myUserId > 0 &&
      _activeFirestoreDocId != null;

  static const Color _chatBlue = Ios26IMessageTokens.bubbleMine;
  static const Color _chatBlueSoft = Color(0xFFE8F3FF);
  static const Color _textBlack = ApoloChatDlTokens.inkPrimary;
  static const Color _textMuted = ApoloChatDlTokens.inkSecondary;
  static const Color _textSubtle = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _accountId = _state.currentUser?['id'];
    _resolvedFirestoreDocId = widget.firestoreDocId?.trim();
    _resolvedPeerId = widget.peerId;
    _resolvedAdId = widget.adId;
    _resolvedBackendConvId = widget.backendConversationId ??
        ((widget.firestoreDocId == null || widget.firestoreDocId!.isEmpty)
            ? widget.conversationId
            : 0);
    _state.addListener(_onAccountChanged);

    if (widget.initialDraft != null) _msgCtrl.text = widget.initialDraft!;
    _typingUsers = List<String>.from(widget.initialTypingUsers);
    _stagedAttachments.addAll(widget.initialAttachments);

    _scrollCtrl.addListener(_handleScrollPosition);

    _typingController = TypingIndicatorController(
      memberCount: 2,
      onEmit: (payload) {
        if (!mounted || !_useFirestore) return;
        final docId = _activeFirestoreDocId;
        if (docId == null) return;
        FirebaseChatService.instance.setTyping(
          docId: docId,
          myUserId: _myUserId,
          isTyping: payload['typing'] == true,
        );
      },
    );

    _msgCtrl.addListener(() {
      if (mounted) setState(() {});
      _handleTypingActivity();
    });

    _focus.addListener(() {
      if (_focus.hasFocus) {
        if (_isDrawerOpen && mounted) {
          setState(() => _isDrawerOpen = false);
        }
        if (!_isUserReadingHistory) {
          _focusScrollTimer?.cancel();
          _focusScrollTimer =
              Timer(const Duration(milliseconds: 300), _scrollToEnd);
        }
      }
    });

    if (widget.initialMessages != null) {
      _messages = widget.initialMessages!
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _loading = false;
    } else if (_useFirestore) {
      _bindFirestoreStreams();
      _resolveBestFirestoreDocIfNeeded();
      if (_resolvedBackendConvId > 0) {
        unawaited(_loadBackendMessagesIntoFirestoreIfNeeded());
      }
    } else {
      // Initial one-time history hydration only; live updates arrive over persistent WebSocket (NO HTTP polling).
      _loadMessages(scrollToBottom: true);
    }

    if (widget.initialMessages == null && _state.isLoggedIn && _myUserId > 0) {
      unawaited(_initRealtimeWebSocket());
    }

    if (widget.initialMessages == null) {
      _restFallbackTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted ||
            _useFirestore ||
            ChatRealtimeClient.instance.isConnected) {
          return;
        }
        unawaited(_loadMessages(silent: true));
      });
    }

    if (widget.autoSendInitialDraft &&
        widget.initialDraft != null &&
        widget.initialDraft!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _msgCtrl.text.trim().isNotEmpty) {
          _sendText();
        }
      });
    }
  }

  String get _realtimeChannelId {
    final docId = _activeFirestoreDocId;
    if (docId != null && docId.isNotEmpty) return docId;
    if (_resolvedBackendConvId > 0) return 'conv_$_resolvedBackendConvId';
    if (widget.conversationId > 0) return 'conv_${widget.conversationId}';
    return 'dm_${_myUserId}_${_effectivePeerId}_$_effectiveAdId';
  }

  Future<void> _initRealtimeWebSocket() async {
    final ws = ChatRealtimeClient.instance;
    ws.registerActiveChannel(_realtimeChannelId);
    final peerId = _effectivePeerId;
    if (peerId > 0) {
      final cached = ws.cachedPresence(peerId);
      if (cached != null && mounted) {
        setState(() => _peerPresence = cached);
      }
    }

    _wsPresenceSub?.cancel();
    _wsPresenceSub = ws.presenceUpdates.listen((state) {
      if (!mounted) return;
      if (state.userId == _effectivePeerId) {
        setState(() => _peerPresence = state);
      }
    });

    _wsMessageSub?.cancel();
    _wsMessageSub = ws.incomingMessages.listen((msg) {
      if (!mounted) return;
      if ((msg['channel_id'] ?? '').toString() != _realtimeChannelId) return;
      _mergeRealtimeMessage(msg);
      final senderId = int.tryParse('${msg['sender_id'] ?? 0}') ?? 0;
      final mid = (msg['message_id'] ?? '').toString();
      if (senderId > 0 && senderId != _myUserId && mid.isNotEmpty) {
        // Stage 3 ACK (`read` ✓✓): user is actively viewing this conversation
        ws.sendReadAck(
          channelId: _realtimeChannelId,
          lastReadMessageId: mid,
          senderId: senderId,
        );
      }
    });

    // Stage 1 ACK (`sent` ✓): updates ONLY the affected message's ValueNotifier
    _wsAckSub?.cancel();
    _wsAckSub = ws.messageAcks.listen((ack) {
      if (!mounted) return;
      if ((ack['channel_id'] ?? '').toString() != _realtimeChannelId) return;
      final clientId = (ack['client_message_id'] ?? '').toString();
      final serverId = (ack['message_id'] ?? '').toString();
      if (clientId.isEmpty) return;

      final ackStatus = ChatAckStatusCodec.fromWire(ack['ack_status'] ?? 'sent');
      _ackRegistry.applyServerAck(
        clientMessageId: clientId,
        serverMessageId: serverId,
        status: ackStatus,
      );

      for (final p in _pending) {
        if ((p['client_message_id'] ?? p['local_id'] ?? '').toString() ==
            clientId) {
          p['message_id'] = serverId;
          p['ack_status'] = ackStatus.wireValue;
          p['_pending'] = false;
          p['_failed'] = false;
        }
      }
    });

    // Stage 2 ACK (`delivered` ✓✓): zero-jitter ValueNotifier update (no list rebuild!)
    _wsDeliveryReceiptSub?.cancel();
    _wsDeliveryReceiptSub = ws.deliveryReceipts.listen((receipt) {
      if (!mounted) return;
      if ((receipt['channel_id'] ?? '').toString() != _realtimeChannelId) return;
      final ids = (receipt['message_ids'] is List)
          ? (receipt['message_ids'] as List).map((e) => '$e').toList()
          : const <String>[];
      final clientIds = (receipt['client_message_ids'] is List)
          ? (receipt['client_message_ids'] as List).map((e) => '$e').toList()
          : const <String>[];
      final upTo = receipt['last_delivered_message_id']?.toString();
      _ackRegistry.applyReceipt(
        status: ChatAckStatus.delivered,
        messageIds: ids,
        clientMessageIds: clientIds,
        upToMessageId: upTo,
      );
    });

    // Stage 3 ACK (`read` ✓✓ highlighted): zero-jitter ValueNotifier update (no list rebuild!)
    _wsReadReceiptSub?.cancel();
    _wsReadReceiptSub = ws.readReceipts.listen((receipt) {
      if (!mounted) return;
      if ((receipt['channel_id'] ?? '').toString() != _realtimeChannelId) return;
      final clientIds = (receipt['client_message_ids'] is List)
          ? (receipt['client_message_ids'] as List).map((e) => '$e').toList()
          : const <String>[];
      final upTo = receipt['last_read_message_id']?.toString();
      _ackRegistry.applyReceipt(
        status: ChatAckStatus.read,
        clientMessageIds: clientIds,
        upToMessageId: upTo,
      );
    });

    _wsSyncSub?.cancel();
    _wsSyncSub = ws.syncResponses.listen((sync) {
      if (!mounted) return;
      if ((sync['channel_id'] ?? '').toString() != _realtimeChannelId) return;
      final list = sync['messages'];
      if (list is List) {
        for (final item in list) {
          if (item is Map) {
            _mergeRealtimeMessage(Map<String, dynamic>.from(item));
          }
        }
      }
    });

    _wsConnSub?.cancel();
    _wsConnSub = ws.connectionState.listen((connected) {
      if (!mounted || !connected) return;
      if (_effectivePeerId > 0) ws.subscribePresence(_effectivePeerId);
      unawaited(ws.requestChannelSync(_realtimeChannelId));
    });

    final connected = await ws.connect(
      userId: _myUserId,
      userName: _myDisplayName,
    );
    if (connected && mounted) {
      if (peerId > 0) ws.subscribePresence(peerId);
      unawaited(ws.requestChannelSync(_realtimeChannelId));
    }
  }

  void _mergeRealtimeMessage(Map<String, dynamic> raw) {
    final senderId = int.tryParse('${raw['sender_id'] ?? 0}') ?? 0;
    final createdIso = (raw['created_at'] ?? '').toString();
    final createdDt = DateTime.tryParse(createdIso)?.toLocal() ?? DateTime.now();
    final normalized = <String, dynamic>{
      'id': (raw['message_id'] ?? raw['id'] ?? '').toString(),
      'message_id': (raw['message_id'] ?? '').toString(),
      'client_message_id': (raw['client_message_id'] ?? '').toString(),
      'sender_id': '$senderId',
      'sender_name': (raw['sender_name'] ?? '').toString(),
      'is_mine': senderId == _myUserId,
      'type': (raw['type'] ?? 'text').toString(),
      'body': (raw['body'] ?? '').toString(),
      'created_at_ms': createdDt.millisecondsSinceEpoch,
      'created_at_time': formatChatClock(createdDt),
      'read': false,
      if (raw['metadata'] is Map) ...Map<String, dynamic>.from(raw['metadata']),
    };

    setState(() {
      final clientId = normalized['client_message_id'].toString();
      if (clientId.isNotEmpty) {
        _pending.removeWhere(
          (p) =>
              (p['client_message_id'] ?? p['local_id'] ?? '').toString() ==
              clientId,
        );
      }
      _messages = ChatRealtimeClient.deduplicateMessages([
        ..._messages,
        normalized,
      ]);
      _loading = false;
    });

    if (!_isUserReadingHistory) {
      _scrollToEnd();
    } else if (senderId != _myUserId) {
      setState(() => _unreadIncomingCount++);
    }
  }

  bool get _isNearBottom {
    if (!_scrollCtrl.hasClients) return true;
    final pos = _scrollCtrl.position;
    return (pos.maxScrollExtent - pos.pixels) <= 64.0;
  }

  void _handleScrollPosition() {
    if (!_scrollCtrl.hasClients) return;
    final nearBottom = _isNearBottom;
    if (nearBottom) {
      if (_isUserReadingHistory || _unreadIncomingCount > 0) {
        setState(() {
          _isUserReadingHistory = false;
          _unreadIncomingCount = 0;
        });
      }
    } else {
      if (!_isUserReadingHistory) {
        setState(() {
          _isUserReadingHistory = true;
        });
      }
    }
  }

  void _jumpToLatest() {
    setState(() {
      _isUserReadingHistory = false;
      _unreadIncomingCount = 0;
    });
    if (_scrollCtrl.hasClients) {
      final target = _scrollCtrl.position.maxScrollExtent;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scrollCtrl.jumpTo(target);
      } else {
        _scrollCtrl.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    }
    _scrollToEnd();
  }

  void _handleTypingActivity() {
    if (!_useFirestore) return;
    _typingController?.onTextChanged(_msgCtrl.text);
  }

  Future<void> _resolveBestFirestoreDocIfNeeded() async {
    if (!FirebaseChatService.instance.isReady || _myUserId <= 0) return;
    if ((widget.firestoreDocId ?? '').trim().isNotEmpty) return;
    if (_effectivePeerId <= 0) return;
    final bestDocId =
        await FirebaseChatService.instance.resolveBestConversationDocId(
      myUserId: _myUserId,
      peerUserId: _effectivePeerId,
      adId: _effectiveAdId,
    );
    if (!mounted) return;
    if (bestDocId.isNotEmpty && bestDocId != _activeFirestoreDocId) {
      setState(() {
        _resolvedFirestoreDocId = bestDocId;
      });
      _bindFirestoreStreams();
    }
  }

  Future<void> _loadBackendMessagesIntoFirestoreIfNeeded() async {
    final convId = _resolvedBackendConvId;
    if (convId <= 0 || !_state.isLoggedIn) return;
    try {
      final res =
          await _state.api.dio.get('/chat/conversations/$convId/messages');
      if (!mounted || res.data is! Map || res.data['status'] != 'success') {
        return;
      }
      final dynamic raw = res.data['messages'] ?? res.data['data'];
      final dynamic incoming = raw is Map ? raw['data'] : raw;
      if (incoming is! List || incoming.isEmpty) return;
      final parsed = incoming
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (_messages.isEmpty && parsed.isNotEmpty && mounted) {
        setState(() {
          _messages = parsed;
          _loading = false;
        });
        _scrollToEnd();
      }
    } catch (_) {}
  }

  Future<void> _mirrorTextMessageToBackend(String text) async {
    if (!_state.isLoggedIn || text.trim().isEmpty) return;
    try {
      int convId = _resolvedBackendConvId;
      if (convId <= 0 && _effectiveAdId > 0) {
        final startRes = await _state.api.dio.post(
          '/chat/start',
          data: {'ad_id': _effectiveAdId},
        );
        if (startRes.data is Map && startRes.data['status'] == 'success') {
          final conv = startRes.data['conversation'];
          if (conv is Map) {
            convId = int.tryParse('${conv['id'] ?? 0}') ?? 0;
            _resolvedBackendConvId = convId;
          }
        }
      }
      if (convId > 0) {
        await _state.api.dio.post(
          '/chat/conversations/$convId/messages',
          data: {'body': text, 'message': text},
        );
      }
    } catch (_) {}
  }

  void _bindFirestoreStreams() {
    _messagesSub?.cancel();
    _convMetaSub?.cancel();

    final docId = _activeFirestoreDocId;
    if (docId == null || _myUserId <= 0) return;
    FirebaseChatService.activeChatDocId = docId;

    FirebaseChatService.instance.markConversationRead(
      docId: docId,
      myUserId: _myUserId,
    );

    _messagesSub = FirebaseChatService.instance
        .watchMessages(docId, _myUserId)
        .listen((incoming) {
      if (!mounted) return;
      final effectiveIncoming =
          (incoming.isEmpty && _messages.isNotEmpty) ? _messages : incoming;
      final prevLen = _messages.length;
      final diffCount = effectiveIncoming.length - prevLen;
      final wasAlreadyLoaded = !_loading;
      final wasReadingHistory =
          wasAlreadyLoaded && _scrollCtrl.hasClients && !_isNearBottom;

      setState(() {
        _messages = effectiveIncoming;
        _pending.removeWhere((p) => p['_failed'] != true);
        _loading = false;
        _loadError = null;
        if (wasAlreadyLoaded && diffCount > 0 && wasReadingHistory) {
          _isUserReadingHistory = true;
          final incomingFromPeer = effectiveIncoming
              .skip(prevLen)
              .where((m) => m['is_mine'] != true)
              .length;
          _unreadIncomingCount +=
              incomingFromPeer > 0 ? incomingFromPeer : diffCount;
        }
      });

      if (diffCount > 0) {
        // Rule 4: Only auto-scroll if user is already at bottom
        if (!wasAlreadyLoaded || !wasReadingHistory) {
          _scrollToEnd();
        }
        if (wasAlreadyLoaded &&
            incoming.isNotEmpty &&
            incoming.last['is_mine'] != true) {
          MediaRtcBridge.playMessageSound();
        }
        FirebaseChatService.instance.markConversationRead(
          docId: docId,
          myUserId: _myUserId,
        );
      }
    }, onError: (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = _state.s.tr('تعذر الاتصال بالمحادثة. حاول مجدداً.',
            'Connexion impossible. Réessayez.', 'Unable to connect. Please try again.');
      });
    });

    _convMetaSub =
        FirebaseChatService.instance.watchConversationDoc(docId).listen((data) {
      if (!mounted || data == null) return;
      final typingMap = data['typing'] is Map ? data['typing'] as Map : null;
      final metaMap = data['participants_meta'] is Map
          ? data['participants_meta'] as Map
          : null;
      final nextTypers = <String>[];
      if (typingMap != null) {
        for (final entry in typingMap.entries) {
          final uid = '${entry.key}';
          if (uid != '$_myUserId' && entry.value == true) {
            final meta = metaMap?[uid];
            final name = (meta is Map ? meta['name'] : null)?.toString().trim();
            nextTypers.add(
              (name != null && name.isNotEmpty) ? name : widget.peerName,
            );
          }
        }
      }
      if (nextTypers.join('|') != _typingUsers.join('|')) {
        setState(() => _typingUsers = nextTypers);
      }
    });

    _incomingCallSub?.cancel();
    _incomingCallSub = FirebaseChatService.instance
        .watchIncomingCalls(_myUserId)
        .listen((callData) {
      if (!mounted || callData == null) return;
      final callId = (callData['id'] ?? '').toString();
      if (callId.isEmpty || callId == _lastHandledCallId) return;
      _lastHandledCallId = callId;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            peerName: (callData['caller_name'] ?? widget.peerName).toString(),
            peerAvatar: callData['caller_avatar']?.toString(),
            peerId: int.tryParse('${callData['caller_id'] ?? ''}'),
            conversationDocId: callData['conversation_doc_id']?.toString(),
            isVideo: callData['is_video'] == true,
            incomingCallId: callId,
            incomingOfferJson: (callData['offer'] ?? '').toString(),
          ),
        ),
      );
    });
  }

  void _onAccountChanged() {
    if (!mounted || _accountId == _state.currentUser?['id']) return;
    _accountId = _state.currentUser?['id'];
    setState(() {
      _messages = [];
      _pending.clear();
      _loading = false;
      _unreadIncomingCount = 0;
      _isUserReadingHistory = false;
    });
    _msgCtrl.clear();
    if (_useFirestore) {
      _bindFirestoreStreams();
    } else if (widget.initialMessages == null) {
      _loadMessages();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isBackgrounded = state != AppLifecycleState.resumed;
    final ws = ChatRealtimeClient.instance;
    ws.setBackgrounded(isBackgrounded);
    if (!isBackgrounded) {
      if (ws.isConnected) {
        unawaited(ws.requestChannelSync(_realtimeChannelId));
      } else {
        if (!_useFirestore && widget.initialMessages == null) {
          unawaited(_loadMessages(silent: true));
        }
        if (widget.initialMessages == null &&
            _state.isLoggedIn &&
            _myUserId > 0) {
          unawaited(ws.connect(userId: _myUserId, userName: _myDisplayName));
        }
      }
    }
  }

  @override
  void dispose() {
    ChatRealtimeClient.instance.unregisterActiveChannel(_realtimeChannelId);
    if (FirebaseChatService.activeChatDocId == _activeFirestoreDocId) {
      FirebaseChatService.activeChatDocId = null;
    }
    if (_useFirestore) {
      FirebaseChatService.instance.setTyping(
        docId: _activeFirestoreDocId!,
        myUserId: _myUserId,
        isTyping: false,
      );
    }
    _typingController?.dispose();
    _messagesSub?.cancel();
    _convMetaSub?.cancel();
    _incomingCallSub?.cancel();
    _wsMessageSub?.cancel();
    _wsAckSub?.cancel();
    _wsDeliveryReceiptSub?.cancel();
    _wsReadReceiptSub?.cancel();
    _wsSyncSub?.cancel();
    _wsPresenceSub?.cancel();
    _wsConnSub?.cancel();
    _typingTimer?.cancel();
    _recordTimer?.cancel();
    _restFallbackTimer?.cancel();
    if (_isRecordingVoice) {
      MediaRtcBridge.cancelVoiceRecording();
    }
    MediaRtcBridge.pauseVoiceMessage();
    _focusScrollTimer?.cancel();
    _ackRegistry.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _state.removeListener(_onAccountChanged);
    _scrollCtrl.removeListener(_handleScrollPosition);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatRoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId ||
        oldWidget.firestoreDocId != widget.firestoreDocId) {
      setState(() {
        _messages = [];
        _pending.clear();
        _loading = true;
        _loadError = null;
        _typingUsers = List<String>.from(widget.initialTypingUsers);
        _unreadIncomingCount = 0;
        _isUserReadingHistory = false;
        _msgCtrl.text = widget.initialDraft ?? '';
      });
      if (_useFirestore) {
        _bindFirestoreStreams();
      } else {
        _loadMessages(scrollToBottom: true);
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _loadMessages({
    bool silent = false,
    bool scrollToBottom = false,
  }) async {
    if (_loadingRequest || !mounted) return;
    final conversationId = widget.conversationId;
    final userId = _state.currentUser?['id'];
    _loadingRequest = true;
    try {
      if (!_state.isLoggedIn || conversationId <= 0) {
        throw StateError('Sign in required');
      }
      final res = await _state.api.dio
          .get('/chat/conversations/$conversationId/messages');
      if (res.data is! Map || res.data['status'] != 'success') {
        throw StateError('Messages unavailable');
      }
      final dynamic raw = res.data['messages'] ?? res.data['data'];
      final dynamic incoming = raw is Map ? raw['data'] : raw;
      if (incoming is! List) throw StateError('Invalid messages');
      if (!mounted ||
          conversationId != widget.conversationId ||
          userId != _state.currentUser?['id']) {
        return;
      }

      final parsed = incoming
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (_effectivePeerId <= 0) {
        final convMap = res.data['conversation'] is Map
            ? res.data['conversation'] as Map
            : null;
        final otherUser = convMap?['other_user'] is Map
            ? convMap!['other_user'] as Map
            : (convMap?['peer'] is Map ? convMap!['peer'] as Map : null);
        int discoveredPeer = int.tryParse(
                '${otherUser?['id'] ?? convMap?['peer_id'] ?? ''}') ??
            0;
        if (discoveredPeer <= 0 || discoveredPeer == _myUserId) {
          for (final m in parsed) {
            final sid = int.tryParse('${m['sender_id'] ?? m['user_id'] ?? ''}') ?? 0;
            if (sid > 0 && sid != _myUserId) {
              discoveredPeer = sid;
              break;
            }
          }
        }
        final discoveredAdId =
            int.tryParse('${convMap?['ad_id'] ?? convMap?['ad']?['id'] ?? ''}') ?? 0;
        if (discoveredPeer > 0) {
          _resolvedPeerId = discoveredPeer;
          if (discoveredAdId > 0 && _effectiveAdId <= 0) {
            _resolvedAdId = discoveredAdId;
          }
        }
      }

      final prevLen = _messages.length;
      final diffCount = parsed.length - prevLen;
      final wasLoaded = !_loading;
      final wasReadingHistory =
          wasLoaded && _scrollCtrl.hasClients && !_isNearBottom;

      setState(() {
        _messages = parsed;
        _loading = false;
        _loadError = null;
        if (wasLoaded && diffCount > 0 && wasReadingHistory) {
          _isUserReadingHistory = true;
          final incomingFromPeer = parsed
              .skip(prevLen)
              .where((m) => m['is_mine'] != true)
              .length;
          _unreadIncomingCount +=
              incomingFromPeer > 0 ? incomingFromPeer : diffCount;
        }
      });

      // Rule 4: Only auto-scroll if user is at bottom or initial load requested it
      if (scrollToBottom || (diffCount > 0 && !wasReadingHistory)) {
        _scrollToEnd();
      }
    } catch (_) {
      if (mounted && conversationId == widget.conversationId) {
        setState(() {
          _loading = false;
          _loadError = _state.s.tr('تعذر تحميل الرسائل. حاول مجدداً.',
              'Chargement impossible. Réessayez.', 'Failed to load messages. Please try again.');
        });
      }
    } finally {
      _loadingRequest = false;
      if (mounted && conversationId != widget.conversationId) _loadMessages();
    }
  }

  String _messageKey(Map<String, dynamic> m, int index) {
    final id = m['id'] ?? m['local_id'];
    if (id != null && id.toString().isNotEmpty) return 'id_$id';
    return 'local_${index}_${m['created_at_time'] ?? ''}_${m['body'] ?? ''}';
  }

  Future<void> _commitEditMessage(String newText) async {
    final target = _editingMessage;
    final key = _editingMessageKey;
    if (target == null || key == null) return;
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _editedMessageBodies[key] = trimmed;
      target['body'] = trimmed;
      target['_edited'] = true;
      _editingMessage = null;
      _editingMessageKey = null;
      _msgCtrl.clear();
    });

    final docMsgId = (target['doc_id'] ?? '').toString().trim();
    if (_useFirestore && docMsgId.isNotEmpty) {
      try {
        await FirebaseChatService.instance.editMessage(
          docId: _activeFirestoreDocId!,
          messageDocId: docMsgId,
          newBody: trimmed,
        );
      } catch (_) {}
      _notice(
          _state.s.tr('تم تعديل الرسالة', 'Message modifié', 'Message edited'));
      return;
    }

    final msgId = int.tryParse('${target['id'] ?? ''}');
    if (msgId != null && msgId > 0 && widget.conversationId > 0) {
      try {
        await _state.api.dio.put(
          '/chat/conversations/${widget.conversationId}/messages/$msgId',
          data: {'body': trimmed, 'message': trimmed},
        );
      } catch (_) {}
    }
    _notice(
        _state.s.tr('تم تعديل الرسالة', 'Message modifié', 'Message edited'));
  }

  Future<void> _deleteMessageForEveryone(
      Map<String, dynamic> m, String key) async {
    setState(() {
      _deletedForEveryoneKeys.add(key);
      _editedMessageBodies.remove(key);
      if (_editingMessageKey == key) {
        _editingMessage = null;
        _editingMessageKey = null;
        _msgCtrl.clear();
      }
    });
    final docMsgId = (m['doc_id'] ?? '').toString().trim();
    if (_useFirestore && docMsgId.isNotEmpty) {
      try {
        await FirebaseChatService.instance.deleteMessageForEveryone(
          docId: _activeFirestoreDocId!,
          messageDocId: docMsgId,
        );
      } catch (_) {}
      _notice(_state.s.tr(
        'تم حذف الرسالة لدى الجميع',
        'Message supprimé pour tout le monde',
        'Deleted for everyone',
      ));
      return;
    }
    final msgId = int.tryParse('${m['id'] ?? ''}');
    if (msgId != null && msgId > 0 && widget.conversationId > 0) {
      try {
        await _state.api.dio.delete(
          '/chat/conversations/${widget.conversationId}/messages/$msgId',
          data: {'scope': 'everyone'},
        );
      } catch (_) {}
    }
    _notice(_state.s.tr(
      'تم حذف الرسالة لدى الجميع',
      'Message supprimé pour tout le monde',
      'Deleted for everyone',
    ));
  }

  void _toggleReaction(Map<String, dynamic> m, String key, String emoji) {
    HapticFeedback.lightImpact();
    final myKey = '${_myUserId > 0 ? _myUserId : 1}';
    final currentMap = <String, String>{
      if (m['reactions'] is Map)
        ...Map<String, String>.from(
          (m['reactions'] as Map).map((k, v) => MapEntry('$k', '$v')),
        ),
      if (_localReactions[key] != null) ..._localReactions[key]!,
    };
    final existing = currentMap[myKey];
    final nextEmoji = existing == emoji ? '' : emoji;
    setState(() {
      final map = _localReactions.putIfAbsent(key, () => <String, String>{});
      if (nextEmoji.isEmpty) {
        map.remove(myKey);
        if (m['reactions'] is Map) {
          (m['reactions'] as Map).remove(myKey);
        }
      } else {
        map[myKey] = nextEmoji;
      }
    });
    final docMsgId = (m['doc_id'] ?? '').toString().trim();
    if (_useFirestore && docMsgId.isNotEmpty) {
      FirebaseChatService.instance.toggleMessageReaction(
        docId: _activeFirestoreDocId!,
        messageDocId: docMsgId,
        myUserId: _myUserId,
        emoji: nextEmoji,
      );
    }
  }

  void _togglePin(Map<String, dynamic> m, String key) {
    HapticFeedback.selectionClick();
    final currentlyPinned =
        m['pinned'] == true || _pinnedMessageKeys.contains(key);
    final nextPinned = !currentlyPinned;
    setState(() {
      if (nextPinned) {
        _pinnedMessageKeys.add(key);
        m['pinned'] = true;
      } else {
        _pinnedMessageKeys.remove(key);
        m['pinned'] = false;
      }
    });
    final docMsgId = (m['doc_id'] ?? '').toString().trim();
    if (_useFirestore && docMsgId.isNotEmpty) {
      FirebaseChatService.instance.togglePinMessage(
        docId: _activeFirestoreDocId!,
        messageDocId: docMsgId,
        pinned: nextPinned,
      );
    }
    _notice(nextPinned
        ? _state.s.tr('تم تثبيت الرسالة', 'Message épinglé', 'Message pinned')
        : _state.s.tr('تم إلغاء التثبيت', 'Désépinglé', 'Message unpinned'));
  }

  void _toggleStar(Map<String, dynamic> m, String key) {
    HapticFeedback.selectionClick();
    final starredBy = m['starred_by'] is List
        ? (m['starred_by'] as List).map((e) => '$e').toList()
        : const <String>[];
    final currentlyStarred =
        starredBy.contains('$_myUserId') || _starredMessageKeys.contains(key);
    final nextStarred = !currentlyStarred;
    setState(() {
      if (nextStarred) {
        _starredMessageKeys.add(key);
      } else {
        _starredMessageKeys.remove(key);
      }
    });
    final docMsgId = (m['doc_id'] ?? '').toString().trim();
    if (_useFirestore && docMsgId.isNotEmpty) {
      FirebaseChatService.instance.toggleStarMessage(
        docId: _activeFirestoreDocId!,
        messageDocId: docMsgId,
        myUserId: _myUserId,
        starred: nextStarred,
      );
    }
    _notice(nextStarred
        ? _state.s.tr('تم تمييز الرسالة بنجمة ⭐', 'Message suivi ⭐',
            'Message starred ⭐')
        : _state.s.tr('تمت إزالة النجمة', 'Étoile retirée', 'Star removed'));
  }

  void _showChatSafetyMenu() {
    HapticFeedback.selectionClick();
    final s = _state.s;
    final blocked = _isPeerBlocked;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Directionality(
        textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          showApoloReportSheet(
                            context,
                            targetType: 'chat',
                            targetId: _activeFirestoreDocId ??
                                '${widget.conversationId}',
                            targetName: widget.peerName,
                            reportedUserId: _peerBlockKey,
                            reportedUserAvatar: widget.peerAvatar,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  CupertinoIcons.flag,
                                  size: 17,
                                  color: _textBlack,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  s.tr(
                                    'الإبلاغ عن المحادثة',
                                    'Signaler la conversation',
                                    'Report conversation',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: _textBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsetsDirectional.only(start: 62),
                        child: SizedBox(
                          height: 1,
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFFEEEEEE),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                        onTap: () async {
                          Navigator.pop(ctx);
                          if (blocked) {
                            await FirebaseChatService.instance.unblockTarget(
                              myUserId: _myUserId,
                              targetId: _peerBlockKey,
                            );
                            if (mounted) setState(() {});
                            _notice(s.tr(
                              'تم إلغاء الحظر',
                              'Utilisateur débloqué',
                              'User unblocked',
                            ));
                          } else {
                            await FirebaseChatService.instance.blockTarget(
                              myUserId: _myUserId,
                              targetId: _peerBlockKey,
                              targetName: widget.peerName,
                              targetAvatar: widget.peerAvatar ?? '',
                            );
                            if (mounted) setState(() {});
                            _notice(s.tr(
                              'تم حظر ${widget.peerName}',
                              '${widget.peerName} a été bloqué',
                              'User blocked',
                            ));
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  blocked
                                      ? CupertinoIcons.checkmark_shield
                                      : CupertinoIcons.nosign,
                                  size: 17,
                                  color: blocked
                                      ? _textBlack
                                      : const Color(0xFFE31B23),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  blocked
                                      ? s.tr(
                                          'إلغاء حظر ${widget.peerName}',
                                          'Débloquer ${widget.peerName}',
                                          'Unblock ${widget.peerName}',
                                        )
                                      : s.tr(
                                          'حظر ${widget.peerName}',
                                          'Bloquer ${widget.peerName}',
                                          'Block ${widget.peerName}',
                                        ),
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: blocked
                                        ? _textBlack
                                        : const Color(0xFFE31B23),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageActionsSheet(Map<String, dynamic> m, int index) {
    final key = _messageKey(m, index);
    if (_deletedForEveryoneKeys.contains(key) ||
        m['_deleted_for_everyone'] == true) {
      return;
    }
    HapticFeedback.mediumImpact();
    final s = _state.s;
    final bool isMine = m['is_mine'] == true;
    final bool isAudio = m['type'] == 'audio';
    final String body =
        (_editedMessageBodies[key] ?? m['body'] ?? '').toString();
    final String timeStr = (m['created_at_time'] ?? '').toString();
    final bool isPinned =
        m['pinned'] == true || _pinnedMessageKeys.contains(key);
    final starredBy = m['starred_by'] is List
        ? (m['starred_by'] as List).map((e) => '$e').toList()
        : const <String>[];
    final bool isStarred =
        starredBy.contains('$_myUserId') || _starredMessageKeys.contains(key);

    final myReactionKey = '${_myUserId > 0 ? _myUserId : 1}';
    final existingReactions = <String, String>{
      if (m['reactions'] is Map)
        ...Map<String, String>.from(
          (m['reactions'] as Map).map((k, v) => MapEntry('$k', '$v')),
        ),
      if (_localReactions[key] != null) ..._localReactions[key]!,
    };
    final String? currentMyReaction = existingReactions[myReactionKey];

    Widget buildMenuRow({
      required String label,
      required IconData icon,
      required VoidCallback onTap,
      bool isDestructive = false,
      bool showDivider = true,
    }) {
      final color = isDestructive
          ? Ios26IMessageTokens.errorRed
          : Ios26IMessageTokens.labelPrimary;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(icon, color: color, size: 19),
                ],
              ),
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              thickness: 0.6,
              color: Colors.black.withValues(alpha: 0.08),
            ),
        ],
      );
    }

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Message Menu',
      barrierColor: Colors.white.withValues(alpha: 0.30),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogCtx, _, __) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(dialogCtx),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: isMine
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          ApoloEmojiReactionBar(
                            selectedEmoji: currentMyReaction,
                            onSelectEmoji: (emoji) {
                              Navigator.pop(dialogCtx);
                              _toggleReaction(m, key, emoji);
                            },
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isMine
                                  ? Ios26IMessageTokens.bubbleMine
                                  : Ios26IMessageTokens.bubbleOther,
                              borderRadius: BorderRadius.circular(
                                Ios26IMessageTokens.bubbleRadius,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    isAudio
                                        ? '🎤 ${(m['audio_duration'] ?? '0:01')}'
                                        : (body.isNotEmpty ? body : '📷 Photo'),
                                    textDirection: isAudio
                                        ? TextDirection.ltr
                                        : ChatMessage.detectTextDirection(
                                            body,
                                            fallback:
                                                Directionality.of(dialogCtx),
                                          ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isMine
                                          ? Ios26IMessageTokens.bubbleMineText
                                          : Ios26IMessageTokens.bubbleOtherText,
                                      fontSize:
                                          Ios26IMessageTokens.messageFontSize,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (timeStr.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  Text(
                                    timeStr,
                                    textDirection: TextDirection.ltr,
                                    style: TextStyle(
                                      color: isMine
                                          ? Colors.white70
                                          : Ios26IMessageTokens.dateGray,
                                      fontSize: 11.5,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          LiquidGlassSurface(
                            width: 248,
                            borderRadius: BorderRadius.circular(22),
                            fillAlpha: 0.88,
                            child: Material(
                              color: Colors.transparent,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    key: const Key('chat-action-reply'),
                                    onTap: () {
                                      Navigator.pop(dialogCtx);
                                      final replyAuthor = isMine
                                          ? _myDisplayName
                                          : ((m['sender_name'] ?? '')
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty
                                              ? m['sender_name']
                                                  .toString()
                                                  .trim()
                                              : widget.peerName);
                                      final replyAvatar = isMine
                                          ? (_myAvatarUrl ?? '')
                                          : (widget.peerAvatar ?? '');
                                      setState(() {
                                        _editingMessage = null;
                                        _editingMessageKey = null;
                                        _replyingToMessage = <String, dynamic>{
                                          'id': key,
                                          'sender_name': replyAuthor,
                                          'sender_avatar': replyAvatar,
                                          'body': isAudio
                                              ? '🎤 ${(m['audio_duration'] ?? '0:01')}'
                                              : (body.isNotEmpty
                                                  ? body
                                                  : '📷 Photo'),
                                        };
                                      });
                                      _focus.requestFocus();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 13,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              s.tr('رد', 'Répondre', 'Reply'),
                                              style: const TextStyle(
                                                color: Ios26IMessageTokens
                                                    .labelPrimary,
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            CupertinoIcons
                                                .arrowshape_turn_up_left,
                                            color: Ios26IMessageTokens
                                                .labelPrimary,
                                            size: 19,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Divider(
                                    height: 1,
                                    thickness: 0.6,
                                    color: Colors.black.withValues(alpha: 0.08),
                                  ),
                                  buildMenuRow(
                                    label: isPinned
                                        ? s.tr('إلغاء التثبيت', 'Désépingler',
                                          'Unpin')
                                      : s.tr('تثبيت', 'Épingler', 'Pin'),
                                  icon: isPinned
                                      ? CupertinoIcons.pin_slash
                                      : CupertinoIcons.pin,
                                  onTap: () {
                                    Navigator.pop(dialogCtx);
                                    _togglePin(m, key);
                                  },
                                ),
                                buildMenuRow(
                                  label: isStarred
                                      ? s.tr('إزالة النجمة',
                                          'Retirer l\'étoile', 'Unstar')
                                      : s.tr('تمييز بنجمة',
                                          'Marquer d\'une étoile', 'Star'),
                                  icon: isStarred
                                      ? CupertinoIcons.star_fill
                                      : CupertinoIcons.star,
                                  onTap: () {
                                    Navigator.pop(dialogCtx);
                                    _toggleStar(m, key);
                                  },
                                ),
                                if (!isAudio && body.isNotEmpty)
                                  buildMenuRow(
                                    label: s.tr(
                                        'نسخ النص', 'Copier le texte', 'Copy'),
                                    icon: CupertinoIcons.doc_on_doc,
                                    onTap: () {
                                      Navigator.pop(dialogCtx);
                                      Clipboard.setData(
                                          ClipboardData(text: body));
                                      _notice(
                                          s.tr('تم النسخ', 'Copié', 'Copied'));
                                    },
                                  ),
                                if (isMine && !isAudio)
                                  buildMenuRow(
                                    label: s.tr(
                                        'تعديل الرسالة', 'Modifier', 'Edit'),
                                    icon: CupertinoIcons.pencil,
                                    onTap: () {
                                      Navigator.pop(dialogCtx);
                                      setState(() {
                                        _editingMessage = m;
                                        _editingMessageKey = key;
                                        _msgCtrl.text = body;
                                        _msgCtrl.selection =
                                            TextSelection.collapsed(
                                                offset: body.length);
                                      });
                                      _focus.requestFocus();
                                    },
                                  ),
                                buildMenuRow(
                                  label:
                                      s.tr('إبلاغ', 'Signaler', 'Report'),
                                  icon:
                                      CupertinoIcons.exclamationmark_triangle,
                                  onTap: () {
                                    Navigator.pop(dialogCtx);
                                    showApoloReportSheet(
                                      context,
                                      targetType: 'message',
                                      targetId:
                                          '${m['doc_id'] ?? m['id'] ?? key}',
                                      targetName: widget.peerName,
                                      reportedUserId: _peerBlockKey,
                                      reportedUserAvatar: widget.peerAvatar,
                                      messageExcerpt: body,
                                    );
                                  },
                                ),
                                buildMenuRow(
                                  label: s.tr('حذف لدي فقط',
                                      'Supprimer pour moi', 'Delete'),
                                  icon: CupertinoIcons.trash,
                                  isDestructive: true,
                                  showDivider: isMine,
                                  onTap: () {
                                    Navigator.pop(dialogCtx);
                                    setState(
                                        () => _hiddenMessageKeys.add(key));
                                    final docMsgId =
                                        (m['doc_id'] ?? '').toString().trim();
                                    if (_useFirestore && docMsgId.isNotEmpty) {
                                      FirebaseChatService.instance
                                          .deleteMessageForMe(
                                        docId: _activeFirestoreDocId!,
                                        messageDocId: docMsgId,
                                        myUserId: _myUserId,
                                      );
                                    }
                                  },
                                ),
                                if (isMine)
                                  buildMenuRow(
                                    label: s.tr(
                                      'حذف لدى الجميع',
                                      'Supprimer pour tous',
                                      'Delete for everyone',
                                    ),
                                    icon: CupertinoIcons.trash_fill,
                                    isDestructive: true,
                                    showDivider: false,
                                    onTap: () {
                                      Navigator.pop(dialogCtx);
                                      _deleteMessageForEveryone(m, key);
                                    },
                                  ),
                              ],
                            ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Rule 3: Optimistic UI — adds message bubble immediately before server confirmation,
  /// shows inline retry button on failure, never shows toast or loading spinner on send.
  Future<void> _sendText([String? preset]) async {
    final text = (preset ?? _msgCtrl.text).trim();
    final hasAttachments = preset == null && _stagedAttachments.isNotEmpty;
    if (text.isEmpty && !hasAttachments) return;
    if (!mounted) return;

    if (preset == null && _editingMessage != null && text.isNotEmpty) {
      await _commitEditMessage(text);
      return;
    }

    if (!_useFirestore && (!_state.isLoggedIn || widget.conversationId <= 0)) {
      return;
    }

    final usedInitialDraft =
        preset == null && widget.initialDraft != null && text == widget.initialDraft;

    final now = DateTime.now();
    final tempId = 'opt_${now.microsecondsSinceEpoch}_${_optimisticSeq++}';
    final attachmentsToSend =
        hasAttachments ? List<ChatAttachment>.from(_stagedAttachments) : const <ChatAttachment>[];

    final isImageAttachment = attachmentsToSend.isNotEmpty &&
        attachmentsToSend.first.type == ChatAttachmentType.image &&
        attachmentsToSend.first.bytes != null;

    final activeReply = preset == null && _replyingToMessage != null
        ? Map<String, dynamic>.from(_replyingToMessage!)
        : null;

    final tempMsg = <String, dynamic>{
      'id': tempId,
      'local_id': tempId,
      'client_message_id': tempId,
      // Never inject raw auto-generated filenames (e.g. `scaled_IMG_0865.png`) into image message body
      'body': text.isNotEmpty
          ? text
          : (isImageAttachment
              ? ''
              : (attachmentsToSend.isNotEmpty
                  ? attachmentsToSend.first.name
                  : '')),
      'is_mine': true,
      'sender_id': '$_myUserId',
      'sender_name': _myDisplayName,
      'type': isImageAttachment ? 'image' : 'text',
      if (activeReply != null) 'reply_to': activeReply,
      if (attachmentsToSend.isNotEmpty &&
          attachmentsToSend.first.bytes != null)
        'image_base64': base64Encode(attachmentsToSend.first.bytes!),
      'read': false,
      'created_at_ms': now.millisecondsSinceEpoch,
      'created_at_time': formatChatClock(now),
      '_pending': true,
      '_failed': false,
      '_from_initial_draft': usedInitialDraft,
    };

    setState(() {
      _pending.add(tempMsg);
      if (preset == null) {
        _typingController?.onMessageSent();
        _msgCtrl.clear();
        _stagedAttachments.clear();
        _replyingToMessage = null;
      }
      _isUserReadingHistory = false;
      _unreadIncomingCount = 0;
    });
    _scrollToEnd();

    await _dispatchOptimisticMessage(tempMsg);
  }

  Future<void> _retryMessage(Map<String, dynamic> tempMsg) async {
    if (!mounted) return;
    setState(() {
      tempMsg['_failed'] = false;
      tempMsg['_pending'] = true;
      tempMsg['_use_rich_text'] = false;
    });
    await _dispatchOptimisticMessage(tempMsg);
  }

  Future<void> _dispatchOptimisticMessage(Map<String, dynamic> tempMsg) async {
    final text = (tempMsg['body'] ?? '').toString();
    final conversationId = widget.conversationId;
    final userId = _state.currentUser?['id'];
    final clientMsgId =
        (tempMsg['client_message_id'] ?? tempMsg['local_id'] ?? '').toString();

    // Primary bidirectional WebSocket path when Stateful Chat Server is connected
    if (ChatRealtimeClient.instance.isConnected && _effectivePeerId > 0) {
      ChatRealtimeClient.instance.sendMessage(
        channelId: _realtimeChannelId,
        recipientIds: [_effectivePeerId],
        clientMessageId: clientMsgId,
        type: (tempMsg['type'] ?? 'text').toString(),
        body: text,
        metadata: {
          if (tempMsg['type'] == 'audio') ...{
            'audio_base64': (tempMsg['audio_base64'] ?? '').toString(),
            'audio_mime': (tempMsg['audio_mime'] ?? 'audio/webm').toString(),
            'audio_duration': (tempMsg['audio_duration'] ?? '').toString(),
            if (tempMsg['audio_waveform'] != null)
              'audio_waveform': tempMsg['audio_waveform'],
          },
          if (tempMsg['image_base64'] != null)
            'image_base64': tempMsg['image_base64'],
          if (tempMsg['reply_to'] is Map) 'reply_to': tempMsg['reply_to'],
        },
        adContext: widget.adTitle.trim().isNotEmpty
            ? {
                'ad_id': _effectiveAdId,
                'ad_title': widget.adTitle.trim(),
                'ad_price': (widget.adPrice ?? '').trim(),
                'ad_image': (widget.adImage ?? '').trim(),
              }
            : null,
      );
    }

    if (_useFirestore) {
      final docId = _activeFirestoreDocId!;
      final peerId = _effectivePeerId;
      try {
        if (tempMsg['type'] == 'audio') {
          final rawWave = tempMsg['audio_waveform'];
          final waveform = rawWave is List
              ? rawWave.map((e) => double.tryParse('$e') ?? 0.35).toList()
              : const <double>[];
          await FirebaseChatService.instance.sendAudioMessage(
            docId: docId,
            myUserId: _myUserId,
            myName: _myDisplayName,
            myAvatar: _myAvatarUrl ?? '',
            peerUserId: peerId,
            peerName: widget.peerName,
            peerAvatar: widget.peerAvatar ?? '',
            audioBase64: (tempMsg['audio_base64'] ?? '').toString(),
            audioMime: (tempMsg['audio_mime'] ?? 'audio/webm').toString(),
            audioDuration: (tempMsg['audio_duration'] ?? '0:01').toString(),
            audioWaveform: waveform,
            adId: _effectiveAdId,
            adTitle: widget.adTitle,
            adPrice: widget.adPrice ?? '',
            adImage: widget.adImage ?? '',
          );
          unawaited(_mirrorTextMessageToBackend(
            '🎤 ${(tempMsg['audio_duration'] ?? '0:01')}',
          ));
        } else if (tempMsg['type'] == 'image' &&
            (tempMsg['image_base64'] ?? '').toString().isNotEmpty) {
          await FirebaseChatService.instance.sendImageMessage(
            docId: docId,
            myUserId: _myUserId,
            myName: _myDisplayName,
            myAvatar: _myAvatarUrl ?? '',
            peerUserId: peerId,
            peerName: widget.peerName,
            peerAvatar: widget.peerAvatar ?? '',
            imageBase64: tempMsg['image_base64'].toString(),
            caption: text,
            adId: _effectiveAdId,
            adTitle: widget.adTitle,
            adPrice: widget.adPrice ?? '',
            adImage: widget.adImage ?? '',
          );
        } else {
          await FirebaseChatService.instance.sendTextMessage(
            docId: docId,
            myUserId: _myUserId,
            myName: _myDisplayName,
            myAvatar: _myAvatarUrl ?? '',
            peerUserId: peerId,
            peerName: widget.peerName,
            peerAvatar: widget.peerAvatar ?? '',
            body: text,
            replyTo: tempMsg['reply_to'] is Map
                ? Map<String, dynamic>.from(tempMsg['reply_to'] as Map)
                : null,
            adId: _effectiveAdId,
            adTitle: widget.adTitle,
            adPrice: widget.adPrice ?? '',
            adImage: widget.adImage ?? '',
          );
          unawaited(_mirrorTextMessageToBackend(text));
        }
        if (mounted) {
          setState(() {
            _pending.remove(tempMsg);
          });
        }
      } catch (_) {
        // Fallback: if Firestore failed, try sending via REST backend before marking failed
        try {
          await _mirrorTextMessageToBackend(text);
          if (_resolvedBackendConvId > 0 && mounted) {
            setState(() {
              tempMsg['_pending'] = false;
              tempMsg['_failed'] = false;
              _pending.remove(tempMsg);
              _messages.add(tempMsg);
            });
            return;
          }
        } catch (_) {}
        // Rule 3: Mark bubble as failed with inline retry button; NEVER show a toast.
        if (mounted) {
          setState(() {
            tempMsg['_pending'] = false;
            tempMsg['_failed'] = true;
          });
        }
      }
      return;
    }

    try {
      final res = await _state.api.dio.post(
        '/chat/conversations/$conversationId/messages',
        data: {
          'body': text,
          'message': text,
          if (tempMsg['reply_to'] is Map) 'reply_to': tempMsg['reply_to'],
        },
      );
      if (res.data is! Map || res.data['status'] != 'success') {
        throw StateError('Send not confirmed');
      }
      if (!mounted ||
          conversationId != widget.conversationId ||
          userId != _state.currentUser?['id']) {
        return;
      }
      final created = res.data['message'];
      setState(() {
        _pending.remove(tempMsg);
        if (created is Map) {
          final createdMap = Map<String, dynamic>.from(created);
          if (!_messages.any(
              (m) => m['id'] != null && m['id'] == createdMap['id'])) {
            _messages.add(createdMap);
          }
        } else {
          final confirmed = Map<String, dynamic>.from(tempMsg)
            ..['_pending'] = false
            ..['_failed'] = false;
          _messages.add(confirmed);
        }
      });
      if (created is! Map) {
        await _loadMessages(silent: true);
      }
    } catch (_) {
      // Rule 3: Keep failed bubble in flow with inline retry button, no toast/SnackBar.
      if (mounted &&
          conversationId == widget.conversationId &&
          userId == _state.currentUser?['id']) {
        setState(() {
          tempMsg['_pending'] = false;
          tempMsg['_failed'] = true;
          if (tempMsg['_from_initial_draft'] == true &&
              _msgCtrl.text.isEmpty) {
            _msgCtrl.text = text;
            tempMsg['_use_rich_text'] = true;
          }
        });
      }
    }
  }

  void _notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void _toggleIMessageDrawer([Ios26DrawerTab? preferredTab]) {
    HapticFeedback.selectionClick();
    if (_isDrawerOpen && (preferredTab == null || preferredTab == _drawerTab)) {
      setState(() => _isDrawerOpen = false);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _showCallMenu = false;
      if (preferredTab != null) _drawerTab = preferredTab;
      _isDrawerOpen = true;
    });
    _scrollToEnd();
  }

  Future<void> _sendSticker(IMessageStickerItem item) async {
    setState(() => _isDrawerOpen = false);
    await _sendText('[sticker:${item.id}]');
  }

  Future<void> _sendLocationMessage() async {
    setState(() => _isDrawerOpen = false);
    final city = _state.activeZoneCityLabel(_state.s).trim();
    final userCity = (_state.currentUser?['city'] ?? '').toString().trim();
    final resolvedCity = city.isNotEmpty
        ? city
        : (userCity.isNotEmpty
            ? userCity
            : _state.s.tr('المغرب', 'Maroc', 'Morocco'));
    final msg = _state.s.tr(
      '📍 موقعي الحالي: \u2068$resolvedCity\u2069',
      '📍 Ma position : $resolvedCity',
      '📍 My location: $resolvedCity',
    );
    await _sendText(msg);
  }

  Future<void> _sendOfferMessage(String rawAmount) async {
    final cleaned = rawAmount.replaceAll(RegExp(r'[^0-9.,]'), '').trim();
    if (cleaned.isEmpty) return;
    setState(() => _isDrawerOpen = false);
    final title = widget.adTitle.trim();
    final msg = title.isNotEmpty
        ? _state.s.tr(
            '💰 عرض ثمن على "\u2068$title\u2069": \u2066$cleaned DH\u2069',
            '💰 Offre pour "$title" : $cleaned DH',
            '💰 Price offer for "$title": DH $cleaned',
          )
        : _state.s.tr(
            '💰 عرض ثمن: \u2066$cleaned DH\u2069',
            '💰 Offre de prix : $cleaned DH',
            '💰 Price offer: DH $cleaned',
          );
    await _sendText(msg);
  }

  Future<void> _pickAndStageImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    if (_uploadingMedia) return;
    if (_isDrawerOpen && mounted) {
      setState(() => _isDrawerOpen = false);
    }
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 960,
        imageQuality: 65,
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 700 * 1024) {
        return;
      }
      setState(() {
        _stagedAttachments.add(
          ChatAttachment(
            id: 'att_${DateTime.now().microsecondsSinceEpoch}',
            name: picked.name.isNotEmpty ? picked.name : 'Photo.jpg',
            type: ChatAttachmentType.image,
            bytes: bytes,
            subtitle: '${(bytes.length / 1024).round()} KB',
          ),
        );
      });
    } catch (_) {}
  }

  void _openImagePreview(Uint8List bytes) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  void _openImageUrlPreview(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: AppImage(url: url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> _startVoiceRecording() async {
    _voiceRecorderKey.currentState?.startCapsuleRecording();
  }

  Future<void> _cancelVoiceRecording() async {
    _recordTimer?.cancel();
    await MediaRtcBridge.cancelVoiceRecording();
  }

  Future<void> _handleSendVoiceRecording(VoiceRecordingData recording) async {
    if (!mounted) return;
    if (MediaRtcBridge.isVoiceSupported &&
        _useFirestore &&
        recording.audioBase64.isEmpty) {
      _notice(_state.s.tr(
        'تعذر حفظ التسجيل الصوتي. تأكد من السماح للميكروفون وجرب مرة أخرى.',
        'Impossible d\'enregistrer l\'audio. Autorisez le microphone et réessayez.',
        'Could not capture audio. Please allow microphone access and try again.',
      ));
      return;
    }
    if (recording.audioBase64.length > 900 * 1024) {
      _notice(_state.s.tr(
        'الرسالة الصوتية طويلة جداً. حاول تسجيل رسالة أقصر.',
        'Message vocal trop long. Essayez un enregistrement plus court.',
        'Voice message is too long. Please record a shorter message.',
      ));
      return;
    }

    final now = DateTime.now();
    final tempId = 'voice_${now.microsecondsSinceEpoch}_${_optimisticSeq++}';

    final voiceMsg = <String, dynamic>{
      'id': tempId,
      'local_id': tempId,
      'body': '',
      'type': 'audio',
      'audio_duration': recording.formattedDuration,
      'audio_waveform': recording.waveform,
      'audio_base64': recording.audioBase64,
      'audio_mime': recording.audioMime,
      'is_mine': true,
      'sender_id': '$_myUserId',
      'sender_name': _myDisplayName,
      'read': false,
      'created_at_ms': now.millisecondsSinceEpoch,
      'created_at_time': formatChatClock(now),
      '_pending': _useFirestore,
      '_failed': false,
    };

    setState(() {
      if (_useFirestore) {
        _pending.add(voiceMsg);
      } else {
        _messages.add(voiceMsg);
      }
      _isUserReadingHistory = false;
      _unreadIncomingCount = 0;
    });
    _scrollToEnd();

    if (_useFirestore) {
      try {
        await FirebaseChatService.instance.sendAudioMessage(
          docId: _activeFirestoreDocId!,
          myUserId: _myUserId,
          myName: _myDisplayName,
          myAvatar: _myAvatarUrl ?? '',
          peerUserId: _effectivePeerId,
          peerName: widget.peerName,
          peerAvatar: widget.peerAvatar ?? '',
          audioBase64: recording.audioBase64,
          audioMime: recording.audioMime,
          audioDuration: recording.formattedDuration,
          audioWaveform: recording.waveform,
          adId: _effectiveAdId,
          adTitle: widget.adTitle,
          adPrice: widget.adPrice ?? '',
          adImage: widget.adImage ?? '',
        );
        unawaited(_mirrorTextMessageToBackend('🎤 ${recording.formattedDuration}'));
        if (mounted) {
          setState(() {
            _pending.remove(voiceMsg);
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            voiceMsg['_pending'] = false;
            voiceMsg['_failed'] = true;
          });
        }
      }
    }
  }

  void _startCall({required bool isVideo}) {
    setState(() => _showCallMenu = false);
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          peerName: widget.peerName,
          peerAvatar: widget.peerAvatar,
          peerId: widget.peerId,
          conversationDocId: _activeFirestoreDocId,
          isVideo: isVideo,
        ),
      ),
    );
  }

  void _openPeerProfile() {
    if (widget.peerId == null || widget.peerId! <= 0) return;
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerProfileScreen(
          sellerId: widget.peerId!,
          sellerName: widget.peerName,
          sellerAvatar: widget.peerAvatar,
          initialAd: widget.adTitle.isNotEmpty
              ? {
                  'title': widget.adTitle,
                  'price_formatted': widget.adPrice ?? '',
                  'main_image': widget.adImage ?? '',
                }
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allRaw = ChatRealtimeClient.deduplicateMessages([
      ..._messages,
      ..._pending,
    ]);
    final visibleMessages = <Map<String, dynamic>>[];
    final visibleKeys = <String>[];
    for (int i = 0; i < allRaw.length; i++) {
      final m = allRaw[i];
      final k = _messageKey(m, i);
      if (!_hiddenMessageKeys.contains(k)) {
        visibleMessages.add(m);
        visibleKeys.add(k);
      }
    }

    // Precompute O(N) grouping & date dividers for virtual list
    final groupMeta = ChatMessage.computeGrouping(
      visibleMessages,
      strings: _state.s,
    );
    final hasTypingInFlow = _typingUsers.isNotEmpty;
    final totalFlowCount =
        visibleMessages.length + (hasTypingInFlow ? 1 : 0);

    // Find index of the very last outgoing message to display iMessage "Delivered / Read" status
    int lastOutgoingIdx = -1;
    for (int i = visibleMessages.length - 1; i >= 0; i--) {
      if (visibleMessages[i]['is_mine'] == true) {
        lastOutgoingIdx = i;
        break;
      }
    }

    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bool isKeyboardOpen = keyboardInset > 0;
    const double listHorizontalPad = 16.0;
    final hasAdContext = widget.adTitle.trim().isNotEmpty;
    final int adContextOffset = hasAdContext ? 1 : 0;
    final int totalListCount = adContextOffset + totalFlowCount;
    // Floating header & 45px composer clearance:
    // - Closed keyboard: `41px` bottom offset + `45px` bar
    // - Open keyboard (`1:2660` / `1:989`): `14px` gap above keyboard + `45px` bar (`Y = 411px` on `375×812`)
    final double headerTopClearance = topInset + 64.0;
    final double headerGradientHeight = topInset + 72.0;
    final double restingComposerBottom = _isDrawerOpen
        ? 12.0
        : (isKeyboardOpen
            ? Ios26IMessageTokens.composerKeyboardGap
            : math.max(
                Ios26IMessageTokens.composerBottomOffset,
                bottomInset + 7.0,
              ));
    final double drawerHeightOffset = _isDrawerOpen ? 342.0 : 0.0;
    final double composerBottomClearance =
        restingComposerBottom + Ios26IMessageTokens.composerMinHeight + 14.0 + drawerHeightOffset;

    return Scaffold(
      backgroundColor: Ios26IMessageTokens.canvasWhite,
      body: Stack(
        children: [
          // Layer 0: Full-bleed message stream scrolling naturally beneath the clipped frosted header
          Positioned.fill(
            child: _loading
                ? Padding(
                    padding: EdgeInsets.only(
                      top: headerTopClearance,
                      bottom: composerBottomClearance,
                    ),
                    child: const ChatRoomSkeleton(),
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (_showCallMenu || _isDrawerOpen) {
                        setState(() {
                          _showCallMenu = false;
                          _isDrawerOpen = false;
                        });
                      }
                      FocusScope.of(context).unfocus();
                    },
                    onHorizontalDragUpdate: (details) {
                      final isRtl = Directionality.of(context) == TextDirection.rtl;
                      final delta = isRtl ? details.delta.dx : -details.delta.dx;
                      if (delta.abs() < 0.2) return;
                      final next = (_swipeRevealProgress + delta / 56.0)
                          .clamp(0.0, 1.0);
                      if ((next - _swipeRevealProgress).abs() > 0.01) {
                        setState(() => _swipeRevealProgress = next);
                      }
                    },
                    onHorizontalDragEnd: (_) {
                      if (_swipeRevealProgress > 0.0) {
                        setState(() => _swipeRevealProgress = 0.0);
                      }
                    },
                    onHorizontalDragCancel: () {
                      if (_swipeRevealProgress > 0.0) {
                        setState(() => _swipeRevealProgress = 0.0);
                      }
                    },
                    child: totalFlowCount == 0
                        ? Padding(
                            padding: EdgeInsets.only(
                              top: headerTopClearance,
                              bottom: composerBottomClearance,
                            ),
                            child: _buildEmptyChatState(
                              includeAdCard: hasAdContext,
                            ),
                          )
                        : ListView.builder(
                            key: const Key('chat-virtual-list'),
                            controller: _scrollCtrl,
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            addAutomaticKeepAlives: false,
                            addRepaintBoundaries: true,
                            padding: EdgeInsetsDirectional.fromSTEB(
                              listHorizontalPad,
                              headerTopClearance + 6,
                              listHorizontalPad,
                              composerBottomClearance,
                            ),
                            itemCount: totalListCount,
                            itemBuilder: (_, idx) {
                              // Embedded initial product/ad context preview card at the
                              // very start of the conversation (scrolls away naturally).
                              if (hasAdContext && idx == 0) {
                                return _buildEmbeddedAdContextCard();
                              }
                              final msgIdx = idx - adContextOffset;
                              // Rule 5: Typing indicator inline in flow where next message will appear
                              if (msgIdx == visibleMessages.length) {
                                return ChatTypingIndicator(
                                  key: const Key('chat-typing-indicator-flow'),
                                  typingUsers: _typingUsers,
                                  avatarUrl: widget.peerAvatar,
                                );
                              }
                              return _buildChatMessageItem(
                                visibleMessages[msgIdx],
                                visibleKeys[msgIdx],
                                groupMeta[msgIdx],
                                msgIdx,
                                isLastOutgoing: msgIdx == lastOutgoingIdx,
                              );
                            },
                          ),
                  ),
          ),

          // Layer 1: Soft bottom progressive white fade under floating Liquid Glass composer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Ios26BottomEdgeFade(
              height: restingComposerBottom +
                  Ios26IMessageTokens.composerMinHeight +
                  16.0,
            ),
          ),

          // Layer 2: Exact Figma `1:2` White Header Gradient Overlay (`(-8, -11, 390, 180)`)
          // Placed ABOVE scrolling messages/photos and BELOW the floating clear-glass header controls.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Ios26HeaderGradientOverlay(
              height: headerGradientHeight,
            ),
          ),

          // Layer 2.5: Floating Clear-Glass Header Controls (`Back`, `65×65` Avatar + `Name >`, `Video`)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                if (_loadError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 6),
                    child: LiquidGlassSurface(
                      borderRadius: BorderRadius.circular(999),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      onTap: () => _loadMessages(),
                      child: Text(
                        _loadError!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Ios26IMessageTokens.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Layer 3: Rule 4 Scroll Anchoring — Floating Liquid Glass "X new messages · Jump to latest" pill
          if (_unreadIncomingCount > 0)
            Positioned(
              bottom: restingComposerBottom +
                  Ios26IMessageTokens.composerMinHeight +
                  10.0,
              left: 16,
              right: 16,
              child: Center(
                child: Semantics(
                  liveRegion: true,
                  button: true,
                  label:
                      '$_unreadIncomingCount new ${_unreadIncomingCount == 1 ? "message" : "messages"}. Jump to latest',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('chat-new-messages-pill'),
                      onTap: _jumpToLatest,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF000000),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                '$_unreadIncomingCount new ${_unreadIncomingCount == 1 ? 'message' : 'messages'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Container(
                                key: const Key('chat-jump-to-latest'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Jump to latest',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    Icon(
                                      CupertinoIcons.arrow_down,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Layer 4: Floating iOS 26 Liquid Glass Bottom Composer + Half-Height `+` Apps/Stickers Sheet (`0:99`)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  _buildComposerSection(isKeyboardOpen: isKeyboardOpen),
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: const Cubic(0.22, 1.0, 0.36, 1.0),
                  alignment: Alignment.bottomCenter,
                  child: _isDrawerOpen
                      ? Ios26IMessageDrawer(
                          initialTab: _drawerTab,
                          lang: _state.s.lang,
                          hasListingContext: hasAdContext,
                          listingPrice: (widget.adPrice ?? '').trim(),
                          onClose: () => setState(() => _isDrawerOpen = false),
                          onPickPhoto: () =>
                              _pickAndStageImage(source: ImageSource.gallery),
                          onTakePhoto: () =>
                              _pickAndStageImage(source: ImageSource.camera),
                          onStartVoice: () {
                            setState(() => _isDrawerOpen = false);
                            _startVoiceRecording();
                          },
                          onSendLocation: _sendLocationMessage,
                          onSendOffer: _sendOfferMessage,
                          onSendSticker: _sendSticker,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Layer 5: Floating Liquid Glass Call & Safety Popover
          if (_showCallMenu)
            PositionedDirectional(
              top: topInset + 64,
              end: 18,
              child: _buildCallDropdownCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildChatMessageItem(
    Map<String, dynamic> m,
    String msgKey,
    ChatMessageGroupMeta meta,
    int index, {
    bool isLastOutgoing = false,
  }) {
    final bool isMine = m['is_mine'] == true;
    final bool isDeletedAll = m['_deleted_for_everyone'] == true ||
        _deletedForEveryoneKeys.contains(msgKey);
    final bool isEdited =
        m['_edited'] == true || _editedMessageBodies.containsKey(msgKey);
    final String rawBody = isDeletedAll
        ? _state.s.tr(
            'تم حذف هذه الرسالة',
            'Ce message a été supprimé',
            'This message was deleted',
          )
        : (_editedMessageBodies[msgKey] ?? m['body'] ?? '').toString();
    final String timeStr = (m['created_at_time'] ?? '').toString();
    final bool isAudio = !isDeletedAll && m['type'] == 'audio';
    final String audioDuration = (m['audio_duration'] ?? '').toString();

    final String rawImageBase64 = (m['image_base64'] ?? '').toString().trim();
    Uint8List? imageBytes;
    if (!isDeletedAll && rawImageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(rawImageBase64);
      } catch (_) {}
    }

    String resolvedImageUrl = (m['image_url'] ??
            m['media_url'] ??
            m['attachment_url'] ??
            m['photo_url'] ??
            '')
        .toString()
        .trim();
    final bool looksLikeRawImageFilename =
        !isDeletedAll && !isAudio && ChatMessage.isRawMediaFilename(rawBody);
    if (!isDeletedAll &&
        imageBytes == null &&
        resolvedImageUrl.isEmpty &&
        (m['type'] == 'image' ||
            m['type'] == 'ad_share' ||
            looksLikeRawImageFilename)) {
      resolvedImageUrl =
          (m['ad_image'] ?? widget.adImage ?? '').toString().trim();
    }

    final bool isImage =
        !isDeletedAll && (imageBytes != null || resolvedImageUrl.isNotEmpty);
    final String body = isDeletedAll
        ? rawBody
        : (isImage
            ? ChatMessage.sanitizeCaption(rawBody, hasImage: true)
            : (looksLikeRawImageFilename
                ? _state.s.tr('📷 صورة', '📷 Photo', '📷 Photo')
                : rawBody));

    final bool isPinned = !isDeletedAll &&
        (m['pinned'] == true || _pinnedMessageKeys.contains(msgKey));
    final starredBy = m['starred_by'] is List
        ? (m['starred_by'] as List).map((e) => '$e').toList()
        : const <String>[];
    final bool isStarred = !isDeletedAll &&
        (starredBy.contains('$_myUserId') ||
            _starredMessageKeys.contains(msgKey));

    final mergedReactions = <String, String>{
      if (!isDeletedAll && m['reactions'] is Map)
        ...Map<String, String>.from(
          (m['reactions'] as Map).map((k, v) => MapEntry('$k', '$v')),
        ),
      if (!isDeletedAll && _localReactions[msgKey] != null)
        ..._localReactions[msgKey]!,
    };
    final reactionEmojis =
        mergedReactions.values.where((e) => e.trim().isNotEmpty).toList();

    final ChatMessageStatus status;
    final ChatAckStatus initialAckStatus;
    if (m['_failed'] == true) {
      status = ChatMessageStatus.failed;
      initialAckStatus = ChatAckStatus.failed;
    } else if (m['_pending'] == true) {
      status = ChatMessageStatus.sending;
      initialAckStatus = ChatAckStatus.sending;
    } else if (m['read'] == true || m['ack_status'] == 'read') {
      status = ChatMessageStatus.read;
      initialAckStatus = ChatAckStatus.read;
    } else if (m['delivered'] == true || m['ack_status'] == 'delivered') {
      status = ChatMessageStatus.delivered;
      initialAckStatus = ChatAckStatus.delivered;
    } else {
      status = ChatMessageStatus.sent;
      initialAckStatus = ChatAckStatus.sent;
    }

    final ackListenable = isMine && !isDeletedAll
        ? _ackRegistry.listenableFor(
            msgKey,
            initial: initialAckStatus,
            serverMessageId: (m['message_id'] ?? m['id'])?.toString(),
          )
        : null;

    final senderName = isMine
        ? _myDisplayName
        : ((m['sender_name'] ?? '').toString().trim().isNotEmpty
            ? m['sender_name'].toString().trim()
            : widget.peerName);
    final senderAvatar = isMine ? _myAvatarUrl : widget.peerAvatar;

    String? deliveryLabel;
    if (isMine && (isLastOutgoing || isImage) && !isDeletedAll) {
      if (status == ChatMessageStatus.read) {
        deliveryLabel = _state.s.tr('تمت القراءة', 'Lu', 'Read');
      } else if (status == ChatMessageStatus.delivered ||
          status == ChatMessageStatus.sent) {
        deliveryLabel = _state.s.tr('تم التسليم', 'Distribué', 'Delivered');
      }
    }

    // Detect die-cut iMessage sticker payload `[sticker:<id>]`
    IMessageStickerItem? stickerItem;
    if (!isDeletedAll && !isAudio && !isImage) {
      final stickerMatch =
          RegExp(r'^\[sticker:([a-z0-9_]+)\]$').firstMatch(body.trim());
      if (stickerMatch != null) {
        stickerItem = IMessageStickerItem.findById(stickerMatch.group(1)!);
      }
    }

    final Map<String, dynamic>? replyMap = m['reply_to'] is Map
        ? Map<String, dynamic>.from(m['reply_to'] as Map)
        : (m['metadata'] is Map && (m['metadata'] as Map)['reply_to'] is Map
            ? Map<String, dynamic>.from(
                (m['metadata'] as Map)['reply_to'] as Map,
              )
            : null);

    final bool effectiveHideGutter;
    final bool effectiveShowAvatar;
    if (widget.showInlineAvatars == true) {
      effectiveHideGutter = false;
      effectiveShowAvatar = meta.showAvatar;
    } else if (widget.showInlineAvatars == false) {
      effectiveHideGutter = true;
      effectiveShowAvatar = false;
    } else {
      // Dynamic Layer v5.1 (`47281:3598`): peer avatar on bottom-left of incoming group, none on outgoing.
      effectiveHideGutter = isMine;
      effectiveShowAvatar = !isMine && meta.isLastInGroup;
    }

    return ChatMessage(
      key: ValueKey<String>(msgKey),
      messageKey: msgKey,
      body: stickerItem != null
          ? '${stickerItem.emoji} ${stickerItem.labelFor(_state.s.lang)}'
          : body,
      isMine: isMine,
      senderName: senderName,
      senderAvatar: senderAvatar,
      timestamp: timeStr,
      status: status,
      showAvatar: effectiveShowAvatar,
      hideAvatarGutter: effectiveHideGutter,
      deliveryLabel: deliveryLabel,
      ackStatusListenable: ackListenable,
      swipeRevealProgress: _swipeRevealProgress,
      isBorderlessCustomContent: stickerItem != null,
      replySenderName: replyMap?['sender_name']?.toString(),
      replySenderAvatar: replyMap?['sender_avatar']?.toString(),
      replyBody: replyMap?['body']?.toString(),
      isFirstInGroup: meta.isFirstInGroup,
      isLastInGroup: meta.isLastInGroup,
      topSpacing: meta.topSpacing,
      showDateDivider: meta.showDateDivider,
      dateLabel: meta.dateLabel,
      isDeleted: isDeletedAll,
      isEdited: isEdited,
      isPinned: isPinned,
      isStarred: isStarred,
      reactions: reactionEmojis,
      imageBytes: imageBytes,
      imageUrl: resolvedImageUrl.isNotEmpty ? resolvedImageUrl : null,
      customContent: stickerItem != null
          ? IMessageDieCutSticker(
              emoji: stickerItem.emoji,
              label: stickerItem.labelFor(_state.s.lang),
              tint: stickerItem.tint,
              tiltDeg: stickerItem.tiltDeg,
              size: 108,
            )
          : (isAudio
              ? _buildAudioBubbleContent(m, msgKey, audioDuration, isMine)
              : null),
      onRetry: status == ChatMessageStatus.failed
          ? () => _retryMessage(m)
          : null,
      onAvatarTap: !isMine ? _openPeerProfile : null,
      onImageTap: imageBytes != null
          ? () => _openImagePreview(imageBytes!)
          : (resolvedImageUrl.isNotEmpty
              ? () => _openImageUrlPreview(resolvedImageUrl)
              : null),
      onDoubleTap: isDeletedAll
          ? null
          : () => _toggleReaction(m, msgKey, '❤️'),
      onOpenActions:
          isDeletedAll ? null : () => _showMessageActionsSheet(m, index),
      useRichTextForBody: m['_use_rich_text'] == true,
    );
  }

  Widget _buildEmptyChatState({bool includeAdCard = false}) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (includeAdCard) ...[
              _buildEmbeddedAdContextCard(),
              const SizedBox(height: 12),
            ],
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _chatBlueSoft,
                border: Border.all(
                  color: _chatBlue.withValues(alpha: 0.18),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.chat_bubble_2_fill,
                  color: _chatBlue,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.peerName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _textBlack,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.adTitle.isNotEmpty
                  ? 'محادثة بخصوص: "\u2068${widget.adTitle}\u2069"'
                  : 'ابدأ المحادثة الآن واطرح استفساراتك مباشرة',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Native iOS rich preview card embedded inside the scrollable message list
  /// (at the start of the conversation) so it scrolls away naturally with chat history.
  Widget _buildEmbeddedAdContextCard() {
    final title = widget.adTitle.trim();
    final price = (widget.adPrice ?? '').trim();
    final img = (widget.adImage ?? '').trim();
    final adId = _effectiveAdId;
    final canOpenAd = adId > 0;
    final contextDir = Directionality.of(context);
    final isRtl = contextDir == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('chat-ad-context-banner'),
              borderRadius: BorderRadius.circular(18),
              onTap: canOpenAd
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdDetailScreen(adId: adId),
                        ),
                      );
                    }
                  : null,
              child: Ink(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1C1E)
                      : const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFEEEEEE),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 56,
                        height: 56,
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : Colors.white,
                        child: img.isNotEmpty
                            ? AppImage(
                                url: img,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Icon(
                                  CupertinoIcons.tag_fill,
                                  size: 20,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF000000),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textDirection: ChatMessage.detectTextDirection(
                              title,
                              fallback: contextDir,
                            ),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF000000),
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (price.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                price,
                                key: const Key('chat-ad-context-price'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF000000),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (canOpenAd) ...[
                      const SizedBox(width: 8),
                      Icon(
                        isRtl
                            ? CupertinoIcons.chevron_left
                            : CupertinoIcons.chevron_right,
                        size: 14,
                        color: const Color(0xFF757575),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatPresenceSubtitle() {
    final presence = _peerPresence;
    if (presence != null) {
      if (presence.isOnline) {
        return _state.s.tr('متصل الآن', 'En ligne', 'Online');
      }
      final last = presence.lastActiveAt;
      if (last != null) {
        final clock = formatChatClock(last);
        return _state.s.tr(
          'آخر ظهور \u2066$clock\u2069',
          'Vu à $clock',
          'Last seen $clock',
        );
      }
    }
    return _state.s.tr('غير متصل', 'Hors ligne', 'Offline');
  }

  /// Combined Dynamic Layer v5.1 Chat Header:
  /// - Start: `40 × 40` circular `#EEEEEE` `<` back button (plus compact unread badge if `unreadCount > 0`)
  /// - Center: Clean inline `34 × 34` circular profile avatar + peer name (`16px Bold #000000`) from Screenshot 4 (`Joshi`)
  /// - End: `40 × 40` circular `#EEEEEE` `•••` button for Voice/Video Call & Safety/Report menu.
  Widget _buildHeader() {
    final topInset = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? Colors.white : const Color(0xFF000000);
    final Color pillBg =
        isDark ? const Color(0xFF262629) : const Color(0xFFEEEEEE);
    final contextDir = Directionality.of(context);
    final isRtl = contextDir == TextDirection.rtl;
    final isPeerOnline = _peerPresence?.isOnline == true;
    final unreadCount = _state.unreadChatCount;

    return Padding(
      padding: EdgeInsets.only(top: topInset),
      child: SizedBox(
        key: const Key('chat-dl-top-nav'),
        height: 56.0,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Start: `40 × 40` `#EEEEEE` circular `<` back button
              Semantics(
                button: true,
                label: 'Back',
                child: Material(
                  key: const Key('chat-ios26-back-button'),
                  color: pillBg,
                  shape: unreadCount > 0
                      ? const StadiumBorder()
                      : const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: unreadCount > 0
                        ? const StadiumBorder()
                        : const CircleBorder(),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      height: 40.0,
                      width: unreadCount > 0 ? null : 40.0,
                      padding: unreadCount > 0
                          ? const EdgeInsets.symmetric(horizontal: 10)
                          : EdgeInsets.zero,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isRtl
                                ? CupertinoIcons.chevron_forward
                                : CupertinoIcons.chevron_back,
                            color: ink,
                            size: 19,
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: ink,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF000000)
                                      : Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Start-aligned `34 × 34` profile avatar + bold Peer Name + Blue Verified Seal (`47281:3598`)
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.peerId != null && widget.peerId! > 0
                        ? _openPeerProfile
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NotificationBadge(
                          count: isPeerOnline ? 1 : 0,
                          type: NotificationBadgeType.dot,
                          variant: NotificationBadgeVariant.green,
                          top: 0,
                          right: 0,
                          dotSize: 9,
                          child: Container(
                            key: const Key('chat-ios26-avatar-glass'),
                            width: 34.0,
                            height: 34.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: pillBg,
                            ),
                            child: ClipOval(
                              child: widget.peerAvatar != null &&
                                      widget.peerAvatar!.isNotEmpty
                                    ? AppImage(
                                        url: widget.peerAvatar!,
                                        width: 34.0,
                                        height: 34.0,
                                        fit: BoxFit.cover,
                                        fallback: _buildAvatarFallback(
                                          widget.peerName,
                                        ),
                                      )
                                    : _buildAvatarFallback(widget.peerName),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.peerName,
                            key: const Key('chat-ios26-name-pill'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: ChatMessage.detectTextDirection(
                              widget.peerName,
                              fallback: contextDir,
                            ),
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              color: ink,
                              height: 20.0 / 16.0,
                              letterSpacing: AppTypography.trackingForContext(
                                context,
                                -0.3,
                              ),
                            ),
                          ),
                        ),
                        if (widget.isPeerVerified) ...[
                          const SizedBox(width: 6),
                          const ApoloVerifiedBadge(
                            key: Key('chat-header-verified-badge'),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // End: `40 × 40` `#EEEEEE` circular `•••` menu button (Video / Voice Call / Safety)
              Semantics(
                button: true,
                label: 'Call and chat options',
                child: Material(
                  key: const Key('chat-ios26-call-button'),
                  color: pillBg,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showCallMenu = !_showCallMenu);
                    },
                    child: SizedBox(
                      width: 40.0,
                      height: 40.0,
                      child: Center(
                        child: Icon(
                          CupertinoIcons.ellipsis,
                          color:
                              _showCallMenu ? Ios26IMessageTokens.bubbleMine : ink,
                          size: 20,
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

  Widget _buildCallDropdownCard() {
    final liveCalls = _useFirestore && MediaRtcBridge.isRtcSupported;
    final isPeerOnline = _peerPresence?.isOnline == true;
    return Container(
      width: 248,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isPeerOnline
                            ? Ios26IMessageTokens.onlineGreen
                            : const Color(0xFF9E9E9E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatPresenceSubtitle(),
                        key: const Key('chat-peer-presence-text'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPeerOnline
                              ? Ios26IMessageTokens.onlineGreen
                              : const Color(0xFF757575),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(
              height: 1,
              color: Color(0xFFEEEEEE),
              indent: 14,
              endIndent: 14,
            ),
            ListTile(
              dense: true,
              leading: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEEEEE),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  CupertinoIcons.videocam_fill,
                  color: Color(0xFF000000),
                  size: 16,
                ),
              ),
              title: Text(
                liveCalls
                    ? _state.s.tr('مكالمة فيديو', 'Appel vidéo', 'Video Call')
                    : _state.s.tr(
                        'مكالمة فيديو — غير متاحة',
                        'Appel vidéo — indisponible',
                        'Video Call — unavailable',
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
              onTap: () => _startCall(isVideo: true),
            ),
            const Divider(
              height: 1,
              color: Color(0xFFEEEEEE),
              indent: 14,
              endIndent: 14,
            ),
            ListTile(
              dense: true,
              leading: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEEEEE),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  CupertinoIcons.phone_fill,
                  color: Color(0xFF000000),
                  size: 15,
                ),
              ),
              title: Text(
                liveCalls
                    ? _state.s.tr('مكالمة صوتية', 'Appel vocal', 'Voice Call')
                    : _state.s.tr(
                        'مكالمة صوتية — غير متاحة',
                        'Appel vocal — indisponible',
                        'Voice Call — unavailable',
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
              onTap: () => _startCall(isVideo: false),
            ),
            const Divider(
              height: 1,
              color: Color(0xFFEEEEEE),
              indent: 14,
              endIndent: 14,
            ),
            ListTile(
              dense: true,
              leading: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEEEEE),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  CupertinoIcons.shield_lefthalf_fill,
                  color: Color(0xFFE31B23),
                  size: 16,
                ),
              ),
              title: Text(
                _state.s.tr(
                  'الأمان والتبليغ',
                  'Sécurité et signalement',
                  'Safety & Report',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE31B23),
                ),
              ),
              onTap: () {
                setState(() => _showCallMenu = false);
                _showChatSafetyMenu();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioBubbleContent(
      Map<String, dynamic> m, String msgKey, String duration, bool isMine) {
    final audioB64 = (m['audio_base64'] ?? '').toString().trim();
    final audioMime = (m['audio_mime'] ?? 'audio/webm').toString();
    final rawWave = m['audio_waveform'];
    final List<double>? waveform = rawWave is List
        ? rawWave.map((e) => double.tryParse('$e') ?? 0.35).toList()
        : null;

    return VoiceMessagePlayer(
      messageKey: msgKey,
      durationLabel: duration.isNotEmpty ? duration : '0:01',
      waveform: waveform,
      isMine: isMine,
      audioBase64: audioB64,
      audioMime: audioMime,
    );
  }

  Widget _buildComposerSection({bool isKeyboardOpen = false}) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    if (_isPeerBlocked) {
      return Container(
        padding: EdgeInsetsDirectional.fromSTEB(16, 12, 16, bottomInset + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.nosign, size: 18, color: _textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _state.s.tr(
                  'لقد قمت بحظر هذا المستخدم',
                  'Vous avez bloqué cet utilisateur',
                  'You blocked this user',
                ),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: _textMuted,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: _textBlack,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () async {
                await FirebaseChatService.instance.unblockTarget(
                  myUserId: _myUserId,
                  targetId: _peerBlockKey,
                );
                if (mounted) setState(() {});
              },
              child: Text(
                _state.s.tr('إلغاء الحظر', 'Débloquer', 'Unblock'),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ChatInput(
      controller: _msgCtrl,
      focusNode: _focus,
      voiceRecorderKey: _voiceRecorderKey,
      attachments: _stagedAttachments,
      onSend: (_) => _sendText(),
      onAttachTap: _toggleIMessageDrawer,
      isDrawerOpen: _isDrawerOpen,
      hasBottomSheetBelow: _isDrawerOpen,
      isKeyboardOpen: isKeyboardOpen,
      onRemoveAttachment: (att) {
        setState(() {
          _stagedAttachments.removeWhere((a) => a.id == att.id);
        });
      },
      onVoiceTap: _startVoiceRecording,
      onSendVoice: _handleSendVoiceRecording,
      isRecordingVoice: _isRecordingVoice,
      recordSeconds: _recordSeconds,
      onCancelVoice: _cancelVoiceRecording,
      editingBannerText: _editingMessage != null
          ? _state.s.tr(
              'تعديل الرسالة',
              'Modifier le message',
              'Editing message',
            )
          : null,
      onCancelEdit: () {
        setState(() {
          _editingMessage = null;
          _editingMessageKey = null;
          _msgCtrl.clear();
        });
      },
      replySenderName: _replyingToMessage?['sender_name']?.toString(),
      replyBody: _replyingToMessage?['body']?.toString(),
      onCancelReply: () {
        setState(() => _replyingToMessage = null);
      },
      hintText: _state.s.tr(
        'أكتب رسالة...',
        'Envoyer un message',
        'Send a message',
      ),
      recordingText: _state.s.tr(
        'جاري التسجيل...',
        'Enregistrement...',
        'Recording...',
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final trimmed = name.trim();
    return Container(
      color: const Color(0xFFEEEEEE),
      alignment: Alignment.center,
      child: Text(
        trimmed.isNotEmpty ? trimmed.characters.first.toUpperCase() : 'A',
        style: const TextStyle(
          color: Color(0xFF000000),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
