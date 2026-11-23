import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/services/firebase_chat_service.dart';
import '../core/services/media_rtc_bridge.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_message.dart';
import '../widgets/notification_badge.dart';
import '../widgets/voice_recorder.dart';
import 'call_screen.dart';
import 'seller_profile_screen.dart';
import 'widgets/apolo_safety_sheet.dart';
import 'widgets/app_image.dart';
import 'widgets/chat_utils.dart';

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

  Timer? _pollTimer;
  Timer? _focusScrollTimer;
  Timer? _typingTimer;
  Timer? _recordTimer;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<Map<String, dynamic>?>? _convMetaSub;
  StreamSubscription<Map<String, dynamic>?>? _incomingCallSub;
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

  static const Color _bg = Color(0xFFFFFFFF);
  static const Color _chatBlue = Color(0xFF0A0A0A);
  static const Color _chatBlueSoft = Color(0xFFF2F3F7);
  static const Color _surfaceGrey = Color(0xFFF2F3F7);
  static const Color _textBlack = Color(0xFF0A0A0A);
  static const Color _textMuted = Color(0xFF6B7280);
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

    _msgCtrl.addListener(() {
      if (mounted) setState(() {});
      _handleTypingActivity();
    });

    _focus.addListener(() {
      if (_focus.hasFocus && !_isUserReadingHistory) {
        _focusScrollTimer?.cancel();
        _focusScrollTimer =
            Timer(const Duration(milliseconds: 300), _scrollToEnd);
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
      _loadMessages(scrollToBottom: true);
      _startPolling();
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
    final docId = _activeFirestoreDocId!;
    final hasText = _msgCtrl.text.trim().isNotEmpty;
    FirebaseChatService.instance.setTyping(
      docId: docId,
      myUserId: _myUserId,
      isTyping: hasText,
    );
    _typingTimer?.cancel();
    if (hasText) {
      _typingTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted && _useFirestore) {
          FirebaseChatService.instance.setTyping(
            docId: docId,
            myUserId: _myUserId,
            isTyping: false,
          );
        }
      });
    }
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
    _pollTimer?.cancel();
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
            'Connexion impossible. Réessayez.');
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

  void _startPolling() {
    if (_useFirestore || widget.initialMessages != null) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _loadMessages(silent: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_useFirestore || widget.initialMessages != null) return;
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      if (ModalRoute.of(context)?.isCurrent == true) {
        _loadMessages(silent: true);
      }
    } else {
      _pollTimer?.cancel();
    }
  }

  @override
  void dispose() {
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
    _messagesSub?.cancel();
    _convMetaSub?.cancel();
    _incomingCallSub?.cancel();
    _typingTimer?.cancel();
    _recordTimer?.cancel();
    if (_isRecordingVoice) {
      MediaRtcBridge.cancelVoiceRecording();
    }
    MediaRtcBridge.pauseVoiceMessage();
    _pollTimer?.cancel();
    _focusScrollTimer?.cancel();
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
              'Chargement impossible. Réessayez.');
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: _textBlack,
                ),
                title: Text(
                  s.tr('الإبلاغ عن المحادثة', 'Signaler la conversation',
                      'Report conversation'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textBlack,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showApoloReportSheet(
                    context,
                    targetType: 'chat',
                    targetId:
                        _activeFirestoreDocId ?? '${widget.conversationId}',
                    targetName: widget.peerName,
                    reportedUserId: _peerBlockKey,
                    reportedUserAvatar: widget.peerAvatar,
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  blocked
                      ? CupertinoIcons.checkmark_shield
                      : CupertinoIcons.nosign,
                  color: blocked ? _textBlack : const Color(0xFFE31B23),
                ),
                title: Text(
                  blocked
                      ? s.tr(
                          'إلغاء حظر ${widget.peerName}',
                          'Débloquer ${widget.peerName}',
                          'Unblock ${widget.peerName}')
                      : s.tr(
                          'حظر ${widget.peerName}',
                          'Bloquer ${widget.peerName}',
                          'Block ${widget.peerName}'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: blocked ? _textBlack : const Color(0xFFE31B23),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (blocked) {
                    await FirebaseChatService.instance.unblockTarget(
                      myUserId: _myUserId,
                      targetId: _peerBlockKey,
                    );
                    if (mounted) setState(() {});
                    _notice(s.tr('تم إلغاء الحظر', 'Utilisateur débloqué',
                        'User unblocked'));
                  } else {
                    await FirebaseChatService.instance.blockTarget(
                      myUserId: _myUserId,
                      targetId: _peerBlockKey,
                      targetName: widget.peerName,
                      targetAvatar: widget.peerAvatar ?? '',
                    );
                    if (mounted) setState(() {});
                    _notice(s.tr('تم حظر ${widget.peerName}',
                        '${widget.peerName} a été bloqué', 'User blocked'));
                  }
                },
              ),
            ],
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

    const quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏', '👏'];

    Widget buildMenuRow({
      required String label,
      required IconData icon,
      required VoidCallback onTap,
      bool isDestructive = false,
      bool showDivider = true,
    }) {
      final color = isDestructive ? const Color(0xFFFF6B6B) : Colors.white;
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
                        fontSize: 15,
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
              color: Colors.white.withValues(alpha: 0.12),
            ),
        ],
      );
    }

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Message Menu',
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogCtx, _, __) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(dialogCtx),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2024),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final emoji in quickEmojis)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(dialogCtx);
                                      _toggleReaction(m, key, emoji);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5.5,
                                      ),
                                      child: Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 25),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF23252A),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    isAudio
                                        ? '🎤 ${(m['audio_duration'] ?? '0:01')}'
                                        : (body.isNotEmpty ? body : '📷 Photo'),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (timeStr.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: 245,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2024),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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

    final tempMsg = <String, dynamic>{
      'id': tempId,
      'local_id': tempId,
      'body': text.isNotEmpty
          ? text
          : (attachmentsToSend.isNotEmpty ? attachmentsToSend.first.name : ''),
      'is_mine': true,
      'sender_id': '$_myUserId',
      'sender_name': _myDisplayName,
      'type': attachmentsToSend.isNotEmpty &&
              attachmentsToSend.first.type == ChatAttachmentType.image &&
              attachmentsToSend.first.bytes != null
          ? 'image'
          : 'text',
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
        _msgCtrl.clear();
        _stagedAttachments.clear();
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

    if (_useFirestore) {
      final docId = _activeFirestoreDocId!;
      final peerId = _effectivePeerId;
      try {
        if (tempMsg['type'] == 'image' &&
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
        data: {'body': text, 'message': text},
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

  Future<void> _pickAndStageImage() async {
    if (_uploadingMedia) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
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

  Future<void> _startVoiceRecording() async {
    if (!_useFirestore || !MediaRtcBridge.isVoiceSupported) {
      return;
    }
  }

  Future<void> _cancelVoiceRecording() async {
    _recordTimer?.cancel();
    await MediaRtcBridge.cancelVoiceRecording();
  }

  Future<void> _handleSendVoiceRecording(VoiceRecordingData recording) async {
    if (!mounted) return;
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
      '_pending': false,
      '_failed': false,
    };

    setState(() {
      _messages.add(voiceMsg);
      _isUserReadingHistory = false;
      _unreadIncomingCount = 0;
    });
    _scrollToEnd();

    if (_useFirestore && recording.audioBase64.isNotEmpty) {
      if (recording.audioBase64.length > 900 * 1024) return;
      try {
        await FirebaseChatService.instance.sendAudioMessage(
          docId: _activeFirestoreDocId!,
          myUserId: _myUserId,
          myName: _myDisplayName,
          myAvatar: _myAvatarUrl ?? '',
          peerUserId: widget.peerId ?? 0,
          peerName: widget.peerName,
          peerAvatar: widget.peerAvatar ?? '',
          audioBase64: recording.audioBase64,
          audioMime: recording.audioMime,
          audioDuration: recording.formattedDuration,
          audioWaveform: recording.waveform,
          adTitle: widget.adTitle,
          adPrice: widget.adPrice ?? '',
          adImage: widget.adImage ?? '',
        );
      } catch (_) {}
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
    final allRaw = [..._messages, ..._pending];
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

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              if (widget.adTitle.trim().isNotEmpty) _buildAdContextBar(),
              if (_loadError != null)
                TextButton(
                  onPressed: () => _loadMessages(),
                  child: Text(_loadError!),
                ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CupertinoActivityIndicator(radius: 12),
                      )
                    : Stack(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              if (_showCallMenu) {
                                setState(() => _showCallMenu = false);
                              }
                              FocusScope.of(context).unfocus();
                            },
                            child: totalFlowCount == 0
                                ? _buildEmptyChatState()
                                : ListView.builder(
                                    key: const Key('chat-virtual-list'),
                                    controller: _scrollCtrl,
                                    physics: const BouncingScrollPhysics(),
                                    addAutomaticKeepAlives: false,
                                    addRepaintBoundaries: true,
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      16,
                                    ),
                                    itemCount: totalFlowCount,
                                    itemBuilder: (_, idx) {
                                      // Rule 5: Typing indicator inline in flow where next message will appear
                                      if (idx == visibleMessages.length) {
                                        return ChatTypingIndicator(
                                          key: const Key(
                                              'chat-typing-indicator-flow'),
                                          typingUsers: _typingUsers,
                                          avatarUrl: widget.peerAvatar,
                                        );
                                      }
                                      return _buildChatMessageItem(
                                        visibleMessages[idx],
                                        visibleKeys[idx],
                                        groupMeta[idx],
                                        idx,
                                      );
                                    },
                                  ),
                          ),

                          // Rule 4: Scroll Anchoring — "X new messages" pill with "Jump to latest" button
                          if (_unreadIncomingCount > 0)
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
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
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _textBlack,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.18),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
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
                                                key: const Key(
                                                    'chat-jump-to-latest'),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.16),
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        'Jump to latest',
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
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
                        ],
                      ),
              ),
              _buildComposerSection(),
            ],
          ),
          if (_showCallMenu)
            PositionedDirectional(
              top: MediaQuery.of(context).padding.top + 48,
              end: 16,
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
    int index,
  ) {
    final bool isMine = m['is_mine'] == true;
    final bool isDeletedAll = m['_deleted_for_everyone'] == true ||
        _deletedForEveryoneKeys.contains(msgKey);
    final bool isEdited =
        m['_edited'] == true || _editedMessageBodies.containsKey(msgKey);
    final String body = isDeletedAll
        ? _state.s.tr(
            'تم حذف هذه الرسالة',
            'Ce message a été supprimé',
            'This message was deleted',
          )
        : (_editedMessageBodies[msgKey] ?? m['body'] ?? '').toString();
    final String timeStr = (m['created_at_time'] ?? '').toString();
    final bool isAudio = !isDeletedAll && m['type'] == 'audio';
    final bool isImage = !isDeletedAll &&
        m['type'] == 'image' &&
        (m['image_base64'] ?? '').toString().trim().isNotEmpty;
    final String audioDuration = (m['audio_duration'] ?? '').toString();

    Uint8List? imageBytes;
    if (isImage) {
      try {
        imageBytes =
            base64Decode((m['image_base64'] ?? '').toString().trim());
      } catch (_) {}
    }

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
    if (m['_failed'] == true) {
      status = ChatMessageStatus.failed;
    } else if (m['_pending'] == true) {
      status = ChatMessageStatus.sending;
    } else if (m['read'] == true) {
      status = ChatMessageStatus.read;
    } else {
      status = ChatMessageStatus.sent;
    }

    final senderName = isMine
        ? _myDisplayName
        : ((m['sender_name'] ?? '').toString().trim().isNotEmpty
            ? m['sender_name'].toString().trim()
            : widget.peerName);
    final senderAvatar = isMine ? _myAvatarUrl : widget.peerAvatar;

    return ChatMessage(
      key: ValueKey<String>(msgKey),
      messageKey: msgKey,
      body: body,
      isMine: isMine,
      senderName: senderName,
      senderAvatar: senderAvatar,
      timestamp: timeStr,
      status: status,
      showAvatar: meta.showAvatar,
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
      customContent: isAudio
          ? _buildAudioBubbleContent(m, msgKey, audioDuration, isMine)
          : null,
      onRetry: status == ChatMessageStatus.failed
          ? () => _retryMessage(m)
          : null,
      onAvatarTap: !isMine ? _openPeerProfile : null,
      onImageTap:
          imageBytes != null ? () => _openImagePreview(imageBytes!) : null,
      onOpenActions:
          isDeletedAll ? null : () => _showMessageActionsSheet(m, index),
      useRichTextForBody: m['_use_rich_text'] == true,
    );
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                  ? 'محادثة بخصوص: "${widget.adTitle}"'
                  : 'ابدأ المحادثة الآن واطرح استفساراتك مباشرة',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'رسائل سريعة مقترحة:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _textSubtle,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickPill('السلام عليكم، واش الإعلان باقي متوفر؟'),
                _buildQuickPill('شحال آخر ثمن من فضلك؟'),
                _buildQuickPill('فين كاين بالضبط باش نشوف السلعة؟'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPill(String text) {
    return InkWell(
      onTap: () => _sendText(text),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _textBlack,
          ),
        ),
      ),
    );
  }

  Widget _buildAdContextBar() {
    final title = widget.adTitle.trim();
    final price = (widget.adPrice ?? '').trim();
    final img = (widget.adImage ?? '').trim();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _surfaceGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (img.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 34,
                height: 34,
                child: AppImage(
                  url: img,
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textBlack,
              ),
            ),
          ),
          if (price.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              price,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _chatBlue,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final topInset = MediaQuery.of(context).padding.top;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(6, topInset + 4, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            icon: Icon(
              isRtl
                  ? CupertinoIcons.chevron_right
                  : CupertinoIcons.chevron_left,
              color: _textBlack,
              size: 21,
            ),
          ),
          GestureDetector(
            onTap: widget.peerId != null && widget.peerId! > 0
                ? _openPeerProfile
                : null,
            child: NotificationBadge(
              count: _useFirestore ? 1 : 0,
              type: NotificationBadgeType.dot,
              variant: NotificationBadgeVariant.green,
              top: 0,
              right: 0,
              dotSize: 10,
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _chatBlueSoft,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child:
                      widget.peerAvatar != null && widget.peerAvatar!.isNotEmpty
                          ? AppImage(
                              url: widget.peerAvatar!,
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                              fallback: _buildAvatarFallback(widget.peerName),
                            )
                          : _buildAvatarFallback(widget.peerName),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.peerId != null && widget.peerId! > 0
                  ? _openPeerProfile
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: _textBlack,
                      letterSpacing:
                          AppTypography.trackingForContext(context, -0.2),
                    ),
                  ),
                  const SizedBox(height: 1.5),
                  // Rule 5: Typing indicator is rendered inline in flow, never floating at top header
                  Text(
                    _useFirestore
                        ? _state.s.tr('متصل الآن', 'En ligne', 'Online')
                        : _state.s.tr(
                            'حالة الاتصال غير متاحة', 'Statut indisponible'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: _textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _showCallMenu = !_showCallMenu);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _showCallMenu ? _chatBlueSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.phone,
                    color: _showCallMenu ? _chatBlue : _textBlack,
                    size: 19,
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    CupertinoIcons.chevron_down,
                    color: _showCallMenu ? _chatBlue : _textBlack,
                    size: 11.5,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _showChatSafetyMenu,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _surfaceGrey,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: const Icon(
                CupertinoIcons.ellipsis_vertical,
                color: _textBlack,
                size: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallDropdownCard() {
    final liveCalls = _useFirestore && MediaRtcBridge.isRtcSupported;
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 240,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.phone, color: _chatBlue),
              title: Text(liveCalls
                  ? _state.s.tr('مكالمة صوتية', 'Appel vocal', 'Voice Call')
                  : _state.s.tr('مكالمة صوتية — غير متاحة',
                      'Appel vocal — indisponible')),
              onTap: () => _startCall(isVideo: false),
            ),
            ListTile(
              leading:
                  const Icon(CupertinoIcons.videocam_fill, color: _chatBlue),
              title: Text(liveCalls
                  ? _state.s.tr('مكالمة فيديو', 'Appel vidéo', 'Video Call')
                  : _state.s.tr('مكالمة فيديو — غير متاحة',
                      'Appel vidéo — indisponible')),
              onTap: () => _startCall(isVideo: true),
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

  Widget _buildComposerSection() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    if (_isPeerBlocked) {
      return Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
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
      attachments: _stagedAttachments,
      onSend: (_) => _sendText(),
      onAttachTap: _pickAndStageImage,
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
      hintText: _state.s.tr(
        'اكتب رسالة...',
        'Écrire un message...',
        'Type a message...',
      ),
      recordingText: _state.s.tr(
        'جاري التسجيل...',
        'Enregistrement...',
        'Recording...',
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: _chatBlueSoft,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'R',
        style: const TextStyle(
          color: _chatBlue,
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
