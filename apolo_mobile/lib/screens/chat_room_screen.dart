import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/services/firebase_chat_service.dart';
import '../core/services/media_rtc_bridge.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import 'call_screen.dart';
import 'seller_profile_screen.dart';
import 'widgets/app_image.dart';
import 'widgets/chat_utils.dart';

/// Real-time Chat Room powered by Firebase Firestore (with REST fallback).
class ChatRoomScreen extends StatefulWidget {
  final int conversationId;
  final String? firestoreDocId;
  final String peerName;
  final int? peerId;
  final String adTitle;
  final String? peerAvatar;
  final String? adImage;
  final String? adPrice;
  final String? initialDraft;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    this.firestoreDocId,
    required this.peerName,
    this.peerId,
    this.adTitle = '',
    this.peerAvatar,
    this.adImage,
    this.adPrice,
    this.initialDraft,
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
  final Set<String> _hiddenMessageKeys = {};
  final Set<String> _deletedForEveryoneKeys = {};
  final Map<String, String> _editedMessageBodies = {};
  Map<String, dynamic>? _editingMessage;
  String? _editingMessageKey;
  bool _loading = true;
  bool _showCallMenu = false;
  bool _sending = false;
  bool _uploadingMedia = false;
  bool _isRecordingVoice = false;
  int _recordSeconds = 0;
  String? _playingAudioId;
  double _playingProgress = 0.0;
  bool _loadingRequest = false;
  bool _peerTyping = false;
  String? _loadError;
  Timer? _pollTimer;
  Timer? _focusScrollTimer;
  Timer? _typingTimer;
  Timer? _recordTimer;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<Map<String, dynamic>?>? _convMetaSub;
  StreamSubscription<Map<String, dynamic>?>? _incomingCallSub;
  String? _lastHandledCallId;
  Object? _accountId;

  int get _myUserId => int.tryParse('${_state.currentUser?['id'] ?? ''}') ?? 0;

  String? get _activeFirestoreDocId {
    final explicit = widget.firestoreDocId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    if (FirebaseChatService.instance.isReady &&
        _myUserId > 0 &&
        (widget.peerId ?? 0) > 0) {
      return FirebaseChatService.instance.buildConversationDocId(
        myUserId: _myUserId,
        peerUserId: widget.peerId!,
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
    _state.addListener(_onAccountChanged);

    if (widget.initialDraft != null) _msgCtrl.text = widget.initialDraft!;

    _msgCtrl.addListener(() {
      if (mounted) setState(() {});
      _handleTypingActivity();
    });

    _focus.addListener(() {
      if (_focus.hasFocus) {
        _focusScrollTimer?.cancel();
        _focusScrollTimer =
            Timer(const Duration(milliseconds: 300), _scrollToEnd);
      }
    });

    if (_useFirestore) {
      _bindFirestoreStreams();
    } else {
      _loadMessages(scrollToBottom: true);
      _startPolling();
    }
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
      final hadMore = incoming.length > _messages.length;
      final wasAlreadyLoaded = !_loading;
      setState(() {
        _messages = incoming;
        _pending.clear();
        _loading = false;
        _loadError = null;
      });
      if (hadMore) {
        _scrollToEnd();
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
      bool someoneElseTyping = false;
      if (typingMap != null) {
        for (final entry in typingMap.entries) {
          if ('${entry.key}' != '$_myUserId' && entry.value == true) {
            someoneElseTyping = true;
            break;
          }
        }
      }
      if (someoneElseTyping != _peerTyping) {
        setState(() => _peerTyping = someoneElseTyping);
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
    });
    _msgCtrl.clear();
    if (_useFirestore) {
      _bindFirestoreStreams();
    } else {
      _loadMessages();
    }
  }

  void _startPolling() {
    if (_useFirestore) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _loadMessages(silent: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_useFirestore) return;
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
        _peerTyping = false;
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
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _loadMessages(
      {bool silent = false, bool scrollToBottom = false}) async {
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
      setState(() {
        _messages = incoming
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
        _loadError = null;
      });
      if (scrollToBottom) _scrollToEnd();
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
    final id = m['id'];
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
      _notice(_state.s.tr('تم تعديل الرسالة', 'Message modifié', 'Message edited'));
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
    _notice(_state.s.tr('تم تعديل الرسالة', 'Message modifié', 'Message edited'));
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

  void _showMessageActionsSheet(Map<String, dynamic> m, int index) {
    final key = _messageKey(m, index);
    if (_deletedForEveryoneKeys.contains(key)) return;
    HapticFeedback.mediumImpact();
    final s = _state.s;
    final bool isMine = m['is_mine'] == true;
    final bool isAudio = m['type'] == 'audio';
    final String body = (_editedMessageBodies[key] ?? m['body'] ?? '').toString();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
              if (!isAudio && body.isNotEmpty)
                ListTile(
                  leading: const Icon(CupertinoIcons.doc_on_doc,
                      color: _textBlack, size: 20),
                  title: Text(
                    s.tr('نسخ النص', 'Copier le texte', 'Copy text'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _textBlack,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: body));
                    _notice(s.tr('تم النسخ', 'Copié', 'Copied'));
                  },
                ),
              if (isMine && !isAudio)
                ListTile(
                  leading: const Icon(CupertinoIcons.pencil,
                      color: _textBlack, size: 20),
                  title: Text(
                    s.tr('تعديل الرسالة', 'Modifier le message', 'Edit message'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _textBlack,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _editingMessage = m;
                      _editingMessageKey = key;
                      _msgCtrl.text = body;
                      _msgCtrl.selection =
                          TextSelection.collapsed(offset: body.length);
                    });
                    _focus.requestFocus();
                  },
                ),
              ListTile(
                leading: const Icon(CupertinoIcons.eye_slash,
                    color: _textBlack, size: 20),
                title: Text(
                  s.tr('حذف لدي فقط', 'Supprimer pour moi', 'Delete for me'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textBlack,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _hiddenMessageKeys.add(key));
                  final docMsgId = (m['doc_id'] ?? '').toString().trim();
                  if (_useFirestore && docMsgId.isNotEmpty) {
                    FirebaseChatService.instance.deleteMessageForMe(
                      docId: _activeFirestoreDocId!,
                      messageDocId: docMsgId,
                      myUserId: _myUserId,
                    );
                  }
                  _notice(s.tr(
                    'تم حذف الرسالة من عندك فقط',
                    'Supprimé pour vous uniquement',
                    'Deleted for you',
                  ));
                },
              ),
              if (isMine)
                ListTile(
                  leading: const Icon(CupertinoIcons.trash,
                      color: Color(0xFFE31B23), size: 20),
                  title: Text(
                    s.tr(
                      'حذف لدى الجميع',
                      'Supprimer pour tout le monde',
                      'Delete for everyone',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE31B23),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteMessageForEveryone(m, key);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendText([String? preset]) async {
    final text = (preset ?? _msgCtrl.text).trim();
    if (text.isEmpty || _sending || !mounted) return;
    if (preset == null && _editingMessage != null) {
      await _commitEditMessage(text);
      return;
    }
    if (_useFirestore) {
      final docId = _activeFirestoreDocId!;
      final myName = (_state.currentUser?['name'] ??
              _state.currentUser?['full_name'] ??
              'Apolo User')
          .toString();
      final myAvatar = (_state.currentUser?['avatar_url'] ??
              _state.currentUser?['avatar'] ??
              '')
          .toString();
      final peerId = widget.peerId ?? 0;

      if (preset == null) _msgCtrl.clear();
      setState(() => _sending = true);
      try {
        await FirebaseChatService.instance.sendTextMessage(
          docId: docId,
          myUserId: _myUserId,
          myName: myName,
          myAvatar: myAvatar,
          peerUserId: peerId,
          peerName: widget.peerName,
          peerAvatar: widget.peerAvatar ?? '',
          body: text,
          adTitle: widget.adTitle,
          adPrice: widget.adPrice ?? '',
          adImage: widget.adImage ?? '',
        );
        _scrollToEnd();
      } catch (_) {
        if (mounted) {
          if (_msgCtrl.text.isEmpty) _msgCtrl.text = text;
          _notice(_state.s.tr(
            'تعذر إرسال الرسالة. تحقق من الاتصال وحاول مجدداً.',
            'Impossible d\'envoyer le message. Vérifiez votre connexion.',
          ));
        }
      } finally {
        if (mounted) setState(() => _sending = false);
      }
      return;
    }

    if (!_state.isLoggedIn || widget.conversationId <= 0) {
      _notice(_state.s.tr('سجّل الدخول لإرسال رسالة.',
          'Connectez-vous pour envoyer un message.'));
      return;
    }
    final conversationId = widget.conversationId;
    final userId = _state.currentUser?['id'];
    final tempMsg = <String, dynamic>{
      'body': text,
      'is_mine': true,
      'type': 'text',
      'read': false,
      'created_at_time': formatChatClock(DateTime.now()),
      '_pending': true,
    };
    setState(() {
      _sending = true;
      _pending.add(tempMsg);
    });
    _scrollToEnd();
    try {
      final res = await _state.api.dio.post(
          '/chat/conversations/$conversationId/messages',
          data: {'body': text, 'message': text});
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
        if (created is Map &&
            !_messages
                .any((m) => m['id'] != null && m['id'] == created['id'])) {
          _messages.add(Map<String, dynamic>.from(created));
        }
      });
      if (preset == null && _msgCtrl.text.trim() == text) _msgCtrl.clear();
      await _loadMessages(silent: true);
      _scrollToEnd();
    } catch (_) {
      if (mounted &&
          conversationId == widget.conversationId &&
          userId == _state.currentUser?['id']) {
        if (preset != null && _msgCtrl.text.isEmpty) _msgCtrl.text = text;
        _notice(_state.s.tr(
            'تعذر تأكيد الإرسال. النص محفوظ؛ تحقق من المحادثة قبل إعادة المحاولة.',
            'Envoi non confirmé. Brouillon conservé ; vérifiez la conversation avant de réessayer.'));
      }
    } finally {
      if (mounted) {
        setState(() {
          _pending.remove(tempMsg);
          _sending = false;
        });
      }
    }
  }

  void _notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _pickAndSendImage() async {
    if (!_useFirestore) {
      _mediaUnavailable();
      return;
    }
    if (_uploadingMedia) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 960,
        imageQuality: 65,
      );
      if (picked == null || !mounted) return;
      setState(() => _uploadingMedia = true);

      final bytes = await picked.readAsBytes();
      if (bytes.length > 700 * 1024) {
        if (mounted) {
          _notice(_state.s.tr(
            'الصورة كبيرة بزاف، اختار صورة أصغر.',
            'Image trop lourde, choisissez une image plus petite.',
            'Image is too large, please choose a smaller one.',
          ));
        }
        return;
      }

      final base64Str = base64Encode(bytes);
      final myName = (_state.currentUser?['name'] ??
              _state.currentUser?['full_name'] ??
              'Apolo User')
          .toString();
      final myAvatar = (_state.currentUser?['avatar_url'] ??
              _state.currentUser?['avatar'] ??
              '')
          .toString();

      await FirebaseChatService.instance.sendImageMessage(
        docId: _activeFirestoreDocId!,
        myUserId: _myUserId,
        myName: myName,
        myAvatar: myAvatar,
        peerUserId: widget.peerId ?? 0,
        peerName: widget.peerName,
        peerAvatar: widget.peerAvatar ?? '',
        imageBase64: base64Str,
        adTitle: widget.adTitle,
        adPrice: widget.adPrice ?? '',
        adImage: widget.adImage ?? '',
      );
      _scrollToEnd();
    } catch (_) {
      if (mounted) {
        _notice(_state.s.tr(
          'تعذر إرسال الصورة.',
          'Impossible d\'envoyer l\'image.',
          'Failed to send image.',
        ));
      }
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
    }
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
      _mediaUnavailable();
      return;
    }
    HapticFeedback.mediumImpact();
    final ok = await MediaRtcBridge.startVoiceRecording();
    if (!mounted) return;
    if (!ok) {
      _notice(_state.s.tr(
        'يرجى السماح بالوصول للميكروفون لتسجيل رسالة صوتية.',
        'Veuillez autoriser le micro pour enregistrer un message vocal.',
        'Please allow microphone access to record a voice note.',
      ));
      return;
    }
    _recordTimer?.cancel();
    setState(() {
      _isRecordingVoice = true;
      _recordSeconds = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordSeconds++);
      if (_recordSeconds >= 45) {
        _stopAndSendVoiceRecording();
      }
    });
  }

  Future<void> _cancelVoiceRecording() async {
    _recordTimer?.cancel();
    await MediaRtcBridge.cancelVoiceRecording();
    if (mounted) {
      setState(() {
        _isRecordingVoice = false;
        _recordSeconds = 0;
      });
    }
  }

  Future<void> _stopAndSendVoiceRecording() async {
    if (!_isRecordingVoice) return;
    _recordTimer?.cancel();
    setState(() {
      _isRecordingVoice = false;
      _uploadingMedia = true;
    });
    try {
      final result = await MediaRtcBridge.stopVoiceRecording();
      if (!mounted || result == null || result.base64.isEmpty) return;

      if (result.base64.length > 900 * 1024) {
        _notice(_state.s.tr(
          'التسجيل طويل بزاف، حاول تسجّل رسالة أقصر.',
          'Enregistrement trop long, essayez un message plus court.',
          'Recording is too long, please try a shorter message.',
        ));
        return;
      }

      final mins = result.durationSec ~/ 60;
      final secs = (result.durationSec % 60).toString().padLeft(2, '0');
      final durationStr = '$mins:$secs';

      final myName = (_state.currentUser?['name'] ??
              _state.currentUser?['full_name'] ??
              'Apolo User')
          .toString();
      final myAvatar = (_state.currentUser?['avatar_url'] ??
              _state.currentUser?['avatar'] ??
              '')
          .toString();

      await FirebaseChatService.instance.sendAudioMessage(
        docId: _activeFirestoreDocId!,
        myUserId: _myUserId,
        myName: myName,
        myAvatar: myAvatar,
        peerUserId: widget.peerId ?? 0,
        peerName: widget.peerName,
        peerAvatar: widget.peerAvatar ?? '',
        audioBase64: result.base64,
        audioMime: result.mime,
        audioDuration: durationStr,
        adTitle: widget.adTitle,
        adPrice: widget.adPrice ?? '',
        adImage: widget.adImage ?? '',
      );
      _scrollToEnd();
    } catch (_) {
      if (mounted) {
        _notice(_state.s.tr(
          'تعذر إرسال الرسالة الصوتية.',
          'Impossible d\'envoyer le message vocal.',
          'Failed to send voice note.',
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingMedia = false;
          _recordSeconds = 0;
        });
      }
    }
  }

  void _togglePlayVoice(String id, String base64, String mime) {
    if (_playingAudioId == id) {
      MediaRtcBridge.pauseVoiceMessage();
      setState(() {
        _playingAudioId = null;
        _playingProgress = 0.0;
      });
      return;
    }
    setState(() {
      _playingAudioId = id;
      _playingProgress = 0.0;
    });
    MediaRtcBridge.playVoiceMessage(
      id,
      base64,
      mime,
      onProgress: (p) {
        if (mounted && _playingAudioId == id) {
          setState(() => _playingProgress = p);
        }
      },
      onEnded: () {
        if (mounted && _playingAudioId == id) {
          setState(() {
            _playingAudioId = null;
            _playingProgress = 0.0;
          });
        }
      },
    );
  }

  void _mediaUnavailable() => _notice(_state.s.tr(
      'الرسائل الصوتية غير متاحة على هذا الجهاز حالياً.',
      'Les messages vocaux sont indisponibles sur cet appareil.'));

  // ───────────────────────── Voice & Video Calls ─────────────────────────
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
    final all = [..._messages, ..._pending];

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Main Chat Column
          Column(
            children: [
              _buildHeader(),
              if (widget.adTitle.trim().isNotEmpty) _buildAdContextBar(),
              if (_loadError != null)
                TextButton(
                    onPressed: () => _loadMessages(), child: Text(_loadError!)),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CupertinoActivityIndicator(radius: 12),
                      )
                    : GestureDetector(
                        onTap: () {
                          if (_showCallMenu) {
                            setState(() => _showCallMenu = false);
                          }
                          FocusScope.of(context).unfocus();
                        },
                        child: all.isEmpty
                            ? _buildEmptyChatState()
                            : ListView.builder(
                                controller: _scrollCtrl,
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                itemCount: all.length,
                                itemBuilder: (_, idx) {
                                  return _buildMessageBubble(all[idx], idx);
                                },
                              ),
                      ),
              ),
              _buildComposer(),
            ],
          ),

          // Floating Call Dropdown Menu Popup (Matching Reference)
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

  // ───────────────────────── 1. Header Bar ─────────────────────────

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
                    color: _chatBlue.withValues(alpha: 0.18), width: 2),
              ),
              child: const Center(
                child: Icon(CupertinoIcons.chat_bubble_2_fill,
                    color: _chatBlue, size: 32),
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
                            fallback:
                                _buildAvatarFallback(widget.peerName),
                          )
                        : _buildAvatarFallback(widget.peerName),
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
                  Row(
                    children: [
                      Container(
                        width: 6.5,
                        height: 6.5,
                        decoration: BoxDecoration(
                          color: _useFirestore
                              ? const Color(0xFF22C55E)
                              : _textSubtle,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _peerTyping
                              ? _state.s.tr('يكتب الآن...',
                                  'En train d\'écrire...', 'Typing...')
                              : _useFirestore
                                  ? _state.s.tr('متصل الآن', 'En ligne', 'Online')
                                  : _state.s.tr('حالة الاتصال غير متاحة',
                                      'Statut indisponible'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _peerTyping
                                ? const Color(0xFF16A34A)
                                : _textMuted,
                            fontWeight:
                                _peerTyping ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Right Call Button with dropdown indicator (`📞 ⌵`)
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
        ],
      ),
    );
  }

  // Floating Call Dropdown Card (Voice & Video)
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

  // ───────────────────────── 2. Message Bubbles ─────────────────────────
  Widget _buildMessageBubble(dynamic rawMsg, int index) {
    final Map<String, dynamic> m =
        rawMsg is Map<String, dynamic> ? rawMsg : Map<String, dynamic>.from(rawMsg);
    final String msgKey = _messageKey(m, index);
    if (_hiddenMessageKeys.contains(msgKey)) {
      return const SizedBox.shrink();
    }

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
        imageBytes = base64Decode((m['image_base64'] ?? '').toString().trim());
      } catch (_) {}
    }

    final borderRadius = BorderRadiusDirectional.only(
      topStart: const Radius.circular(18),
      topEnd: const Radius.circular(18),
      bottomStart: Radius.circular(isMine ? 18 : 4),
      bottomEnd: Radius.circular(isMine ? 4 : 18),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onLongPress:
                isDeletedAll ? null : () => _showMessageActionsSheet(m, index),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.76,
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              decoration: BoxDecoration(
                color: isDeletedAll
                    ? _surfaceGrey
                    : (isMine ? _chatBlue : _surfaceGrey),
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: isMine && !isDeletedAll
                        ? _chatBlue.withValues(alpha: 0.14)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAudio)
                    _buildAudioBubbleContent(m, msgKey, audioDuration, isMine)
                  else if (imageBytes != null) ...[
                    GestureDetector(
                      onTap: () => _openImagePreview(imageBytes!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 230,
                            maxHeight: 260,
                          ),
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 14,
                          color: isMine ? Colors.white : _textBlack,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ] else
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.35,
                        fontStyle:
                            isDeletedAll ? FontStyle.italic : FontStyle.normal,
                        color: isDeletedAll
                            ? _textMuted
                            : (isMine ? Colors.white : _textBlack),
                        fontWeight:
                            isDeletedAll ? FontWeight.w400 : FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isEdited && !isDeletedAll) ...[
                        Text(
                          _state.s.tr('معدّلة · ', 'modifié · ', 'edited · '),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isMine ? Colors.white60 : _textSubtle,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDeletedAll
                              ? _textSubtle
                              : (isMine ? Colors.white70 : _textSubtle),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isMine && !isDeletedAll) ...[
                        const SizedBox(width: 4),
                        Icon(
                          m['_pending'] == true
                              ? CupertinoIcons.clock
                              : m['read'] == true
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioBubbleContent(
      Map<String, dynamic> m, String msgKey, String duration, bool isMine) {
    final audioB64 = (m['audio_base64'] ?? '').toString().trim();
    final audioMime = (m['audio_mime'] ?? 'audio/webm').toString();
    final canPlay = audioB64.isNotEmpty && MediaRtcBridge.isVoiceSupported;
    final isPlaying = _playingAudioId == msgKey;
    final progress = isPlaying ? _playingProgress : 0.0;
    const heights = [6.0, 12.0, 18.0, 10.0, 20.0, 14.0, 8.0, 17.0, 13.0, 19.0, 11.0, 15.0, 9.0, 12.0];

    if (!canPlay) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.mic_fill,
              size: 16, color: isMine ? Colors.white70 : _textMuted),
          const SizedBox(width: 6),
          Text(
            duration.isNotEmpty ? '🎤 $duration' : _state.s.tr('رسالة صوتية', 'Message vocal', 'Voice note'),
            style: TextStyle(
              color: isMine ? Colors.white : _textBlack,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: 210,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _togglePlayVoice(msgKey, audioB64, audioMime),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isMine
                    ? Colors.white.withValues(alpha: 0.2)
                    : _textBlack,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(heights.length, (i) {
                final filled = (i / heights.length) <= progress && isPlaying;
                return Container(
                  width: 3,
                  height: heights[i],
                  decoration: BoxDecoration(
                    color: isMine
                        ? (filled ? Colors.white : Colors.white.withValues(alpha: 0.42))
                        : (filled ? _textBlack : _textBlack.withValues(alpha: 0.25)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            duration.isNotEmpty ? duration : '0:01',
            style: TextStyle(
              color: isMine ? Colors.white70 : _textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final canSend = _msgCtrl.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(14, 8, 14, bottomInset + 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_editingMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _surfaceGrey,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.pencil,
                      size: 15, color: _textBlack),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _state.s.tr('تعديل الرسالة', 'Modifier le message',
                          'Editing message'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _textBlack,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _editingMessage = null;
                        _editingMessageKey = null;
                        _msgCtrl.clear();
                      });
                    },
                    child: const Icon(CupertinoIcons.xmark_circle_fill,
                        size: 18, color: _textMuted),
                  ),
                ],
              ),
            ),
          if (_isRecordingVoice)
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _surfaceGrey,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _cancelVoiceRecording,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(CupertinoIcons.xmark,
                          size: 16, color: Color(0xFFE31B23)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE31B23),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_recordSeconds ~/ 60}:${(_recordSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: _textBlack,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _state.s.tr('جاري التسجيل...', 'Enregistrement...',
                          'Recording...'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _stopAndSendVoiceRecording,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: _chatBlue,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        CupertinoIcons.arrow_up,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
            children: [
              // Start `+` button in circular soft grey container (Photo picker)
              GestureDetector(
                onTap: _pickAndSendImage,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: _surfaceGrey,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _uploadingMedia
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _textBlack,
                          ),
                        )
                      : const Icon(
                          CupertinoIcons.plus,
                          color: _textBlack,
                          size: 19,
                        ),
                ),
              ),
              const SizedBox(width: 8),

              // Clean Single-Frame Pill Text Field (no inner border)
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _surfaceGrey,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            inputDecorationTheme: const InputDecorationTheme(
                              filled: false,
                              fillColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          child: TextField(
                            key: const Key('chat-draft'),
                            controller: _msgCtrl,
                            focusNode: _focus,
                            minLines: 1,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendText(),
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: _textBlack,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              filled: false,
                              fillColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              hintText: _state.s.tr('اكتب رسالة...',
                                  'Écrire un message...', 'Type a message...'),
                              hintStyle: const TextStyle(
                                color: _textSubtle,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 11),
                            ),
                          ),
                        ),
                      ),
                      if (!canSend) ...[
                        GestureDetector(
                          onTap: _pickAndSendImage,
                          child: const Icon(
                            CupertinoIcons.camera,
                            color: _textMuted,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Voice Note Recording Button
                        GestureDetector(
                          onTap: _startVoiceRecording,
                          child: const Icon(
                            CupertinoIcons.mic_fill,
                            color: _chatBlue,
                            size: 19,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Monochrome Send / Save Edit Button
              if (canSend) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  key: const Key('chat-send'),
                  onTap: _sending ? null : () => _sendText(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: _chatBlue,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _editingMessage != null
                          ? Icons.check_rounded
                          : CupertinoIcons.arrow_up,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
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
